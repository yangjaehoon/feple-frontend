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

/// [context]가 속한 라우트를 [result]와 함께 닫는다.
///
/// `Navigator.pop`은 **최상단** 라우트를 닫는다 — 비동기 작업이 끝나기를 기다리는
/// 사이에 확인 다이얼로그(취소 확인·밴 안내)나 딥링크/FCM 화면이 위로 올라와
/// 있으면 내 화면이 아니라 그쪽이 닫히고, 그 라우트가 기대하는 결과 타입과 맞지
/// 않는 값이 전달돼 `didPop`에서 TypeError까지 난다. 위에 쌓인 라우트를 먼저
/// 걷어낸 뒤 내 라우트를 닫는다.
///
/// 닫으면 빈 스택이 되는 최초 라우트면 아무것도 하지 않는다.
void popRouteWithResult<T>(BuildContext context, T result) {
  final navigator = Navigator.of(context);
  final route = ModalRoute.of(context);
  if (route == null || route.isFirst) return;
  if (!route.isCurrent) {
    navigator.popUntil((candidate) => candidate == route);
  }
  navigator.pop(result);
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
