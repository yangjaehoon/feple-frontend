import 'dart:ui';

import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/screen/main/tab/home/f_all_favorite_boards.dart';
import 'package:feple/screen/main/tab/home/w_boards_section_skeleton.dart';
import 'package:feple/screen/main/tab/home/w_home_section_header.dart';
import 'package:feple/model/favorite_board.dart';
import 'package:feple/screen/main/tab/home/favorite_boards_prefs_manager.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_post_list.dart';
import 'package:feple/screen/main/tab/search/festival_information/s_festival_board.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  late final FavoriteBoardsPrefsManager _prefs;

  @override
  void initState() {
    super.initState();
    _prefs = FavoriteBoardsPrefsManager(widget.userId);
    _loadPrefs();
  }

  @override
  void didUpdateWidget(covariant FavoriteBoardsSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_prefsLoaded) return;

    final oldIds = oldWidget.allBoards.map((b) => b.boardId).toSet();
    final newIds = widget.allBoards.map((b) => b.boardId).toSet();
    // Dart Set은 == 연산자가 identity 비교 → 직접 집합 동등 비교
    if (oldIds.length == newIds.length && oldIds.containsAll(newIds)) return;

    // 기존 선택 목록 중 유효한 것만 유지
    final stillSelected = _orderedSelectedIds.where(newIds.contains).toList();
    // oldIds에 없는 ID만 "진짜 신규" 게시판 — 이전에 비활성화된 게시판은 제외
    final addedIds = widget.allBoards
        .map((b) => b.boardId)
        .where((id) => !oldIds.contains(id))
        .toList();

    setState(() => _orderedSelectedIds = [...stillSelected, ...addedIds]);
  }

  Future<void> _loadPrefs() async {
    final allIds = widget.allBoards.map((b) => b.boardId).toList();
    final ordered = await _prefs.load(allIds);
    if (!mounted) return;
    setState(() {
      _orderedSelectedIds = ordered;
      _prefsLoaded = true;
    });
  }

  Future<void> _savePrefs(List<String> orderedSelected) async {
    final allIds = widget.allBoards.map((b) => b.boardId).toList();
    await _prefs.save(orderedSelected, allIds);
  }

  void _openAllBoards() {
    Navigator.push(
      context,
      SlideRoute(
        builder: (_) => AllFavoriteBoardsPage(
          allBoards: widget.allBoards,
          orderedSelectedIds: _orderedSelectedIds,
          onSave: (newIds) {
            setState(() => _orderedSelectedIds = newIds);
            _savePrefs(newIds);
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (!_prefsLoaded) {
      return const BoardsSectionSkeleton();
    }

    final boardMap = {for (final b in widget.allBoards) b.boardId: b};
    final selectedBoards = _orderedSelectedIds
        .map((id) => boardMap[id])
        .whereType<FavoriteBoard>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        HomeSectionHeader(
          title: 'favorite_boards'.tr(),
          onExpand: widget.allBoards.isNotEmpty ? _openAllBoards : null,
        ),
        _buildBoardList(selectedBoards, colors),
      ],
    );
  }

  Widget _buildBoardList(
      List<FavoriteBoard> selectedBoards, AbstractThemeColors colors) {
    if (selectedBoards.isEmpty) {
      return EmptyState(
        icon: Icons.view_list_rounded,
        title: 'select_boards_prompt'.tr(),
      );
    }
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: selectedBoards.length,
        itemBuilder: (context, index) {
          final board = selectedBoards[index];
          return _BoardTile(board: board);
        },
      ),
    );
  }
}

class _BoardTile extends StatelessWidget {
  final FavoriteBoard board;

  const _BoardTile({required this.board});

  void _navigate(BuildContext context) {
    final isEnglish = context.locale.languageCode == 'en';
    final displayEntityName = board.entityDisplayName(isEnglish);
    final route = switch (board.type) {
      FavoriteBoardType.artist => SlideRoute(
          builder: (_) => ArtistPostListScreen(
            artistId: board.entityId,
            artistName: displayEntityName,
          ),
        ),
      FavoriteBoardType.festival => SlideRoute(
          builder: (_) => FestivalBoardScreen(
            festivalId: board.entityId,
            festivalName: displayEntityName,
          ),
        ),
    };
    Navigator.push(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TapScale(
      onTap: () => _navigate(context),
      child: Container(
        width: 110,
        height: 110,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
          boxShadow: [
            BoxShadow(
              color: colors.cardShadow.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
          child: Stack(
            fit: StackFit.expand,
            children: [
              ..._buildImageLayers(colors),
              _buildNameOverlay(context.locale.languageCode == 'en'),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildImageLayers(AbstractThemeColors colors) => [
        if (board.imageUrl != null && board.imageUrl!.isNotEmpty)
          CachedNetworkImage(
            imageUrl: board.imageUrl!,
            fit: BoxFit.cover,
            memCacheWidth: 220,
            errorWidget: (_, __, ___) => _buildPlaceholder(colors),
          )
        else
          _buildPlaceholder(colors),
      ];

  Widget _buildNameOverlay(bool isEnglish) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.75),
                  Colors.black.withValues(alpha: 0.3),
                ],
              ),
            ),
            child: Text(
              board.displayName(isEnglish),
              style: const TextStyle(
                color: Colors.white,
                fontSize: AppDimens.fontSizeXs,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholder(AbstractThemeColors colors) {
    return Container(
      color: colors.surface,
      child: Icon(Icons.forum_rounded, color: colors.textSecondary, size: 36),
    );
  }
}
