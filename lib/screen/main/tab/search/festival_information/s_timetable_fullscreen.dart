import 'dart:convert';

import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/constant/timetable_colors.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_timetable_entry_dialog.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_timetable_fullscreen_grid.dart';
import 'package:feple/model/user_entry.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TimetableFullscreenScreen extends StatefulWidget {
  final int festivalId;
  final List<TimetableEntry> entries;
  final Set<String> followedNames;
  final List<String> dates;
  final String? initialDate;

  const TimetableFullscreenScreen({
    super.key,
    required this.festivalId,
    required this.entries,
    required this.followedNames,
    required this.dates,
    required this.initialDate,
  });

  @override
  State<TimetableFullscreenScreen> createState() => _TimetableFullscreenScreenState();
}

class _TimetableFullscreenScreenState extends State<TimetableFullscreenScreen> {
  late String? _selectedDate;

  final Map<String, List<UserEntry>> _userEntriesMap = {};
  int _colorCursor = 0;

  late TimetableRange _range;

  String get _prefKey => 'user_timetable_entries_${widget.festivalId}';

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.initialDate;
    _range = computeTimetableRange(widget.entries, _selectedDate);
    _loadEntries();
  }

  Future<void> _loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null || !mounted) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      final map = decoded.map(
        (k, v) => MapEntry(
          k,
          (v as List).map((e) => UserEntry.fromJson(e as Map<String, dynamic>)).toList(),
        ),
      );
      setState(() => _userEntriesMap.addAll(map));
    } catch (e) {
      debugPrint('[Timetable] load user entries failed: $e');
    }
  }

  Future<void> _saveEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(
      _userEntriesMap.map((k, v) => MapEntry(k, v.map((e) => e.toJson()).toList())),
    );
    await prefs.setString(_prefKey, encoded);
  }

  List<UserEntry> get _currentUserEntries =>
      _userEntriesMap[_selectedDate ?? ''] ?? [];

  Color _nextColor() {
    final color = kUserScheduleColors[_colorCursor % kUserScheduleColors.length];
    _colorCursor++;
    return color;
  }

  Future<void> _upsert(UserEntry entry) async {
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
    await _saveEntries();
  }

  Future<void> _remove(String id) async {
    setState(() {
      final key = _selectedDate ?? '';
      _userEntriesMap[key] =
          (_userEntriesMap[key] ?? []).where((e) => e.id != id).toList();
    });
    await _saveEntries();
  }

  Future<void> _openAdd({String? stage, String? startTime}) async {
    if (_range.stages.isEmpty) return;
    final blank = UserEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      stageName: stage ?? _range.stages.first,
      label: '',
      startTime: startTime ?? '${_range.startHour.toString().padLeft(2, '0')}:00',
      endTime: '${(_range.startHour + 1).clamp(0, 23).toString().padLeft(2, '0')}:00',
      color: _nextColor(),
    );
    final result = await showDialog<UserEntry>(
      context: context,
      builder: (_) => TimetableEntryDialog(stages: _range.stages, initial: blank, isEditing: false),
    );
    if (result != null && mounted) await _upsert(result);
  }

  Future<void> _openEdit(UserEntry entry) async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (_) => TimetableEntryDialog(stages: _range.stages, initial: entry, isEditing: true),
    );
    if (!mounted) return;
    if (result is UserEntry) {
      await _upsert(result);
    } else if (result == 'delete') {
      await _remove(entry.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          _buildAppBar(colors),
          Expanded(
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  Expanded(child: _buildGridArea(colors)),
                  if (_range.stages.isNotEmpty) _buildHint(colors),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(AbstractThemeColors colors) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: AppDimens.appBarHeight,
        color: colors.surface,
        child: Row(
          children: [
            IconButton(
              tooltip: 'close'.tr(),
              icon: Icon(Icons.close_rounded, color: colors.textTitle),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(child: _buildAppBarCenter(colors)),
            if (_range.stages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: _openAdd,
                  icon: Icon(Icons.add_rounded, size: 16, color: colors.activate),
                  label: Text(
                    'timetable_add'.tr(),
                    style: TextStyle(
                        fontSize: AppDimens.fontSizeSm, fontWeight: FontWeight.w600, color: colors.activate),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBarCenter(AbstractThemeColors colors) {
    if (widget.dates.length <= 1) {
      return Row(
        children: [
          Icon(Icons.schedule_rounded, size: 15, color: colors.activate),
          const SizedBox(width: 8),
          Text(
            'timetable'.tr(),
            style: TextStyle(
                fontSize: AppDimens.fontSizeXl, fontWeight: FontWeight.w700, color: colors.textTitle),
          ),
        ],
      );
    }
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: widget.dates.map((date) {
          final selected = _selectedDate == date;
          return GestureDetector(
            onTap: () => setState(() {
              _selectedDate = date;
              _range = computeTimetableRange(widget.entries, _selectedDate);
            }),
            child: AnimatedContainer(
              duration: AppDimens.animXFast,
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: selected ? colors.activate : Colors.transparent,
                borderRadius: BorderRadius.circular(AppDimens.cardRadius),
                border: Border.all(
                  color: selected ? colors.activate : colors.listDivider,
                ),
              ),
              child: Text(
                date,
                style: TextStyle(
                  fontSize: AppDimens.fontSizeXs,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : colors.textTitle,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildGridArea(AbstractThemeColors colors) {
    if (_range.filtered.isEmpty) {
      return Center(
        child: Text('no_timetable'.tr(),
            style: TextStyle(color: colors.textSecondary)),
      );
    }
    return TimetableFullscreenGrid(
      range: _range,
      userEntries: _currentUserEntries,
      followedNames: widget.followedNames,
      onTapGrid: (stage, start) => _openAdd(stage: stage, startTime: start),
      onTapUserEntry: _openEdit,
    );
  }

  Widget _buildHint(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.touch_app_rounded, size: 12, color: colors.textSecondary),
          const SizedBox(width: 4),
          Text(
            'timetable_hint'.tr(),
            style: TextStyle(fontSize: AppDimens.fontSizeTiny, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

