import '../app_preferences.dart';

class PreferenceItem<T> {
  final T defaultValue;
  final String key;

  PreferenceItem(this.key, this.defaultValue);

  Future<void> set(T value) => AppPreferences.setValue<T>(this, value);

  T get() {
    return AppPreferences.getValue<T>(this);
  }
}