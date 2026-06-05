import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/song_model.dart';
import 'package:feple/service/song_service.dart';
import 'package:feple/screen/main/tab/community_board/w_board_card_header.dart';
import 'package:feple/screen/main/tab/search/artist_page/f_artist_songs.dart';
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
  State<ArtistSongs> createState() => _ArtistSongsState();
}

class _ArtistSongsState extends State<ArtistSongs> {
  late Future<List<SongModel>> _songsFuture;

  @override
  void initState() {
    super.initState();
    _songsFuture = _fetchSongs();
  }

  Future<List<SongModel>> _fetchSongs() =>
      sl<SongService>().fetchSongs(widget.artistId);

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
            onTap: () => Navigator.push(
              context,
              SlideRoute(
                builder: (_) => ArtistSongsScreen(
                  artistId: widget.artistId,
                  artistName: widget.artistName,
                ),
              ),
            ),
          ),
          _buildSongList(colors),
        ],
      ),
    );
  }

  Widget _buildSongSkeleton() {
    return Column(
      children: List.generate(3, (index) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingHorizontal, vertical: 12),
              child: const Row(
                children: [
                  SkeletonBox(width: 52, height: 52, borderRadius: BorderRadius.all(Radius.circular(4))),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(height: 13),
                        SizedBox(height: 6),
                        SkeletonBox(width: 80, height: 11),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (index < 2)
              const Divider(height: 1, thickness: 1, indent: 16, endIndent: 16),
          ],
        );
      }),
    );
  }

  Widget _buildSongList(AbstractThemeColors colors) {
    return FutureBuilder<List<SongModel>>(
      future: _songsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSongSkeleton();
        }
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: ErrorState(
              message: 'err_fetch_data'.tr(),
              onRetry: () => setState(() {
                _songsFuture = _fetchSongs();
              }),
            ),
          );
        }

        final songs = snapshot.data ?? [];
        if (songs.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: EmptyState(
              icon: Icons.music_off_rounded,
              title: 'no_songs'.tr(),
            ),
          );
        }

        final preview = songs.take(5).toList();

        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: preview.length,
          itemBuilder: (_, index) => SongListTile(song: preview[index], index: index),
          separatorBuilder: (_, __) => Divider(
            thickness: 1,
            color: colors.listDivider,
            indent: AppDimens.paddingHorizontal,
            endIndent: AppDimens.paddingHorizontal,
          ),
        );
      },
    );
  }
}
