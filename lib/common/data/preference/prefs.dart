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
  static final postCreatedCount = PreferenceItem<int>('postCreatedCount', 0);
  static final artistFollowedCount = PreferenceItem<int>('artistFollowedCount', 0);
  static final reviewRequested = PreferenceItem<bool>('reviewRequested', false);
  static final showCurrentTimeLine = PreferenceItem<bool>('showCurrentTimeLine', true);
  static final recentSearches = PreferenceItem<List<String>>('recentSearches', []);
}
