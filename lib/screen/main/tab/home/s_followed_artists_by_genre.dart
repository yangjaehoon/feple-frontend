import 'package:feple/common/common.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/widget/w_selectable_chip.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/navigation_guard.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/model/followed_artist.dart';
import 'package:feple/screen/main/tab/home/w_reorder_sheet.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_page.dart';
import 'package:feple/screen/main/tab/search/w_artist_card.dart';
import 'package:feple/common/constant/app_dimensions.dart';
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
    extends State<FollowedArtistsByGenreScreen> with NavigationGuard {
  String? _selectedGenre;
  bool _isSheetOpen = false;
  late List<FollowedArtist> _artists;
  late List<String> _genres;

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

  void _openSettings() async {
    if (_isSheetOpen) return;
    _isSheetOpen = true;
    final isEnglish = context.isEnglish;
    final items = _artists
        .map((a) => ReorderItem(id: a.id, name: a.displayName(isEnglish), imageUrl: a.profileImageUrl))
        .toList();
    final newOrder = await showAppBottomSheet<List<int>>(
      context,
      builder: (_) => ReorderSheet(
        title: 'followed_artists'.tr(),
        subtitle: 'reorder_followed_artists_hint'.tr(),
        items: items,
        onSave: widget.onSaveOrder ?? (_) {},
      ),
    );
    if (mounted) _isSheetOpen = false;
    // widget.artists는 화면 진입 시점의 스냅샷이라 onSaveOrder가 상위 notifier를
    // 갱신해도 이 화면 자체는 재진입 전까지 반영되지 않았음 — 즉시 반영
    if (newOrder != null && mounted) {
      setState(() {
        _artists = _reordered(_artists, newOrder);
        _genres = _computeGenres();
      });
    }
  }

  List<FollowedArtist> _reordered(List<FollowedArtist> source, List<int> order) {
    final map = {for (final a in source) a.id: a};
    final ordered = order.where(map.containsKey).map((id) => map[id]!).toList();
    final orderedIds = order.toSet();
    final rest = source.where((a) => !orderedIds.contains(a.id)).toList();
    return [...ordered, ...rest];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final genres = _genres;
    final artists = _filteredArtists;

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
          'followed_artists'.tr(),
          style: TextStyle(
            fontSize: AppDimens.fontSizeXxl,
            fontWeight: FontWeight.w700,
            color: colors.textTitle,
          ),
        ),
        actions: [
          if (widget.onSaveOrder != null)
            IconButton(
              tooltip: 'settings'.tr(),
              icon: Icon(Icons.settings_rounded, color: colors.textSecondary, size: 20),
              onPressed: _openSettings,
            ),
        ],
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
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            SelectableChip(
              label: 'filter_all'.tr(),
              selected: _selectedGenre == null,
              onTap: () => setState(() => _selectedGenre = null),
            ),
            ...genres.map((genre) => SelectableChip(
                  label: genre,
                  selected: _selectedGenre == genre,
                  onTap: () => setState(() => _selectedGenre = genre),
                )),
          ],
        ),
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
              SlideRoute(builder: (_) => ArtistScreen(
                artistId: artist.id,
                artistName: artist.name,
                artistNameEn: artist.nameEn,
                followerCount: artist.followerCount,
                profileImageUrl: artist.profileImageUrl,
              )),
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
