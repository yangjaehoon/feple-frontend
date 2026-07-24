import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/navigation_guard.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:feple/common/widget/w_async_content_builder.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/song_model.dart';
import 'package:feple/service/song_service.dart';
import 'package:feple/screen/main/tab/community_board/w_board_card_header.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_songs.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_song_list_skeleton.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_song_list_tile.dart';
import 'package:flutter/material.dart';

class ArtistSongs extends StatefulWidget {
  final int artistId;
  final String artistName;

  const ArtistSongs({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  State<ArtistSongs> createState() => ArtistSongsState();
}

class ArtistSongsState extends State<ArtistSongs> with NavigationGuard {
  final _songService = sl<SongService>();
  late Future<List<SongModel>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _songsFuture = _fetchSongs();
  }

  Future<List<SongModel>> _fetchSongs() =>
      _songService.fetchSongs(widget.artistId);

  Future<void> refresh() async {
    final future = _fetchSongs();
    setState(() { _songsFuture = future; });
    try { await future; } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SurfaceCard(
      width: double.infinity,
      child: Column(
        children: [
          BoardCardHeader(
            icon: Icons.music_note_rounded,
            title: 'artist_songs_title'.tr(args: [widget.artistName]),
            headerColor: colors.activate,
            onTap: () => guardedNavigate(() => Navigator.push(
              context,
              SlideRoute(
                builder: (_) => ArtistSongsScreen(
                  artistId: widget.artistId,
                  artistName: widget.artistName,
                ),
              ),
            )),
          ),
          _buildSongList(colors),
        ],
      ),
    );
  }

  Widget _buildSongList(AbstractThemeColors colors) {
    return AsyncContentBuilder<List<SongModel>>(
      future: _songsFuture,
      loadingBuilder: (_) => const SongListSkeleton(),
      onRetry: () => setState(() { _songsFuture = _fetchSongs(); }),
      emptyBuilder: (_) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: EmptyState(icon: Icons.music_off_rounded, title: 'no_songs'.tr()),
      ),
      useListViewForEmptyState: false,
      builder: (_, songs) {
        final preview = songs.take(5).toList();
        return Column(
          children: [
            for (int i = 0; i < preview.length; i++) ...[
              SongListTile(song: preview[i], index: i),
              if (i < preview.length - 1)
                Divider(
                  thickness: 1,
                  color: colors.listDivider,
                  indent: AppDimens.paddingHorizontal,
                  endIndent: AppDimens.paddingHorizontal,
                ),
            ],
          ],
        );
      },
    );
  }
}
