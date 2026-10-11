/// 서버 `ErrorResponse.code` 값 중 클라이언트가 분기에 쓰는 것들.
/// 백엔드 `ErrorCode` enum 이름과 같아야 한다.
abstract final class ApiErrorCode {
  static const userBanned = 'USER_BANNED';
  static const ageRestricted = 'AGE_RESTRICTED';
  static const ageVerificationRequired = 'AGE_VERIFICATION_REQUIRED';

  /// 응답 본문의 `code`가 [code]인지.
  static bool matches(Object? responseData, String code) =>
      responseData is Map && responseData['code'] == code;
}

/// 정지 응답을 호출부가 직접 처리하는 요청에 붙이는 `RequestOptions.extra` 키 —
/// 붙어 있으면 인터셉터가 전역 정지 다이얼로그를 띄우지 않는다.
const handlesUserBanExtraKey = 'handlesUserBan';
