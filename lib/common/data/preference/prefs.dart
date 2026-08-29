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

  /// 온보딩에서 좋아요/팔로우를 마친 뒤, 다음 홈 진입이 캐시 우선 렌더를
  /// 건너뛰고 강제 새로고침하도록 하는 1회용 플래그 (유저 단위).
  /// 온보딩 중에는 홈이 아직 없어 좋아요 이벤트를 못 듣고, 스플래시가
  /// 저장해 둔 낡은 스냅샷을 홈이 먼저 렌더하는 문제를 막는다.
  ///
  /// 생명주기: [HomeStateNotifier.init]이 읽는 즉시 false로 되돌려 소비한다.
  /// 홈이 한 번도 안 뜬 채 로그아웃하면 키가 true로 남지만, 재로그인 시 첫
  /// 홈 로드에서 소비되므로 자기수렴한다(불필요한 강제 새로고침 1회뿐).
  /// [onboardingCompletedFor]와 마찬가지로 유저 단위라 로그아웃 시 리셋하지
  /// 않는다 — 같은 기기의 다른 계정에 영향 없음.
  static PreferenceItem<bool> pendingHomeForceRefreshFor(int userId) =>
      BoolPreferenceItem('pendingHomeForceRefresh_$userId', false);

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
