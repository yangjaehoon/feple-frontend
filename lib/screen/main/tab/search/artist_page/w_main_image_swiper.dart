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
  State<MainImageSwiper> createState() => _MainImageSwiperState();
}

class _MainImageSwiperState extends State<MainImageSwiper> {
  static const double _swiperHeight = 350.0;
  static const double _pageViewHeight = 250.0;
  static const double _photoCardSize = 200.0;

  late final ArtistSwiperPhotosNotifier _photosNotifier;

  final PageController _pageController = PageController(viewportFraction: 0.55);
  int _currentPage = 0;
  final ValueNotifier<double> _pageOffset = ValueNotifier(0.0);
  Timer? _timer;
  bool _isUserScrolling = false;

  @override
  void initState() {
    super.initState();
    _photosNotifier = ArtistSwiperPhotosNotifier(artistId: widget.artistId)..load();
    _photosNotifier.addListener(_onPhotosLoaded);
    _pageController.addListener(_onPageScroll);
  }

  void _onPhotosLoaded() {
    if (_photosNotifier.loaded && mounted) {
      setState(() {});
      if (_photosNotifier.photoUrls.isNotEmpty) _startTimer();
    }
  }

  void _onPageScroll() {
    final page = _pageController.page;
    if (page == null) return;
    _pageOffset.value = page;
    _isUserScrolling = (page - page.roundToDouble()).abs() > 0.01;
  }

  void _startTimer() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _timer = Timer.periodic(const Duration(seconds: 3), (_) {
        if (!mounted || !_pageController.hasClients || _photosNotifier.photoUrls.isEmpty || _isUserScrolling) return;
        final nextPage = (_currentPage + 1) % _photosNotifier.photoUrls.length;
        _pageController.animateToPage(
          nextPage,
          duration: AppDimens.animSlow,
          curve: Curves.easeIn,
        );
      });
    });
  }

  void _onPageChanged(int newPage) {
    setState(() => _currentPage = newPage);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _photosNotifier.removeListener(_onPhotosLoaded);
    _photosNotifier.dispose();
    _pageController.removeListener(_onPageScroll);
    _pageOffset.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _swiperHeight,
      child: Stack(
        children: [
          _buildBackground(),
          if (_photosNotifier.photoUrls.isNotEmpty) _buildPhotoPageView(),
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
    return SizedBox(
      height: _pageViewHeight,
      child: PageView.builder(
        onPageChanged: _onPageChanged,
        controller: _pageController,
        itemCount: _photosNotifier.photoUrls.length,
        itemBuilder: (context, index) => _buildPhotoItem(index),
      ),
    );
  }

  Widget _buildPhotoItem(int index) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 30, 0, 20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ValueListenableBuilder<double>(
            valueListenable: _pageOffset,
            builder: (context, pageOffset, child) {
              final difference = (pageOffset - index).abs();
              final scale = 1 - (difference * 0.2);
              return Transform.scale(
                scale: scale,
                child: _buildPhotoCard(index),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoCard(int index) {
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
          imageUrl: _photosNotifier.photoUrls[index],
          fit: BoxFit.cover,
          memCacheWidth: 300,
        ),
      ),
    );
  }

  Widget _buildBackground() {
    if (!_photosNotifier.loaded || _photosNotifier.photoUrls.isEmpty) {
      if (widget.profileImageUrl != null) {
        return Hero(
          tag: 'artist_image_${widget.artistId}',
          child: CachedNetworkImage(
            imageUrl: widget.profileImageUrl!,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            memCacheWidth: 600,
          ),
        );
      }
      return Container(color: Colors.black54);
    }
    return AnimatedSwitcher(
      duration: AppDimens.animVerySlow,
      child: Container(
        key: ValueKey(_currentPage),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: CachedNetworkImageProvider(_photosNotifier.photoUrls[_currentPage]),
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
