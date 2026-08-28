import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_app_network_image.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_diary_model.dart';
import 'package:feple/screen/main/tab/home/w_home_section_header.dart';
import 'package:feple/screen/main/tab/my_page/s_festival_diary_list.dart';
import 'package:feple/service/festival_diary_service.dart';
import 'package:flutter/material.dart';
import 'package:feple/common/util/responsive_size.dart';

class FestivalDiaryWidget extends StatefulWidget {
  const FestivalDiaryWidget({super.key});

  @override
  State<FestivalDiaryWidget> createState() => FestivalDiaryWidgetState();
}

class FestivalDiaryWidgetState extends State<FestivalDiaryWidget> {
  final _diaryService = sl<FestivalDiaryService>();
  List<FestivalDiaryModel>? _diaries;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  void refresh() => _load();

  Future<void> _load() async {
    setState(() { _isLoading = true; _hasError = false; });
    try {
      final list = await _diaryService.getMyDiaries();
      if (mounted) setState(() { _diaries = list; _isLoading = false; });
    } catch (e) {
      debugPrint('[FestivalDiary] 일기 목록 로드 실패: $e');
      if (mounted) setState(() { _hasError = true; _isLoading = false; });
    }
  }

  Future<void> _openList() async {
    await Navigator.push(context, SlideRoute(builder: (_) => const FestivalDiaryListScreen()));
    unawaited(_load());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'festival_diary'.tr(),
          trailing: TextButton(
            onPressed: _isLoading ? null : _openList,
            style: TextButton.styleFrom(
              minimumSize: Size.zero,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'see_all'.tr(),
                  style: TextStyle(fontSize: AppDimens.fontSizeSm, fontWeight: FontWeight.w600, color: colors.activate),
                ),
                Icon(Icons.chevron_right_rounded, size: 18, color: colors.activate),
              ],
            ),
          ),
        ),
        if (_hasError)
          ErrorState(message: 'load_error'.tr(), onRetry: _load)
        else
          SizedBox(
            height: ResponsiveSize(context).w(150),
            child: _isLoading
                ? _buildSkeletonList()
                : _diaries == null || _diaries!.isEmpty
                    ? _buildEmptyState(colors)
                    : _buildDiaryList(colors),
          ),
      ],
    );
  }

  Widget _buildSkeletonList() {
    final size = ResponsiveSize(context).w(98);
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: 3,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SkeletonBox(width: size, height: size, borderRadius: const BorderRadius.all(Radius.circular(16))),
            const SizedBox(height: AppDimens.space6),
            const SkeletonBox(width: 72, height: 11),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(AbstractThemeColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.menu_book_outlined, size: 32, color: colors.activate.withValues(alpha: 0.5)),
          const SizedBox(height: AppDimens.space8),
          Text(
            'diary_no_history'.tr(),
            style: TextStyle(fontSize: AppDimens.fontSizeSm, fontWeight: FontWeight.w600, color: colors.textTitle),
          ),
          const SizedBox(height: 3),
          Text(
            'diary_no_history_hint'.tr(),
            style: TextStyle(fontSize: AppDimens.fontSizeXxs, color: colors.textSecondary, height: 1.4),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppDimens.space10),
          FilledButton.icon(
            onPressed: _openList,
            icon: const Icon(Icons.add_rounded, size: 14),
            label: Text('diary_write'.tr(), style: const TextStyle(fontSize: AppDimens.fontSizeXs)),
            style: FilledButton.styleFrom(
              backgroundColor: colors.activate,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.padded,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiaryList(AbstractThemeColors colors) {
    final diaries = _diaries!;
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: diaries.length,
      itemBuilder: (context, index) => _buildDiaryItem(diaries[index], context.isEnglish, colors),
    );
  }

  Widget _buildDiaryItem(FestivalDiaryModel diary, bool isEnglish, AbstractThemeColors colors) {
    final size = ResponsiveSize(context).w(98);
    return TapScale(
      onTap: _openList,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: SizedBox(
                width: size,
                height: size,
                child: diary.photoUrls.isNotEmpty
                    ? AppNetworkImage(imageUrl: diary.photoUrls.first, width: size, height: size)
                    : Container(
                        color: colors.activate.withValues(alpha: 0.1),
                        child: Icon(Icons.menu_book_outlined, color: colors.activate.withValues(alpha: 0.4), size: 28),
                      ),
              ),
            ),
            const SizedBox(height: AppDimens.space4),
            SizedBox(
              width: ResponsiveSize(context).w(106),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    diary.isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
                    size: 10,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 3),
                  Flexible(
                    child: Text(
                      diary.displayFestivalTitle(isEnglish),
                      style: TextStyle(fontSize: AppDimens.fontSizeXxs, fontWeight: FontWeight.w600, color: colors.textTitle),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
