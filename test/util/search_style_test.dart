import 'package:feple/model/search_suggestion.dart';
import 'package:feple/screen/main/tab/search/search_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SearchTypeStyle.icon', () {
    test('artist는 person 아이콘을 반환한다', () {
      expect(SearchType.artist.icon, Icons.person_rounded);
    });

    test('festival은 festival 아이콘을 반환한다', () {
      expect(SearchType.festival.icon, Icons.festival_rounded);
    });
  });
}
