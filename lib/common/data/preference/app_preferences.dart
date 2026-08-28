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

  static Future<void> setValue<T>(PreferenceItem<T> item, T? value) async {
    if (value == null) {
      // null을 세팅한다는 것은 값을 지운다는 의미로 해석.
      await _prefs.remove(getPrefKey(item));
      return;
    }
    await item.writeValue(_prefs, value);
  }

  static T getValue<T>(PreferenceItem<T> item) =>
      item.readValue(_prefs) ?? item.defaultValue;
}
