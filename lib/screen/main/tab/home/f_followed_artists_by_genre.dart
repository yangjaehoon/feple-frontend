import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/model/followed_artist.dart';
import 'package:feple/screen/main/tab/home/w_reorder_sheet.dart';
import 'package:feple/screen/main/tab/search/artist_page/f_artist_page.dart';
import 'package:flutter/material.dart';

class FollowedArtistsByGenrePage extends StatefulWidget {
  const FollowedArtistsByGenrePage({
    super.key,
    required this.artists,
    this.onSaveOrder,
  });

  final List<FollowedArtist> artists;
  final Future<void> Function(List<int>)? onSaveOrder;

  @override
  State<FollowedArtistsByGenrePage> createState() =>
      _FollowedArtistsByGenrePageState();
}

class _FollowedArtistsByGenrePageState
    extends State<FollowedArtistsByGenrePage> {
  String? _selectedGenre;

  List<String> get _genres => widget.artists
      .map((a) => a.genre)
      .whereType<String>()
      .where((g) => g.isNotEmpty)
      .toSet()
      .toList()
    ..sort();

  List<FollowedArtist> get _filteredArtists => _selectedGenre == null
      ? widget.artists
      : widget.artists.where((a) => a.genre == _selectedGenre).toList();

  void _openSettings() {
    final items = widget.artists
        .map((a) => ReorderItem(id: a.id, name: a.name, imageUrl: a.profileImageUrl))
        .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReorderSheet(
        title: 'followed_artists'.tr(),
        subtitle: 'reorder_followed_artists_hint'.tr(),
        items: items,
        onSave: widget.onSaveOrder ?? (_) {},
      ),
    );
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
          icon: Icon(Icons.arrow_back_ios_rounded, color: colors.textTitle, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'followed_artists'.tr(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: colors.textTitle,
          ),
        ),
        actions: [
          if (widget.onSaveOrder != null)
            IconButton(
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
            _GenreChip(
              label: 'filter_all'.tr(),
              selected: _selectedGenre == null,
              onTap: () => setState(() => _selectedGenre = null),
            ),
            ...genres.map((genre) => _GenreChip(
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
            onTap: () => Navigator.push(
              context,
              SlideRoute(
                builder: (_) => ArtistPage(
                  artistId: artist.id,
                  artistName: artist.name,
                  followerCounter: 0,
                  profileImageUrl: artist.profileImageUrl,
                ),
              ),
            ),
            child: _buildArtistCard(artist, colors),
          ),
        );
      },
    );
  }

  Widget _buildArtistCard(FollowedArtist artist, AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: colors.cardShadow.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12.0),
              child: (artist.profileImageUrl?.isNotEmpty == true)
                  ? CachedNetworkImage(
                      imageUrl: artist.profileImageUrl!,
                      memCacheWidth: 200,
                      fit: BoxFit.cover,
                      placeholder: (_, __) =>
                          const SkeletonBox(height: double.infinity),
                      errorWidget: (_, __, ___) => _buildPlaceholder(colors),
                    )
                  : _buildPlaceholder(colors),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          artist.name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textTitle,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPlaceholder(AbstractThemeColors colors) {
    return Container(
      color: colors.activate.withValues(alpha: 0.1),
      child: Icon(Icons.person_rounded, color: colors.activate, size: 40),
    );
  }
}

class _GenreChip extends StatelessWidget {
  const _GenreChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colors.activate : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colors.activate : colors.listDivider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
