import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/model/artist_model.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/search/w_search_result_tiles.dart';
import 'package:flutter/material.dart';

/// 검색 실행 후 결과 화면 — 전체/아티스트/페스티벌/게시글 탭.
/// 결과가 하나도 없으면 빈 상태를 대신 보여준다.
class SearchResultsView extends StatelessWidget {
  final List<Artist> artists;
  final List<FestivalPreview> festivals;
  final List<Post> posts;
  final String keyword;
  final TabController tabController;

  const SearchResultsView({
    super.key,
    required this.artists,
    required this.festivals,
    required this.posts,
    required this.keyword,
    required this.tabController,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    if (artists.length + festivals.length + posts.length == 0) {
      return EmptyState(
          icon: Icons.search_off_rounded, title: 'search_no_result'.tr());
    }
    return Column(
      children: [
        _buildTabBar(colors),
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: [
              _buildAllTab(colors),
              _buildCategoryTab(
                colors,
                items: artists,
                builder: (d) =>
                    SearchArtistTile(data: d, highlightKeyword: keyword),
                emptyIcon: Icons.person_search_rounded,
              ),
              _buildCategoryTab(
                colors,
                items: festivals,
                builder: (d) =>
                    SearchFestivalTile(data: d, highlightKeyword: keyword),
                emptyIcon: Icons.festival_rounded,
              ),
              _buildCategoryTab(
                colors,
                items: posts,
                builder: (d) =>
                    SearchPostTile(data: d, highlightKeyword: keyword),
                emptyIcon: Icons.article_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(AbstractThemeColors colors) {
    final labels = [
      'search_all'.tr(),
      'search_artists'.tr(),
      'search_festivals'.tr(),
      'search_posts'.tr(),
    ];
    final counts = [null, artists.length, festivals.length, posts.length];

    return TabBar(
      controller: tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: colors.activate,
      unselectedLabelColor: colors.textSecondary,
      indicatorColor: colors.activate,
      indicatorWeight: 2,
      labelStyle: const TextStyle(
          fontSize: AppDimens.fontSizeSm, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(
          fontSize: AppDimens.fontSizeSm, fontWeight: FontWeight.w400),
      tabs: List.generate(labels.length, (i) {
        final count = counts[i];
        return Tab(
          text: count != null && count > 0
              ? '${labels[i]} ($count)'
              : labels[i],
        );
      }),
    );
  }

  Widget _buildAllTab(AbstractThemeColors colors) {
    final hasArtists = artists.isNotEmpty;
    final hasFestivals = festivals.isNotEmpty;
    final hasPosts = posts.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        if (hasArtists) ...[
          _sectionHeader('search_artists'.tr(), artists.length, colors,
              isFirst: true),
          ...artists.map((d) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SearchArtistTile(data: d, highlightKeyword: keyword),
              )),
        ],
        if (hasFestivals) ...[
          _sectionHeader('search_festivals'.tr(), festivals.length, colors,
              isFirst: !hasArtists),
          ...festivals.map((d) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SearchFestivalTile(data: d, highlightKeyword: keyword),
              )),
        ],
        if (hasPosts) ...[
          _sectionHeader('search_posts'.tr(), posts.length, colors,
              isFirst: !hasArtists && !hasFestivals),
          ...posts.map((d) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SearchPostTile(data: d, highlightKeyword: keyword),
              )),
        ],
      ],
    );
  }

  Widget _buildCategoryTab<T>(
    AbstractThemeColors colors, {
    required List<T> items,
    required Widget Function(T) builder,
    required IconData emptyIcon,
  }) {
    if (items.isEmpty) {
      return EmptyState(icon: emptyIcon, title: 'search_no_result'.tr());
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: items.length,
      itemBuilder: (_, i) =>
          AnimatedListItem(index: i, child: builder(items[i])),
      separatorBuilder: (_, _) => Divider(height: 1, color: colors.listDivider),
    );
  }

  Widget _sectionHeader(String title, int count, AbstractThemeColors colors,
      {bool isFirst = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isFirst)
          Divider(height: 1, thickness: 1, color: colors.listDivider),
        Padding(
          padding: EdgeInsets.fromLTRB(16, isFirst ? 16 : 20, 16, 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 18,
                decoration: BoxDecoration(
                  color: colors.sectionBarColor,
                  borderRadius: BorderRadius.circular(AppDimens.barRadius),
                ),
              ),
              const SizedBox(width: AppDimens.space8),
              Text(title,
                  style: TextStyle(
                      fontSize: AppDimens.fontSizeLg,
                      fontWeight: FontWeight.w800,
                      color: colors.textTitle)),
              const SizedBox(width: AppDimens.space6),
              Text('($count)',
                  style: TextStyle(
                      fontSize: AppDimens.fontSizeSm,
                      color: colors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
