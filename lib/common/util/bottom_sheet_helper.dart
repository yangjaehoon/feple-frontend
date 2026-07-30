import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

const _sheetAnimationStyle = AnimationStyle(
  duration: AppDimens.animNormal,
  curve: Curves.easeOutCubic,
  reverseDuration: AppDimens.animFast,
  reverseCurve: Curves.easeInCubic,
);

Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useRootNavigator = false,
  bool isDismissible = true,
  bool enableDrag = true,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: Colors.transparent,
    sheetAnimationStyle: _sheetAnimationStyle,
    builder: builder,
  );
}
