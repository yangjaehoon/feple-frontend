import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/song_model.dart';
import 'package:feple/service/song_service.dart';
import 'package:feple/screen/main/tab/community_board/w_board_card_header.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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

  Future<void> _openYoutubeMusic(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('youtube_open_failed'.tr())),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingHorizontal,
        vertical: AppDimens.paddingVertical,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius:
            const BorderRadius.all(Radius.circular(AppDimens.cardRadius)),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.12),
            blurRadius: AppDimens.cardRadius,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          BoardCardHeader(
            icon: Icons.music_note_rounded,
            title: 'artist_songs_title'.tr(args: [widget.artistName]),
            headerColor: colors.activate,
            onTap: () {},
          ),
          _buildSongList(colors),
        ],
      ),
    );
  }

  Widget _buildSongSkeleton() {
    return Column(
      children: List.generate(3, (i) {
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppDimens.paddingHorizontal, vertical: 12),
              child: Row(
                children: [
                  const SkeletonBox(width: 52, height: 39, borderRadius: BorderRadius.all(Radius.circular(4))),
                  const SizedBox(width: 12),
                  const Expanded(
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
            if (i < 2)
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
              message: 'err_fetch_data'.tr(args: ['']),
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

        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: songs.length,
          itemBuilder: (_, index) => _buildSongItem(songs[index], index, colors),
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

  Widget _buildSongItem(SongModel song, int index, AbstractThemeColors colors) {
    return InkWell(
      onTap: () => _openYoutubeMusic(song.youtubeUrl),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimens.paddingHorizontal,
          vertical: 12,
        ),
        child: Row(
          children: [
            Text(
              '${index + 1}',
              style: TextStyle(
                fontSize: AppDimens.fontSizeXs,
                color: colors.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 12),
            if (song.thumbnailUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
                child: CachedNetworkImage(
                  imageUrl: song.thumbnailUrl!,
                  width: 52,
                  height: 39,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _thumbnailPlaceholder(colors),
                ),
              )
            else
              _thumbnailPlaceholder(colors),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                song.title,
                style: TextStyle(
                  fontSize: AppDimens.fontSizeMd,
                  fontWeight: FontWeight.w500,
                  color: colors.textTitle,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.open_in_new_rounded, size: 14, color: colors.textSecondary),
          ],
        ),
      ),
    );
  }

  Widget _thumbnailPlaceholder(AbstractThemeColors colors) {
    return Container(
      width: 52,
      height: 39,
      decoration: BoxDecoration(
        color: colors.backgroundMain,
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
      ),
      child: Icon(Icons.music_note_rounded, size: 18, color: colors.textSecondary),
    );
  }
}
