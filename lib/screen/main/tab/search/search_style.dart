import 'package:feple/model/search_suggestion.dart';
import 'package:flutter/material.dart';

extension SearchTypeStyle on SearchType {
  IconData get icon => switch (this) {
        SearchType.artist   => Icons.person_rounded,
        SearchType.festival => Icons.festival_rounded,
      };
}
