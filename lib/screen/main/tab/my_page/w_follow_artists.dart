import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:flutter/material.dart';

class FollowArtistsWidget extends StatefulWidget {
  const FollowArtistsWidget({super.key});

  @override
  State<FollowArtistsWidget> createState() => _FollowArtistsWidgetState();
}

class _FollowArtistsWidgetState extends State<FollowArtistsWidget> {
  List<Map<String, dynamic>> followArtist = [
    {"id": 1, "name": "ashisland", "path": "assets/image/artist/ashisland.jpg"},
    {"id": 2, "name": "changmo", "path": "assets/image/artist/changmo.jpg"},
    {"id": 3, "name": "hanyohan", "path": "assets/image/artist/hanyohan.jpg"},
    {"id": 4, "name": "kimseungmin", "path": "assets/image/artist/kimseungmin.jpg"},
    {"id": 5, "name": "lellamarz", "path": "assets/image/artist/lellamarz.jpg"},
    {"id": 6, "name": "loco", "path": "assets/image/artist/loco.jpg"},
    {"id": 7, "name": "swings", "path": "assets/image/artist/swings.jpg"},
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Container(
                width: 3, height: 20,
                decoration: BoxDecoration(
                  color: colors.sectionBarColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '팔로우 아티스트 ',
                style: TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800, color: colors.textTitle,
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: followArtist.length,
            itemBuilder: (BuildContext context, int index) {
              final artist = followArtist[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.followRingColor,
                        boxShadow: [
                          BoxShadow(
                            color: colors.cardShadow.withOpacity(0.2),
                            blurRadius: 8, offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surface),
                        child: CircleAvatar(
                          radius: 50,
                          backgroundImage: AssetImage(artist['path']),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 6.0),
                      child: Text(
                        artist['name'],
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textTitle),
                      ),
                    )
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
