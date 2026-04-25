import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:feple/model/artist_photo_response.dart';
import 'artist_photo_notifier.dart';
import 'w_edit_photo_sheet.dart';

class ImgCollectionWidget extends StatefulWidget {
  const ImgCollectionWidget(
      {super.key, required this.artistId, required this.artistName});

  final int artistId;
  final String artistName;

  @override
  State<ImgCollectionWidget> createState() => ImgCollectionWidgetState();
}

class ImgCollectionWidgetState extends State<ImgCollectionWidget> {
  late final ArtistPhotoNotifier _notifier;

  @override
  void initState() {
    super.initState();
    _notifier = ArtistPhotoNotifier(artistId: widget.artistId);
    _notifier.onError = (key) {
      if (!mounted) return;
      context.showErrorSnackbar(key.tr());
    };
    _notifier.loadPhotos();
  }

  @override
  void dispose() {
    _notifier.dispose();
    super.dispose();
  }

  void refresh() => _notifier.loadPhotos();

  Future<void> _confirmAndDelete(int photoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('photo_delete_title'.tr()),
        content: Text('photo_delete_confirm'.tr()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('cancel'.tr()),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('msg_delete'.tr(),
                style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) _notifier.deletePhoto(photoId);
  }

  void _showEditBottomSheet(ArtistPhotoResponse photo) {
    final colors = context.appColors;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => EditPhotoSheet(
        colors: colors,
        artistId: widget.artistId,
        photo: photo,
        onSave: (newTitle, newDesc) =>
            _notifier.updatePhoto(photo.photoId, newTitle, newDesc),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final currentUserId =
        Provider.of<UserProvider>(context, listen: false).user?.id;

    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, _) {
        if (_notifier.isLoading) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child:
                    CircularProgressIndicator(color: colors.loadingIndicator),
              ),
            ),
          );
        }

        if (_notifier.photos.isEmpty) {
          return SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Column(
                  children: [
                    Icon(Icons.photo_library_outlined,
                        size: 48, color: colors.textSecondary),
                    const SizedBox(height: 12),
                    Text(
                      'photo_no_photos'.tr(),
                      style: TextStyle(
                          color: colors.textSecondary, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverList.builder(
          itemCount: _notifier.photos.length,
          itemBuilder: (context, index) {
            final photo = _notifier.photos[index];
            final isUploader =
                currentUserId != null && photo.uploaderUserId == currentUserId;

            return Padding(
              padding: EdgeInsets.only(
                  bottom: index == _notifier.photos.length - 1 ? 0 : 12.0),
              child: Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: colors.cardShadow.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        GestureDetector(
                          onDoubleTap: () =>
                              _notifier.toggleLike(photo.photoId),
                          child: ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              bottomLeft: Radius.circular(16),
                            ),
                            child: CachedNetworkImage(
                              imageUrl: photo.url,
                              width: 195,
                              height: 195,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                width: 195,
                                height: 195,
                                color: colors.listDivider,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: colors.loadingIndicator,
                                    strokeWidth: 2,
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                width: 195,
                                height: 195,
                                color: colors.listDivider,
                                child: Icon(Icons.broken_image_rounded,
                                    color: colors.textSecondary),
                              ),
                            ),
                          ),
                        ),
                        Positioned(
                          left: 6,
                          bottom: 6,
                          child: GestureDetector(
                            onTap: () => _notifier.toggleLike(photo.photoId),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    photo.isLiked
                                        ? Icons.favorite_rounded
                                        : Icons.favorite_border_rounded,
                                    color: photo.isLiked
                                        ? AppColors.kawaiiPink
                                        : Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${photo.likecount}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    Expanded(
                      child: SizedBox(
                        height: 195,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(14, 12, 4, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Text(
                                      photo.title,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                        color: colors.textTitle,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isUploader)
                                    PopupMenuButton<String>(
                                      padding: EdgeInsets.zero,
                                      icon: Icon(Icons.more_vert_rounded,
                                          color: colors.textSecondary,
                                          size: 20),
                                      onSelected: (value) {
                                        if (value == 'edit') {
                                          _showEditBottomSheet(photo);
                                        } else if (value == 'delete') {
                                          _confirmAndDelete(photo.photoId);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        PopupMenuItem(
                                          value: 'edit',
                                          child: Row(children: [
                                            Icon(Icons.edit_rounded,
                                                size: 16,
                                                color: colors.textSecondary),
                                            const SizedBox(width: 8),
                                            Text('photo_edit_action'.tr()),
                                          ]),
                                        ),
                                        PopupMenuItem(
                                          value: 'delete',
                                          child: Row(children: [
                                            const Icon(Icons.delete_rounded,
                                                size: 16, color: Colors.red),
                                            const SizedBox(width: 8),
                                            Text('msg_delete'.tr(),
                                                style: const TextStyle(
                                                    color: Colors.red)),
                                          ]),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                              if (photo.description.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: colors.activate
                                        .withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    photo.description,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: colors.activate,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
