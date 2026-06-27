import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/constant/festival_constants.dart';
import 'package:feple/screen/main/tab/festival_list/w_festival_list.dart';
import 'package:feple/screen/main/tab/search/w_feple_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/festival_preview_provider.dart';

class ConcertListFragment extends StatefulWidget {
  const ConcertListFragment({super.key});

  @override
  State<ConcertListFragment> createState() => _ConcertListFragmentState();
}

class _ConcertListFragmentState extends State<ConcertListFragment> {
  bool _filterExpanded = false;
  bool _showScrollToTop = false;
  late final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FestivalPreviewProvider>().addListener(_onProviderChange);
    });
  }

  void _onProviderChange() {
    if (!mounted) return;
    final provider = context.read<FestivalPreviewProvider>();
    final err = provider.refreshError;
    if (err == null) return;
    provider.clearRefreshError();
    context.showErrorSnackbar(err);
  }

  @override
  void dispose() {
    context.read<FestivalPreviewProvider>().removeListener(_onProviderChange);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!mounted) return;
    final pixels = _scrollController.position.pixels;
    final show = pixels > 300;
    if (show != _showScrollToTop) setState(() => _showScrollToTop = show);
    final provider = context.read<FestivalPreviewProvider>();
    if (!provider.hasMore || provider.isLoadingMore || provider.isLoading) return;
    if (pixels >= _scrollController.position.maxScrollExtent - 300) {
      provider.fetchNext();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // 각 필터 Set을 개별 구독 — 로딩·목록 변경 시 재빌드 없음
    final selectedGenres = context.select<FestivalPreviewProvider, Set<String>>(
      (p) => p.selectedGenres,
    );
    final selectedRegions = context.select<FestivalPreviewProvider, Set<String>>(
      (p) => p.selectedRegions,
    );
    final selectedAgeRestrictions = context.select<FestivalPreviewProvider, Set<String>>(
      (p) => p.selectedAgeRestrictions,
    );

    return Stack(
      children: [
        ColoredBox(
      color: colors.backgroundMain,
      child: Column(
        children: [
          FepleAppBar('festival_schedule'.tr()),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => context.read<FestivalPreviewProvider>().refresh(force: true),
              color: colors.activate,
              child: CustomScrollView(
                controller: _scrollController,
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.only(bottom: AppDimens.scrollPaddingBottom),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _FilterPanel(
                          expanded: _filterExpanded,
                          onToggle: () =>
                              setState(() => _filterExpanded = !_filterExpanded),
                          selectedGenres: selectedGenres,
                          selectedRegions: selectedRegions,
                          selectedAgeRestrictions: selectedAgeRestrictions,
                        ),
                        const ConcertListWidget(),
                        const _LoadMoreIndicator(),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
        ),
        if (_showScrollToTop)
          Positioned(
            bottom: 20,
            right: 16,
            child: FloatingActionButton.small(
              heroTag: 'festivalScrollTop',
              onPressed: () => _scrollController.animateTo(
                0,
                duration: AppDimens.animNormal,
                curve: Curves.easeOut,
              ),
              backgroundColor: colors.surface,
              foregroundColor: colors.textTitle,
              elevation: 2,
              child: const Icon(Icons.arrow_upward_rounded, size: 20),
            ),
          ),
      ],
    );
  }
}

class _FilterPanel extends StatelessWidget {
  final bool expanded;
  final VoidCallback onToggle;
  final Set<String> selectedGenres;
  final Set<String> selectedRegions;
  final Set<String> selectedAgeRestrictions;

  const _FilterPanel({
    required this.expanded,
    required this.onToggle,
    required this.selectedGenres,
    required this.selectedRegions,
    required this.selectedAgeRestrictions,
  });

  int get _activeFilterCount =>
      selectedGenres.length + selectedRegions.length + selectedAgeRestrictions.length;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // context.read: 콜백 전용 (반응형 상태 아님)
    final p = context.read<FestivalPreviewProvider>();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
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
          _buildHeader(colors, p.clearFilters),
          if (expanded) ...[
            Divider(height: 1, color: colors.listDivider),
            _buildBody(colors, p),
          ],
        ],
      ),
    );
  }

  Widget _buildHeader(AbstractThemeColors colors, VoidCallback onClearFilters) {
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.tune_rounded, size: 18, color: colors.activate),
            const SizedBox(width: 8),
            Text(
              'btn_filter'.tr(),
              style: TextStyle(
                fontSize: AppDimens.fontSizeMd,
                fontWeight: FontWeight.w700,
                color: colors.textTitle,
              ),
            ),
            if (_activeFilterCount > 0) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: colors.activate,
                  borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
                ),
                child: Text(
                  '$_activeFilterCount',
                  style: const TextStyle(
                      color: Colors.white, fontSize: AppDimens.fontSizeXxs, fontWeight: FontWeight.w700),
                ),
              ),
            ],
            const Spacer(),
            if (_activeFilterCount > 0)
              GestureDetector(
                onTap: onClearFilters,
                child: Text(
                  'btn_reset'.tr(),
                  style: TextStyle(fontSize: AppDimens.fontSizeXs, color: colors.textSecondary),
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
    );
  }

  Widget _buildBody(AbstractThemeColors colors, FestivalPreviewProvider p) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilterSection(
            label: 'filter_genre'.tr(),
            items: kGenreOptions,
            selected: selectedGenres,
            onToggle: p.toggleGenre,
          ),
          const SizedBox(height: 12),
          _FilterSection(
            label: 'filter_region'.tr(),
            items: kRegionOptions,
            selected: selectedRegions,
            onToggle: p.toggleRegion,
          ),
          const SizedBox(height: 12),
          _FilterSection(
            label: 'filter_age_restriction'.tr(),
            items: kAgeRestrictionOptions,
            selected: selectedAgeRestrictions,
            onToggle: p.toggleAgeRestriction,
          ),
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
          style: TextStyle(fontSize: AppDimens.fontSizeXs, fontWeight: FontWeight.w700, color: colors.textSecondary),
        ),
        const SizedBox(height: 8),
        _buildChips(colors),
      ],
    );
  }

  Widget _buildChips(AbstractThemeColors colors) {
    return Wrap(
      spacing: 8,
      runSpacing: 6,
      children: items.map((item) {
        final (value, displayName) = item;
        return _buildChip(colors, value, displayName, selected.contains(value));
      }).toList(),
    );
  }

  Widget _buildChip(AbstractThemeColors colors, String value, String displayName, bool isSelected) {
    return GestureDetector(
      onTap: () => onToggle(value),
      child: AnimatedContainer(
        duration: AppDimens.animXFast,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? colors.activate : colors.backgroundMain,
          borderRadius: BorderRadius.circular(AppDimens.cardRadius),
          border: Border.all(color: isSelected ? colors.activate : colors.listDivider),
        ),
        child: Text(
          displayName.tr(),
          style: TextStyle(
            fontSize: AppDimens.fontSizeSm,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : colors.textTitle,
          ),
        ),
      ),
    );
  }
}

class _LoadMoreIndicator extends StatelessWidget {
  const _LoadMoreIndicator();

  @override
  Widget build(BuildContext context) {
    return Consumer<FestivalPreviewProvider>(
      builder: (_, p, __) {
        if (p.isLoadingMore) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: context.appColors.activate)),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
