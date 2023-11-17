import 'package:flutter/material.dart';

class FtvCertificationWidget extends StatefulWidget {
  const FtvCertificationWidget({super.key});

  @override
  State<FtvCertificationWidget> createState() => _FtvCertificationWidgetState();
}

class _FtvCertificationWidgetState extends State<FtvCertificationWidget> {
  List<Map<String, dynamic>> ftv_certification = [
    {
      "id": 1,
      "title": "psy_show",
      "path": "assets/image/ftv_certification/psy_certification.jpg",
    },
    {
      "id": 2,
      "title": "rapbeat",
      "path": "assets/image/ftv_certification/rapbeat_certification.jpg",
    },
    {
      "id": 3,
      "title": "seouljazzftv",
      "path": "assets/image/ftv_certification/seouljazzftv_certification.jpg",
    },
    {
      "id": 4,
      "title": "thecryground",
      "path": "assets/image/ftv_certification/thecryground_certification.jpg",
    },
    {
      "id": 5,
      "title": "waterbomb",
      "path": "assets/image/ftv_certification/waterbomb_certification.jpg",
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      //Todo 사이즈 하드코딩 된거 수정
      color: Colors.grey[900],
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: ftv_certification.length,
        itemBuilder: (BuildContext context, int index) {
          Map<String, dynamic> certification = ftv_certification[index];
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: AssetImage(certification['path']),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      certification['title'],
                    ),
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
