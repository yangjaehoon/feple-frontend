import 'package:feple/common/common.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_keyboard_dismiss.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/constant/festival_constants.dart';
import 'package:feple/injection.dart';
import 'package:feple/screen/main/tab/festival_list/w_festival_form_fields.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/festival_preview_provider.dart';

class FestivalRegisterScreen extends StatefulWidget {
  const FestivalRegisterScreen({super.key});

  @override
  State<FestivalRegisterScreen> createState() => _FestivalRegisterScreenState();
}

class _FestivalRegisterScreenState extends State<FestivalRegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _posterUrlController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  final Set<String> _selectedGenres = {};
  String? _selectedRegion;
  bool _isLoading = false;

  bool get _isDirty =>
      _titleController.text.isNotEmpty ||
      _descriptionController.text.isNotEmpty ||
      _locationController.text.isNotEmpty ||
      _posterUrlController.text.isNotEmpty ||
      _startDate != null ||
      _endDate != null ||
      _selectedGenres.isNotEmpty ||
      _selectedRegion != null;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _posterUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickStartDate() async {
    final picked = await _showDatePicker();
    if (picked != null && mounted) setState(() => _startDate = picked);
  }

  Future<void> _pickEndDate() async {
    final picked = await _showDatePicker();
    if (picked != null && mounted) setState(() => _endDate = picked);
  }

  Future<DateTime?> _showDatePicker() => showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        builder: (ctx, child) => Theme(
          data: Theme.of(ctx).copyWith(
            colorScheme: Theme.of(ctx).colorScheme.copyWith(
              primary: ctx.appColors.activate,
            ),
          ),
          child: child!,
        ),
      );

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      context.showInfoSnackbar('festival_reg_start_end_date_req'.tr());
      return;
    }
    if (_endDate!.isBefore(_startDate!)) {
      context.showInfoSnackbar('festival_reg_end_before_start'.tr());
      return;
    }
    if (_selectedRegion == null) {
      context.showInfoSnackbar('festival_reg_region_req'.tr());
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() => _isLoading = true);
    try {
      await sl<FestivalService>().submitFestival(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        location: _locationController.text.trim(),
        startDate: _startDate!.toYMD,
        endDate: _endDate!.toYMD,
        posterUrl: _posterUrlController.text.trim(),
        genres: _selectedGenres.toList(),
        region: _selectedRegion!,
      );

      if (mounted) {
        context.read<FestivalPreviewProvider>().refresh(force: true);
        context.showSuccessSnackbar('festival_reg_register_success'.tr());
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        debugPrint('festival register error: $e');
        context.showErrorSnackbar(networkAwareErrorKey(e, 'festival_reg_register_failed').tr());
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildDateRow() {
    return Row(
      children: [
        Expanded(
          child: FestivalDateTile(
            label: 'label_start_date'.tr(),
            date: _startDate,
            onTap: _pickStartDate,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: FestivalDateTile(
            label: 'label_end_date'.tr(),
            date: _endDate,
            onTap: _pickEndDate,
          ),
        ),
      ],
    );
  }

  Widget _buildGenreSelector(AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FestivalSectionLabel('label_genre'.tr()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: kGenreOptions.map((opt) {
            final (value, label) = opt;
            final selected = _selectedGenres.contains(value);
            return GestureDetector(
              onTap: () => setState(() {
                selected
                    ? _selectedGenres.remove(value)
                    : _selectedGenres.add(value);
              }),
              child: AnimatedContainer(
                duration: AppDimens.animXFast,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? colors.activate : colors.surface,
                  borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                  border: Border.all(
                    color: selected ? colors.activate : colors.listDivider,
                  ),
                ),
                child: Text(
                  label.tr(),
                  style: TextStyle(
                    fontSize: AppDimens.fontSizeMd,
                    fontWeight: FontWeight.w600,
                    color: selected ? Colors.white : colors.textTitle,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildRegionDropdown(AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FestivalSectionLabel('label_region'.tr()),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
            border: Border.all(color: colors.listDivider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedRegion,
              hint: Text('label_region'.tr(),
                  style: TextStyle(color: colors.textSecondary)),
              isExpanded: true,
              dropdownColor: colors.surface,
              items: kRegionOptions.map((opt) {
                final (value, label) = opt;
                return DropdownMenuItem(
                  value: value,
                  child: Text(label.tr(),
                      style: TextStyle(color: colors.textTitle)),
                );
              }).toList(),
              onChanged: (v) => setState(() => _selectedRegion = v),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _onPopInvoked(bool didPop) async {
    if (didPop) return;
    if (_isLoading) return;
    if (!_isDirty) { Navigator.of(context).pop(); return; }
    final ctx = context;
    final confirmed = await showConfirmDialog(
      ctx,
      title: 'discard_changes'.tr(),
      content: 'discard_changes_msg'.tr(),
      confirmLabel: 'discard'.tr(),
    );
    if (confirmed && ctx.mounted) Navigator.of(ctx).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _onPopInvoked(didPop),
      child: Scaffold(
        backgroundColor: colors.backgroundMain,
        body: KeyboardDismiss(
          child: Column(
            children: [
              SecondaryAppBar(title: 'festival_reg_register_title'.tr()),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: _buildFormContent(colors),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildFormContent(AbstractThemeColors colors) => [
    FestivalTextField(
      controller: _titleController,
      label: 'label_festival_name'.tr(),
      validator: (v) => v == null || v.trim().isEmpty ? 'label_input_name_req'.tr() : null,
    ),
    const SizedBox(height: 16),
    FestivalTextField(controller: _descriptionController, label: 'label_desc'.tr(), maxLines: 3),
    const SizedBox(height: 16),
    FestivalTextField(controller: _locationController, label: 'label_location'.tr()),
    const SizedBox(height: 16),
    FestivalTextField(controller: _posterUrlController, label: 'label_poster_url'.tr()),
    const SizedBox(height: 16),
    _buildDateRow(),
    const SizedBox(height: 20),
    _buildGenreSelector(colors),
    const SizedBox(height: 20),
    _buildRegionDropdown(colors),
    const SizedBox(height: 32),
    LoadingButton(
      label: 'btn_register'.tr(),
      onPressed: _submit,
      isLoading: _isLoading,
      backgroundColor: colors.activate,
    ),
  ];
}
