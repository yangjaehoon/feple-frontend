import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/data/preference/item/nullable_preference_item.dart';
import 'package:feple/common/data/preference/item/preference_item.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  group('AppPreferences int/String/double/bool/List<String>', () {
    test('int 값을 저장하고 읽는다', () async {
      final item = PreferenceItem<int>('testInt', 0);

      await item.set(42);

      expect(item.get(), 42);
    });

    test('String 값을 저장하고 읽는다', () async {
      final item = PreferenceItem<String>('testString', '');

      await item.set('hello');

      expect(item.get(), 'hello');
    });

    test('double 값을 저장하고 읽는다', () async {
      final item = PreferenceItem<double>('testDouble', 0.0);

      await item.set(3.14);

      expect(item.get(), 3.14);
    });

    test('bool 값을 저장하고 읽는다', () async {
      final item = PreferenceItem<bool>('testBool', false);

      await item.set(true);

      expect(item.get(), isTrue);
    });

    test('List<String> 값을 저장하고 읽는다', () async {
      final item = PreferenceItem<List<String>>('testList', const []);

      await item.set(['a', 'b']);

      expect(item.get(), ['a', 'b']);
    });

    test('값이 없으면 기본값을 반환한다', () {
      final item = PreferenceItem<int>('neverSet', 99);

      expect(item.get(), 99);
    });
  });

  group('AppPreferences DateTime', () {
    test('DateTime 값을 ISO 문자열로 저장하고 파싱해서 읽는다', () async {
      final item = PreferenceItem<DateTime>('testDate', DateTime(2000));
      final date = DateTime(2026, 1, 5, 10, 30);

      await item.set(date);

      expect(item.get(), date);
    });
  });

  group('AppPreferences Enum', () {
    test('enum 값을 name으로 저장하고 읽는다', () async {
      final item = PreferenceItem<CustomTheme>('testTheme', CustomTheme.light);

      await item.set(CustomTheme.dark);

      expect(item.get(), CustomTheme.dark);
    });
  });

  group('NullablePreferenceItem', () {
    test('null로 설정하면 값이 제거되고 기본값을 반환한다', () async {
      final item = NullablePreferenceItem<CustomTheme>('testNullableTheme');

      await item.set(CustomTheme.dark);
      expect(item.get(), CustomTheme.dark);

      await item.set(null);
      expect(item.get(), isNull);
    });
  });
}
