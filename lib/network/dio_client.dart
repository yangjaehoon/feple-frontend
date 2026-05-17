import 'dart:async';
import 'package:dio/dio.dart';
import '../auth/token_store.dart';
import '../config.dart' as app_config;

class DioClient {
  DioClient._();

  /// 리프레시 토큰도 만료됐을 때 호출 → 로그인 화면으로 이동
  static void Function()? onSessionExpired;

  /// 인터셉터 없이 토큰 갱신/재시도에만 사용하는 내부 Dio
  static final Dio _plainDio = Dio(BaseOptions(baseUrl: app_config.baseUrl));

  // refresh 중복 호출 방지: 진행 중인 refresh가 있으면 완료될 때까지 대기
  static bool _isRefreshing = false;
  static final List<Completer<String?>> _refreshWaiters = [];

  static Future<String?> _refreshAccessToken() async {
    final refreshToken = await TokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return null;

    final resp = await _plainDio.post(
      '/auth/refresh',
      data: {'refreshToken': refreshToken},
    );
    final newAccessToken = resp.data['accessToken'] as String?;
    if (newAccessToken == null) throw Exception('accessToken missing');
    final newRefreshToken = resp.data['refreshToken'] as String?;

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
        final jwt = await TokenStore.readAccessToken();
        if (jwt != null && jwt.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $jwt';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
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
  );
}