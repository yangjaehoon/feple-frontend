import 'package:feple/app.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_selectable_chip.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/model/notification_model.dart';
import 'package:feple/screen/main/tab/community_board/w_post_detail_card.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_page.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/screen/notification/notification_notifier.dart';
import 'package:feple/screen/notification/w_notification_card.dart';
import 'package:feple/screen/settings/s_notification_settings.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/artist_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';

// 섹션 헤더 또는 알림 카드를 구분하는 sealed class
sealed class _ListItem {}

class _SectionHeader extends _ListItem {
  final String label;
  _SectionHeader(this.label);
}

class _NotifItem extends _ListItem {
  final NotificationModel model;
  _NotifItem(this.model);
}

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _artistService = sl<ArtistService>();
  final _festivalService = sl<FestivalService>();
  final _postService = sl<PostService>();
  final _scrollController = ScrollController();
  late final NotificationNotifier _notifier;
  int? _navigatingId;
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    _notifier = NotificationNotifier();
    _scrollController.addListener(_onScroll);
    App.resumeEvent.addListener(_onAppResumed);
    _notifier.load();
  }

  @override
  void dispose() {
    App.resumeEvent.removeListener(_onAppResumed);
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _notifier.dispose();
    super.dispose();
  }

  void _onAppResumed() => _notifier.refresh();

  void _onScroll() {
    final pixels = _scrollController.position.pixels;
    final show = pixels > 300;
    if (show != _showScrollToTop) setState(() => _showScrollToTop = show);
    if (pixels >= _scrollController.position.maxScrollExtent - 300) {
      _notifier.loadMore();
    }
  }

  Future<void> _onTap(NotificationModel item) async {
    if (_navigatingId != null) return;
    await _notifier.markRead(item);
    if (item.type == null || item.referenceId == null) return;
    if (item.type!.hasFestivalNavigation) {
      await _navigateToFestival(item);
    } else if (item.type!.isCommentType) {
      await _navigateToPost(item);
    } else if (item.type!.isArtistNavigationType) {
      await _navigateToArtist(item);
    }
  }

  Future<void> _navigateToArtist(NotificationModel item) async {
    setState(() => _navigatingId = item.id);
    try {
      final artist = await _artistService.fetchArtistById(item.referenceId!);
      if (!mounted) return;
      await Navigator.push(
        context,
        SlideRoute(
          builder: (_) => ArtistScreen(
            artistId: artist.id,
            artistName: artist.name,
            followerCount: artist.followerCount,
            profileImageUrl: artist.profileImageUrl,
          ),
        ),
      );
    } catch (e) {
      debugPrint('[Notification] 아티스트 이동 실패: $e');
    } finally {
      if (mounted) setState(() => _navigatingId = null);
    }
  }

  Future<void> _navigateToPost(NotificationModel item) async {
    setState(() => _navigatingId = item.id);
    try {
      final post = await _postService.fetchPost(item.referenceId!);
      if (!mounted) return;
      await Navigator.push(
        context,
        SlideRoute(
          builder: (_) => PostDetailCard.fromPost(boardName: post.boardDisplayName, post: post),
        ),
      );
    } catch (e) {
      debugPrint('[Notification] 게시글 이동 실패: $e');
    } finally {
      if (mounted) setState(() => _navigatingId = null);
    }
  }

  Future<void> _navigateToFestival(NotificationModel item) async {
    setState(() => _navigatingId = item.id);
    try {
      final festival = await _festivalService.fetchById(item.referenceId!);
      if (!mounted) return;
      await Navigator.push(
        context,
        SlideRoute(
          builder: (_) => FestivalInformationFragment(poster: festival),
        ),
      );
    } catch (e) {
      debugPrint('[Notification] 페스티벌 이동 실패: $e');
    } finally {
      if (mounted) setState(() => _navigatingId = null);
    }
  }

  Future<void> _onDeleteAll() async {
    final confirmed = await showConfirmDialog(
      context,
      title: context.isEnglish ? 'Delete all notifications?' : '알림을 모두 삭제할까요?',
      content: context.isEnglish
          ? 'This cannot be undone.'
          : '삭제한 알림은 복구할 수 없습니다.',
      confirmLabel: context.isEnglish ? 'Delete all' : '모두 삭제',
    );
    if (confirmed == true) {
      await _notifier.deleteAll();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      floatingActionButton: _showScrollToTop
          ? FloatingActionButton.small(
              heroTag: 'notifScrollTop',
              onPressed: () => _scrollController.animateTo(
                0,
                duration: AppDimens.animNormal,
                curve: Curves.easeOut,
              ),
              backgroundColor: colors.surface,
              foregroundColor: colors.textTitle,
              elevation: 2,
              child: const Icon(Icons.arrow_upward_rounded, size: 20),
            )
          : null,
      body: ListenableBuilder(
        listenable: _notifier,
        builder: (context, _) => Column(
          children: [
            _buildAppBar(colors),
            _buildFilterChips(colors),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  try {
                    await _notifier.refresh(force: true);
                  } catch (_) {
                    if (context.mounted) context.showErrorSnackbar('refresh_failed'.tr());
                  }
                },
                color: colors.activate,
                child: _notifier.isLoading
                    ? _buildSkeleton(colors)
                    : _notifier.hasError
                        ? _buildScrollable(ErrorState(message: 'err_fetch_data'.tr(), onRetry: _notifier.load))
                        : _notifier.items.isEmpty
                            ? _buildScrollable(EmptyState(icon: Icons.notifications_none_rounded, title: 'no_notifications'.tr()))
                            : _buildNotificationList(colors),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar(AbstractThemeColors colors) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: AppDimens.appBarHeight,
        color: colors.backgroundMain,
        child: Row(
          children: [
            IconButton(
              tooltip: 'back'.tr(),
              icon: Icon(Icons.arrow_back_ios_rounded, color: colors.textTitle),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(
                'notifications'.tr(),
                style: TextStyle(
                  color: colors.textTitle,
                  fontSize: AppDimens.fontSizeTitle,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (_notifier.hasUnread)
              TextButton(
                onPressed: _notifier.markAllRead,
                child: Text(
                  'mark_all_read'.tr(),
                  style: TextStyle(
                    color: colors.activate,
                    fontSize: AppDimens.fontSizeSm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (_notifier.items.isNotEmpty)
              IconButton(
                tooltip: context.isEnglish ? 'Delete all' : '모두 삭제',
                icon: Icon(Icons.delete_sweep_rounded, color: colors.textSecondary),
                onPressed: _onDeleteAll,
              ),
            IconButton(
              tooltip: 'notif_settings'.tr(),
              icon: Icon(Icons.settings_rounded, color: colors.textTitle),
              onPressed: () => Navigator.push(
                context,
                SlideRoute(builder: (_) => const NotificationSettingsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips(AbstractThemeColors colors) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          SelectableChip(
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            label: 'filter_all'.tr(),
            selected: _notifier.filter == NotifFilter.all,
            onTap: () => _notifier.setFilter(NotifFilter.all),
          ),
          SelectableChip(
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            label: 'notif_filter_cert'.tr(),
            selected: _notifier.filter == NotifFilter.cert,
            onTap: () => _notifier.setFilter(NotifFilter.cert),
          ),
          SelectableChip(
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            label: 'notif_filter_comment'.tr(),
            selected: _notifier.filter == NotifFilter.comment,
            onTap: () => _notifier.setFilter(NotifFilter.comment),
          ),
          SelectableChip(
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            label: 'notif_filter_festival'.tr(),
            selected: _notifier.filter == NotifFilter.festival,
            onTap: () => _notifier.setFilter(NotifFilter.festival),
          ),
        ],
      ),
    );
  }

  void _dismissWithUndo(NotificationModel item) {
    _notifier.removeLocally(item);
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger
        .showSnackBar(SnackBar(
          content: Text('notification_dismissed'.tr()),
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'undo'.tr(),
            onPressed: () => _notifier.undoDismiss(item),
          ),
        ))
        .closed
        .then((reason) {
          if (reason != SnackBarClosedReason.action && mounted) {
            _notifier.confirmDismiss(item);
          }
        });
  }

  Widget _buildNotificationList(AbstractThemeColors colors) {
    final isEnglish = context.isEnglish;
    final sectioned = _buildSectionedItems(_notifier.items, !isEnglish);

    if (sectioned.isEmpty) {
      return _buildScrollable(
        EmptyState(icon: Icons.notifications_none_rounded, title: 'no_notifications'.tr()),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: sectioned.length + (_notifier.isLoadingMore ? 1 : 0),
      itemBuilder: (_, index) {
        if (index == sectioned.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(color: colors.activate)),
          );
        }

        final listItem = sectioned[index];

        if (listItem is _SectionHeader) {
          return Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 8),
            child: Text(
              listItem.label,
              style: TextStyle(
                fontSize: AppDimens.fontSizeSm,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
          );
        }

        final item = (listItem as _NotifItem).model;
        // 알림 인덱스 계산 (헤더 제외)
        final notifIndex = sectioned
            .take(index + 1)
            .whereType<_NotifItem>()
            .length - 1;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AnimatedListItem(
            index: notifIndex,
            child: Dismissible(
              key: ValueKey(item.id),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => _dismissWithUndo(item),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 20),
                decoration: BoxDecoration(
                  color: colors.error,
                  borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
                ),
                child: const Icon(Icons.delete_rounded, color: Colors.white, size: 22),
              ),
              child: TapScale(
                child: NotificationCard(
                  item: item,
                  isLoading: _navigatingId == item.id,
                  onTap: () => _onTap(item),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  List<_ListItem> _buildSectionedItems(List<NotificationModel> items, bool isKorean) {
    final result = <_ListItem>[];
    String? lastLabel;
    for (final item in items) {
      final label = item.sectionLabel(isKorean);
      if (label != lastLabel) {
        result.add(_SectionHeader(label));
        lastLabel = label;
      }
      result.add(_NotifItem(item));
    }
    return result;
  }

  Widget _buildScrollable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(child: child),
        ),
      ),
    );
  }

  Widget _buildSkeleton(AbstractThemeColors colors) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (_, __) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
          border: Border.all(color: colors.listDivider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SkeletonBox(
              width: 40,
              height: 40,
              borderRadius: BorderRadius.all(Radius.circular(20)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(height: 14),
                  SizedBox(height: 6),
                  SkeletonBox(width: 200, height: 12),
                  SizedBox(height: 4),
                  SkeletonBox(width: 80, height: 10),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
