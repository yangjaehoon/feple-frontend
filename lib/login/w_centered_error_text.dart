import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 폼 아래·버튼 위에 가운데 정렬로 띄우는 오류 문구 한 줄(필드에 속하지 않는 오류).
/// 필드 바로 아래 아이콘과 함께 붙는 문구는 [FormErrorText].
class CenteredErrorText extends StatelessWidget {
  final String message;
  final EdgeInsetsGeometry padding;

  const CenteredErrorText({
    super.key,
    required this.message,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        message,
        style: TextStyle(
          fontSize: AppDimens.fontSizeSm,
          color: context.appColors.error,
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
