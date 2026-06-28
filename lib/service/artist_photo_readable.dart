import 'package:feple/model/artist_photo.dart';

abstract class ArtistPhotoReadable {
  Future<List<ArtistPhotoResponse>> fetchPhotos(int artistId);
}
