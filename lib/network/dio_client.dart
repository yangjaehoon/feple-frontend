import 'dart:async';
import 'package:dio/dio.dart';
import '../auth/token_store.dart';
import '../config.dart' as app_config;
import 'api_cache_store.dart';
import 'performance_interceptor.dart';

extension ResponseListExt on Response {
  List<T> toModelList<T>(T Function(Map<String, dynamic>) fromJson) =>
      (data as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
}

bool _isNetworkError(DioException e) {
  return e.response == null &&
      (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.unknown);
}

const _defaultConnectTimeout = Duration(seconds: 10);
const _defaultReceiveTimeout = Duration(seconds: 20);

/// per-request Authorization이 이미 있으면 덮어쓰지 않음 (예: 카카오 액세스 토큰)
Future<void> _attachJwtIfAbsent(RequestOptions options) async {
  if (options.headers.containsKey('Authorization')) return;
  final jwt = await TokenStore.readAccessToken();
  if (jwt != null && jwt.isNotEmpty) {
    options.headers['Authorization'] = 'Bearer $jwt';
  }
}

/// dio.interceptors 등록 순서 (중요 — 순서를 바꾸면 인증/캐시 흐름이 조용히 깨짐):
/// 1. [_AuthAndSwrInterceptor] — JWT 첨부, SWR 캐시 즉시 반환(요청 단축), 401 리프레시
/// 2. [_ResponseCacheInterceptor] — 응답 캐시 저장/무효화, 오프라인 폴백
/// 3. [PerformanceInterceptor] — 실제 네트워크 응답시간 측정 (SWR로 단축된
///    요청까지 측정하면 안 되므로 반드시 1번 뒤에 위치)
class DioClient {
  DioClient._();

  /// 리프레시 토큰도 만료됐을 때 호출 → 로그인 화면으로 이동
  /// Kakao/Firebase 로그아웃까지 포함한 비동기 정리이므로 완료를 기다려야
  /// 다음 로그인 시도(예: 자동 로그인 직후 사용자가 바로 재로그인)와 경쟁하지 않음
  static Future<void> Function()? onSessionExpired;

  /// 계정 정지(403 banned) 시 호출 → 안내 다이얼로그 표시 후 로그아웃
  static void Function()? onUserBanned;

  /// 인터셉터 없이 토큰 갱신/재시도에만 사용하는 내부 Dio
  static final Dio _plainDio = Dio(BaseOptions(
    baseUrl: app_config.baseUrl,
    connectTimeout: _defaultConnectTimeout,
    receiveTimeout: _defaultReceiveTimeout,
  ));

  // refresh 중복 호출 방지: 진행 중인 refresh가 있으면 완료될 때까지 대기
  static bool _isRefreshing = false;
  static final List<Completer<String?>> _refreshWaiters = [];

  static Future<String?> _refreshAccessToken() async {
    final refreshToken = await TokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final response = await _plainDio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final newAccessToken = response.data['accessToken'] as String?;
    if (newAccessToken == null) throw Exception('accessToken missing');
    final newRefreshToken = response.data['refreshToken'] as String?;

    await TokenStore.saveAccessToken(newAccessToken);
    if (newRefreshToken != null) {
      await TokenStore.saveRefreshToken(newRefreshToken);
    }
    return newAccessToken;
  }

  /// SWR 백그라운드 갱신 전용 Dio.
  /// JWT 첨부 + 캐시 저장만 수행, SWR 로직 없음 (무한 재귀 방지).
  static final Dio _bgDio = Dio(
    BaseOptions(
      baseUrl: app_config.baseUrl,
      connectTimeout: _defaultConnectTimeout,
      receiveTimeout: _defaultReceiveTimeout,
      contentType: 'application/json',
    ),
  )..interceptors.add(
    InterceptorsWrapper(
      onRequest: (opts, handler) async {
        await _attachJwtIfAbsent(opts);
        handler.next(opts);
      },
      onResponse: (resp, handler) async {
        if (resp.requestOptions.method == 'GET' && resp.statusCode == 200) {
          await ApiCacheStore.put(resp.requestOptions.uri.toString(), resp.data);
        }
        handler.next(resp);
      },
    ),
  );

  /// 캐시 제공 후 백그라운드에서 실제 요청으로 캐시 갱신
  static Future<void> _bgRefresh(RequestOptions options) async {
    try {
      await _bgDio.get(options.path, queryParameters: options.queryParameters);
    } catch (_) {}
  }

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: app_config.baseUrl,
      // 페스티벌 현장 저신호 대응: 타임아웃 단축 (이전 10s/20s → 5s/12s)
      // 타임아웃 발생 시 캐시가 더 빨리 반환됨
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 12),
      contentType: 'application/json',
    ),
  )..interceptors.add(_AuthAndSwrInterceptor())
   ..interceptors.add(_ResponseCacheInterceptor())
   ..interceptors.add(PerformanceInterceptor());
}

/// 등록 순서 1번 — JWT 첨부, SWR 캐시 즉시 반환, 401 리프레시.
/// [DioClient]와 같은 파일에 두는 이유: refresh 상태(`_isRefreshing`,
/// `_refreshWaiters`)와 `_plainDio`/`_refreshAccessToken`을 공유해야 함.
class _AuthAndSwrInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    await _attachJwtIfAbsent(options);

    // SWR: GET 요청에 메모리 캐시가 있으면 즉시 반환 + 백그라운드 갱신
    // 첫 방문(캐시 없음)이나 오프라인 fallback은 _ResponseCacheInterceptor가 처리
    if (options.method == 'GET') {
      final cached = ApiCacheStore.getSync(options.uri.toString());
      if (cached != null) {
        DioClient._bgRefresh(options);
        return handler.resolve(Response(
          requestOptions: options,
          data: cached,
          statusCode: 200,
          extra: const {'fromCache': true},
        ));
      }
    }

    handler.next(options);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) async {
    if (error.response?.statusCode == 403) {
      final data = error.response?.data;
      if (data is Map && data['error'] == 'banned') {
        DioClient.onUserBanned?.call();
      }
      return handler.next(error);
    }

    if (error.response?.statusCode != 401) {
      return handler.next(error);
    }

    // refresh 진행 중이면 완료될 때까지 대기
    if (DioClient._isRefreshing) {
      final completer = Completer<String?>();
      DioClient._refreshWaiters.add(completer);
      final newToken = await completer.future;
      if (newToken == null) return handler.next(error);
      final opts = error.requestOptions;
      opts.headers['Authorization'] = 'Bearer $newToken';
      try {
        return handler.resolve(await DioClient._plainDio.fetch(opts));
      } on DioException catch (retryErr) {
        return handler.next(retryErr);
      }
    }

    DioClient._isRefreshing = true;
    String? newToken;
    try {
      newToken = await DioClient._refreshAccessToken();
    } catch (_) {
      // refresh 엔드포인트 오류 — newToken remains null
    } finally {
      DioClient._isRefreshing = false;
      for (final c in DioClient._refreshWaiters) {
        c.complete(newToken);
      }
      DioClient._refreshWaiters.clear();
    }

    // refresh 토큰 없음(null 반환) 또는 refresh 실패(예외) — 두 경우 모두 정리
    if (newToken == null) {
      await TokenStore.clear();
      await DioClient.onSessionExpired?.call();
      return handler.next(error);
    }
    final opts = error.requestOptions;
    opts.headers['Authorization'] = 'Bearer $newToken';
    try {
      return handler.resolve(await DioClient._plainDio.fetch(opts));
    } on DioException catch (retryErr) {
      return handler.next(retryErr);
    }
  }
}

/// 등록 순서 2번 — 응답 캐시 저장/무효화, 오프라인 폴백.
/// 반드시 [_AuthAndSwrInterceptor] 뒤에 등록되어야 함: SWR 단축 응답은 이미
/// 캐시된 데이터이므로 여기서 다시 저장할 필요가 없고, 이 인터셉터는 실제
/// 네트워크 응답에 대해서만 캐시 쓰기/무효화를 수행한다.
class _ResponseCacheInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) async {
    final method = response.requestOptions.method;
    final url = response.requestOptions.uri.toString();
    if (method == 'GET' && response.statusCode == 200) {
      await ApiCacheStore.put(url, response.data);
    } else if (method != 'GET') {
      await ApiCacheStore.invalidateFor(url);
    }
    handler.next(response);
  }

  @override
  void onError(DioException error, ErrorInterceptorHandler handler) async {
    // 네트워크 에러 + 메모리 캐시도 없을 때 → SharedPreferences에서 복구
    if (_isNetworkError(error) && error.requestOptions.method == 'GET') {
      final url = error.requestOptions.uri.toString();
      final cached = await ApiCacheStore.get(url);
      if (cached != null) {
        return handler.resolve(Response(
          requestOptions: error.requestOptions,
          data: cached,
          statusCode: 200,
          extra: const {'fromCache': true},
        ));
      }
    }
    handler.next(error);
  }
}
