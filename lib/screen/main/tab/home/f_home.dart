import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_dimensions.dart';
import 'package:fast_app_base/common/util/responsive_size.dart';
import 'package:fast_app_base/model/favorite_board.dart';
import 'package:fast_app_base/model/followed_artist.dart';
import 'package:fast_app_base/model/poster_model.dart';
import 'package:fast_app_base/network/dio_client.dart';
import 'package:fast_app_base/screen/main/tab/home/w_favorite_boards_section.dart';
import 'package:fast_app_base/screen/main/tab/home/w_reorder_sheet.dart';
import 'package:fast_app_base/screen/main/tab/search/artist_page/f_artist_page.dart';
import 'package:fast_app_base/screen/main/tab/search/concert_information/f_festival_information.dart';
import 'package:fast_app_base/screen/main/tab/search/w_feple_app_bar.dart';
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
  List<PosterModel>? _festivals;

  List<int> _artistOrder = [];
  List<int> _festivalOrder = [];

  late Future<List<FavoriteBoard>> _boardsFuture;
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
      _boardsFuture = Future.value([]);
      _loadData();
    }
  }

  @override
  void dispose() {
    _likeNotifier.removeListener(_refresh);
    super.dispose();
  }

  Future<void> _loadData() async {
    await Future.wait([
      _loadArtistOrder(),
      _loadFestivalOrder(),
    ]);
    await Future.wait([
      _fetchAndSetArtists(),
      _fetchAndSetFestivals(),
    ]);
  }

  Future<void> _loadArtistOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_artistOrderKey);
    if (saved != null && mounted) {
      setState(() => _artistOrder = saved.map(int.parse).toList());
    }
  }

  Future<void> _loadFestivalOrder() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_festivalOrderKey);
    if (saved != null && mounted) {
      setState(() => _festivalOrder = saved.map(int.parse).toList());
    }
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

  Future<void> _fetchAndSetArtists() async {
    try {
      final data = await _fetchArtists(_userId!);
      if (!mounted) return;
      setState(() => _artists = data);
      _maybeUpdateBoards();
    } catch (_) {
      if (mounted) setState(() => _artists = []);
    }
  }

  Future<void> _fetchAndSetFestivals() async {
    try {
      final data = await _fetchFestivals(_userId!);
      if (!mounted) return;
      setState(() => _festivals = data);
      _maybeUpdateBoards();
    } catch (_) {
      if (mounted) setState(() => _festivals = []);
    }
  }

  void _maybeUpdateBoards() {
    if (_artists != null && _festivals != null) {
      setState(() {
        _boardsFuture = Future.value(_buildBoards(_artists!, _festivals!));
      });
    }
  }

  void _refresh() {
    if (_userId == null || !mounted) return;
    setState(() {
      _artists = null;
      _festivals = null;
    });
    _fetchAndSetArtists();
    _fetchAndSetFestivals();
  }

  Future<List<FollowedArtist>> _fetchArtists(int userId) async {
    final resp = await DioClient.dio.get('/users/$userId/following');
    return (resp.data as List).map((e) => FollowedArtist.fromJson(e)).toList();
  }

  Future<List<PosterModel>> _fetchFestivals(int userId) async {
    final resp = await DioClient.dio.get('/users/$userId/liked-festivals');
    return (resp.data as List).map((e) => PosterModel.fromJson(e)).toList();
  }

  List<FavoriteBoard> _buildBoards(
      List<FollowedArtist> artists, List<PosterModel> festivals) {
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

  // 저장된 순서 적용: order에 있는 id 순 → 나머지 뒤에 추가
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
                _buildSectionHeader(
                  'followed_artists'.tr(),
                  colors,
                  onSettings: _artists != null && _artists!.isNotEmpty
                      ? _openArtistOrderSettings
                      : null,
                ),
                _buildArtistsSection(colors),
                const SizedBox(height: 8),
                _buildSectionHeader(
                  'liked_festivals'.tr(),
                  colors,
                  onSettings: _festivals != null && _festivals!.isNotEmpty
                      ? _openFestivalOrderSettings
                      : null,
                ),
                _buildFestivalsSection(colors),
                const SizedBox(height: 8),
                FutureBuilder<List<FavoriteBoard>>(
                  future: _boardsFuture,
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) return const SizedBox(height: 150);
                    return FavoriteBoardsSection(
                      allBoards: snapshot.data!,
                      userId: _userId!,
                    );
                  },
                ),
              ],
            ),
          ),
          const FepleAppBar("Feple"),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, AbstractThemeColors colors,
      {VoidCallback? onSettings}) {
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

  // ── 팔로우 아티스트 ──

  Widget _buildArtistsSection(AbstractThemeColors colors) {
    if (_artists == null) {
      return SizedBox(
        height: 110,
        child: Center(
            child: CircularProgressIndicator(color: colors.loadingIndicator)),
      );
    }
    if (_artists!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text('no_followed_artists'.tr(),
            style: TextStyle(color: colors.textSecondary)),
      );
    }
    final artists = _applyOrder(_artists!, _artistOrder, (a) => a.id);
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: artists.length,
        itemBuilder: (context, index) {
          final artist = artists[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ArtistPage(
                  artistId: artist.id,
                  artistName: artist.name,
                  followerCounter: 0,
                ),
              ),
            ).then((_) => _refresh()),
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
        },
      ),
    );
  }

  // ── 좋아요한 페스티벌 ──

  Widget _buildFestivalsSection(AbstractThemeColors colors) {
    if (_festivals == null) {
      return SizedBox(
        height: 160,
        child: Center(
            child: CircularProgressIndicator(color: colors.loadingIndicator)),
      );
    }
    if (_festivals!.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Text('no_liked_festivals'.tr(),
            style: TextStyle(color: colors.textSecondary)),
      );
    }
    final festivals = _applyOrder(_festivals!, _festivalOrder, (f) => f.id);
    return SizedBox(
      height: 190,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: festivals.length,
        itemBuilder: (context, index) {
          final festival = festivals[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FestivalInformationFragment(poster: festival),
              ),
            ).then((_) => _refresh()),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 6),
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
        },
      ),
    );
  }
}
