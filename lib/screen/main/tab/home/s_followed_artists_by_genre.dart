import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/widget/w_selectable_chip.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/model/followed_artist.dart';
import 'package:feple/screen/main/tab/home/w_reorder_sheet.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_page.dart';
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
    extends State<FollowedArtistsByGenreScreen> {
  String? _selectedGenre;
  bool _isNavigating = false;
  bool _isSheetOpen = false;

  List<String> get _genres => widget.artists
      .expand((a) => a.genres)
      .toSet()
      .toList()
    ..sort();

  List<FollowedArtist> get _filteredArtists => _selectedGenre == null
      ? widget.artists
      : widget.artists.where((a) => a.genres.contains(_selectedGenre)).toList();

  void _openSettings() {
    if (_isSheetOpen) return;
    _isSheetOpen = true;
    final isEnglish = context.isEnglish;
    final items = widget.artists
        .map((a) => ReorderItem(id: a.id, name: a.displayName(isEnglish), imageUrl: a.profileImageUrl))
        .toList();
    showAppBottomSheet(
      context,
      builder: (_) => ReorderSheet(
        title: 'followed_artists'.tr(),
        subtitle: 'reorder_followed_artists_hint'.tr(),
        items: items,
        onSave: widget.onSaveOrder ?? (_) {},
      ),
    ).whenComplete(() { if (mounted) _isSheetOpen = false; });
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
            onTap: () {
              if (_isNavigating) return;
              _isNavigating = true;
              Navigator.push(
                context,
                SlideRoute(builder: (_) => ArtistScreen(
                  artistId: artist.id,
                  artistName: artist.name,
                  artistNameEn: artist.nameEn,
                  followerCount: artist.followerCount,
                  profileImageUrl: artist.profileImageUrl,
                )),
              ).whenComplete(() { if (mounted) _isNavigating = false; });
            },
            child: _buildArtistCard(artist, context.isEnglish, colors),
          ),
        );
      },
    );
  }

  Widget _buildArtistCard(FollowedArtist artist, bool isEnglish, AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
              boxShadow: [
                BoxShadow(
                  color: colors.cardShadow.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
              child: (artist.profileImageUrl?.isNotEmpty == true)
                  ? CachedNetworkImage(
                      imageUrl: artist.profileImageUrl!,
                      memCacheWidth: 300,
                      fit: BoxFit.cover,
                      fadeInDuration: AppDimens.animXFast,
                      fadeOutDuration: AppDimens.animTapFeedback,
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
          artist.displayName(isEnglish),
          style: TextStyle(
            fontSize: AppDimens.fontSizeSm,
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
