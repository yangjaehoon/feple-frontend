
import 'package:fast_app_base/model/poster_model.dart';
import 'package:flutter/material.dart';

Widget buildPosterCard(PosterModel poster) {
  return Container(
    height: 160,
    margin: EdgeInsets.only(top: 16, bottom: 16, left: 16),
    child: Row(
      children: [
        Container(
          width: 113,
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(16),
            image: DecorationImage(
              image: NetworkImage(poster.imgUrl),
              //image: NetworkImage('ftv_poster/waterbomb_poster.jpg'),
              fit: BoxFit.cover,
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      poster.name ?? '페스티벌 이름',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    PopupMenuButton(
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          child: Text("리뷰"),
                        ),
                        const PopupMenuItem(
                          child: Text("삭제"),
                        ),
                      ],
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.only(top: 12.0),
                  child: Text(
                    "페스티벌 이름: ${poster.name}\n"
                    //"참여 아티스트: ${poster['artists']}\n"
                        "장소: ${poster.location}\n"
                        "날짜: ${poster.date}",
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}