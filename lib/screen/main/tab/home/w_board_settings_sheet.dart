import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/model/favorite_board.dart';
import 'package:flutter/material.dart';

// ── 설정 바텀시트 ──

class BoardSettingsSheet extends StatefulWidget {
  final List<FavoriteBoard> allBoards;
  final List<String> initialOrderedIds;
  final Set<String> initialCheckedIds;
  final void Function(List<String>) onSave;

  const BoardSettingsSheet({
    super.key,
    required this.allBoards,
    required this.initialOrderedIds,
    required this.initialCheckedIds,
    required this.onSave,
  });

  @override
  State<BoardSettingsSheet> createState() => _BoardSettingsSheetState();
}

class _BoardSettingsSheetState extends State<BoardSettingsSheet> {
  late List<FavoriteBoard> _orderedBoards;
  late Set<String> _checked;

  @override
  void initState() {
    super.initState();
    _checked = Set.from(widget.initialCheckedIds);

    // 선택된 보드(저장된 순서) → 미선택 보드 순으로 정렬
    final selectedInOrder = widget.initialOrderedIds
        .map((id) => widget.allBoards.firstWhereOrNull((b) => b.boardId == id))
        .whereType<FavoriteBoard>()
        .toList();

    final unselected =
        widget.allBoards.where((b) => !_checked.contains(b.boardId)).toList();

    _orderedBoards = [...selectedInOrder, ...unselected];
  }

  Widget _buildTitleRow(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Text(
            'select_boards'.tr(),
            style: TextStyle(fontSize: AppDimens.fontSizeXxl, fontWeight: FontWeight.w800, color: colors.textTitle),
          ),
          const Spacer(),
          Text(
            '${_checked.length}/${_orderedBoards.length}',
            style: TextStyle(fontSize: 13, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardList(AbstractThemeColors colors) {
    return Flexible(
      child: ReorderableListView.builder(
        shrinkWrap: true,
        itemCount: _orderedBoards.length,
        onReorder: (oldIndex, newIndex) {
          setState(() {
            if (newIndex > oldIndex) newIndex--;
            final item = _orderedBoards.removeAt(oldIndex);
            _orderedBoards.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          final board = _orderedBoards[index];
          final checked = _checked.contains(board.boardId);
          return _BoardSettingsItem(
            key: ValueKey(board.boardId),
            board: board,
            checked: checked,
            index: index,
            onChanged: (val) {
              setState(() {
                if (val == true) {
                  _checked.add(board.boardId);
                } else {
                  _checked.remove(board.boardId);
                }
              });
            },
          );
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
          _buildTitleRow(colors),
          const SizedBox(height: 8),
          Divider(color: colors.listDivider, height: 1),
          _buildBoardList(colors),
          Divider(color: colors.listDivider, height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
            child: LoadingButton(
              label: 'confirm'.tr(),
              isLoading: false,
              backgroundColor: colors.activate,
              onPressed: () {
                final orderedSelected = _orderedBoards
                    .where((b) => _checked.contains(b.boardId))
                    .map((b) => b.boardId)
                    .toList();
                widget.onSave(orderedSelected);
                Navigator.of(context).pop();
              },
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class _BoardSettingsItem extends StatelessWidget {
  final FavoriteBoard board;
  final bool checked;
  final int index;
  final ValueChanged<bool?> onChanged;

  const _BoardSettingsItem({
    super.key,
    required this.board,
    required this.checked,
    required this.index,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colors.listDivider, width: 0.5),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16),
        leading: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ReorderableDragStartListener(
              index: index,
              child: Icon(Icons.drag_handle_rounded,
                  color: colors.textSecondary, size: 22),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              child: board.imageUrl != null && board.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: board.imageUrl!,
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
          board.displayName(context.locale.languageCode == 'en'),
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: colors.textTitle,
          ),
        ),
        trailing: Checkbox(
          value: checked,
          onChanged: onChanged,
          activeColor: colors.activate,
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
