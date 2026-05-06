import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:flutter/material.dart';

// ── 스테이지 팔레트 (w_festival_timetable 과 동일) ────────────────────────────
const List<Color> _stageColors = [
  Color(0xFF6C5CE7),
  Color(0xFF00B894),
  Color(0xFFE17055),
  Color(0xFF74B9FF),
  Color(0xFFFD79A8),
  Color(0xFFA29BFE),
  Color(0xFF55EFC4),
  Color(0xFFFFCE54),
];

// ── 사용자 일정 색상 팔레트 ─────────────────────────────────────────────────
const List<Color> _userColors = [
  Color(0xFFFF7675),
  Color(0xFFFF9F43),
  Color(0xFFFFD32A),
  Color(0xFF2ECC71),
  Color(0xFF00CEC9),
  Color(0xFF0984E3),
  Color(0xFFBE2EDD),
  Color(0xFFE84393),
];

// ── 사용자 일정 모델 ──────────────────────────────────────────────────────────
class _UserEntry {
  final String id;
  String stageName;
  String label;
  String startTime;
  String endTime;
  Color color;

  _UserEntry({
    required this.id,
    required this.stageName,
    required this.label,
    required this.startTime,
    required this.endTime,
    required this.color,
  });

  _UserEntry copyWith({
    String? stageName,
    String? label,
    String? startTime,
    String? endTime,
    Color? color,
  }) =>
      _UserEntry(
        id: id,
        stageName: stageName ?? this.stageName,
        label: label ?? this.label,
        startTime: startTime ?? this.startTime,
        endTime: endTime ?? this.endTime,
        color: color ?? this.color,
      );
}

// ── 전체화면 페이지 ───────────────────────────────────────────────────────────
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
  State<TimetableFullscreenPage> createState() =>
      _TimetableFullscreenPageState();
}

class _TimetableFullscreenPageState extends State<TimetableFullscreenPage> {
  late String? _selectedDate;

  // 날짜별 사용자 일정 보관
  final Map<String, List<_UserEntry>> _userEntriesMap = {};
  int _colorCursor = 0;

  // 선택 날짜로 계산된 캐시
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
        : widget.entries
            .where((e) => e.festivalDate == _selectedDate)
            .toList();

    final seen = <String, int>{};
    for (final e in _filtered) {
      seen.putIfAbsent(e.stageName, () => e.stageOrder);
    }
    _stages = (seen.entries.toList()
          ..sort((a, b) => a.value.compareTo(b.value)))
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

  List<_UserEntry> get _currentUserEntries =>
      _userEntriesMap[_selectedDate ?? ''] ?? [];

  Color _nextColor() {
    final c = _userColors[_colorCursor % _userColors.length];
    _colorCursor++;
    return c;
  }

  void _upsert(_UserEntry entry) {
    setState(() {
      final key = _selectedDate ?? '';
      final list = List<_UserEntry>.from(_userEntriesMap[key] ?? []);
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
    final blank = _UserEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      stageName: stage ?? _stages.first,
      label: '',
      startTime: startTime ?? '${_startHour.toString().padLeft(2, '0')}:00',
      endTime:
          '${(_startHour + 1).clamp(0, 23).toString().padLeft(2, '0')}:00',
      color: _nextColor(),
    );
    final result = await showDialog<_UserEntry>(
      context: context,
      builder: (_) =>
          _EntryDialog(stages: _stages, initial: blank, isEditing: false),
    );
    if (result != null) _upsert(result);
  }

  Future<void> _openEdit(_UserEntry entry) async {
    final result = await showDialog<dynamic>(
      context: context,
      builder: (_) =>
          _EntryDialog(stages: _stages, initial: entry, isEditing: true),
    );
    if (result is _UserEntry) {
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
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: colors.textTitle),
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
                          '추가',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: colors.activate),
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
            // 날짜 탭 (2일 이상일 때만)
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

            // 그리드
            Expanded(
              child: _filtered.isEmpty
                  ? Center(
                      child: Text('no_timetable'.tr(),
                          style: TextStyle(color: colors.textSecondary)),
                    )
                  : _FullscreenGrid(
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

            // 하단 힌트
            if (_stages.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4, bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.touch_app_rounded,
                        size: 12, color: colors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '빈 공간을 탭해 내 일정 추가 · 내 일정 카드를 탭해 수정',
                      style: TextStyle(
                          fontSize: 10, color: colors.textSecondary),
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

// ── 날짜 탭 바 ────────────────────────────────────────────────────────────────
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: sel ? colors.activate : colors.backgroundMain,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: sel ? colors.activate : colors.listDivider),
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

// ── 전체화면 그리드 ───────────────────────────────────────────────────────────
class _FullscreenGrid extends StatefulWidget {
  final List<String> stages;
  final List<TimetableEntry> filtered;
  final List<_UserEntry> userEntries;
  final int startHour;
  final int endHour;
  final Set<String> followedNames;
  final void Function(String stage, String startTime) onTapGrid;
  final void Function(_UserEntry entry) onTapUserEntry;

  const _FullscreenGrid({
    required this.stages,
    required this.filtered,
    required this.userEntries,
    required this.startHour,
    required this.endHour,
    required this.followedNames,
    required this.onTapGrid,
    required this.onTapUserEntry,
  });

  @override
  State<_FullscreenGrid> createState() => _FullscreenGridState();
}

class _FullscreenGridState extends State<_FullscreenGrid> {
  static const double _topPad = 16.0;
  static const double _bottomPad = 16.0;
  static const double _timeColW = 48.0;
  static const double _stageHeaderH = 36.0;

  // 탭 위치 임시 저장 (onTapDown → onTap 전달용)
  Offset? _tapPos;

  double _toY(String time, double pxPerMin) {
    final parts = time.split(':');
    final h = int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return ((h - widget.startHour) * 60 + m) * pxPerMin;
  }

  Color _stageColor(String stage) {
    final idx = widget.stages.indexOf(stage) % _stageColors.length;
    return _stageColors[idx < 0 ? 0 : idx];
  }

  void _handleTap(double pxPerMin, double stageW) {
    if (_tapPos == null) return;
    final pos = _tapPos!;
    _tapPos = null;

    final totalMins = (widget.endHour - widget.startHour) * 60;
    final rawMins = ((pos.dy - _topPad) / pxPerMin).round();
    final clampedMins = rawMins.clamp(0, totalMins);
    final h = widget.startHour + (clampedMins ~/ 60);
    final m = (clampedMins % 60 ~/ 10) * 10;
    final timeStr =
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

    final si = (pos.dx / stageW).floor().clamp(0, widget.stages.length - 1);
    widget.onTapGrid(widget.stages[si], timeStr);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return LayoutBuilder(builder: (_, constraints) {
      final availW = constraints.maxWidth;
      final availH = constraints.maxHeight;

      // 세로 스크롤 없이 전체 화면에 딱 맞게
      final gridH = availH - _stageHeaderH;
      final totalMins = (widget.endHour - widget.startHour) * 60;
      final pxPerMin =
          (gridH - _topPad - _bottomPad) / totalMins.clamp(1, 99999);

      // 스테이지 너비: 가로 스크롤 없이 화면에 딱 맞게
      final stageW = widget.stages.isEmpty
          ? availW - _timeColW
          : (availW - _timeColW) / widget.stages.length;

      return Column(
        children: [
          // ─ 스테이지 헤더 ─────────────────────────────────────────────
          SizedBox(
            height: _stageHeaderH,
            child: Row(
              children: [
                // 시간 열 헤더 자리
                Container(
                  width: _timeColW,
                  decoration: BoxDecoration(
                    color: colors.surface,
                    border: Border(
                      bottom: BorderSide(color: colors.listDivider),
                      right: BorderSide(color: colors.listDivider),
                    ),
                  ),
                ),
                // 스테이지 헤더들
                ...widget.stages.map((stage) {
                  final color = _stageColor(stage);
                  return Container(
                    width: stageW,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      border: Border(
                        bottom: BorderSide(color: colors.listDivider),
                        right: BorderSide(
                            color: colors.listDivider, width: 0.5),
                      ),
                    ),
                    child: Text(
                      stage,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: color),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
            ),
          ),

          // ─ 그리드 본문 ───────────────────────────────────────────────
          SizedBox(
            height: gridH,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 시간 열
                SizedBox(
                  width: _timeColW,
                  height: gridH,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: List.generate(
                      widget.endHour - widget.startHour + 1,
                      (i) {
                        final hour = widget.startHour + i;
                        return Positioned(
                          top: _topPad + i * 60.0 * pxPerMin - 8,
                          left: 0,
                          right: 0,
                          child: Text(
                            '${hour.toString().padLeft(2, '0')}:00',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: colors.textSecondary),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // 그리드 내용
                SizedBox(
                  width: widget.stages.length * stageW,
                  height: gridH,
                  child: GestureDetector(
                    onTapDown: (d) => _tapPos = d.localPosition,
                    onTap: () => _handleTap(pxPerMin, stageW),
                    child: Stack(
                      clipBehavior: Clip.hardEdge,
                      children: [
                        // 세로 구분선
                        ...List.generate(
                          widget.stages.length,
                          (i) => Positioned(
                            left: (i + 1) * stageW - 0.5,
                            top: 0,
                            bottom: 0,
                            width: 0.5,
                            child: Container(color: colors.listDivider),
                          ),
                        ),

                        // 가로선 (1시간·30분·10분)
                        ...List.generate(
                          (widget.endHour - widget.startHour) * 6 + 1,
                          (i) {
                            final mins = i * 10;
                            final isHour = mins % 60 == 0;
                            final isHalf = mins % 30 == 0;
                            return Positioned(
                              top: _topPad + mins * pxPerMin,
                              left: 0,
                              right: 0,
                              height: 0.5,
                              child: Container(
                                color: isHour
                                    ? colors.listDivider
                                        .withValues(alpha: 0.9)
                                    : isHalf
                                        ? colors.listDivider
                                            .withValues(alpha: 0.5)
                                        : colors.listDivider
                                            .withValues(alpha: 0.2),
                              ),
                            );
                          },
                        ),

                        // 공식 공연 카드 (읽기 전용)
                        ...widget.filtered.map((entry) {
                          final si =
                              widget.stages.indexOf(entry.stageName);
                          if (si < 0) return const SizedBox.shrink();
                          final rawTop = _toY(entry.startTime, pxPerMin);
                          final cardH =
                              _toY(entry.endTime, pxPerMin) - rawTop;
                          final color = _stageColor(entry.stageName);
                          final followed = widget.followedNames
                              .contains(entry.artistName);
                          return Positioned(
                            left: si * stageW + 3,
                            top: _topPad + rawTop + 2,
                            width: stageW - 6,
                            height: (cardH - 4).clamp(4.0, double.infinity),
                            child: _OfficialCard(
                              entry: entry,
                              color: color,
                              cardH: cardH - 4,
                              followed: followed,
                            ),
                          );
                        }),

                        // 사용자 일정 카드 (탭 → 수정)
                        ...widget.userEntries.map((entry) {
                          final si =
                              widget.stages.indexOf(entry.stageName);
                          if (si < 0) return const SizedBox.shrink();
                          final rawTop = _toY(entry.startTime, pxPerMin);
                          final cardH =
                              _toY(entry.endTime, pxPerMin) - rawTop;
                          return Positioned(
                            left: si * stageW + 3,
                            top: _topPad + rawTop + 2,
                            width: stageW - 6,
                            height: (cardH - 4).clamp(4.0, double.infinity),
                            child: GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () => widget.onTapUserEntry(entry),
                              child: _UserCard(entry: entry, cardH: cardH - 4),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    });
  }
}

// ── 공식 공연 카드 ─────────────────────────────────────────────────────────────
class _OfficialCard extends StatelessWidget {
  final TimetableEntry entry;
  final Color color;
  final double cardH;
  final bool followed;

  const _OfficialCard({
    required this.entry,
    required this.color,
    required this.cardH,
    required this.followed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: followed ? color.withValues(alpha: 0.88) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        border: followed
            ? null
            : Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
        boxShadow: followed
            ? [
                BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2))
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.artistName,
            style: TextStyle(
                color: followed ? Colors.white : color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (cardH > 26)
            Text(
              '${entry.startTime} – ${entry.endTime}',
              style: TextStyle(
                  color: followed
                      ? Colors.white70
                      : color.withValues(alpha: 0.7),
                  fontSize: 9,
                  height: 1.3),
            ),
        ],
      ),
    );
  }
}

// ── 사용자 일정 카드 ───────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final _UserEntry entry;
  final double cardH;

  const _UserCard({required this.entry, required this.cardH});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: entry.color.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        boxShadow: [
          BoxShadow(
              color: entry.color.withValues(alpha: 0.4),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      height: 1.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (cardH > 26)
                  Text(
                    '${entry.startTime} – ${entry.endTime}',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 9, height: 1.3),
                  ),
              ],
            ),
          ),
          Icon(Icons.edit_rounded,
              size: 10, color: Colors.white.withValues(alpha: 0.8)),
        ],
      ),
    );
  }
}

// ── 추가/수정 다이얼로그 ──────────────────────────────────────────────────────
class _EntryDialog extends StatefulWidget {
  final List<String> stages;
  final _UserEntry initial;
  final bool isEditing;

  const _EntryDialog({
    required this.stages,
    required this.initial,
    required this.isEditing,
  });

  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
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

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(bool isStart) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _start : _end,
      builder: (ctx, child) => MediaQuery(
        data: MediaQuery.of(ctx).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() => isStart ? _start = picked : _end = picked);
  }

  _UserEntry get _result => _UserEntry(
        id: widget.initial.id,
        stageName: _stage,
        label: _labelCtrl.text.trim(),
        startTime: _fmt(_start),
        endTime: _fmt(_end),
        color: _color,
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final valid = _labelCtrl.text.trim().isNotEmpty;

    return AlertDialog(
      backgroundColor: colors.surface,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        widget.isEditing ? '내 일정 수정' : '내 일정 추가',
        style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: colors.textTitle),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 일정 이름
            TextField(
              controller: _labelCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: '일정 이름',
                hintStyle: TextStyle(color: colors.textSecondary),
                enabledBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: colors.listDivider)),
                focusedBorder: UnderlineInputBorder(
                    borderSide: BorderSide(color: colors.activate)),
              ),
              style: TextStyle(color: colors.textTitle),
            ),
            const SizedBox(height: 16),

            // 스테이지 선택
            _Label('스테이지', colors),
            const SizedBox(height: 6),
            DropdownButton<String>(
              value: _stage,
              isExpanded: true,
              dropdownColor: colors.surface,
              style: TextStyle(color: colors.textTitle, fontSize: 14),
              underline: Container(height: 1, color: colors.listDivider),
              items: widget.stages
                  .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                  .toList(),
              onChanged: (s) {
                if (s != null) setState(() => _stage = s);
              },
            ),
            const SizedBox(height: 16),

            // 시간 선택
            Row(
              children: [
                Expanded(
                  child: _TimeBtn(
                    label: '시작',
                    time: _start,
                    onTap: () => _pickTime(true),
                    colors: colors,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Text('–',
                      style: TextStyle(
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ),
                Expanded(
                  child: _TimeBtn(
                    label: '종료',
                    time: _end,
                    onTap: () => _pickTime(false),
                    colors: colors,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 색상 선택
            _Label('색상', colors),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _userColors.map((c) {
                final selected = c.toARGB32() == _color.toARGB32();
                return GestureDetector(
                  onTap: () => setState(() => _color = c),
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: c,
                      shape: BoxShape.circle,
                      border: selected
                          ? Border.all(color: colors.textTitle, width: 2.5)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: selected
                        ? const Icon(Icons.check_rounded,
                            size: 16, color: Colors.white)
                        : null,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
      actions: [
        if (widget.isEditing)
          TextButton(
            onPressed: () => Navigator.pop(context, 'delete'),
            child:
                const Text('삭제', style: TextStyle(color: Colors.redAccent)),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('취소',
              style: TextStyle(color: colors.textSecondary)),
        ),
        ElevatedButton(
          onPressed: valid ? () => Navigator.pop(context, _result) : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.activate,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8)),
          ),
          child: Text(widget.isEditing ? '수정' : '추가'),
        ),
      ],
    );
  }
}

// ── 다이얼로그 내부 소형 위젯 ──────────────────────────────────────────────────
class _Label extends StatelessWidget {
  final String text;
  final AbstractThemeColors colors;
  const _Label(this.text, this.colors);

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary),
      );
}

class _TimeBtn extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;
  final AbstractThemeColors colors;

  const _TimeBtn({
    required this.label,
    required this.time,
    required this.onTap,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Label(label, colors),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: colors.backgroundMain,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.listDivider),
            ),
            child: Text(
              '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}',
              style: TextStyle(
                  color: colors.textTitle,
                  fontSize: 14,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}
