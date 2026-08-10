import 'package:flutter/foundation.dart';

/// [action] 실패를 로그만 남기고 무시. 여러 정리/프리페치 단계 중 하나가
/// 실패해도 나머지 단계를 계속 진행해야 하는 곳에서 사용.
Future<void> runIgnoringErrors(String logTag, Future<dynamic> Function() action) async {
  try {
    await action();
  } catch (e) {
    debugPrint('$logTag: $e');
  }
}
