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
  Set<String> _selectedIds = {};
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
      _selectedIds = saved == null
          ? widget.allBoards.map((b) => b.boardId).toSet()
          : saved.toSet();
      _prefsLoaded = true;
    });
  }

  Future<void> _savePrefs(Set<String> selected) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_prefsKey, selected.toList());
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
        initialSelected: Set.from(_selectedIds),
        onSave: (newSelected) {
          setState(() => _selectedIds = newSelected);
          _savePrefs(newSelected);
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

    final selectedBoards = widget.allBoards
        .where((b) => _selectedIds.contains(b.boardId))
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
                '즐겨찾는 게시판',
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
              '표시할 게시판을 선택해주세요.',
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
              // 이미지 or 기본 배경
              if (board.imageUrl != null && board.imageUrl!.isNotEmpty)
                Image.network(
                  board.imageUrl!,
                  fit: BoxFit.cover,
                  cacheWidth: 220,
                  errorBuilder: (_, __, ___) => _buildPlaceholder(),
                )
              else
                _buildPlaceholder(),

              // 하단 그라디언트 오버레이
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
  final Set<String> initialSelected;
  final void Function(Set<String>) onSave;

  const _BoardSettingsSheet({
    required this.allBoards,
    required this.initialSelected,
    required this.onSave,
  });

  @override
  State<_BoardSettingsSheet> createState() => _BoardSettingsSheetState();
}

class _BoardSettingsSheetState extends State<_BoardSettingsSheet> {
  late Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set.from(widget.initialSelected);
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
                  '게시판 선택',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: colors.textTitle,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_selected.length}/${widget.allBoards.length}',
                  style:
                      TextStyle(fontSize: 13, color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Divider(color: colors.listDivider, height: 1),

          // 목록
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: widget.allBoards.length,
              separatorBuilder: (_, __) =>
                  Divider(color: colors.listDivider, height: 1),
              itemBuilder: (_, index) {
                final board = widget.allBoards[index];
                final checked = _selected.contains(board.boardId);
                return CheckboxListTile(
                  value: checked,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selected.add(board.boardId);
                      } else {
                        _selected.remove(board.boardId);
                      }
                    });
                  },
                  activeColor: colors.activate,
                  title: Text(
                    board.displayName,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colors.textTitle,
                    ),
                  ),
                  secondary: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: board.imageUrl != null && board.imageUrl!.isNotEmpty
                        ? Image.network(
                            board.imageUrl!,
                            width: 40,
                            height: 40,
                            fit: BoxFit.cover,
                            cacheWidth: 80,
                            errorBuilder: (_, __, ___) => _placeholder(colors),
                          )
                        : _placeholder(colors),
                  ),
                  controlAffinity: ListTileControlAffinity.trailing,
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
                  widget.onSave(Set.from(_selected));
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
                child: const Text(
                  '확인',
                  style: TextStyle(
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

  Widget _placeholder(AbstractThemeColors colors) {
    return Container(
      width: 40,
      height: 40,
      color: colors.surface,
      child: Icon(Icons.forum_rounded, color: colors.textSecondary, size: 20),
    );
  }
}
