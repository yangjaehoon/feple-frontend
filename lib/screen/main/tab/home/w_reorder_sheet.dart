import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_app_network_image.dart';
import 'package:feple/common/widget/w_draggable_sheet_scaffold.dart';
import 'package:flutter/material.dart';

/// 순서 변경에 사용할 아이템
class ReorderItem {
  final int id;
  final String name;
  final String? imageUrl;

  const ReorderItem({required this.id, required this.name, this.imageUrl});
}

/// 재정렬 바텀시트 항목 공통 타일 — 드래그 핸들 + 썸네일 + 제목(+선택적 trailing).
/// [ReorderSheet]와 [BoardSettingsSheet](체크박스 추가)가 공유한다.
class ReorderListTile extends StatelessWidget {
  final int index;
  final String? imageUrl;
  final String title;
  final Widget? trailing;

  const ReorderListTile({
    super.key,
    required this.index,
    required this.imageUrl,
    required this.title,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.listDivider, width: 0.5)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Icon(Icons.drag_handle_rounded, color: colors.textSecondary, size: 22),
            ),
            const SizedBox(width: 12),
            AppNetworkImage(
              imageUrl: imageUrl,
              width: 40,
              height: 40,
              errorIcon: Icons.forum_rounded,
              errorIconSize: 20,
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              excludeFromSemantics: true,
            ),
          ],
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: AppDimens.fontSizeMd, fontWeight: FontWeight.w600, color: colors.textTitle),
        ),
        trailing: trailing,
      ),
    );
  }
}

/// 드래그 앤 드롭으로 순서를 변경할 수 있는 바텀시트
class ReorderSheet extends StatefulWidget {
  final String title;
  final String? subtitle;
  final List<ReorderItem> items;
  final void Function(List<int>) onSave;

  const ReorderSheet({
    super.key,
    required this.title,
    this.subtitle,
    required this.items,
    required this.onSave,
  });

  @override
  State<ReorderSheet> createState() => _ReorderSheetState();
}

class _ReorderSheetState extends State<ReorderSheet> {
  late List<ReorderItem> _items;

  @override
  void initState() {
    super.initState();
    _items = List.from(widget.items);
  }

  Widget _buildHeader(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.title,
            style: TextStyle(fontSize: AppDimens.fontSizeXxl, fontWeight: FontWeight.w800, color: colors.textTitle),
          ),
          if (widget.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(widget.subtitle!, style: TextStyle(fontSize: AppDimens.fontSizeSm, color: colors.textSecondary)),
          ],
        ],
      ),
    );
  }

  Widget _buildList() {
    return Flexible(
      child: ReorderableListView.builder(
        itemCount: _items.length,
        onReorderItem: (oldIndex, newIndex) {
          setState(() {
            final item = _items.removeAt(oldIndex);
            _items.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          final item = _items[index];
          return ReorderListTile(
            key: ValueKey(item.id),
            index: index,
            imageUrl: item.imageUrl,
            title: item.name,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DraggableSheetScaffold(
      header: _buildHeader(colors),
      list: _buildList(),
      onConfirm: () {
        final newOrder = _items.map((e) => e.id).toList();
        widget.onSave(newOrder);
        Navigator.of(context).pop(newOrder);
      },
    );
  }
}
