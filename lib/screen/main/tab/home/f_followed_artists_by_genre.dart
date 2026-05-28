import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/model/followed_artist.dart';
import 'package:feple/screen/main/tab/home/w_reorder_sheet.dart';
import 'package:feple/screen/main/tab/search/artist_page/f_artist_page.dart';
import 'package:flutter/material.dart';

class FollowedArtistsByGenrePage extends StatelessWidget {
  const FollowedArtistsByGenrePage({
    super.key,
    required this.artists,
    this.onSaveOrder,
  });

  final List<FollowedArtist> artists;
  final Future<void> Function(List<int>)? onSaveOrder;

  void _openSettings(BuildContext context) {
    final items = artists
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
        items: items,
        onSave: onSaveOrder!,
      ),
    );
  }

  List<MapEntry<String, List<FollowedArtist>>> _buildGroups(String fallback) {
    final map = <String, List<FollowedArtist>>{};
    for (final artist in artists) {
      final key = (artist.genre?.isNotEmpty == true) ? artist.genre! : fallback;
      (map[key] ??= []).add(artist);
    }
    return map.entries.toList()
      ..sort((a, b) {
        if (a.key == fallback) return 1;
        if (b.key == fallback) return -1;
        return a.key.compareTo(b.key);
      });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final fallback = 'genre_etc'.tr();
    final groups = _buildGroups(fallback);

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
          if (onSaveOrder != null)
            IconButton(
              icon: Icon(Icons.settings_rounded, color: colors.textSecondary, size: 20),
              onPressed: () => _openSettings(context),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 24),
        children: [
          for (final entry in groups) ...[
            _buildGenreHeader(entry.key, entry.value.length, colors),
            for (final artist in entry.value)
              _buildArtistTile(artist, colors, context),
          ],
        ],
      ),
    );
  }

  Widget _buildGenreHeader(String genre, int count, AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 16,
            decoration: BoxDecoration(
              color: colors.sectionBarColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            genre,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: colors.textTitle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistTile(
      FollowedArtist artist, AbstractThemeColors colors, BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: colors.backgroundMain,
        backgroundImage: (artist.profileImageUrl?.isNotEmpty == true)
            ? CachedNetworkImageProvider(artist.profileImageUrl!, maxWidth: 100)
            : null,
        child: (artist.profileImageUrl == null || artist.profileImageUrl!.isEmpty)
            ? Icon(Icons.person_rounded, size: 22, color: colors.textSecondary)
            : null,
      ),
      title: Text(
        artist.name,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: colors.textTitle,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
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
    );
  }
}
