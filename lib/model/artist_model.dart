import 'genre_parser.dart';
import 'json_reader.dart';
import 'localized_text.dart';

class Artist {
  final int id;
  final String name;
  final String nameEn;
  final String genre;
  final String profileImageUrl;
  final int followerCount;

  const Artist({
    required this.id,
    required this.name,
    this.nameEn = '',
    required this.genre,
    required this.profileImageUrl,
    required this.followerCount,
  });

  factory Artist.fromJson(Map<String, dynamic> json) {
    return Artist(
      id: json.integer('id'),
      name: json.str('name'),
      nameEn: json.str('nameEn'),
      genre: json.str('genre'),
      profileImageUrl: json.str('profileImageUrl'),
      followerCount: json.integer('followerCount'),
    );
  }

  List<String> get genres => splitGenres(genre);

  String displayName(bool isEnglish) => pickLocalized(isEnglish, name, nameEn);
}