import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_app_network_image.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_list_row_skeleton.dart';
import 'package:feple/model/festival_diary_model.dart';
import 'package:feple/service/festival_diary_service.dart';
import 'package:flutter/material.dart';
import 'package:feple/common/util/responsive_size.dart';

/// 다른 유저 프로필에서 그 유저가 쓴 공개 일기 목록을 보여주는 바텀시트.
class UserDiaryFeedSheet extends StatefulWidget {
  final int userId;
  final String nickname;
  final FestivalDiaryService diaryService;

  const UserDiaryFeedSheet({
    super.key,
    required this.userId,
    required this.nickname,
    required this.diaryService,
  });

  @override
  State<UserDiaryFeedSheet> createState() => _UserDiaryFeedSheetState();
}

class _UserDiaryFeedSheetState extends State<UserDiaryFeedSheet> {
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasError = false;
  final List<FestivalDiaryModel> _diaries = [];
  int _page = 0;
  bool _hasNext = false;

  @override
  void initState() {
    super.initState();
    _load(0);
  }

  Future<void> _load(int page) async {
    if (page == 0) {
      setState(() { _isLoading = true; _hasError = false; });
    } else {
      if (_isLoadingMore || !_hasNext) return;
      setState(() => _isLoadingMore = true);
    }
    try {
      final data = await widget.diaryService.getUserPublicDiaries(widget.userId, page: page);
      if (!mounted) return;
      setState(() {
        if (page == 0) {
          _diaries.clear();
          _isLoading = false;
        } else {
          _isLoadingMore = false;
        }
        _diaries.addAll(data.diaries);
        _page = page;
        _hasNext = data.hasNext;
      });
    } catch (e) {
      debugPrint('[UserDiaryFeedSheet] load error: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isLoadingMore = false;
        if (page == 0) _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) => Container(
        decoration: BoxDecoration(
          color: colors.backgroundMain,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.shapeSheet)),
        ),
        child: Column(
          children: [
            _buildSheetHeader(colors),
            Expanded(child: _buildBody(colors, scrollController)),
          ],
        ),
      ),
    );
  }

  Widget _buildSheetHeader(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: BottomSheetHandle()),
          const SizedBox(height: 14),
          Text(
            'user_diary_feed_title'.tr(args: [widget.nickname]),
            style: TextStyle(fontSize: AppDimens.fontSizeXxl, fontWeight: FontWeight.w800, color: colors.textTitle),
          ),
          const SizedBox(height: AppDimens.space12),
          Divider(color: colors.divider, height: 1),
        ],
      ),
    );
  }

  Widget _buildBody(AbstractThemeColors colors, ScrollController scrollController) {
    if (_isLoading) return const ListRowSkeleton();
    if (_hasError) {
      return ErrorState(message: 'diary_load_failed'.tr(), onRetry: () => _load(0));
    }
    if (_diaries.isEmpty) {
      return EmptyState(icon: Icons.menu_book_outlined, title: 'diary_public_feed_empty'.tr());
    }

    final itemCount = _diaries.length + (_isLoadingMore ? 1 : 0);
    return NotificationListener<ScrollNotification>(
      onNotification: (n) {
        if (n is ScrollEndNotification &&
            n.metrics.pixels >=
                n.metrics.maxScrollExtent - AppDimens.loadMoreTriggerDistance) {
          _load(_page + 1);
        }
        return false;
      },
      child: ListView.builder(
        controller: scrollController,
        padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom + 24),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          if (index < _diaries.length) {
            final diary = _diaries[index];
            return AnimatedListItem(
              index: index,
              child: _DiaryFeedCard(key: ValueKey(diary.id), diary: diary),
            );
          }
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }
}

class _DiaryFeedCard extends StatelessWidget {
  final FestivalDiaryModel diary;

  const _DiaryFeedCard({super.key, required this.diary});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final isEnglish = context.isEnglish;
    final photoSize = ResponsiveSize(context).w(84);
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  diary.displayFestivalTitle(isEnglish),
                  style: TextStyle(fontSize: AppDimens.fontSizeSm, fontWeight: FontWeight.w700, color: colors.textTitle),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (diary.formattedDate != null)
                Text(
                  diary.formattedDate!,
                  style: TextStyle(fontSize: AppDimens.fontSizeXxs, color: colors.textSecondary),
                ),
            ],
          ),
          const SizedBox(height: AppDimens.space8),
          Text(
            diary.content,
            style: TextStyle(fontSize: AppDimens.fontSizeSm, color: colors.textTitle, height: 1.4),
          ),
          if (diary.photoUrls.isNotEmpty) ...[
            const SizedBox(height: AppDimens.space10),
            SizedBox(
              height: photoSize,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: diary.photoUrls.length,
                separatorBuilder: (_, _) => const SizedBox(width: AppDimens.space8),
                itemBuilder: (_, i) => ClipRRect(
                  borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  child: AppNetworkImage(
                    imageUrl: diary.photoUrls[i],
                    width: photoSize,
                    height: photoSize,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
