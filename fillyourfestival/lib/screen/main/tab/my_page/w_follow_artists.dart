import 'package:flutter/material.dart';

class FollowArtistsWidget extends StatefulWidget {
  const FollowArtistsWidget({super.key});

  @override
  State<FollowArtistsWidget> createState() => _FollowArtistsWidgetState();
}

class _FollowArtistsWidgetState extends State<FollowArtistsWidget> {
  List<Map<String, dynamic>> follow_artist = [
    {
      "id": 1,
      "name": "ashisland",
      "path": "assets/image/artist/ashisland.jpg",
    },
    {
      "id": 2,
      "name": "changmo",
      "path": "assets/image/artist/changmo.jpg",
    },
    {
      "id": 3,
      "name": "hanyohan",
      "path": "assets/image/artist/hanyohan.jpg",
    },
    {
      "id": 4,
      "name": "kimseungmin",
      "path": "assets/image/artist/kimseungmin.jpg",
    },
    {
      "id": 5,
      "name": "lellamarz",
      "path": "assets/image/artist/lellamarz.jpg",
    },
    {
      "id": 6,
      "name": "loco",
      "path": "assets/image/artist/loco.jpg",
    },
    {
      "id": 7,
      "name": "swings",
      "path": "assets/image/artist/swings.jpg",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      //Todo 사이즈 하드코딩 된거 수정
      color: Colors.grey[900],
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: follow_artist.length,
        itemBuilder: (BuildContext context, int index) {
          Map<String, dynamic> artist = follow_artist[index];
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: AssetImage(artist['path']),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      artist['name'],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
