import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../model/ticket_link.dart';

class TicketLinkSheet extends StatelessWidget {
  final List<TicketLink> links;

  const TicketLinkSheet({super.key, required this.links});

  Future<void> _open(BuildContext context, String url) async {
    final launched = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) context.showErrorSnackbar('link_open_failed'.tr());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundMain,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppDimens.shapeSheet),
        ),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: BottomSheetHandle()),
          const SizedBox(height: 20),
          Text(
            'ticket_links_title'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeXxl,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          const SizedBox(height: 12),
          ...links.map((link) => _buildLinkTile(context, colors, link)),
        ],
      ),
    );
  }

  Widget _buildLinkTile(BuildContext context, AbstractThemeColors colors, TicketLink link) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
        onTap: () => _open(context, link.url),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Row(
            children: [
              _buildVendorIcon(colors, link),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  (link.label?.isNotEmpty ?? false) ? link.label! : link.url,
                  style: TextStyle(
                    fontSize: AppDimens.fontSizeMd,
                    fontWeight: FontWeight.w600,
                    color: colors.textTitle,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.open_in_new_rounded, color: colors.textSecondary, size: AppDimens.iconSizeMd),
            ],
          ),
        ),
      ),
    );
  }

  // 인터파크(NOL)/예스24/멜론티켓/티켓링크처럼 URL 도메인으로 식별되는 예매처는
  // 브랜드 로고를, 그 외에는 일반 티켓 아이콘을 보여준다.
  Widget _buildVendorIcon(AbstractThemeColors colors, TicketLink link) {
    final logoAsset = link.vendorLogoAsset;
    if (logoAsset == null) {
      return Icon(Icons.confirmation_number_outlined, color: colors.activate, size: AppDimens.iconSizeLg);
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      child: Image.asset(
        logoAsset,
        width: 28,
        height: 28,
        fit: BoxFit.cover,
      ),
    );
  }
}
