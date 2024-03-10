import 'package:fast_app_base/screen/main/tab/home/artist_page/w_ftv_youtube.dart';
import 'package:fast_app_base/screen/main/tab/home/artist_page/w_main_image_swiper.dart';

import 'package:flutter/material.dart';

class ArtistPage extends StatefulWidget {
  const ArtistPage({super.key, required this.artistName});

  final String artistName;

  @override
  State<ArtistPage> createState() => _ArtistPageState();
}

class _ArtistPageState extends State<ArtistPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              MainImageSwiper(artistName: widget.artistName),
              FtvYoutube(artistName: widget.artistName),
            ],
          ),
        ),
      ),
    );
  }
}
