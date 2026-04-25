import 'package:feple/common/common.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_schedule.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_main_image_swiper.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_board.dart';

import 'package:flutter/material.dart';

class ArtistPage extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(artistName),
        backgroundColor: colors.appBarColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: colors.backgroundMain,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              MainImageSwiper(
                artistName: artistName,
                artistId: artistId,
                followerCount: followerCounter,
                profileImageUrl: profileImageUrl,
              ),
              ArtistBoard(artistId: artistId, artistName: artistName),
              ArtistSchedule(artistId: artistId, artistName: artistName),
            ],
          ),
        ),
      ),
    );
  }
}
