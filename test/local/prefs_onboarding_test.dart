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

  test('유저 단위 플래그가 true면 완료', () async {
    await Prefs.onboardingCompletedFor(7).set(true);
    expect(Prefs.isOnboardingCompleted(7), true);
  });

  test('유저 플래그도 레거시도 없으면 미완료', () {
    expect(Prefs.isOnboardingCompleted(7), false);
  });

  test('레거시 전역 플래그 true → 현재 유저를 완료로 승격하고 레거시는 소비', () async {
    final sp = await SharedPreferences.getInstance();
    await sp.setBool(_legacyKey, true); // 업데이트 전 온보딩을 마친 상태

    expect(Prefs.isOnboardingCompleted(7), true);
    expect(Prefs.onboardingCompletedFor(7).get(), true); // per-user로 승격됨
    expect(Prefs.isOnboardingCompleted(8), false); // 레거시 소비 → 무임승차 불가
  });
}
