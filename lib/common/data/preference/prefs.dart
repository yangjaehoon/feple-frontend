import 'package:feple/common/data/preference/item/preference_item.dart';
import 'package:feple/common/theme/custom_theme.dart';

class Prefs {
  static final appTheme =
      NullableEnumPreferenceItem<CustomTheme>('appTheme', CustomTheme.values);

  /// 온보딩 완료 여부는 유저 단위로 저장한다 — 같은 기기에서 다른 계정으로
  /// 로그인하면 각자 온보딩을 하고, 재로그인 시엔 다시 하지 않는다.
  /// (예전엔 전역 bool이라 로그아웃 때마다 false로 리셋해 재로그인 시 온보딩이
  /// 반복됐다.)
  static PreferenceItem<bool> onboardingCompletedFor(int userId) =>
      BoolPreferenceItem('onboardingCompleted_$userId', false);

  /// 마이그레이션 이전에 쓰이던 전역 온보딩 플래그.
  static final _legacyOnboardingCompleted =
      BoolPreferenceItem('onboardingCompleted', false);

  static final postCreatedCount = IntPreferenceItem('postCreatedCount', 0);
  static final artistFollowedCount = IntPreferenceItem('artistFollowedCount', 0);
  static final reviewRequested = BoolPreferenceItem('reviewRequested', false);
  static final showCurrentTimeLine =
      BoolPreferenceItem('showCurrentTimeLine', true);
  static final recentSearches =
      StringListPreferenceItem('recentSearches', const []);

  /// 이 유저가 온보딩을 마쳤는지 (순수 조회). 유저 단위 플래그가 없어도
  /// 레거시 전역 플래그가 남아 있으면(업데이트 전에 마친 유저) 완료로 본다.
  /// 레거시 플래그 정리는 [migrateLegacyOnboarding]이 담당한다.
  static bool isOnboardingCompleted(int userId) =>
      onboardingCompletedFor(userId).get() || _legacyOnboardingCompleted.get();

  /// 로그인 직후 1회 실행 — 레거시 전역 온보딩 플래그가 켜져 있으면 현재 유저의
  /// 유저 단위 플래그로 옮기고 전역 플래그를 끈다. 이렇게 소비해야 같은 기기의
  /// 다른 계정이 무임승차(온보딩 스킵)하지 않는다.
  static Future<void> migrateLegacyOnboarding(int userId) async {
    try {
      if (!_legacyOnboardingCompleted.get()) return;
      await onboardingCompletedFor(userId).set(true);
      await _legacyOnboardingCompleted.set(false);
    } catch (_) {
      // 다음 로그인에서 재시도됨 — 실패해도 조회는 레거시 플래그로 폴백.
      // 로그인 핫패스에서 호출되므로 어떤 이유로도 던지지 않는다.
    }
  }
}
