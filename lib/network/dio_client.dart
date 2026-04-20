import 'package:dio/dio.dart';
import '../auth/token_store.dart';
import '../config.dart' as app_config;

class DioClient {
  DioClient._();

  /// 리프레시 토큰도 만료됐을 때 호출 → 로그인 화면으로 이동
  static void Function()? onSessionExpired;

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
        if (error.response?.statusCode == 401) {
          final refreshToken = await TokenStore.readRefreshToken();
          if (refreshToken != null && refreshToken.isNotEmpty) {
            try {
              final refreshDio = Dio(BaseOptions(baseUrl: app_config.baseUrl));
              final resp = await refreshDio.post(
                '/auth/refresh',
                data: {'refreshToken': refreshToken},
              );
              final newAccessToken = resp.data['accessToken'] as String;
              final newRefreshToken = resp.data['refreshToken'] as String?;

              await TokenStore.saveAccessToken(newAccessToken);
              if (newRefreshToken != null) {
                await TokenStore.saveRefreshToken(newRefreshToken);
              }

              // 원래 요청 재시도 (인터셉터를 타지 않는 별도 Dio로 실행)
              final retryDio = Dio(BaseOptions(baseUrl: app_config.baseUrl));
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $newAccessToken';
              final retryResp = await retryDio.fetch(opts);
              return handler.resolve(retryResp);
            } catch (_) {
              await TokenStore.clear();
              onSessionExpired?.call();
            }
          }
        }
        handler.next(error);
      },
    ),
  );
}