import 'dart:ui';

import 'package:flutter/material.dart';

class FestivalPoster extends StatefulWidget {
  const FestivalPoster({super.key, required this.posterName});

  final String posterName;

  @override
  State<FestivalPoster> createState() => _FestivalPosterState();
}

class _FestivalPosterState extends State<FestivalPoster> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 250,
      child: Stack(
        children: [
            Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(widget.posterName),
                  fit: BoxFit.cover,
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 5,
                  sigmaY: 5,
                ),
                child: Container(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
            ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                alignment: Alignment.centerLeft,
                margin: EdgeInsets.all(16),
                height: 200,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    widget.posterName,
                    fit: BoxFit.fill,
                  ),
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(style: TextStyle(fontSize: 30),"랩비트 페스티벌 "),
                  Text(style: TextStyle(fontSize: 20),"날짜: 2023.12.25 "),
                  Text(style: TextStyle(fontSize: 20),"장소: 과천 서울랜드 "),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
