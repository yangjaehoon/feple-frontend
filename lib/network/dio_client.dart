import 'package:dio/dio.dart';
import '../auth/token_store.dart';
import '../config.dart' as AppConfig;

class DioClient {
  DioClient._();

  static final Dio dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.baseUrl,
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
              final refreshDio = Dio(BaseOptions(baseUrl: AppConfig.baseUrl));
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

              // 원래 요청 재시도
              error.requestOptions.headers['Authorization'] = 'Bearer $newAccessToken';
              final retryResp = await dio.fetch(error.requestOptions);
              return handler.resolve(retryResp);
            } catch (_) {
              await TokenStore.clear();
            }
          }
        }
        handler.next(error);
      },
    ),
  );
}