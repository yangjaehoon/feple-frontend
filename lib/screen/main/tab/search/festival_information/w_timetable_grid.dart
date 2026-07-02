import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/constant/timetable_colors.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:flutter/material.dart';
import 'w_timetable_stage_cell.dart';

class TimetableScrollControllers {
  final ScrollController hHeader;
  final ScrollController hContent;
  final ScrollController vContent;
  final ScrollController vTime;

  const TimetableScrollControllers({
    required this.hHeader,
    required this.hContent,
    required this.vContent,
    required this.vTime,
  });
}

class TimetableGrid extends StatelessWidget {
  static const double _minPx = 1.5;
  static const double _topPad = 20.0;
  static const double _bottomPad = 24.0;
  static const double _timeColW = 52.0;
  static const double _stageHeaderH = 38.0;
  static const double _viewH = 460.0;
  static const double _minStageW = 80.0;

  final List<String> stages;
  final List<TimetableEntry> filtered;
  final int startHour;
  final int endHour;
  final Set<String> followedNames;
  final double availableW;
  final TimetableScrollControllers scrollControllers;

  const TimetableGrid({
    super.key,
    required this.stages,
    required this.filtered,
    required this.startHour,
    required this.endHour,
    required this.followedNames,
    required this.availableW,
    required this.scrollControllers,
  });

  double _toY(String time) {
    final timeComponents = time.split(':');
    final hour = int.tryParse(timeComponents.isNotEmpty ? timeComponents[0] : '0') ?? 0;
    final minute = int.tryParse(timeComponents.length > 1 ? timeComponents[1] : '0') ?? 0;
    return ((hour - startHour) * 60 + minute) * _minPx;
  }

  Color _colorFor(String stage) {
    final colorIndex = stages.indexOf(stage) % kStageColors.length;
    return kStageColors[colorIndex < 0 ? 0 : colorIndex];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final stageW = stages.isEmpty
        ? _minStageW
        : ((availableW - _timeColW) / stages.length).clamp(_minStageW, double.infinity);
    final totalW = stages.isEmpty ? stageW : stages.length * stageW;
    final totalH = (endHour - startHour) * 60 * _minPx + _topPad + _bottomPad;

    return Column(
      children: [
        _buildStageHeader(stageW),
        _buildBody(colors, stageW, totalW, totalH),
      ],
    );
  }

  Widget _buildStageHeader(double stageW) {
    return Row(
      children: [
        TimetableCornerCell(width: _timeColW, height: _stageHeaderH),
        Expanded(
          child: SingleChildScrollView(
            controller: scrollControllers.hHeader,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: stages.map((stage) => TimetableStageCell(
                stage: stage,
                color: _colorFor(stage),
                width: stageW,
                height: _stageHeaderH,
              )).toList(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody(AbstractThemeColors colors, double stageW, double totalW, double totalH) {
    return SizedBox(
      height: _viewH,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTimeColumn(colors, totalH),
          Expanded(child: _buildGridContent(colors, stageW, totalW, totalH)),
        ],
      ),
    );
  }

  Widget _buildTimeColumn(AbstractThemeColors colors, double totalH) {
    return SizedBox(
      width: _timeColW,
      child: SingleChildScrollView(
        controller: scrollControllers.vTime,
        physics: const NeverScrollableScrollPhysics(),
        child: SizedBox(
          height: totalH,
          child: Stack(
            children: List.generate(endHour - startHour + 1, (i) {
              final hour = startHour + i;
              return Positioned(
                top: _topPad + i * 60.0 * _minPx - 8,
                left: 0,
                right: 0,
                child: Text(
                  '${hour.toString().padLeft(2, '0')}:00',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: AppDimens.fontSizeTiny, fontWeight: FontWeight.w600, color: colors.textSecondary),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildGridContent(AbstractThemeColors colors, double stageW, double totalW, double totalH) {
    return SingleChildScrollView(
      controller: scrollControllers.hContent,
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        controller: scrollControllers.vContent,
        child: SizedBox(
          width: totalW,
          height: totalH,
          child: Stack(
            children: [
              // 수십~수백 개의 Positioned Container 대신 CustomPaint 1개로 처리
              Positioned.fill(
                child: RepaintBoundary(
                  child: CustomPaint(
                    painter: _TimetableGridPainter(
                      dividerColor: colors.listDivider,
                      stages: stages,
                      stageW: stageW,
                      topPad: _topPad,
                      minPx: _minPx,
                      startHour: startHour,
                      endHour: endHour,
                    ),
                  ),
                ),
              ),
              ..._buildPerformanceCards(stageW),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildPerformanceCards(double stageW) {
    final cards = <Widget>[];
    for (final entry in filtered) {
      final rawTop = _toY(entry.startTime);
      final clampedH = (_toY(entry.endTime) - rawTop - 4).clamp(4.0, double.infinity);
      if (entry.isOps) {
        // 운영 항목: 별도 열 없이 모든 스테이지 열에 동일하게 표시
        for (int i = 0; i < stages.length; i++) {
          cards.add(Positioned(
            left: i * stageW + 3,
            top: _topPad + rawTop + 2,
            width: stageW - 6,
            height: clampedH,
            child: _PerformanceCard(
              entry: entry,
              color: kOpsColor,
              cardHeight: clampedH,
              isFollowed: false,
            ),
          ));
        }
      } else {
        final stageIndex = stages.indexOf(entry.stageName);
        if (stageIndex < 0) continue;
        cards.add(Positioned(
          left: stageIndex * stageW + 3,
          top: _topPad + rawTop + 2,
          width: stageW - 6,
          height: clampedH,
          child: _PerformanceCard(
            entry: entry,
            color: _colorFor(entry.stageName),
            cardHeight: clampedH,
            isFollowed: entry.isFollowedBy(followedNames),
          ),
        ));
      }
    }
    return cards;
  }
}

class _TimetableGridPainter extends CustomPainter {
  final Color dividerColor;
  final List<String> stages;
  final double stageW;
  final double topPad;
  final double minPx;
  final int startHour;
  final int endHour;

  const _TimetableGridPainter({
    required this.dividerColor,
    required this.stages,
    required this.stageW,
    required this.topPad,
    required this.minPx,
    required this.startHour,
    required this.endHour,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final totalMinutes = (endHour - startHour) * 60;
    for (int mins = 0; mins <= totalMinutes; mins += 10) {
      final isHour = mins % 60 == 0;
      final isHalf = mins % 30 == 0;
      final alpha = isHour ? 0.9 : isHalf ? 0.5 : 0.2;
      final paint = Paint()
        ..color = dividerColor.withValues(alpha: alpha)
        ..strokeWidth = 0.5;
      final y = topPad + mins * minPx;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    final vPaint = Paint()
      ..color = dividerColor
      ..strokeWidth = 0.5;
    for (int i = 1; i <= stages.length; i++) {
      final x = i * stageW - 0.5;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), vPaint);
    }
  }

  @override
  bool shouldRepaint(_TimetableGridPainter old) =>
      old.dividerColor != dividerColor ||
      old.stages.length != stages.length ||
      old.stageW != stageW ||
      old.startHour != startHour ||
      old.endHour != endHour;
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
        color: isFollowed ? color.withValues(alpha: 0.88) : Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        border: isFollowed
            ? null
            : Border.all(color: color.withValues(alpha: 0.6), width: 1.5),
        boxShadow: isFollowed
            ? [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 4, offset: const Offset(0, 2))]
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
                fontSize: AppDimens.fontSizeXxs,
                fontWeight: FontWeight.w700,
                height: 1.2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (entry.memberArtistNames.isNotEmpty && cardHeight > 36)
            Text(
              entry.memberArtistNames.join(' · '),
              style: TextStyle(
                  color: isFollowed ? Colors.white70 : color.withValues(alpha: 0.7),
                  fontSize: AppDimens.fontSizeNano,
                  height: 1.2),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          if (cardHeight > 28)
            Text(
              entry.timeRange,
              style: TextStyle(
                  color: isFollowed ? Colors.white70 : color.withValues(alpha: 0.7),
                  fontSize: AppDimens.fontSizeMini,
                  height: 1.3),
            ),
        ],
      ),
    );
  }
}
