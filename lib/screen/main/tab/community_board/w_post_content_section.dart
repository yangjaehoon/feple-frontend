import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_page_indicator_pill.dart';
import 'package:flutter/material.dart';

class PostContentSection extends StatefulWidget {
  final String content;
  final List<String> imageUrls;
  final void Function(int index)? onImageTap;

  const PostContentSection({
    super.key,
    required this.content,
    this.imageUrls = const [],
    this.onImageTap,
  });

  @override
  State<PostContentSection> createState() => _PostContentSectionState();
}

class _PostContentSectionState extends State<PostContentSection> {
  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final screenWidth = MediaQuery.sizeOf(context).width;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.content,
          style: TextStyle(
            color: colors.textTitle,
            fontSize: AppDimens.fontSizeLg,
          ),
        ),
        if (widget.imageUrls.isNotEmpty) ...[
          const SizedBox(height: 12),
          _buildImages(colors, screenWidth),
        ],
      ],
    );
  }

  Widget _buildImage(AbstractThemeColors colors, double screenWidth, int index) {
    return GestureDetector(
      onTap: widget.onImageTap != null ? () => widget.onImageTap!(index) : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        child: CachedNetworkImage(
          imageUrl: widget.imageUrls[index],
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
    );
  }

  Widget _buildImages(AbstractThemeColors colors, double screenWidth) {
    if (widget.imageUrls.length == 1) {
      return _buildImage(colors, screenWidth, 0);
    }
    return SizedBox(
      height: screenWidth * 0.513,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
            child: PageView.builder(
              controller: _pageController,
              itemCount: widget.imageUrls.length,
              onPageChanged: (i) => setState(() => _currentPage = i),
              itemBuilder: (_, i) => _buildImage(colors, screenWidth, i),
            ),
          ),
          Positioned(
            bottom: 10,
            child: PageIndicatorPill(
              currentIndex: _currentPage,
              total: widget.imageUrls.length,
            ),
          ),
        ],
      ),
    );
  }
}
