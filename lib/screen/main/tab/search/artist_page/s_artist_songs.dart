import 'package:feple/common/common.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
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

  const ArtistSongsScreen({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  State<ArtistSongsScreen> createState() => _ArtistSongsScreenState();
}

class _ArtistSongsScreenState extends State<ArtistSongsScreen> {
  final _songService = sl<SongService>();
  late Future<List<SongModel>> _future;
  bool _isSheetOpen = false;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<SongModel>> _fetch() => _songService.fetchSongs(widget.artistId);

  Future<void> _refresh() async {
    setState(() {
      _future = _fetch();
    });
    try {
      await _future;
    } catch (_) {}
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
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
        onRefresh: _refresh,
        child: FutureBuilder<List<SongModel>>(
          future: _future,
          builder: (context, snapshot) => _buildBody(snapshot, colors),
        ),
      ),
    );
  }

  Widget _buildBody(
    AsyncSnapshot<List<SongModel>> snapshot,
    AbstractThemeColors colors,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return const SongListSkeleton(itemCount: 6);
    }
    if (snapshot.hasError) {
      return ErrorState.network(snapshot.error!, onRetry: _refresh);
    }
    final songs = snapshot.data ?? [];
    if (songs.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          const SizedBox(height: 80),
          EmptyState(icon: Icons.music_off_rounded, title: 'no_songs'.tr()),
        ],
      );
    }
    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(top: 8, bottom: 24),
      itemCount: songs.length,
      separatorBuilder: (_, _) => Divider(
        height: 1,
        thickness: 1,
        color: colors.listDivider,
        indent: AppDimens.paddingHorizontal,
        endIndent: AppDimens.paddingHorizontal,
      ),
      itemBuilder: (_, index) => SongListTile(song: songs[index], index: index),
    );
  }
}
