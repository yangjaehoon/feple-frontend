import 'package:fast_app_base/common/common.dart';
import 'package:flutter/material.dart';

class DarkAppShadows extends AbsThemeShadows {
  const DarkAppShadows();

  @override
  BoxShadow get buttonShadow => BoxShadow(
        offset: const Offset(0, 4),
        blurRadius: 20,
        color: Colors.black.withOpacity(0.4),
      );

  @override
  BoxShadow get thickTextShadow => BoxShadow(
        offset: const Offset(0, 2),
        blurRadius: 8,
        color: Colors.black.withOpacity(0.5),
      );

  @override
  BoxShadow get defaultShadow => BoxShadow(
        offset: const Offset(0, 4),
        blurRadius: 12,
        color: Colors.black.withOpacity(0.3),
      );

  @override
  BoxShadow get textShadow => BoxShadow(
        offset: const Offset(0, 2),
        blurRadius: 4,
        color: Colors.black.withOpacity(0.4),
      );

  @override
  BoxShadow get buttonShadowSmall => BoxShadow(
        offset: const Offset(0, 2),
        blurRadius: 10,
        color: Colors.black.withOpacity(0.25),
      );
}
