import 'package:feple/common/common.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  static const double _minPx = 1.5;
  static const double _topPad = 20.0;
  static const double _timeColW = 52.0;
  static const double _stageHeaderH = 38.0;
  static const double _viewH = 460.0;
  static const double _minStageW = 80.0;

  final _vContent = ScrollController();
  final _vTime = ScrollController();
  final _hContent = ScrollController();
  final _hHeader = ScrollController();
  bool _lockV = false, _lockH = false;

  List<TimetableEntry> _entries = [];
  Set<String> _followedNames = {};
  bool _loading = true;
  String? _error;

  List<String> _dates = [];
  String? _selectedDate;

  // 캐싱된 계산 결과 (build 호출마다 반복 계산 방지)
  List<TimetableEntry> _cachedFiltered = [];
  List<String> _cachedStages = [];
  int _cachedStartHour = 12;
  int _cachedEndHour = 13;

  void _rebuildCache() {
    _cachedFiltered = _selectedDate == null
        ? []
        : _entries.where((e) => e.festivalDate == _selectedDate).toList();

    final seen = <String, int>{};
    for (final e in _cachedFiltered) {
      seen.putIfAbsent(e.stageName, () => e.stageOrder);
    }
    final sorted = seen.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    _cachedStages = sorted.map((e) => e.key).toList();

    int minH = 12;
    for (final e in _cachedFiltered) {
      final h = int.tryParse(e.startTime.split(':')[0]);
      if (h != null && h < minH) minH = h;
    }
    _cachedStartHour = minH;

    int maxH = minH + 1;
    for (final e in _cachedFiltered) {
      final parts = e.endTime.split(':');
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts.length > 1 ? parts[1] : '0');
      if (h == null || m == null) continue;
      final endH = m > 0 ? h + 1 : h;
      if (endH > maxH) maxH = endH;
    }
    _cachedEndHour = maxH;
  }

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
      for (var d = start; !d.isAfter(end); d = d.add(const Duration(days: 1))) {
        _dates.add(
            '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}');
      }
      _selectedDate = _dates.isNotEmpty ? _dates.first : null;
    } catch (_) {
      // 날짜 파싱 실패 시 날짜 탭 미표시
    }
  }

  Future<void> _fetch() async {
    try {
      final timetableFuture =
          DioClient.dio.get('/festivals/${widget.festivalId}/timetable');

      // 로그인한 경우 팔로우 아티스트 병렬 조회
      final user = context.read<UserProvider>().user;
      final followFuture = user != null
          ? DioClient.dio.get('/users/${user.id}/following')
          : null;

      final timetableRes = await timetableFuture;
      final list = (timetableRes.data as List)
          .map((e) => TimetableEntry.fromJson(e as Map<String, dynamic>))
          .toList();

      Set<String> followed = {};
      if (followFuture != null) {
        final followRes = await followFuture;
        followed = (followRes.data as List)
            .map((a) => (a['name'] as String))
            .toSet();
      }

      if (mounted) {
        setState(() {
          _entries = list;
          _followedNames = followed;
          _loading = false;
          _rebuildCache();
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
    _vContent.removeListener(_onV);
    _hContent.removeListener(_onH);
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
    return ((h - _cachedStartHour) * 60 + m) * _minPx;
  }

  Color _colorFor(String stage) {
    final idx = _cachedStages.indexOf(stage) % _stageColors.length;
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
                      onTap: () => setState(() {
                        _selectedDate = date;
                        _rebuildCache();
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(right: 8, bottom: 10),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: selected
                              ? colors.activate
                              : colors.backgroundMain,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? colors.activate
                                : colors.listDivider,
                          ),
                        ),
                        child: Text(
                          date,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color:
                                selected ? Colors.white : colors.textTitle,
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
            else if (_cachedFiltered.isEmpty)
              Padding(
                padding: const EdgeInsets.all(24),
                child: Center(
                    child: Text('등록된 타임테이블이 없습니다.',
                        style: TextStyle(color: colors.textSecondary))),
              )
            else
              LayoutBuilder(
                builder: (_, constraints) =>
                    _buildGrid(colors, constraints.maxWidth),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(dynamic colors, double availableW) {
    final stages = _cachedStages;
    // 스테이지 수에 맞게 너비 동적 계산 (최소 80px 보장)
    final stageW = stages.isEmpty
        ? _minStageW
        : ((availableW - _timeColW) / stages.length)
            .clamp(_minStageW, double.infinity);
    final totalW = stages.isEmpty ? stageW : stages.length * stageW;
    final totalH = (_cachedEndHour - _cachedStartHour) * 60 * _minPx + _topPad;

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
                      width: stageW,
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
                              fontSize: 12,
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
                      children: List.generate(_cachedEndHour - _cachedStartHour + 1, (i) {
                        final hour = _cachedStartHour + i;
                        return Positioned(
                          top: _topPad + i * 60.0 * _minPx - 8,
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
                          ...List.generate(
                              _cachedStages.length,
                              (i) => Positioned(
                                    left: (i + 1) * stageW - 0.5,
                                    top: 0,
                                    bottom: 0,
                                    width: 0.5,
                                    child: Container(color: colors.listDivider),
                                  )),
                          // 가로선
                          ...List.generate(
                            (_cachedEndHour - _cachedStartHour) * 6 + 1,
                            (i) {
                              final mins = i * 10;
                              final isHour = mins % 60 == 0;
                              final isHalf = mins % 30 == 0;
                              return Positioned(
                                top: _topPad + mins * _minPx,
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
                          // 공연 카드
                          ..._cachedFiltered.map((entry) {
                            final si = stages.indexOf(entry.stageName);
                            if (si < 0) return const SizedBox.shrink();
                            final rawTop = _toY(entry.startTime);
                            final cardH = _toY(entry.endTime) - rawTop;
                            final color = _colorFor(entry.stageName);
                            final followed =
                                _followedNames.contains(entry.artistName);
                            return Positioned(
                              left: si * stageW + 3,
                              top: _topPad + rawTop + 2,
                              width: stageW - 6,
                              height: cardH - 4,
                              child: _PerformanceCard(
                                entry: entry,
                                color: color,
                                cardHeight: cardH - 4,
                                isFollowed: followed,
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
  final bool isFollowed;

  const _PerformanceCard({
    required this.entry,
    required this.color,
    required this.cardHeight,
    required this.isFollowed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        // 팔로우한 아티스트만 배경 채움, 나머지는 테두리만
        color: isFollowed ? color.withValues(alpha: 0.88) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        border: isFollowed
            ? null
            : Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
        boxShadow: isFollowed
            ? [
                BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 4,
                    offset: const Offset(0, 2)),
              ]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.artistName,
            style: TextStyle(
                color: isFollowed ? Colors.white : color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (cardHeight > 28)
            Text(
              '${entry.startTime} – ${entry.endTime}',
              style: TextStyle(
                  color: isFollowed
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
