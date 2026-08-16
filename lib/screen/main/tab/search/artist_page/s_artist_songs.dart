import 'package:feple/common/common.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/util/future_refreshable.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_async_content_builder.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/song_model.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_song_list_skeleton.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_song_list_tile.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_song_request_sheet.dart';
import 'package:feple/service/song_service.dart';
import 'package:flutter/material.dart';

class ArtistSongsScreen extends StatefulWidget {
  final int artistId;
  final String artistName;

  /// 프리뷰 카드에서 이미 로드된 목록 — 있으면 첫 진입 시 재요청 없이 바로 보여준다.
  final List<SongModel>? initialSongs;

  const ArtistSongsScreen({
    super.key,
    required this.artistId,
    required this.artistName,
    this.initialSongs,
  });

  @override
  State<ArtistSongsScreen> createState() => _ArtistSongsScreenState();
}

class _ArtistSongsScreenState extends State<ArtistSongsScreen>
    with FutureRefreshable<List<SongModel>, ArtistSongsScreen> {
  final _songService = sl<SongService>();
  bool _isSheetOpen = false;
  bool _initialSongsConsumed = false;

  @override
  Future<List<SongModel>> fetchData() {
    if (!_initialSongsConsumed && widget.initialSongs != null) {
      _initialSongsConsumed = true;
      return Future.value(widget.initialSongs!);
    }
    return _songService.fetchSongs(widget.artistId);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      appBar: SecondaryAppBar(
        title: 'artist_songs_title'.tr(args: [widget.artistName]),
        actions: [
          TextButton.icon(
            onPressed: () {
              if (_isSheetOpen) return;
              _isSheetOpen = true;
              showAppBottomSheet(
                context,
                isDismissible: false,
                enableDrag: false,
                builder: (_) => SongRequestSheet(
                  artistId: widget.artistId,
                  artistName: widget.artistName,
                ),
              ).whenComplete(() {
                if (mounted) _isSheetOpen = false;
              });
            },
            icon: const Icon(Icons.add_rounded, size: 16),
            label: Text('song_request_button'.tr()),
            style: TextButton.styleFrom(
              foregroundColor: colors.appBarIconColor,
              textStyle: const TextStyle(
                fontSize: AppDimens.fontSizeSm,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: colors.activate,
        onRefresh: refresh,
        child: AsyncContentBuilder<List<SongModel>>(
          future: future,
          loadingBuilder: (_) => const SongListSkeleton(itemCount: 6),
          onRetry: refresh,
          emptyBuilder: (_) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              const SizedBox(height: 80),
              EmptyState(icon: Icons.music_off_rounded, title: 'no_songs'.tr()),
            ],
          ),
          useListViewForEmptyState: false,
          builder: (_, songs) => ListView.separated(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(top: 8, bottom: 24),
            itemCount: songs.length,
            separatorBuilder: (_, _) => const SongListDivider(height: 1),
            itemBuilder: (_, index) => AnimatedListItem(
              index: index,
              child: SongListTile(song: songs[index], index: index),
            ),
          ),
        ),
      ),
    );
  }
}
