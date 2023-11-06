import 'package:fast_app_base/screen/main/tab/home/artist_page/w_ftv_calender.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../vo/artist_dummy.dart';
import 'img_collection/f_img_collection.dart';

class ArtistNameLike extends StatefulWidget {
  const ArtistNameLike({super.key, required this.artistName});

  final String artistName;

  @override
  State<ArtistNameLike> createState() => _ArtistNameLikeState();
}

class _ArtistNameLikeState extends State<ArtistNameLike> {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      bottom: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 5, 12, 3),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  //artist name
                  Artists[0].name,
                  style: const TextStyle(
                    fontSize: 36,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  //artist chat room
                  onPressed: () {},
                  icon: const Icon(Icons.textsms),
                ),
                IconButton(
                  // artist calender
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const FtvCalender()),
                    );
                  },
                  icon: const Icon(Icons.calendar_month_outlined),
                ),
                IconButton(
                  //artist gallery
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ImgCollection(artistName: widget.artistName)),
                    );
                  },
                  icon: const Icon(Icons.image),
                )
              ],
            ),
            const SizedBox(width: 8.0),
            SizedBox(
              child: Row(
                children: [
                  const Text('좋아요 '),
                  IconButton(
                    icon: const Icon(Icons.heart_broken),
                    onPressed: () {
                      flutterToast();
                    },
                  ),
                  const Text('145만 '),
                  SizedBox(width:8.0),
                  ElevatedButton(
                    onPressed: () {},
                    child: Text('팔로우'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)
                      )
                    ),
                  )
                ],
              ),
            ),
          ],
        ),
      ),
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
