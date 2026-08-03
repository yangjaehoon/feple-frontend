/// [order]에 담긴 id 순서대로 [items]를 재배열하고, [order]에 없는 나머지는 뒤에 붙인다.
/// [order]가 비어있으면 [items]를 그대로 반환한다.
List<T> reorderById<T>(List<T> items, List<int> order, int Function(T) getId) {
  if (order.isEmpty) return items;
  final map = {for (final item in items) getId(item): item};
  final ordered = order.where(map.containsKey).map((id) => map[id]!).toList();
  final orderedIds = order.toSet();
  final rest = items.where((item) => !orderedIds.contains(getId(item))).toList();
  return [...ordered, ...rest];
}
