import 'dart:async';
import 'package:dio/dio.dart';
import '../auth/token_store.dart';
import '../config.dart' as app_config;
import 'api_cache_store.dart';

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

class DioClient {
  DioClient._();

  /// 리프레시 토큰도 만료됐을 때 호출 → 로그인 화면으로 이동
  static void Function()? onSessionExpired;

  /// 계정 정지(403 banned) 시 호출 → 안내 다이얼로그 표시 후 로그아웃
  static void Function()? onUserBanned;

  /// 인터셉터 없이 토큰 갱신/재시도에만 사용하는 내부 Dio
  static final Dio _plainDio = Dio(BaseOptions(baseUrl: app_config.baseUrl));

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

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: app_config.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 20),
      contentType: 'application/json',
    ),
  )..interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        // per-request Authorization이 이미 있으면 덮어쓰지 않음 (예: 카카오 액세스 토큰)
        if (!options.headers.containsKey('Authorization')) {
          final jwt = await TokenStore.readAccessToken();
          if (jwt != null && jwt.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $jwt';
          }
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode == 403) {
          final data = error.response?.data;
          if (data is Map && data['error'] == 'banned') {
            onUserBanned?.call();
          }
          return handler.next(error);
        }

        if (error.response?.statusCode != 401) {
          return handler.next(error);
        }

        // refresh 진행 중이면 완료될 때까지 대기
        if (_isRefreshing) {
          final completer = Completer<String?>();
          _refreshWaiters.add(completer);
          final newToken = await completer.future;
          if (newToken == null) return handler.next(error);
          final opts = error.requestOptions;
          opts.headers['Authorization'] = 'Bearer $newToken';
          return handler.resolve(await _plainDio.fetch(opts));
        }

        _isRefreshing = true;
        String? newToken;
        try {
          newToken = await _refreshAccessToken();
        } catch (_) {
          await TokenStore.clear();
          onSessionExpired?.call();
        } finally {
          _isRefreshing = false;
          // 대기 중인 요청에 결과 전달
          for (final c in _refreshWaiters) {
            c.complete(newToken);
          }
          _refreshWaiters.clear();
        }

        if (newToken == null) return handler.next(error);
        final opts = error.requestOptions;
        opts.headers['Authorization'] = 'Bearer $newToken';
        return handler.resolve(await _plainDio.fetch(opts));
      },
    ),
  )..interceptors.add(
    InterceptorsWrapper(
      onResponse: (response, handler) async {
        if (response.requestOptions.method == 'GET' &&
            response.statusCode == 200) {
          final url = response.requestOptions.uri.toString();
          await ApiCacheStore.put(url, response.data);
        }
        handler.next(response);
      },
      onError: (error, handler) async {
        if (_isNetworkError(error) &&
            error.requestOptions.method == 'GET') {
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
      },
    ),
  );
}