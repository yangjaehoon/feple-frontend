import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/notification_service.dart';
import 'package:flutter/foundation.dart';

class NotificationCountNotifier extends SafeChangeNotifier {
  final _service = sl<NotificationService>();

  int _count = 0;
  int get count => _count;

  Future<void> load() async {
    try {
      _count = await _service.getUnreadCount();
      safeNotify();
    } catch (e) {
      debugPrint('[NotificationCount] 로드 실패: $e');
    }
  }

  void clear() {
    _count = 0;
    safeNotify();
  }
}
