import 'package:fast_app_base/screen/main/tab/home/artist_page/w_ftv_calender.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../../../../../config.dart' as AppConfig;
import '../vo/artist_dummy.dart';
import 'img_collection/f_img_collection.dart';

class ArtistNameLike extends StatefulWidget {
  const ArtistNameLike({super.key, required this.artistName, required this.artistId});

  final String artistName;
  final int artistId;

  @override
  State<ArtistNameLike> createState() => _ArtistNameLikeState();
}

class _ArtistNameLikeState extends State<ArtistNameLike> {
  bool isFollowed = false;
  int followCount = 0;
  bool isLoading = false;

  Future<void> toggleFollow(int artistId) async {
    if (isLoading) return;
    setState(() => isLoading = true);

    final baseUrl = AppConfig.baseUrl;
    final url = Uri.parse('$baseUrl/artists/$artistId/follow');

    try {
      final response = isFollowed
          ? await http.delete(url, headers: {
        'Content-Type': 'application/json',
        // 'Authorization': 'Bearer $accessToken',
      })
          : await http.post(url, headers: {
        'Content-Type': 'application/json',
        // 'Authorization': 'Bearer $accessToken',
      });

      if (!mounted) return; // async 후 setState 안전장치(권장) [web:420]

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 204) {
        setState(() {
          if (isFollowed) {
            isFollowed = false;
            if (followCount > 0) followCount--;
          } else {
            isFollowed = true;
            followCount++;
          }
        });
      } else {
        setState(() {}); // 필요하면 에러 상태 변수 추가
      }
    } catch (e) {
      if (!mounted) return; // [web:420]
      // 에러 처리
    } finally {
      if (!mounted) return; // [web:420]
      setState(() => isLoading = false);
    }
  }


  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      bottom: 0,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 12, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  height: 50,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 12.0),
                    child: Text(
                      //Artists[0].name,
                      widget.artistName,
                      style: const TextStyle(
                        fontSize: 36,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const Text(
                  style: TextStyle(fontSize: 20),
                  '145만 ',
                ),
                SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: () {},
                  child: Text('팔로우'),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.lightBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12))),
                ),
              ],
            ),
            SizedBox(
              child: Row(
                children: [
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

