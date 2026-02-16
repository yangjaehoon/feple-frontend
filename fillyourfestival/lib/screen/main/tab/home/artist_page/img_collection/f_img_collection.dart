import 'package:fast_app_base/screen/main/tab/home/artist_page/img_collection/w_img_upload.dart';
import 'package:flutter/material.dart';
import 'package:fast_app_base/screen/main/tab/home/artist_page/img_collection/w_img_collection_widget.dart';
import '../../w_fyf_app_bar.dart';

class ImgCollection extends StatefulWidget {
  const ImgCollection(
      {super.key, required this.artistName, required this.artistId});

  final String artistName;
  final int artistId;

  @override
  State<ImgCollection> createState() => _ImgCollectionState();
}

class _ImgCollectionState extends State<ImgCollection> {

  final GlobalKey<ImgCollectionWidgetState> _imgCollectionKey = GlobalKey<ImgCollectionWidgetState>();

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
            ),
            child: Column(
              children: [
                ImgCollectionWidget(
                  key: _imgCollectionKey,
                  artistName: widget.artistName,
                  artistId: widget.artistId,
                ),
              ],
            ),
          ),
          const FyfAppBar("사진 모아보기"),
          Positioned(
            bottom: 40,
            right: 10,
            child: FloatingActionButton(
              child: const Icon(Icons.add_photo_alternate),
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ImgUpload(
                      artistName: widget.artistName,
                      artistId: widget.artistId,
                    ),
                  ),
                );
                if (result == true) {
                  _imgCollectionKey.currentState?.refresh();
                }

              },
            ),
          ),
        ],
      ),
    );
  }
}
