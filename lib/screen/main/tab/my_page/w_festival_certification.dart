import 'package:feple/common/common.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/screen/main/tab/home/w_home_section_header.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/model/certification_model.dart';
import 'package:feple/screen/main/tab/my_page/cert_status_style.dart';
import 'package:feple/screen/main/tab/my_page/s_certification_list.dart';
import 'package:feple/screen/main/tab/my_page/w_certification_ring.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

class FestivalCertificationWidget extends StatefulWidget {
  const FestivalCertificationWidget({super.key});

  @override
  State<FestivalCertificationWidget> createState() => FestivalCertificationWidgetState();
}

class FestivalCertificationWidgetState extends State<FestivalCertificationWidget> {
  final _certService = sl<CertificationService>();
  List<CertificationModel>? _certifications;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void refresh() => _load();

  Future<void> _load() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final list = await _certService.getMyCertifications();
      if (mounted) setState(() { _certifications = list; _isLoading = false; });
    } catch (e) {
      debugPrint('[Certification] 인증 목록 로드 실패: $e');
      if (mounted) setState(() { _hasError = true; _isLoading = false; });
    }
  }

  Future<void> _openDetail() async {
    await Navigator.push(
      context,
      SlideRoute(builder: (_) => const CertificationListScreen()),
    );
    unawaited(_load()); // 돌아왔을 때 목록 새로고침
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
            onPressed: _isLoading ? null : _openDetail,
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
            height: ResponsiveSize(context).w(150),
            child: _isLoading
                ? _buildSkeletonList()
                : _certifications == null || _certifications!.isEmpty
                    ? _buildEmptyState(colors)
                    : _buildCertList(colors),
          ),
      ],
    );
  }

  // CertificationRing 실제 렌더 크기(반지름 44/390 + 안쪽 padding 2*2 + 바깥
  // padding 3*2)와 일치시켜 로딩→콘텐츠 전환 시 크기가 튀지 않게 한다.
  double _certRingSize(BuildContext context) =>
      ResponsiveSize(context).w(88) + 10; // 반지름 44/390 * 2 + padding(2*2 + 3*2)

  Widget _buildSkeletonList() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: 3,
      itemBuilder: (_, _) {
        final ringSize = _certRingSize(context);
        return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeletonBox(
              width: ringSize,
              height: ringSize,
              borderRadius: BorderRadius.circular(ringSize / 2),
            ),
            const SizedBox(height: AppDimens.space6),
            const SkeletonBox(width: 72, height: 11),
            const SizedBox(height: AppDimens.space4),
            const SkeletonBox(width: 48, height: 10, borderRadius: BorderRadius.all(Radius.circular(20))),
          ],
        ),
        );
      },
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
          const SizedBox(height: AppDimens.space8),
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
          const SizedBox(height: AppDimens.space10),
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
    // 승인된 것만 보여주면 대기중/거절만 있는 경우 "제출 이력이 없다"는
    // 빈 상태로 잘못 보임 — 상세 화면과 동일하게 모든 상태를 표시
    final certs = _certifications!;
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
            CertificationRing(
              imageUrl: cert.posterUrl,
              ringColor: ringColor,
              ringAlpha: isApproved ? 0.6 : 0.3,
            ),
            const SizedBox(height: AppDimens.space4),
            SizedBox(
              width: ResponsiveSize(context).w(106),
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

}
