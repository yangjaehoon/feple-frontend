import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:flutter/material.dart';

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

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: SecondaryAppBar(title: widget.title),
      backgroundColor: colors.backgroundMain,
      body: RefreshIndicator(
        color: colors.activate,
        onRefresh: _load,
        child: _loading
            ? widget.skeletonBuilder(colors)
            : _hasError
                ? _buildScrollable(
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off_rounded,
                            size: 48,
                            color: colors.textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('err_fetch_data'.tr(args: ['']),
                            style: TextStyle(color: colors.textSecondary),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text('retry'.tr()),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.activate,
                            shape: RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(AppDimens.shapeButton)),
                          ),
                        ),
                      ],
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
