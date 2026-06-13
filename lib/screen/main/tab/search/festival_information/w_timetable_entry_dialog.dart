import 'package:feple/common/common.dart';
import 'package:feple/common/constant/timetable_colors.dart';
import 'package:feple/common/dart/extension/time_of_day_extension.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_timetable_user_entry.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

class TimetableEntryDialog extends StatefulWidget {
  final List<String> stages;
  final UserEntry initial;
  final bool isEditing;

  const TimetableEntryDialog({
    super.key,
    required this.stages,
    required this.initial,
    required this.isEditing,
  });

  @override
  State<TimetableEntryDialog> createState() => _TimetableEntryDialogState();
}

class _TimetableEntryDialogState extends State<TimetableEntryDialog> {
  late final TextEditingController _labelCtrl;
  late String _stage;
  late TimeOfDay _start;
  late TimeOfDay _end;
  late Color _color;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.initial.label);
    _stage = widget.initial.stageName;
    _start = _parse(widget.initial.startTime);
    _end = _parse(widget.initial.endTime);
    _color = widget.initial.color;
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    super.dispose();
  }

  TimeOfDay _parse(String t) {
    final parts = t.split(':');
    return TimeOfDay(
      hour: int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0,
      minute: int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0,
    );
  }

  Future<void> _pickStartTime() async {
    final picked = await _showTimePicker(_start);
    if (picked != null && mounted) setState(() => _start = picked);
  }

  Future<void> _pickEndTime() async {
    final picked = await _showTimePicker(_end);
    if (picked != null && mounted) setState(() => _end = picked);
  }

  Future<TimeOfDay?> _showTimePicker(TimeOfDay initial) => showTimePicker(
        context: context,
        initialTime: initial,
        builder: (ctx, child) => MediaQuery(
          data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
          child: child!,
        ),
      );

  int _toMins(TimeOfDay t) => t.hour * 60 + t.minute;

  UserEntry get _result => UserEntry(
        id: widget.initial.id,
        stageName: _stage,
        label: _labelCtrl.text.trim(),
        startTime: _start.toHHmm,
        endTime: _end.toHHmm,
        color: _color,
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final valid = _labelCtrl.text.trim().isNotEmpty && _toMins(_end) > _toMins(_start);

    return AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.cardRadius)),
      title: Text(
        widget.isEditing ? 'timetable_edit_entry'.tr() : 'timetable_add_entry'.tr(),
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: colors.textTitle),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabelField(colors),
            const SizedBox(height: 16),
            _buildStageDropdown(colors),
            const SizedBox(height: 16),
            _buildTimeRow(colors),
            const SizedBox(height: 16),
            _buildColorPicker(colors),
          ],
        ),
      ),
      actions: [
        if (widget.isEditing)
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            child: Text('msg_delete'.tr(), style: const TextStyle(color: AppColors.errorRed)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr(), style: TextStyle(color: colors.textSecondary)),
        ),
        FilledButton(
          onPressed: valid ? () => Navigator.pop(context, _result) : null,
          style: FilledButton.styleFrom(
            backgroundColor: colors.activate,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSmall)),
          ),
          child: Text(widget.isEditing ? 'photo_edit_action'.tr() : 'timetable_add'.tr()),
        ),
      ],
    );
  }

  Widget _buildLabelField(AbstractThemeColors colors) {
    return TextField(
      controller: _labelCtrl,
      onChanged: (_) => setState(() {}),
      decoration: InputDecoration(
        hintText: 'timetable_entry_name_hint'.tr(),
        hintStyle: TextStyle(color: colors.textSecondary),
        enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.listDivider)),
        focusedBorder: UnderlineInputBorder(borderSide: BorderSide(color: colors.activate)),
      ),
      style: TextStyle(color: colors.textTitle),
    );
  }

  Widget _buildStageDropdown(AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('timetable_stage'.tr()),
        const SizedBox(height: 6),
        DropdownButton<String>(
          value: _stage,
          isExpanded: true,
          dropdownColor: colors.surface,
          style: TextStyle(color: colors.textTitle, fontSize: 14),
          underline: Container(height: 1, color: colors.listDivider),
          items: widget.stages.map((stage) => DropdownMenuItem(value: stage, child: Text(stage))).toList(),
          onChanged: (stage) {
            if (stage != null) setState(() => _stage = stage);
          },
        ),
      ],
    );
  }

  Widget _buildTimeRow(AbstractThemeColors colors) {
    return Row(
      children: [
        Expanded(
          child: _TimeBtn(label: 'timetable_start'.tr(), time: _start, onTap: _pickStartTime),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('–', style: TextStyle(color: colors.textSecondary, fontWeight: FontWeight.w700, fontSize: 16)),
        ),
        Expanded(
          child: _TimeBtn(label: 'timetable_end'.tr(), time: _end, onTap: _pickEndTime),
        ),
      ],
    );
  }

  Widget _buildColorPicker(AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label('timetable_color'.tr()),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: kUserScheduleColors.map((c) {
            final selected = c.toARGB32() == _color.toARGB32();
            return GestureDetector(
              onTap: () => setState(() => _color = c),
              child: Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: c,
                  shape: BoxShape.circle,
                  border: selected ? Border.all(color: colors.textTitle, width: 2.5) : null,
                ),
                alignment: Alignment.center,
                child: selected ? const Icon(Icons.check_rounded, size: 16, color: Colors.white) : null,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Text(
      text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: colors.textSecondary),
    );
  }
}

class _TimeBtn extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimeBtn({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: colors.backgroundMain,
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              border: Border.all(color: colors.listDivider),
            ),
            child: Text(
              time.toHHmm,
              style: TextStyle(color: colors.textTitle, fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
