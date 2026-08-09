import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// "새 항목 제안하기" 배너 — 아티스트/페스티벌 등 여러 탭에서 아이콘·문구·
/// 열리는 바텀시트만 다르고 카드 모양/로그인 가드/시트 오픈 로직은 동일했던
/// 패턴을 공용화.
class SuggestionBanner extends StatelessWidget {
  final IconData icon;
  final String titleKey;
  final String subtitleKey;
  final EdgeInsetsGeometry margin;
  final WidgetBuilder sheetBuilder;

  const SuggestionBanner({
    super.key,
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    this.margin = const EdgeInsets.symmetric(horizontal: 20),
    required this.sheetBuilder,
  });

  void _openSheet(BuildContext context) {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final userId = context.read<UserProvider>().currentUserId;
    if (userId == null) {
      context.showInfoSnackbar('no_login_info'.tr());
      return;
    }
    showAppBottomSheet(context, builder: sheetBuilder);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: () => _openSheet(context),
      child: Container(
        margin: margin,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
          border: Border.all(color: colors.activate.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, color: colors.activate, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titleKey.tr(),
                    style: TextStyle(
                      fontSize: AppDimens.fontSizeSm,
                      fontWeight: FontWeight.w600,
                      color: colors.textTitle,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitleKey.tr(),
                    style: TextStyle(
                      fontSize: AppDimens.fontSizeXs,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.textSecondary,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}
