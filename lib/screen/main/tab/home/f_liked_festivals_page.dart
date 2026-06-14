import 'package:feple/common/common.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_app_network_image.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/screen/main/tab/home/w_reorder_sheet.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

class LikedFestivalsPage extends StatefulWidget {
  const LikedFestivalsPage({
    super.key,
    required this.festivals,
    this.onSaveOrder,
  });

  final List<FestivalModel> festivals;
  final Future<void> Function(List<int>)? onSaveOrder;

  @override
  State<LikedFestivalsPage> createState() => _LikedFestivalsPageState();
}

class _LikedFestivalsPageState extends State<LikedFestivalsPage> {
  bool _showEnded = false;

  void _openSettings() {
    final isEnglish = context.locale.languageCode == 'en';
    final items = widget.festivals
        .where((f) => !f.isEnded)
        .map((f) => ReorderItem(id: f.id, name: f.displayTitle(isEnglish), imageUrl: f.posterUrl))
        .toList();
    showAppBottomSheet(
      context,
      builder: (_) => ReorderSheet(
        title: 'liked_festivals'.tr(),
        subtitle: 'reorder_liked_festivals_hint'.tr(),
        items: items,
        onSave: widget.onSaveOrder ?? (_) {},
      ),
    );
  }

  List<FestivalModel> get _filtered =>
      widget.festivals.where((f) => f.isEnded == _showEnded).toList();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final filtered = _filtered;

    return Scaffold(
      backgroundColor: colors.backgroundMain,
      appBar: AppBar(
        backgroundColor: colors.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: colors.textTitle, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'liked_festivals'.tr(),
          style: TextStyle(
            fontSize: AppDimens.fontSizeXxl,
            fontWeight: FontWeight.w700,
            color: colors.textTitle,
          ),
        ),
        actions: [
          if (widget.onSaveOrder != null && !_showEnded)
            IconButton(
              icon: Icon(Icons.settings_rounded, color: colors.textSecondary, size: 20),
              onPressed: _openSettings,
            ),
        ],
      ),
      body: Column(
        children: [
          _buildTabToggle(colors),
          Expanded(child: _buildList(filtered, colors)),
        ],
      ),
    );
  }

  Widget _buildTabToggle(AbstractThemeColors colors) {
    return Container(
      color: colors.surface,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
      child: Row(
        children: [
          _TabButton(
            label: 'tab_upcoming_festivals'.tr(),
            selected: !_showEnded,
            colors: colors,
            onTap: () => setState(() => _showEnded = false),
          ),
          const SizedBox(width: 8),
          _TabButton(
            label: 'tab_ended_festivals'.tr(),
            selected: _showEnded,
            colors: colors,
            onTap: () => setState(() => _showEnded = true),
          ),
        ],
      ),
    );
  }

  Widget _buildList(List<FestivalModel> items, AbstractThemeColors colors) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border_rounded,
                size: 40, color: colors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 10),
            Text(
              _showEnded ? 'tab_ended_festivals'.tr() : 'tab_upcoming_festivals'.tr(),
              style: TextStyle(
                  fontSize: AppDimens.fontSizeMd, color: colors.textSecondary.withValues(alpha: 0.6)),
            ),
            Text(
              'no_liked_in_tab'.tr(),
              style: TextStyle(
                  fontSize: AppDimens.fontSizeSm, color: colors.textSecondary.withValues(alpha: 0.45)),
            ),
          ],
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final festival = items[index];
        return AnimatedListItem(
          index: index,
          child: TapScale(
            onTap: () => Navigator.push(
              context,
              SlideRoute(
                builder: (_) => FestivalInformationFragment(poster: festival),
              ),
            ),
            child: _FestivalCard(festival: festival),
          ),
        );
      },
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.colors,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final AbstractThemeColors colors;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDimens.animFast,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? colors.activate : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
          border: Border.all(
            color: selected ? colors.activate : colors.listDivider,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: AppDimens.fontSizeSm,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _FestivalCard extends StatelessWidget {
  const _FestivalCard({required this.festival});

  final FestivalModel festival;

  Widget _buildPosterSection(AbstractThemeColors colors) {
    return Container(
      height: 120,
      margin: const EdgeInsets.all(10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
        child: AspectRatio(
          aspectRatio: 2 / 3,
          child: Stack(
            fit: StackFit.expand,
            children: [
              AppNetworkImage(imageUrl: festival.posterUrl, fit: BoxFit.fill),
              if (festival.isEnded) ...[
                Container(color: Colors.black.withValues(alpha: 0.5)),
                Center(
                  child: Text(
                    'status_ended'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: AppDimens.fontSizeSm,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
              if (!festival.isEnded && festival.dDaysUntil != null)
                Positioned(
                  top: 6,
                  left: 6,
                  child: _DayBadge(dDays: festival.dDaysUntil!, colors: colors),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoSection(AbstractThemeColors colors, bool isEnglish) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              festival.displayTitle(isEnglish),
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: AppDimens.fontSizeXl,
                color: colors.textTitle,
                letterSpacing: -0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(Icons.location_on_rounded, color: colors.activate, size: 14),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    festival.location,
                    style: TextStyle(fontSize: AppDimens.fontSizeXs, color: colors.textSecondary, fontWeight: FontWeight.w500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: colors.activate, size: 14),
                const SizedBox(width: 4),
                Text(
                  festival.startDate,
                  style: TextStyle(fontSize: AppDimens.fontSizeXs, color: colors.textSecondary, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          _buildPosterSection(colors),
          _buildInfoSection(colors, context.locale.languageCode == 'en'),
        ],
      ),
    );
  }
}

class _DayBadge extends StatelessWidget {
  const _DayBadge({required this.dDays, required this.colors});

  final int dDays;
  final AbstractThemeColors colors;

  @override
  Widget build(BuildContext context) {
    final String label;
    final Color color;

    if (dDays < 0) {
      label = 'festival_ongoing'.tr();
      color = colors.statusOngoingColor;
    } else if (dDays == 0) {
      label = 'd_day'.tr();
      color = AppColors.errorRed;
    } else if (dDays <= 7) {
      label = 'D-$dDays';
      color = colors.activate;
    } else {
      label = 'D-$dDays';
      color = colors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppDimens.radiusBadge),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: AppDimens.fontSizeTiny,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
