import 'package:feple/common/common.dart';
import 'package:feple/model/favorite_board.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_post_list.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_post_list.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/screen/main/tab/home/w_board_settings_sheet.dart';

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
  String get _orderKey => 'fav_boards_order_${widget.userId}';
  String get _knownKey => 'fav_boards_known_${widget.userId}';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void didUpdateWidget(covariant FavoriteBoardsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_prefsLoaded) return;

    final oldIds = oldWidget.allBoards.map((b) => b.boardId).toSet();
    final newIds = widget.allBoards.map((b) => b.boardId).toSet();
    if (oldIds == newIds) return; // 변화 없으면 무시

    final validIds = newIds;
    // 기존 선택 목록 중 유효한 것만 유지
    final stillSelected =
        _orderedSelectedIds.where(validIds.contains).toList();
    // 새로 추가된 게시판은 끝에 자동 추가
    final knownIds = _orderedSelectedIds.toSet();
    final addedIds = widget.allBoards
        .map((b) => b.boardId)
        .where((id) => !knownIds.contains(id))
        .toList();

    setState(() => _orderedSelectedIds = [...stillSelected, ...addedIds]);
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey);
    final savedOrder = prefs.getStringList(_orderKey);
    final knownIds = prefs.getStringList(_knownKey)?.toSet();
    if (!mounted) return;
    setState(() {
      final validIds = widget.allBoards.map((b) => b.boardId).toSet();

      // 저장 후 새로 좋아요/팔로우한 보드만 자동 추가
      final trulyNewIds = knownIds != null
          ? widget.allBoards
              .map((b) => b.boardId)
              .where((id) => !knownIds.contains(id))
              .toList()
          : <String>[];

      if (saved != null && saved.isNotEmpty) {
        // 선택 목록이 저장되어 있는 경우 (일부만 선택)
        final savedValid = saved.where(validIds.contains).toList();
        _orderedSelectedIds = [...savedValid, ...trulyNewIds];
      } else if (savedOrder != null && savedOrder.isNotEmpty) {
        // 전체 선택 상태이지만 순서가 저장되어 있는 경우
        final orderedValid = savedOrder.where(validIds.contains).toList();
        _orderedSelectedIds = [...orderedValid, ...trulyNewIds];
      } else {
        // 기본값: 좋아요/팔로우한 게시판 전체 표시
        _orderedSelectedIds = widget.allBoards.map((b) => b.boardId).toList();
      }
      _prefsLoaded = true;
    });
  }

  Future<void> _savePrefs(List<String> orderedSelected) async {
    final prefs = await SharedPreferences.getInstance();
    // 순서는 항상 저장
    await prefs.setStringList(_orderKey, orderedSelected);
    // 저장 시점에 알고 있던 모든 보드 ID 기록 (새 보드 자동 추가 판별용)
    final allKnown = widget.allBoards.map((b) => b.boardId).toList();
    await prefs.setStringList(_knownKey, allKnown);
    // 전부 선택된 상태라면 선택 목록은 삭제 (새로 좋아요한 게시판 자동 추가 유지)
    if (orderedSelected.length == widget.allBoards.length) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setStringList(_prefsKey, orderedSelected);
    }
  }

  void _openSettings() {
    // 현재 표시 중인 ID 셋 (체크된 것들)
    final selectedSet = _orderedSelectedIds.toSet();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BoardSettingsSheet(
        allBoards: widget.allBoards,
        initialOrderedIds: List.from(_orderedSelectedIds),
        initialCheckedIds: selectedSet,
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
              color: colors.cardShadow.withValues(alpha: 0.12),
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
                CachedNetworkImage(
                  imageUrl: board.imageUrl!,
                  fit: BoxFit.cover,
                  memCacheWidth: 220,
                  errorWidget: (_, __, ___) => _buildPlaceholder(),
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
                        Colors.black.withValues(alpha: 0.72),
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


