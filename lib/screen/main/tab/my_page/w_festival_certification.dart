import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/screen/main/tab/home/w_home_section_header.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/model/certification_model.dart';
import 'package:feple/screen/main/tab/my_page/cert_status_style.dart';
import 'package:feple/screen/main/tab/my_page/s_certification_list.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FtvCertificationWidget extends StatefulWidget {
  const FtvCertificationWidget({super.key});

  @override
  State<FtvCertificationWidget> createState() => FtvCertificationWidgetState();
}

class FtvCertificationWidgetState extends State<FtvCertificationWidget> {
  final _certService = sl<CertificationService>();
  List<CertificationModel>? _certifications;
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void refresh() => _load();

  Future<void> _load() async {
    setState(() { _loading = true; _hasError = false; });
    try {
      final list = await _certService.getMyCertifications();
      if (mounted) setState(() { _certifications = list; _loading = false; });
    } catch (e) {
      debugPrint('[Certification] 인증 목록 로드 실패: $e');
      if (mounted) setState(() { _hasError = true; _loading = false; });
    }
  }

  Future<void> _openDetail() async {
    await Navigator.push(
      context,
      SlideRoute(builder: (_) => const CertificationListScreen()),
    );
    _load(); // 돌아왔을 때 목록 새로고침
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'festival_certification'.tr(),
          trailing: TextButton(
            onPressed: _loading ? null : _openDetail,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'see_all'.tr(),
                  style: TextStyle(fontSize: AppDimens.fontSizeSm, fontWeight: FontWeight.w600, color: colors.activate),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: colors.activate),
              ],
            ),
          ),
        ),
        if (_hasError)
          ErrorState(message: 'load_error'.tr(), onRetry: _load)
        else
          SizedBox(
            height: 150,
            child: _loading
                ? _buildSkeletonList()
                : _certifications == null || _certifications!.isEmpty
                    ? _buildEmptyState(colors)
                    : _buildCertList(colors),
          ),
      ],
    );
  }

  Widget _buildSkeletonList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: 3,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SkeletonBox(
              width: 98,
              height: 98,
              borderRadius: BorderRadius.all(Radius.circular(49)),
            ),
            const SizedBox(height: 6),
            const SkeletonBox(width: 72, height: 11),
            const SizedBox(height: 4),
            const SkeletonBox(width: 48, height: 10, borderRadius: BorderRadius.all(Radius.circular(20))),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AbstractThemeColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.workspace_premium_outlined,
            size: 32,
            color: colors.activate.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 8),
          Text(
            'cert_no_history'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeSm,
              fontWeight: FontWeight.w600,
              color: colors.textTitle,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            'cert_no_history_hint'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeXxs,
              color: colors.textSecondary,
              height: 1.4,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _openDetail,
            icon: const Icon(Icons.add_rounded, size: 14),
            label: Text(
              'cert_submit'.tr(),
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

  Widget _buildCertList(AbstractThemeColors colors) {
    final certs = _certifications!
        .where((c) => c.status == CertStatus.approved)
        .toList();
    if (certs.isEmpty) return _buildEmptyState(colors);
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: certs.length,
      itemBuilder: (context, index) {
        return _buildCertItem(certs[index], context.isEnglish, colors);
      },
    );
  }

  Widget _buildCertItem(CertificationModel cert, bool isEnglish, AbstractThemeColors colors) {
    final isApproved = cert.status == CertStatus.approved;
    final ringColor = cert.status.displayColor(colors);

    return TapScale(
      onTap: _openDetail,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCertRing(cert.posterUrl, ringColor, isApproved, colors),
            const SizedBox(height: 4),
            SizedBox(
              width: 106,
              child: Text(
                cert.displayFestivalTitle(isEnglish),
                style: TextStyle(fontSize: AppDimens.fontSizeXxs, fontWeight: FontWeight.w600, color: colors.textTitle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ringColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(AppDimens.cardRadius),
              ),
              child: Text(
                cert.status.labelKey.tr(),
                style: TextStyle(fontSize: AppDimens.fontSizeTiny, fontWeight: FontWeight.w600, color: ringColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCertRing(String? imageUrl, Color ringColor, bool isApproved, AbstractThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: ringColor.withValues(alpha: isApproved ? 0.6 : 0.3),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surface),
        child: CircleAvatar(
          radius: 44,
          backgroundColor: ringColor.withValues(alpha: 0.15),
          // radius 44 → diameter 88px, *1.5 = 132 (고DPI 여유분)
          backgroundImage: imageUrl != null ? CachedNetworkImageProvider(imageUrl, maxWidth: 132) : null,
          child: imageUrl == null
              ? Icon(Icons.photo_rounded, size: 26, color: colors.textTitle.withValues(alpha: 0.3))
              : null,
        ),
      ),
    );
  }

}
