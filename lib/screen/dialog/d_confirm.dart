import 'package:feple/common/widget/scaffold/w_center_dialog_scaffold.dart';
import 'package:feple/data/simple_result.dart';
import 'package:flutter/material.dart';
import 'package:nav/dialog/dialog.dart';

import '../../common/common.dart';
import '../../common/constant/app_dimensions.dart';

class ConfirmDialog extends DialogWidget<SimpleResult> {
  final String? message;
  final String buttonText;
  final String cancelButtonText;
  final bool cancelable;
  final TextAlign textAlign;
  final double fontSize;

  ConfirmDialog(
    this.message, {
    super.context,
    super.key,
    String? buttonText,
    String? cancelButtonText,
    this.fontSize = 14,
    this.cancelable = true,
    this.textAlign = TextAlign.start,
  })  : buttonText = buttonText ?? 'close'.tr(),
        cancelButtonText = cancelButtonText ?? 'cancel'.tr();

  @override
  State<StatefulWidget> createState() {
    return _MessageDialogState();
  }
}

class _MessageDialogState extends DialogState<ConfirmDialog> {
  var isChecked = false;

  Widget _buildMessageRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              widget.message!,
              style: TextStyle(
                  fontSize: widget.fontSize,
                  height: 1.8,
                  color: context.appColors.text),
              textAlign: widget.textAlign,
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Tap(
            onTap: () {
              widget.hide(SimpleResult.failure());
            },
            child: Semantics(
              button: true,
              label: widget.cancelButtonText,
              child: Container(
                  constraints: const BoxConstraints(minHeight: 50),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    widget.cancelButtonText,
                    style: TextStyle(
                      color: context.appColors.confirmText,
                      fontSize: AppDimens.fontSizeXl,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.normal,
                    ),
                  )),
            ),
          ),
        ),
        Expanded(
          child: Tap(
            onTap: () {
              widget.hide(SimpleResult.success());
            },
            child: Semantics(
              button: true,
              label: widget.buttonText,
              child: Container(
                  constraints: const BoxConstraints(minHeight: 50),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    widget.buttonText,
                    style: TextStyle(
                      color: context.appColors.confirmText,
                      fontSize: AppDimens.fontSizeXl,
                      fontWeight: FontWeight.w700,
                      fontStyle: FontStyle.normal,
                    ),
                  )),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CenterDialogScaffold(
        body: Container(
            constraints: BoxConstraints(maxHeight: context.deviceHeight),
            decoration: BoxDecoration(
                color: context.appColors.drawerBg,
                borderRadius: BorderRadius.circular(28)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMessageRow(context),
                Line(color: context.appColors.divider),
                _buildActionButtons(context),
              ],
            )));
  }
}
