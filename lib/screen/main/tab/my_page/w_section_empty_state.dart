import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 마이페이지 가로 섹션(페스티벌 인증·일기)의 빈 상태.
/// 아이콘 + 제목 + 힌트 + 첫 항목을 만들러 가는 CTA 버튼.
class SectionEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String hint;
  final String ctaLabel;
  final VoidCallback onCta;

  const SectionEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.hint,
    required this.ctaLabel,
    required this.onCta,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: colors.activate.withValues(alpha: 0.5)),
          const SizedBox(height: AppDimens.space8),
          Text(
            title,
            style: TextStyle(
              fontSize: AppDimens.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: colors.textTitle,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            hint,
            style: TextStyle(
              fontSize: AppDimens.fontSizeXxs,
              color: colors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.space10),
          FilledButton.icon(
            onPressed: onCta,
            icon: const Icon(Icons.add_rounded, size: 14),
            label: Text(
              ctaLabel,
              style: const TextStyle(fontSize: AppDimens.fontSizeXs),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: colors.activate,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
          ),
        ],
      ),
    );
  }
}
