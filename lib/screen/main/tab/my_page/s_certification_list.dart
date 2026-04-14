import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/model/poster_model.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/certification_service.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';

class CertificationListScreen extends StatefulWidget {
  const CertificationListScreen({super.key});

  @override
  State<CertificationListScreen> createState() =>
      _CertificationListScreenState();
}

class _CertificationListScreenState extends State<CertificationListScreen> {
  final _certService = CertificationService();
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
      builder: (_) => _SubmitCertificationSheet(certService: _certService),
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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openSubmitSheet,
        backgroundColor: colors.certRingColor,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: Text(
          'cert_submit'.tr(),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
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
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: _certifications.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
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
    final photoUrl = cert['photoUrl'] as String?;
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
          // 인증 사진
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16)),
            child: SizedBox(
              width: 90,
              height: 90,
              child: photoUrl != null
                  ? CachedNetworkImage(
                      imageUrl: photoUrl,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          _buildPhotoPlaceholder(),
                    )
                  : _buildPhotoPlaceholder(),
            ),
          ),
          // 내용
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                  Row(
                    children: [
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
                            Icon(Icons.circle,
                                size: 7, color: statusColor),
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
                    ],
                  ),
                  if (!isPending && !isApproved &&
                      rejectionMessage != null &&
                      rejectionMessage.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      'cert_rejection_reason'
                          .tr(args: [rejectionMessage]),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[500],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      createdAt.length >= 10 ? createdAt.substring(0, 10) : createdAt,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary,
                      ),
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

class _SubmitCertificationSheet extends StatefulWidget {
  final CertificationService certService;

  const _SubmitCertificationSheet({required this.certService});

  @override
  State<_SubmitCertificationSheet> createState() =>
      _SubmitCertificationSheetState();
}

class _SubmitCertificationSheetState
    extends State<_SubmitCertificationSheet> {
  List<PosterModel> _festivals = [];
  PosterModel? _selectedFestival;
  bool _loadingFestivals = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadFestivals();
  }

  Future<void> _loadFestivals() async {
    try {
      final res = await DioClient.dio.get('/festivals');
      final list = (res.data as List)
          .map((j) => PosterModel.fromJson(j))
          .toList();
      if (mounted) setState(() { _festivals = list; _loadingFestivals = false; });
    } catch (_) {
      if (mounted) setState(() { _loadingFestivals = false; });
    }
  }

  Future<void> _submit() async {
    if (_selectedFestival == null) {
      Fluttertoast.showToast(msg: '페스티벌을 선택해주세요.');
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked == null) return;

    setState(() => _submitting = true);
    try {
      final Uint8List imageData = await picked.readAsBytes();
      await widget.certService.submit(
        festivalId: _selectedFestival!.id,
        imageData: imageData,
      );
      if (!mounted) return;
      Fluttertoast.showToast(msg: 'cert_submit_success'.tr());
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('이미') || msg.contains('already')) {
        Fluttertoast.showToast(msg: 'cert_already_submitted'.tr());
      } else {
        Fluttertoast.showToast(msg: 'cert_submit_failed'.tr(args: [msg]));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
            child: Text(
              'cert_submit_title'.tr(),
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.textTitle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(
              'cert_photo_guide'.tr(),
              style: TextStyle(
                  fontSize: 13, color: colors.textSecondary, height: 1.5),
            ),
          ),
          // 페스티벌 선택
          _loadingFestivals
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: DropdownButtonFormField<PosterModel>(
                    value: _selectedFestival,
                    decoration: InputDecoration(
                      labelText: 'tab_concert'.tr(),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 12),
                    ),
                    isExpanded: true,
                    items: _festivals
                        .map((f) => DropdownMenuItem(
                              value: f,
                              child: Text(
                                f.title,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 14),
                              ),
                            ))
                        .toList(),
                    onChanged: (val) =>
                        setState(() => _selectedFestival = val),
                  ),
                ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.add_photo_alternate_rounded),
                label: Text(
                  _submitting
                      ? 'cert_submitting'.tr()
                      : 'cert_select_photo'.tr(),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.certRingColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
