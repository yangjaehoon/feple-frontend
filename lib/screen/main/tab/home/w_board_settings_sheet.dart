import 'package:collection/collection.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_draggable_sheet_scaffold.dart';
import 'package:feple/model/favorite_board.dart';
import 'package:feple/screen/main/tab/home/w_reorder_sheet.dart';
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
            style: TextStyle(fontSize: AppDimens.fontSizeSm, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildBoardList() {
    return Flexible(
      child: ReorderableListView.builder(
        itemCount: _orderedBoards.length,
        onReorderItem: (oldIndex, newIndex) {
          setState(() {
            final item = _orderedBoards.removeAt(oldIndex);
            _orderedBoards.insert(newIndex, item);
          });
        },
        itemBuilder: (context, index) {
          final board = _orderedBoards[index];
          final checked = _checked.contains(board.boardId);
          return ReorderListTile(
            key: ValueKey(board.boardId),
            index: index,
            imageUrl: board.imageUrl,
            title: 'favorite_board_name'.tr(args: [board.entityDisplayName(context.isEnglish)]),
            trailing: Checkbox(
              value: checked,
              onChanged: (val) {
                setState(() {
                  if (val == true) {
                    _checked.add(board.boardId);
                  } else {
                    _checked.remove(board.boardId);
                  }
                });
              },
              activeColor: context.appColors.activate,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DraggableSheetScaffold(
      header: _buildTitleRow(colors),
      list: _buildBoardList(),
      onConfirm: () {
        final orderedSelected = _orderedBoards
            .where((b) => _checked.contains(b.boardId))
            .map((b) => b.boardId)
            .toList();
        widget.onSave(orderedSelected);
        Navigator.of(context).pop();
      },
    );
  }
}
