import 'package:fast_app_base/common/data/preference/item/preference_item.dart';

class NullablePreferenceItem<T> extends PreferenceItem<T?> {
  NullablePreferenceItem(super.key, [super.defaultValue]);
}
