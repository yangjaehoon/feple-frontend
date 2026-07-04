import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/favorite_board.dart';
import 'package:feple/model/followed_artist.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/service/cache_prefetch_service.dart';
import 'package:feple/service/festival_cache_service.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeStateNotifier extends SafeChangeNotifier {
  final _userService = sl<UserService>();
  final _cacheService = sl<FestivalCacheService>();
  final _prefetchService = sl<CachePrefetchService>();

  List<FollowedArtist>? artists;
  List<FestivalModel>? festivals;
  List<FavoriteBoard>? boards;
  bool hasError = false;

  DateTime? _loadedAt;
  static const _staleAfter = Duration(minutes: 5);
  bool get _isStale =>
      _loadedAt == null || DateTime.now().difference(_loadedAt!) > _staleAfter;

  List<int> artistOrder = [];
  List<int> festivalOrder = [];

  int? userId;

  String get _artistOrderKey => 'artist_order_$userId';
  String get _festivalOrderKey => 'festival_order_$userId';

  Future<void> init(int newUserId) async {
    userId = newUserId;
    artists = null;
    festivals = null;
    boards = null;
    hasError = false;
    safeNotify();
    await loadData();
  }

  Future<void> loadData() async {
    final id = userId;
    if (id == null) return;

    hasError = false;

    final (artistOrd, festivalOrd) = await (
      _loadOrder(_artistOrderKey),
      _loadOrder(_festivalOrderKey),
    ).wait;
    if (artistOrd != null) artistOrder = artistOrd;
    if (festivalOrd != null) festivalOrder = festivalOrd;

    // 1단계: 캐시가 있으면 즉시 표시 (스플래시 프리패치 활용)
    await _showFromCacheIfAvailable(id);

    // 2단계: 네트워크에서 최신 데이터 갱신
    try {
      final (fetchedArtists, fetchedFestivals) = await (
        _fetchArtists(id),
        _fetchFestivals(id),
      ).wait;
      // 비동기 완료 시점에 userId가 바뀌었으면 다른 init() 호출 중 — 결과 버림
      if (userId != id) return;
      artists = fetchedArtists;
      festivals = fetchedFestivals;
      boards = _buildBoards(fetchedArtists, fetchedFestivals);
      _loadedAt = DateTime.now();
      // ignore: unawaited_futures
      _cacheService.saveHomeFestivals(id, fetchedFestivals);
      // ignore: unawaited_futures
      _cacheService.saveHomeArtists(id, fetchedArtists);
      // ignore: unawaited_futures
      _prefetchService.prefetchForFestivals(fetchedFestivals);
    } catch (e) {
      if (userId != id) return;
      debugPrint('[Home] 데이터 로드 실패: $e');
      // 캐시에서 이미 표시 중이면 에러 표시 안 함
      if (artists == null) hasError = true;
    }
    safeNotify();
  }

  // 프리패치된 캐시가 있으면 즉시 렌더링 후 notify
  Future<void> _showFromCacheIfAvailable(int id) async {
    final (cachedFestivals, cachedArtists) = await (
      _cacheService.loadHomeFestivals(id),
      _cacheService.loadHomeArtists(id),
    ).wait;
    if (cachedFestivals == null || cachedArtists == null) return;
    festivals = cachedFestivals;
    artists = cachedArtists;
    boards = _buildBoards(cachedArtists, cachedFestivals);
    safeNotify();
  }

  /// [force] true면 항상 재요청. false면 5분 이내 로드된 데이터가 있으면 skip.
  Future<void> refresh({bool force = false}) async {
    if (!force && !_isStale && artists != null) return;
    hasError = false;
    await loadData();
  }

  Future<void> refreshFestivals() async {
    final id = userId;
    if (id == null) return;
    // 기존 festivals 유지 — 네트워크 응답이 올 때 교체
    try {
      final fetched = await _fetchFestivals(id);
      if (userId != id) return;
      festivals = fetched;
      boards = _buildBoards(artists ?? [], fetched);
    } catch (e) {
      debugPrint('[Home] 페스티벌 갱신 실패: $e');
    }
    if (userId == id) safeNotify();
  }

  Future<void> refreshArtists() async {
    final id = userId;
    if (id == null) return;
    // 기존 artists 유지 — 네트워크 응답이 올 때 교체
    try {
      final fetched = await _fetchArtists(id);
      if (userId != id) return;
      artists = fetched;
      boards = _buildBoards(fetched, festivals ?? []);
    } catch (e) {
      debugPrint('[Home] 아티스트 갱신 실패: $e');
    }
    if (userId == id) safeNotify();
  }

  Future<void> retry() async {
    artists = null;
    festivals = null;
    boards = null;
    hasError = false;
    safeNotify();
    await loadData();
  }

  Future<void> saveArtistOrder(List<int> order) async {
    artistOrder = order;
    await _persistOrder(_artistOrderKey, order);
  }

  Future<void> saveFestivalOrder(List<int> order) async {
    festivalOrder = order;
    await _persistOrder(_festivalOrderKey, order);
  }

  Future<void> _persistOrder(String key, List<int> order) async {
    safeNotify();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(key, order.map((e) => e.toString()).toList());
    } catch (e) {
      // 화면에 반영된 순서는 이미 유효하므로 재로드 전까지는 문제없음 —
      // 다음 실행 시 순서가 저장 전으로 되돌아갈 수 있음을 로그로만 남김
      debugPrint('order persist error ($key): $e');
    }
  }

  List<FollowedArtist>? get orderedArtists {
    if (artists == null) return null;
    return applyOrder(artists!, artistOrder, (x) => x.id);
  }

  List<FestivalModel>? get orderedFestivals {
    if (festivals == null) return null;
    final ordered = applyOrder(festivals!, festivalOrder, (x) => x.id);
    return [
      ...ordered.where((f) => !f.isEnded),
      ...ordered.where((f) => f.isEnded),
    ];
  }

  @visibleForTesting
  List<T> applyOrder<T>(List<T> items, List<int> order, int Function(T) getId) {
    if (order.isEmpty) return items;
    final map = {for (final item in items) getId(item): item};
    final ordered =
        order.where(map.containsKey).map((id) => map[id]!).toList();
    final orderedIds = order.toSet();
    final rest =
        items.where((item) => !orderedIds.contains(getId(item))).toList();
    return [...ordered, ...rest];
  }

  Future<List<int>?> _loadOrder(String key) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(key)?.map(int.parse).toList();
  }

  Future<List<FollowedArtist>> _fetchArtists(int userId) =>
      _userService.fetchFollowingArtists(userId);

  Future<List<FestivalModel>> _fetchFestivals(int userId) =>
      _userService.fetchLikedFestivals(userId);

  List<FavoriteBoard> _buildBoards(
      List<FollowedArtist> artists, List<FestivalModel> festivals) {
    return [
      ...artists.map((artist) => FavoriteBoard(
            boardId: 'artist_${artist.id}',
            type: FavoriteBoardType.artist,
            entityId: artist.id,
            entityName: artist.name,
            entityNameEn: artist.nameEn,
            imageUrl: artist.profileImageUrl,
          )),
      ...festivals.map((festival) => FavoriteBoard(
            boardId: 'festival_${festival.id}',
            type: FavoriteBoardType.festival,
            entityId: festival.id,
            entityName: festival.title,
            entityNameEn: festival.titleEn,
            imageUrl: festival.posterUrl,
          )),
    ];
  }
}
