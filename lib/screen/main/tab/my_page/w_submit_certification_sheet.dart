import 'dart:typed_data';

import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/certification_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SubmitCertificationSheet extends StatefulWidget {
  final CertificationService certService;

  const SubmitCertificationSheet({super.key, required this.certService});

  @override
  State<SubmitCertificationSheet> createState() =>
      _SubmitCertificationSheetState();
}

class _SubmitCertificationSheetState extends State<SubmitCertificationSheet> {
  List<FestivalModel> _festivals = [];
  FestivalModel? _selectedFestival;
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
      final list = (res.data as List).map((j) => FestivalModel.fromJson(j)).toList();
      if (mounted) setState(() { _festivals = list; _loadingFestivals = false; });
    } catch (_) {
      if (mounted) setState(() { _loadingFestivals = false; });
    }
  }

  Future<void> _submit() async {
    if (_selectedFestival == null) {
      context.showInfoSnackbar('페스티벌을 선택해주세요.');
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
      context.showSuccessSnackbar('cert_submit_success'.tr());
      Navigator.pop(context, true);
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

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundMain,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            kBottomNavigationBarHeight +
            MediaQuery.of(context).padding.bottom +
            24,
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
          _loadingFestivals
              ? const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator()),
                )
              : Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: DropdownButtonFormField<FestivalModel>(
                    key: ValueKey(_selectedFestival),
                    initialValue: _selectedFestival,
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
                    onChanged: (val) => setState(() => _selectedFestival = val),
                  ),
                ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LoadingButton(
              label: 'cert_select_photo'.tr(),
              icon: Icons.add_photo_alternate_rounded,
              isLoading: _submitting,
              onPressed: _submit,
              backgroundColor: colors.certRingColor,
              height: 50,
              borderRadius: 12,
            ),
          ),
        ],
      ),
    );
  }
}
