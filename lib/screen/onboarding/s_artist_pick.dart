import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/app_events.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_selectable_chip.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/future_refreshable.dart';
import 'package:feple/common/widget/w_async_content_builder.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_model.dart';
import 'package:feple/screen/main/tab/search/artist_genre_style.dart';
import 'package:feple/screen/onboarding/w_onboarding_progress_dots.dart';
import 'package:feple/service/artist_follow_service.dart';
import 'package:feple/service/artist_service.dart';
import 'package:flutter/material.dart';

/// 아티스트 팔로우 선택 화면 — 온보딩 흐름(뒤이어 페스티벌 선택 단계로 진행,
/// [progressDotIndex]로 5단계 중 자신의 위치를 표시)과 홈 화면 빈 상태에서의
/// 독립 재진입(완료 시 그냥 화면을 닫음, [progressDotIndex]는 null) 양쪽에서
/// 재사용된다. 진행 도트를 몇 번째에 표시할지는 호출하는 쪽(온보딩 흐름의
/// 구성)만 아는 정보라 여기서 기본값을 두지 않고 매번 명시적으로 받는다.
///
/// [onComplete]는 실제로 하나 이상 팔로우에 성공했는지(didFollow)를 넘겨준다 —
/// FestivalPickScreen.onComplete(didLike)와 대칭을 맞춘 것으로, 이 화면을 부모
/// 스냅샷 위에 띄운 화면이 있다면 뭔가 새로 팔로우됐을 때만 자신도 함께 닫고
/// 데이터가 최신인 화면으로 보내는 식으로 활용할 수 있다.
class ArtistPickScreen extends StatefulWidget {
  final Future<void> Function(bool didFollow) onComplete;
  final int? progressDotIndex;

  const ArtistPickScreen({
    super.key,
    required this.onComplete,
    required this.progressDotIndex,
  });

  @override
  State<ArtistPickScreen> createState() => _ArtistPickScreenState();
}

class _ArtistPickScreenState extends State<ArtistPickScreen>
    with FutureRefreshable<List<Artist>, ArtistPickScreen> {
  final Set<int> _selectedIds = {};
  bool _isSubmitting = false;
  String? _selectedGenre;

  @override
  Future<List<Artist>> fetchData() => sl<ArtistService>().fetchArtists();

  Future<void> _submit() async {
    if (_isSubmitting) return;
    setState(() => _isSubmitting = true);
    final targets = _selectedIds.toList();
    try {
      await Future.wait(
        targets.map((id) => sl<ArtistFollowService>().follow(id)),
      );
      if (targets.isNotEmpty) AppEvents.artistFollowChanged.value++;
    } catch (e) {
      debugPrint('[ArtistPick] artist follow failed: $e');
      if (mounted) {
        setState(() => _isSubmitting = false);
        context.showErrorSnackbar('onboarding_follow_failed'.tr());
      }
      return;
    }
    if (!mounted) return;
    try {
      await widget.onComplete(targets.isNotEmpty);
    } catch (e) {
      debugPrint('[ArtistPick] onComplete failed: $e');
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
          if (widget.progressDotIndex != null) ...[
            buildOnboardingProgressDots(colors, activeIndex: widget.progressDotIndex!),
            const SizedBox(height: 24),
          ],
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
