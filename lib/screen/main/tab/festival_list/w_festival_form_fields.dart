import 'package:feple/common/common.dart';
import 'package:flutter/material.dart';

class FestivalTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final int maxLines;
  final String? Function(String?)? validator;

  const FestivalTextField({
    super.key,
    required this.controller,
    required this.label,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: colors.textTitle),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textSecondary),
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.listDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.listDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.activate, width: 1.5),
        ),
      ),
    );
  }
}

class FestivalDateTile extends StatelessWidget {
  final String label;
  final DateTime? date;
  final VoidCallback onTap;

  const FestivalDateTile({
    super.key,
    required this.label,
    required this.date,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.listDivider),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded, size: 16, color: colors.activate),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style:
                          TextStyle(fontSize: 11, color: colors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    date != null
                        ? '${date!.year}.${date!.month.toString().padLeft(2, '0')}.${date!.day.toString().padLeft(2, '0')}'
                        : 'label_not_selected'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: date != null ? colors.textTitle : colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class FestivalSectionLabel extends StatelessWidget {
  final String label;

  const FestivalSectionLabel(this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: colors.textTitle,
      ),
    );
  }
}
