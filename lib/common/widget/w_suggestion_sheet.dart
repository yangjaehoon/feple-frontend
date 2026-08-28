import 'package:feple/common/common.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 아티스트/축제 등록 제안 시트 공용 위젯.
/// [i18nPrefix]로 화면별 문구(예: `artist_suggestion_*`, `festival_suggestion_*`)를,
/// [submit]으로 화면별 서비스 호출을 주입받는다.
class SuggestionSheet extends StatefulWidget {
  final String i18nPrefix;
  final Future<void> Function({required String name, String? note}) submit;

  const SuggestionSheet({
    super.key,
    required this.i18nPrefix,
    required this.submit,
  });

  @override
  State<SuggestionSheet> createState() => _SuggestionSheetState();
}

class _SuggestionSheetState extends State<SuggestionSheet> {
  final _nameCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _submitting = false;
  String? _nameError;

  String _key(String suffix) => '${widget.i18nPrefix}_$suffix';

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = _key('name_required').tr());
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() {
      _nameError = null;
      _submitting = true;
    });

    try {
      await widget.submit(
        name: name,
        note: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
      );
      if (!mounted) return;
      Navigator.pop(context, true);
      context.showSuccessSnackbar(_key('success').tr());
    } catch (e) {
      if (!mounted) return;
      debugPrint('${widget.i18nPrefix} submit error: $e');
      final networkKey = networkAwareErrorKey(e, '');
      if (networkKey == 'connection_error') {
        context.showErrorSnackbar('connection_error'.tr());
      } else {
        context.showErrorSnackbar(
          isDioConflict(e) ? _key('duplicate').tr() : _key('failed').tr(),
        );
      }
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          color: colors.backgroundMain,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.shapeSheet)),
        ),
        padding: EdgeInsets.only(
          bottom: kBottomNavigationBarHeight +
              MediaQuery.paddingOf(context).bottom +
              24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: AppDimens.space12),
            const BottomSheetHandle(),
            ..._buildHeader(colors),
            ..._buildFormFields(colors),
            const SizedBox(height: AppDimens.space20),
            _buildSubmitButton(colors),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildHeader(AbstractThemeColors colors) => [
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      child: Text(
        _key('title').tr(),
        style: TextStyle(
          fontSize: AppDimens.fontSizeXxl,
          fontWeight: FontWeight.w800,
          color: colors.textTitle,
        ),
      ),
    ),
    Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
      child: Text(
        _key('desc').tr(),
        style: TextStyle(fontSize: AppDimens.fontSizeSm, color: colors.textSecondary, height: 1.5),
      ),
    ),
  ];

  List<Widget> _buildFormFields(AbstractThemeColors colors) => [
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _nameCtrl,
        autofocus: true,
        textInputAction: TextInputAction.next,
        onChanged: (_) {
          if (_nameError != null) setState(() => _nameError = null);
        },
        decoration: InputDecoration(
          labelText: _key('name_label').tr(),
          hintText: _key('name_hint').tr(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          errorText: _nameError,
        ),
      ),
    ),
    const SizedBox(height: AppDimens.space12),
    Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: TextField(
        controller: _noteCtrl,
        maxLines: 3,
        textInputAction: TextInputAction.done,
        decoration: InputDecoration(
          labelText: _key('note_label').tr(),
          hintText: _key('note_hint').tr(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ),
  ];

  Widget _buildSubmitButton(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LoadingButton(
        label: _key('submit').tr(),
        icon: Icons.send_rounded,
        isLoading: _submitting,
        onPressed: _submit,
        backgroundColor: colors.activate,
        height: 50,
        borderRadius: 12,
      ),
    );
  }
}
