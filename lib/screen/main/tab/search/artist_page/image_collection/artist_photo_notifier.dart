import 'package:feple/injection.dart';
import 'package:feple/model/artist_photo_response.dart';
import 'package:feple/service/artist_photo_service.dart';
import 'package:flutter/foundation.dart';

class ArtistPhotoNotifier extends ChangeNotifier {
  final int artistId;
  final _photoService = sl<ArtistPhotoService>();

  List<ArtistPhotoResponse> photos = [];
  bool isLoading = true;
  String? errorKey;
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _safeNotify() {
    if (!_disposed) notifyListeners();
  }

  void clearError() {
    errorKey = null;
  }

  ArtistPhotoNotifier({required this.artistId});

  Future<void> loadPhotos() async {
    isLoading = true;
    _safeNotify();
    try {
      photos = await _photoService.fetchPhotos(artistId);
    } catch (e) {
      debugPrint('load photos error: $e');
    } finally {
      isLoading = false;
      _safeNotify();
    }
  }

  Future<void> toggleLike(int photoId) async {
    try {
      await _photoService.toggleLike(artistId, photoId);
      final idx = photos.indexWhere((photo) => photo.photoId == photoId);
      if (idx != -1) {
        final photo = photos[idx];
        photos[idx] = ArtistPhotoResponse(
          photoId: photo.photoId,
          url: photo.url,
          uploaderUserId: photo.uploaderUserId,
          createdAt: photo.createdAt,
          title: photo.title,
          description: photo.description,
          likeCount: photo.isLiked ? photo.likeCount - 1 : photo.likeCount + 1,
          isLiked: !photo.isLiked,
        );
        photos.sort((a, b) => b.likeCount.compareTo(a.likeCount));
        _safeNotify();
      }
    } catch (e) {
      debugPrint('toggle like error: $e');
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
      _safeNotify();
    }
  }

  Future<void> updatePhoto(int photoId, String title, String description) async {
    try {
      await _photoService.updatePhoto(artistId, photoId, title, description);
      await loadPhotos();
    } catch (e) {
      debugPrint('update error: $e');
      errorKey = 'photo_update_failed';
      _safeNotify();
    }
  }
}
