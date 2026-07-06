import 'package:feple/common/theme/custom_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'item/preference_item.dart';

class AppPreferences {
  static const String prefix = 'AppPreference.';

  static late final SharedPreferences _prefs;

  static String getPrefKey(PreferenceItem item) {
    return '${AppPreferences.prefix}${item.key}';
  }

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    return;
  }

  static bool checkIsNullable<T>() => null is T;

  // `T`가 nullable(`int?` 등)이어도 `T.toString()`은 "int?"처럼 접미사가 붙을 뿐이라
  // '?'만 제거하면 nullable/non-nullable 타입을 하나의 매칭 로직으로 처리할 수 있음
  static String _baseTypeName(Type t) => t.toString().replaceAll('?', '');

  static Future<void> setValue<T>(PreferenceItem<T> item, T? value) async {
    final String key = getPrefKey(item);

    if (checkIsNullable<T>() && value == null) {
      //null을 세팅한다는 것은 값을 지운다는 의미로 해석. 필요에 따라 변경해서 쓰시면 되요.
      await _prefs.remove(key);
      return;
    }

    switch (_baseTypeName(T)) {
      case 'int':
        await _prefs.setInt(key, value as int);
      case 'String':
        await _prefs.setString(key, value as String);
      case 'double':
        await _prefs.setDouble(key, value as double);
      case 'bool':
        await _prefs.setBool(key, value as bool);
      case 'List<String>':
        await _prefs.setStringList(key, value as List<String>);
      case 'DateTime':
        await _prefs.setString(key, (value as DateTime).toIso8601String());
      default:
        if (value is Enum) {
          await _prefs.setString(key, value.name);
        } else {
          throw Exception('$T 타입에 대한 저장 transform 함수를 추가 해주세요.');
        }
    }
  }

  static Future<void> deleteValue<T>(PreferenceItem<T> item) async {
    final String key = getPrefKey(item);
    await _prefs.remove(key);
  }

  static T getValue<T>(PreferenceItem<T> item) {
    final String key = getPrefKey(item);
    switch (_baseTypeName(T)) {
      case 'int':
        return _prefs.getInt(key) as T? ?? item.defaultValue;
      case 'String':
        return _prefs.getString(key) as T? ?? item.defaultValue;
      case 'double':
        return _prefs.getDouble(key) as T? ?? item.defaultValue;
      case 'bool':
        return _prefs.getBool(key) as T? ?? item.defaultValue;
      case 'List<String>':
        return _prefs.getStringList(key) as T? ?? item.defaultValue;
      default:
        return transform(T, _prefs.getString(key)) ?? item.defaultValue;
    }
  }

  static T? transform<T>(Type t, String? value) {
    if (value == null) {
      return null;
    }

    switch (_baseTypeName(t)) {
      case 'CustomTheme':
        return CustomTheme.values.asNameMap()[value] as T?;
      case 'DateTime':
        return DateTime.parse(value) as T?;
      default:
        throw Exception('$t 타입에 대한 transform 함수를 추가 해주세요.');
    }
  }
}
