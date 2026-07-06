import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/model/artist_photo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'artist_photo_notifier.dart';

class PhotoFullscreenViewer extends StatefulWidget {
  final int photoId;
  final ArtistPhotoNotifier notifier;

  const PhotoFullscreenViewer({
    super.key,
    required this.photoId,
    required this.notifier,
  });

  @override
  State<PhotoFullscreenViewer> createState() => _PhotoFullscreenViewerState();
}

class _PhotoFullscreenViewerState extends State<PhotoFullscreenViewer> {
  bool _uiVisible = true;
  final _transformController = TransformationController();

  // 좋아요 상태는 로컬로 복제하지 않고 notifier를 그대로 구독 —
  // toggleLike 실패 시 notifier가 롤백하면 화면도 자동으로 정확한 값을 반영함
  ArtistPhotoResponse? get _photo =>
      widget.notifier.photos.firstWhereOrNull((p) => p.photoId == widget.photoId);

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _toggleUi() => setState(() => _uiVisible = !_uiVisible);

  void _handleLike() => widget.notifier.toggleLike(widget.photoId);

  void _handleDoubleTap(TapDownDetails details) {
    if (_transformController.value != Matrix4.identity()) {
      _transformController.value = Matrix4.identity();
    } else {
      final pos = details.localPosition;
      _transformController.value = Matrix4.identity()
        ..translateByDouble(-pos.dx * 1.5, -pos.dy * 1.5, 0.0, 0.0)
        ..scaleByDouble(2.5, 2.5, 2.5, 1.0);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.notifier,
      builder: (context, _) {
        final photo = _photo;
        if (photo == null) {
          // 보는 도중 다른 화면에서 삭제된 경우 — 다음 프레임에 닫기
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) Navigator.pop(context);
          });
          return const SizedBox.shrink();
        }
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.light,
          child: Scaffold(
            backgroundColor: Colors.black,
            body: Stack(
              children: [
                _buildImageArea(photo),
                if (_uiVisible) ...[
                  _buildTopBar(),
                  _buildBottomInfo(photo),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageArea(ArtistPhotoResponse photo) {
    return GestureDetector(
      onTap: _toggleUi,
      onDoubleTapDown: _handleDoubleTap,
      onDoubleTap: () {},
      child: SizedBox.expand(
        child: InteractiveViewer(
          transformationController: _transformController,
          minScale: 0.5,
          maxScale: 4.0,
          child: CachedNetworkImage(
            imageUrl: photo.url,
            cacheKey: 'artist-photo-${photo.photoId}',
            fit: BoxFit.contain,
            fadeInDuration: AppDimens.animXFast,
            fadeOutDuration: AppDimens.animTapFeedback,
            placeholder: (_, _) => const Center(
              child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
            ),
            errorWidget: (_, _, _) => const Center(
              child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 48),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return SafeArea(
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: IconButton(
            tooltip: 'close'.tr(),
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close_rounded, color: Colors.white, size: 28),
            style: IconButton.styleFrom(
              backgroundColor: Colors.black38,
              shape: const CircleBorder(),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomInfo(ArtistPhotoResponse photo) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black87, Colors.transparent],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
        child: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                photo.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: AppDimens.fontSizeXl,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              _buildUploaderRow(photo),
              const SizedBox(height: 12),
              _buildLikeRow(photo),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploaderRow(ArtistPhotoResponse photo) {
    return Row(
      children: [
        const Icon(Icons.person_rounded, size: 13, color: Colors.white70),
        const SizedBox(width: 4),
        Text(
          photo.uploaderNickname,
          style: const TextStyle(color: Colors.white70, fontSize: AppDimens.fontSizeXs),
        ),
        if (photo.description.isNotEmpty) ...[
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(AppDimens.cardRadius),
            ),
            child: Text(
              photo.description,
              style: const TextStyle(color: Colors.white, fontSize: AppDimens.fontSizeXxs, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildLikeRow(ArtistPhotoResponse photo) {
    return Semantics(
      button: true,
      label: 'like'.tr(),
      child: GestureDetector(
        onTap: _handleLike,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              photo.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: photo.isLiked ? AppColors.hotPink : Colors.white70,
              size: 22,
            ),
            const SizedBox(width: 6),
            Text(
              '${photo.likeCount}',
              style: const TextStyle(color: Colors.white70, fontSize: AppDimens.fontSizeMd, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
