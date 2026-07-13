import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';

import '../../auth/token_store.dart';
import '../../model/user_model.dart' as app;
import '../../network/dio_client.dart';

/// Firebase/카카오 등 외부 인증 토큰을 앱 자체 JWT로 교환하고 저장하는 로직.
/// 어느 로그인 제공자를 쓰든 공통으로 필요한 서버 왕복이라 별도로 분리함.
class AuthTokenExchanger {
  Future<app.AppUser> exchangeFirebaseToken(String idToken, {String? nickname}) async {
    final body = <String, dynamic>{'idToken': idToken};
    if (nickname != null) body['nickname'] = nickname;

    try {
      final response = await DioClient.dio.post('/auth/firebase', data: body);
      final data = response.data;
      if (data is! Map<String, dynamic>) throw Exception('auth_err_auth_failed'.tr());
      await _saveTokens(data);
      return _parseUser(data);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final respBody = e.response?.data;
      if (respBody is Map<String, dynamic>) {
        debugPrint('[Auth] Firebase 서버 오류 ($status): ${respBody['message']}');
        throw Exception('auth_err_auth_failed'.tr());
      }
      debugPrint('[Auth] Firebase 요청 실패 (${e.type.name}, status=$status)');
      throw Exception('auth_err_auth_failed'.tr());
    }
  }

  Future<app.AppUser> exchangeKakaoToken(String accessToken) async {
    try {
      final response = await DioClient.dio.post(
        '/auth/kakao',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) throw Exception('auth_err_auth_failed'.tr());
      await _saveTokens(data);
      return _parseUser(data);
    } on DioException catch (e) {
      debugPrint('[Auth] 카카오 서버 교환 실패: [${e.type.name}] ${e.response?.statusCode}');
      final respBody = e.response?.data;
      if (respBody is Map<String, dynamic>) {
        debugPrint('[Auth] 카카오 서버 메시지: ${respBody['message']}');
        throw Exception('auth_err_auth_failed'.tr());
      }
      throw Exception('auth_err_auth_failed'.tr());
    }
  }

  Future<void> revokeRefreshToken(String refreshToken) async {
    try {
      await DioClient.dio.post('/auth/logout', data: {'refreshToken': refreshToken});
    } catch (e) {
      debugPrint('[Auth] 리프레시 토큰 서버 취소 실패: $e');
    }
  }

  Future<void> _saveTokens(Map<String, dynamic> json) async {
    await TokenStore.saveAccessToken(json['accessToken'] as String);
    final refreshToken = json['refreshToken'] as String?;
    if (refreshToken != null) await TokenStore.saveRefreshToken(refreshToken);
  }

  app.AppUser _parseUser(Map<String, dynamic> json) {
    final userJson = json['user'];
    if (userJson is! Map<String, dynamic>) throw Exception('auth_err_auth_failed'.tr());
    return app.AppUser.fromJson(userJson);
  }
}
