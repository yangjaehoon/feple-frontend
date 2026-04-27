import 'package:feple/common/common.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_schedule.dart';
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
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.artistName),
        backgroundColor: colors.appBarColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: colors.backgroundMain,
      body: SafeArea(
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
    );
  }
}
