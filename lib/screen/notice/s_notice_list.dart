import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/notice_model.dart';
import 'package:feple/screen/notice/s_notice_detail.dart';
import 'package:feple/service/notice_service.dart';
import 'package:flutter/material.dart';

class NoticeListScreen extends StatefulWidget {
  const NoticeListScreen({super.key});

  @override
  State<NoticeListScreen> createState() => _NoticeListScreenState();
}

class _NoticeListScreenState extends State<NoticeListScreen> {
  final _service = sl<NoticeService>();
  final _scrollController = ScrollController();
  List<NoticeModel>? _list;
  Object? _error;
  bool _navigating = false;
  int _page = 0;
  bool _hasNext = false;
  bool _loadingMore = false;

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
    final pixels = _scrollController.position.pixels;
    if (pixels >= _scrollController.position.maxScrollExtent - AppDimens.loadMoreTriggerDistance) {
      _loadMore();
    }
  }

  // 이미 목록이 있는 상태(새로고침 실패)에서는 화면을 에러로 덮지 않고
  // 기존 목록을 유지한 채 스낵바로만 알린다 — 첫 로드 실패만 전체 화면 에러로 취급.
  Future<void> _load() async {
    try {
      final page = await _service.getNotices(page: 0);
      if (!mounted) return;
      setState(() {
        _list = page.notices;
        _hasNext = page.hasNext;
        _page = 0;
        _error = null;
      });
    } catch (e) {
      debugPrint('[NoticeList] 조회 실패: $e');
      if (!mounted) return;
      if (_list == null) {
        setState(() => _error = e);
      } else {
        context.showErrorSnackbar('refresh_failed'.tr());
      }
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasNext) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _service.getNotices(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _list = [...(_list ?? []), ...page.notices];
        _hasNext = page.hasNext;
        _page += 1;
      });
    } catch (e) {
      debugPrint('[NoticeList] 추가 로드 실패: $e');
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  // 목록에는 content가 없어(NoticeSummaryDto) 상세 진입 시 항상 재조회가 필요하다.
  // 실패해도 조용히 무시되지 않도록 스낵바로 알린다.
  Future<void> _openNotice(NoticeModel item) async {
    setState(() => _navigating = true);
    try {
      final notice = await _service.getNotice(item.id);
      if (!mounted) return;
      await Navigator.push(context, SlideRoute(builder: (_) => NoticeDetailScreen(notice: notice)));
    } catch (e) {
      debugPrint('[NoticeList] 상세 조회 실패: $e');
      if (mounted) context.showErrorSnackbar('load_error'.tr());
    } finally {
      if (mounted) setState(() => _navigating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SecondaryAppBar(title: 'notices'.tr()),
          Expanded(child: _buildBody(colors)),
        ],
      ),
    );
  }

  Widget _buildBody(AbstractThemeColors colors) {
    if (_list == null) {
      return _error != null
          ? ErrorState.network(_error!, onRetry: _load)
          : _buildSkeleton(colors);
    }
    if (_list!.isEmpty) {
      return EmptyState(icon: Icons.campaign_outlined, title: 'no_notices'.tr());
    }
    return RefreshIndicator(
      color: colors.activate,
      onRefresh: _load,
      child: ListView.separated(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _list!.length + (_loadingMore ? 1 : 0),
        separatorBuilder: (_, _) => Divider(height: 1, color: colors.listDivider),
        itemBuilder: (_, i) {
          if (i == _list!.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator(color: colors.activate)),
            );
          }
          return AnimatedListItem(index: i, child: _buildItem(_list![i], colors));
        },
      ),
    );
  }

  Widget _buildItem(NoticeModel notice, AbstractThemeColors colors) {
    return ListTile(
      tileColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      enabled: !_navigating,
      onTap: () => _openNotice(notice),
      title: Row(
        children: [
          if (notice.pinned) ...[
            Tooltip(
              message: 'notice_pinned'.tr(),
              child: Icon(Icons.push_pin_rounded, size: 14, color: colors.activate),
            ),
            const SizedBox(width: 6),
          ],
          Expanded(
            child: Text(
              notice.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: AppDimens.fontSizeMd,
                color: colors.textTitle,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      subtitle: notice.formattedDate == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                notice.formattedDate!,
                style: TextStyle(fontSize: AppDimens.fontSizeXs, color: colors.textSecondary),
              ),
            ),
      trailing: Icon(Icons.chevron_right_rounded, color: colors.textSecondary),
    );
  }

  Widget _buildSkeleton(AbstractThemeColors colors) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: 6,
      separatorBuilder: (_, _) => Divider(height: 1, color: colors.listDivider),
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            SkeletonBox(width: 200, height: 15),
            SizedBox(height: 8),
            SkeletonBox(width: 80, height: 11),
          ],
        ),
      ),
    );
  }
}
