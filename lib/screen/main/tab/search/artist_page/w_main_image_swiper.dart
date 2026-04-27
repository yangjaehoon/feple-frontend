import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/model/artist_photo_response.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_name_like.dart';
import 'package:flutter/material.dart';

class MainImageSwiper extends StatefulWidget {
  const MainImageSwiper({
    super.key,
    required this.artistName,
    required this.artistId,
    required this.followerCount,
    this.profileImageUrl,
  });

  final int followerCount;
  final String artistName;
  final int artistId;
  final String? profileImageUrl;

  @override
  State<MainImageSwiper> createState() => _MainImageSwiperState();
}

class _MainImageSwiperState extends State<MainImageSwiper> {
  List<String> _photoUrls = [];
  bool _loaded = false;

  final PageController _pageController = PageController(viewportFraction: 0.55);
  int _currentPage = 0;
  final ValueNotifier<double> _scroll = ValueNotifier(0.0);
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadPhotos();
    _pageController.addListener(_onPageScroll);
  }

  void _onPageScroll() {
    final p = _pageController.page;
    if (p == null) return;
    _scroll.value = p;
  }

  Future<void> _loadPhotos() async {
    try {
      final res = await DioClient.dio.get('/artists/${widget.artistId}/photos');
      if (res.statusCode == 200) {
        final urls = (res.data as List)
            .map((e) => ArtistPhotoResponse.fromJson(e).url)
            .take(10)
            .toList();
        if (!mounted) return;
        setState(() {
          _photoUrls = urls;
          _loaded = true;
        });
        _startTimer();
      }
    } catch (e) {
      debugPrint('[ImageSwiper] 사진 로드 실패: $e');
      if (mounted) setState(() => _loaded = true);
    }
  }

  void _startTimer() {
    if (_photoUrls.isEmpty) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _timer = Timer.periodic(const Duration(seconds: 2), (_) {
        if (!mounted || !_pageController.hasClients || _photoUrls.isEmpty) return;
        final nextPage = (_currentPage + 1) % _photoUrls.length;
        _pageController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 350),
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
    _pageController.removeListener(_onPageScroll);
    _scroll.dispose();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 350,
      child: Stack(
        children: [
          _buildBackground(),
          if (_photoUrls.isNotEmpty)
            SizedBox(
              height: 250,
              child: PageView.builder(
                onPageChanged: _onPageChanged,
                controller: _pageController,
                itemCount: _photoUrls.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(0, 30, 0, 20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ValueListenableBuilder<double>(
                          valueListenable: _scroll,
                          builder: (context, scroll, child) {
                            final difference = (scroll - index).abs();
                            final scale = 1 - (difference * 0.2);
                            return Transform.scale(
                              scale: scale,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
                                child: Container(
                                  height: 200,
                                  width: 200,
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
                                    imageUrl: _photoUrls[index],
                                    fit: BoxFit.cover,
                                    memCacheWidth: 300,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ArtistNameLike(
            artistName: widget.artistName,
            artistId: widget.artistId,
            initialFollowerCount: widget.followerCount,
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    if (!_loaded || _photoUrls.isEmpty) {
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
      duration: const Duration(milliseconds: 500),
      child: Container(
        key: ValueKey(_currentPage),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: CachedNetworkImageProvider(_photoUrls[_currentPage]),
            fit: BoxFit.cover,
          ),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(color: Colors.black.withValues(alpha: 0.5)),
        ),
      ),
    );
  }
}
