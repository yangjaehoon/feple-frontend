import 'package:cached_network_image/cached_network_image.dart';
import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/model/festival_artist_item.dart';
import 'package:fast_app_base/network/dio_client.dart';
import 'package:fast_app_base/provider/user_provider.dart';
import 'package:fast_app_base/screen/main/tab/search/artist_page/f_artist_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FestivalArtists extends StatefulWidget {
  final int festivalId;

  const FestivalArtists({super.key, required this.festivalId});

  @override
  State<FestivalArtists> createState() => _FestivalArtistsState();
}

class _FestivalArtistsState extends State<FestivalArtists> {
  List<FestivalArtistItem> _artists = [];
  Set<int> _followedIds = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    try {
      final artistFuture =
          DioClient.dio.get('/festivals/${widget.festivalId}/artists');

      final user = context.read<UserProvider>().user;
      final followFuture = user != null
          ? DioClient.dio.get('/users/${user.id}/following')
          : null;

      final artistRes = await artistFuture;
      final artists =
          (artistRes.data as List).map((e) => FestivalArtistItem.fromJson(e)).toList();

      Set<int> followed = {};
      if (followFuture != null) {
        final followRes = await followFuture;
        followed = (followRes.data as List)
            .map((a) => (a['id'] as num).toInt())
            .toSet();
      }

      // 팔로우한 아티스트를 앞으로 정렬
      artists.sort((a, b) {
        final aF = followed.contains(a.artistId) ? 0 : 1;
        final bF = followed.contains(b.artistId) ? 0 : 1;
        return aF.compareTo(bF);
      });

      if (mounted) {
        setState(() {
          _artists = artists;
          _followedIds = followed;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.10),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.music_note_rounded, color: colors.activate, size: 18),
              const SizedBox(width: 6),
              Text(
                'participating_artists'.tr(),
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_loading)
            _buildPlaceholderRow(colors)
          else if (_artists.isEmpty)
            _buildPlaceholderRow(colors)
          else
            _buildArtistRow(colors),
        ],
      ),
    );
  }
  Widget _buildArtistRow(AbstractThemeColors colors) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _artists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final artist = _artists[index];
          final isFollowed = _followedIds.contains(artist.artistId);
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArtistPage(
                  artistId: artist.artistId,
                  artistName: artist.artistName,
                  followerCounter: 0,
                ),
              ),
            ),
            child: SizedBox(
              width: 64,
              child: Column(
                children: [
                  _CircleImage(
                    imageUrl: artist.profileImageUrl,
                    colors: colors,
                    isFollowed: isFollowed,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    artist.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isFollowed ? AppColors.skyBlue : colors.textTitle,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPlaceholderRow(AbstractThemeColors colors) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 3,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (_, __) => SizedBox(
          width: 64,
          child: Column(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colors.activate.withValues(alpha: 0.08),
                  border: Border.all(
                    color: colors.activate.withValues(alpha: 0.2),
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  Icons.person_rounded,
                  color: colors.activate.withValues(alpha: 0.4),
                  size: 28,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                width: 40,
                height: 10,
                decoration: BoxDecoration(
                  color: colors.activate.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CircleImage extends StatelessWidget {
  final String? imageUrl;
  final AbstractThemeColors colors;
  final bool isFollowed;

  const _CircleImage({
    required this.imageUrl,
    required this.colors,
    required this.isFollowed,
  });

  @override
  Widget build(BuildContext context) {
    final image = Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.activate.withValues(alpha: 0.08),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: (imageUrl != null && imageUrl!.isNotEmpty)
            ? CachedNetworkImage(
                imageUrl: imageUrl!,
                fit: BoxFit.cover,
                errorWidget: (context, url, error) => Icon(
                  Icons.person_rounded,
                  color: colors.activate.withValues(alpha: 0.5),
                  size: 26,
                ),
              )
            : Icon(
                Icons.person_rounded,
                color: colors.activate.withValues(alpha: 0.5),
                size: 26,
              ),
      ),
    );

    if (!isFollowed) return image;

    // 팔로우한 아티스트: 하늘색 테두리 링
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [AppColors.skyBlue, AppColors.skyBlueLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(2.5),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        padding: const EdgeInsets.all(1.5),
        child: ClipOval(
          child: (imageUrl != null && imageUrl!.isNotEmpty)
              ? CachedNetworkImage(
                  imageUrl: imageUrl!,
                  fit: BoxFit.cover,
                  width: 52,
                  height: 52,
                  errorWidget: (context, url, error) => Icon(
                    Icons.person_rounded,
                    color: colors.activate.withValues(alpha: 0.5),
                    size: 26,
                  ),
                )
              : Icon(
                  Icons.person_rounded,
                  color: colors.activate.withValues(alpha: 0.5),
                  size: 26,
                ),
        ),
      ),
    );
  }
}
