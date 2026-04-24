import 'package:feple/model/artist_photo_response.dart';
import 'package:feple/network/dio_client.dart';
import 'package:flutter/foundation.dart';

class ArtistPhotoNotifier extends ChangeNotifier {
  final int artistId;

  List<ArtistPhotoResponse> photos = [];
  bool isLoading = true;

  void Function(String)? onError;

  ArtistPhotoNotifier({required this.artistId});

  Future<void> loadPhotos() async {
    isLoading = true;
    notifyListeners();
    try {
      final res = await DioClient.dio.get('/artists/$artistId/photos');
      if (res.statusCode == 200) {
        photos = (res.data as List)
            .map((e) => ArtistPhotoResponse.fromJson(e))
            .toList();
      }
    } catch (e) {
      debugPrint('load photos error: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(int photoId) async {
    try {
      await DioClient.dio.post('/artists/$artistId/photos/$photoId/like');
      final idx = photos.indexWhere((p) => p.photoId == photoId);
      if (idx != -1) {
        final photo = photos[idx];
        photos[idx] = ArtistPhotoResponse(
          photoId: photo.photoId,
          url: photo.url,
          uploaderUserId: photo.uploaderUserId,
          createdAt: photo.createdAt,
          title: photo.title,
          description: photo.description,
          likecount: photo.isLiked ? photo.likecount - 1 : photo.likecount + 1,
          isLiked: !photo.isLiked,
        );
        photos.sort((a, b) => b.likecount.compareTo(a.likecount));
        notifyListeners();
      }
    } catch (e) {
      debugPrint('toggle like error: $e');
      await loadPhotos();
    }
  }

  Future<void> deletePhoto(int photoId) async {
    try {
      await DioClient.dio.delete('/artists/$artistId/photos/$photoId');
      await loadPhotos();
    } catch (e) {
      debugPrint('delete error: $e');
      onError?.call('photo_delete_failed');
    }
  }

  Future<void> updatePhoto(int photoId, String title, String description) async {
    try {
      await DioClient.dio.patch(
        '/artists/$artistId/photos/$photoId',
        data: {'title': title, 'description': description},
      );
      await loadPhotos();
    } catch (e) {
      debugPrint('update error: $e');
      onError?.call('photo_update_failed');
    }
  }
}
