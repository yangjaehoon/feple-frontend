import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'w_transparent_scaffold.dart';

class BottomDialogScaffold extends StatelessWidget {
  final Widget body;
  const BottomDialogScaffold({required this.body, super.key});

  @override
  Widget build(BuildContext context) {
    return TransparentScaffold(
      backgroundColor: Colors.transparent,
      body: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          padding: const EdgeInsets.only(top: 20, bottom: 20, right: 15, left: 15),
          decoration: BoxDecoration(
              color: context.backgroundColor,
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppDimens.shapeSheet), topRight: Radius.circular(AppDimens.shapeSheet))),
          child: body,
        ),
      ),
    );
  }
}
