import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_selectable_chip.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/data/preference/prefs.dart';
import 'package:feple/common/widget/w_async_content_builder.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_model.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/artist_service.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    if (_showArtistPick) {
      return _ArtistPickPage(onComplete: _finish);
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
          _buildDots(colors),
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

  Widget _buildDots(AbstractThemeColors colors) {
    final totalDots = _pageCount + 1; // 마지막 도트 = 아티스트 선택 단계
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalDots, (index) {
        final isActive = index == _currentPage;
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
}

// ─── 아티스트 선택 전체 화면 ───────────────────────────────────────────────────

class _ArtistPickPage extends StatefulWidget {
  final Future<void> Function() onComplete;

  const _ArtistPickPage({required this.onComplete});

  @override
  State<_ArtistPickPage> createState() => _ArtistPickPageState();
}

class _ArtistPickPageState extends State<_ArtistPickPage> {
  late Future<List<Artist>> _artistsFuture;
  final Set<int> _selectedIds = {};
  bool _isSubmitting = false;
  String? _selectedGenre;

  @override
  void initState() {
    super.initState();
    _artistsFuture = sl<ArtistService>().fetchArtists();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    try {
      await Future.wait(
        _selectedIds.map((id) => sl<ArtistFollowService>().follow(id)),
      );
    } catch (e) {
      debugPrint('[Onboarding] artist follow failed: $e');
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
          _buildDots(colors),
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

  Widget _buildDots(AbstractThemeColors colors) {
    // 4번째(인덱스 3) 도트가 활성
    return Row(
      children: List.generate(4, (index) {
        final isActive = index == 3;
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

  Widget _buildGrid(AbstractThemeColors colors) {
    return AsyncContentBuilder<List<Artist>>(
      future: _artistsFuture,
      loadingBuilder: (_) => _buildSkeleton(),
      errorBuilder: (_) => Center(
        child: ErrorState(
          message: 'onboarding_pick_load_failed'.tr(),
          onRetry: () => setState(() { _artistsFuture = sl<ArtistService>().fetchArtists(); }),
        ),
      ),
      isEmpty: (_) => false,
      builder: (_, artists) {
        final genres = _extractGenres(artists);
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

  List<String> _extractGenres(List<Artist> artists) {
    return artists.expand((a) => a.genres).toSet().toList()..sort();
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
          ...genres.map((genre) => SelectableChip(
                label: _genreLabel(genre),
                selected: _selectedGenre == genre,
                unselectedTextColor: colors.textTitle,
                onTap: () => setState(() => _selectedGenre = genre),
              )),
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
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                  placeholder: (_, _) => const SkeletonBox(height: double.infinity),
                  errorWidget: (_, _, _) => Container(
                    color: colors.activate.withValues(alpha: 0.08),
                    child: Icon(Icons.person_rounded, color: colors.activate, size: 36),
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
                decoration: BoxDecoration(color: colors.activate, shape: BoxShape.circle),
                child: Icon(Icons.check_rounded, color: Theme.of(context).colorScheme.onPrimary, size: 14),
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
            child: Icon(page.icon, size: outerSize * 0.309, color: page.primaryColor), // 68/220
          ),
        ],
      ),
    );
  }
}
