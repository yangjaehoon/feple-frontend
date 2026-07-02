import 'dart:typed_data';

abstract class ArtistPhotoUploadable {
  Future<void> uploadPhoto({
    required int artistId,
    required Uint8List imageData,
    required String title,
    required String description,
    bool isAnonymous = false,
  });
}
