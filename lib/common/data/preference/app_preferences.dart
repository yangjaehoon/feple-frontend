import 'package:feple/common/theme/custom_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'item/preference_item.dart';

export 'package:get/get_rx/get_rx.dart';
export 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';

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

  static Future<void> setValue<T>(PreferenceItem<T> item, T? value) async {
    final String key = getPrefKey(item);
    final isNullable = checkIsNullable<T>();

    if (isNullable && value == null) {
      //null을 세팅한다는 것은 값을 지운다는 의미로 해석. 필요에 따라 변경해서 쓰시면 되요.
      await _prefs.remove(key);
      return;
    }

    if (isNullable) {
      switch (T.toString()) {
        case "int?":
          await _prefs.setInt(key, value as int);
        case "String?":
          await _prefs.setString(key, value as String);
        case "double?":
          await _prefs.setDouble(key, value as double);
        case "bool?":
          await _prefs.setBool(key, value as bool);
        case "List<String>?":
          await _prefs.setStringList(key, value as List<String>);
        case "DateTime?":
          await _prefs.setString(key, (value as DateTime).toIso8601String());
        default:
          if (value is Enum) {
            await _prefs.setString(key, value.name);
          } else {
            throw Exception('$T 타입에 대한 저장 transform 함수를 추가 해주세요.');
          }
      }
    } else {
      switch (T) {
        case const (int):
          await _prefs.setInt(key, value as int);
        case const (String):
          await _prefs.setString(key, value as String);
        case const (double):
          await _prefs.setDouble(key, value as double);
        case const (bool):
          await _prefs.setBool(key, value as bool);
        case const (List<String>):
          await _prefs.setStringList(key, value as List<String>);
        case const (DateTime):
          await _prefs.setString(key, (value as DateTime).toIso8601String());
        default:
          if (value is Enum) {
            await _prefs.setString(key, value.name);
          } else {
            throw Exception('$T 타입에 대한 저장 transform 함수를 추가 해주세요.');
          }
      }
    }
  }

  static Future<void> deleteValue<T>(PreferenceItem<T> item) async {
    final String key = getPrefKey(item);
    await _prefs.remove(key);
  }

  static T getValue<T>(PreferenceItem<T> item) {
    final String key = getPrefKey(item);
    switch (T) {
      case const (int):
        return _prefs.getInt(key) as T? ?? item.defaultValue;
      case const (String):
        return _prefs.getString(key) as T? ?? item.defaultValue;
      case const (double):
        return _prefs.getDouble(key) as T? ?? item.defaultValue;
      case const (bool):
        return _prefs.getBool(key) as T? ?? item.defaultValue;
      case const (List<String>):
        return _prefs.getStringList(key) as T? ?? item.defaultValue;
      default:
        return transform(T, _prefs.getString(key)) ?? item.defaultValue;
    }
  }

  static T? transform<T>(Type t, String? value) {
    if (value == null) {
      return null;
    }

    bool isNullableType = checkIsNullable<T>();
    if (isNullableType) {
      switch (t.toString()) {
        case "CustomTheme?":
          return CustomTheme.values.asNameMap()[value] as T?;
        case "DateTime?":
          return DateTime.parse(value) as T?;
        default:
          throw Exception('$t 타입에 대한 transform 함수를 추가 해주세요.');
      }
    } else {
      switch (t) {
        case const (CustomTheme):
          return CustomTheme.values.asNameMap()[value] as T?;
        case const (DateTime):
          return DateTime.parse(value) as T?;
        default:
          throw Exception('$t 타입에 대한 transform 함수를 추가 해주세요.');
      }
    }
  }
}
