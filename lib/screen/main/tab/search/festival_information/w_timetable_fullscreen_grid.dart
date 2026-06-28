import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/constant/timetable_colors.dart';
import 'package:feple/common/dart/extension/time_of_day_extension.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_timetable_stage_cell.dart';
import 'package:feple/model/user_entry.dart';
import 'package:flutter/material.dart';

class TimetableFullscreenGrid extends StatefulWidget {
  final TimetableRange range;
  final List<UserEntry> userEntries;
  final Set<String> followedNames;
  final void Function(String stage, String startTime) onTapGrid;
  final void Function(UserEntry entry) onTapUserEntry;

  const TimetableFullscreenGrid({
    super.key,
    required this.range,
    required this.userEntries,
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
  static const double _stageHeaderH = 28.0;

  TimetableRange get _range => widget.range;
  List<String> get _stages => _range.stages;
  int get _startHour => _range.startHour;
  int get _endHour => _range.endHour;

  Offset? _tapPos;

  double _toY(String time, double pxPerMin) {
    final parts = time.split(':');
    final hour = int.tryParse(parts.isNotEmpty ? parts[0] : '0') ?? 0;
    final minute = int.tryParse(parts.length > 1 ? parts[1] : '0') ?? 0;
    return ((hour - _startHour) * 60 + minute) * pxPerMin;
  }

  Color _stageColor(String stage) {
    final colorIndex = _stages.indexOf(stage) % kStageColors.length;
    return kStageColors[colorIndex < 0 ? 0 : colorIndex];
  }

  void _handleTap(double pxPerMin, double stageW) {
    if (_tapPos == null) return;
    final pos = _tapPos!;
    _tapPos = null;

    final totalMins = (_endHour - _startHour) * 60;
    final rawMins = ((pos.dy - _topPad) / pxPerMin).round();
    final clampedMins = rawMins.clamp(0, totalMins);
    final hour = _startHour + (clampedMins ~/ 60);
    final minute = (clampedMins % 60 ~/ 10) * 10;
    final timeStr = TimeOfDay(hour: hour, minute: minute).toHHmm;

    final stageIndex = (pos.dx / stageW).floor().clamp(0, _stages.length - 1);
    widget.onTapGrid(_stages[stageIndex], timeStr);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return LayoutBuilder(builder: (_, constraints) {
      final gridH = constraints.maxHeight - _stageHeaderH;
      final totalMins = (_endHour - _startHour) * 60;
      final pxPerMin = (gridH - _topPad - _bottomPad) / totalMins.clamp(1, 99999);
      final stageW = _stages.isEmpty
          ? constraints.maxWidth - _timeColW
          : (constraints.maxWidth - _timeColW) / _stages.length;

      return Column(
        children: [
          _buildStageHeader(stageW),
          SizedBox(
            height: gridH,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTimeColumn(gridH, pxPerMin, colors),
                _buildGridContent(gridH, pxPerMin, stageW, colors),
              ],
            ),
          ),
        ],
      );
    });
  }

  Widget _buildStageHeader(double stageW) {
    return SizedBox(
      height: _stageHeaderH,
      child: Row(
        children: [
          TimetableCornerCell(width: _timeColW),
          ..._stages.map((stage) => TimetableStageCell(
                stage: stage,
                color: _stageColor(stage),
                width: stageW,
              )),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(double gridH, double pxPerMin, AbstractThemeColors colors) {
    return SizedBox(
      width: _timeColW,
      height: gridH,
      child: Stack(
        clipBehavior: Clip.none,
        children: List.generate(_endHour - _startHour + 1, (i) {
          final hour = _startHour + i;
          return Positioned(
            top: _topPad + i * 60.0 * pxPerMin - 8,
            left: 0,
            right: 0,
            child: Text(
              TimeOfDay(hour: hour, minute: 0).toHHmm,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: AppDimens.fontSizeTiny,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildGridContent(
      double gridH, double pxPerMin, double stageW, AbstractThemeColors colors) {
    return SizedBox(
      width: _stages.length * stageW,
      height: gridH,
      child: GestureDetector(
        onTapDown: (d) => _tapPos = d.localPosition,
        onTap: () => _handleTap(pxPerMin, stageW),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            ...List.generate(
              _stages.length,
              (i) => Positioned(
                left: (i + 1) * stageW - 0.5,
                top: 0,
                bottom: 0,
                width: 0.5,
                child: Container(color: colors.listDivider),
              ),
            ),
            ...List.generate(
              (_endHour - _startHour) * 6 + 1,
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
            ..._range.filtered.map((entry) {
              final stageIndex = _stages.indexOf(entry.stageName);
              if (stageIndex < 0) return const SizedBox.shrink();
              final rawTop = _toY(entry.startTime, pxPerMin);
              final cardH = _toY(entry.endTime, pxPerMin) - rawTop;
              return Positioned(
                left: stageIndex * stageW + 3,
                top: _topPad + rawTop + 2,
                width: stageW - 6,
                height: (cardH - 4).clamp(4.0, double.infinity),
                child: _OfficialCard(
                  entry: entry,
                  color: _stageColor(entry.stageName),
                  followed: entry.isFollowedBy(widget.followedNames),
                  cardH: cardH - 4,
                ),
              );
            }),
            ...widget.userEntries.map((entry) {
              final stageIndex = _stages.indexOf(entry.stageName);
              if (stageIndex < 0) return const SizedBox.shrink();
              final rawTop = _toY(entry.startTime, pxPerMin);
              final cardH = _toY(entry.endTime, pxPerMin) - rawTop;
              return Positioned(
                left: stageIndex * stageW + 3,
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
    );
  }
}

class _OfficialCard extends StatelessWidget {
  final TimetableEntry entry;
  final Color color;
  final bool followed;
  final double cardH;

  const _OfficialCard({
    required this.entry,
    required this.color,
    required this.followed,
    required this.cardH,
  });

  @override
  Widget build(BuildContext context) {
    // border(1.5×2=3px) reduces content height for non-followed cards; no vertical padding
    final availH = (cardH - (followed ? 0.0 : 3.0)).clamp(0.0, double.infinity);
    // fontSize × lineHeight(1.25) must fit availH
    final nameFontSize = (availH / 1.25).clamp(0.0, 11.0);
    final subFontSize = nameFontSize * (9.0 / 11.0);

    final nameColor = followed ? Colors.white : color;
    final subColor = followed ? Colors.white70 : color.withValues(alpha: 0.7);

    return Container(
      clipBehavior: Clip.hardEdge,
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
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: nameFontSize < 5.0
          ? const SizedBox.shrink()
          : Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      entry.timeRange,
                      style: TextStyle(color: subColor, fontSize: subFontSize, height: 1.25),
                    ),
                    SizedBox(width: nameFontSize > 8 ? 4 : 2),
                    Expanded(
                      child: Text(
                        entry.artistName,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: nameColor,
                          fontSize: nameFontSize,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: nameFontSize > 8 ? 4 : 2),
                    Text(
                      '${entry.durationMinutes}분',
                      style: TextStyle(color: subColor, fontSize: subFontSize, height: 1.25),
                    ),
                  ],
                ),
                if (entry.memberArtistNames.isNotEmpty && availH > nameFontSize * 1.25 + 10)
                  Text(
                    entry.memberArtistNames.join(' · '),
                    style: TextStyle(color: subColor, fontSize: subFontSize * 0.9, height: 1.2),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: Color(entry.colorValue).withValues(alpha: 0.88),
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        boxShadow: [
          BoxShadow(color: Color(entry.colorValue).withValues(alpha: 0.4), blurRadius: 4, offset: const Offset(0, 2)),
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
                      color: Colors.white, fontSize: AppDimens.fontSizeXxs, fontWeight: FontWeight.w700, height: 1.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (cardH > 26)
                  Text(
                    entry.timeRange,
                    style: const TextStyle(color: Colors.white70, fontSize: AppDimens.fontSizeMini, height: 1.3),
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
