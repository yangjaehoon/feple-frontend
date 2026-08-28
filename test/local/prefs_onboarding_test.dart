import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/data/preference/prefs.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _legacyKey = 'AppPreference.onboardingCompleted';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  setUp(() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_legacyKey);
    await Prefs.onboardingCompletedFor(7).set(false);
    await Prefs.onboardingCompletedFor(8).set(false);
  });

  group('isOnboardingCompleted (순수 조회)', () {
    test('유저 단위 플래그가 true면 완료', () async {
      await Prefs.onboardingCompletedFor(7).set(true);
      expect(Prefs.isOnboardingCompleted(7), true);
    });

    test('유저 플래그도 레거시도 없으면 미완료', () {
      expect(Prefs.isOnboardingCompleted(7), false);
    });

    test('레거시 전역 플래그만 있어도 완료로 본다 (아직 소비 전)', () async {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(_legacyKey, true);
      expect(Prefs.isOnboardingCompleted(7), true);
      // 순수 조회는 write하지 않는다
      expect(sp.getBool(_legacyKey), true);
      expect(Prefs.onboardingCompletedFor(7).get(), false);
    });
  });

  group('migrateLegacyOnboarding', () {
    test('레거시 true → 현재 유저를 완료로 승격하고 레거시는 소비', () async {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool(_legacyKey, true);

      await Prefs.migrateLegacyOnboarding(7);

      expect(Prefs.onboardingCompletedFor(7).get(), true);
      expect(sp.getBool(_legacyKey), false);
      // 다른 계정은 무임승차 못 함
      expect(Prefs.isOnboardingCompleted(8), false);
    });

    test('레거시가 이미 없으면 아무것도 하지 않는다', () async {
      await Prefs.migrateLegacyOnboarding(7);
      expect(Prefs.onboardingCompletedFor(7).get(), false);
    });
  });
}
