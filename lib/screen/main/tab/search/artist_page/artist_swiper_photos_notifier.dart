import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_photo.dart';
import 'package:feple/service/artist_photo_readable.dart';
import 'package:flutter/foundation.dart';

class ArtistSwiperPhotosNotifier extends SafeChangeNotifier {
  static const int _previewCount = 10;

  final int artistId;
  final _photoService = sl<ArtistPhotoReadable>();

  List<ArtistPhoto> photos = [];
  bool loaded = false;

  ArtistSwiperPhotosNotifier({required this.artistId});

  Future<void> load() async {
    try {
      // limit을 서버에 전달해 미리보기에 필요한 만큼만 조회 — 전체 목록을 받아
      // 클라이언트에서 자르면 인기 아티스트일수록 불필요한 presign 서명 비용이 커짐
      final result = await _photoService.fetchPhotos(artistId, limit: _previewCount);
      // 서버가 limit을 초과해 반환하더라도 캐러셀이 과도하게 커지지 않도록 방어적으로 재확인
      photos = result.take(_previewCount).toList();
    } catch (e) {
      debugPrint('[ArtistSwiperPhotosNotifier] 사진 로드 실패: $e');
    } finally {
      loaded = true;
      safeNotify();
    }
  }
}
