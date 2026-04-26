import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/screen/main/tab/my_page/s_certification_list.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FtvCertificationWidget extends StatefulWidget {
  const FtvCertificationWidget({super.key});

  @override
  State<FtvCertificationWidget> createState() => _FtvCertificationWidgetState();
}

class _FtvCertificationWidgetState extends State<FtvCertificationWidget> {
  final _certService = sl<CertificationService>();
  List<Map<String, dynamic>>? _certifications;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _certService.getMyCertifications();
      if (mounted) setState(() { _certifications = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _certifications = []; _loading = false; });
    }
  }

  void _openDetail() async {
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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: colors.sectionBarColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'festival_certification'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textTitle,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.settings_rounded,
                    color: colors.textSecondary, size: 20),
                onPressed: _loading ? null : _openDetail,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),
        SizedBox(
          height: 150,
          child: _loading
              ? _buildSkeletonList()
              : _certifications == null || _certifications!.isEmpty
                  ? _buildEmptyList(colors)
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
      itemBuilder: (_, __) => Padding(
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

  Widget _buildEmptyList(AbstractThemeColors colors) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: 3,
      itemBuilder: (_, __) => _buildPlaceholderItem(colors),
    );
  }

  Widget _buildCertList(AbstractThemeColors colors) {
    final certs = _certifications!;
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: certs.length,
      itemBuilder: (context, index) {
        return _buildCertItem(certs[index], colors);
      },
    );
  }

  Widget _buildCertItem(Map<String, dynamic> cert, AbstractThemeColors colors) {
    final status = cert['status'] as String? ?? 'PENDING';
    final festivalTitle = cert['festivalTitle'] as String? ?? '';
    final imageUrl = cert['festivalPosterUrl'] as String? ?? cert['photoUrl'] as String?;
    final isApproved = status == 'APPROVED';
    final isPending = status == 'PENDING';

    Color ringColor;
    if (isApproved) {
      ringColor = colors.certRingColor;
    } else if (isPending) {
      ringColor = Colors.orange;
    } else {
      ringColor = Colors.grey;
    }

    return GestureDetector(
      onTap: _openDetail,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
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
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: colors.surface),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor: ringColor.withValues(alpha: 0.15),
                  backgroundImage: imageUrl != null
                      ? CachedNetworkImageProvider(imageUrl)
                      : null,
                  child: imageUrl == null
                      ? Icon(Icons.photo, size: 26,
                          color: colors.textTitle.withValues(alpha: 0.3))
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 106,
              child: Text(
                festivalTitle,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.textTitle,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: ringColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isApproved
                    ? 'cert_status_approved'.tr()
                    : isPending
                        ? 'cert_status_pending'.tr()
                        : 'cert_status_rejected'.tr(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: ringColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholderItem(AbstractThemeColors colors) {
    return GestureDetector(
      onTap: _openDetail,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.certRingColor.withValues(alpha: 0.3),
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
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: colors.surface),
                child: CircleAvatar(
                  radius: 44,
                  backgroundColor:
                      colors.certRingColor.withValues(alpha: 0.15),
                  child: Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 28,
                    color: colors.textTitle.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'no_certification'.tr(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textTitle.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
