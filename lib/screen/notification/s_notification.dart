import 'package:feple/app.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_selectable_chip.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/model/notification_model.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/screen/notification/notification_notifier.dart';
import 'package:feple/screen/notification/w_notification_card.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _festivalService = sl<FestivalService>();
  final _scrollController = ScrollController();
  late final NotificationNotifier _notifier;
  bool _isNavigating = false;
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
    await _notifier.markRead(item);
    if (item.type != null && item.type!.isFestivalType && item.referenceId != null) {
      await _navigateToFestival(item.referenceId!);
    }
  }

  Future<void> _navigateToFestival(int festivalId) async {
    if (_isNavigating) return;
    _isNavigating = true;
    try {
      final festival = await _festivalService.fetchById(festivalId);
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
      if (mounted) _isNavigating = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ListenableBuilder(
      listenable: _notifier,
      builder: (context, _) => Scaffold(
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
        body: Column(
          children: [
            _buildAppBar(colors),
            _buildFilterChips(colors),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  try {
                    await _notifier.refresh();
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
    ScaffoldMessenger.of(context)
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
    final displayed = _notifier.filtered;
    if (displayed.isEmpty) {
      return _buildScrollable(
        EmptyState(
          icon: Icons.notifications_none_rounded,
          title: 'no_notifications'.tr(),
        ),
      );
    }
    return ListView.separated(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: displayed.length + (_notifier.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, index) => index < displayed.length - 1 ? const SizedBox(height: 8) : const SizedBox.shrink(),
      itemBuilder: (_, index) {
        if (index == displayed.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(color: colors.activate)),
          );
        }
        final item = displayed[index];
        return AnimatedListItem(
          index: index,
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
              child: NotificationCard(item: item, onTap: () => _onTap(item)),
            ),
          ),
        );
      },
    );
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
