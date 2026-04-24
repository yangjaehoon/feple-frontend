import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/certification_service.dart';
import 'package:flutter/material.dart';

import 'w_submit_certification_sheet.dart';

class CertificationListScreen extends StatefulWidget {
  const CertificationListScreen({super.key});

  @override
  State<CertificationListScreen> createState() =>
      _CertificationListScreenState();
}

class _CertificationListScreenState extends State<CertificationListScreen> {
  final _certService = sl<CertificationService>();
  List<Map<String, dynamic>> _certifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final list = await _certService.getMyCertifications();
      if (mounted) setState(() { _certifications = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _certifications = []; _loading = false; });
    }
  }

  Future<void> _openSubmitSheet() async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SubmitCertificationSheet(certService: _certService),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.backgroundMain,
      appBar: AppBar(
        backgroundColor: colors.backgroundMain,
        elevation: 0,
        title: Text(
          'festival_certification'.tr(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: colors.textTitle,
          ),
        ),
        iconTheme: IconThemeData(color: colors.textTitle),
        actions: [
          TextButton.icon(
            onPressed: _openSubmitSheet,
            icon: Icon(Icons.add_photo_alternate_rounded,
                color: colors.certRingColor, size: 20),
            label: Text(
              'cert_submit'.tr(),
              style: TextStyle(
                color: colors.certRingColor,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _certifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_outlined,
                          size: 56,
                          color: colors.textSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text(
                        'cert_no_history'.tr(),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: _certifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final cert = _certifications[index];
                    return _CertCard(cert: cert, colors: colors);
                  },
                ),
    );
  }
}

class _CertCard extends StatelessWidget {
  final Map<String, dynamic> cert;
  final AbstractThemeColors colors;

  const _CertCard({required this.cert, required this.colors});

  @override
  Widget build(BuildContext context) {
    final status = cert['status'] as String? ?? 'PENDING';
    final festivalTitle = cert['festivalTitle'] as String? ?? '';
    final posterUrl = cert['festivalPosterUrl'] as String? ?? cert['photoUrl'] as String?;
    final rejectionMessage = cert['rejectionMessage'] as String?;
    final createdAt = cert['createdAt'] as String?;

    final isApproved = status == 'APPROVED';
    final isPending = status == 'PENDING';

    Color statusColor;
    String statusLabel;
    if (isApproved) {
      statusColor = colors.certRingColor;
      statusLabel = 'cert_status_approved'.tr();
    } else if (isPending) {
      statusColor = Colors.orange;
      statusLabel = 'cert_status_pending'.tr();
    } else {
      statusColor = Colors.grey;
      statusLabel = 'cert_status_rejected'.tr();
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(16)),
            child: SizedBox(
              width: 90,
              height: 90,
              child: posterUrl != null
                  ? CachedNetworkImage(
                      imageUrl: posterUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => _buildPhotoPlaceholder(),
                    )
                  : _buildPhotoPlaceholder(),
            ),
          ),
          Expanded(
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    festivalTitle,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textTitle,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.circle, size: 7, color: statusColor),
                        const SizedBox(width: 4),
                        Text(
                          statusLabel,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isPending &&
                      !isApproved &&
                      rejectionMessage != null &&
                      rejectionMessage.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'cert_rejection_reason'.tr(args: [rejectionMessage]),
                      style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      createdAt.length >= 10
                          ? createdAt.substring(0, 10)
                          : createdAt,
                      style: TextStyle(
                          fontSize: 11, color: colors.textSecondary),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPlaceholder() {
    return Container(
      color: colors.certRingColor.withValues(alpha: 0.1),
      child: Icon(Icons.photo_rounded,
          color: colors.textSecondary.withValues(alpha: 0.4), size: 32),
    );
  }
}
