import 'package:feple/service/artist_photo_readable.dart';

abstract class ArtistPhotoManageable extends ArtistPhotoReadable {
  Future<void> toggleLike(int artistId, int photoId);
  Future<void> deletePhoto(int artistId, int photoId);
  Future<void> updatePhoto(int artistId, int photoId, String title, String description);
}
