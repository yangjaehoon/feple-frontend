import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';

class PasswordChecklist extends StatelessWidget {
  final String password;
  const PasswordChecklist({super.key, required this.password});

  static const _rules = [
    (label: 'pw_rule_min', regex: null, minLen: 8),
    (label: 'pw_rule_upper', regex: r'[A-Z]', minLen: 0),
    (label: 'pw_rule_lower', regex: r'[a-z]', minLen: 0),
    (label: 'pw_rule_digit', regex: r'[0-9]', minLen: 0),
    (label: 'pw_rule_special', regex: r'[!@#$%^&*(),.?":{}|<>]', minLen: 0),
  ];

  bool _check(({String label, String? regex, int minLen}) rule) {
    if (rule.minLen > 0) return password.length >= rule.minLen;
    return RegExp(rule.regex!).hasMatch(password);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.textSecondary.withValues(alpha: 0.15)),
      ),
      child: Column(
        children: _rules.map((rule) {
          final ok = _check(rule);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 3),
            child: Row(
              children: [
                Icon(
                  ok ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                  size: 16,
                  color: ok ? const Color(0xFF00C896) : colors.textSecondary.withValues(alpha: 0.5),
                ),
                const SizedBox(width: 8),
                Text(
                  rule.label.tr(),
                  style: TextStyle(
                    fontSize: 12,
                    color: ok ? const Color(0xFF00C896) : colors.textSecondary,
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
