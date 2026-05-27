import 'package:feple/common/common.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/artist_suggestion_service.dart';
import 'package:flutter/material.dart';

class ArtistSuggestionSheet extends StatefulWidget {
  const ArtistSuggestionSheet({super.key});

  @override
  State<ArtistSuggestionSheet> createState() => _ArtistSuggestionSheetState();
}

class _ArtistSuggestionSheetState extends State<ArtistSuggestionSheet> {
  final _nameCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _submitting = false;
  String? _nameError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = 'artist_suggestion_name_required'.tr());
      return;
    }
    setState(() { _nameError = null; _submitting = true; });

    try {
      await sl<ArtistSuggestionService>().submit(
        artistName: name,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      context.showSuccessSnackbar('artist_suggestion_success'.tr());
    } catch (e) {
      if (!mounted) return;
      debugPrint('artist suggestion submit error: $e');
      final backendMsg = dioBackendMessage(e);
      final isDuplicate = backendMsg?.contains('이미') == true ||
          backendMsg?.contains('already') == true;
      context.showErrorSnackbar(
        isDuplicate
            ? 'artist_suggestion_duplicate'.tr()
            : 'artist_suggestion_failed'.tr(),
      );
      if (mounted) setState(() { _submitting = false; });
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
            const BottomSheetHandle(),
            ..._buildHeader(colors),
            ..._buildFormFields(colors),
            const SizedBox(height: 20),
            _buildSubmitButton(context),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHeader(AbstractThemeColors colors) => [
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        'artist_suggestion_title'.tr(),
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
        'artist_suggestion_desc'.tr(),
        style: TextStyle(fontSize: 13, color: colors.textSecondary, height: 1.5),
      ),
    ),
  ];

  List<Widget> _buildFormFields(AbstractThemeColors colors) => [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _nameCtrl,
        onChanged: (_) {
          if (_nameError != null) setState(() => _nameError = null);
        },
        decoration: InputDecoration(
          labelText: 'artist_suggestion_name_label'.tr(),
          hintText: 'artist_suggestion_name_hint'.tr(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          errorText: _nameError,
        ),
      ),
    ),
    const SizedBox(height: 12),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _noteCtrl,
        maxLines: 3,
        decoration: InputDecoration(
          labelText: 'artist_suggestion_note_label'.tr(),
          hintText: 'artist_suggestion_note_hint'.tr(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ),
  ];

  Widget _buildSubmitButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LoadingButton(
        label: 'artist_suggestion_submit'.tr(),
        icon: Icons.send_rounded,
        isLoading: _submitting,
        onPressed: _submit,
        backgroundColor: context.appColors.activate,
        height: 50,
        borderRadius: 12,
      ),
    );
  }
}
