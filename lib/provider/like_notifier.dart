import 'package:flutter/foundation.dart';

/// 좋아요 상태 변경 시 홈 화면 등 리스너에게 리프레시 신호를 보내는 이벤트 버스.
/// 데이터 전달 없이 변경 알림만 담당합니다.
class LikeNotifier extends ChangeNotifier {
  void notifyLikeChanged() => notifyListeners();
}
