import 'package:fast_app_base/common/common.dart';
import 'package:flutter/material.dart';

class LightAppShadows extends AbsThemeShadows {
  const LightAppShadows();

  @override
  BoxShadow get buttonShadow => BoxShadow(
        offset: const Offset(0, 4),
        blurRadius: 20,
        color: AppColors.skyBlue.withOpacity(0.2),
      );

  @override
  BoxShadow get thickTextShadow => const BoxShadow(
        offset: Offset(0, 2),
        blurRadius: 8,
        color: Color.fromARGB(20, 0, 0, 0),
      );

  @override
  BoxShadow get defaultShadow => BoxShadow(
        offset: const Offset(0, 4),
        blurRadius: 12,
        color: AppColors.skyBlue.withOpacity(0.15),
      );

  @override
  BoxShadow get textShadow => const BoxShadow(
        offset: Offset(0, 2),
        blurRadius: 4,
        color: Color.fromARGB(15, 0, 0, 0),
      );

  @override
  BoxShadow get buttonShadowSmall => BoxShadow(
        offset: const Offset(0, 2),
        blurRadius: 10,
        color: AppColors.skyBlue.withOpacity(0.12),
      );
}
