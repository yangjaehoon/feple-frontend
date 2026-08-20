import 'package:feple/common/common.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_app_network_image.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_refreshable_center.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_diary_model.dart';
import 'package:feple/screen/main/tab/my_page/s_write_festival_diary.dart';
import 'package:feple/service/festival_diary_service.dart';
import 'package:flutter/material.dart';
import 'package:feple/common/util/responsive_size.dart';

class FestivalDiaryListScreen extends StatefulWidget {
  const FestivalDiaryListScreen({super.key});

  @override
  State<FestivalDiaryListScreen> createState() => _FestivalDiaryListScreenState();
}

class _FestivalDiaryListScreenState extends State<FestivalDiaryListScreen> {
  final _diaryService = sl<FestivalDiaryService>();
  List<FestivalDiaryModel> _diaries = [];
  bool _isLoading = true;
  Object? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _loadError = null; });
    try {
      final list = await _diaryService.getMyDiaries();
      if (mounted) setState(() { _diaries = list; _isLoading = false; });
    } catch (e) {
      debugPrint('[DiaryList] 로드 실패: $e');
      if (mounted) setState(() { _loadError = e; _isLoading = false; });
    }
  }

  Future<void> _openWriteScreen({FestivalDiaryModel? existing}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => WriteFestivalDiaryScreen(existing: existing)),
    );
    if (result == true) unawaited(_load());
  }

  Future<void> _delete(FestivalDiaryModel diary) async {
    final confirmed = await showConfirmDialog(
      context,
      title: 'diary_delete_confirm_title'.tr(),
      content: 'diary_delete_confirm_msg'.tr(),
      confirmLabel: 'delete'.tr(),
    );
    if (!confirmed || !mounted) return;
    try {
      await _diaryService.delete(diary.id);
      if (!mounted) return;
      setState(() => _diaries.removeWhere((d) => d.id == diary.id));
      context.showInfoSnackbar('diary_delete_success'.tr());
    } catch (e) {
      debugPrint('[DiaryList] 삭제 실패: $e');
      if (mounted) context.showErrorSnackbar('diary_delete_failed'.tr());
    }
  }

  Widget _buildSkeleton(AbstractThemeColors colors) {
    final size = ResponsiveSize(context).w(96);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 3,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => Container(
        height: size,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
          boxShadow: CardShadows.subtle(colors),
        ),
        child: Row(
          children: [
            SkeletonBox(
              width: size,
              height: size,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    SkeletonBox(height: 15),
                    SizedBox(height: 8),
                    SkeletonBox(height: 11),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(AbstractThemeColors colors) {
    return RefreshIndicator(
      onRefresh: _load,
      color: colors.activate,
      child: _isLoading
          ? _buildSkeleton(colors)
          : _loadError != null
              ? RefreshableCenter(child: ErrorState.network(_loadError!, onRetry: _load))
              : _diaries.isEmpty
                  ? RefreshableCenter(
                      child: EmptyState(
                        icon: Icons.menu_book_outlined,
                        title: 'diary_no_history'.tr(),
                        subtitle: 'diary_no_history_hint'.tr(),
                      ),
                    )
                  : ListView.separated(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      itemCount: _diaries.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final diary = _diaries[index];
                        return AnimatedListItem(
                          index: index,
                          child: _DiaryCard(
                            key: ValueKey(diary.id),
                            diary: diary,
                            onTap: () => _openWriteScreen(existing: diary),
                            onDelete: () => _delete(diary),
                          ),
                        );
                      },
                    ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      appBar: SecondaryAppBar(
        title: 'festival_diary'.tr(),
        actions: [
          TextButton.icon(
            onPressed: () => _openWriteScreen(),
            icon: Icon(Icons.edit_note_rounded, color: colors.appBarIconColor, size: 20),
            label: Text(
              'diary_write'.tr(),
              style: TextStyle(color: colors.appBarIconColor, fontWeight: FontWeight.w700, fontSize: AppDimens.fontSizeSm),
            ),
          ),
        ],
      ),
      body: _buildBody(colors),
    );
  }
}

class _DiaryCard extends StatelessWidget {
  final FestivalDiaryModel diary;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _DiaryCard({super.key, required this.diary, required this.onTap, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
        boxShadow: CardShadows.subtle(colors),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
              child: SizedBox(
                width: ResponsiveSize(context).w(96),
                height: ResponsiveSize(context).w(96),
                child: diary.photoUrls.isNotEmpty
                    ? AppNetworkImage(
                        imageUrl: diary.photoUrls.first,
                        width: ResponsiveSize(context).w(96),
                        height: ResponsiveSize(context).w(96),
                      )
                    : Container(
                        color: colors.activate.withValues(alpha: 0.1),
                        child: Icon(Icons.menu_book_outlined, color: colors.activate.withValues(alpha: 0.4), size: 28),
                      ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            diary.displayFestivalTitle(context.isEnglish),
                            style: TextStyle(fontSize: AppDimens.fontSizeMd, fontWeight: FontWeight.w700, color: colors.textTitle),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: onDelete,
                          child: Icon(Icons.delete_outline_rounded, size: 18, color: colors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      diary.content,
                      style: TextStyle(fontSize: AppDimens.fontSizeXs, color: colors.textSecondary),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          diary.isPublic ? Icons.public_rounded : Icons.lock_outline_rounded,
                          size: 12,
                          color: colors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          (diary.isPublic ? 'diary_visibility_public' : 'diary_visibility_private').tr(),
                          style: TextStyle(fontSize: AppDimens.fontSizeXxs, color: colors.textSecondary),
                        ),
                        if (diary.formattedDate != null) ...[
                          const SizedBox(width: 8),
                          Text(
                            diary.formattedDate!,
                            style: TextStyle(fontSize: AppDimens.fontSizeXxs, color: colors.textSecondary),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
