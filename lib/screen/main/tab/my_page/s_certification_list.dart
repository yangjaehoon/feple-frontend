import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
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
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _hasError = false; });
    try {
      final list = await _certService.getMyCertifications();
      if (mounted) setState(() { _certifications = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _certifications = []; _loading = false; _hasError = true; });
    }
  }

  /// 에러·빈 상태를 RefreshIndicator가 감지할 수 있도록 스크롤 가능하게 감쌉니다.
  Widget _buildScrollable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildSkeleton(AbstractThemeColors colors) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 3,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, __) => Container(
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
            SkeletonBox(
              width: 90,
              height: 90,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(height: 15),
                    SizedBox(height: 8),
                    SkeletonBox(width: 80, height: 22,
                        borderRadius: BorderRadius.all(Radius.circular(20))),
                    SizedBox(height: 6),
                    SkeletonBox(width: 60, height: 11),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
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
        foregroundColor: colors.textTitle,
        title: Text('festival_certification'.tr()),
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
      body: RefreshIndicator(
        onRefresh: _load,
        color: colors.activate,
        child: _loading
            ? _buildSkeleton(colors)
            : _hasError
                ? _buildScrollable(
                    ErrorState(
                      message: 'err_fetch_data'.tr(args: ['']),
                      onRetry: _load,
                    ),
                  )
                : _certifications.isEmpty
                    ? _buildScrollable(
                        EmptyState(
                          icon: Icons.verified_outlined,
                          title: 'cert_no_history'.tr(),
                          subtitle: 'cert_no_history_hint'.tr(),
                        ),
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        itemCount: _certifications.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final cert = _certifications[index];
                          return _CertCard(cert: cert, colors: colors);
                        },
                      ),
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
      statusColor = AppColors.statusPending;
      statusLabel = 'cert_status_pending'.tr();
    } else {
      statusColor = colors.textSecondary;
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
                      placeholder: (_, __) => const SkeletonBox(height: double.infinity),
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
                      style: TextStyle(fontSize: 11, color: colors.textSecondary),
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
