import 'package:fast_app_base/screen/main/tab/home/concert_information/w_festival_poster.dart';
import 'package:fast_app_base/screen/main/tab/home/w_fyf_app_bar.dart';
import 'package:flutter/material.dart';

class FestivalInformationFragment extends StatelessWidget {
  const FestivalInformationFragment({
    Key? key, required this.posterName
  }) : super(key: key);

  final String posterName;
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: 60,
              bottom: 50,
            ), // 상단바 부분만큼 띄워줌(stack이여서),
            child: Column(
              children: [
                FestivalPoster(posterName: posterName),
                Placeholder(),
              ],
            ),
          ),
          FyfAppBar("페스티벌 상세 페이지"),
        ],
      ),
    );
  }
}