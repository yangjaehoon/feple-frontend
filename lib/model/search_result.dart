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
        artists: _parseList(json['artists'], Artist.fromJson),
        festivals: _parseList(json['festivals'], FestivalPreview.fromJson),
        posts: _parseList(json['posts'], Post.fromJson),
      );

  static List<T> _parseList<T>(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
  ) =>
      ((raw as List?) ?? []).map((e) => fromJson(e as Map<String, dynamic>)).toList();
}
