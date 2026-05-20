import 'package:dio/dio.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/song_request_service.dart';
import 'package:flutter/material.dart';

class SongRequestSheet extends StatefulWidget {
  final int artistId;
  final String artistName;

  const SongRequestSheet({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  State<SongRequestSheet> createState() => _SongRequestSheetState();
}

class _SongRequestSheetState extends State<SongRequestSheet> {
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitSuccess = false;
  String? _titleError;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'song_request_title_required'.tr());
      return;
    }
    setState(() { _titleError = null; _submitting = true; });

    try {
      await sl<SongRequestService>().submit(
        artistId: widget.artistId,
        songTitle: title,
        youtubeUrl: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() { _submitting = false; _submitSuccess = true; });
      await Future.delayed(AppDimens.animSuccessDelay);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      debugPrint('song request submit error: $e');
      final backendMsg = e is DioException
          ? (e.response?.data is Map ? e.response!.data['message'] as String? : null)
          : null;
      final isDuplicate = backendMsg?.contains('이미') == true ||
          backendMsg?.contains('already') == true;
      context.showErrorSnackbar(
        isDuplicate ? 'song_request_duplicate'.tr() : 'song_request_failed'.tr(),
      );
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.backgroundMain,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: kBottomNavigationBarHeight +
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
                  borderRadius: BorderRadius.circular(AppDimens.barRadius),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text(
                'song_request_title'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textTitle,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
              child: Text(
                'song_request_desc'.tr(),
                style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.5),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _titleCtrl,
                onChanged: (_) { if (_titleError != null) setState(() => _titleError = null); },
                decoration: InputDecoration(
                  labelText: 'song_request_song_title'.tr(),
                  hintText: 'song_request_song_title_hint'.tr(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  errorText: _titleError,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _urlCtrl,
                keyboardType: TextInputType.url,
                decoration: InputDecoration(
                  labelText: 'song_request_youtube_url'.tr(),
                  hintText: 'song_request_youtube_url_hint'.tr(),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: LoadingButton(
                label: 'song_request_submit'.tr(),
                icon: Icons.send_rounded,
                isLoading: _submitting,
                isSuccess: _submitSuccess,
                onPressed: _submit,
                backgroundColor: context.appColors.activate,
                height: 50,
                borderRadius: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
