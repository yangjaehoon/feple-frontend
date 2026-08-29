import 'package:card_swiper/card_swiper.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/refresh_coordinator.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/screen/main/tab/search/artist_page/artist_follow_notifier.dart';
import 'package:feple/screen/main/tab/search/artist_page/artist_swiper_photos_notifier.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_follow_header.dart';
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

class MainImageSwiperState extends State<MainImageSwiper>
    with RefreshableSection<MainImageSwiper> {
  // 무한 루프·자동재생·인접 카드 축소는 card_swiper(Swiper)가 담당한다.
  // (예전엔 PageController를 _loopMultiplier(10000)배 가상 페이지로 부풀리고
  //  Timer.periodic + _pageOffset ValueNotifier로 직접 구현했다.)
  static const int _autoplayDelayMs = 3000;
  static const double _adjacentCardScale = 0.8;
  static const double _viewportFraction = 0.55;

  // 화면 폭에 비례하는 크기(기준 390px) — 다른 화면 카드들과 동일한 관례.
  double get _swiperHeight => ResponsiveSize(context).w(350);
  double get _pageViewHeight => ResponsiveSize(context).w(250);
  double get _photoCardSize => ResponsiveSize(context).w(200);

  late final ArtistSwiperPhotosNotifier _photosNotifier;
  // 블러 배경이 따라갈 현재 사진 인덱스
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _photosNotifier = ArtistSwiperPhotosNotifier(artistId: widget.artistId)..load();
    _photosNotifier.addListener(_onPhotosChanged);
  }

  void _onPhotosChanged() {
    if (!mounted) return;
    if (_currentPhotoIndex >= _photosNotifier.photos.length) {
      _currentPhotoIndex = 0;
    }
    setState(() {});
  }

  @override
  Future<void> refreshSection() => refresh();

  Future<void> refresh() => _photosNotifier.load();

  @override
  void dispose() {
    _photosNotifier.removeListener(_onPhotosChanged);
    _photosNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasPhotos = _photosNotifier.loaded && _photosNotifier.photos.isNotEmpty;
    return SizedBox(
      height: _swiperHeight,
      child: Stack(
        children: [
          // 블러 배경은 포토카드 스케일 애니메이션과 독립적으로 리페인트되도록 격리
          RepaintBoundary(child: _buildBackground()),
          if (hasPhotos) _buildPhotoSwiper(),
          ArtistFollowHeader(
            artistName: widget.artistName,
            artistId: widget.artistId,
            followNotifier: widget.followNotifier,
          ),
        ],
      ),
    );
  }

  Widget _buildPhotoSwiper() {
    final photos = _photosNotifier.photos;
    final canLoop = photos.length > 1;
    // 무한 루프를 위해 itemCount를 부풀리므로(내부적으로) 스크린리더가
    // "수만 개 중 n번째"로 안내하는 것을 막기 위해 시맨틱스에서 제외.
    // 자동 재생되는 장식용 캐러셀이며, 동일 사진은 접근 가능한 다른 화면에서도 노출됨.
    return ExcludeSemantics(
      child: SizedBox(
        height: _pageViewHeight,
        child: Swiper(
          itemCount: photos.length,
          loop: canLoop,
          autoplay: canLoop,
          autoplayDelay: _autoplayDelayMs,
          autoplayDisableOnInteraction: true,
          duration: AppDimens.animSlow.inMilliseconds,
          curve: Curves.easeIn,
          viewportFraction: _viewportFraction,
          scale: _adjacentCardScale,
          onIndexChanged: (index) {
            if (mounted) setState(() => _currentPhotoIndex = index);
          },
          itemBuilder: (context, index) => _buildPhotoItem(index),
        ),
      ),
    );
  }

  Widget _buildPhotoItem(int index) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 30, 0, 20),
      child: Center(child: _buildPhotoCard(index)),
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
          imageUrl: _photosNotifier.photos[index].url,
          cacheKey: 'artist-photo-${_photosNotifier.photos[index].photoId}',
          fit: BoxFit.cover,
          memCacheWidth: 300,
          fadeInDuration: AppDimens.animXFast,
          fadeOutDuration: AppDimens.animTapFeedback,
          placeholder: (_, _) => const ColoredBox(color: Colors.black26),
          errorWidget: (_, _, _) => const ColoredBox(
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
            placeholder: (_, _) => const ColoredBox(color: Colors.black54),
            errorWidget: (_, _, _) => const ColoredBox(color: Colors.black54),
          ),
        );
      }
      return Container(color: Colors.black54);
    }
    final index = _currentPhotoIndex.clamp(0, _photosNotifier.photos.length - 1);
    return AnimatedSwitcher(
      duration: AppDimens.animVerySlow,
      child: Container(
        key: ValueKey(index),
        decoration: BoxDecoration(
          image: DecorationImage(
            image: CachedNetworkImageProvider(
              _photosNotifier.photos[index].url,
              cacheKey: 'artist-photo-${_photosNotifier.photos[index].photoId}',
              // 의도적으로 초저해상도 캐시 — 전체 너비로 늘려지면 자연스럽게 블러처럼 보임, BackdropFilter 없이 동일 효과
              maxWidth: 20,
            ),
            fit: BoxFit.cover,
          ),
        ),
        child: Container(color: Colors.black.withValues(alpha: 0.5)),
      ),
    );
  }
}
