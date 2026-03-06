import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:fast_app_base/screen/main/tab/search/artist_page/img_collection/w_img_upload.dart';
import 'package:flutter/material.dart';
import 'package:fast_app_base/screen/main/tab/search/artist_page/img_collection/w_img_collection_widget.dart';

class ImgCollection extends StatefulWidget {
  const ImgCollection(
      {super.key, required this.artistName, required this.artistId});

  final String artistName;
  final int artistId;

  @override
  State<ImgCollection> createState() => _ImgCollectionState();
}

class _ImgCollectionState extends State<ImgCollection> {
  final GlobalKey<ImgCollectionWidgetState> _imgCollectionKey =
      GlobalKey<ImgCollectionWidgetState>();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('사진 모아보기'),
        backgroundColor: colors.appBarColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: colors.backgroundMain,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 60),
        child: FloatingActionButton(
          backgroundColor: colors.activate,
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
          child: const Icon(Icons.add_photo_alternate, color: Colors.white),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: ImgCollectionWidget(
              key: _imgCollectionKey,
              artistName: widget.artistName,
              artistId: widget.artistId,
            ),
          ),
        ],
      ),
    );
  }
}
