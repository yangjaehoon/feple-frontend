import 'package:fast_app_base/common/common.dart';
import 'package:flutter/material.dart';

// ── Mock data (실제 백엔드 연동 전 임시) ─────────────────────────────────────
class TimetableEntry {
  final String artistName;
  final String stage;
  final int startHour;
  final int startMin;
  final int endHour;
  final int endMin;
  final Color color;

  const TimetableEntry({
    required this.artistName,
    required this.stage,
    required this.startHour,
    required this.startMin,
    required this.endHour,
    required this.endMin,
    required this.color,
  });
}

const _stages = ['Main', 'Sub1', 'Sub2'];
const _selectedDate = '2026-05-03';

const _mockEntries = [
  TimetableEntry(artistName: 'Artist A', stage: 'Main',  startHour: 13, startMin: 0,  endHour: 14, endMin: 30, color: Color(0xFF6C5CE7)),
  TimetableEntry(artistName: 'Artist B', stage: 'Sub1',  startHour: 13, startMin: 30, endHour: 15, endMin: 0,  color: Color(0xFF00B894)),
  TimetableEntry(artistName: 'Artist C', stage: 'Main',  startHour: 15, startMin: 0,  endHour: 16, endMin: 30, color: Color(0xFFE17055)),
  TimetableEntry(artistName: 'Artist D', stage: 'Sub2',  startHour: 14, startMin: 0,  endHour: 15, endMin: 30, color: Color(0xFF74B9FF)),
  TimetableEntry(artistName: 'Artist E', stage: 'Sub1',  startHour: 16, startMin: 0,  endHour: 17, endMin: 30, color: Color(0xFFFD79A8)),
  TimetableEntry(artistName: 'Artist F', stage: 'Main',  startHour: 17, startMin: 0,  endHour: 19, endMin: 0,  color: Color(0xFFA29BFE)),
  TimetableEntry(artistName: 'Artist G', stage: 'Sub2',  startHour: 16, startMin: 30, endHour: 18, endMin: 0,  color: Color(0xFF55EFC4)),
];
// ─────────────────────────────────────────────────────────────────────────────

class FestivalTimetable extends StatefulWidget {
  const FestivalTimetable({super.key});

  @override
  State<FestivalTimetable> createState() => _FestivalTimetableState();
}

class _FestivalTimetableState extends State<FestivalTimetable> {
  // 시간 범위: 12:00 ~ 24:00
  static const int _startHour = 12;
  static const int _endHour = 24;

  // 1분 = 1.5px  →  10분 = 15px, 1시간 = 90px, 12시간 = 1080px
  static const double _minPx = 1.5;
  static const double _stageW = 120.0;
  static const double _timeColW = 52.0;
  static const double _stageHeaderH = 38.0;
  static const double _viewH = 460.0;

  final _vContent = ScrollController();
  final _vTime = ScrollController();
  final _hContent = ScrollController();
  final _hHeader = ScrollController();

  bool _lockV = false;
  bool _lockH = false;

  @override
  void initState() {
    super.initState();
    _vContent.addListener(_onVScroll);
    _hContent.addListener(_onHScroll);
  }

  void _onVScroll() {
    if (_lockV) return;
    _lockV = true;
    if (_vTime.hasClients) _vTime.jumpTo(_vContent.offset);
    _lockV = false;
  }

  void _onHScroll() {
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

  double _toY(int hour, int min) =>
      ((hour - _startHour) * 60 + min) * _minPx;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final totalH = (_endHour - _startHour) * 60 * _minPx; // 1080
    final totalW = _stages.length * _stageW;

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
            // ── 날짜 헤더 ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded,
                      size: 15, color: colors.activate),
                  const SizedBox(width: 8),
                  Text(
                    _selectedDate,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textTitle,
                    ),
                  ),
                ],
              ),
            ),

            // ── 스테이지 헤더 행 ───────────────────────────────────────────
            Row(
              children: [
                // 좌상단 코너
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
                // 스테이지 이름들 (헤더 가로 스크롤 = 콘텐츠와 동기화)
                Expanded(
                  child: SingleChildScrollView(
                    controller: _hHeader,
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Row(
                      children: _stages.map((stage) {
                        return Container(
                          width: _stageW,
                          height: _stageHeaderH,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: colors.activate.withValues(alpha: 0.08),
                            border: Border(
                              bottom: BorderSide(color: colors.listDivider),
                              right: BorderSide(
                                  color: colors.listDivider, width: 0.5),
                            ),
                          ),
                          child: Text(
                            stage,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: colors.activate,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),

            // ── 본문: 시간 열 + 그리드 ─────────────────────────────────────
            SizedBox(
              height: _viewH,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 시간 레이블 열 (세로 스크롤 동기화, 가로 고정)
                  SizedBox(
                    width: _timeColW,
                    child: SingleChildScrollView(
                      controller: _vTime,
                      physics: const NeverScrollableScrollPhysics(),
                      child: SizedBox(
                        height: totalH,
                        child: Stack(
                          children: List.generate(
                            _endHour - _startHour + 1,
                            (i) {
                              final hour = _startHour + i;
                              final y = i * 60.0 * _minPx;
                              return Positioned(
                                top: y - 8,
                                left: 0,
                                right: 0,
                                child: Text(
                                  '${hour.toString().padLeft(2, '0')}:00',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: colors.textSecondary,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ),

                  // 그리드 (가로 + 세로 스크롤)
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
                              // 세로 구분선 (스테이지 경계)
                              ...List.generate(_stages.length, (i) {
                                return Positioned(
                                  left: (i + 1) * _stageW - 0.5,
                                  top: 0,
                                  bottom: 0,
                                  width: 0.5,
                                  child: Container(
                                      color: colors.listDivider),
                                );
                              }),

                              // 가로 구분선 (1시간마다 진한 선, 30분마다 흐린 선)
                              ...List.generate(
                                (_endHour - _startHour) * 6 + 1,
                                (i) {
                                  final mins = i * 10;
                                  final isHour = mins % 60 == 0;
                                  final isHalf = mins % 30 == 0;
                                  final y = mins * _minPx;
                                  return Positioned(
                                    top: y,
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
                              ..._mockEntries.map((entry) {
                                final stageIdx = _stages.indexOf(entry.stage);
                                if (stageIdx < 0) return const SizedBox.shrink();
                                final top = _toY(entry.startHour, entry.startMin);
                                final cardH =
                                    _toY(entry.endHour, entry.endMin) - top;
                                return Positioned(
                                  left: stageIdx * _stageW + 3,
                                  top: top + 2,
                                  width: _stageW - 6,
                                  height: cardH - 4,
                                  child: _PerformanceCard(
                                    entry: entry,
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
        ),
      ),
    );
  }
}

class _PerformanceCard extends StatelessWidget {
  final TimetableEntry entry;
  final double cardHeight;

  const _PerformanceCard({required this.entry, required this.cardHeight});

  String _fmt(int h, int m) =>
      '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: entry.color.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: entry.color.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
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
              height: 1.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (cardHeight > 28)
            Text(
              '${_fmt(entry.startHour, entry.startMin)} – ${_fmt(entry.endHour, entry.endMin)}',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 9,
                height: 1.3,
              ),
            ),
        ],
      ),
    );
  }
}
