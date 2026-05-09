import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/constant/timetable_colors.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_timetable_user_entry.dart';
import 'package:flutter/material.dart';

class TimetableFullscreenGrid extends StatefulWidget {
  final List<String> stages;
  final List<TimetableEntry> filtered;
  final List<UserEntry> userEntries;
  final int startHour;
  final int endHour;
  final Set<String> followedNames;
  final void Function(String stage, String startTime) onTapGrid;
  final void Function(UserEntry entry) onTapUserEntry;

  const TimetableFullscreenGrid({
    super.key,
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
  State<TimetableFullscreenGrid> createState() => _TimetableFullscreenGridState();
}

class _TimetableFullscreenGridState extends State<TimetableFullscreenGrid> {
  static const double _topPad = 16.0;
  static const double _bottomPad = 16.0;
  static const double _timeColW = 48.0;
  static const double _stageHeaderH = 36.0;

  Offset? _tapPos;

  double _toY(String time, double pxPerMin) {
    final parts = time.split(':');
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return ((hour - widget.startHour) * 60 + minute) * pxPerMin;
  }

  Color _stageColor(String stage) {
    final idx = widget.stages.indexOf(stage) % kStageColors.length;
    return kStageColors[idx < 0 ? 0 : idx];
  }

  void _handleTap(double pxPerMin, double stageW) {
    if (_tapPos == null) return;
    final pos = _tapPos!;
    _tapPos = null;

    final totalMins = (widget.endHour - widget.startHour) * 60;
    final rawMins = ((pos.dy - _topPad) / pxPerMin).round();
    final clampedMins = rawMins.clamp(0, totalMins);
    final hour = widget.startHour + (clampedMins ~/ 60);
    final minute = (clampedMins % 60 ~/ 10) * 10;
    final timeStr =
        '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

    final si = (pos.dx / stageW).floor().clamp(0, widget.stages.length - 1);
    widget.onTapGrid(widget.stages[si], timeStr);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return LayoutBuilder(builder: (_, constraints) {
      final availW = constraints.maxWidth;
      final availH = constraints.maxHeight;

      final gridH = availH - _stageHeaderH;
      final totalMins = (widget.endHour - widget.startHour) * 60;
      final pxPerMin = (gridH - _topPad - _bottomPad) / totalMins.clamp(1, 99999);

      final stageW = widget.stages.isEmpty
          ? availW - _timeColW
          : (availW - _timeColW) / widget.stages.length;

      return Column(
        children: [
          // 스테이지 헤더
          SizedBox(
            height: _stageHeaderH,
            child: Row(
              children: [
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
                ...widget.stages.map((stage) {
                  final color = _stageColor(stage);
                  return Container(
                    width: stageW,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      border: Border(
                        bottom: BorderSide(color: colors.listDivider),
                        right: BorderSide(color: colors.listDivider, width: 0.5),
                      ),
                    ),
                    child: Text(
                      stage,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color),
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                }),
              ],
            ),
          ),

          // 그리드 본문
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

                        // 가로선
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
                                    ? colors.listDivider.withValues(alpha: 0.9)
                                    : isHalf
                                        ? colors.listDivider.withValues(alpha: 0.5)
                                        : colors.listDivider.withValues(alpha: 0.2),
                              ),
                            );
                          },
                        ),

                        // 공식 공연 카드
                        ...widget.filtered.map((entry) {
                          final si = widget.stages.indexOf(entry.stageName);
                          if (si < 0) return const SizedBox.shrink();
                          final rawTop = _toY(entry.startTime, pxPerMin);
                          final cardH = _toY(entry.endTime, pxPerMin) - rawTop;
                          final color = _stageColor(entry.stageName);
                          final followed = widget.followedNames.contains(entry.artistName);
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

                        // 사용자 일정 카드
                        ...widget.userEntries.map((entry) {
                          final si = widget.stages.indexOf(entry.stageName);
                          if (si < 0) return const SizedBox.shrink();
                          final rawTop = _toY(entry.startTime, pxPerMin);
                          final cardH = _toY(entry.endTime, pxPerMin) - rawTop;
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

  int get _durationMinutes {
    try {
      final startParts = entry.startTime.split(':');
      final endParts = entry.endTime.split(':');
      return (int.parse(endParts[0]) * 60 + int.parse(endParts[1])) -
          (int.parse(startParts[0]) * 60 + int.parse(startParts[1]));
    } catch (_) {
      return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final subColor = followed ? Colors.white70 : color.withValues(alpha: 0.7);
    final subStyle = TextStyle(color: subColor, fontSize: 9, height: 1.2);

    return Container(
      decoration: BoxDecoration(
        color: followed ? color.withValues(alpha: 0.88) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        border: followed
            ? null
            : Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
        boxShadow: followed
            ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))]
            : null,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: Row(
        children: [
          Text('${entry.startTime}–${entry.endTime}', style: subStyle),
          Expanded(
            child: Text(
              entry.artistName,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: followed ? Colors.white : color,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text('$_durationMinutes분', style: subStyle),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final UserEntry entry;
  final double cardH;

  const _UserCard({required this.entry, required this.cardH});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: entry.color.withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        boxShadow: [
          BoxShadow(color: entry.color.withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 2)),
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
                      color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, height: 1.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (cardH > 26)
                  Text(
                    '${entry.startTime} – ${entry.endTime}',
                    style: const TextStyle(color: Colors.white70, fontSize: 9, height: 1.3),
                  ),
              ],
            ),
          ),
          Icon(Icons.edit_rounded, size: 10, color: Colors.white.withValues(alpha: 0.8)),
        ],
      ),
    );
  }
}
