import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 앱 전역 입력 필드 반경(`AppDimens.cardRadiusTiny`)을 쓰는 공용 OutlineInputBorder.
OutlineInputBorder appInputBorder(Color color, {double width = 1}) =>
    OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
      borderSide: BorderSide(color: color, width: width),
    );
