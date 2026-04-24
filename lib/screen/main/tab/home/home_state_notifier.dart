import 'package:feple/model/favorite_board.dart';
import 'package:feple/model/followed_artist.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/network/dio_client.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeStateNotifier extends ChangeNotifier {
  List<FollowedArtist>? artists;
  List<FestivalModel>? festivals;
  List<FavoriteBoard>? boards;

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
    notifyListeners();
    await loadData();
  }

  Future<void> loadData() async {
    final id = userId;
    if (id == null) return;

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
      artists ??= [];
      festivals ??= [];
      boards ??= [];
    }
    notifyListeners();
  }

  Future<void> refresh() async {
    artists = null;
    festivals = null;
    boards = null;
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
}
