import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_dimensions.dart';
import 'package:fast_app_base/common/util/responsive_size.dart';
import 'package:fast_app_base/model/poster_model.dart';
import 'package:fast_app_base/network/dio_client.dart';
import 'package:fast_app_base/screen/main/tab/search/artist_page/f_artist_page.dart';
import 'package:fast_app_base/screen/main/tab/search/concert_information/f_festival_information.dart';
import 'package:fast_app_base/screen/main/tab/search/w_feple_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/user_provider.dart';

class HomeFragment extends StatefulWidget {
  const HomeFragment({Key? key}) : super(key: key);

  @override
  State<HomeFragment> createState() => _HomeFragmentState();
}

class _HomeFragmentState extends State<HomeFragment> {
  late Future<List<_FollowedArtist>> _artistsFuture;
  late Future<List<PosterModel>> _festivalsFuture;
  int? _userId;
  bool _wasVisible = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = context.read<UserProvider>().user;
    final isVisible = TickerMode.of(context);

    if (user != null) {
      if (_userId == null) {
        _userId = user.id;
        _artistsFuture = _fetchArtists(user.id);
        _festivalsFuture = _fetchFestivals(user.id);
      } else if (isVisible && !_wasVisible) {
        _artistsFuture = _fetchArtists(_userId!);
        _festivalsFuture = _fetchFestivals(_userId!);
      }
    }
    _wasVisible = isVisible;
  }

  Future<List<_FollowedArtist>> _fetchArtists(int userId) async {
    final resp = await DioClient.dio.get('/users/$userId/following');
    return (resp.data as List).map((e) => _FollowedArtist.fromJson(e)).toList();
  }

  Future<List<PosterModel>> _fetchFestivals(int userId) async {
    final resp = await DioClient.dio.get('/users/$userId/liked-festivals');
    return (resp.data as List).map((e) => PosterModel.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final colors = context.appColors;

    if (_userId == null) {
      return Container(
        color: colors.backgroundMain,
        child: Center(child: CircularProgressIndicator(color: colors.loadingIndicator)),
      );
    }

    return Container(
      color: colors.backgroundMain,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: rs.h(AppDimens.scrollPaddingTop),
              bottom: rs.h(AppDimens.scrollPaddingBottom),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('팔로우 아티스트', colors),
                _buildArtistsSection(colors),
                const SizedBox(height: 8),
                _buildSectionHeader('좋아요한 페스티벌', colors),
                _buildFestivalsSection(colors),
              ],
            ),
          ),
          const FepleAppBar("Feple"),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 20,
            decoration: BoxDecoration(
              color: colors.sectionBarColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.textTitle,
            ),
          ),
        ],
      ),
    );
  }

  // ── 팔로우 아티스트 ──

  Widget _buildArtistsSection(AbstractThemeColors colors) {
    return FutureBuilder<List<_FollowedArtist>>(
      future: _artistsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 110,
            child: Center(child: CircularProgressIndicator(color: colors.loadingIndicator)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text('팔로우한 아티스트가 없습니다.', style: TextStyle(color: colors.textSecondary)),
          );
        }
        final artists = snapshot.data!;
        return SizedBox(
          height: 110,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ArtistPage(
                      artistId: artist.id,
                      artistName: artist.name,
                      followerCounter: 0,
                    ),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: colors.followRingColor,
                          boxShadow: [
                            BoxShadow(
                              color: colors.cardShadow.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surface),
                          child: CircleAvatar(
                            radius: 32,
                            backgroundColor: colors.backgroundMain,
                            backgroundImage: (artist.profileImageUrl != null && artist.profileImageUrl!.isNotEmpty)
                                ? NetworkImage(artist.profileImageUrl!)
                                : null,
                            child: (artist.profileImageUrl == null || artist.profileImageUrl!.isEmpty)
                                ? Icon(Icons.person_rounded, size: 28, color: colors.textSecondary)
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 64,
                        child: Text(
                          artist.name,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: colors.textTitle),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── 좋아요한 페스티벌 ──

  Widget _buildFestivalsSection(AbstractThemeColors colors) {
    return FutureBuilder<List<PosterModel>>(
      future: _festivalsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SizedBox(
            height: 160,
            child: Center(child: CircularProgressIndicator(color: colors.loadingIndicator)),
          );
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text('좋아요한 페스티벌이 없습니다.', style: TextStyle(color: colors.textSecondary)),
          );
        }
        final festivals = snapshot.data!;
        return SizedBox(
          height: 190,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: festivals.length,
            itemBuilder: (context, index) {
              final festival = festivals[index];
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FestivalInformationFragment(poster: festival),
                  ),
                ),
                child: Container(
                  width: 130,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: colors.cardShadow.withOpacity(0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.network(
                          festival.posterUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: colors.surface,
                            child: Icon(Icons.image_not_supported_rounded, color: colors.textSecondary),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                              ),
                            ),
                            child: Text(
                              festival.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _FollowedArtist {
  final int id;
  final String name;
  final String? profileImageUrl;

  const _FollowedArtist({required this.id, required this.name, this.profileImageUrl});

  factory _FollowedArtist.fromJson(Map<String, dynamic> json) {
    return _FollowedArtist(
      id: json['id'] as int,
      name: json['name'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
    );
  }
}
