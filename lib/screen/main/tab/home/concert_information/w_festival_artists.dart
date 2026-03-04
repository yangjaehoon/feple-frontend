import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/network/dio_client.dart';
import 'package:fast_app_base/screen/main/tab/home/artist_page/f_artist_page.dart';
import 'package:flutter/material.dart';

class FestivalArtists extends StatefulWidget {
  final int festivalId;

  const FestivalArtists({super.key, required this.festivalId});

  @override
  State<FestivalArtists> createState() => _FestivalArtistsState();
}

class _FestivalArtistsState extends State<FestivalArtists> {
  late Future<List<_ArtistItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetchArtists();
  }

  Future<List<_ArtistItem>> _fetchArtists() async {
    final resp =
        await DioClient.dio.get('/festivals/${widget.festivalId}/artists');
    final list = resp.data as List<dynamic>;
    return list.map((e) => _ArtistItem.fromJson(e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
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
                '참여 아티스트',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textTitle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<_ArtistItem>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildPlaceholderRow(colors);
              }
              if (snapshot.hasError || !snapshot.hasData) {
                return _buildPlaceholderRow(colors);
              }
              final artists = snapshot.data!;
              if (artists.isEmpty) {
                return _buildPlaceholderRow(colors);
              }
              return _buildArtistRow(artists, colors);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildArtistRow(List<_ArtistItem> artists, AbstractThemeColors colors) {
    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: artists.length,
        separatorBuilder: (_, __) => const SizedBox(width: 16),
        itemBuilder: (context, index) {
          final artist = artists[index];
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
                  ),
                  const SizedBox(height: 6),
                  Text(
                    artist.displayName,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: colors.textTitle,
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

  // 아티스트 정보 미등록 시 플레이스홀더 3개
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

  const _CircleImage({required this.imageUrl, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
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
            ? Image.network(
                imageUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Icon(
                  Icons.person_rounded,
                  color: colors.activate.withValues(alpha: 0.5),
                  size: 28,
                ),
              )
            : Icon(
                Icons.person_rounded,
                color: colors.activate.withValues(alpha: 0.5),
                size: 28,
              ),
      ),
    );
  }
}

class _ArtistItem {
  final int artistId;
  final String artistName;
  final String? profileImageUrl;
  final String? stageName;

  _ArtistItem({
    required this.artistId,
    required this.artistName,
    this.profileImageUrl,
    this.stageName,
  });

  String get displayName => stageName?.isNotEmpty == true ? stageName! : artistName;

  factory _ArtistItem.fromJson(Map<String, dynamic> json) {
    return _ArtistItem(
      artistId: json['artistId'] as int,
      artistName: json['artistName'] as String,
      profileImageUrl: json['profileImageUrl'] as String?,
      stageName: json['stageName'] as String?,
    );
  }
}
