import 'package:shared_preferences/shared_preferences.dart';

import '../app_preferences.dart';

/// SharedPreferences에 저장되는 값 하나.
///
/// 저장/조회 방식은 각 서브클래스가 스스로 정의한다 — 예전처럼 `T.toString()`
/// 문자열로 분기하지 않으므로, 릴리스 빌드의 `--obfuscate`로 타입 이름이 바뀌어도
/// 안전하고, 잘못된 타입은 컴파일 단계에서 걸린다.
abstract class PreferenceItem<T> {
  PreferenceItem(this.key, this.defaultValue);

  final String key;
  final T defaultValue;

  /// `AppPreferences.prefix`가 붙은 실제 저장 키.
  String get storageKey => AppPreferences.getPrefKey(this);

  /// 저장된 값을 읽는다. 저장된 적이 없으면 null (호출부가 기본값으로 대체).
  T? readValue(SharedPreferences prefs);

  /// 값을 저장한다. (null 저장 = 삭제는 [AppPreferences.setValue]가 먼저 처리)
  Future<void> writeValue(SharedPreferences prefs, T value);

  Future<void> set(T value) => AppPreferences.setValue<T>(this, value);

  T get() => AppPreferences.getValue<T>(this);
}

class IntPreferenceItem extends PreferenceItem<int> {
  IntPreferenceItem(super.key, super.defaultValue);

  @override
  int? readValue(SharedPreferences prefs) => prefs.getInt(storageKey);

  @override
  Future<void> writeValue(SharedPreferences prefs, int value) =>
      prefs.setInt(storageKey, value);
}

class BoolPreferenceItem extends PreferenceItem<bool> {
  BoolPreferenceItem(super.key, super.defaultValue);

  @override
  bool? readValue(SharedPreferences prefs) => prefs.getBool(storageKey);

  @override
  Future<void> writeValue(SharedPreferences prefs, bool value) =>
      prefs.setBool(storageKey, value);
}

class StringPreferenceItem extends PreferenceItem<String> {
  StringPreferenceItem(super.key, super.defaultValue);

  @override
  String? readValue(SharedPreferences prefs) => prefs.getString(storageKey);

  @override
  Future<void> writeValue(SharedPreferences prefs, String value) =>
      prefs.setString(storageKey, value);
}

class StringListPreferenceItem extends PreferenceItem<List<String>> {
  StringListPreferenceItem(super.key, super.defaultValue);

  @override
  List<String>? readValue(SharedPreferences prefs) =>
      prefs.getStringList(storageKey);

  @override
  Future<void> writeValue(SharedPreferences prefs, List<String> value) =>
      prefs.setStringList(storageKey, value);
}

/// nullable enum 값 (미설정 = null). enum ↔ `name` 문자열로 저장한다.
/// 저장된 문자열이 [values] 중 어느 것과도 맞지 않으면(enum 상수 rename 등)
/// null로 처리해 기본값으로 폴백한다.
class NullableEnumPreferenceItem<E extends Enum> extends PreferenceItem<E?> {
  NullableEnumPreferenceItem(String key, this.values) : super(key, null);

  final List<E> values;

  @override
  E? readValue(SharedPreferences prefs) {
    final name = prefs.getString(storageKey);
    if (name == null) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }

  @override
  Future<void> writeValue(SharedPreferences prefs, E? value) {
    if (value == null) return prefs.remove(storageKey);
    return prefs.setString(storageKey, value.name);
  }
}
