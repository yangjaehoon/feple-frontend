import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
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
      floatingActionButton: _buildFab(colors),
      appBar: SecondaryAppBar(title: 'photo_collection_title'.tr()),
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

  Widget _buildFab(AbstractThemeColors colors) {
    return FloatingActionButton(
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
    );
  }

}
