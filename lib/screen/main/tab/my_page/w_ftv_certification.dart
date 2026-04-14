import 'package:feple/common/common.dart';
import 'package:feple/service/certification_service.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class FtvCertificationWidget extends StatefulWidget {
  const FtvCertificationWidget({super.key});

  @override
  State<FtvCertificationWidget> createState() => _FtvCertificationWidgetState();
}

class _FtvCertificationWidgetState extends State<FtvCertificationWidget> {
  final _certService = CertificationService();
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

  void _openDetail() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CertificationDetailSheet(
        certifications: _certifications ?? [],
      ),
    );
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
          height: 160,
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _certifications == null || _certifications!.isEmpty
                  ? _buildEmptyList(colors)
                  : _buildCertList(colors),
        ),
      ],
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
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _certifications!.length,
      itemBuilder: (context, index) {
        final cert = _certifications![index];
        return _buildCertItem(cert, colors);
      },
    );
  }

  Widget _buildCertItem(Map<String, dynamic> cert, AbstractThemeColors colors) {
    final status = cert['status'] as String? ?? 'PENDING';
    final festivalTitle = cert['festivalTitle'] as String? ?? '';
    final photoUrl = cert['photoUrl'] as String?;
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

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
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
                radius: 50,
                backgroundColor: ringColor.withValues(alpha: 0.15),
                backgroundImage: photoUrl != null
                    ? CachedNetworkImageProvider(photoUrl)
                    : null,
                child: photoUrl == null
                    ? Icon(Icons.photo, size: 30,
                        color: colors.textTitle.withValues(alpha: 0.3))
                    : null,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: SizedBox(
              width: 110,
              child: Column(
                children: [
                  Text(
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
                  const SizedBox(height: 2),
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
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderItem(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
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
                radius: 50,
                backgroundColor: colors.certRingColor.withValues(alpha: 0.15),
                child: Icon(
                  Icons.add_photo_alternate_outlined,
                  size: 30,
                  color: colors.textTitle.withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 6.0),
            child: Text(
              'no_certification'.tr(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: colors.textTitle.withValues(alpha: 0.35),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CertificationDetailSheet extends StatelessWidget {
  final List<Map<String, dynamic>> certifications;

  const _CertificationDetailSheet({required this.certifications});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundMain,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: colors.textSecondary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                Text(
                  'cert_my_list'.tr(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: colors.textTitle,
                  ),
                ),
              ],
            ),
          ),
          if (certifications.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'cert_no_history'.tr(),
                style: TextStyle(color: colors.textSecondary),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: certifications.length,
              separatorBuilder: (_, __) => Divider(
                height: 1,
                color: colors.textSecondary.withValues(alpha: 0.12),
              ),
              itemBuilder: (context, index) {
                final cert = certifications[index];
                final status = cert['status'] as String? ?? 'PENDING';
                final festivalTitle = cert['festivalTitle'] as String? ?? '';
                final isApproved = status == 'APPROVED';
                final isPending = status == 'PENDING';

                Color statusColor;
                if (isApproved) {
                  statusColor = colors.certRingColor;
                } else if (isPending) {
                  statusColor = Colors.orange;
                } else {
                  statusColor = Colors.grey;
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Icon(Icons.verified_rounded,
                          color: statusColor, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          festivalTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: colors.textTitle,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          isApproved
                              ? 'cert_status_approved'.tr()
                              : isPending
                                  ? 'cert_status_pending'.tr()
                                  : 'cert_status_rejected'.tr(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
