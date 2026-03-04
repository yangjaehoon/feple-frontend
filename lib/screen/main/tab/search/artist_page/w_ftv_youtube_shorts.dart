import 'package:flutter/material.dart';
import 'dto_ftv_youtube_shorts.dart';

class FtvYoutubeShorts extends StatefulWidget {
  const FtvYoutubeShorts({super.key, required this.artistName});

  final String artistName;

  @override
  State<FtvYoutubeShorts> createState() => _FtvYoutubeShortsState();
}

class _FtvYoutubeShortsState extends State<FtvYoutubeShorts> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: FutureBuilder<List<Map<String, String>>>(
        future: fetchMostViewedNewsThumbnail(widget.artistName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Error: ${snapshot.error}');
          } else {
            // 데이터 사용 예제
            final data = snapshot.data!;
            return ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: data.length,
              itemBuilder: (context, index) {
                final thumbnailUrl = data[index]['thumbnailUrl'];
                //final videoTitle = data[index]['videoTitle'];
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 90,
                    child: Image.network(thumbnailUrl!),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
