import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

class AppTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final int? maxLength;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final String? semanticsLabel;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;

  const AppTextField({
    super.key,
    required this.controller,
    required this.hintText,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.maxLength,
    this.errorText,
    this.onChanged,
    this.onSubmitted,
    this.semanticsLabel,
    this.textInputAction,
    this.autofillHints,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  late bool _isObscured;

  @override
  void initState() {
    super.initState();
    _isObscured = widget.obscureText;
  }

  InputDecoration _buildInputDecoration(AbstractThemeColors colors) {
    return InputDecoration(
      counterText: widget.maxLength != null ? '' : null,
      prefixIcon: Icon(widget.icon, color: colors.activate, size: 22),
      suffixIcon: widget.obscureText
          ? IconButton(
              tooltip: _isObscured ? 'show_password'.tr() : 'hide_password'.tr(),
              icon: Icon(
                _isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                color: colors.textSecondary,
                size: 20,
              ),
              onPressed: () => setState(() => _isObscured = !_isObscured),
              splashRadius: 20,
            )
          : null,
      hintText: widget.hintText,
      hintStyle: TextStyle(color: colors.hintText, fontSize: AppDimens.fontSizeLg),
      filled: true,
      fillColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
        borderSide: BorderSide(color: colors.divider),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
        borderSide: BorderSide(
          color: widget.errorText != null ? colors.error : colors.divider,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
        borderSide: BorderSide(color: colors.focusedBorder, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: widget.semanticsLabel ?? widget.hintText,
          child: TextField(
            controller: widget.controller,
            obscureText: _isObscured,
            keyboardType: widget.keyboardType,
            textInputAction: widget.textInputAction,
            maxLength: widget.maxLength,
            onChanged: widget.onChanged,
            onSubmitted: widget.onSubmitted,
            autofillHints: widget.autofillHints,
            style: TextStyle(fontSize: AppDimens.fontSizeLg, color: colors.text),
            decoration: _buildInputDecoration(colors),
          ),
        ),
        if (widget.errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              widget.errorText!,
              style: TextStyle(
                fontSize: AppDimens.fontSizeXs,
                color: colors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
