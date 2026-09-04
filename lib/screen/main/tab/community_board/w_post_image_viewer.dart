import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_page_indicator_pill.dart';
import 'package:flutter/material.dart';

/// 게시글 이미지 전체화면 뷰어 — 좌우 스와이프 + 핀치 줌, 배경 탭 시 닫힘.
class PostImageViewer extends StatefulWidget {
  final List<String> images;
  final int initialIndex;

  const PostImageViewer({
    super.key,
    required this.images,
    required this.initialIndex,
  });

  @override
  State<PostImageViewer> createState() => _PostImageViewerState();
}

class _PostImageViewerState extends State<PostImageViewer> {
  late final _pageController = PageController(initialPage: widget.initialIndex);
  late int _currentIndex = widget.initialIndex;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            PageView.builder(
              controller: _pageController,
              itemCount: widget.images.length,
              onPageChanged: (i) => setState(() => _currentIndex = i),
              itemBuilder: (_, i) => Center(
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: CachedNetworkImage(
                    imageUrl: widget.images[i],
                    fadeInDuration: AppDimens.animXFast,
                    fadeOutDuration: AppDimens.animTapFeedback,
                    placeholder: (_, _) => const Center(
                      child: CircularProgressIndicator(
                        color: Colors.white54,
                        strokeWidth: 2,
                      ),
                    ),
                    errorWidget: (_, _, _) => const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white38,
                        size: 56,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            if (widget.images.length > 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 32),
                child: PageIndicatorPill(
                  currentIndex: _currentIndex,
                  total: widget.images.length,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
