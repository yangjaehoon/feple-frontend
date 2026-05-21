import '../app_preferences.dart';

class PreferenceItem<T> {
  final T defaultValue;
  final String key;

  PreferenceItem(this.key, this.defaultValue);

  void call(T value) {
    AppPreferences.setValue<T>(this, value);
  }

  Future<void> set(T value) => AppPreferences.setValue<T>(this, value);

  T get() {
    return AppPreferences.getValue<T>(this);
  }

  Future<void> delete() => AppPreferences.deleteValue<T>(this);
}