import 'package:feple/common/common.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/navigation_guard.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/screen/main/tab/festival_list/w_festival_preview_card.dart';
import 'package:feple/screen/main/tab/home/w_reorder_sheet.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

FestivalPreview _asPreview(FestivalModel f) => FestivalPreview(
      id: f.id,
      title: f.title,
      titleEn: f.titleEn,
      description: f.description,
      location: f.location,
      posterUrl: f.posterUrl,
      startDate: f.startDate,
      endDate: f.endDate,
      genres: f.genres,
      ageRestriction: f.ageRestriction,
      latitude: f.latitude,
      longitude: f.longitude,
      attendingCount: f.attendingCount,
    );

class LikedFestivalsScreen extends StatefulWidget {
  const LikedFestivalsScreen({
    super.key,
    required this.festivals,
    this.onSaveOrder,
  });

  final List<FestivalModel> festivals;
  final Future<void> Function(List<int>)? onSaveOrder;

  @override
  State<LikedFestivalsScreen> createState() => _LikedFestivalsScreenState();
}

class _LikedFestivalsScreenState extends State<LikedFestivalsScreen> with NavigationGuard {
  bool _showEnded = false;
  bool _isSheetOpen = false;
  late List<FestivalModel> _festivals;

  @override
  void initState() {
    super.initState();
    _festivals = widget.festivals;
  }

  void _openSettings() async {
    if (_isSheetOpen) return;
    _isSheetOpen = true;
    final isEnglish = context.isEnglish;
    final items = _festivals
        .where((f) => !f.isEnded)
        .map((f) => ReorderItem(id: f.id, name: f.displayTitle(isEnglish), imageUrl: f.posterUrl))
        .toList();
    final newOrder = await showAppBottomSheet<List<int>>(
      context,
      builder: (_) => ReorderSheet(
        title: 'liked_festivals'.tr(),
        subtitle: 'reorder_liked_festivals_hint'.tr(),
        items: items,
        onSave: widget.onSaveOrder ?? (_) {},
      ),
    );
    if (mounted) _isSheetOpen = false;
    // 저장 성공 여부와 무관하게 화면에 방금 지정한 순서를 즉시 반영 —
    // widget.festivals는 화면 진입 시점의 스냅샷이라 onSaveOrder가 상위
    // notifier를 갱신해도 이 화면 자체는 재진입 전까지 반영되지 않았음
    if (newOrder != null && mounted) {
      setState(() => _festivals = _reordered(_festivals, newOrder));
    }
  }

  List<FestivalModel> _reordered(List<FestivalModel> source, List<int> order) {
    final map = {for (final f in source) f.id: f};
    final ordered = order.where(map.containsKey).map((id) => map[id]!).toList();
    final orderedIds = order.toSet();
    final rest = source.where((f) => !orderedIds.contains(f.id)).toList();
    return [...ordered, ...rest];
  }

  List<FestivalModel> get _filtered =>
      _festivals.where((f) => f.isEnded == _showEnded).toList();

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
          tooltip: 'back'.tr(),
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
              tooltip: 'settings'.tr(),
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
            onTap: () => guardedNavigate(() => Navigator.push(
              context,
              SlideRoute(builder: (_) => FestivalInformationFragment(poster: festival)),
            )),
            child: FestivalPreviewCard(festival: _asPreview(festival)),
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
            color: selected ? Theme.of(context).colorScheme.onPrimary : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
