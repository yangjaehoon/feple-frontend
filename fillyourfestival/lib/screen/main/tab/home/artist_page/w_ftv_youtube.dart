import 'package:flutter/material.dart';
import 'dto_ftv_youtube.dart';

class FtvYoutube extends StatefulWidget {
  const FtvYoutube({super.key});

  @override
  State<FtvYoutube> createState() => _FtvYoutubeState();
}

class _FtvYoutubeState extends State<FtvYoutube> {

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 400,
      child: FutureBuilder<List<String>>(
        future: fetchMostViewedNewsThumbnail(),
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
                return Image.network(data[index]);
              },
            );
          }
        },
      ),
    );
  }
}
