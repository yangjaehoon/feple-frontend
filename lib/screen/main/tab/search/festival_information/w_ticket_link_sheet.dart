import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/url_validator.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../model/ticket_link.dart';

class TicketLinkSheet extends StatelessWidget {
  // 예매처 아이콘은 로고 유무와 무관하게 항상 같은 정사각 박스를 차지해야
  // 각 행의 텍스트 시작 위치와 행 높이가 일정해진다(로고 없는 벤더에서 정렬 깨짐 방지).
  static const double _vendorIconBox = 28;
  static const double _fallbackIconSize = 24;

  final List<TicketLink> links;

  const TicketLinkSheet({super.key, required this.links});

  Future<void> _open(BuildContext context, String url) async {
    // 서버가 준 티켓 벤더 URL — 실행 직전 http(s) 스킴 재검증 (임의 스킴 차단)
    if (!isSafeExternalUrl(url)) {
      if (context.mounted) context.showErrorSnackbar('link_open_failed'.tr());
      return;
    }
    final launched =
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      context.showErrorSnackbar('link_open_failed'.tr());
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
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
          const SizedBox(height: AppDimens.space20),
          Text(
            'ticket_links_title'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeXxl,
              fontWeight: FontWeight.bold,
              color: colors.text,
            ),
          ),
          const SizedBox(height: AppDimens.space12),
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildVendorIcon(colors, link),
              const SizedBox(width: AppDimens.space12),
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
  // 브랜드 로고를, 그 외에는 일반 티켓 아이콘을 보여준다. 어느 쪽이든 _vendorIconBox
  // 정사각 안에 담아 행마다 텍스트 시작 위치·높이를 동일하게 유지한다.
  Widget _buildVendorIcon(AbstractThemeColors colors, TicketLink link) {
    final logoAsset = link.vendorLogoAsset;
    return SizedBox(
      width: _vendorIconBox,
      height: _vendorIconBox,
      child: logoAsset == null
          ? _buildFallbackIcon(colors)
          : ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              child: Image.asset(
                logoAsset,
                fit: BoxFit.cover,
                // 원본이 표시 크기보다 훨씬 큰 에셋도 있어 필요 이상 해상도로
                // 디코딩되지 않게 캡 — 3배 밀도 화면 기준.
                cacheWidth: 84,
                cacheHeight: 84,
                errorBuilder: (_, _, _) => _buildFallbackIcon(colors),
              ),
            ),
    );
  }

  Widget _buildFallbackIcon(AbstractThemeColors colors) {
    return Center(
      child: Icon(
        Icons.confirmation_number_outlined,
        color: colors.activate,
        size: _fallbackIconSize,
      ),
    );
  }
}
