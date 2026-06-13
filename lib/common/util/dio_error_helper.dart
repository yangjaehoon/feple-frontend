import 'package:dio/dio.dart';
import 'package:feple/common/exception/banned_word_exception.dart';

bool isDioConflict(Object e) {
  return e is DioException && e.response?.statusCode == 409;
}

/// 400 BAD_WORD 응답이면 [BannedWordException] throw, 아니면 아무것도 하지 않음.
/// 서비스 레이어의 DioException catch 블록에서 rethrow 전에 호출.
void throwIfBannedWord(DioException e, {String defaultField = 'content'}) {
  if (e.response?.statusCode == 400) {
    final data = e.response?.data;
    if (data is Map && data['code'] == 'BAD_WORD') {
      throw BannedWordException(data['field'] as String? ?? defaultField);
    }
  }
}

/// 타임아웃·연결 오류면 'connection_error', 그 외(서버 에러 포함)면 [operationErrorKey] 반환.
String networkAwareErrorKey(Object e, String operationErrorKey) {
  if (e is DioException) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.connectionError:
        return 'connection_error';
      default:
        break;
    }
  }
  return operationErrorKey;
}
