import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../auth/token_store.dart';
import '../../common/exception/age_restricted_exception.dart';
import '../../common/exception/auth_exchange_exception.dart';
import '../../model/user_model.dart' as app;
import '../../network/dio_client.dart';

/// Firebase/카카오 등 외부 인증 토큰을 앱 자체 JWT로 교환하고 저장하는 로직.
/// 어느 로그인 제공자를 쓰든 공통으로 필요한 서버 왕복이라 별도로 분리함.
class AuthTokenExchanger {
  Future<app.AppUser> exchangeFirebaseToken(String idToken, {String? nickname}) {
    final body = <String, dynamic>{'idToken': idToken};
    if (nickname != null) body['nickname'] = nickname;
    return _exchange(
      providerLabel: 'Firebase',
      request: () => DioClient.dio.post('/auth/firebase', data: body),
    );
  }

  Future<app.AppUser> exchangeKakaoToken(String accessToken) {
    return _exchange(
      providerLabel: '카카오',
      request: () => DioClient.dio.post(
        '/auth/kakao',
        options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
      ),
    );
  }

  /// 인증 제공자로 토큰을 교환하고 응답을 파싱. 실패 시 로그 남기고 공통 예외로 통일.
  Future<app.AppUser> _exchange({
    required String providerLabel,
    required Future<Response> Function() request,
  }) async {
    try {
      final response = await request();
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw AuthExchangeException('$providerLabel: response is not a JSON object');
      }
      await _saveTokens(data);
      return _parseUser(data);
    } on AuthExchangeException {
      rethrow;
    } on DioException catch (e) {
      debugPrint('[Auth] $providerLabel 서버 교환 실패: [${e.type.name}] ${e.response?.statusCode}');
      final respBody = e.response?.data;
      if (respBody is Map<String, dynamic>) {
        debugPrint('[Auth] $providerLabel 서버 메시지: ${respBody['message']}');
      }
      // 만 14세 미만으로 계정이 이미 파기된 사용자가 같은 계정으로 재로그인을
      // 시도하는 경우 — submitBirthDate()와 동일하게 구체적인 예외로 변환해,
      // 재로그인도 나이확인 최초 거부와 같은 안내 문구를 보여줄 수 있게 한다.
      if (e.response?.statusCode == 403 &&
          respBody is Map &&
          respBody['code'] == 'AGE_RESTRICTED') {
        throw AgeRestrictedException();
      }
      throw AuthExchangeException(
        '$providerLabel: server exchange failed (${e.response?.statusCode ?? e.type.name})',
      );
    } catch (e) {
      // 응답 파싱 단계(_saveTokens/_parseUser)의 예상치 못한 필드 누락·타입 불일치도
      // DioException과 동일하게 공통 예외로 통일 — raw exception이 그대로 새어나가지 않도록
      debugPrint('[Auth] $providerLabel 응답 처리 실패: $e');
      throw AuthExchangeException('$providerLabel: response processing failed');
    }
  }

  /// 나이 확인 게이트 — 생년월일 제출. 만 14세 이상이면 정상 반환,
  /// 미만이면 서버가 계정을 파기하고 [AgeRestrictedException]을 던진다.
  /// JwtAuthenticationFilter가 `/auth/**`를 건너뛰므로 액세스 토큰을 헤더로 직접 넘긴다.
  Future<void> submitBirthDate(DateTime birthDate) async {
    final token = await TokenStore.readAccessToken();
    if (token == null) {
      throw AuthExchangeException('age-verification: no access token');
    }
    final iso = birthDate.toIso8601String().split('T').first; // yyyy-MM-dd
    try {
      await DioClient.dio.post(
        '/auth/age-verification',
        data: {'birthDate': iso},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      if (e.response?.statusCode == 403 &&
          data is Map &&
          data['code'] == 'AGE_RESTRICTED') {
        throw AgeRestrictedException();
      }
      debugPrint(
        '[Auth] 나이 확인 실패: [${e.type.name}] ${e.response?.statusCode}',
      );
      throw AuthExchangeException(
        'age-verification failed (${e.response?.statusCode ?? e.type.name})',
      );
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
    if (userJson is! Map<String, dynamic>) {
      throw AuthExchangeException('response has no user object');
    }
    return app.AppUser.fromJson(userJson);
  }
}
