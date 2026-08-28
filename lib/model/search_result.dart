import 'package:feple/model/artist_model.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/post_model.dart';

import 'json_reader.dart';

class SearchResult {
  final List<Artist> artists;
  final List<FestivalPreview> festivals;
  final List<Post> posts;

  const SearchResult({
    required this.artists,
    required this.festivals,
    required this.posts,
  });

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
        artists: json.objectList('artists').map(Artist.fromJson).toList(),
        festivals:
            json.objectList('festivals').map(FestivalPreview.fromJson).toList(),
        posts: json.objectList('posts').map(Post.fromJson).toList(),
      );
}
