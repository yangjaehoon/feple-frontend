import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/w_artist_suggestion_sheet.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../model/artist_model.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/injection.dart';
import '../../../../service/artist_service.dart';
import '../../../../service/artist_follow_service.dart';
import 'artist_page/f_artist_page.dart';

class CircleArtistWidget extends StatefulWidget {
  const CircleArtistWidget({super.key});

  @override
  State<CircleArtistWidget> createState() => _CircleArtistWidgetState();
}

class _CircleArtistWidgetState extends State<CircleArtistWidget> {
  late Future<List<Artist>> _artistsFuture;
  String? _selectedGenre;
  Set<int> _followedIds = {};

  @override
  void initState() {
    super.initState();
    _artistsFuture = sl<ArtistService>().fetchArtists();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFollowedIds());
  }

  Future<void> _loadFollowedIds() async {
    if (!mounted) return;
    final userId = context.read<UserProvider>().currentUserId;
    if (userId == null) return;
    try {
      final ids = await sl<ArtistFollowService>().getFollowingIds(userId);
      if (mounted) setState(() => _followedIds = ids);
    } catch (e) {
      debugPrint('[CircleArtist] follow ids load failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return FutureBuilder<List<Artist>>(
      future: _artistsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildSkeleton();
        }
        if (snapshot.hasError) {
          return ErrorState(
            message: 'err_fetch_data'.tr(),
            onRetry: () => setState(() {
              _artistsFuture = sl<ArtistService>().fetchArtists();
            }),
          );
        }
        final allArtists = snapshot.data ?? [];
        final genres = allArtists.map((a) => a.genre).toSet().toList()..sort();
        final artists = _selectedGenre == null
            ? allArtists
            : allArtists.where((a) => a.genre == _selectedGenre).toList();
        return _buildContent(artists, genres, colors);
      },
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: SkeletonBox(width: 72, height: 20),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: List.generate(
                4,
                (_) => const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: SkeletonBox(
                    width: 60,
                    height: 36,
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _buildSkeletonGrid(),
        ],
      ),
    );
  }

  Widget _buildSkeletonGrid() {
    return GridView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 6,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.75,
      ),
      itemBuilder: (_, __) => Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: const [
          AspectRatio(
            aspectRatio: 1.0,
            child: SkeletonBox(
              height: double.infinity,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          SizedBox(height: 8),
          SkeletonBox(width: 60, height: 13),
        ],
      ),
    );
  }

  Widget _buildContent(
      List<Artist> artists, List<String> genres, AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'artist'.tr(),
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: colors.textTitle,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                _GenreChip(
                  label: 'filter_all'.tr(),
                  selected: _selectedGenre == null,
                  onTap: () => setState(() => _selectedGenre = null),
                ),
                ...genres.map((genre) => _GenreChip(
                      label: _genreLabel(genre),
                      selected: _selectedGenre == genre,
                      onTap: () => setState(() => _selectedGenre = genre),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: artists.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 12,
              childAspectRatio: 0.75,
            ),
            itemBuilder: (context, index) {
              final artist = artists[index];
              return AnimatedListItem(
                index: index,
                child: TapScale(
                  onTap: () => Navigator.push(
                    context,
                    SlideRoute(
                      builder: (context) => ArtistPage(
                        artistName: artist.name,
                        artistId: artist.id,
                        followerCounter: artist.followerCount,
                        profileImageUrl: artist.profileImageUrl,
                      ),
                    ),
                  ).then((_) => _loadFollowedIds()),
                  child: _buildArtistCard(
                    artist,
                    colors,
                    isFollowed: _followedIds.contains(artist.id),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _ArtistSuggestionBanner(colors: colors),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildArtistCard(
    Artist artist,
    AbstractThemeColors colors, {
    required bool isFollowed,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.0),
              boxShadow: [
                BoxShadow(
                  color: isFollowed
                      ? colors.activate.withValues(alpha: 0.35)
                      : colors.cardShadow.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            foregroundDecoration: isFollowed
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12.0),
                    border: Border.all(color: colors.activate, width: 2.5),
                  )
                : null,
            child: Hero(
              tag: 'artist_image_${artist.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: CachedNetworkImage(
                  imageUrl: artist.profileImageUrl,
                  memCacheWidth: 200,
                  fit: BoxFit.cover,
                  placeholder: (context, url) =>
                      const SkeletonBox(height: double.infinity),
                  errorWidget: (_, __, ___) => Container(
                    decoration: BoxDecoration(
                      color: colors.activate.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.person_rounded,
                        color: colors.activate, size: 40),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          artist.name,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isFollowed ? FontWeight.w700 : FontWeight.w600,
            color: isFollowed ? colors.activate : colors.textTitle,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }
}

String _genreLabel(String genre) {
  switch (genre) {
    case 'Band':
      return 'genre_band'.tr();
    case 'Hip-hop':
      return 'genre_hip_hop'.tr();
    case 'Indie':
      return 'genre_indie'.tr();
    case 'Ballad':
      return 'genre_ballad'.tr();
    case 'R&B':
      return 'genre_rnb'.tr();
    default:
      return 'genre_etc'.tr();
  }
}

class _ArtistSuggestionBanner extends StatelessWidget {
  final AbstractThemeColors colors;

  const _ArtistSuggestionBanner({required this.colors});

  void _openSheet(BuildContext context) {
    final userId = context.read<UserProvider>().currentUserId;
    if (userId == null) {
      context.showInfoSnackbar('no_login_info'.tr());
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ArtistSuggestionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _openSheet(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colors.activate.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(Icons.person_add_rounded, color: colors.activate, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'artist_suggestion_banner'.tr(),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: colors.textTitle,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'artist_suggestion_banner_sub'.tr(),
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded,
                color: colors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _GenreChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _GenreChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? colors.activate : colors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? colors.activate : colors.listDivider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : colors.textSecondary,
          ),
        ),
      ),
    );
  }
}
