import 'package:feple/model/artist_photo.dart';

abstract class ArtistPhotoReadable {
  /// [limit] 지정 시 인기순 상위 N개만 반환 (캐러셀 미리보기 등)
  Future<List<ArtistPhoto>> fetchPhotos(int artistId, {int? limit});
}
