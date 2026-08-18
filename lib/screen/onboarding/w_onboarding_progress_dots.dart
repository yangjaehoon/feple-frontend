import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

// 온보딩 전체 단계 수 (인포 3 + 아티스트 선택 + 페스티벌 선택) — 온보딩 흐름에
// 포함된 화면들(OnboardingScreen/ArtistPickScreen/FestivalPickScreen)이 공유.
const onboardingTotalSteps = 5;

/// 온보딩 진행 상태 도트 — 인포 페이지와 아티스트/페스티벌 선택 페이지가
/// activeIndex만 다르게 공유.
Widget buildOnboardingProgressDots(
  AbstractThemeColors colors, {
  required int activeIndex,
}) {
  return Row(
    key: const Key('onboardingProgressDots'),
    mainAxisSize: MainAxisSize.min,
    children: List.generate(onboardingTotalSteps, (index) {
      final isActive = index == activeIndex;
      return AnimatedContainer(
        duration: AppDimens.animNormal,
        margin: const EdgeInsets.only(right: 8),
        width: isActive ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: isActive ? colors.activate : colors.inActivate,
          borderRadius: BorderRadius.circular(AppDimens.radiusXs),
        ),
      );
    }),
  );
}
