import 'dart:typed_data';

import 'package:feple/service/certification_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../common/common.dart';

class CertificationBottomSheet extends StatefulWidget {
  final String festivalName;
  final int festivalId;
  final CertificationService certService;

  const CertificationBottomSheet({
    super.key,
    required this.festivalName,
    required this.festivalId,
    required this.certService,
  });

  @override
  State<CertificationBottomSheet> createState() =>
      _CertificationBottomSheetState();
}

class _CertificationBottomSheetState extends State<CertificationBottomSheet> {
  XFile? _pickedFile;
  bool _submitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked != null) setState(() => _pickedFile = picked);
  }

  Future<void> _submit() async {
    if (_pickedFile == null) return;
    setState(() => _submitting = true);
    try {
      final imageData = await _pickedFile!.readAsBytes();
      await widget.certService.submit(
        festivalId: widget.festivalId,
        imageData: imageData,
      );
      if (!mounted) return;
      context.showSuccessSnackbar('cert_submit_success'.tr());
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      context.showErrorSnackbar(
        msg.contains('이미') || msg.contains('already')
            ? 'cert_already_submitted'.tr()
            : 'cert_submit_failed'.tr(args: [msg]),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final mediaQuery = MediaQuery.of(context);
    final bottomInset = mediaQuery.viewInsets.bottom + mediaQuery.padding.bottom;

    return Container(
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 핸들
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textSecondary.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 타이틀
          Row(
            children: [
              Icon(Icons.verified_rounded, color: colors.activate, size: 22),
              const SizedBox(width: 8),
              Text(
                'cert_title'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // 안내 문구
          Text(
            'cert_description'.tr(args: [widget.festivalName]),
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          // 사진 첨부 영역
          GestureDetector(
            onTap: _submitting ? null : _pickImage,
            child: Container(
              width: double.infinity,
              height: 160,
              decoration: BoxDecoration(
                color: colors.backgroundMain,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _pickedFile != null
                      ? colors.activate
                      : colors.textSecondary.withValues(alpha: 0.2),
                  width: _pickedFile != null ? 2 : 1,
                ),
              ),
              child: _pickedFile != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: FutureBuilder<Uint8List>(
                        future: _pickedFile!.readAsBytes(),
                        builder: (ctx, snap) {
                          if (snap.hasData) {
                            return Image.memory(snap.data!, fit: BoxFit.cover);
                          }
                          return const Center(child: CircularProgressIndicator());
                        },
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined,
                            size: 36, color: colors.textSecondary.withValues(alpha: 0.5)),
                        const SizedBox(height: 8),
                        Text(
                          'cert_photo_hint'.tr(),
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.textSecondary,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 20),

          // 제출 버튼
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: (_pickedFile == null || _submitting) ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: colors.activate,
                foregroundColor: Colors.white,
                disabledBackgroundColor: colors.activate.withValues(alpha: 0.3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation(Colors.white)),
                    )
                  : Text(
                      'cert_submit'.tr(),
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
