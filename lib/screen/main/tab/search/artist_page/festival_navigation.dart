import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/injection.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';

/// 축제 ID로 상세 정보를 조회해 [FestivalInformationFragment]로 이동한다.
/// 실패 시 에러 스낵바를 보여준다. [awaitNavigation]이 true면 화면에서 돌아올
/// 때까지 대기하고, false(기본값)면 push만 발생시키고 바로 반환한다.
Future<void> navigateToFestivalById(
  BuildContext context,
  int festivalId, {
  bool awaitNavigation = false,
}) async {
  try {
    final festival = await sl<FestivalService>().fetchById(festivalId);
    if (!context.mounted) return;
    final push = Navigator.push(
      context,
      SlideRoute(builder: (_) => FestivalInformationFragment(poster: festival)),
    );
    if (awaitNavigation) {
      await push;
    } else {
      unawaited(push);
    }
  } catch (e) {
    debugPrint('festival fetch error: $e');
    if (context.mounted) {
      context.showErrorSnackbar(fetchFailureText(e));
    }
  }
}

/// "탭 → fetchById → 화면 전환까지 아무 피드백 없이 멈춰 보이는 걸 방지" 패턴 공용화.
/// [navigatingFestivalId]로 현재 로딩 중인 festivalId를 노출해, 그 항목에만
/// 로딩 인디케이터를 표시하고 재탭은 무시할 수 있다.
mixin FestivalNavigationGuard<T extends StatefulWidget> on State<T> {
  int? _navigatingFestivalId;

  int? get navigatingFestivalId => _navigatingFestivalId;

  Future<void> navigateToFestival(int festivalId) async {
    if (_navigatingFestivalId != null) return;
    setState(() => _navigatingFestivalId = festivalId);
    try {
      await navigateToFestivalById(context, festivalId);
    } finally {
      if (mounted) setState(() => _navigatingFestivalId = null);
    }
  }
}
