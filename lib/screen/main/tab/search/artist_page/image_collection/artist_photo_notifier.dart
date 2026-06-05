import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_photo_response.dart';
import 'package:feple/service/artist_photo_service.dart';
import 'package:flutter/foundation.dart';

class ArtistPhotoNotifier extends SafeChangeNotifier {
  final int artistId;
  final _photoService = sl<ArtistPhotoService>();

  List<ArtistPhotoResponse> _photos = [];
  List<ArtistPhotoResponse> get photos => List.unmodifiable(_photos);
  bool isLoading = true;
  String? errorKey;

  void clearError() {
    errorKey = null;
  }

  ArtistPhotoNotifier({required this.artistId});

  Future<void> loadPhotos() async {
    isLoading = true;
    errorKey = null;
    safeNotify();
    try {
      _photos = await _photoService.fetchPhotos(artistId);
    } catch (e) {
      debugPrint('load photos error: $e');
      errorKey = 'err_fetch_data';
    } finally {
      isLoading = false;
      safeNotify();
    }
  }

  Future<void> toggleLike(int photoId) async {
    try {
      await _photoService.toggleLike(artistId, photoId);
      final index = _photos.indexWhere((photo) => photo.photoId == photoId);
      if (index != -1) {
        final photo = _photos[index];
        _photos[index] = ArtistPhotoResponse(
          photoId: photo.photoId,
          url: photo.url,
          uploaderUserId: photo.uploaderUserId,
          createdAt: photo.createdAt,
          title: photo.title,
          description: photo.description,
          likeCount: photo.isLiked ? photo.likeCount - 1 : photo.likeCount + 1,
          isLiked: !photo.isLiked,
        );
        _photos.sort((a, b) => b.likeCount.compareTo(a.likeCount));
        safeNotify();
      }
    } catch (e) {
      debugPrint('toggle like error: $e');
      errorKey = 'like_failed';
      await loadPhotos();
    }
  }

  Future<void> deletePhoto(int photoId) async {
    try {
      await _photoService.deletePhoto(artistId, photoId);
      await loadPhotos();
    } catch (e) {
      debugPrint('delete error: $e');
      errorKey = 'photo_delete_failed';
      safeNotify();
    }
  }

  Future<void> updatePhoto(int photoId, String title, String description) async {
    try {
      await _photoService.updatePhoto(artistId, photoId, title, description);
      await loadPhotos();
    } catch (e) {
      debugPrint('update error: $e');
      errorKey = 'photo_update_failed';
      safeNotify();
    }
  }
}
