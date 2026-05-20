import 'package:dio/dio.dart';

String? dioBackendMessage(Object e) {
  if (e is! DioException) return null;
  final data = e.response?.data;
  if (data is! Map) return null;
  return data['message'] as String?;
}
