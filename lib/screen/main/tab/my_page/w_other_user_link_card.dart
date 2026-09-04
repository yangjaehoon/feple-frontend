import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:flutter/material.dart';

/// 타인 프로필 화면의 "게시글" / "페스티벌 다이어리" 처럼 탭하면 다른 화면·시트로
/// 넘어가는 한 줄 카드. 아이콘 + 라벨 + (선택)우측 값 + 화살표.
class OtherUserLinkCard extends StatelessWidget {
  final IconData icon;
  final String label;

  /// 우측에 표시할 위젯(예: 게시글 수 / 로딩 스켈레톤). 없으면 화살표만.
  final Widget? trailing;
  final VoidCallback onTap;

  const OtherUserLinkCard({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TapScale(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
            border: Border.all(color: colors.listDivider),
            boxShadow: CardShadows.subtle(colors),
          ),
          child: Row(
            children: [
              Icon(icon, color: colors.activate, size: 22),
              const SizedBox(width: AppDimens.space12),
              Text(
                label,
                style: TextStyle(
                  fontSize: AppDimens.fontSizeMd,
                  fontWeight: FontWeight.w600,
                  color: colors.textTitle,
                ),
              ),
              const Spacer(),
              if (trailing != null) ...[
                trailing!,
                const SizedBox(width: AppDimens.space8),
              ],
              Icon(Icons.chevron_right_rounded,
                  color: colors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}
