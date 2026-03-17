import 'package:easy_localization/easy_localization.dart';
import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/model/favorite_board.dart';
import 'package:fast_app_base/screen/main/tab/search/artist_page/w_artist_post_list.dart';
import 'package:fast_app_base/screen/main/tab/search/concert_information/w_festival_post_list.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteBoardsSection extends StatefulWidget {
  final List<FavoriteBoard> allBoards;
  final int userId;

  const FavoriteBoardsSection({
    super.key,
    required this.allBoards,
    required this.userId,
  });

  @override
  State<FavoriteBoardsSection> createState() => _FavoriteBoardsSectionState();
}

class _FavoriteBoardsSectionState extends State<FavoriteBoardsSection> {
  List<String> _orderedSelectedIds = [];
  bool _prefsLoaded = false;

  String get _prefsKey => 'fav_boards_${widget.userId}';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey);
    if (!mounted) return;
    setState(() {
      if (saved == null) {
        _orderedSelectedIds = widget.allBoards.map((b) => b.boardId).toList();
      } else {
        final validIds = widget.allBoards.map((b) => b.boardId).toSet();
        _orderedSelectedIds = saved.where((id) => validIds.contains(id)).toList();
      }
      _prefsLoaded = true;
    });
  }

  Future<void> _savePrefs(List<String> orderedSelected) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, orderedSelected);
  }

  void _openSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _BoardSettingsSheet(
        allBoards: widget.allBoards,
        initialOrderedIds: List.from(_orderedSelectedIds),
        onSave: (newOrderedIds) {
          setState(() => _orderedSelectedIds = newOrderedIds);
          _savePrefs(newOrderedIds);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (!_prefsLoaded) {
      return const SizedBox(height: 150);
    }

    final selectedBoards = _orderedSelectedIds
        .map((id) {
          try {
            return widget.allBoards.firstWhere((b) => b.boardId == id);
          } catch (_) {
            return null;
          }
        })
        .whereType<FavoriteBoard>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 섹션 헤더
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 8, 8),
          child: Row(
            children: [
              Container(
                width: 3,
                height: 20,
                decoration: BoxDecoration(
                  color: colors.sectionBarColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'favorite_boards'.tr(),
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: colors.textTitle,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: Icon(Icons.settings_rounded,
                    color: colors.textSecondary, size: 20),
                onPressed: _openSettings,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(width: 12),
            ],
          ),
        ),

        // 가로 스크롤 타일
        if (selectedBoards.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Text(
              'select_boards_prompt'.tr(),
              style: TextStyle(color: colors.textSecondary),
            ),
          )
        else
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: selectedBoards.length,
              itemBuilder: (context, index) {
                final board = selectedBoards[index];
                return _BoardTile(board: board, colors: colors);
              },
            ),
          ),
      ],
    );
  }
}

class _BoardTile extends StatelessWidget {
  final FavoriteBoard board;
  final AbstractThemeColors colors;

  const _BoardTile({required this.board, required this.colors});

  void _navigate(BuildContext context) {
    if (board.type == 'artist') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ArtistPostListScreen(
            artistId: board.entityId,
            artistName: board.entityName,
          ),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FestivalPostListScreen(
            festivalId: board.entityId,
            festivalName: board.entityName,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _navigate(context),
      child: Container(
        width: 110,
        height: 110,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: colors.cardShadow.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (board.imageUrl != null && board.imageUrl!.isNotEmpty)
                Image.network(
                  board.imageUrl!,
                  fit: BoxFit.cover,
                  cacheWidth: 220,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                )
              else
                _buildPlaceholder(),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.72),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Text(
                    board.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      color: colors.surface,
      child: Icon(Icons.forum_rounded, color: colors.textSecondary, size: 36),
    );
  }
}

// ── 설정 바텀시트 ──

class _BoardSettingsSheet extends StatefulWidget {
  final List<FavoriteBoard> allBoards;
  final List<String> initialOrderedIds;
  final void Function(List<String>) onSave;

  const _BoardSettingsSheet({
    required this.allBoards,
    required this.initialOrderedIds,
    required this.onSave,
  });

  @override
  State<_BoardSettingsSheet> createState() => _BoardSettingsSheetState();
}

class _BoardSettingsSheetState extends State<_BoardSettingsSheet> {
  late List<FavoriteBoard> _orderedBoards;
  late Set<String> _checked;

  @override
  void initState() {
    super.initState();
    _checked = Set.from(widget.initialOrderedIds);

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

    final unselected = widget.allBoards
        .where((b) => !_checked.contains(b.boardId))
        .toList();

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
                  ? Image.network(
                      board.imageUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      cacheWidth: 80,
                      errorBuilder: (_, __, ___) => _placeholder(),
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
