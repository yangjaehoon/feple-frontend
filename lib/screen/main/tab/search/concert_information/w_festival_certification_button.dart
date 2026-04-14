import 'dart:typed_data';
import 'package:feple/common/common.dart';
import 'package:feple/service/certification_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fluttertoast/fluttertoast.dart';

class FestivalCertificationButton extends StatefulWidget {
  final int festivalId;
  final String festivalName;

  const FestivalCertificationButton({
    super.key,
    required this.festivalId,
    required this.festivalName,
  });

  @override
  State<FestivalCertificationButton> createState() =>
      _FestivalCertificationButtonState();
}

class _FestivalCertificationButtonState
    extends State<FestivalCertificationButton> {
  final _certService = CertificationService();
  bool _submitting = false;

  Future<void> _submit() async {
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
      await _certService.submit(
        festivalId: widget.festivalId,
        imageData: imageData,
      );
      if (!mounted) return;
      Fluttertoast.showToast(msg: 'cert_submit_success'.tr());
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString();
      if (msg.contains('이미') || msg.contains('already')) {
        Fluttertoast.showToast(msg: 'cert_already_submitted'.tr());
      } else {
        Fluttertoast.showToast(
            msg: 'cert_submit_failed'.tr(args: [msg]));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: ElevatedButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.verified_rounded, size: 20),
          label: Text(
            _submitting ? 'cert_submitting'.tr() : 'cert_submit'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.certRingColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
          ),
        ),
      ),
    );
  }
}
