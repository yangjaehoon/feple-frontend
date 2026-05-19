import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/song_model.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_song_request_sheet.dart';
import 'package:feple/service/song_service.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ArtistSongsScreen extends StatefulWidget {
  final int artistId;
  final String artistName;

  const ArtistSongsScreen({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  State<ArtistSongsScreen> createState() => _ArtistSongsScreenState();
}

class _ArtistSongsScreenState extends State<ArtistSongsScreen> {
  late Future<List<SongModel>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<SongModel>> _fetch() async {
    final songs = await sl<SongService>().fetchSongs(widget.artistId);
    songs.sort((a, b) {
      final c = b.festivalCount.compareTo(a.festivalCount);
      return c != 0 ? c : a.title.compareTo(b.title);
    });
    return songs;
  }

  Future<void> _refresh() async {
    setState(() { _future = _fetch(); });
    try {
      await _future;
    } catch (_) {}
  }

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
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SecondaryAppBar(
            title: 'artist_songs_title'.tr(args: [widget.artistName]),
            actions: [
              TextButton.icon(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => SongRequestSheet(
                    artistId: widget.artistId,
                    artistName: widget.artistName,
                  ),
                ),
                icon: const Icon(Icons.add_rounded, size: 16),
                label: Text('song_request_button'.tr()),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          Expanded(
            child: RefreshIndicator(
              color: colors.activate,
              onRefresh: _refresh,
              child: FutureBuilder<List<SongModel>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return ErrorState(
                      message: 'err_fetch_data'.tr(args: ['']),
                      onRetry: _refresh,
                    );
                  }
                  final songs = snapshot.data ?? [];
                  if (songs.isEmpty) {
                    return ListView(
                      children: [
                        const SizedBox(height: 80),
                        EmptyState(
                          icon: Icons.music_off_rounded,
                          title: 'no_songs'.tr(),
                        ),
                      ],
                    );
                  }
                  return ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: songs.length,
                    separatorBuilder: (_, __) => Divider(
                      height: 1,
                      thickness: 1,
                      color: colors.listDivider,
                      indent: AppDimens.paddingHorizontal,
                      endIndent: AppDimens.paddingHorizontal,
                    ),
                    itemBuilder: (_, index) =>
                        _buildSongItem(songs[index], index, colors),
                  );
                },
              ),
            ),
          ),
        ],
      ),
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
            SizedBox(
              width: 24,
              child: Text(
                '${index + 1}',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: AppDimens.fontSizeXs,
                  color: colors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(width: 10),
            if (song.thumbnailUrl != null)
              ClipRRect(
                borderRadius:
                    BorderRadius.circular(AppDimens.cardRadiusTiny),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    song.title,
                    style: TextStyle(
                      fontSize: AppDimens.fontSizeMd,
                      fontWeight: FontWeight.w500,
                      color: colors.textTitle,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (song.festivalCount > 0) ...[
                    const SizedBox(height: 3),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: colors.activate.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'festival_performed_count'
                            .tr(args: [song.festivalCount.toString()]),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: colors.activate,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.open_in_new_rounded,
                size: 14, color: colors.textSecondary),
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
      child: Icon(Icons.music_note_rounded,
          size: 18, color: colors.textSecondary),
    );
  }
}
