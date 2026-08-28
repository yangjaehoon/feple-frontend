import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/data/preference/item/preference_item.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    // _prefs는 late final이라 init은 프로세스당 1회만 가능 — stale 값도 여기서 심는다.
    SharedPreferences.setMockInitialValues({
      '${AppPreferences.prefix}staleTheme': 'renamedValue',
    });
    await AppPreferences.init();
  });

  group('타입별 PreferenceItem', () {
    test('int 값을 저장하고 읽는다', () async {
      final item = IntPreferenceItem('testInt', 0);

      await item.set(42);

      expect(item.get(), 42);
    });

    test('String 값을 저장하고 읽는다', () async {
      final item = StringPreferenceItem('testString', '');

      await item.set('hello');

      expect(item.get(), 'hello');
    });

    test('bool 값을 저장하고 읽는다', () async {
      final item = BoolPreferenceItem('testBool', false);

      await item.set(true);

      expect(item.get(), isTrue);
    });

    test('List<String> 값을 저장하고 읽는다', () async {
      final item = StringListPreferenceItem('testList', const []);

      await item.set(['a', 'b']);

      expect(item.get(), ['a', 'b']);
    });

    test('값이 없으면 기본값을 반환한다', () {
      final item = IntPreferenceItem('neverSet', 99);

      expect(item.get(), 99);
    });
  });

  group('NullableEnumPreferenceItem', () {
    test('enum 값을 name으로 저장하고 읽는다', () async {
      final item =
          NullableEnumPreferenceItem<CustomTheme>('testTheme', CustomTheme.values);

      await item.set(CustomTheme.dark);

      expect(item.get(), CustomTheme.dark);
    });

    test('null로 설정하면 값이 제거되고 기본값(null)을 반환한다', () async {
      final item = NullableEnumPreferenceItem<CustomTheme>(
        'testNullableTheme',
        CustomTheme.values,
      );

      await item.set(CustomTheme.dark);
      expect(item.get(), CustomTheme.dark);

      await item.set(null);
      expect(item.get(), isNull);
    });

    test('저장된 문자열이 어떤 enum 상수와도 맞지 않으면 null로 폴백한다', () {
      final item = NullableEnumPreferenceItem<CustomTheme>(
        'staleTheme',
        CustomTheme.values,
      );

      expect(item.get(), isNull);
    });
  });
}
