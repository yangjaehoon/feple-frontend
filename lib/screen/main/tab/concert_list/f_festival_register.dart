import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/festival_constants.dart';
import 'package:fast_app_base/network/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/FestivalPreviewProvider.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('시작일과 종료일을 선택해주세요.')),
      );
      return;
    }
    if (_selectedRegion == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('지역을 선택해주세요.')),
      );
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
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('페스티벌이 등록되었습니다.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('등록 실패: $e')),
        );
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
      appBar: AppBar(
        backgroundColor: colors.appBarColor,
        title: const Text(
          '페스티벌 등록',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _buildTextField(
              controller: _titleController,
              label: '페스티벌 이름',
              validator: (v) =>
                  v == null || v.trim().isEmpty ? '이름을 입력해주세요.' : null,
              colors: colors,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _descriptionController,
              label: '설명',
              maxLines: 3,
              colors: colors,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _locationController,
              label: '장소',
              colors: colors,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              controller: _posterUrlController,
              label: '포스터 URL (S3 key)',
              colors: colors,
            ),
            const SizedBox(height: 16),

            // 날짜 선택
            Row(
              children: [
                Expanded(
                  child: _buildDateTile(
                    label: '시작일',
                    date: _startDate,
                    onTap: () => _pickDate(isStart: true),
                    colors: colors,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateTile(
                    label: '종료일',
                    date: _endDate,
                    onTap: () => _pickDate(isStart: false),
                    colors: colors,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // 장르 선택
            _buildSectionLabel('장르', colors),
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
                      label,
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
            _buildSectionLabel('지역', colors),
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
                  hint: Text('지역 선택',
                      style: TextStyle(color: colors.textSecondary)),
                  isExpanded: true,
                  dropdownColor: colors.surface,
                  items: kRegionOptions.map((opt) {
                    final (value, label) = opt;
                    return DropdownMenuItem(
                      value: value,
                      child: Text(label,
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
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                      )
                    : const Text(
                        '등록',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required AbstractThemeColors colors,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: TextStyle(color: colors.textTitle),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.textSecondary),
        filled: true,
        fillColor: colors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.listDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.listDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: colors.activate, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildDateTile({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
    required AbstractThemeColors colors,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colors.listDivider),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 16, color: colors.activate),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 11, color: colors.textSecondary)),
                  const SizedBox(height: 2),
                  Text(
                    date != null
                        ? '${date.year}.${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}'
                        : '선택',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: date != null
                          ? colors.textTitle
                          : colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionLabel(String label, AbstractThemeColors colors) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: colors.textTitle,
      ),
    );
  }
}
