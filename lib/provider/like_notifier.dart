import 'package:flutter/foundation.dart';

/// 좋아요 상태 변경 시 홈 화면 등 리스너에게 알림을 보내는 notifier
class LikeNotifier extends ChangeNotifier {
  void notifyLikeChanged() => notifyListeners();
}
