import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:fast_app_base/model/ftv_youtube.dart';

class FtvYoutube extends StatefulWidget {
  const FtvYoutube({super.key, required this.artistName});

  final String artistName;

  @override
  State<FtvYoutube> createState() => _FtvYoutubeState();
}

class _FtvYoutubeState extends State<FtvYoutube> {
  late Future<List<Map<String, String>>> _future;

  @override
  void initState() {
    super.initState();
    _future = fetchMostViewedNewsThumbnail(widget.artistName);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
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
              itemCount: data.length,
              itemBuilder: (context, index) {
                final thumbnailUrl = data[index]['thumbnailUrl'];
                final videoTitle = data[index]['videoTitle'];
                return Row(
                  children: [
                    SizedBox(height: 90, child: CachedNetworkImage(
                      imageUrl: thumbnailUrl!,
                      errorWidget: (context, url, error) => const Icon(Icons.broken_image),
                    )),
                    SizedBox(
                      width: 5,
                    ),
                    Expanded(
                      child: Text(
                        videoTitle!,
                      ),
                    ),
                  ],
                );
              },
            );
          }
        },
      ),
    );
  }
}
