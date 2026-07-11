import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_photo.dart';
import 'package:feple/service/artist_photo_manageable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ArtistPhotoNotifier extends SafeChangeNotifier {
  final int artistId;
  final _photoService = sl<ArtistPhotoManageable>();

  List<ArtistPhoto> _photos = [];
  List<ArtistPhoto> get photos => List.unmodifiable(_photos);
  bool isLoading = true;
  String? errorKey;

  // 연타로 인한 중복 요청 방지 (photoId 단위 — 서로 다른 사진끼리는 막지 않음)
  final Set<int> _pendingLikeToggles = {};
  final Set<int> _pendingDeletes = {};
  final Set<int> _pendingUpdates = {};

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
    if (!_pendingLikeToggles.add(photoId)) return;
    try {
      final index = _photos.indexWhere((p) => p.photoId == photoId);
      if (index == -1) return;
      HapticFeedback.lightImpact();
      final original = _photos[index];
      _photos[index] = original.copyWith(
        likeCount: original.isLiked ? original.likeCount - 1 : original.likeCount + 1,
        isLiked: !original.isLiked,
      );
      safeNotify();
      try {
        await _photoService.toggleLike(artistId, photoId);
      } catch (e) {
        // await 도중 loadPhotos()로 _photos가 통째로 교체됐을 수 있으므로
        // 캡처해둔 index가 아니라 photoId로 다시 찾아서 롤백
        final rollbackIndex = _photos.indexWhere((p) => p.photoId == photoId);
        if (rollbackIndex != -1) _photos[rollbackIndex] = original;
        errorKey = 'like_failed';
        safeNotify();
        debugPrint('toggle like error: $e');
      }
    } finally {
      _pendingLikeToggles.remove(photoId);
    }
  }

  Future<void> deletePhoto(int photoId) async {
    if (!_pendingDeletes.add(photoId)) return;
    try {
      await _photoService.deletePhoto(artistId, photoId);
      await loadPhotos();
    } catch (e) {
      debugPrint('delete error: $e');
      errorKey = 'photo_delete_failed';
      safeNotify();
    } finally {
      _pendingDeletes.remove(photoId);
    }
  }

  Future<void> updatePhoto(int photoId, String title, String description) async {
    if (!_pendingUpdates.add(photoId)) return;
    try {
      await _photoService.updatePhoto(artistId, photoId, title, description);
      await loadPhotos();
    } catch (e) {
      debugPrint('update error: $e');
      errorKey = 'photo_update_failed';
      safeNotify();
    } finally {
      _pendingUpdates.remove(photoId);
    }
  }
}
