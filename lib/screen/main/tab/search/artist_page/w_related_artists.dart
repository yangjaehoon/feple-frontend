import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_model.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_page.dart';
import 'package:feple/service/artist_service.dart';
import 'package:flutter/material.dart';

class RelatedArtists extends StatefulWidget {
  final int artistId;

  const RelatedArtists({super.key, required this.artistId});

  @override
  State<RelatedArtists> createState() => RelatedArtistsState();
}

class RelatedArtistsState extends State<RelatedArtists> {
  final _artistService = sl<ArtistService>();
  late Future<List<Artist>> _future;

  @override
  void initState() {
    super.initState();
    _future = _fetch();
  }

  Future<List<Artist>> _fetch() =>
      _artistService.fetchRelatedArtists(widget.artistId);

  void refresh() => setState(() { _future = _fetch(); });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Artist>>(
      future: _future,
      builder: (context, snapshot) {
        if (!snapshot.hasData || (snapshot.data?.isEmpty ?? true)) {
          return const SizedBox.shrink();
        }
        if (snapshot.hasError) return const SizedBox.shrink();
        return _buildSection(context, snapshot.data!);
      },
    );
  }

  Widget _buildSection(BuildContext context, List<Artist> artists) {
    final colors = context.appColors;
    return SurfaceCard(
      width: double.infinity,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(colors),
          Divider(height: 1, thickness: 1, color: colors.listDivider),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              itemCount: artists.length,
              itemBuilder: (_, i) => _buildArtistCard(context, artists[i], colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimens.paddingHorizontal,
        vertical: 14,
      ),
      child: Row(
        children: [
          Icon(Icons.people_rounded, color: colors.activate, size: 22),
          const SizedBox(width: 8),
          Text(
            'related_artists'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeXxl,
              color: colors.textTitle,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArtistCard(BuildContext context, Artist artist, AbstractThemeColors colors) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        SlideRoute(
          builder: (_) => ArtistScreen(
            artistId: artist.id,
            artistName: artist.name,
            artistNameEn: artist.nameEn,
            followerCount: artist.followerCount,
            profileImageUrl: artist.profileImageUrl,
          ),
        ),
      ),
      child: Container(
        width: 76,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildAvatar(artist, colors),
            const SizedBox(height: 6),
            Text(
              artist.displayName(context.isEnglish),
              style: TextStyle(
                fontSize: AppDimens.fontSizeXs,
                fontWeight: FontWeight.w600,
                color: colors.textTitle,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            if (artist.genres.isNotEmpty)
              Text(
                artist.genres.first,
                style: TextStyle(
                  fontSize: AppDimens.fontSizeTiny,
                  color: colors.textSecondary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAvatar(Artist artist, AbstractThemeColors colors) {
    final hasImage = artist.profileImageUrl.isNotEmpty;
    return CircleAvatar(
      radius: 30,
      backgroundColor: colors.activate.withValues(alpha: 0.1),
      backgroundImage: hasImage
          ? CachedNetworkImageProvider(artist.profileImageUrl, maxWidth: 120)
          : null,
      child: hasImage
          ? null
          : Icon(Icons.person_rounded, color: colors.activate, size: 28),
    );
  }
}
