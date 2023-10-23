import 'package:fast_app_base/screen/main/tab/home/artist_page/img_collection/w_img_upload.dart';
import 'package:flutter/material.dart';

import '../../w_fyf_app_bar.dart';

class ImgCollectionWidget extends StatefulWidget {
  const ImgCollectionWidget({super.key, required this.artistName});

  final String artistName;

  @override
  State<ImgCollectionWidget> createState() => _ImgCollectionWidgetState();
}

class _ImgCollectionWidgetState extends State<ImgCollectionWidget> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 10,
      itemBuilder: (context, index) {
        return Container(
          height: 160,
          margin: EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              Container(
                width: 160,
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "사진 이름",
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
                      const Padding(
                        padding: EdgeInsets.only(top: 8.0),
                        child: Text(
                          "사진에 대한 내용 설명, "
                              "이사진은 언제 찍었고,"
                              " 이사진은 어디서 찍었고"
                              "어떠한 모습이 잘담긴 것 같아서 올린다.",
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
