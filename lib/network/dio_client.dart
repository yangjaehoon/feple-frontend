import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../auth/token_store.dart';
import '../common/util/forced_refresh.dart';
import '../common/util/request_scope.dart';
import '../common/util/response_parsing.dart';
import '../config.dart' as app_config;
import 'api_cache_store.dart';
import 'performance_interceptor.dart';

extension ResponseListExt on Response {
  /// 순수 배열/Spring Page(`content`) 어느 쪽이든 안전하게 모델 리스트로 변환.
  List<T> toModelList<T>(T Function(Map<String, dynamic>) fromJson) =>
      extractJsonList(data)
          .map((e) => fromJson(e as Map<String, dynamic>))
          .toList();
}

bool _isNetworkError(DioException e) {
  return e.response == null &&
      (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.unknown);
}

/// refresh 요청 실패가 "일시적"인지(타임아웃·연결오류·서버 5xx) 판단한다.
/// 일시적 실패는 refresh 토큰이 여전히 유효할 수 있으므로 세션을 유지한다.
bool _isTransientRefreshFailure(DioException e) {
  if (_isNetworkError(e)) return true;
  final status = e.response?.statusCode;
  return status != null && status >= 500;
}

enum _RefreshResultKind { refreshed, transientFailure, sessionExpired }

/// 401 → 토큰 갱신 시도의 결과. 대기 중이던 다른 401 요청들에도 이 값이 전달된다.
class _RefreshResult {
  const _RefreshResult.refreshed(this.token)
      : kind = _RefreshResultKind.refreshed;
  const _RefreshResult.transientFailure()
      : kind = _RefreshResultKind.transientFailure,
        token = null;
  const _RefreshResult.sessionExpired()
      : kind = _RefreshResultKind.sessionExpired,
        token = null;

  final _RefreshResultKind kind;
  final String? token;
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

  /// 계정 정지(403 banned) 시 호출 → 안내 다이얼로그 표시 후 로그아웃.
  /// [onSessionExpired]와 마찬가지로 비동기 정리(다이얼로그 + 로그아웃)를
  /// 포함하므로 완료를 기다릴 수 있도록 Future 반환 타입으로 통일.
  static Future<void> Function()? onUserBanned;

  /// 인터셉터 없이 토큰 갱신/재시도에만 사용하는 내부 Dio
  static final Dio _plainDio = Dio(BaseOptions(
    baseUrl: app_config.baseUrl,
    connectTimeout: _defaultConnectTimeout,
    receiveTimeout: _defaultReceiveTimeout,
  ));

  // refresh 중복 호출 방지: 진행 중인 refresh가 있으면 완료될 때까지 대기
  static bool _isRefreshing = false;
  static final List<Completer<_RefreshResult>> _refreshWaiters = [];

  // 리프레시 토큰까지 무효일 때의 세션 정리(토큰 삭제 + 로그인 화면 이동)를
  // 동시 다발 401에 대해 한 번만 수행하기 위한 in-flight 가드.
  // 이후 토큰 갱신이 다시 성공하면 null로 되돌려, 재로그인 후의 세션 만료도
  // 정상 처리되게 한다.
  static Future<void>? _sessionExpiryInFlight;

  @visibleForTesting
  static void resetForTesting({String? plainDioBaseUrl}) {
    _isRefreshing = false;
    _refreshWaiters.clear();
    _sessionExpiryInFlight = null;
    if (plainDioBaseUrl != null) {
      _plainDio.options.baseUrl = plainDioBaseUrl;
    }
  }

  /// 리프레시 토큰까지 만료됐을 때의 정리. [_sessionExpiryInFlight]로 감싸
  /// 동시 요청들이 이 정리를 중복 실행하지 않도록 한다.
  static Future<void> _handleSessionExpiry() async {
    try {
      await TokenStore.clear();
      await onSessionExpired?.call();
    } catch (e) {
      // 정리 실패 시 다음 401에서 재시도할 수 있도록 가드를 해제한다.
      _sessionExpiryInFlight = null;
      debugPrint('[DioClient] session expiry cleanup failed: $e');
    }
  }

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

    // 화면 dispose 시 취소되도록 Zone에 연결된 CancelToken을 부착.
    // 조회(GET)에만 적용한다 — mutation이 스코프 안에서 화면 이탈로 취소되면
    // 서버 상태가 불완전하게 남을 수 있음. (명시적으로 넘긴 cancelToken은 존중)
    if (options.method == 'GET') {
      options.cancelToken ??= ambientCancelToken;
    }

    // SWR: GET 요청에 메모리 캐시가 있으면 즉시 반환 + 백그라운드 갱신
    // 첫 방문(캐시 없음)이나 오프라인 fallback은 _ResponseCacheInterceptor가 처리
    // 단, 사용자가 명시적으로 최신화를 요청한 흐름(withForcedRefresh)이나
    // per-request로 refresh 플래그를 준 경우엔 캐시를 건너뛰고 실제 네트워크로 나감
    final forced = isForcedRefreshZone || options.extra['refresh'] == true;
    if (options.method == 'GET' && !forced) {
      final cached = ApiCacheStore.getSync(options.uri.toString());
      if (cached != null) {
        unawaited(DioClient._bgRefresh(options));
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
        await DioClient.onUserBanned?.call();
      }
      return handler.next(error);
    }

    if (error.response?.statusCode != 401) {
      return handler.next(error);
    }

    // 이미 세션 만료 정리가 진행/완료된 상태면 재시도 없이 원래 에러를 전파
    if (DioClient._sessionExpiryInFlight != null) {
      return handler.next(error);
    }

    // refresh 진행 중이면 완료될 때까지 대기 후 같은 결과를 공유
    if (DioClient._isRefreshing) {
      final completer = Completer<_RefreshResult>();
      DioClient._refreshWaiters.add(completer);
      await _applyRefreshResult(error, handler, await completer.future);
      return;
    }

    DioClient._isRefreshing = true;
    var result = const _RefreshResult.transientFailure();
    try {
      final token = await DioClient._refreshAccessToken();
      result = token == null
          ? const _RefreshResult.sessionExpired()
          : _RefreshResult.refreshed(token);
    } on DioException catch (e) {
      // 타임아웃·연결오류·5xx는 세션 유지, 그 외(401/400 등)는 만료로 간주
      result = _isTransientRefreshFailure(e)
          ? const _RefreshResult.transientFailure()
          : const _RefreshResult.sessionExpired();
    } catch (_) {
      // accessToken 누락 등 예상 못 한 응답 형태 — 만료로 간주
      result = const _RefreshResult.sessionExpired();
    } finally {
      DioClient._isRefreshing = false;
      final waiters = List<Completer<_RefreshResult>>.of(
        DioClient._refreshWaiters,
      );
      DioClient._refreshWaiters.clear();
      for (final c in waiters) {
        c.complete(result);
      }
    }

    await _applyRefreshResult(error, handler, result);
  }

  /// 토큰 갱신 결과에 따라 재시도 / 세션 유지 / 세션 만료 정리를 수행한다.
  Future<void> _applyRefreshResult(
    DioException error,
    ErrorInterceptorHandler handler,
    _RefreshResult result,
  ) async {
    switch (result.kind) {
      case _RefreshResultKind.refreshed:
        DioClient._sessionExpiryInFlight = null;
        await _retryWithToken(error, handler, result.token!);
      case _RefreshResultKind.transientFailure:
        // 리프레시 토큰은 여전히 유효할 수 있음 — 세션을 유지하고 원래 401을
        // 전파해 호출부/다음 요청이 재시도하도록 둔다.
        handler.next(error);
      case _RefreshResultKind.sessionExpired:
        await (DioClient._sessionExpiryInFlight ??=
            DioClient._handleSessionExpiry());
        handler.next(error);
    }
  }

  /// 새 액세스 토큰으로 헤더를 갱신해 원래 요청을 재시도한다.
  Future<void> _retryWithToken(
    DioException error,
    ErrorInterceptorHandler handler,
    String newToken,
  ) async {
    final opts = error.requestOptions;
    opts.headers['Authorization'] = 'Bearer $newToken';
    try {
      final response = await DioClient._plainDio.fetch(opts);
      // _plainDio는 인터셉터가 없어 _ResponseCacheInterceptor를 안 타므로
      // 재시도로 받은 GET 응답이 캐시에 남지 않는다 → 여기서 직접 기록
      if (opts.method == 'GET' && response.statusCode == 200) {
        await ApiCacheStore.put(opts.uri.toString(), response.data);
      }
      handler.resolve(response);
    } on DioException catch (retryErr) {
      handler.next(retryErr);
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
