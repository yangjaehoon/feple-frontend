import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// 순서 변경에 사용할 아이템
class ReorderItem {
  final int id;
  final String name;
  final String? imageUrl;

  const ReorderItem({required this.id, required this.name, this.imageUrl});
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

  Widget _buildList(AbstractThemeColors colors) {
    return Flexible(
      child: ReorderableListView.builder(
        itemCount: _items.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = _items.removeAt(oldIndex);
            _items.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          final item = _items[index];
          return Container(
            key: ValueKey(item.id),
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
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                    child: item.imageUrl != null && item.imageUrl!.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: item.imageUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            memCacheWidth: 80,
                            errorWidget: (_, __, ___) => _placeholder(colors),
                          )
                        : _placeholder(colors),
                  ),
                ],
              ),
              title: Text(
                item.name,
                style: TextStyle(fontSize: AppDimens.fontSizeMd, fontWeight: FontWeight.w600, color: colors.textTitle),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConfirmButton(AbstractThemeColors colors) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
      child: LoadingButton(
        label: 'confirm'.tr(),
        isLoading: false,
        backgroundColor: colors.activate,
        onPressed: () {
          widget.onSave(_items.map((e) => e.id).toList());
          Navigator.of(context).pop();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      clipBehavior: Clip.hardEdge,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            const BottomSheetHandle(),
          const SizedBox(height: 16),
          _buildHeader(colors),
          const SizedBox(height: 8),
          Divider(color: colors.listDivider, height: 1),
          _buildList(colors),
          Divider(color: colors.listDivider, height: 1),
          _buildConfirmButton(colors),
        ],
      ),
      ),
    );
  }

  Widget _placeholder(AbstractThemeColors colors) {
    return Container(
      width: 40,
      height: 40,
      color: colors.surface,
      child: Icon(Icons.forum_rounded, color: colors.textSecondary, size: 20),
    );
  }
}
