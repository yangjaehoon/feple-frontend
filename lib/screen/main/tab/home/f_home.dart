import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/model/favorite_board.dart';
import 'package:feple/model/followed_artist.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/screen/main/tab/home/w_favorite_boards_section.dart';
import 'package:feple/screen/main/tab/home/w_reorder_sheet.dart';
import 'package:feple/screen/main/tab/search/artist_page/f_artist_page.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/screen/main/tab/search/w_feple_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../provider/like_notifier.dart';
import '../../../../provider/user_provider.dart';

class HomeFragment extends StatefulWidget {
  const HomeFragment({super.key});

  @override
  State<HomeFragment> createState() => _HomeFragmentState();
}

class _HomeFragmentState extends State<HomeFragment> {
  List<FollowedArtist>? _artists;
  List<FestivalModel>? _festivals;

  List<int> _artistOrder = [];
  List<int> _festivalOrder = [];

  List<FavoriteBoard>? _boards;
  int? _userId;
  late LikeNotifier _likeNotifier;
  bool _likeListenerAdded = false;

  String get _artistOrderKey => 'artist_order_$_userId';
  String get _festivalOrderKey => 'festival_order_$_userId';

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (!_likeListenerAdded) {
      _likeNotifier = context.read<LikeNotifier>();
      _likeNotifier.addListener(_refresh);
      _likeListenerAdded = true;
    }

    final user = context.read<UserProvider>().user;
    if (user != null && _userId != user.id) {
      _userId = user.id;
      _boards = null;
      _loadData();
    }
  }

  @override
  void dispose() {
    _likeNotifier.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _loadData() async {
    // 순서 로드를 배치로 처리 (setState 2번 → 1번)
    final orders = await Future.wait([
      _loadArtistOrder(),
      _loadFestivalOrder(),
    ]);
    if (!mounted) return;
    setState(() {
      if (orders[0] != null) _artistOrder = orders[0]!;
      if (orders[1] != null) _festivalOrder = orders[1]!;
    });

    // 데이터 로드를 배치로 처리 (setState 3번 → 1번)
    try {
      final data = await Future.wait([
        _fetchArtists(_userId!),
        _fetchFestivals(_userId!),
      ]);
      if (!mounted) return;
      final artists = data[0] as List<FollowedArtist>;
      final festivals = data[1] as List<FestivalModel>;
      setState(() {
        _artists = artists;
        _festivals = festivals;
        _boards = _buildBoards(artists, festivals);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _artists = _artists ?? [];
        _festivals = _festivals ?? [];
        _boards ??= [];
      });
    }
  }

  Future<List<int>?> _loadArtistOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_artistOrderKey);
    return saved?.map(int.parse).toList();
  }

  Future<List<int>?> _loadFestivalOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_festivalOrderKey);
    return saved?.map(int.parse).toList();
  }

  Future<void> _saveArtistOrder(List<int> order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _artistOrderKey, order.map((e) => e.toString()).toList());
  }

  Future<void> _saveFestivalOrder(List<int> order) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _festivalOrderKey, order.map((e) => e.toString()).toList());
  }

  Future<List<FollowedArtist>> _fetchArtists(int userId) async {
    final resp = await DioClient.dio.get('/users/$userId/following');
    return (resp.data as List).map((e) => FollowedArtist.fromJson(e)).toList();
  }

  Future<List<FestivalModel>> _fetchFestivals(int userId) async {
    final resp = await DioClient.dio.get('/users/$userId/liked-festivals');
    return (resp.data as List).map((e) => FestivalModel.fromJson(e)).toList();
  }

  List<FavoriteBoard> _buildBoards(
      List<FollowedArtist> artists, List<FestivalModel> festivals) {
    return [
      ...artists.map((a) => FavoriteBoard(
            boardId: 'artist_${a.id}',
            type: 'artist',
            entityId: a.id,
            entityName: a.name,
            imageUrl: a.profileImageUrl,
          )),
      ...festivals.map((f) => FavoriteBoard(
            boardId: 'festival_${f.id}',
            type: 'festival',
            entityId: f.id,
            entityName: f.title,
            imageUrl: f.posterUrl,
          )),
    ];
  }

  List<T> _applyOrder<T>(
      List<T> items, List<int> order, int Function(T) getId) {
    if (order.isEmpty) return items;
    final map = {for (final item in items) getId(item): item};
    final ordered = order.where(map.containsKey).map((id) => map[id]!).toList();
    final orderedIds = order.toSet();
    final rest =
        items.where((item) => !orderedIds.contains(getId(item))).toList();
    return [...ordered, ...rest];
  }

  void _refresh() {
    if (_userId == null || !mounted) return;
    setState(() {
      _artists = null;
      _festivals = null;
      _boards = null;
    });
    _loadData();
  }

  void _openArtistOrderSettings() {
    final artists = _artists;
    if (artists == null || artists.isEmpty) return;
    final items = _applyOrder(artists, _artistOrder, (a) => a.id)
        .map((a) =>
            ReorderItem(id: a.id, name: a.name, imageUrl: a.profileImageUrl))
        .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReorderSheet(
        title: 'followed_artists'.tr(),
        items: items,
        onSave: (newOrder) {
          setState(() => _artistOrder = newOrder);
          _saveArtistOrder(newOrder);
        },
      ),
    );
  }

  void _openFestivalOrderSettings() {
    final festivals = _festivals;
    if (festivals == null || festivals.isEmpty) return;
    final items = _applyOrder(festivals, _festivalOrder, (f) => f.id)
        .map(
            (f) => ReorderItem(id: f.id, name: f.title, imageUrl: f.posterUrl))
        .toList();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => ReorderSheet(
        title: 'liked_festivals'.tr(),
        items: items,
        onSave: (newOrder) {
          setState(() => _festivalOrder = newOrder);
          _saveFestivalOrder(newOrder);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final colors = context.appColors;

    if (_userId == null) {
      return Container(
        color: colors.backgroundMain,
        child: Center(
            child: CircularProgressIndicator(color: colors.loadingIndicator)),
      );
    }

    final artists = _artists == null
        ? null
        : _applyOrder(_artists!, _artistOrder, (a) => a.id);
    final festivals = _festivals == null
        ? null
        : _applyOrder(_festivals!, _festivalOrder, (f) => f.id);

    return Container(
      color: colors.backgroundMain,
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: rs.h(AppDimens.scrollPaddingTop),
              bottom: rs.h(AppDimens.scrollPaddingBottom),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionHeader(
                  title: 'followed_artists'.tr(),
                  onSettings: _artists != null && _artists!.isNotEmpty
                      ? _openArtistOrderSettings
                      : null,
                ),
                _ArtistsSection(
                  artists: artists,
                  onTap: (artist) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ArtistPage(
                        artistId: artist.id,
                        artistName: artist.name,
                        followerCounter: 0,
                      ),
                    ),
                  ).then((_) => _refresh()),
                ),
                const SizedBox(height: 8),
                _SectionHeader(
                  title: 'liked_festivals'.tr(),
                  onSettings: _festivals != null && _festivals!.isNotEmpty
                      ? _openFestivalOrderSettings
                      : null,
                ),
                _FestivalsSection(
                  festivals: festivals,
                  onTap: (festival) => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          FestivalInformationFragment(poster: festival),
                    ),
                  ).then((_) => _refresh()),
                ),
                const SizedBox(height: 8),
                if (_boards == null)
                  const SizedBox(height: 150)
                else
                  FavoriteBoardsSection(
                    allBoards: _boards!,
                    userId: _userId!,
                  ),
              ],
            ),
          ),
          const FepleAppBar("Feple"),
        ],
      ),
    );
  }
}

// ── 섹션 헤더 ──────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.onSettings});

  final String title;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 16, onSettings != null ? 8 : 20, 8),
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
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.textTitle,
            ),
          ),
          if (onSettings != null) ...[
            const Spacer(),
            IconButton(
              icon: Icon(Icons.settings_rounded,
                  color: colors.textSecondary, size: 20),
              onPressed: onSettings,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
            const SizedBox(width: 12),
          ],
        ],
      ),
    );
  }
}

// ── 팔로우 아티스트 섹션 ──────────────────────────────────────────────────

class _ArtistsSection extends StatelessWidget {
  const _ArtistsSection({required this.artists, required this.onTap});

  final List<FollowedArtist>? artists;
  final void Function(FollowedArtist) onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (artists == null) {
      return SizedBox(
        height: 110,
        child: Center(
            child: CircularProgressIndicator(color: colors.loadingIndicator)),
      );
    }
    if (artists!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text('no_followed_artists'.tr(),
            style: TextStyle(color: colors.textSecondary)),
      );
    }
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: artists!.length,
        itemBuilder: (_, index) => _ArtistItem(
          key: ValueKey(artists![index].id),
          artist: artists![index],
          onTap: onTap,
        ),
      ),
    );
  }
}

class _ArtistItem extends StatelessWidget {
  const _ArtistItem({
    super.key,
    required this.artist,
    required this.onTap,
  });

  final FollowedArtist artist;
  final void Function(FollowedArtist) onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: () => onTap(artist),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colors.followRingColor,
                boxShadow: [
                  BoxShadow(
                    color: colors.cardShadow.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                    shape: BoxShape.circle, color: colors.surface),
                child: CircleAvatar(
                  radius: 32,
                  backgroundColor: colors.backgroundMain,
                  backgroundImage: (artist.profileImageUrl != null &&
                          artist.profileImageUrl!.isNotEmpty)
                      ? CachedNetworkImageProvider(
                          artist.profileImageUrl!,
                          maxWidth: 150)
                      : null,
                  child: (artist.profileImageUrl == null ||
                          artist.profileImageUrl!.isEmpty)
                      ? Icon(Icons.person_rounded,
                          size: 28, color: colors.textSecondary)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: 64,
              child: Text(
                artist.name,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textTitle),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 좋아요한 페스티벌 섹션 ────────────────────────────────────────────────

class _FestivalsSection extends StatelessWidget {
  const _FestivalsSection({required this.festivals, required this.onTap});

  final List<FestivalModel>? festivals;
  final void Function(FestivalModel) onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    if (festivals == null) {
      return SizedBox(
        height: 160,
        child: Center(
            child: CircularProgressIndicator(color: colors.loadingIndicator)),
      );
    }
    if (festivals!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text('no_liked_festivals'.tr(),
            style: TextStyle(color: colors.textSecondary)),
      );
    }
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: festivals!.length,
        itemBuilder: (_, index) => _FestivalItem(
          key: ValueKey(festivals![index].id),
          festival: festivals![index],
          onTap: onTap,
        ),
      ),
    );
  }
}

class _FestivalItem extends StatelessWidget {
  const _FestivalItem({
    super.key,
    required this.festival,
    required this.onTap,
  });

  final FestivalModel festival;
  final void Function(FestivalModel) onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: () => onTap(festival),
      child: Container(
        width: 130,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors.cardShadow.withValues(alpha: 0.12),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: festival.posterUrl,
                memCacheWidth: 260,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Container(
                  color: colors.surface,
                  child: Icon(Icons.image_not_supported_rounded,
                      color: colors.textSecondary),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withValues(alpha: 0.7),
                        Colors.transparent
                      ],
                    ),
                  ),
                  child: Text(
                    festival.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
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
}
