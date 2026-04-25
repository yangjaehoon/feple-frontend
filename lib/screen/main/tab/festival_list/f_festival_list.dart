import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/constant/festival_constants.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/screen/main/tab/festival_list/w_festival_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/festival_preview_provider.dart';
import '../search/w_feple_app_bar.dart';

class ConcertListFragment extends StatefulWidget {
  const ConcertListFragment({super.key});

  @override
  State<ConcertListFragment> createState() => _ConcertListFragmentState();
}

class _ConcertListFragmentState extends State<ConcertListFragment> {
  bool _filterExpanded = false;

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final colors = context.appColors;
    // 필터 개수만 구독 — 페스티벌 목록 로딩과 무관하게 재빌드하지 않음
    final activeFilterCount = context.select<FestivalPreviewProvider, int>(
      (p) => p.selectedGenres.length + p.selectedRegions.length,
    );

    return Container(
      color: colors.backgroundMain,
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: () async =>
                context.read<FestivalPreviewProvider>().refresh(),
            color: colors.activate,
            child: CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: EdgeInsets.only(
                    top: rs.h(AppDimens.scrollPaddingTop),
                    bottom: rs.h(AppDimens.scrollPaddingBottom),
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      _FilterPanel(
                        expanded: _filterExpanded,
                        onToggle: () =>
                            setState(() => _filterExpanded = !_filterExpanded),
                        activeFilterCount: activeFilterCount,
                      ),
                      const ConcertListWidget(),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          FepleAppBar('festival_schedule'.tr()),
        ],
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final int activeFilterCount;

  const _FilterPanel({
    required this.expanded,
    required this.onToggle,
    required this.activeFilterCount,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final provider = context.watch<FestivalPreviewProvider>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.tune_rounded,
                      size: 18, color: colors.activate),
                  const SizedBox(width: 8),
                  Text(
                    'btn_filter'.tr(),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textTitle,
                    ),
                  ),
                  if (activeFilterCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.activate,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$activeFilterCount',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                  const Spacer(),
                  if (activeFilterCount > 0)
                    GestureDetector(
                      onTap: provider.clearFilters,
                      child: Text(
                        'btn_reset'.tr(),
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.textSecondary,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: colors.textSecondary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            Divider(height: 1, color: colors.listDivider),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FilterSection(
                    label: '장르',
                    items: kGenreOptions,
                    selected: provider.selectedGenres,
                    onToggle: provider.toggleGenre,
                  ),
                  const SizedBox(height: 12),
                  _FilterSection(
                    label: '지역',
                    items: kRegionOptions,
                    selected: provider.selectedRegions,
                    onToggle: provider.toggleRegion,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String label;
  final List<(String, String)> items;
  final Set<String> selected;
  final void Function(String) onToggle;

  const _FilterSection({
    required this.label,
    required this.items,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: items.map((item) {
            final (value, displayName) = item;
            final isSelected = selected.contains(value);
            return GestureDetector(
              onTap: () => onToggle(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colors.activate
                      : colors.backgroundMain,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? colors.activate
                        : colors.listDivider,
                  ),
                ),
                child: Text(
                  displayName.tr(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : colors.textTitle,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
