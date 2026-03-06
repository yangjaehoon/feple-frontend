import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/screen/main/tab/search/artist_page/w_artist_schedule.dart';
import 'package:fast_app_base/screen/main/tab/search/artist_page/w_main_image_swiper.dart';
import 'package:fast_app_base/screen/main/tab/search/artist_page/w_artist_board.dart';

import 'package:flutter/material.dart';

class ArtistPage extends StatelessWidget {
  const ArtistPage({super.key, required this.artistName, required this.artistId, required this.followerCounter});

  final String artistName;
  final int artistId;
  final int followerCounter;

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
              MainImageSwiper(artistName: artistName, artistId: artistId, followerCount: followerCounter),
              ArtistBoard(artistId: artistId, artistName: artistName),
              ArtistSchedule(artistId: artistId, artistName: artistName),
            ],
          ),
        ),
      ),
    );
  }
}
