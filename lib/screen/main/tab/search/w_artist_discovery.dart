import 'package:feple/common/app_events.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_selectable_chip.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_suggestion_banner.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/future_refreshable.dart';
import 'package:feple/common/util/navigation_guard.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/search/artist_genre_style.dart';
import 'package:feple/screen/main/tab/search/w_artist_card.dart';
import 'package:feple/screen/main/tab/search/w_artist_suggestion_sheet.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../model/artist_model.dart';
import 'package:feple/injection.dart';
import '../../../../service/artist_service.dart';
import '../../../../service/artist_follow_service.dart';
import 'artist_page/s_artist_page.dart';

class ArtistDiscoverySection extends StatefulWidget {
  const ArtistDiscoverySection({super.key});

  @override
  State<ArtistDiscoverySection> createState() => ArtistDiscoverySectionState();
}

class ArtistDiscoverySectionState extends State<ArtistDiscoverySection>
    with FutureRefreshable<List<Artist>, ArtistDiscoverySection> {
  final _artistService = sl<ArtistService>();
  final _followService = sl<ArtistFollowService>();

  Set<int> _followedIds = {};

  @override
  Future<List<Artist>> fetchData() => _artistService.fetchArtists();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadFollowedIds());
    AppEvents.artistFollowChanged.addListener(_onArtistFollowChanged);
  }

  @override
  void dispose() {
    AppEvents.artistFollowChanged.removeListener(_onArtistFollowChanged);
    super.dispose();
  }

  void _onArtistFollowChanged() => _loadFollowedIds();

  // 부모(SearchFragment)가 GlobalKey로 refresh()를 호출해 완료 시점을 기다리므로
  // 목록/팔로우 상태를 함께 새로고침하고 끝날 때까지 기다린다.
  @override
  Future<void> refresh() => Future.wait([super.refresh(), _loadFollowedIds()]);

  Future<void> _loadFollowedIds() async {
    if (!mounted) return;
    final userId = context.read<UserProvider>().currentUserId;
    if (userId == null) return;
    try {
      final ids = await _followService.fetchFollowingIds(userId);
      if (mounted) setState(() => _followedIds = ids);
    } catch (e) {
      debugPrint('[ArtistDiscovery] follow ids load failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Artist>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildSkeleton();
        }
        if (snapshot.hasError) {
          return ErrorState.network(snapshot.error!, onRetry: refresh);
        }
        return _ArtistContent(
          allArtists: snapshot.data ?? [],
          followedIds: _followedIds,
          onRefreshFollowedIds: _loadFollowedIds,
        );
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
      child: LayoutBuilder(
        builder: (context, constraints) {
          final colWidth = gridColumnWidth(constraints.maxWidth);
          return Wrap(
            spacing: 12,
            runSpacing: 16,
            children: List.generate(
              6,
              (_) => SizedBox(
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
              ),
            ),
          );
        },
      ),
    );
  }
}

// Owns _selectedGenre so genre chip taps only rebuild this widget,
// not the FutureBuilder in ArtistDiscoverySectionState.
class _ArtistContent extends StatefulWidget {
  final List<Artist> allArtists;
  final Set<int> followedIds;
  final VoidCallback onRefreshFollowedIds;

  const _ArtistContent({
    required this.allArtists,
    required this.followedIds,
    required this.onRefreshFollowedIds,
  });

  @override
  State<_ArtistContent> createState() => _ArtistContentState();
}

// 전체 다음에 노출할 우선순위 — 나머지 장르는 그 뒤에 기존 정렬 순서대로 붙는다.
const List<String> _genrePriorityOrder = ['Band', 'Indie', 'Hip-hop', 'R&B', 'Ballad'];

List<String> _sortGenresByPriority(List<String> genres) {
  final prioritized = _genrePriorityOrder.where(genres.contains);
  final rest = genres.where((g) => !_genrePriorityOrder.contains(g));
  return [...prioritized, ...rest];
}

class _ArtistContentState extends State<_ArtistContent> with NavigationGuard {
  String? _selectedGenre;
  late List<String> _genres;

  @override
  void initState() {
    super.initState();
    _genres = _sortGenresByPriority(extractArtistGenres(widget.allArtists));
  }

  @override
  void didUpdateWidget(_ArtistContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.allArtists, widget.allArtists)) {
      _genres = _sortGenresByPriority(extractArtistGenres(widget.allArtists));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final artists = _selectedGenre == null
        ? widget.allArtists
        : widget.allArtists
              .where((a) => a.genres.contains(_selectedGenre))
              .toList();
    return _buildContent(artists, _genres, colors);
  }

  Future<void> _navigateToArtist(Artist artist) => guardedNavigate(
        () => Navigator.push(
          context,
          SlideRoute(builder: (context) => ArtistScreen.fromArtist(artist)),
        ).then((_) {
          if (mounted) widget.onRefreshFollowedIds();
        }),
      );

  Widget _buildTitle(AbstractThemeColors colors) {
    return Padding(
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
    );
  }

  Widget _buildGenreChips(List<String> genres) {
    return SelectableChipRow<String>(
      values: genres,
      selected: _selectedGenre,
      allLabel: 'filter_all'.tr(),
      labelOf: artistGenreLabel,
      onChanged: (genre) => setState(() => _selectedGenre = genre),
    );
  }

  Widget _buildArtistGrid(List<Artist> artists) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final colWidth = gridColumnWidth(constraints.maxWidth);
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
                      onTap: () => _navigateToArtist(artists[index]),
                      child: ArtistCard(
                        profileImageUrl: artists[index].profileImageUrl,
                        name: artists[index].displayName(context.isEnglish),
                        isFollowed: widget.followedIds.contains(
                          artists[index].id,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildContent(
    List<Artist> artists,
    List<String> genres,
    AbstractThemeColors colors,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitle(colors),
          const SizedBox(height: 10),
          _buildGenreChips(genres),
          const SizedBox(height: 12),
          _buildArtistGrid(artists),
          const SizedBox(height: 20),
          const _ArtistSuggestionBanner(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// 3열 아티스트 그리드의 컬럼 폭 — 스켈레톤과 실제 그리드가 동일하게 사용.
double gridColumnWidth(double maxWidth) => (maxWidth - 24) / 3;

class _ArtistSuggestionBanner extends StatelessWidget {
  const _ArtistSuggestionBanner();

  @override
  Widget build(BuildContext context) {
    return SuggestionBanner(
      icon: Icons.person_add_rounded,
      titleKey: 'artist_suggestion_banner',
      subtitleKey: 'artist_suggestion_banner_sub',
      sheetBuilder: (_) => const ArtistSuggestionSheet(),
    );
  }
}
