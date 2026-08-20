import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/app_events.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/future_refreshable.dart';
import 'package:feple/common/widget/w_async_content_builder.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/screen/onboarding/w_onboarding_progress_dots.dart';
import 'package:feple/service/festival_interaction_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:flutter/material.dart';

// 페스티벌 선택 화면(온보딩 진입/홈에서의 독립 진입 모두)이 한 번에 조회하는
// 다가오는 페스티벌 개수 상한. "고를 만한 페스티벌을 빠르게 보여주는" 화면의
// 목적상 목록 화면(FestivalPreviewProvider)처럼 스크롤 무한 로드를 붙이기보다
// 상한을 넉넉히 잡는 쪽을 택했다 — "다가오는 페스티벌"은 시간상 자연히 개수가
// 제한되는 데이터라 이 상한을 넘길 가능성이 낮다는 전제.
const upcomingFestivalsFetchSize = 100;

/// 페스티벌 좋아요 선택 화면 — 온보딩 흐름에서는 부모(OnboardingScreen)가
/// 개수를 확인하려고 미리 받아온 목록을 [initialFestivals]로 그대로 넘겨받아
/// 중복 조회 없이 표시하고(뒤이어 [progressDotIndex]로 5단계 중 자신의 위치를
/// 표시), 홈 화면 빈 상태에서의 독립 재진입에서는 [initialFestivals]가 없으므로
/// 직접 조회한다([progressDotIndex]는 null, 완료 시 화면을 닫음).
///
/// [onComplete]는 실제로 하나 이상 좋아요에 성공했는지(didLike)를 넘겨준다 —
/// 이 화면을 부모 스냅샷 위에 띄운 화면(예: LikedFestivalsScreen)이라면, 뭔가
/// 새로 좋아요됐을 때만 자신도 함께 닫고 데이터가 최신인 홈으로 보내는 식으로
/// 활용할 수 있다.
class FestivalPickScreen extends StatefulWidget {
  final Future<void> Function(bool didLike) onComplete;
  final List<FestivalPreview>? initialFestivals;
  final int? progressDotIndex;

  const FestivalPickScreen({
    super.key,
    required this.onComplete,
    this.initialFestivals,
    required this.progressDotIndex,
  });

  @override
  State<FestivalPickScreen> createState() => _FestivalPickScreenState();
}

class _FestivalPickScreenState extends State<FestivalPickScreen>
    with FutureRefreshable<List<FestivalPreview>, FestivalPickScreen> {
  final Set<int> _selectedIds = {};
  bool _isSubmitting = false;
  bool _initialFestivalsConsumed = false;

  @override
  Future<List<FestivalPreview>> fetchData() {
    if (widget.initialFestivals != null && !_initialFestivalsConsumed) {
      _initialFestivalsConsumed = true;
      return Future.value(widget.initialFestivals!);
    }
    return sl<FestivalService>()
        .fetchPreviews(page: 0, size: upcomingFestivalsFetchSize, includeEnded: false)
        .then((page) => page.items);
  }

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
      debugPrint('[FestivalPick] festival like failed: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        context.showErrorSnackbar('onboarding_festival_like_failed'.tr());
      }
      return;
    }
    if (!mounted) return;
    try {
      await widget.onComplete(targets.isNotEmpty);
    } catch (e) {
      debugPrint('[FestivalPick] onComplete failed: $e');
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
          if (widget.progressDotIndex != null) ...[
            buildOnboardingProgressDots(colors, activeIndex: widget.progressDotIndex!),
            const SizedBox(height: 24),
          ],
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
    return AsyncContentBuilder<List<FestivalPreview>>(
      future: future,
      loadingBuilder: (_) => _buildSkeleton(),
      errorBuilder: (error) => Center(
        child: ErrorState.network(
          error ?? Exception('unknown'),
          operationErrorKey: 'onboarding_festival_pick_load_failed',
          onRetry: refresh,
        ),
      ),
      emptyBuilder: (_) => Center(
        child: EmptyState(
          icon: Icons.event_busy_rounded,
          title: 'no_upcoming_festivals'.tr(),
        ),
      ),
      builder: (_, festivals) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 16,
          crossAxisSpacing: 12,
          childAspectRatio: 0.56,
        ),
        itemCount: festivals.length,
        itemBuilder: (_, index) {
          final festival = festivals[index];
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
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.56,
      ),
      itemCount: 6,
      itemBuilder: (_, _) => Column(
        children: const [
          AspectRatio(
            aspectRatio: 2 / 3,
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
    final checkSize = ResponsiveSize(context).w(22);
    return AspectRatio(
      aspectRatio: 2 / 3,
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
                width: checkSize,
                height: checkSize,
                decoration: BoxDecoration(
                  color: colors.activate,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_rounded,
                  color: Theme.of(context).colorScheme.onPrimary,
                  size: checkSize * (14 / 22),
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
