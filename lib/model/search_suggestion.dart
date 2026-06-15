import 'package:flutter/material.dart';

enum SearchType {
  artist,
  festival;

  IconData get icon => switch (this) {
        SearchType.artist   => Icons.person_rounded,
        SearchType.festival => Icons.festival_rounded,
      };
}

class SearchSuggestion {
  final String label;
  final SearchType type;
  const SearchSuggestion(this.label, this.type);
}
