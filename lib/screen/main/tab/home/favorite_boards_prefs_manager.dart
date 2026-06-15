import 'package:shared_preferences/shared_preferences.dart';

class FavoriteBoardsPrefsManager {
  final int userId;

  FavoriteBoardsPrefsManager(this.userId);

  String get _prefsKey => 'fav_boards_$userId';
  String get _orderKey => 'fav_boards_order_$userId';
  String get _knownKey => 'fav_boards_known_$userId';

  /// Returns the ordered list of selected board IDs, accounting for new boards
  /// that have been added since the last save.
  Future<List<String>> load(List<String> allBoardIds) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_prefsKey);
    final savedOrder = prefs.getStringList(_orderKey);
    final knownIds = prefs.getStringList(_knownKey)?.toSet();

    final validIds = allBoardIds.toSet();

    // Boards that are new since the last save (auto-add to selection)
    final trulyNewIds = knownIds != null
        ? allBoardIds.where((id) => !knownIds.contains(id)).toList()
        : <String>[];

    if (saved != null && saved.isNotEmpty) {
      final savedValid = saved.where(validIds.contains).toList();
      return [...savedValid, ...trulyNewIds];
    } else if (savedOrder != null && savedOrder.isNotEmpty) {
      final orderedValid = savedOrder.where(validIds.contains).toList();
      return [...orderedValid, ...trulyNewIds];
    } else {
      return List.from(allBoardIds);
    }
  }

  Future<void> save(
      List<String> orderedSelected, List<String> allBoardIds) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_orderKey, orderedSelected);
    await prefs.setStringList(_knownKey, allBoardIds);
    if (orderedSelected.length == allBoardIds.length) {
      await prefs.remove(_prefsKey);
    } else {
      await prefs.setStringList(_prefsKey, orderedSelected);
    }
  }
}
