import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/navigate_after_fetch.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_tap_loading_indicator.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/certification_model.dart';
import 'package:feple/screen/main/tab/my_page/cert_status_style.dart';
import 'package:feple/screen/main/tab/my_page/w_certification_ring.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';

/// 타인 프로필 화면의 페스티벌 인증 뱃지 가로 목록.
/// [certifications]가 null이면 스켈레톤, 비어 있으면 안내, 있으면 목록.
/// 뱃지 탭 → 페스티벌 상세로 이동(fetch 중 로딩 오버레이는 이 위젯이 자체 관리).
class OtherUserCertifications extends StatefulWidget {
  final List<CertificationModel>? certifications;

  const OtherUserCertifications({super.key, required this.certifications});

  @override
  State<OtherUserCertifications> createState() =>
      _OtherUserCertificationsState();
}

class _OtherUserCertificationsState extends State<OtherUserCertifications> {
  final _festivalService = sl<FestivalService>();

  // 인증 카드 탭 → fetchById → 화면 전환까지 아무 피드백 없이 멈춰 보이는 걸 방지
  int? _navigatingFestivalId;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final certs = widget.certifications;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.verified_rounded, color: colors.activate, size: 18),
              const SizedBox(width: AppDimens.space6),
              Text(
                'certification_badge'.tr(),
                style: TextStyle(
                  fontSize: AppDimens.fontSizeMd,
                  fontWeight: FontWeight.w700,
                  color: colors.textTitle,
                ),
              ),
              if (certs != null) ...[
                const SizedBox(width: AppDimens.space6),
                Text(
                  '${certs.length}',
                  style: TextStyle(
                    fontSize: AppDimens.fontSizeSm,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppDimens.space12),
        SizedBox(
          height: ResponsiveSize(context).w(150),
          child: certs == null
              ? _buildSkeleton()
              : certs.isEmpty
                  ? _buildEmpty(colors)
                  : _buildList(certs, colors),
        ),
      ],
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: 3,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SkeletonBox(
                width: 98,
                height: 98,
                borderRadius: BorderRadius.all(Radius.circular(49))),
            SizedBox(height: AppDimens.space6),
            SkeletonBox(width: 72, height: 11),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(AbstractThemeColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_outlined,
              size: 32, color: colors.activate.withValues(alpha: 0.4)),
          const SizedBox(height: AppDimens.space8),
          Text(
            'no_certification'.tr(),
            style: TextStyle(
                fontSize: AppDimens.fontSizeSm, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<CertificationModel> certs, AbstractThemeColors colors) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: certs.length,
      itemBuilder: (_, i) => _buildItem(certs[i], colors),
    );
  }

  Future<void> _navigateToFestival(int festivalId) async {
    if (_navigatingFestivalId != null) return;
    await navigateAfterFetch(
      context,
      fetch: () => _festivalService.fetchById(festivalId),
      builder: (festival) => FestivalInformationFragment(poster: festival),
      setLoading: (v) {
        if (mounted) {
          setState(() => _navigatingFestivalId = v ? festivalId : null);
        }
      },
      errorTag: 'OtherUserProfile',
      awaitNavigation: false,
    );
  }

  Widget _buildItem(CertificationModel cert, AbstractThemeColors colors) {
    final isEnglish = context.isEnglish;
    final ringColor = CertStatus.approved.displayColor(colors);
    final isLoading = _navigatingFestivalId == cert.festivalId;
    return TapScale(
      onTap: isLoading ? null : () => _navigateToFestival(cert.festivalId),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CertificationRing(
              imageUrl: cert.posterUrl,
              ringColor: ringColor,
              overlay: isLoading ? const TapLoadingIndicator() : null,
            ),
            const SizedBox(height: AppDimens.space6),
            SizedBox(
              width: ResponsiveSize(context).w(106),
              child: Text(
                cert.displayFestivalTitle(isEnglish),
                style: TextStyle(
                    fontSize: AppDimens.fontSizeXxs,
                    fontWeight: FontWeight.w600,
                    color: colors.textTitle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
