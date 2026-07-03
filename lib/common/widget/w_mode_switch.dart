import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

import '../../../common/common.dart';

class ModeSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final double height;
  final Color activeThumbColor;
  final Image? activeThumbImage;
  final Color inactiveThumbColor;
  final Image? inactiveThumbImage;

  const ModeSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    required this.height,
    this.activeThumbColor = Colors.black,
    this.activeThumbImage,
    this.inactiveThumbColor = Colors.black,
    this.inactiveThumbImage,
  });

  Widget _buildTrack() {
    return AnimatedContainer(
      decoration: BoxDecoration(
        color: value ? AppColors.modeSwitchTrackDark : AppColors.modeSwitchTrackLight,
        borderRadius: BorderRadius.circular(height / 2),
      ),
      duration: AppDimens.animQuick,
    );
  }

  Widget _buildThumb() {
    final thumbSize = (3 / 4) * height;
    return AnimatedContainer(
      duration: AppDimens.animQuick,
      padding: EdgeInsets.symmetric(horizontal: (2 / 25) * height),
      alignment: value ? Alignment.centerRight : Alignment.centerLeft,
      child: Stack(
        children: [
          Container(
            height: thumbSize,
            width: thumbSize,
            decoration: BoxDecoration(color: activeThumbColor),
            child: activeThumbImage,
          ).opacity(value: value ? 1 : 0),
          Container(
            height: thumbSize,
            width: thumbSize,
            decoration: BoxDecoration(color: inactiveThumbColor),
            child: inactiveThumbImage,
          ).opacity(value: value ? 0 : 1),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const aspectRatio = (40 / 25);
    final colors = context.appColors;
    return Tap(
      onTap: () => onChanged(!value),
      child: Row(
        children: [
          'Light'
              .text
              .size(14)
              .color(value ? colors.inActivate : colors.activate)
              .bold
              .makeWithDefaultFont(),
          const Width(5),
          SizedBox(
            height: height,
            width: aspectRatio * height,
            child: Stack(
              children: [
                _buildTrack(),
                _buildThumb(),
              ],
            ),
          ),
          const Width(5),
          'Dark'
              .text
              .size(14)
              .color(value ? colors.activate : colors.inActivate)
              .bold
              .makeWithDefaultFont(),
        ],
      ),
    );
  }
}
