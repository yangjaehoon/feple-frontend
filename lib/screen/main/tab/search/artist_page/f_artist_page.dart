import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/screen/main/tab/search/artist_page/w_ftv_youtube.dart';
// import 'package:fast_app_base/screen/main/tab/search/artist_page/w_ftv_youtube_shorts.dart';
import 'package:fast_app_base/screen/main/tab/search/artist_page/w_main_image_swiper.dart';
import 'package:fast_app_base/screen/main/tab/search/artist_page/w_artist_board.dart';

import 'package:flutter/material.dart';

class ArtistPage extends StatefulWidget {
  const ArtistPage({super.key, required this.artistName, required this.artistId, required this.followerCounter});

  final String artistName;
  final int artistId;
  final int followerCounter;


  @override
  State<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              MainImageSwiper(artistName: widget.artistName, artistId: widget.artistId, followerCount: widget.followerCounter),
              // FtvYoutubeShorts(artistName: widget.artistName),
              ArtistBoard(artistId: widget.artistId, artistName: widget.artistName),
              FtvYoutube(artistName: widget.artistName),
            ],
          ),
        ),
      ),
    );
  }
}
