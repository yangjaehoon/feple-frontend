import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Material, MaterialType;

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

/// [App.navigatorKey](최상위 루트 Navigator) 위로 화면을 push할 때 쓴다.
///
/// 탭 내부 네비게이션(각 탭의 중첩 Navigator)과 달리 루트 Navigator는
/// MainScreen의 Scaffold 바깥에 있어 Material 조상이 없다 — 목적지 화면이
/// 자체 Scaffold를 갖고 있지 않으면(예: FestivalInformationFragment) 그
/// 안의 InkWell 계열 위젯이 "No Material widget found"로 깨진다(딥링크·FCM
/// 알림 탭으로 진입 시 게시판 미리보기 섹션이 깨지는 것을 실측으로 확인).
/// `MaterialType.transparency`라 배경색 등 시각적 변화 없이 Material
/// 조상만 보강한다.
Route<T> rootNavigatorRoute<T>(Widget screen) => SlideRoute<T>(
      builder: (_) => Material(type: MaterialType.transparency, child: screen),
    );
