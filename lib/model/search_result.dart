import 'package:feple/model/artist_model.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/post_model.dart';

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
        artists: (json['artists'] as List? ?? [])
            .map((e) => Artist.fromJson(e as Map<String, dynamic>))
            .toList(),
        festivals: (json['festivals'] as List? ?? [])
            .map((e) => FestivalPreview.fromJson(e as Map<String, dynamic>))
            .toList(),
        posts: (json['posts'] as List? ?? [])
            .map((e) => Post.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
