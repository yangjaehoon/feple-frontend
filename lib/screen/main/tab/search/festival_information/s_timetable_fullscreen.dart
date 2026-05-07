import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/constant/timetable_colors.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_timetable_entry_dialog.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_timetable_fullscreen_grid.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_timetable_user_entry.dart';
import 'package:flutter/material.dart';

class TimetableFullscreenPage extends StatefulWidget {
  final List<TimetableEntry> entries;
  final Set<String> followedNames;
  final List<String> dates;
  final String? initialDate;

  const TimetableFullscreenPage({
    super.key,
    required this.entries,
    required this.followedNames,
    required this.dates,
    required this.initialDate,
  });

  @override
  State<TimetableFullscreenPage> createState() => _TimetableFullscreenPageState();
}

class _TimetableFullscreenPageState extends State<TimetableFullscreenPage> {
  late String? _selectedDate;

  final Map<String, List<UserEntry>> _userEntriesMap = {};
  int _colorCursor = 0;

  List<TimetableEntry> _filtered = [];
  List<String> _stages = [];
  int _startHour = 12;
  int _endHour = 13;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _rebuildCache();
  }

  void _rebuildCache() {
    _filtered = _selectedDate == null
        ? []
        : widget.entries.where((e) => e.festivalDate == _selectedDate).toList();

    final seen = <String, int>{};
    for (final e in _filtered) {
      seen.putIfAbsent(e.stageName, () => e.stageOrder);
    }
    _stages = (seen.entries.toList()..sort((a, b) => a.value.compareTo(b.value)))
        .map((e) => e.key)
        .toList();

    int minH = 12;
    for (final e in _filtered) {
      final h = int.tryParse(e.startTime.split(':')[0]);
      if (h != null && h < minH) minH = h;
    }
    _startHour = minH;

    int maxH = minH + 1;
    for (final e in _filtered) {
      final parts = e.endTime.split(':');
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts.length > 1 ? parts[1] : '0');
      if (h == null || m == null) continue;
      final endH = m > 0 ? h + 1 : h;
      if (endH > maxH) maxH = endH;
    }
    _endHour = maxH;
  }

  List<UserEntry> get _currentUserEntries =>
      _userEntriesMap[_selectedDate ?? ''] ?? [];

  Color _nextColor() {
    final c = kUserScheduleColors[_colorCursor % kUserScheduleColors.length];
    _colorCursor++;
    return c;
  }

  void _upsert(UserEntry entry) {
    setState(() {
      final key = _selectedDate ?? '';
      final list = List<UserEntry>.from(_userEntriesMap[key] ?? []);
      final idx = list.indexWhere((e) => e.id == entry.id);
      if (idx >= 0) {
        list[idx] = entry;
      } else {
        list.add(entry);
      }
      _userEntriesMap[key] = list;
    });
  }

  void _remove(String id) {
    setState(() {
      final key = _selectedDate ?? '';
      _userEntriesMap[key] =
          (_userEntriesMap[key] ?? []).where((e) => e.id != id).toList();
    });
  }

  Future<void> _openAdd({String? stage, String? startTime}) async {
    if (_stages.isEmpty) return;
    final blank = UserEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      stageName: stage ?? _stages.first,
      label: '',
      startTime: startTime ?? '${_startHour.toString().padLeft(2, '0')}:00',
      endTime: '${(_startHour + 1).clamp(0, 23).toString().padLeft(2, '0')}:00',
      color: _nextColor(),
    );
    final result = await showDialog<UserEntry>(
      context: context,
      builder: (_) => TimetableEntryDialog(stages: _stages, initial: blank, isEditing: false),
    );
    if (result != null) _upsert(result);
  }

  Future<void> _openEdit(UserEntry entry) async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (_) => TimetableEntryDialog(stages: _stages, initial: entry, isEditing: true),
    );
    if (result is UserEntry) {
      _upsert(result);
    } else if (result == 'delete') {
      _remove(entry.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              height: AppDimens.appBarHeight,
              color: colors.surface,
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: colors.textTitle),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Row(
                      children: [
                        Icon(Icons.schedule_rounded, size: 15, color: colors.activate),
                        const SizedBox(width: 8),
                        Text(
                          'timetable'.tr(),
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700, color: colors.textTitle),
                        ),
                      ],
                    ),
                  ),
                  if (_stages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: TextButton.icon(
                        onPressed: _openAdd,
                        icon: Icon(Icons.add_rounded, size: 16, color: colors.activate),
                        label: Text(
                          'timetable_add'.tr(),
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600, color: colors.activate),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  if (widget.dates.length > 1)
                    _DateTabBar(
                      dates: widget.dates,
                      selected: _selectedDate,
                      onSelect: (d) => setState(() {
                        _selectedDate = d;
                        _rebuildCache();
                      }),
                      colors: colors,
                    ),
                  Expanded(
                    child: _filtered.isEmpty
                        ? Center(
                            child: Text('no_timetable'.tr(),
                                style: TextStyle(color: colors.textSecondary)),
                          )
                        : TimetableFullscreenGrid(
                            stages: _stages,
                            filtered: _filtered,
                            userEntries: _currentUserEntries,
                            startHour: _startHour,
                            endHour: _endHour,
                            followedNames: widget.followedNames,
                            onTapGrid: (stage, start) =>
                                _openAdd(stage: stage, startTime: start),
                            onTapUserEntry: _openEdit,
                          ),
                  ),
                  if (_stages.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4, bottom: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.touch_app_rounded, size: 12, color: colors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            'timetable_hint'.tr(),
                            style: TextStyle(fontSize: 10, color: colors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DateTabBar extends StatelessWidget {
  final List<String> dates;
  final String? selected;
  final void Function(String) onSelect;
  final AbstractThemeColors colors;

  const _DateTabBar({
    required this.dates,
    required this.selected,
    required this.onSelect,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: dates.map((date) {
          final sel = date == selected;
          return GestureDetector(
            onTap: () => onSelect(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? colors.activate : colors.backgroundMain,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: sel ? colors.activate : colors.listDivider),
              ),
              child: Text(
                date,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: sel ? Colors.white : colors.textTitle,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
