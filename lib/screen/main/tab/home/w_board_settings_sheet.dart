import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
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
        .map((id) {
          try {
            return widget.allBoards.firstWhere((b) => b.boardId == id);
          } catch (_) {
            return null;
          }
        })
        .whereType<FavoriteBoard>()
        .toList();

    final unselected =
        widget.allBoards.where((b) => !_checked.contains(b.boardId)).toList();

    _orderedBoards = [...selectedInOrder, ...unselected];
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final maxHeight = MediaQuery.of(context).size.height * 0.75;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 핸들
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // 타이틀
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'select_boards'.tr(),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.textTitle,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_checked.length}/${_orderedBoards.length}',
                  style: TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: colors.listDivider, height: 1),

          // 드래그 가능한 목록
          Flexible(
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
                  colors: colors,
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
          ),

          // 확인 버튼
          Divider(color: colors.listDivider, height: 1),
          Padding(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, 12 + MediaQuery.of(context).padding.bottom),
            child: SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  final orderedSelected = _orderedBoards
                      .where((b) => _checked.contains(b.boardId))
                      .map((b) => b.boardId)
                      .toList();
                  widget.onSave(orderedSelected);
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.activate,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'confirm'.tr(),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BoardSettingsItem extends StatelessWidget {
  final FavoriteBoard board;
  final bool checked;
  final int index;
  final AbstractThemeColors colors;
  final ValueChanged<bool?> onChanged;

  const _BoardSettingsItem({
    super.key,
    required this.board,
    required this.checked,
    required this.index,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
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
              borderRadius: BorderRadius.circular(8),
              child: board.imageUrl != null && board.imageUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: board.imageUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      memCacheWidth: 80,
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
          ],
        ),
        title: Text(
          board.displayName,
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

  Widget _placeholder() {
    return Container(
      width: 40,
      height: 40,
      color: colors.surface,
      child: Icon(Icons.forum_rounded, color: colors.textSecondary, size: 20),
    );
  }
}
