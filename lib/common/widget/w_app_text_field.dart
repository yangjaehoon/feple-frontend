import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:flutter/material.dart';

/// 앱 전체에서 사용하는 공통 텍스트 필드 스타일.
/// login / signup 등에서 중복 정의되던 스타일을 통합합니다.
class AppTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hintText;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final int? maxLength;
  final String? errorText;
  final ValueChanged<String>? onChanged;

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
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLength: maxLength,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15, color: AppColors.textMain),
          decoration: InputDecoration(
            counterText: maxLength != null ? '' : null,
            prefixIcon: Icon(icon, color: AppColors.skyBlue, size: 22),
            hintText: hintText,
            hintStyle:
                const TextStyle(color: AppColors.textMuted, fontSize: 15),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                  color: AppColors.skyBlueLight.withValues(alpha: 0.5)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: errorText != null
                    ? Colors.red
                    : AppColors.skyBlueLight.withValues(alpha: 0.4),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide:
                  const BorderSide(color: AppColors.skyBlue, width: 2),
            ),
          ),
        ),
        if (errorText != null)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              errorText!,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}
