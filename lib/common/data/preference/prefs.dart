import 'dart:async';

import 'package:feple/common/data/preference/item/nullable_preference_item.dart';
import 'package:feple/common/data/preference/item/preference_item.dart';
import 'package:feple/common/theme/custom_theme.dart';

class Prefs {
  static final appTheme = NullablePreferenceItem<CustomTheme>('appTheme');

  /// 온보딩 완료 여부는 유저 단위로 저장한다 — 같은 기기에서 다른 계정으로
  /// 로그인하면 각자 온보딩을 하고, 재로그인 시엔 다시 하지 않는다.
  /// (예전엔 전역 bool이라 로그아웃 때마다 false로 리셋해 재로그인 시 온보딩이
  /// 반복됐다.)
  static PreferenceItem<bool> onboardingCompletedFor(int userId) =>
      PreferenceItem<bool>('onboardingCompleted_$userId', false);

  /// 마이그레이션 이전에 쓰이던 전역 온보딩 플래그. 직접 읽지 말고
  /// [isOnboardingCompleted]를 통해서만 접근한다.
  static final _legacyOnboardingCompleted =
      PreferenceItem<bool>('onboardingCompleted', false);

  /// 이 유저가 온보딩을 마쳤는지. 유저 단위 플래그가 없고 레거시 전역 플래그가
  /// true면(= 업데이트 전에 이미 온보딩을 마친 유저) 이 유저를 완료로 승격시키고
  /// 레거시 플래그는 소비한다 — 업데이트 후 기존 유저가 온보딩을 다시 하지 않도록.
  static bool isOnboardingCompleted(int userId) {
    final perUser = onboardingCompletedFor(userId);
    if (perUser.get()) return true;
    if (_legacyOnboardingCompleted.get()) {
      unawaited(perUser.set(true));
      unawaited(_legacyOnboardingCompleted.set(false));
      return true;
    }
    return false;
  }
  static final postCreatedCount = PreferenceItem<int>('postCreatedCount', 0);
  static final artistFollowedCount = PreferenceItem<int>('artistFollowedCount', 0);
  static final reviewRequested = PreferenceItem<bool>('reviewRequested', false);
  static final showCurrentTimeLine = PreferenceItem<bool>('showCurrentTimeLine', true);
  static final recentSearches = PreferenceItem<List<String>>('recentSearches', []);
}
