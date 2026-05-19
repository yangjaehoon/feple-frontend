import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_schedule.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_songs.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_main_image_swiper.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_board.dart';

import 'package:flutter/material.dart';

class ArtistPage extends StatefulWidget {
  const ArtistPage({
    super.key,
    required this.artistName,
    required this.artistId,
    required this.followerCounter,
    this.profileImageUrl,
  });

  final String artistName;
  final int artistId;
  final int followerCounter;
  final String? profileImageUrl;

  @override
  State<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
  int _refreshKey = 0;

  Future<void> _onRefresh() async {
    setState(() => _refreshKey++);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              height: AppDimens.appBarHeight,
              color: colors.appBarColor,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      widget.artistName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: SafeArea(
              top: false,
              child: RefreshIndicator(
          color: colors.activate,
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              children: [
                MainImageSwiper(
                  key: ValueKey('swiper_$_refreshKey'),
                  artistName: widget.artistName,
                  artistId: widget.artistId,
                  followerCount: widget.followerCounter,
                  profileImageUrl: widget.profileImageUrl,
                ),
                ArtistBoard(
                  key: ValueKey('board_$_refreshKey'),
                  artistId: widget.artistId,
                  artistName: widget.artistName,
                ),
                ArtistSongs(
                  key: ValueKey('songs_$_refreshKey'),
                  artistId: widget.artistId,
                  artistName: widget.artistName,
                ),
                ArtistSchedule(
                  key: ValueKey('schedule_$_refreshKey'),
                  artistId: widget.artistId,
                  artistName: widget.artistName,
                ),
              ],
            ),
          ),
        ),
      ),
          ),
        ],
      ),
    );
  }
}
