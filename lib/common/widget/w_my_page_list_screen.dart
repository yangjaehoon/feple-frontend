import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:flutter/material.dart';

/// 내 게시글·스크랩처럼 '제목 + 서브텍스트 + trailing 숫자' 형태 목록의 기본 스켈레톤.
Widget postListSkeleton(AbstractThemeColors colors) {
  Widget item() => Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppDimens.paddingHorizontal, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(height: 15),
                  SizedBox(height: 6),
                  SkeletonBox(width: 80, height: 11),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const SkeletonBox(width: 50, height: 13),
          ],
        ),
      );
  return Column(
    children: [
      for (int i = 0; i < 5; i++) ...[
        item(),
        if (i < 4) Divider(thickness: 1, color: colors.listDivider),
      ],
    ],
  );
}

/// 마이페이지의 목록형 서브 화면(내 게시글, 내 댓글, 스크랩)에서 공유하는 스캐폴드.
///
/// 로딩 → 스켈레톤, 에러 → 재시도 버튼, 빈 목록 → [emptyIcon]/[emptyTitle],
/// 데이터 있음 → [itemBuilder]를 사용한 ListView.separated 를 표준 방식으로 렌더합니다.
class MyPageListScreen<T> extends StatefulWidget {
  final String title;
  final Future<List<T>> Function() loader;
  final Widget Function(AbstractThemeColors colors) skeletonBuilder;
  final Widget Function(BuildContext context, T item, VoidCallback reload) itemBuilder;
  final IconData emptyIcon;
  final String emptyTitle;

  const MyPageListScreen({
    super.key,
    required this.title,
    required this.loader,
    required this.skeletonBuilder,
    required this.itemBuilder,
    required this.emptyIcon,
    required this.emptyTitle,
  });

  @override
  State<MyPageListScreen<T>> createState() => _MyPageListScreenState<T>();
}

class _MyPageListScreenState<T> extends State<MyPageListScreen<T>> {
  List<T> _items = [];
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _hasError = false;
    });
    try {
      final data = await widget.loader();
      if (mounted) setState(() { _items = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  Future<void> _refresh() async {
    try {
      final data = await widget.loader();
      if (mounted) setState(() { _items = data; _hasError = false; });
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SecondaryAppBar(title: widget.title),
          Expanded(
            child: RefreshIndicator(
              color: colors.activate,
              onRefresh: _refresh,
              child: _loading
                  ? widget.skeletonBuilder(colors)
                  : _hasError
                      ? _buildScrollable(
                          ErrorState(
                            message: 'err_fetch_data'.tr(),
                            onRetry: _load,
                          ),
                        )
                      : _items.isEmpty
                          ? _buildScrollable(
                              EmptyState(
                                icon: widget.emptyIcon,
                                title: widget.emptyTitle,
                              ),
                            )
                          : ListView.separated(
                              physics: const AlwaysScrollableScrollPhysics(),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) =>
                                  Divider(thickness: 1, color: colors.listDivider),
                              itemBuilder: (context, index) => AnimatedListItem(
                                index: index,
                                child: widget.itemBuilder(
                                    context, _items[index], _load),
                              ),
                            ),
            ),
          ),
        ],
      ),
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
