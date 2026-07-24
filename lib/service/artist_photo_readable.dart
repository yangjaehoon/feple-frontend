import 'package:feple/model/artist_photo.dart';

abstract class ArtistPhotoReadable {
  Future<List<ArtistPhoto>> fetchPhotos(int artistId);
}
