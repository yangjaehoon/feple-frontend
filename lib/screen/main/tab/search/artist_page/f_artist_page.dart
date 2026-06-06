import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/screen/main/tab/search/artist_page/artist_follow_notifier.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_board.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_schedule.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_songs.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_main_image_swiper.dart';
import 'package:flutter/material.dart';

class ArtistPage extends StatefulWidget {
  const ArtistPage({
    super.key,
    required this.artistName,
    required this.artistId,
    required this.followerCount,
    this.profileImageUrl,
  });

  final String artistName;
  final int artistId;
  final int followerCount;
  final String? profileImageUrl;

  @override
  State<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
  int _refreshKey = 0;
  late final ArtistFollowNotifier _followNotifier;

  @override
  void initState() {
    super.initState();
    _followNotifier = ArtistFollowNotifier(
      artistId: widget.artistId,
      initialFollowerCount: widget.followerCount,
    )..init();
  }

  @override
  void dispose() {
    _followNotifier.dispose();
    super.dispose();
  }

  Future<void> _onRefresh() async {
    setState(() => _refreshKey++);
    await Future.delayed(AppDimens.animVerySlow);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SecondaryAppBar(title: widget.artistName),
          Expanded(
            child: SafeArea(
              top: false,
              child: RefreshIndicator(
                color: colors.activate,
                onRefresh: _onRefresh,
                child: _buildScrollBody(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScrollBody() {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        children: [
          MainImageSwiper(
            key: ValueKey('swiper_$_refreshKey'),
            artistName: widget.artistName,
            artistId: widget.artistId,
            followNotifier: _followNotifier,
            profileImageUrl: widget.profileImageUrl,
          ),
          ArtistSchedule(
            key: ValueKey('schedule_$_refreshKey'),
            artistId: widget.artistId,
            artistName: widget.artistName,
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
        ],
      ),
    );
  }
}
