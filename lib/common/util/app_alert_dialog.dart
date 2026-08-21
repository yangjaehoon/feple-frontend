import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 프로젝트 공통 AlertDialog 크롬(배경/모서리/제목/본문 스타일). actions만 호출부에서 지정.
/// iOS에서는 [AlertDialog.adaptive]가 자동으로 CupertinoAlertDialog로 렌더링한다
/// (이 경우 backgroundColor/shape는 무시됨 — Cupertino 자체 스타일을 따름).
AlertDialog buildAppAlertDialog(
  BuildContext context, {
  required String title,
  required String content,
  required List<Widget> actions,
}) {
  final colors = context.appColors;
  return AlertDialog.adaptive(
    backgroundColor: colors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppDimens.shapeDialog)),
    ),
    title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: colors.textTitle)),
    content: Text(content, style: TextStyle(color: colors.textSecondary)),
    actions: actions,
  );
}
