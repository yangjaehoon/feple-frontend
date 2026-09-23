import 'package:feple/common/common.dart';
import 'package:feple/common/util/refresh_coordinator.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/screen/main/tab/home/w_home_section_header.dart';
import 'package:feple/screen/main/tab/my_page/w_section_see_all_button.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/model/certification_model.dart';
import 'package:feple/screen/main/tab/my_page/cert_status_style.dart';
import 'package:feple/screen/main/tab/my_page/s_certification_list.dart';
import 'package:feple/screen/main/tab/my_page/w_certification_ring.dart';
import 'package:feple/screen/main/tab/my_page/w_section_empty_state.dart';
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

class FestivalCertificationWidgetState extends State<FestivalCertificationWidget>
    with RefreshableSection<FestivalCertificationWidget> {
  final _certService = sl<CertificationService>();
  List<CertificationModel>? _certifications;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  Future<void> refreshSection() => _load();

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
    // 상세에 머무는 동안 이 위젯이 사라졌을 수 있다(로그아웃 등)
    if (mounted) unawaited(_load()); // 돌아왔을 때 목록 새로고침
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'festival_certification'.tr(),
          trailing: SectionSeeAllButton(
            onTap: _isLoading ? null : _openDetail,
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
                    ? _buildEmptyState()
                    : _buildCertList(colors),
          ),
      ],
    );
  }

  Widget _buildSkeletonList() {
    final ringSize = CertificationRing.diameter(context);
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: 3,
      itemBuilder: (_, _) => Padding(
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
      ),
    );
  }

  Widget _buildEmptyState() {
    return SectionEmptyState(
      icon: Icons.workspace_premium_outlined,
      title: 'cert_no_history'.tr(),
      hint: 'cert_no_history_hint'.tr(),
      ctaLabel: 'cert_submit'.tr(),
      onCta: _openDetail,
    );
  }

  Widget _buildCertList(AbstractThemeColors colors) {
    // 승인된 것만 보여주면 대기중/거절만 있는 경우 "제출 이력이 없다"는
    // 빈 상태로 잘못 보임 — 상세 화면과 동일하게 모든 상태를 표시
    final certs = _certifications!;
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
