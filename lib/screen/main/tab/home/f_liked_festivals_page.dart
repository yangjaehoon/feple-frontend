import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_app_network_image.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/screen/main/tab/home/w_reorder_sheet.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:flutter/material.dart';

class LikedFestivalsPage extends StatelessWidget {
  const LikedFestivalsPage({
    super.key,
    required this.festivals,
    this.onSaveOrder,
  });

  final List<FestivalModel> festivals;
  final Future<void> Function(List<int>)? onSaveOrder;

  void _openSettings(BuildContext context) {
    final items = festivals
        .map((f) => ReorderItem(id: f.id, name: f.title, imageUrl: f.posterUrl))
        .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReorderSheet(
        title: 'liked_festivals'.tr(),
        subtitle: 'reorder_liked_festivals_hint'.tr(),
        items: items,
        onSave: onSaveOrder ?? (_) {},
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

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
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textTitle,
          ),
        ),
        actions: [
          if (onSaveOrder != null)
            IconButton(
              icon: Icon(Icons.settings_rounded, color: colors.textSecondary, size: 20),
              onPressed: () => _openSettings(context),
            ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.only(top: 8, bottom: 24),
        itemCount: festivals.length,
        itemBuilder: (context, index) {
          final festival = festivals[index];
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
      ),
    );
  }
}

class _FestivalCard extends StatelessWidget {
  const _FestivalCard({required this.festival});

  final FestivalModel festival;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      height: 140,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
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
          Container(
            height: 120,
            margin: const EdgeInsets.all(10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 2 / 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AppNetworkImage(
                      imageUrl: festival.posterUrl,
                      fit: BoxFit.fill,
                    ),
                    if (festival.isEnded) ...[
                      Container(color: Colors.black.withValues(alpha: 0.5)),
                      Center(
                        child: Text(
                          'status_ended'.tr(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
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
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    festival.title,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
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
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
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
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
      color = Colors.green.shade600;
    } else if (dDays == 0) {
      label = 'd_day'.tr();
      color = Colors.redAccent;
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
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
