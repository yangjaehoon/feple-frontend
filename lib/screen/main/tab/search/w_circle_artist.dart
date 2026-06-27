import 'package:feple/common/common.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/widget/w_selectable_chip.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/w_artist_card.dart';
import 'package:feple/screen/main/tab/search/w_artist_suggestion_sheet.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../model/artist_model.dart';
import 'package:feple/injection.dart';
import '../../../../service/artist_service.dart';
import '../../../../service/artist_follow_service.dart';
import 'artist_page/f_artist_page.dart';

class CircleArtistWidget extends StatefulWidget {
  const CircleArtistWidget({super.key});

  @override
  State<CircleArtistWidget> createState() => CircleArtistWidgetState();
}

class CircleArtistWidgetState extends State<CircleArtistWidget> {
  late Future<List<Artist>> _artistsFuture;
  String? _selectedGenre;
  Set<int> _followedIds = {};
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _artistsFuture = sl<ArtistService>().fetchArtists();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFollowedIds());
  }

  void refresh() {
    setState(() => _artistsFuture = sl<ArtistService>().fetchArtists());
    _loadFollowedIds();
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
        final genres = allArtists.expand((a) => a.genres).toSet().toList()..sort();
        final artists = _selectedGenre == null
            ? allArtists
            : allArtists.where((a) => a.genres.contains(_selectedGenre)).toList();
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(builder: (context, constraints) {
        final colWidth = (constraints.maxWidth - 24) / 3;
        return Wrap(
          spacing: 12,
          runSpacing: 16,
          children: List.generate(6, (_) => SizedBox(
            width: colWidth,
            child: Column(
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
          )),
        );
      }),
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
                fontSize: AppDimens.fontSizeTitle,
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
                SelectableChip(
                  label: 'filter_all'.tr(),
                  selected: _selectedGenre == null,
                  onTap: () => setState(() => _selectedGenre = null),
                ),
                ...genres.map((genre) => SelectableChip(
                      label: _genreLabel(genre),
                      selected: _selectedGenre == genre,
                      onTap: () => setState(() => _selectedGenre = genre),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: LayoutBuilder(builder: (context, constraints) {
              final colWidth = (constraints.maxWidth - 24) / 3;
              return Wrap(
                spacing: 12,
                runSpacing: 16,
                children: [
                  for (int index = 0; index < artists.length; index++)
                    SizedBox(
                      width: colWidth,
                      child: AnimatedListItem(
                        index: index,
                        child: TapScale(
                          onTap: () {
                            if (_isNavigating) return;
                            _isNavigating = true;
                            Navigator.push(
                              context,
                              SlideRoute(
                                builder: (context) => ArtistPage(
                                  artistName: artists[index].name,
                                  artistId: artists[index].id,
                                  followerCount: artists[index].followerCount,
                                  profileImageUrl: artists[index].profileImageUrl,
                                ),
                              ),
                            ).then((_) { if (mounted) _loadFollowedIds(); })
                             .whenComplete(() { if (mounted) _isNavigating = false; });
                          },
                          child: ArtistCard(
                            artist: artists[index],
                            isFollowed: _followedIds.contains(artists[index].id),
                            isEnglish: context.locale.languageCode == 'en',
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ),
          const SizedBox(height: 20),
          const _ArtistSuggestionBanner(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

}

String _genreLabel(String genre) {
  switch (genre) {
    case 'Band':    return 'genre_band'.tr();
    case 'Hip-hop': return 'genre_hip_hop'.tr();
    case 'Indie':   return 'genre_indie'.tr();
    case 'Ballad':  return 'genre_ballad'.tr();
    case 'R&B':     return 'genre_rnb'.tr();
    case '댄스':     return 'genre_dance'.tr();
    case '아이돌':   return 'genre_idol'.tr();
    default:        return genre;
  }
}

class _ArtistSuggestionBanner extends StatelessWidget {
  const _ArtistSuggestionBanner();

  void _openSheet(BuildContext context) {
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final userId = context.read<UserProvider>().currentUserId;
    if (userId == null) {
      context.showInfoSnackbar('no_login_info'.tr());
      return;
    }
    showAppBottomSheet(
      context,
      builder: (_) => const ArtistSuggestionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: () => _openSheet(context),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
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
                      fontSize: AppDimens.fontSizeSm,
                      fontWeight: FontWeight.w600,
                      color: colors.textTitle,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'artist_suggestion_banner_sub'.tr(),
                    style: TextStyle(fontSize: AppDimens.fontSizeXs, color: colors.textSecondary),
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

