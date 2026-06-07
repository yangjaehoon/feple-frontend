import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/model/favorite_board.dart';
import 'package:feple/screen/main/tab/home/w_board_settings_sheet.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_post_list.dart';
import 'package:feple/screen/main/tab/search/festival_information/s_festival_board.dart';
import 'package:flutter/material.dart';

class AllFavoriteBoardsPage extends StatefulWidget {
  final List<FavoriteBoard> allBoards;
  final List<String> orderedSelectedIds;
  final void Function(List<String>) onSave;

  const AllFavoriteBoardsPage({
    super.key,
    required this.allBoards,
    required this.orderedSelectedIds,
    required this.onSave,
  });

  @override
  State<AllFavoriteBoardsPage> createState() => _AllFavoriteBoardsPageState();
}

class _AllFavoriteBoardsPageState extends State<AllFavoriteBoardsPage> {
  late List<String> _orderedSelectedIds;

  @override
  void initState() {
    super.initState();
    _orderedSelectedIds = List.from(widget.orderedSelectedIds);
  }

  void _openSettings() {
    final selectedSet = _orderedSelectedIds.toSet();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => BoardSettingsSheet(
        allBoards: widget.allBoards,
        initialOrderedIds: List.from(_orderedSelectedIds),
        initialCheckedIds: selectedSet,
        onSave: (newIds) {
          setState(() => _orderedSelectedIds = newIds);
          widget.onSave(newIds);
        },
      ),
    );
  }

  void _navigateToBoard(BuildContext context, FavoriteBoard board) {
    final route = switch (board.type) {
      FavoriteBoardType.artist => SlideRoute(
          builder: (_) => ArtistPostListScreen(
            artistId: board.entityId,
            artistName: board.entityName,
          ),
        ),
      FavoriteBoardType.festival => SlideRoute(
          builder: (_) => FestivalBoardScreen(
            festivalId: board.entityId,
            festivalName: board.entityName,
          ),
        ),
    };
    Navigator.push(context, route);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final boardMap = {for (final b in widget.allBoards) b.boardId: b};
    final selectedBoards = _orderedSelectedIds
        .map((id) => boardMap[id])
        .whereType<FavoriteBoard>()
        .toList();

    return Scaffold(
      backgroundColor: colors.backgroundMain,
      appBar: SecondaryAppBar(
        title: 'favorite_boards'.tr(),
        actions: [
          IconButton(
            tooltip: 'settings'.tr(),
            icon: const Icon(Icons.settings_rounded, size: 20),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: selectedBoards.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.forum_rounded,
                title: 'select_boards_prompt'.tr(),
              ),
            )
          : _buildGrid(selectedBoards, colors),
    );
  }

  Widget _buildGrid(List<FavoriteBoard> boards, AbstractThemeColors colors) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: boards.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1.0,
      ),
      itemBuilder: (_, index) => _GridBoardTile(
        board: boards[index],
        onTap: () => _navigateToBoard(context, boards[index]),
      ),
    );
  }
}

class _GridBoardTile extends StatelessWidget {
  final FavoriteBoard board;
  final VoidCallback onTap;

  const _GridBoardTile({required this.board, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
          boxShadow: [
            BoxShadow(
              color: colors.cardShadow.withValues(alpha: 0.12),
              blurRadius: 10,
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
              _buildNameOverlay(),
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
            memCacheWidth: 350,
            errorWidget: (_, __, ___) => _placeholder(colors),
          )
        else
          _placeholder(colors),
      ];

  Widget _buildNameOverlay() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
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
              board.displayName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
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

  Widget _placeholder(AbstractThemeColors colors) {
    return Container(
      color: colors.surface,
      child: Icon(Icons.forum_rounded, color: colors.textSecondary, size: 48),
    );
  }
}
