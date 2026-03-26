import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/network/dio_client.dart';
import 'package:flutter/material.dart';

// ── 모델 ──────────────────────────────────────────────────────────────────────
class TimetableEntry {
  final int id;
  final String stageName;
  final String artistName;
  final String festivalDate;
  final String startTime; // "HH:mm"
  final String endTime;

  const TimetableEntry({
    required this.id,
    required this.stageName,
    required this.artistName,
    required this.festivalDate,
    required this.startTime,
    required this.endTime,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> j) => TimetableEntry(
        id: (j['id'] as num).toInt(),
        stageName: j['stageName'] as String,
        artistName: j['artistName'] as String,
        festivalDate: j['festivalDate'] as String,
        startTime: (j['startTime'] as String).substring(0, 5),
        endTime: (j['endTime'] as String).substring(0, 5),
      );
}

// ── 상수 ──────────────────────────────────────────────────────────────────────
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

// ── 위젯 ──────────────────────────────────────────────────────────────────────
class FestivalTimetable extends StatefulWidget {
  final int festivalId;
  final String startDate;
  final String endDate;

  const FestivalTimetable({
    super.key,
    required this.festivalId,
    required this.startDate,
    required this.endDate,
  });

  @override
  State<FestivalTimetable> createState() => _FestivalTimetableState();
}

class _FestivalTimetableState extends State<FestivalTimetable> {
  static const int _startHour = 12;
  static const int _endHour = 24;
  static const double _minPx = 1.5;
  static const double _stageW = 130.0;
  static const double _timeColW = 52.0;
  static const double _stageHeaderH = 38.0;
  static const double _viewH = 460.0;

  final _vContent = ScrollController();
  final _vTime = ScrollController();
  final _hContent = ScrollController();
  final _hHeader = ScrollController();
  bool _lockV = false, _lockH = false;

  List<TimetableEntry> _entries = [];
  bool _loading = true;
  String? _error;

  // 날짜 목록 (페스티벌 기간)
  List<String> _dates = [];
  String? _selectedDate;

  @override
  void initState() {
    super.initState();
    _vContent.addListener(_onV);
    _hContent.addListener(_onH);
    _buildDates();
    _fetch();
  }

  void _buildDates() {
    if (widget.startDate.isEmpty) return;
    try {
      final start = DateTime.parse(widget.startDate);
      final end = widget.endDate.isNotEmpty
          ? DateTime.parse(widget.endDate)
          : start;
      _dates = [];
      for (var d = start;
          !d.isAfter(end);
          d = d.add(const Duration(days: 1))) {
        _dates.add('${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
      }
      _selectedDate = _dates.isNotEmpty ? _dates.first : null;
    } catch (_) {}
  }

  Future<void> _fetch() async {
    try {
      final res = await DioClient.dio
          .get('/festivals/${widget.festivalId}/timetable');
      final list = (res.data as List)
          .map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>))
          .toList();
      if (mounted) {
        setState(() {
          _entries = list;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _onV() {
    if (_lockV) return;
    _lockV = true;
    if (_vTime.hasClients) _vTime.jumpTo(_vContent.offset);
    _lockV = false;
  }

  void _onH() {
    if (_lockH) return;
    _lockH = true;
    if (_hHeader.hasClients) _hHeader.jumpTo(_hContent.offset);
    _lockH = false;
  }

  @override
  void dispose() {
    _vContent.dispose();
    _vTime.dispose();
    _hContent.dispose();
    _hHeader.dispose();
    super.dispose();
  }

  double _toY(String time) {
    final parts = time.split(':');
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    return ((h - _startHour) * 60 + m) * _minPx;
  }

  List<TimetableEntry> get _filtered => _selectedDate == null
      ? []
      : _entries.where((e) => e.festivalDate == _selectedDate).toList();

  List<String> get _stages {
    final seen = <String>{};
    return _filtered
        .map((e) => e.stageName)
        .where(seen.add)
        .toList();
  }

  Color _colorFor(String stage) {
    final idx = _stages.indexOf(stage) % _stageColors.length;
    return _stageColors[idx < 0 ? 0 : idx];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 제목
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Icon(Icons.schedule_rounded, size: 15, color: colors.activate),
                  const SizedBox(width: 8),
                  Text('타임테이블',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: colors.textTitle)),
                ],
              ),
            ),

            // 날짜 탭
            if (_dates.isNotEmpty)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(
                  children: _dates.map((date) {
                    final selected = date == _selectedDate;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDate = date),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8, bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected ? colors.activate : colors.backgroundMain,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected ? colors.activate : colors.listDivider,
                          ),
                        ),
                        child: Text(
                          date,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: selected ? Colors.white : colors.textTitle,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

            if (_loading)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                    child: Text('불러오기 실패',
                        style: TextStyle(color: colors.textSecondary))),
              )
            else if (_filtered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                    child: Text('등록된 타임테이블이 없습니다.',
                        style: TextStyle(color: colors.textSecondary))),
              )
            else
              _buildGrid(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(dynamic colors) {
    final stages = _stages;
    final totalH = (_endHour - _startHour) * 60 * _minPx;
    final totalW = stages.isEmpty ? _stageW : stages.length * _stageW;

    return Column(
      children: [
        // 스테이지 헤더
        Row(
          children: [
            Container(
              width: _timeColW,
              height: _stageHeaderH,
              decoration: BoxDecoration(
                color: colors.surface,
                border: Border(
                  bottom: BorderSide(color: colors.listDivider),
                  right: BorderSide(color: colors.listDivider),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _hHeader,
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                child: Row(
                  children: stages.map((stage) {
                    return Container(
                      width: _stageW,
                      height: _stageHeaderH,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: _colorFor(stage).withValues(alpha: 0.12),
                        border: Border(
                          bottom: BorderSide(color: colors.listDivider),
                          right: BorderSide(
                              color: colors.listDivider, width: 0.5),
                        ),
                      ),
                      child: Text(stage,
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: _colorFor(stage))),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),

        // 본문
        SizedBox(
          height: _viewH,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 시간 열
              SizedBox(
                width: _timeColW,
                child: SingleChildScrollView(
                  controller: _vTime,
                  physics: const NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    height: totalH,
                    child: Stack(
                      children: List.generate(_endHour - _startHour + 1, (i) {
                        final hour = _startHour + i;
                        return Positioned(
                          top: i * 60.0 * _minPx - 8,
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
                      }),
                    ),
                  ),
                ),
              ),

              // 그리드
              Expanded(
                child: SingleChildScrollView(
                  controller: _hContent,
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    controller: _vContent,
                    child: SizedBox(
                      width: totalW,
                      height: totalH,
                      child: Stack(
                        children: [
                          // 세로 구분선
                          ...List.generate(stages.length, (i) => Positioned(
                                left: (i + 1) * _stageW - 0.5,
                                top: 0,
                                bottom: 0,
                                width: 0.5,
                                child: Container(color: colors.listDivider),
                              )),
                          // 가로선 (1시간/30분/10분)
                          ...List.generate(
                            (_endHour - _startHour) * 6 + 1,
                            (i) {
                              final mins = i * 10;
                              final isHour = mins % 60 == 0;
                              final isHalf = mins % 30 == 0;
                              return Positioned(
                                top: mins * _minPx,
                                left: 0, right: 0, height: 0.5,
                                child: Container(
                                  color: isHour
                                      ? colors.listDivider.withValues(alpha: 0.9)
                                      : isHalf
                                          ? colors.listDivider.withValues(alpha: 0.5)
                                          : colors.listDivider.withValues(alpha: 0.2),
                                ),
                              );
                            },
                          ),
                          // 공연 카드
                          ..._filtered.map((entry) {
                            final si = stages.indexOf(entry.stageName);
                            if (si < 0) return const SizedBox.shrink();
                            final top = _toY(entry.startTime);
                            final cardH = _toY(entry.endTime) - top;
                            final color = _colorFor(entry.stageName);
                            return Positioned(
                              left: si * _stageW + 3,
                              top: top + 2,
                              width: _stageW - 6,
                              height: cardH - 4,
                              child: _PerformanceCard(
                                entry: entry,
                                color: color,
                                cardHeight: cardH - 4,
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final TimetableEntry entry;
  final Color color;
  final double cardHeight;

  const _PerformanceCard(
      {required this.entry, required this.color, required this.cardHeight});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
              color: color.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.artistName,
            style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (cardHeight > 28)
            Text(
              '${entry.startTime} – ${entry.endTime}',
              style: const TextStyle(
                  color: Colors.white70, fontSize: 9, height: 1.3),
            ),
        ],
      ),
    );
  }
}
