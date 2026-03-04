import 'dart:ui';

import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/network/dio_client.dart';
import 'package:fast_app_base/screen/main/tab/home/concert_information/weather/screens/loading.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../../model/poster_model.dart';
import '../../../../../provider/user_provider.dart';
import 'ftv_map/ftv_map_widget.dart';

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
      final resp = await DioClient.dio.get('/festivals/${widget.poster.id}/liked');
      if (mounted) setState(() => _liked = resp.data as bool);
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    final user = context.read<UserProvider>().user;
    if (user == null) return;
    try {
      final resp = await DioClient.dio.post('/festivals/${widget.poster.id}/like');
      if (mounted) setState(() => _liked = resp.data as bool);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SizedBox(
      height: 180,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: NetworkImage(widget.poster.posterUrl),
                fit: BoxFit.cover,
              ),
            ),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 5,
                sigmaY: 5,
              ),
              child: Container(
                color: colors.swiperOverlay.withOpacity(0.5),
              ),
            ),
          ),
          Row(
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
                    Text(widget.poster.title,
                        softWrap: true,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        )),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.calendar_today_rounded,
                                color: colors.accentColor, size: 16),
                            const SizedBox(width: 6),
                            Text("${widget.poster.startDate}",
                                style: const TextStyle(
                                    fontSize: 15, color: Colors.white70)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.location_on_rounded,
                                color: colors.accentColor, size: 16),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text("${widget.poster.location}",
                                  softWrap: true,
                                  style: const TextStyle(
                                      fontSize: 15, color: Colors.white70)),
                            ),
                          ],
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
                              _liked ? Icons.favorite_rounded : Icons.favorite_border_rounded,
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
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.wb_cloudy_rounded,
                                color: Colors.white, size: 20),
                          ),
                          onTap: () {
                            Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (context) => const Loading()));
                          },
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.location_on_rounded,
                                color: Colors.white, size: 20),
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (context) => Scaffold()),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
