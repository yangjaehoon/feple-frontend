import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/data/preference/prefs.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/screen/onboarding/s_artist_pick.dart';
import 'package:feple/screen/onboarding/s_festival_pick.dart';
import 'package:feple/screen/onboarding/w_onboarding_progress_dots.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';

// 페스티벌 선택 단계를 보여주기 위한 최소 다가오는 페스티벌 수 — 이보다 적으면
// 고를 게 마땅치 않아 그 단계 자체를 건너뛴다.
const _minUpcomingFestivalsForPick = 3;

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
  // FestivalPickScreen에 그대로 넘겨주므로 그 화면이 같은 API를 다시 호출하지 않는다.
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
      return FestivalPickScreen(
        onComplete: _finish,
        initialFestivals: _festivals,
        showProgressDots: true,
      );
    }
    if (_showArtistPick) {
      return ArtistPickScreen(
        onComplete: _goToFestivalPick,
        showProgressDots: true,
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
