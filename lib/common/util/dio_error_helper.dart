import 'package:dio/dio.dart';

String? dioBackendMessage(Object e) {
  if (e is! DioException) return null;
  final data = e.response?.data;
  if (data is! Map) return null;
  return data['message'] as String?;
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
