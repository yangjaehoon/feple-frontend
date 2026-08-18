import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/navigate_after_fetch.dart';
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
  List<NoticeModel>? _list;
  Object? _error;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _error = null);
    try {
      final page = await _service.getNotices();
      if (mounted) setState(() => _list = page.notices);
    } catch (e) {
      debugPrint('[NoticeList] 조회 실패: $e');
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _openNotice(NoticeModel item) => navigateAfterFetch(
        context,
        fetch: () => _service.getNotice(item.id),
        builder: (notice) => NoticeDetailScreen(notice: notice),
        setLoading: (v) => mounted ? setState(() => _navigating = v) : null,
        errorTag: 'Notice',
      );

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
    if (_error != null) {
      return ErrorState.network(_error!, onRetry: _load);
    }
    if (_list == null) {
      return _buildSkeleton(colors);
    }
    if (_list!.isEmpty) {
      return EmptyState(icon: Icons.campaign_outlined, title: 'no_notices'.tr());
    }
    return RefreshIndicator(
      color: colors.activate,
      onRefresh: _load,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _list!.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: colors.listDivider),
        itemBuilder: (_, i) =>
            AnimatedListItem(index: i, child: _buildItem(_list![i], colors)),
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
            Icon(Icons.push_pin_rounded, size: 14, color: colors.activate),
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
