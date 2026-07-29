import 'dart:convert';

import 'package:feple/model/search_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SearchResult.fromJson', () {
    test('artists/festivals/posts를 파싱한다', () {
      final json = jsonDecode('''
      {
        "artists": [
          {"id":1,"name":"IU","nameEn":"IU","genre":"Pop","profileImageUrl":"https://img.example.com/iu.jpg","followerCount":5000}
        ],
        "festivals": [
          {"id":5,"title":"Rock Fest","titleEn":"Rock Fest","location":"Seoul","posterUrl":"https://img.example.com/poster.jpg","startDate":"2025-06-01"}
        ],
        "posts": [
          {"id":10,"title":"Post","content":"Body","likeCount":3,"nickname":"user1"}
        ]
      }
      ''') as Map<String, dynamic>;

      final result = SearchResult.fromJson(json);

      expect(result.artists, hasLength(1));
      expect(result.artists.first.name, 'IU');
      expect(result.festivals, hasLength(1));
      expect(result.festivals.first.title, 'Rock Fest');
      expect(result.posts, hasLength(1));
      expect(result.posts.first.title, 'Post');
    });

    test('키가 없으면 빈 리스트로 처리한다', () {
      final result = SearchResult.fromJson(const {});

      expect(result.artists, isEmpty);
      expect(result.festivals, isEmpty);
      expect(result.posts, isEmpty);
    });
  });
}
