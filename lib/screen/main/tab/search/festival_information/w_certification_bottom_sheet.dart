import 'dart:typed_data';

import 'package:feple/common/util/certification_submit_helper.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/common/constant/app_dimensions.dart';
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

  Uint8List? _imageBytes;
  bool _submitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: _maxImageDimension.toDouble(),
      maxHeight: _maxImageDimension.toDouble(),
    );
    if (picked == null || !mounted) return;
    final bytes = await picked.readAsBytes();
    if (mounted) setState(() => _imageBytes = bytes);
  }

  Future<void> _submit() async {
    if (_imageBytes == null) return;
    setState(() => _submitting = true);
    final success = await submitCertification(
      context,
      certService: widget.certService,
      festivalId: widget.festivalId,
      imageData: _imageBytes!,
    );
    if (!mounted) return;
    if (success) {
      context.showSuccessSnackbar('cert_submit_success'.tr());
      Navigator.pop(context);
    }
    setState(() => _submitting = false);
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
          _buildHeader(colors),
          const SizedBox(height: 24),
          _buildPhotoArea(colors),
          const SizedBox(height: 20),
          LoadingButton(
            label: 'cert_submit'.tr(),
            onPressed: _imageBytes == null ? null : _submit,
            isLoading: _submitting,
            backgroundColor: colors.activate,
            height: 50,
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AbstractThemeColors colors) {
    return Column(
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
              style: TextStyle(fontSize: AppDimens.fontSizeXxl, fontWeight: FontWeight.w800, color: colors.textTitle),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'cert_description'.tr(args: [widget.festivalName]),
          style: TextStyle(fontSize: AppDimens.fontSizeMd, color: colors.textSecondary, height: 1.5),
        ),
      ],
    );
  }

  // 사진 선택 후에도 다시 탭해서 바꿀 수 있다는 어포던스가 없어 추가 —
  // ImagePickerBox(image_collection)와 동일한 패턴
  Widget _buildChangeBadge(AbstractThemeColors colors) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: colors.activate,
        shape: BoxShape.circle,
        border: Border.all(color: colors.surface, width: 2),
      ),
      child: const Icon(Icons.edit_rounded, color: Colors.white, size: 16),
    );
  }

  Widget _buildPhotoArea(AbstractThemeColors colors) {
    return GestureDetector(
      onTap: _submitting ? null : _pickImage,
      child: Container(
        width: double.infinity,
        height: _photoAreaHeight,
        decoration: BoxDecoration(
          color: colors.backgroundMain,
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
          border: Border.all(
            color: _imageBytes != null
                ? colors.activate
                : colors.textSecondary.withValues(alpha: 0.2),
            width: _imageBytes != null ? 2 : 1,
          ),
        ),
        child: _imageBytes != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_imageBytes!, fit: BoxFit.cover),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: _buildChangeBadge(colors),
                    ),
                  ],
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
                    style: TextStyle(fontSize: AppDimens.fontSizeSm, color: colors.textSecondary),
                  ),
                ],
              ),
      ),
    );
  }
}
