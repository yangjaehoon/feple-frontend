import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fast_app_base/model/ftv_youtube_shorts.dart';

class FtvYoutubeShorts extends StatefulWidget {
  const FtvYoutubeShorts({super.key, required this.artistName});

  final String artistName;

  @override
  State<FtvYoutubeShorts> createState() => _FtvYoutubeShortsState();
}

class _FtvYoutubeShortsState extends State<FtvYoutubeShorts> {
  late Future<List<Map<String, String>>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchMostViewedNewsThumbnail(widget.artistName);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 200,
      child: FutureBuilder<List<Map<String, String>>>(
        future: _future,
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
                return Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    height: 90,
                    child: CachedNetworkImage(
                      imageUrl: thumbnailUrl!,
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                    ),
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
