import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/model/artist_photo_response.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class PhotoFullscreenViewer extends StatefulWidget {
  final ArtistPhotoResponse photo;
  final VoidCallback onLike;

  const PhotoFullscreenViewer({
    super.key,
    required this.photo,
    required this.onLike,
  });

  @override
  State<PhotoFullscreenViewer> createState() => _PhotoFullscreenViewerState();
}

class _PhotoFullscreenViewerState extends State<PhotoFullscreenViewer> {
  bool _uiVisible = true;
  final _transformController = TransformationController();

  @override
  void dispose() {
    _transformController.dispose();
    super.dispose();
  }

  void _toggleUi() => setState(() => _uiVisible = !_uiVisible);

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
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            _buildImageArea(),
            if (_uiVisible) ...[
              _buildTopBar(),
              _buildBottomInfo(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageArea() {
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
            imageUrl: widget.photo.url,
            cacheKey: 'artist-photo-${widget.photo.photoId}',
            fit: BoxFit.contain,
            placeholder: (_, __) => const Center(
              child: CircularProgressIndicator(color: Colors.white54, strokeWidth: 2),
            ),
            errorWidget: (_, __, ___) => const Center(
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

  Widget _buildBottomInfo() {
    final photo = widget.photo;
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
              Row(
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
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: widget.onLike,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      photo.isLiked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                      color: photo.isLiked ? const Color(0xFFFF6B8A) : Colors.white70,
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
            ],
          ),
        ),
      ),
    );
  }
}
