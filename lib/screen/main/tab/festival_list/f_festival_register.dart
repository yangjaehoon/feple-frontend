import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/constant/festival_constants.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/screen/main/tab/festival_list/w_festival_form_fields.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/festival_preview_provider.dart';

class FestivalRegisterPage extends StatefulWidget {
  const FestivalRegisterPage({super.key});

  @override
  State<FestivalRegisterPage> createState() => _FestivalRegisterPageState();
}

class _FestivalRegisterPageState extends State<FestivalRegisterPage> {
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

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _posterUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _startDate = picked;
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_startDate == null || _endDate == null) {
      context.showInfoSnackbar('festival_reg_start_end_date_req'.tr());
      return;
    }
    if (_selectedRegion == null) {
      context.showInfoSnackbar('festival_reg_region_req'.tr());
      return;
    }

    setState(() => _isLoading = true);
    try {
      await DioClient.dio.post('/festivals', data: {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'startDate': _startDate!.toIso8601String().split('T').first,
        'endDate': _endDate!.toIso8601String().split('T').first,
        'posterUrl': _posterUrlController.text.trim(),
        'genres': _selectedGenres.toList(),
        'region': _selectedRegion,
      });

      if (mounted) {
        context.read<FestivalPreviewProvider>().refresh();
        context.showSuccessSnackbar('festival_reg_register_success'.tr());
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        context.showErrorSnackbar('festival_reg_register_failed'.tr(args: [e.toString()]));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      appBar: SecondaryAppBar(title: 'festival_reg_register_title'.tr(), elevation: 0),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            FestivalTextField(
              controller: _titleController,
              label: 'label_festival_name'.tr(),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'label_input_name_req'.tr() : null,
            ),
            const SizedBox(height: 16),
            FestivalTextField(
              controller: _descriptionController,
              label: 'label_desc'.tr(),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            FestivalTextField(
              controller: _locationController,
              label: 'label_location'.tr(),
            ),
            const SizedBox(height: 16),
            FestivalTextField(
              controller: _posterUrlController,
              label: 'label_poster_url'.tr(),
            ),
            const SizedBox(height: 16),

            // 날짜 선택
            Row(
              children: [
                Expanded(
                  child: FestivalDateTile(
                    label: 'label_start_date'.tr(),
                    date: _startDate,
                    onTap: () => _pickDate(isStart: true),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FestivalDateTile(
                    label: 'label_end_date'.tr(),
                    date: _endDate,
                    onTap: () => _pickDate(isStart: false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 장르 선택
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
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? colors.activate : colors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? colors.activate : colors.listDivider,
                      ),
                    ),
                    child: Text(
                      label.tr(),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : colors.textTitle,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // 지역 선택
            FestivalSectionLabel('label_region'.tr()),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(12),
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
            const SizedBox(height: 32),

            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.activate,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'btn_register'.tr(),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
