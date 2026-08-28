import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/screen/main/tab/home/s_followed_artists_by_genre.dart';
import 'package:feple/screen/main/tab/home/s_liked_festivals.dart';
import 'package:feple/screen/main/tab/home/home_state_notifier.dart';
import 'package:feple/screen/main/tab/home/w_favorite_boards_section_skeleton.dart';
import 'package:feple/screen/main/tab/home/w_favorite_boards_section.dart';
import 'package:feple/common/widget/w_adaptive_refresh_view.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/screen/main/tab/home/w_home_artists_section.dart';
import 'package:feple/screen/main/tab/home/w_home_festivals_section.dart';
import 'package:feple/screen/main/tab/home/w_home_section_header.dart';
import 'package:feple/screen/onboarding/s_artist_pick.dart';
import 'package:feple/screen/onboarding/s_festival_pick.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_page.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/screen/main/tab/search/w_feple_app_bar.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../app.dart';
import '../../../../common/app_events.dart';
import '../../../../provider/user_provider.dart';

class HomeFragment extends StatefulWidget {
  const HomeFragment({super.key});

  @override
  State<HomeFragment> createState() => _HomeFragmentState();
}

class _HomeFragmentState extends State<HomeFragment> {
  final _notifier = HomeStateNotifier();
  final _scrollController = ScrollController();
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    AppEvents.festivalLikeChanged.addListener(_onFestivalLikeChanged);
    AppEvents.artistFollowChanged.addListener(_onArtistFollowChanged);
    App.resumeEvent.addListener(_onAppResumed);
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final show =
        _scrollController.position.pixels > AppDimens.scrollToTopThreshold;
    if (show != _showScrollToTop) setState(() => _showScrollToTop = show);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final userId = context.read<UserProvider>().currentUserId;
    if (userId != null && _notifier.userId != userId) {
      _notifier.init(userId);
    }
  }

  @override
  void dispose() {
    AppEvents.festivalLikeChanged.removeListener(_onFestivalLikeChanged);
    AppEvents.artistFollowChanged.removeListener(_onArtistFollowChanged);
    App.resumeEvent.removeListener(_onAppResumed);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _notifier.dispose();
    super.dispose();
  }

  void _onFestivalLikeChanged() => _notifier.refreshFestivals();
  void _onArtistFollowChanged() => _notifier.refreshArtists();
  void _onAppResumed() => _notifier.refresh();

  void _openArtistPick(BuildContext context) {
    Navigator.push(
      context,
      SlideRoute(
        builder: (_) => ArtistPickScreen(
          onComplete: (_) async => Navigator.pop(context),
          progressDotIndex: null,
        ),
      ),
    );
  }

  void _openFestivalPick(BuildContext context) {
    Navigator.push(
      context,
      SlideRoute(
        builder: (_) => FestivalPickScreen(
          onComplete: (_) async => Navigator.pop(context),
          progressDotIndex: null,
        ),
      ),
    );
  }

  Future<void> _onRefresh(BuildContext context) async {
    try {
      await _notifier.refresh(force: true);
    } catch (_) {
      if (!context.mounted) return;
      context.showErrorSnackbar('refresh_failed'.tr());
    }
  }

  Widget _buildBody(AbstractThemeColors colors) {
    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, _) {
        if (_notifier.userId == null) {
          return Center(
            child: CircularProgressIndicator(color: colors.loadingIndicator),
          );
        }
        return AdaptiveRefreshView(
          indicatorColor: colors.activate,
          onRefresh: () => _onRefresh(context),
          controller: _scrollController,
          padding: const EdgeInsets.only(bottom: AppDimens.scrollPaddingBottom),
          child: _buildScrollContent(context, colors),
        );
      },
    );
  }

  Widget _buildScrollToTopButton(AbstractThemeColors colors) {
    return Positioned(
      bottom: 20,
      right: 16,
      child: FloatingActionButton.small(
        heroTag: 'homeScrollTop',
        onPressed: () => _scrollController.animateTo(
          0,
          duration: AppDimens.animNormal,
          curve: Curves.easeOut,
        ),
        backgroundColor: colors.surface,
        foregroundColor: colors.textTitle,
        elevation: 6,
        child: const Icon(Icons.arrow_upward_rounded, size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    context
        .locale; // Subscribe to locale changes so section titles re-translate immediately
    final colors = context.appColors;
    return Stack(
      children: [
        ColoredBox(
          color: colors.backgroundMain,
          child: Column(
            children: [
              const FepleAppBar('Feple'),
              Expanded(child: _buildBody(colors)),
            ],
          ),
        ),
        if (_showScrollToTop) _buildScrollToTopButton(colors),
      ],
    );
  }

  // 아티스트/페스티벌 섹션을 각각 별도 ListenableBuilder로 감싸서, 좋아요·팔로우
  // 토글이나 정렬 변경이 반대쪽 섹션과 이미지 캐러셀까지 리빌드하지 않게 함
  // (HomeStateNotifier.artistsChanges/festivalsChanges 참고).
  Widget _buildScrollContent(BuildContext context, AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListenableBuilder(
          listenable: _notifier.artistsChanges,
          builder: (context, _) => _buildArtistsSection(context),
        ),
        const SizedBox(height: AppDimens.space8),
        ListenableBuilder(
          listenable: _notifier.festivalsChanges,
          builder: (context, _) => _buildFestivalsSection(context),
        ),
        const SizedBox(height: AppDimens.space8),
        ListenableBuilder(
          listenable: Listenable.merge([
            _notifier.artistsChanges,
            _notifier.festivalsChanges,
          ]),
          builder: (context, _) => _buildBoardsSection(colors),
        ),
      ],
    );
  }

  Widget _buildArtistsSection(BuildContext context) {
    final orderedArtists = _notifier.orderedArtists;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'followed_artists'.tr(),
          onExpand: (_notifier.artists?.isNotEmpty ?? false)
              ? () => Navigator.push(
                  context,
                  SlideRoute(
                    builder: (_) => FollowedArtistsByGenreScreen(
                      artists: orderedArtists ?? [],
                      onSaveOrder: _notifier.saveArtistOrder,
                    ),
                  ),
                )
              : null,
        ),
        HomeArtistsSection(
          artists: orderedArtists,
          error: _notifier.error,
          onRetry: _notifier.retry,
          onShowMore:
              (orderedArtists != null &&
                  orderedArtists.length > HomeArtistsSection.maxPreview)
              ? () => Navigator.push(
                  context,
                  SlideRoute(
                    builder: (_) => FollowedArtistsByGenreScreen(
                      artists: orderedArtists,
                      onSaveOrder: _notifier.saveArtistOrder,
                    ),
                  ),
                )
              : null,
          onTap: (artist) => Navigator.push(
            context,
            SlideRoute(
              builder: (_) => ArtistScreen.fromFollowedArtist(artist),
            ),
          ),
          onAddArtists: () => _openArtistPick(context),
        ),
      ],
    );
  }

  Widget _buildFestivalsSection(BuildContext context) {
    final orderedFestivals = _notifier.orderedFestivals;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'liked_festivals'.tr(),
          onExpand: (_notifier.festivals?.isNotEmpty ?? false)
              ? () => Navigator.push(
                  context,
                  SlideRoute(
                    builder: (_) => LikedFestivalsScreen(
                      festivals: orderedFestivals ?? [],
                      onSaveOrder: _notifier.saveFestivalOrder,
                    ),
                  ),
                )
              : null,
        ),
        HomeFestivalsSection(
          festivals: orderedFestivals,
          error: _notifier.error,
          onRetry: _notifier.retry,
          onTap: (festival) => Navigator.push(
            context,
            SlideRoute(
              builder: (_) => FestivalInformationFragment(poster: festival),
            ),
          ),
          onAddFestivals: () => _openFestivalPick(context),
        ),
      ],
    );
  }

  Widget _buildBoardsSection(AbstractThemeColors colors) {
    if (_notifier.hasError) {
      return ErrorState.section(_notifier.error!, onRetry: _notifier.retry);
    } else if (_notifier.boards == null) {
      return const FavoriteBoardsSectionSkeleton();
    } else {
      return FavoriteBoardsSection(
        allBoards: _notifier.boards!,
        userId: _notifier.userId!,
      );
    }
  }
}
