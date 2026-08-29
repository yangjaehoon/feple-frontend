import 'package:feple/common/common.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/data/preference/prefs.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/screen/onboarding/s_artist_pick.dart';
import 'package:feple/screen/onboarding/s_festival_pick.dart';
import 'package:feple/screen/onboarding/w_onboarding_progress_dots.dart';
import 'package:feple/service/festival_cache_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';

// 페스티벌 선택 단계를 보여주기 위한 최소 다가오는 페스티벌 수 — 이보다 적으면
// 고를 게 마땅치 않아 그 단계 자체를 건너뛴다.
const _minUpcomingFestivalsForPick = 3;

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onComplete;

  /// 온보딩 완료 플래그를 저장할 유저 ID (유저 단위 저장).
  final int userId;

  const OnboardingScreen({
    super.key,
    required this.onComplete,
    required this.userId,
  });

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
    // 온보딩에서 좋아요/팔로우한 내용이 홈 첫 진입에 바로 반영되도록:
    // 스플래시가 저장해 둔 낡은 홈 스냅샷을 지우고(캐시 우선 렌더가 빈 목록을
    // 먼저 보여주는 것 방지), 다음 홈 로드를 강제 새로고침으로 표시한다.
    // 온보딩 중에는 홈이 없어 like/follow 이벤트를 못 듣기 때문.
    try {
      await sl<FestivalCacheService>().clearHome(widget.userId);
      await Prefs.pendingHomeForceRefreshFor(widget.userId).set(true);
    } catch (e) {
      debugPrint('[Onboarding] home cache reset failed: $e');
    }
    await Prefs.onboardingCompletedFor(widget.userId).set(true);
    widget.onComplete();
  }

  // 다가오는 페스티벌을 미리 받아 개수를 확인한다 — 여기서 받아온 목록을
  // FestivalPickScreen에 그대로 넘겨주므로 그 화면이 같은 API를 다시 호출하지 않는다.
  // 조회 실패 시에도(사용자에게 에러를 보여줄 만큼 중요한 단계가 아니므로) 조용히
  // 건너뛰고 완료 처리한다.
  Future<void> _goToFestivalPick() async {
    List<FestivalPreview> festivals = const [];
    try {
      final page = await sl<FestivalService>().fetchPreviews(
        page: 0,
        size: upcomingFestivalsFetchSize,
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
      return FestivalPickScreen(
        onComplete: (_) => _finish(),
        initialFestivals: _festivals,
        progressDotIndex: 4,
      );
    }
    if (_showArtistPick) {
      return ArtistPickScreen(
        onComplete: (_) => _goToFestivalPick(),
        progressDotIndex: 3,
      );
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
          buildOnboardingProgressDots(colors, activeIndex: _currentPage),
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
          const SizedBox(height: AppDimens.space16),
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
    final outerSize = ResponsiveSize(context).w(220);
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
