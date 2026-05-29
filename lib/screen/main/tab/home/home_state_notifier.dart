import 'package:feple/injection.dart';
import 'package:feple/model/favorite_board.dart';
import 'package:feple/model/followed_artist.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeStateNotifier extends ChangeNotifier {
  List<FollowedArtist>? artists;
  List<FestivalModel>? festivals;
  List<FavoriteBoard>? boards;
  bool hasError = false;

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
    notifyListeners();
    await loadData();
  }

  Future<void> loadData() async {
    final id = userId;
    if (id == null) return;

    hasError = false;

    final orders = await Future.wait([
      _loadArtistOrder(),
      _loadFestivalOrder(),
    ]);
    if (orders[0] != null) artistOrder = orders[0]!;
    if (orders[1] != null) festivalOrder = orders[1]!;

    try {
      final data = await Future.wait([
        _fetchArtists(id),
        _fetchFestivals(id),
      ]);
      final fetchedArtists = data[0] as List<FollowedArtist>;
      final fetchedFestivals = data[1] as List<FestivalModel>;
      artists = fetchedArtists;
      festivals = fetchedFestivals;
      boards = _buildBoards(fetchedArtists, fetchedFestivals);
    } catch (_) {
      hasError = true;
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    artists = null;
    festivals = null;
    boards = null;
    hasError = false;
    notifyListeners();
    await loadData();
  }

  Future<void> retry() async {
    artists = null;
    festivals = null;
    boards = null;
    hasError = false;
    notifyListeners();
    await loadData();
  }

  Future<void> saveArtistOrder(List<int> order) async {
    artistOrder = order;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _artistOrderKey, order.map((e) => e.toString()).toList());
  }

  Future<void> saveFestivalOrder(List<int> order) async {
    festivalOrder = order;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
        _festivalOrderKey, order.map((e) => e.toString()).toList());
  }

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

  Future<List<FollowedArtist>> _fetchArtists(int userId) =>
      sl<UserService>().fetchFollowingArtists(userId);

  Future<List<FestivalModel>> _fetchFestivals(int userId) =>
      sl<UserService>().fetchLikedFestivals(userId);

  List<FavoriteBoard> _buildBoards(
      List<FollowedArtist> artists, List<FestivalModel> festivals) {
    return [
      ...artists.map((artist) => FavoriteBoard(
            boardId: 'artist_${artist.id}',
            type: FavoriteBoardType.artist,
            entityId: artist.id,
            entityName: artist.name,
            imageUrl: artist.profileImageUrl,
          )),
      ...festivals.map((festival) => FavoriteBoard(
            boardId: 'festival_${festival.id}',
            type: FavoriteBoardType.festival,
            entityId: festival.id,
            entityName: festival.title,
            imageUrl: festival.posterUrl,
          )),
    ];
  }
}
