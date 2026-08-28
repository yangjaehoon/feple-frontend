import 'package:feple/common/common.dart';
import 'package:feple/common/util/password_validator.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

class PasswordChecklist extends StatelessWidget {
  final String password;
  const PasswordChecklist({super.key, required this.password});

  // 규칙 정의는 PasswordValidator가 소유하고, 여기서는 그 판정 함수만 참조한다.
  static const _rules = <({String label, bool Function(String) satisfied})>[
    (label: 'pw_rule_min', satisfied: PasswordValidator.hasMinLength),
    (label: 'pw_rule_upper', satisfied: PasswordValidator.hasUppercase),
    (label: 'pw_rule_lower', satisfied: PasswordValidator.hasLowercase),
    (label: 'pw_rule_digit', satisfied: PasswordValidator.hasDigit),
    (label: 'pw_rule_special', satisfied: PasswordValidator.hasSpecial),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: _rules.map((rule) {
          final ok = rule.satisfied(password);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(
                  ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: ok ? colors.activate : colors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: AppDimens.space8),
                Text(
                  rule.label.tr(),
                  style: TextStyle(
                    fontSize: AppDimens.fontSizeXs,
                    color: ok ? colors.activate : colors.textSecondary,
                    fontWeight: ok ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
