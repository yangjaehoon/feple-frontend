import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../auth/token_store.dart';
import '../../common/exception/age_restricted_exception.dart';
import '../../common/exception/auth_exchange_exception.dart';
import '../../network/api_error_code.dart';
import '../../network/dio_client.dart';

/// 나이 확인 게이트의 서버 호출 — 첫 로그인 직후 생년월일을 제출한다.
class AgeVerificationClient {
  /// 만 14세 이상이면 정상 반환, 미만이면 서버가 계정을 파기하고
  /// [AgeRestrictedException]을 던진다.
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
      if (ApiErrorCode.isForbiddenWith(e, ApiErrorCode.ageRestricted)) {
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
}
