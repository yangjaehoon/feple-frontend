import 'package:feple/app.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_selectable_chip.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_refreshable_center.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/util/popup_menu_item_builder.dart';
import 'package:feple/model/notification_model.dart';
import 'package:feple/screen/notification/notification_time_style.dart';
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

class _NotificationItem extends _ListItem {
  final NotificationModel model;
  _NotificationItem(this.model);
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
    final show = pixels > AppDimens.scrollToTopThreshold;
    if (show != _showScrollToTop) setState(() => _showScrollToTop = show);
    if (pixels >=
        _scrollController.position.maxScrollExtent -
            AppDimens.loadMoreTriggerDistance) {
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
            artistNameEn: artist.nameEn,
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
          builder: (_) => PostDetailCard.fromPost(
            boardName: post.boardDisplayName,
            post: post,
          ),
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
      title: 'notif_delete_all_title'.tr(),
      content: 'notif_delete_all_content'.tr(),
      confirmLabel: 'notif_delete_all_confirm'.tr(),
    );
    if (!confirmed || !mounted) return;

    _notifier.removeAllLocally();
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger
        .showSnackBar(
          SnackBar(
            content: Text('notif_delete_all_dismissed'.tr()),
            duration: const Duration(seconds: 4),
            persist: false,
            action: SnackBarAction(
              label: 'undo'.tr(),
              onPressed: _notifier.undoDeleteAll,
            ),
          ),
        )
        .closed
        .then((reason) {
          if (reason != SnackBarClosedReason.action) {
            _notifier.confirmDeleteAll();
          }
        });
  }

  void _onMenuSelected(String value) {
    switch (value) {
      case 'settings':
        Navigator.push(
          context,
          SlideRoute(builder: (_) => const NotificationSettingsScreen()),
        );
      case 'delete_all':
        _onDeleteAll();
    }
  }

  List<PopupMenuEntry<String>> _buildMenuItems(AbstractThemeColors colors) {
    return [
      buildPopupMenuItem(
        value: 'settings',
        icon: Icons.settings_outlined,
        label: 'notif_settings'.tr(),
        colors: colors,
      ),
      if (_notifier.items.isNotEmpty) ...[
        const PopupMenuDivider(height: 1),
        buildPopupMenuItem(
          value: 'delete_all',
          icon: Icons.delete_outline_rounded,
          label: 'notif_delete_all_confirm'.tr(),
          colors: colors,
          danger: true,
        ),
      ],
    ];
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
              elevation: 6,
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
                    if (context.mounted) {
                      context.showErrorSnackbar('refresh_failed'.tr());
                    }
                  }
                },
                color: colors.activate,
                child: _notifier.isLoading
                    ? _buildSkeleton(colors)
                    : _notifier.hasError
                    ? _buildScrollable(
                        ErrorState.network(
                          _notifier.error!,
                          onRetry: _notifier.load,
                        ),
                      )
                    : _notifier.items.isEmpty
                    ? _buildScrollable(
                        EmptyState(
                          icon: Icons.notifications_none_rounded,
                          title: 'no_notifications'.tr(),
                        ),
                      )
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
            IconButton(
              tooltip: 'mark_all_read'.tr(),
              icon: Icon(
                Icons.done_all_rounded,
                color: _notifier.hasUnread
                    ? colors.activate
                    : colors.textSecondary.withValues(alpha: 0.3),
              ),
              onPressed: _notifier.hasUnread ? _notifier.markAllRead : null,
            ),
            PopupMenuButton<String>(
              tooltip: 'notif_settings'.tr(),
              icon: Icon(Icons.settings_rounded, color: colors.textTitle),
              onSelected: _onMenuSelected,
              itemBuilder: (_) => _buildMenuItems(colors),
              color: colors.surface,
              shadowColor: colors.cardShadow.withValues(alpha: 0.18),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.shapeDialog),
              ),
              position: PopupMenuPosition.under,
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
            selected: _notifier.filter == NotificationFilter.all,
            onTap: () => _notifier.setFilter(NotificationFilter.all),
          ),
          SelectableChip(
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            label: 'notif_filter_cert'.tr(),
            selected: _notifier.filter == NotificationFilter.cert,
            onTap: () => _notifier.setFilter(NotificationFilter.cert),
          ),
          SelectableChip(
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            label: 'notif_filter_comment'.tr(),
            selected: _notifier.filter == NotificationFilter.comment,
            onTap: () => _notifier.setFilter(NotificationFilter.comment),
          ),
          SelectableChip(
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            label: 'notif_filter_festival'.tr(),
            selected: _notifier.filter == NotificationFilter.festival,
            onTap: () => _notifier.setFilter(NotificationFilter.festival),
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
        .showSnackBar(
          SnackBar(
            content: Text('notification_dismissed'.tr()),
            duration: const Duration(seconds: 4),
            // Flutter 3.x: action != null이면 persist 기본값이 true → 타이머가 실행되도
            // 스낵바를 닫지 않음. 실행취소 버튼이 있어도 4초 후 자동 닫히도록 명시
            persist: false,
            action: SnackBarAction(
              label: 'undo'.tr(),
              onPressed: () => _notifier.undoDismiss(item),
            ),
          ),
        )
        .closed
        .then((reason) {
          // 서버 삭제(confirmDismiss)는 setState 없이 서비스 호출+자체 try-catch만 하므로
          // 스낵바가 닫히는 시점에 화면을 이미 벗어났어도(mounted=false) 안전하게 호출 가능 —
          // 여기서 mounted를 체크하면 화면 이탈 시 서버 삭제가 누락돼 항목이 되살아나는 버그가 생김
          if (reason != SnackBarClosedReason.action) {
            _notifier.confirmDismiss(item);
          }
        });
  }

  Widget _buildNotificationList(AbstractThemeColors colors) {
    final sectioned = _buildSectionedItems(_notifier.items);

    if (sectioned.isEmpty) {
      return _buildScrollable(
        EmptyState(
          icon: Icons.notifications_none_rounded,
          title: 'no_notifications'.tr(),
        ),
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
            child: Center(
              child: CircularProgressIndicator(color: colors.activate),
            ),
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

        final item = (listItem as _NotificationItem).model;
        // 알림 인덱스 계산 (헤더 제외)
        final notifIndex =
            sectioned.take(index + 1).whereType<_NotificationItem>().length - 1;

        final card = TapScale(
          child: NotificationCard(
            item: item,
            isLoading: _navigatingId == item.id,
            onTap: () => _onTap(item),
          ),
        );
        final isDismissible = item.type?.isDismissible ?? true;
        // Dismissible은 child(카드)를 클리핑 없이 translate만 하므로, 카드
        // 자체의 둥근 모서리가 드래그 중간 지점에서 깎아낸 작은 틈이 생김.
        // Dismissible의 background는 실제로 드러난 영역에만 클립되어 그 틈을
        // 못 채우므로, 항상 전체를 채우는 빨간 레이어를 카드 뒤에 별도로 깔아
        // 그 틈에서도 화면 배경이 아닌 삭제 색상이 보이게 함
        final rounded = isDismissible
            ? Stack(
                children: [
                  Positioned.fill(child: Container(color: colors.error)),
                  Dismissible(
                    key: ValueKey(item.id),
                    direction: DismissDirection.endToStart,
                    onDismissed: (_) => _dismissWithUndo(item),
                    background: Container(
                      alignment: Alignment.centerRight,
                      padding: const EdgeInsets.only(right: 20),
                      color: colors.error,
                      child: const Icon(
                        Icons.delete_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    child: card,
                  ),
                ],
              )
            : card;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: AnimatedListItem(
            index: notifIndex,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
              child: rounded,
            ),
          ),
        );
      },
    );
  }

  List<_ListItem> _buildSectionedItems(List<NotificationModel> items) {
    final result = <_ListItem>[];
    String? lastLabel;
    for (final item in items) {
      final label = item.sectionLabel;
      if (label != lastLabel) {
        result.add(_SectionHeader(label));
        lastLabel = label;
      }
      result.add(_NotificationItem(item));
    }
    return result;
  }

  Widget _buildScrollable(Widget child) => RefreshableCenter(child: child);

  Widget _buildSkeleton(AbstractThemeColors colors) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: 5,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (_, _) => Container(
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
