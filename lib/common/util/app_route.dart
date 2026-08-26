import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/cupertino.dart';

/// 오른쪽에서 슬라이드 인 하는 페이지 전환 라우트.
/// MaterialPageRoute의 Android 기본 동작(아래에서 위로) 대신
/// iOS/Toss/Baemin 스타일의 수평 슬라이드를 모든 플랫폼에 적용합니다.
/// CupertinoRouteTransitionMixin을 사용해 iOS 엣지 스와이프 뒤로가기 제스처도 함께 지원합니다.
class SlideRoute<T> extends PageRoute<T> with CupertinoRouteTransitionMixin<T> {
  final WidgetBuilder builder;

  SlideRoute({required this.builder, super.settings});

  @override
  Widget buildContent(BuildContext context) => builder(context);

  @override
  Duration get transitionDuration => AppDimens.animSlideIn;

  @override
  Duration get reverseTransitionDuration => AppDimens.animSlideOut;

  @override
  String? get title => null;

  @override
  bool get maintainState => true;
}
