import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/widget/w_selectable_chip.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/model/favorite_board.dart';
import 'package:feple/screen/main/tab/home/w_board_settings_sheet.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_post_list.dart';
import 'package:feple/screen/main/tab/search/festival_information/s_festival_board.dart';
import 'package:flutter/material.dart';

class AllFavoriteBoardsScreen extends StatefulWidget {
  final List<FavoriteBoard> allBoards;
  final List<String> orderedSelectedIds;
  final void Function(List<String>) onSave;

  const AllFavoriteBoardsScreen({
    super.key,
    required this.allBoards,
    required this.orderedSelectedIds,
    required this.onSave,
  });

  @override
  State<AllFavoriteBoardsScreen> createState() => _AllFavoriteBoardsScreenState();
}

class _AllFavoriteBoardsScreenState extends State<AllFavoriteBoardsScreen> {
  late List<String> _orderedSelectedIds;
  FavoriteBoardType? _selectedType;
  bool _isSheetOpen = false;

  List<FavoriteBoard> get _selectedBoards {
    final boardMap = {for (final b in widget.allBoards) b.boardId: b};
    return _orderedSelectedIds
        .map((id) => boardMap[id])
        .whereType<FavoriteBoard>()
        .toList();
  }

  List<FavoriteBoard> get _filteredBoards {
    final boards = _selectedBoards;
    if (_selectedType == null) return boards;
    return boards.where((b) => b.type == _selectedType).toList();
  }

  @override
  void initState() {
    super.initState();
    _orderedSelectedIds = List.from(widget.orderedSelectedIds);
  }

  void _openSettings() {
    if (_isSheetOpen) return;
    _isSheetOpen = true;
    final selectedSet = _orderedSelectedIds.toSet();
    showAppBottomSheet(
      context,
      builder: (_) => BoardSettingsSheet(
        allBoards: widget.allBoards,
        initialOrderedIds: List.from(_orderedSelectedIds),
        initialCheckedIds: selectedSet,
        onSave: (newIds) {
          setState(() => _orderedSelectedIds = newIds);
          widget.onSave(newIds);
        },
      ),
    ).whenComplete(() { if (mounted) _isSheetOpen = false; });
  }

  void _navigateToBoard(FavoriteBoard board) {
    final isEnglish = context.isEnglish;
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
    final boards = _selectedBoards;
    final hasArtist = boards.any((b) => b.type == FavoriteBoardType.artist);
    final hasFestival = boards.any((b) => b.type == FavoriteBoardType.festival);
    final showChips = hasArtist && hasFestival;

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
      body: boards.isEmpty
          ? Center(
              child: EmptyState(
                icon: Icons.forum_rounded,
                title: 'select_boards_prompt'.tr(),
              ),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (showChips) _buildTypeChips(colors),
                Expanded(child: _buildGrid(colors)),
              ],
            ),
    );
  }

  Widget _buildTypeChips(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 4),
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [
            SelectableChip(
              label: 'filter_all'.tr(),
              selected: _selectedType == null,
              onTap: () => setState(() => _selectedType = null),
            ),
            SelectableChip(
              label: 'artist_boards_section'.tr(),
              selected: _selectedType == FavoriteBoardType.artist,
              onTap: () => setState(() => _selectedType = FavoriteBoardType.artist),
            ),
            SelectableChip(
              label: 'festival_boards_section'.tr(),
              selected: _selectedType == FavoriteBoardType.festival,
              onTap: () => setState(() => _selectedType = FavoriteBoardType.festival),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(AbstractThemeColors colors) {
    final boards = _filteredBoards;
    if (boards.isEmpty) {
      return Center(
        child: EmptyState(icon: Icons.forum_rounded, title: 'select_boards_prompt'.tr()),
      );
    }
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
        onTap: () => _navigateToBoard(boards[index]),
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
    return TapScale(
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
              _buildNameOverlay(context.isEnglish),
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
            fadeInDuration: AppDimens.animXFast,
            fadeOutDuration: AppDimens.animTapFeedback,
            placeholder: (_, __) => _placeholder(colors),
            errorWidget: (_, __, ___) => _placeholder(colors),
          )
        else
          _placeholder(colors),
      ];

  Widget _buildNameOverlay(bool isEnglish) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [
              Colors.black.withValues(alpha: 0.82),
              Colors.black.withValues(alpha: 0.0),
            ],
          ),
        ),
        child: Text(
          board.displayName(isEnglish),
          style: const TextStyle(
            color: Colors.white,
            fontSize: AppDimens.fontSizeSm,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
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
