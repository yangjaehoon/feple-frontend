import 'package:flutter/foundation.dart';

/// 상태 없는 이벤트 신호 전달용 ValueNotifier.
/// ChangeNotifier 기반 Provider 없이 앱 전역 이벤트를 경량으로 전달합니다.
class AppEvents {
  AppEvents._();

  /// 좋아요 상태 변경 시 신호 (값 자체는 무의미, 변경 시 리스너 실행)
  static final likeChanged = ValueNotifier<int>(0);

  /// 게시글 작성/수정/삭제 시 신호 (값 자체는 무의미, 변경 시 리스너 실행)
  static final postChanged = ValueNotifier<int>(0);
}
