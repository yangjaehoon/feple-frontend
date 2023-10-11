import 'package:flutter/material.dart';
import 'dto_ftv_youtube.dart';

class FtvShorts extends StatefulWidget {
  const FtvShorts({super.key});

  @override
  State<FtvShorts> createState() => _FtvShortsState();
}

class _FtvShortsState extends State<FtvShorts> {

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
              scrollDirection: Axis.horizontal,
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
