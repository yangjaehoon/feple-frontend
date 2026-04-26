import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:flutter/material.dart';

/// CachedNetworkImage 공통 래퍼.
/// placeholder → SkeletonBox, errorWidget → 아이콘 일관 적용
class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final BoxFit fit;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final IconData errorIcon;
  final double errorIconSize;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
    this.borderRadius,
    this.errorIcon = Icons.broken_image_rounded,
    this.errorIconSize = 28,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl;

    Widget child;
    if (url == null || url.isEmpty) {
      child = _buildError(context);
    } else {
      child = CachedNetworkImage(
        imageUrl: url,
        fit: fit,
        width: width,
        height: height,
        placeholder: (context, url) => const SkeletonBox(
          height: double.infinity,
        ),
        errorWidget: (context, url, error) => _buildError(context),
      );
    }

    if (borderRadius != null) {
      return ClipRRect(borderRadius: borderRadius!, child: child);
    }
    return child;
  }

  Widget _buildError(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: Colors.grey.withValues(alpha: 0.12),
      child: Icon(
        errorIcon,
        size: errorIconSize,
        color: Colors.grey.withValues(alpha: 0.45),
      ),
    );
  }
}
