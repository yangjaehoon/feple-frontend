import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

class PostContentSection extends StatelessWidget {
  final String content;
  final String? imageUrl;
  final VoidCallback? onImageTap;

  const PostContentSection({
    super.key,
    required this.content,
    this.imageUrl,
    this.onImageTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          content,
          style: TextStyle(
            color: colors.textTitle,
            fontSize: AppDimens.fontSizeLg,
          ),
        ),
        if (imageUrl != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: onImageTap,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              child: CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                memCacheWidth: 800, // 최대 스크린 너비 기준
                fadeInDuration: AppDimens.animXFast,
                fadeOutDuration: AppDimens.animTapFeedback,
                // 기준 390px: 로딩 0.513(200px), 에러 0.308(120px)
                placeholder: (_, _) => Container(
                  height: screenWidth * 0.513,
                  color: colors.listDivider,
                ),
                errorWidget: (_, _, _) => Container(
                  height: screenWidth * 0.308,
                  color: colors.listDivider,
                  child: Center(
                    child: Icon(
                      Icons.broken_image_rounded,
                      color: colors.textSecondary,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
