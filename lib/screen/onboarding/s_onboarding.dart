import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/data/preference/prefs.dart';
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

  static const _pages = [
    _PageData(
      titleKey: 'onboarding_title_1',
      subtitleKey: 'onboarding_subtitle_1',
      icon: Icons.festival_rounded,
      primaryColor: AppColors.skyBlue,
      bgColor: AppColors.skyBlueLight,
      accentColor: AppColors.sunnyYellow,
    ),
    _PageData(
      titleKey: 'onboarding_title_2',
      subtitleKey: 'onboarding_subtitle_2',
      icon: Icons.favorite_rounded,
      primaryColor: AppColors.kawaiiPink,
      bgColor: Color(0xFFFFE4EF),
      accentColor: AppColors.kawaiiPurple,
    ),
    _PageData(
      titleKey: 'onboarding_title_3',
      subtitleKey: 'onboarding_subtitle_3',
      icon: Icons.forum_rounded,
      primaryColor: AppColors.kawaiiMint,
      bgColor: Color(0xFFD4F5EC),
      accentColor: AppColors.sunnyYellow,
    ),
  ];

  bool get _isLastInfoPage => _currentPage == _pages.length - 1;

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
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(colors),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pages.length,
                onPageChanged: (i) => setState(() => _currentPage = i),
                itemBuilder: (_, i) => _PageContent(page: _pages[i]),
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
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
    final totalDots = _pages.length + 1;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(totalDots, (i) {
        final isActive = i == _currentPage;
        return AnimatedContainer(
          duration: AppDimens.animNormal,
          margin: const EdgeInsets.only(right: 8),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? colors.activate : colors.inActivate,
            borderRadius: BorderRadius.circular(4),
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
              fontSize: 24,
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
      children: List.generate(4, (i) {
        final isActive = i == 3;
        return AnimatedContainer(
          duration: AppDimens.animNormal,
          margin: const EdgeInsets.only(right: 8),
          width: isActive ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: isActive ? colors.activate : colors.inActivate,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }

  Widget _buildGrid(AbstractThemeColors colors) {
    return FutureBuilder<List<Artist>>(
      future: _artistsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return _buildSkeleton();
        }
        if (snapshot.hasError || snapshot.data == null) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.wifi_off_rounded,
                    color: colors.inActivate, size: 48),
                const SizedBox(height: 12),
                Text(
                  'onboarding_pick_load_failed'.tr(),
                  style: TextStyle(color: colors.textSecondary),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => setState(() {
                    _artistsFuture = sl<ArtistService>().fetchArtists();
                  }),
                  child: Text('onboarding_pick_retry'.tr()),
                ),
              ],
            ),
          );
        }
        final artists = snapshot.data!;
        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 16,
            crossAxisSpacing: 12,
            childAspectRatio: 0.72,
          ),
          itemCount: artists.length,
          itemBuilder: (_, i) {
            final artist = artists[i];
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
        );
      },
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
      itemBuilder: (_, __) => Column(
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
                borderRadius: BorderRadius.circular(20),
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 1.0,
            child: Stack(
              children: [
                Positioned.fill(
                  child: AnimatedContainer(
                    duration: AppDimens.animFast,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: selected
                            ? colors.activate
                            : Colors.transparent,
                        width: 2.5,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: CachedNetworkImage(
                        imageUrl: artist.profileImageUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 200,
                        placeholder: (_, __) => const SkeletonBox(
                          height: double.infinity,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: colors.activate.withValues(alpha: 0.08),
                          child: Icon(Icons.person_rounded,
                              color: colors.activate, size: 36),
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
                      child: const Icon(Icons.check_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            artist.name,
            style: TextStyle(
              fontSize: AppDimens.fontSizeSm,
              fontWeight:
                  selected ? FontWeight.w700 : FontWeight.w500,
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
          _buildIllustration(),
          const SizedBox(height: 52),
          Text(
            page.titleKey.tr(),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
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

  Widget _buildIllustration() {
    return SizedBox(
      width: 220,
      height: 220,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            right: 4,
            bottom: 4,
            child: Container(
              width: 150,
              height: 150,
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
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: page.accentColor.withValues(alpha: 0.55),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Container(
            width: 136,
            height: 136,
            decoration: BoxDecoration(
              color: page.primaryColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: page.primaryColor.withValues(alpha: 0.25),
                width: 2,
              ),
            ),
            child: Icon(page.icon, size: 68, color: page.primaryColor),
          ),
        ],
      ),
    );
  }
}
