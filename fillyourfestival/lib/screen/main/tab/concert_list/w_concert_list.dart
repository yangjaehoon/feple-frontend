import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ConcertListWidget extends StatefulWidget {
  const ConcertListWidget({Key? key}) : super(key: key);

  @override
  State<ConcertListWidget> createState() => _ConcertListWidgetState();
}

class _ConcertListWidgetState extends State<ConcertListWidget> {
  final CollectionReference ftvPosterCollection =
      FirebaseFirestore.instance.collection('poster');

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: ftvPosterCollection.get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          List<DocumentSnapshot> posters = snapshot.data!.docs;

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: posters.length,
            itemBuilder: (context, index) {
              final poster = posters[index];
              final storageRef = FirebaseStorage.instance.ref();
              final pathReference = storageRef.child(poster['imgUrl']);

              return FutureBuilder(
                future: pathReference.getDownloadURL(),
                builder: (context, urlSnapshot) {
                  if (urlSnapshot.connectionState == ConnectionState.done) {
                    if (urlSnapshot.hasError) {
                      return Center(
                        child: Text(
                            'Error getting image URL: ${urlSnapshot.error}'),
                      );
                    }
                    // 이미지 다운로드 URL을 통해 이미지를 로드하여 표시
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
                                image:
                                    NetworkImage(urlSnapshot.data.toString()),
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
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        poster['name'] ?? '페스티벌 이름',
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
                                    child: Text("페스티벌 이름: ${poster['name']}\n"
                                        //"참여 아티스트: ${poster['artists']}\n"
                                        "장소: ${poster['location']}\n"
                                        "날짜: ${poster['date']}",
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
                  return Center(
                    child: CircularProgressIndicator(),
                  );
                },
              );
            },
          );
        }
        return Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}
