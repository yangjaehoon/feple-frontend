import 'dart:typed_data';

import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/service/certification_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../common/common.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';

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
  static const int _maxImageDimension = 1920;
  static const double _photoAreaHeight = 160.0;

  XFile? _pickedFile;
  bool _submitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: _maxImageDimension.toDouble(),
      maxHeight: _maxImageDimension.toDouble(),
    );
    if (picked != null && mounted) setState(() => _pickedFile = picked);
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
      debugPrint('cert submit error: $e');
      final networkKey = networkAwareErrorKey(e, '');
      if (networkKey == 'connection_error') {
        context.showErrorSnackbar('connection_error'.tr());
      } else {
        context.showErrorSnackbar(
          isDioConflict(e) ? 'cert_already_submitted'.tr() : 'cert_submit_failed'.tr(),
        );
      }
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const BottomSheetHandle(),
          const SizedBox(height: 20),

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

          Text(
            'cert_description'.tr(args: [widget.festivalName]),
            style: TextStyle(
              fontSize: 14,
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),

          GestureDetector(
            onTap: _submitting ? null : _pickImage,
            child: Container(
              width: double.infinity,
              height: _photoAreaHeight,
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
                      borderRadius: BorderRadius.circular(16),
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

          LoadingButton(
            label: 'cert_submit'.tr(),
            onPressed: _pickedFile == null ? null : _submit,
            isLoading: _submitting,
            backgroundColor: colors.activate,
            height: 50,
          ),
        ],
      ),
    );
  }
}
