import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/screen/main/tab/search/artist_page/image_collection/w_image_upload.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';
import 'package:feple/screen/main/tab/search/artist_page/image_collection/w_image_collection.dart';

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
      backgroundColor: colors.backgroundMain,
      floatingActionButton: FloatingActionButton(
        backgroundColor: colors.activate,
        onPressed: () async {
          final result = await Navigator.push(
            context,
            SlideRoute(
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
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              height: AppDimens.appBarHeight,
              color: colors.appBarColor,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    'photo_collection_title'.tr(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: CustomScrollView(
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
          ),
        ],
      ),
    );
  }
}
