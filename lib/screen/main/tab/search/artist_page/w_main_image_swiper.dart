import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/screen/main/tab/search/artist_page/artist_follow_notifier.dart';
import 'package:feple/screen/main/tab/search/artist_page/artist_swiper_photos_notifier.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_name_like.dart';
import 'package:flutter/material.dart';

class MainImageSwiper extends StatefulWidget {
  const MainImageSwiper({
    super.key,
    required this.artistName,
    required this.artistId,
    required this.followNotifier,
    this.profileImageUrl,
  });

  final String artistName;
  final int artistId;
  final ArtistFollowNotifier followNotifier;
  final String? profileImageUrl;

  @override
  State<MainImageSwiper> createState() => MainImageSwiperState();
}

class MainImageSwiperState extends State<MainImageSwiper> {
  static const double _swiperHeight = 350.0;
  static const double _pageViewHeight = 250.0;
  static const double _photoCardSize = 200.0;
  // 가상 페이지 수를 크게 잡아 양방향 무한 스크롤처럼 보이게 함
  static const int _loopMultiplier = 10000;

  late final ArtistSwiperPhotosNotifier _photosNotifier;

  // 사진 수를 알아야 initialPage를 설정할 수 있으므로 로드 후 생성
  PageController? _pageController;
  int _virtualPage = 0;
  int _currentRealPage = 0;
  // PageController가 없을 때 scale 계산용 기본값
  final ValueNotifier<double> _pageOffset = ValueNotifier(0.0);
  Timer? _timer;
  bool _isUserScrolling = false;
  bool _isAutoScrolling = false;

  @override
  void initState() {
    super.initState();
    _photosNotifier = ArtistSwiperPhotosNotifier(artistId: widget.artistId)..load();
    _photosNotifier.addListener(_onPhotosLoaded);
  }

  void _onPhotosLoaded() {
    if (!_photosNotifier.loaded || !mounted) return;
    if (_photosNotifier.photos.isNotEmpty) {
      final n = _photosNotifier.photos.length;
      // 중간에서 시작해 양방향 스크롤 여유 확보
      _virtualPage = n * (_loopMultiplier ~/ 2);
      _currentRealPage = 0;
      // initialPage를 정확히 설정해 첫 프레임부터 올바른 위치로 렌더링
      final controller = PageController(
        viewportFraction: 0.55,
        initialPage: _virtualPage,
      );
      _pageOffset.value = _virtualPage.toDouble();
      controller.addListener(_onPageScroll);
      setState(() => _pageController = controller);
      _startTimer();
    } else {
      setState(() {});
    }
  }

  void _onPageScroll() {
    final page = _pageController?.page;
    if (page == null) return;
    _pageOffset.value = page;
    if (!_isAutoScrolling) {
      _isUserScrolling = (page - page.roundToDouble()).abs() > 0.01;
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted || _pageController == null || !_pageController!.hasClients ||
          _photosNotifier.photos.isEmpty || _isUserScrolling) {
        return;
      }
      _isAutoScrolling = true;
      // 항상 +1 전진 — 마지막 사진 다음에도 자연스럽게 처음 사진으로 넘어감
      _pageController!.animateToPage(
        _virtualPage + 1,
        duration: AppDimens.animSlow,
        curve: Curves.easeIn,
      ).whenComplete(() {
        if (mounted) _isAutoScrolling = false;
      });
    });
  }

  void _onPageChanged(int newVirtualPage) {
    setState(() {
      _virtualPage = newVirtualPage;
      _currentRealPage = newVirtualPage % _photosNotifier.photos.length;
    });
  }

  void refresh() {
    _timer?.cancel();
    _timer = null;
    _pageController?.removeListener(_onPageScroll);
    _pageController?.dispose();
    setState(() => _pageController = null);
    _photosNotifier.load();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _photosNotifier.removeListener(_onPhotosLoaded);
    _photosNotifier.dispose();
    _pageController?.removeListener(_onPageScroll);
    _pageOffset.dispose();
    _pageController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _swiperHeight,
      child: Stack(
        children: [
          // 블러 배경은 포토카드 스케일 애니메이션과 독립적으로 리페인트되도록 격리
          RepaintBoundary(child: _buildBackground()),
          if (_pageController != null) _buildPhotoPageView(),
          ArtistNameLike(
            artistName: widget.artistName,
            artistId: widget.artistId,
            followNotifier: widget.followNotifier,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoPageView() {
    final n = _photosNotifier.photos.length;
    return SizedBox(
      height: _pageViewHeight,
      child: PageView.builder(
        onPageChanged: _onPageChanged,
        controller: _pageController,
        itemCount: n * _loopMultiplier,
        itemBuilder: (context, virtualIndex) =>
            _buildPhotoItem(virtualIndex, virtualIndex % n),
      ),
    );
  }

  Widget _buildPhotoItem(int virtualIndex, int realIndex) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 30, 0, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ValueListenableBuilder<double>(
            valueListenable: _pageOffset,
            builder: (context, pageOffset, child) {
              // 가상 인덱스 기준으로 scale 계산 — 인접 카드가 자연스럽게 축소됨
              final difference = (pageOffset - virtualIndex).abs();
              final scale = 1 - (difference * 0.2);
              return Transform.scale(
                scale: scale,
                child: _buildPhotoCard(realIndex),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(int realIndex) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
      child: Container(
        height: _photoCardSize,
        width: _photoCardSize,
        decoration: BoxDecoration(
          color: Colors.grey[800],
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 10,
              spreadRadius: 2,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: CachedNetworkImage(
          imageUrl: _photosNotifier.photos[realIndex].url,
          cacheKey: 'artist-photo-${_photosNotifier.photos[realIndex].photoId}',
          fit: BoxFit.cover,
          memCacheWidth: 300,
          fadeInDuration: AppDimens.animXFast,
          fadeOutDuration: AppDimens.animTapFeedback,
          placeholder: (_, __) => const ColoredBox(color: Colors.black26),
          errorWidget: (_, __, ___) => const ColoredBox(
            color: Colors.black26,
            child: Center(
              child: Icon(Icons.broken_image_rounded, color: Colors.white38, size: 36),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (!_photosNotifier.loaded || _photosNotifier.photos.isEmpty) {
      if (widget.profileImageUrl != null) {
        return Hero(
          tag: 'artist_image_${widget.artistId}',
          child: CachedNetworkImage(
            imageUrl: widget.profileImageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            memCacheWidth: 600,
            fadeInDuration: AppDimens.animXFast,
            fadeOutDuration: AppDimens.animTapFeedback,
            placeholder: (_, __) => const ColoredBox(color: Colors.black54),
            errorWidget: (_, __, ___) => const ColoredBox(color: Colors.black54),
          ),
        );
      }
      return Container(color: Colors.black54);
    }
    return AnimatedSwitcher(
      duration: AppDimens.animVerySlow,
      child: Container(
        key: ValueKey(_currentRealPage),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: CachedNetworkImageProvider(
              _photosNotifier.photos[_currentRealPage].url,
              cacheKey: 'artist-photo-${_photosNotifier.photos[_currentRealPage].photoId}',
              // 배경은 블러 처리되므로 600px 이상 불필요 — 포토 카드와 캐시 공유
              maxWidth: 600,
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
            child: Container(color: Colors.black.withValues(alpha: 0.5)),
          ),
        ),
      ),
    );
  }
}
