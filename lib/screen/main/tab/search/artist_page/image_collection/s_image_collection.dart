import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/screen/main/tab/search/artist_page/image_collection/w_image_upload.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';
import 'package:feple/screen/main/tab/search/artist_page/image_collection/w_image_collection.dart';

class ImageCollectionScreen extends StatefulWidget {
  const ImageCollectionScreen({
    super.key,
    required this.artistName,
    required this.artistId,
  });

  final String artistName;
  final int artistId;

  @override
  State<ImageCollectionScreen> createState() => _ImageCollectionScreenState();
}

class _ImageCollectionScreenState extends State<ImageCollectionScreen> {
  final GlobalKey<ImageCollectionWidgetState> _imgCollectionKey =
      GlobalKey<ImageCollectionWidgetState>();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      floatingActionButton: _buildFab(colors),
      appBar: SecondaryAppBar(title: 'photo_collection_title'.tr()),
      body: RefreshIndicator(
        color: colors.activate,
        onRefresh: () =>
            _imgCollectionKey.currentState?.refresh() ?? Future.value(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: ImageCollectionWidget(
                key: _imgCollectionKey,
                artistName: widget.artistName,
                artistId: widget.artistId,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFab(AbstractThemeColors colors) {
    return FloatingActionButton(
      heroTag: null,
      tooltip: 'photo_add'.tr(),
      backgroundColor: colors.activate,
      onPressed: () async {
        final result = await Navigator.push(
          context,
          SlideRoute(
            builder: (context) => ImageUpload(
              artistName: widget.artistName,
              artistId: widget.artistId,
            ),
          ),
        );
        if (result == true) {
          _imgCollectionKey.currentState?.refresh();
        }
      },
      child: Icon(
        Icons.add_photo_alternate,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}
