import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_selectable_chip.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/navigation_guard.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/model/followed_artist.dart';
import 'package:feple/model/order_utils.dart';
import 'package:feple/screen/main/tab/home/reorder_settings_flow.dart';
import 'package:feple/screen/main/tab/home/w_reorder_screen_app_bar.dart';
import 'package:feple/screen/main/tab/home/w_reorder_sheet.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_page.dart';
import 'package:feple/screen/main/tab/search/w_artist_card.dart';
import 'package:flutter/material.dart';

class FollowedArtistsByGenreScreen extends StatefulWidget {
  const FollowedArtistsByGenreScreen({
    super.key,
    required this.artists,
    this.onSaveOrder,
  });

  final List<FollowedArtist> artists;
  final Future<void> Function(List<int>)? onSaveOrder;

  @override
  State<FollowedArtistsByGenreScreen> createState() =>
      _FollowedArtistsByGenreScreenState();
}

class _FollowedArtistsByGenreScreenState
    extends State<FollowedArtistsByGenreScreen>
    with NavigationGuard, ReorderSettingsFlow<FollowedArtistsByGenreScreen> {
  String? _selectedGenre;
  late List<FollowedArtist> _artists;
  late final List<String> _genres;

  @override
  void initState() {
    super.initState();
    _artists = widget.artists;
    _genres = _computeGenres();
  }

  List<String> _computeGenres() =>
      _artists.expand((a) => a.genres).toSet().toList()..sort();

  List<FollowedArtist> get _filteredArtists => _selectedGenre == null
      ? _artists
      : _artists.where((a) => a.genres.contains(_selectedGenre)).toList();

  @override
  Future<void> Function(List<int>)? get onSaveOrder => widget.onSaveOrder;

  @override
  String get reorderSheetTitle => 'followed_artists'.tr();

  @override
  String? get reorderSheetSubtitle => 'reorder_followed_artists_hint'.tr();

  @override
  List<ReorderItem> buildReorderItems() {
    final isEnglish = context.isEnglish;
    return _artists
        .map((a) => ReorderItem(id: a.id, name: a.displayName(isEnglish), imageUrl: a.profileImageUrl))
        .toList();
  }

  @override
  void applyReorder(List<int> newOrder) {
    // _genres는 정렬된 집합이라 순서 변경으로는 바뀌지 않아 재계산하지 않는다
    setState(() => _artists = reorderById(_artists, newOrder, (a) => a.id));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final genres = _genres;
    final artists = _filteredArtists;

    return Scaffold(
      backgroundColor: colors.backgroundMain,
      appBar: ReorderScreenAppBar(
        title: 'followed_artists'.tr(),
        onOpenSettings: widget.onSaveOrder != null ? openReorderSettings : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (genres.isNotEmpty) _buildGenreChips(genres),
          Expanded(child: _buildGrid(artists, colors)),
        ],
      ),
    );
  }

  Widget _buildGenreChips(List<String> genres) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: SelectableChipRow<String>(
        values: genres,
        selected: _selectedGenre,
        allLabel: 'filter_all'.tr(),
        labelOf: (genre) => genre,
        onChanged: (genre) => setState(() => _selectedGenre = genre),
      ),
    );
  }

  Widget _buildGrid(List<FollowedArtist> artists, AbstractThemeColors colors) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      itemCount: artists.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (context, index) {
        final artist = artists[index];
        return AnimatedListItem(
          index: index,
          child: TapScale(
            onTap: () => guardedNavigate(() => Navigator.push(
              context,
              SlideRoute(builder: (_) => ArtistScreen.fromFollowedArtist(artist)),
            )),
            child: ArtistCard(
              profileImageUrl: artist.profileImageUrl,
              name: artist.displayName(context.isEnglish),
              isFollowed: true,
            ),
          ),
        );
      },
    );
  }

}
