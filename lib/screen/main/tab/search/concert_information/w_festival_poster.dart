import 'dart:ui';

import 'package:url_launcher/url_launcher.dart';
import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_dimensions.dart';
import 'package:fast_app_base/network/dio_client.dart';
import 'package:fast_app_base/provider/like_notifier.dart';
import 'package:provider/provider.dart';
import 'package:fast_app_base/screen/main/tab/search/concert_information/weather/screens/loading.dart';
import 'package:flutter/material.dart';
import '../../../../../model/poster_model.dart';

class FestivalPoster extends StatefulWidget {
  const FestivalPoster({super.key, required this.poster});

  final PosterModel poster;

  @override
  State<FestivalPoster> createState() => _FestivalPosterState();
}

class _FestivalPosterState extends State<FestivalPoster> {
  bool _liked = false;

  @override
  void initState() {
    super.initState();
    _loadLikeState();
  }

  Future<void> _loadLikeState() async {
    try {
      final resp =
          await DioClient.dio.get('/festivals/${widget.poster.id}/liked');
      if (mounted) setState(() => _liked = resp.data as bool);
    } catch (e) {
      debugPrint('loadLikeState error: $e');
    }
  }

  Future<void> _openKakaoMap() async {
    final lat = widget.poster.latitude;
    final lng = widget.poster.longitude;
    final name = Uri.encodeComponent(widget.poster.location);

    if (lat != null && lng != null) {
      // 카카오맵 앱으로 열기 (앱이 없으면 웹으로 폴백)
      final appUri = Uri.parse('kakaomap://look?p=$lat,$lng');
      final webUri = Uri.parse('https://map.kakao.com/link/map/$name,$lat,$lng');
      if (await canLaunchUrl(appUri)) {
        await launchUrl(appUri);
      } else {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
      }
    } else {
      // 좌표가 없으면 장소명으로 검색
      final webUri = Uri.parse('https://map.kakao.com/link/search/$name');
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _toggleLike() async {
    try {
      final resp =
          await DioClient.dio.post('/festivals/${widget.poster.id}/like');
      if (mounted) {
        setState(() => _liked = resp.data as bool);
        context.read<LikeNotifier>().notifyLikeChanged();
      }
    } catch (e) {
      debugPrint('toggleLike error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    const double appBarHeight = AppDimens.appBarHeight;
    const double posterContentHeight = 180.0;

    return SizedBox(
      // 앱바 높이만큼 위쪽 여백도 포함하여 블러 배경이 전체를 덮도록 함
      height: appBarHeight + posterContentHeight,
      child: Stack(
        children: [
          // 블러 + 하늘색 오버레이 - 전체 영역(앱바 포함)을 덮음
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: ResizeImage(
                    NetworkImage(widget.poster.posterUrl),
                    width: 100,
                  ),
                  fit: BoxFit.cover,
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  color: colors.swiperOverlay.withOpacity(0.5),
                ),
              ),
            ),
          ),
          // 포스터 콘텐츠 - 하단 180px 영역에만 배치
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: posterContentHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  flex: 2,
                  child: Container(
                    alignment: Alignment.centerLeft,
                    margin: const EdgeInsets.all(16),
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: colors.cardShadow.withOpacity(0.2),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Image.network(
                        widget.poster.posterUrl,
                        cacheWidth: 300,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                ),
                Flexible(
                  flex: 3,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.poster.title,
                        softWrap: true,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.calendar_today_rounded,
                                  color: colors.accentColor, size: 16),
                              const SizedBox(width: 6),
                              Text(
                                widget.poster.startDate,
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.white70),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: _openKakaoMap,
                            child: Row(
                              children: [
                                Icon(Icons.location_on_rounded,
                                    color: colors.accentColor, size: 16),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    widget.poster.location,
                                    softWrap: true,
                                    style: const TextStyle(
                                        fontSize: 15,
                                        color: Colors.white70,
                                        decoration: TextDecoration.underline,
                                        decorationColor: Colors.white54),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _toggleLike,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: _liked
                                    ? Colors.pink.withOpacity(0.35)
                                    : Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                _liked
                                    ? Icons.favorite_rounded
                                    : Icons.favorite_border_rounded,
                                color: _liked ? Colors.pink[200] : Colors.white,
                                size: 20,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.calendar_month_outlined,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const Loading(),
                                ),
                              );
                            },
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.wb_cloudy_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _openKakaoMap,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.location_on_rounded,
                                  color: Colors.white, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
