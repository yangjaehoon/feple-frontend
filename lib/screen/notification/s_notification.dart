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
import 'package:feple/screen/notification/notification_type.dart';
import 'package:feple/screen/notification/w_notification_card.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/service/notification_service.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';

enum _NotifFilter { all, cert, comment, festival }

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _notificationService = sl<NotificationService>();
  final _festivalService = sl<FestivalService>();
  final _scrollController = ScrollController();
  List<NotificationModel> _items = [];
  bool _loading = true;
  bool _hasError = false;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  int _page = 0;
  _NotifFilter _filter = _NotifFilter.all;

  List<NotificationModel> get _filtered {
    if (_filter == _NotifFilter.all) return _items;
    return _items.where((n) {
      final t = n.type;
      if (t == null) return false;
      return switch (_filter) {
        _NotifFilter.cert     => t.isCertType,
        _NotifFilter.comment  => t.isCommentType,
        _NotifFilter.festival => t.isFestivalFilterType,
        _NotifFilter.all      => true,
      };
    }).toList();
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _load();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _hasError = false; _page = 0; _hasMore = true; _items = []; });
    try {
      final result = await _notificationService.fetchPage(0);
      if (mounted) {
        setState(() {
          _items = result.items;
          _hasMore = result.hasMore;
          _page = 1;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  Future<void> _refresh() async {
    try {
      final result = await _notificationService.fetchPage(0);
      if (mounted) {
        setState(() {
          _items = result.items;
          _hasMore = result.hasMore;
          _page = 1;
          _hasError = false;
        });
      }
    } catch (_) {}
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _loading) return;
    setState(() => _isLoadingMore = true);
    try {
      final result = await _notificationService.fetchPage(_page);
      if (mounted) {
        setState(() {
          _items = [..._items, ...result.items];
          _hasMore = result.hasMore;
          _page++;
          _isLoadingMore = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoadingMore = false);
    }
  }

  Future<void> _onTap(NotificationModel item) async {
    final realIndex = _items.indexWhere((n) => n.id == item.id);
    if (realIndex < 0) return;

    if (!item.read) {
      setState(() => _items[realIndex] = item.copyWithRead());
      try {
        await _notificationService.markRead(item.id);
      } catch (e) {
        debugPrint('markRead error: $e');
      }
    }

    if (item.type != null && item.type!.isFestivalType && item.referenceId != null) {
      await _navigateToFestival(item.referenceId!);
    }
  }

  Future<void> _markAllRead() async {
    if (_items.every((n) => n.read)) return;
    setState(() => _items = _items.map((n) => n.read ? n : n.copyWithRead()).toList());
    try {
      await _notificationService.markAllRead();
    } catch (e) {
      debugPrint('[Notification] markAllRead error: $e');
    }
  }

  Future<void> _dismissNotification(NotificationModel item) async {
    final realIndex = _items.indexWhere((n) => n.id == item.id);
    if (realIndex < 0) return;
    setState(() => _items.removeAt(realIndex));
    // adminBroadcast는 개별 read API 대상이 아님 — 로컬에서만 제거
    if (item.type == NotificationType.adminBroadcast) return;
    try {
      await _notificationService.markRead(item.id);
    } catch (e) {
      debugPrint('[Notification] markRead 실패: $e');
    }
  }

  Future<void> _navigateToFestival(int festivalId) async {
    try {
      final festival = await _festivalService.fetchById(festivalId);
      if (!mounted) return;
      Navigator.push(
        context,
        SlideRoute(
          builder: (_) => FestivalInformationFragment(poster: festival),
        ),
      );
    } catch (e) {
      debugPrint('[Notification] 페스티벌 이동 실패: $e');
    }
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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          _buildAppBar(colors),
          _buildFilterChips(colors),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _refresh,
              color: colors.activate,
              child: _loading
                  ? _buildSkeleton(colors)
                  : _hasError
                      ? _buildScrollable(ErrorState(message: 'err_fetch_data'.tr(), onRetry: _load))
                      : _items.isEmpty
                          ? _buildScrollable(EmptyState(icon: Icons.notifications_none_rounded, title: 'no_notifications'.tr()))
                          : _buildNotificationList(colors),
            ),
          ),
        ],
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
            if (_items.any((n) => !n.read))
              TextButton(
                onPressed: _markAllRead,
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
            selected: _filter == _NotifFilter.all,
            onTap: () => setState(() => _filter = _NotifFilter.all),
          ),
          SelectableChip(
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            label: 'notif_filter_cert'.tr(),
            selected: _filter == _NotifFilter.cert,
            onTap: () => setState(() => _filter = _NotifFilter.cert),
          ),
          SelectableChip(
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            label: 'notif_filter_comment'.tr(),
            selected: _filter == _NotifFilter.comment,
            onTap: () => setState(() => _filter = _NotifFilter.comment),
          ),
          SelectableChip(
            margin: const EdgeInsets.only(right: 8, bottom: 4),
            label: 'notif_filter_festival'.tr(),
            selected: _filter == _NotifFilter.festival,
            onTap: () => setState(() => _filter = _NotifFilter.festival),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList(AbstractThemeColors colors) {
    final displayed = _filtered;
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
      itemCount: displayed.length + (_isLoadingMore ? 1 : 0),
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
            onDismissed: (_) => _dismissNotification(item),
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: AppColors.errorRed,
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
}

