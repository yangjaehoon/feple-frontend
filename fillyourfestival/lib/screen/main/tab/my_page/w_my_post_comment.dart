import 'package:flutter/material.dart';

class MyPostCommentWidget extends StatefulWidget {
  const MyPostCommentWidget({super.key});

  @override
  State<MyPostCommentWidget> createState() => _MyPostCommentWidgetState();
}

class _MyPostCommentWidgetState extends State<MyPostCommentWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(10, 5, 10, 15),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              //Todo: height, width 하드코딩 부분 수정S
              height: 90,
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[800],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.offline_pin),
                  SizedBox(height: 5,),
                  Text('인증 뱃지'),
                  Text('5'),
                ],
              ),
            ),
            Container(
              //Todo: height, width 하드코딩 부분 수정
              height: 90,
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[800],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.library_books),
                  SizedBox(height: 5,),
                  Text('게시글'),
                  Text('23'),
                ],
              ),
            ),
            Container(
              //Todo: height, width 하드코딩 부분 수정
              height: 90,
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[800],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.mode_comment),
                  SizedBox(height: 5,),
                  Text('댓글'),
                  Text('57'),
                ],
              ),
            ),
            Container(
              //Todo: height, width 하드코딩 부분 수정
              height: 90,
              width: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[800],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border),
                  SizedBox(height: 5,),
                  Text('북마크'),
                  Text('10'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
