import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_photo_response.dart';
import 'package:feple/service/artist_photo_service.dart';
import 'package:flutter/foundation.dart';

class ArtistSwiperPhotosNotifier extends SafeChangeNotifier {
  final int artistId;
  final _photoService = sl<ArtistPhotoService>();

  List<ArtistPhotoResponse> photos = [];
  bool loaded = false;

  ArtistSwiperPhotosNotifier({required this.artistId});

  Future<void> load() async {
    try {
      photos = (await _photoService.fetchPhotos(artistId)).take(10).toList();
    } catch (e) {
      debugPrint('[ArtistSwiperPhotosNotifier] 사진 로드 실패: $e');
    } finally {
      loaded = true;
      safeNotify();
    }
  }
}
