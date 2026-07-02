enum SearchType {
  artist,
  festival;
}

class SearchSuggestion {
  final int? id;
  final String label;
  final SearchType type;
  const SearchSuggestion(this.label, this.type, {this.id});
}
