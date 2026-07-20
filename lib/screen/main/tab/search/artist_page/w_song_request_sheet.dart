import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/common/util/url_validator.dart';
import 'package:feple/common/widget/w_app_text_field.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/injection.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/service/song_request_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  final _songRequestService = sl<SongRequestService>();
  final _titleCtrl = TextEditingController();
  final _urlCtrl = TextEditingController();
  bool _submitting = false;
  bool _submitSuccess = false;
  String? _titleError;
  String? _urlError;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  bool get _isDirty =>
      _titleCtrl.text.trim().isNotEmpty || _urlCtrl.text.trim().isNotEmpty;

  Future<void> _handleClose() async {
    if (_submitting) return;
    if (!_isDirty) {
      Navigator.pop(context);
      return;
    }
    final ctx = context;
    final confirmed = await showConfirmDialog(
      ctx,
      title: 'discard_changes'.tr(),
      content: 'discard_changes_msg'.tr(),
      confirmLabel: 'discard'.tr(),
    );
    if (confirmed && ctx.mounted) Navigator.pop(ctx);
  }

  Future<void> _submit() async {
    final userId = context.read<UserProvider>().currentUserId;
    if (userId == null) {
      context.showInfoSnackbar('no_login_info'.tr());
      return;
    }
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) {
      setState(() => _titleError = 'song_request_title_required'.tr());
      return;
    }
    final rawUrl = _urlCtrl.text.trim();
    if (rawUrl.isNotEmpty && !isValidYoutubeUrl(rawUrl)) {
      setState(() => _urlError = 'song_request_invalid_url'.tr());
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _titleError = null;
      _urlError = null;
      _submitting = true;
    });

    try {
      await _songRequestService.submit(
        artistId: widget.artistId,
        songTitle: title,
        youtubeUrl: _urlCtrl.text.trim().isEmpty ? null : _urlCtrl.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _submitSuccess = true;
      });
      await Future.delayed(AppDimens.animSuccessDelay);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      debugPrint('song request submit error: $e');
      context.showErrorSnackbar(
        networkAwareErrorKey(
          e,
          isDioConflict(e) ? 'song_request_duplicate' : 'song_request_failed',
        ).tr(),
      );
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleClose();
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: colors.backgroundMain,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(AppDimens.shapeSheet),
            ),
          ),
          padding: EdgeInsets.only(
            bottom:
                kBottomNavigationBarHeight +
                MediaQuery.of(context).padding.bottom +
                24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),
              const BottomSheetHandle(),
              ..._buildHeader(colors),
              ..._buildFormFields(),
              const SizedBox(height: 20),
              _buildSubmitButton(colors),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildHeader(AbstractThemeColors colors) => [
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'song_request_title'.tr(),
              style: TextStyle(
                fontSize: AppDimens.fontSizeXxl,
                fontWeight: FontWeight.w800,
                color: colors.textTitle,
              ),
            ),
          ),
          IconButton(
            tooltip: 'close'.tr(),
            onPressed: _handleClose,
            icon: Icon(Icons.close_rounded, color: colors.textSecondary),
          ),
        ],
      ),
    ),
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Text(
        'song_request_desc'.tr(),
        style: TextStyle(
          fontSize: AppDimens.fontSizeSm,
          color: colors.textSecondary,
          height: 1.5,
        ),
      ),
    ),
  ];

  List<Widget> _buildFormFields() => [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AppTextField(
        controller: _titleCtrl,
        icon: Icons.music_note_rounded,
        hintText: 'song_request_song_title_hint'.tr(),
        semanticsLabel: 'song_request_song_title'.tr(),
        autofocus: true,
        textInputAction: TextInputAction.next,
        onChanged: (_) {
          if (_titleError != null) setState(() => _titleError = null);
        },
        errorText: _titleError,
      ),
    ),
    const SizedBox(height: 12),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AppTextField(
        controller: _urlCtrl,
        icon: Icons.link_rounded,
        hintText: 'song_request_youtube_url_hint'.tr(),
        semanticsLabel: 'song_request_youtube_url'.tr(),
        keyboardType: TextInputType.url,
        textInputAction: TextInputAction.done,
        onChanged: (_) {
          if (_urlError != null) setState(() => _urlError = null);
        },
        errorText: _urlError,
      ),
    ),
  ];

  Widget _buildSubmitButton(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LoadingButton(
        label: 'song_request_submit'.tr(),
        icon: Icons.send_rounded,
        isLoading: _submitting,
        isSuccess: _submitSuccess,
        onPressed: _submit,
        backgroundColor: colors.activate,
        height: 50,
        borderRadius: 12,
      ),
    );
  }
}
