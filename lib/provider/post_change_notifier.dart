import 'package:flutter/foundation.dart';

/// 게시글 작성/수정/삭제 시 목록 화면에 리프레시 신호를 보내는 이벤트 버스.
/// 데이터 전달 없이 변경 알림만 담당합니다.
class PostChangeNotifier extends ChangeNotifier {
  void notifyPostChanged() => notifyListeners();
}
