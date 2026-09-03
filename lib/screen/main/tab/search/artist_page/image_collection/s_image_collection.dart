import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/screen/main/tab/search/artist_page/image_collection/w_image_upload.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/login_gate.dart';
import 'package:feple/common/util/refresh_coordinator.dart';
import 'package:flutter/material.dart';
import 'package:feple/screen/main/tab/search/artist_page/image_collection/w_image_collection.dart';
import 'package:feple/common/util/forced_refresh.dart';

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
  final _refresh = RefreshCoordinator();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      floatingActionButton: _buildFab(colors),
      appBar: SecondaryAppBar(title: 'photo_collection_title'.tr()),
      body: RefreshScope(
        coordinator: _refresh,
        child: RefreshIndicator(
          color: colors.activate,
          onRefresh: () => withForcedRefresh(_refresh.refreshAll),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.all(16),
                sliver: ImageCollectionWidget(
                  artistName: widget.artistName,
                  artistId: widget.artistId,
                ),
              ),
            ],
          ),
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
        if (!ensureLoggedIn(context)) return;
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
          unawaited(_refresh.refreshAll());
        }
      },
      child: Icon(
        Icons.add_photo_alternate,
        color: Theme.of(context).colorScheme.onPrimary,
      ),
    );
  }
}
