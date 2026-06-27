import 'dart:typed_data';
import 'package:feple/common/util/image_upload_helper.dart';
import 'package:feple/model/artist_photo.dart';
import 'package:feple/network/dio_client.dart';

class ArtistPhotoService {
  Future<List<ArtistPhotoResponse>> fetchPhotos(int artistId) async {
    final response = await DioClient.dio.get('/artists/$artistId/photos');
    return (response.data as List)
        .map((json) => ArtistPhotoResponse.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> toggleLike(int artistId, int photoId) =>
      DioClient.dio.post('/artists/$artistId/photos/$photoId/like');

  Future<void> deletePhoto(int artistId, int photoId) =>
      DioClient.dio.delete('/artists/$artistId/photos/$photoId');

  Future<void> updatePhoto(
          int artistId, int photoId, String title, String description) =>
      DioClient.dio.patch(
        '/artists/$artistId/photos/$photoId',
        data: {'title': title, 'description': description},
      );

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
