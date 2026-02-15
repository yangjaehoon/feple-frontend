import 'package:fast_app_base/screen/main/tab/home/artist_page/w_ftv_calender.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import '../../../../../api/artist_follow_api.dart';
import '../../../../../api/follow_response.dart';
import '../../../../../config.dart' as AppConfig;
import '../vo/artist_dummy.dart';
import 'img_collection/f_img_collection.dart';

class ArtistNameLike extends StatefulWidget {
  const ArtistNameLike({
    super.key,
    required this.artistName,
    required this.artistId,
    this.initialFollowerCount,
  });

  final String artistName;
  final int artistId;

  final int? initialFollowerCount;

  @override
  State<ArtistNameLike> createState() => _ArtistNameLikeState();
}

class _ArtistNameLikeState extends State<ArtistNameLike> {

  final _followApi = ArtistFollowApi();

  bool isFollowed = false;
  int followCount = 0;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    followCount = widget.initialFollowerCount ?? 0;
    _initFollowState();
  }

  Future<void> _initFollowState() async {
    try {
      final status = await _followApi.getFollowStatus(widget.artistId);

      if (!mounted) return;
      setState(() {
        isFollowed = status.followed;
        followCount = status.followerCount;
      });
    } catch (e) {
    }
  }


  Future<void> toggleFollow() async {
    if (isLoading) return;
    setState(() => isLoading = true);
    try {
      final FollowResponse res = isFollowed
          ? await _followApi.unfollow(widget.artistId)
          : await _followApi.follow(widget.artistId);

      if (!mounted) return;
      setState(() {
        isFollowed = res.followed;
        followCount = res.followerCount;
      });

      Fluttertoast.showToast(
        msg: isFollowed ? '팔로우 완료' : '언팔로우 완료',
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      if (!mounted) return;
      Fluttertoast.showToast(
        msg: '팔로우 처리 실패: $e',
        gravity: ToastGravity.BOTTOM,
      );
    } finally {
      if (!mounted) return;
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
                Text(
                  '$followCount',
                  style: const TextStyle(fontSize: 20, color: Colors.white),
                ),
                const SizedBox(width: 8.0),
                SizedBox(width: 8.0),
                ElevatedButton(
                  onPressed: isLoading ? null : toggleFollow,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isFollowed ? Colors.grey : Colors.lightBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(isFollowed ? '팔로잉' : '팔로우'),
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
                                ImgCollection(artistName: widget.artistName)
                          ),
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

