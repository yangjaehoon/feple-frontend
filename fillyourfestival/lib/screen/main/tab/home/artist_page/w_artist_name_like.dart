import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:ui';
import '../vo/artist_dummy.dart';

class ArtistNameLike extends StatefulWidget {
  const ArtistNameLike({super.key});

  @override
  State<ArtistNameLike> createState() => _ArtistNameLikeState();
}

class _ArtistNameLikeState extends State<ArtistNameLike> {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        Row(children: [
          Text(
            Artists[1].name,
            style: const TextStyle(
              fontSize: 36,
              color: Colors.white,
            ),
          ),
        ]),
        const SizedBox(width: 8.0),
        Row(
          children: [
            const Text('좋아요 '),
            const Text('145만 '),
            IconButton(
              icon: const Icon(Icons.heart_broken),
              onPressed: () {
                flutterToast();
              },
            ),
          ],
        ),
      ],
    );
  }
}

void flutterToast() {
  Fluttertoast.showToast(
    msg: 'ㅇㅇ아티스트를 좋아하는군요',
    gravity: ToastGravity.BOTTOM,
    backgroundColor: Colors.red,
    fontSize: 20,
    textColor: Colors.white,
    toastLength: Toast.LENGTH_LONG,
  );
}
