import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/app_events.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_selectable_chip.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/data/preference/prefs.dart';
import 'package:feple/common/util/future_refreshable.dart';
import 'package:feple/common/widget/w_async_content_builder.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_model.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/screen/main/tab/search/artist_genre_style.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/artist_service.dart';
import 'package:feple/service/festival_interaction_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';

// 온보딩 전체 단계 수 (인포 3 + 아티스트 선택 + 페스티벌 선택) — 진행 도트를
// 그리는 세 위젯(_OnboardingScreenState/_ArtistPickPage/_FestivalPickPage)이 공유.
const _onboardingTotalSteps = 5;

// 페스티벌 선택 단계를 보여주기 위한 최소 다가오는 페스티벌 수 — 이보다 적으면
// 고를 게 마땅치 않아 그 단계 자체를 건너뛴다.
const _minUpcomingFestivalsForPick = 3;

/// 온보딩 진행 상태 도트 — 인포 페이지(_OnboardingScreenState)와 아티스트/페스티벌
/// 선택 페이지가 activeIndex만 다르게 공유.
Widget _buildProgressDots(
  AbstractThemeColors colors, {
  required int totalDots,
  required int activeIndex,
}) {
  return Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(totalDots, (index) {
      final isActive = index == activeIndex;
      return AnimatedContainer(
        duration: AppDimens.animNormal,
        margin: const EdgeInsets.only(right: 8),
        width: isActive ? 24 : 8,
        height: 8,
        decoration: BoxDecoration(
          color: isActive ? colors.activate : colors.inActivate,
          borderRadius: BorderRadius.circular(AppDimens.radiusXs),
        ),
      );
    }),
  );
}

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  const OnboardingScreen({super.key, required this.onComplete});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _currentPage = 0;
  bool _showArtistPick = false;
  bool _showFestivalPick = false;
  List<FestivalPreview> _festivals = const [];

  static const _pageCount = 3;
  bool get _isLastInfoPage => _currentPage == _pageCount - 1;

  List<_PageData> _buildPages(AbstractThemeColors colors) => [
    _PageData(
      titleKey: 'onboarding_title_1',
      subtitleKey: 'onboarding_subtitle_1',
      icon: Icons.festival_rounded,
      primaryColor: colors.activate,
      bgColor: AppColors.skyBlueLight,
      accentColor: colors.accentColor,
    ),
    _PageData(
      titleKey: 'onboarding_title_2',
      subtitleKey: 'onboarding_subtitle_2',
      icon: Icons.favorite_rounded,
      primaryColor: AppColors.kawaiiPink,
      bgColor: AppColors.onboardingPink,
      accentColor: AppColors.kawaiiPurple,
    ),
    _PageData(
      titleKey: 'onboarding_title_3',
      subtitleKey: 'onboarding_subtitle_3',
      icon: Icons.forum_rounded,
      primaryColor: AppColors.kawaiiMint,
      bgColor: AppColors.onboardingMint,
      accentColor: colors.accentColor,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_isLastInfoPage) {
      setState(() => _showArtistPick = true);
    } else {
      _pageController.nextPage(
        duration: AppDimens.animNormal,
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    await Prefs.onboardingCompleted.set(true);
    widget.onComplete();
  }

  // 다가오는 페스티벌을 미리 받아 개수를 확인한다 — 여기서 받아온 목록을
  // _FestivalPickPage에 그대로 넘겨주므로 그 화면이 같은 API를 다시 호출하지 않는다.
  // 조회 실패 시에도(사용자에게 에러를 보여줄 만큼 중요한 단계가 아니므로) 조용히
  // 건너뛰고 완료 처리한다.
  Future<void> _goToFestivalPick() async {
    List<FestivalPreview> festivals = const [];
    try {
      final page = await sl<FestivalService>().fetchPreviews(
        page: 0,
        size: 30,
        includeEnded: false,
      );
      festivals = page.items;
    } catch (e) {
      debugPrint('[Onboarding] festival preview fetch failed: $e');
    }
    if (!mounted) return;
    if (festivals.length < _minUpcomingFestivalsForPick) {
      await _finish();
      return;
    }
    setState(() {
      _festivals = festivals;
      _showFestivalPick = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showFestivalPick) {
      return _FestivalPickPage(onComplete: _finish, festivals: _festivals);
    }
    if (_showArtistPick) {
      return _ArtistPickPage(onComplete: _goToFestivalPick);
    }

    final colors = context.appColors;
    final pages = _buildPages(colors);
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(colors),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _PageContent(page: pages[i]),
              ),
            ),
            _buildBottom(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 0),
      child: Row(
        children: [
          _buildProgressDots(colors, totalDots: _onboardingTotalSteps, activeIndex: _currentPage),
          const Spacer(),
          TextButton(
            onPressed: _finish,
            style: TextButton.styleFrom(
              foregroundColor: colors.textSecondary,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            child: Text(
              'onboarding_skip'.tr(),
              style: const TextStyle(
                fontSize: AppDimens.fontSizeMd,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottom(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 36),
      child: LoadingButton(
        label: 'onboarding_next'.tr(),
        onPressed: _goNext,
        backgroundColor: colors.activate,
        borderRadius: AppDimens.shapeButton,
      ),
    );
  }

}

// ─── 아티스트 선택 전체 화면 ───────────────────────────────────────────────────

class _ArtistPickPage extends StatefulWidget {
  final Future<void> Function() onComplete;

  const _ArtistPickPage({required this.onComplete});

  @override
  State<_ArtistPickPage> createState() => _ArtistPickPageState();
}

class _ArtistPickPageState extends State<_ArtistPickPage>
    with FutureRefreshable<List<Artist>, _ArtistPickPage> {
  final Set<int> _selectedIds = {};
  bool _isSubmitting = false;
  String? _selectedGenre;

  @override
  Future<List<Artist>> fetchData() => sl<ArtistService>().fetchArtists();

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await Future.wait(
        _selectedIds.map((id) => sl<ArtistFollowService>().follow(id)),
      );
      if (_selectedIds.isNotEmpty) AppEvents.artistFollowChanged.value++;
    } catch (e) {
      debugPrint('[Onboarding] artist follow failed: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        context.showErrorSnackbar('onboarding_follow_failed'.tr());
      }
      return;
    }
    if (!mounted) return;
    try {
      await widget.onComplete();
    } catch (e) {
      debugPrint('[Onboarding] onComplete failed: $e');
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colors),
            Expanded(child: _buildGrid(colors)),
            _buildBottomBar(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 진행 도트 (4번째 활성)
          _buildProgressDots(colors, totalDots: _onboardingTotalSteps, activeIndex: 3),
          const SizedBox(height: 24),
          Text(
            'onboarding_pick_title'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeDisplay,
              fontWeight: FontWeight.w800,
              color: colors.textTitle,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'onboarding_pick_subtitle'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeMd,
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }


  Widget _buildGrid(AbstractThemeColors colors) {
    return AsyncContentBuilder<List<Artist>>(
      future: future,
      loadingBuilder: (_) => _buildSkeleton(),
      errorBuilder: (error) => Center(
        child: ErrorState.network(
          error ?? Exception('unknown'),
          operationErrorKey: 'onboarding_pick_load_failed',
          onRetry: refresh,
        ),
      ),
      isEmpty: (_) => false,
      builder: (_, artists) {
        final genres = extractArtistGenres(artists);
        final filtered = _selectedGenre == null
            ? artists
            : artists.where((a) => a.genres.contains(_selectedGenre)).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (genres.isNotEmpty) _buildGenreChips(genres, colors),
            Expanded(
              child: GridView.builder(
                key: ValueKey(_selectedGenre),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.72,
                ),
                itemCount: filtered.length,
                itemBuilder: (_, index) {
                  final artist = filtered[index];
                  final selected = _selectedIds.contains(artist.id);
                  return _ArtistSelectCard(
                    artist: artist,
                    selected: selected,
                    onTap: () => setState(() {
                      if (selected) {
                        _selectedIds.remove(artist.id);
                      } else {
                        _selectedIds.add(artist.id);
                      }
                    }),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGenreChips(List<String> genres, AbstractThemeColors colors) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
      child: Row(
        children: [
          SelectableChip(
            label: 'genre_all'.tr(),
            selected: _selectedGenre == null,
            unselectedTextColor: colors.textTitle,
            onTap: () => setState(() => _selectedGenre = null),
          ),
          ...genres.map(
            (genre) => SelectableChip(
              label: artistGenreLabel(genre),
              selected: _selectedGenre == genre,
              unselectedTextColor: colors.textTitle,
              onTap: () => setState(() => _selectedGenre = genre),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.72,
      ),
      itemCount: 9,
      itemBuilder: (_, _) => Column(
        children: const [
          AspectRatio(
            aspectRatio: 1.0,
            child: SkeletonBox(
              height: double.infinity,
              borderRadius: BorderRadius.all(Radius.circular(12)),
            ),
          ),
          SizedBox(height: 8),
          SkeletonBox(width: 56, height: 13),
        ],
      ),
    );
  }

  Widget _buildBottomBar(AbstractThemeColors colors) {
    final count = _selectedIds.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      decoration: BoxDecoration(
        color: colors.backgroundMain,
        border: Border(top: BorderSide(color: colors.listDivider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count > 0) ...[
            AnimatedContainer(
              duration: AppDimens.animFast,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.activate.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.cardRadius),
              ),
              child: Text(
                'onboarding_pick_selected'.tr(args: ['$count']),
                style: TextStyle(
                  fontSize: AppDimens.fontSizeSm,
                  fontWeight: FontWeight.w600,
                  color: colors.activate,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          LoadingButton(
            label: count == 0
                ? 'onboarding_pick_skip'.tr()
                : 'onboarding_start'.tr(),
            onPressed: _submit,
            isLoading: _isSubmitting,
            backgroundColor: colors.activate,
            borderRadius: AppDimens.shapeButton,
          ),
        ],
      ),
    );
  }
}

// ─── 아티스트 선택 카드 ────────────────────────────────────────────────────────

class _ArtistSelectCard extends StatelessWidget {
  final Artist artist;
  final bool selected;
  final VoidCallback onTap;

  const _ArtistSelectCard({
    required this.artist,
    required this.selected,
    required this.onTap,
  });

  Widget _buildCardImage(BuildContext context, AbstractThemeColors colors) {
    return AspectRatio(
      aspectRatio: 1.0,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedContainer(
              duration: AppDimens.animFast,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
                border: Border.all(
                  color: selected ? colors.activate : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                child: CachedNetworkImage(
                  imageUrl: artist.profileImageUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 200,
                  placeholder: (_, _) =>
                      const SkeletonBox(height: double.infinity),
                  errorWidget: (_, _, _) => Container(
                    color: colors.activate.withValues(alpha: 0.08),
                    child: Icon(
                      Icons.person_rounded,
                      color: colors.activate,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (selected)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: colors.activate,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          _buildCardImage(context, colors),
          const SizedBox(height: 6),
          Text(
            artist.name,
            style: TextStyle(
              fontSize: AppDimens.fontSizeSm,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? colors.activate : colors.textTitle,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── 장르 필터 칩 ────────────────────────────────────────────────────────────

// ─── 페스티벌 선택 전체 화면 ───────────────────────────────────────────────────

class _FestivalPickPage extends StatefulWidget {
  final Future<void> Function() onComplete;
  final List<FestivalPreview> festivals;

  const _FestivalPickPage({required this.onComplete, required this.festivals});

  @override
  State<_FestivalPickPage> createState() => _FestivalPickPageState();
}

class _FestivalPickPageState extends State<_FestivalPickPage> {
  final Set<int> _selectedIds = {};
  bool _isSubmitting = false;

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    // toggleLike는 호출할 때마다 좋아요 상태가 뒤집히는 순수 토글이라(멱등 아님),
    // 실패한 항목만 남기고 성공한 항목은 선택 목록에서 제거해야 재시도 시
    // 이미 성공한 좋아요가 다시 눌려서 취소되는 걸 막을 수 있다.
    final targets = _selectedIds.toList();
    try {
      await Future.wait(
        targets.map((id) async {
          await sl<FestivalInteractionService>().toggleLike(id);
          _selectedIds.remove(id);
        }),
        eagerError: false,
      );
      if (targets.isNotEmpty) AppEvents.festivalLikeChanged.value++;
    } catch (e) {
      debugPrint('[Onboarding] festival like failed: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        context.showErrorSnackbar('onboarding_festival_like_failed'.tr());
      }
      return;
    }
    if (!mounted) return;
    try {
      await widget.onComplete();
    } catch (e) {
      debugPrint('[Onboarding] onComplete failed: $e');
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(colors),
            Expanded(child: _buildGrid()),
            _buildBottomBar(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 진행 도트 (5번째 활성)
          _buildProgressDots(colors, totalDots: _onboardingTotalSteps, activeIndex: 4),
          const SizedBox(height: 24),
          Text(
            'onboarding_festival_pick_title'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeDisplay,
              fontWeight: FontWeight.w800,
              color: colors.textTitle,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'onboarding_festival_pick_subtitle'.tr(),
            style: TextStyle(
              fontSize: AppDimens.fontSizeMd,
              color: colors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildGrid() {
    // 목록은 부모(_OnboardingScreenState)가 이미 받아와 넘겨준 것을 그대로 쓴다 —
    // 여기서 다시 조회하지 않는다(_minUpcomingFestivalsForPick 개수 확인을 위해
    // 어차피 한 번 미리 받아와야 해서, 이 화면은 로딩/에러 상태를 갖지 않는다).
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.62,
      ),
      itemCount: widget.festivals.length,
      itemBuilder: (_, index) {
        final festival = widget.festivals[index];
        final selected = _selectedIds.contains(festival.id);
        return _FestivalSelectCard(
          festival: festival,
          selected: selected,
          onTap: () => setState(() {
            if (selected) {
              _selectedIds.remove(festival.id);
            } else {
              _selectedIds.add(festival.id);
            }
          }),
        );
      },
    );
  }

  Widget _buildBottomBar(AbstractThemeColors colors) {
    final count = _selectedIds.length;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
      decoration: BoxDecoration(
        color: colors.backgroundMain,
        border: Border(top: BorderSide(color: colors.listDivider)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (count > 0) ...[
            AnimatedContainer(
              duration: AppDimens.animFast,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: colors.activate.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.cardRadius),
              ),
              child: Text(
                'onboarding_pick_selected'.tr(args: ['$count']),
                style: TextStyle(
                  fontSize: AppDimens.fontSizeSm,
                  fontWeight: FontWeight.w600,
                  color: colors.activate,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
          LoadingButton(
            label: count == 0
                ? 'onboarding_pick_skip'.tr()
                : 'onboarding_start'.tr(),
            onPressed: _submit,
            isLoading: _isSubmitting,
            backgroundColor: colors.activate,
            borderRadius: AppDimens.shapeButton,
          ),
        ],
      ),
    );
  }
}

// ─── 페스티벌 선택 카드 ────────────────────────────────────────────────────────

class _FestivalSelectCard extends StatelessWidget {
  final FestivalPreview festival;
  final bool selected;
  final VoidCallback onTap;

  const _FestivalSelectCard({
    required this.festival,
    required this.selected,
    required this.onTap,
  });

  Widget _buildPoster(BuildContext context, AbstractThemeColors colors) {
    return AspectRatio(
      aspectRatio: 0.75,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedContainer(
              duration: AppDimens.animFast,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
                border: Border.all(
                  color: selected ? colors.activate : Colors.transparent,
                  width: 2.5,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(AppDimens.radiusMedium),
                child: CachedNetworkImage(
                  imageUrl: festival.posterUrl,
                  fit: BoxFit.cover,
                  memCacheWidth: 260,
                  placeholder: (_, _) =>
                      const SkeletonBox(height: double.infinity),
                  errorWidget: (_, _, _) => Container(
                    color: colors.activate.withValues(alpha: 0.08),
                    child: Icon(
                      Icons.festival_rounded,
                      color: colors.activate,
                      size: 36,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (selected)
            Positioned(
              top: 6,
              right: 6,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: colors.activate,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: 14,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          _buildPoster(context, colors),
          const SizedBox(height: 6),
          Text(
            festival.displayTitle(context.isEnglish),
            style: TextStyle(
              fontSize: AppDimens.fontSizeSm,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected ? colors.activate : colors.textTitle,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

// ─── 인포 페이지 데이터 & 위젯 ────────────────────────────────────────────────

class _PageData {
  final String titleKey;
  final String subtitleKey;
  final IconData icon;
  final Color primaryColor;
  final Color bgColor;
  final Color accentColor;

  const _PageData({
    required this.titleKey,
    required this.subtitleKey,
    required this.icon,
    required this.primaryColor,
    required this.bgColor,
    required this.accentColor,
  });
}

class _PageContent extends StatelessWidget {
  final _PageData page;

  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildIllustration(context),
          const SizedBox(height: 52),
          Text(
            page.titleKey.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppDimens.fontSizeDisplay,
              fontWeight: FontWeight.w800,
              color: colors.textTitle,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            page.subtitleKey.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: AppDimens.fontSizeLg,
              color: colors.textSecondary,
              height: 1.7,
              fontWeight: FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIllustration(BuildContext context) {
    final outerSize = MediaQuery.sizeOf(context).width * 0.564; // 220/390
    return SizedBox(
      width: outerSize,
      height: outerSize,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              width: outerSize * 0.682, // 150/220
              height: outerSize * 0.682,
              decoration: BoxDecoration(
                color: page.bgColor.withValues(alpha: 0.45),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: 4,
            top: 8,
            child: Container(
              width: outerSize * 0.273, // 60/220
              height: outerSize * 0.273,
              decoration: BoxDecoration(
                color: page.accentColor.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: outerSize * 0.618, // 136/220
            height: outerSize * 0.618,
            decoration: BoxDecoration(
              color: page.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: page.primaryColor.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            child: Icon(
              page.icon,
              size: outerSize * 0.309,
              color: page.primaryColor,
            ), // 68/220
          ),
        ],
      ),
    );
  }
}
