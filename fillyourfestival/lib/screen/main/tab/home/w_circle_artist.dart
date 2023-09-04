import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/screen/main/tab/home/vo/artist_dummy.dart';
import 'package:fast_app_base/screen/main/tab/home/vo/vo_artist.dart';
import 'package:flutter/material.dart';

import 'artist_page/f_artist_page.dart';

class CircleArtistWidget extends StatelessWidget {
  const CircleArtistWidget({super.key});

//...Artists.map((e) => CircleArtistWidget(e)).toList(),
  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: EdgeInsets.all(20),
      shrinkWrap: true,
      physics: NeverScrollableScrollPhysics(),
      itemCount: Artists.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3, // 한 줄에 3개의 이미지
        mainAxisSpacing: 10,
        crossAxisSpacing: 5,
        //childAspectRatio: 0.66
      ),
      // 전체 이미지 개수
      itemBuilder: (BuildContext context, int index) {
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ArtistPage()),
            );
            print(Artists[index].name);
          },
          child: Column(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20.0),
                  child: Image.asset(
                    Artists[index].faceImagePath,
                    //height: 110,// 이미지 경로
                    //width:110,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(Artists[index].name),
            ],
          ),
        );
      },
    );
  }
}
