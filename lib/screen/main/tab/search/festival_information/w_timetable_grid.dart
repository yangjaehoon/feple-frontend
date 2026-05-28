import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/constant/timetable_colors.dart';
import 'package:feple/model/timetable_entry.dart';
import 'package:flutter/material.dart';

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
    final idx = stages.indexOf(stage) % kStageColors.length;
    return kStageColors[idx < 0 ? 0 : idx];
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
        _buildStageHeader(colors, stageW),
        _buildBody(colors, stageW, totalW, totalH),
      ],
    );
  }

  Widget _buildStageHeader(AbstractThemeColors colors, double stageW) {
    return Row(
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
            controller: scrollControllers.hHeader,
            scrollDirection: Axis.horizontal,
            physics: const NeverScrollableScrollPhysics(),
            child: Row(
              children: stages.map((stage) => Container(
                width: stageW,
                height: _stageHeaderH,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: _colorFor(stage).withValues(alpha: 0.12),
                  border: Border(
                    bottom: BorderSide(color: colors.listDivider),
                    right: BorderSide(color: colors.listDivider, width: 0.5),
                  ),
                ),
                child: Text(
                  stage,
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _colorFor(stage)),
                ),
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
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: colors.textSecondary),
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
              ..._buildVerticalDividers(colors, stageW),
              ..._buildHorizontalLines(colors),
              ..._buildPerformanceCards(stageW),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildVerticalDividers(AbstractThemeColors colors, double stageW) {
    return List.generate(
      stages.length,
      (i) => Positioned(
        left: (i + 1) * stageW - 0.5,
        top: 0,
        bottom: 0,
        width: 0.5,
        child: Container(color: colors.listDivider),
      ),
    );
  }

  List<Widget> _buildHorizontalLines(AbstractThemeColors colors) {
    return List.generate(
      (endHour - startHour) * 6 + 1,
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
                ? colors.listDivider.withValues(alpha: 0.9)
                : isHalf
                    ? colors.listDivider.withValues(alpha: 0.5)
                    : colors.listDivider.withValues(alpha: 0.2),
          ),
        );
      },
    );
  }

  List<Widget> _buildPerformanceCards(double stageW) {
    return filtered.map((entry) {
      final si = stages.indexOf(entry.stageName);
      if (si < 0) return const SizedBox.shrink();
      final rawTop = _toY(entry.startTime);
      final cardH = _toY(entry.endTime) - rawTop;
      return Positioned(
        left: si * stageW + 3,
        top: _topPad + rawTop + 2,
        width: stageW - 6,
        height: cardH - 4,
        child: _PerformanceCard(
          entry: entry,
          color: _colorFor(entry.stageName),
          cardHeight: cardH - 4,
          isFollowed: followedNames.contains(entry.artistName),
        ),
      );
    }).toList();
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
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.2),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (cardHeight > 28)
            Text(
              entry.timeRange,
              style: TextStyle(
                  color: isFollowed ? Colors.white70 : color.withValues(alpha: 0.7),
                  fontSize: 9,
                  height: 1.3),
            ),
        ],
      ),
    );
  }
}
