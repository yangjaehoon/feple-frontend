import 'dart:typed_data';
import 'package:feple/common/util/image_upload_helper.dart';
import 'package:feple/model/artist_photo.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/artist_photo_manageable.dart';
import 'package:feple/service/artist_photo_uploadable.dart';

class ArtistPhotoService implements ArtistPhotoManageable, ArtistPhotoUploadable {
  @override
  Future<List<ArtistPhoto>> fetchPhotos(int artistId) async {
    final response = await DioClient.dio.get('/artists/$artistId/photos');
    return response.toModelList(ArtistPhoto.fromJson);
  }

  @override
  Future<void> toggleLike(int artistId, int photoId) =>
      DioClient.dio.post('/artists/$artistId/photos/$photoId/like');

  @override
  Future<void> deletePhoto(int artistId, int photoId) =>
      DioClient.dio.delete('/artists/$artistId/photos/$photoId');

  @override
  Future<void> updatePhoto(
          int artistId, int photoId, String title, String description) =>
      DioClient.dio.patch(
        '/artists/$artistId/photos/$photoId',
        data: {'title': title, 'description': description},
      );

  @override
  Future<void> uploadPhoto({
    required int artistId,
    required Uint8List imageData,
    required String title,
    required String description,
    bool isAnonymous = false,
  }) async {
    final presign = await ImageUploadHelper.compressAndUpload(
      presignEndpoint: '/artists/$artistId/photos/presign',
      imageData: imageData,
    );

    await DioClient.dio.post(
      '/artists/$artistId/photos',
      data: {
        'objectKey': presign.objectKey,
        'contentType': 'image/jpeg',
        'title': title,
        'description': description,
        'isAnonymous': isAnonymous,
      },
    );
  }
}
