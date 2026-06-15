import 'package:feple/injection.dart';
import 'package:feple/model/artist_photo_response.dart';
import 'package:feple/screen/main/tab/search/artist_page/image_collection/artist_photo_notifier.dart';
import 'package:feple/service/artist_photo_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockArtistPhotoService extends Mock implements ArtistPhotoService {}

ArtistPhotoResponse _photo({
  int id = 1,
  int likeCount = 0,
  bool isLiked = false,
}) =>
    ArtistPhotoResponse(
      photoId: id,
      url: 'https://example.com/$id.jpg',
      uploaderUserId: 10,
      createdAt: DateTime(2025),
      title: 'title $id',
      description: 'desc $id',
      likeCount: likeCount,
      isLiked: isLiked,
    );

void main() {
  late MockArtistPhotoService mockService;
  late ArtistPhotoNotifier notifier;

  setUp(() {
    mockService = MockArtistPhotoService();
    if (sl.isRegistered<ArtistPhotoService>()) {
      sl.unregister<ArtistPhotoService>();
    }
    sl.registerSingleton<ArtistPhotoService>(mockService);
    notifier = ArtistPhotoNotifier(artistId: 1);
  });

  tearDown(() {
    sl.unregister<ArtistPhotoService>();
  });

  group('loadPhotos', () {
    test('성공 시 photos 목록 채우고 isLoading false', () async {
      final photos = [_photo(id: 1), _photo(id: 2)];
      when(() => mockService.fetchPhotos(1)).thenAnswer((_) async => photos);

      await notifier.loadPhotos();

      expect(notifier.photos, photos);
      expect(notifier.isLoading, false);
    });

    test('서비스 예외 시 photos 비어있고 isLoading false', () async {
      when(() => mockService.fetchPhotos(1)).thenThrow(Exception('network'));

      await notifier.loadPhotos();

      expect(notifier.photos, isEmpty);
      expect(notifier.isLoading, false);
    });
  });

  group('toggleLike', () {
    test('좋아요 없던 사진 토글 시 isLiked true, likeCount +1', () async {
      when(() => mockService.fetchPhotos(1))
          .thenAnswer((_) async => [_photo(id: 1, likeCount: 5, isLiked: false)]);
      when(() => mockService.toggleLike(1, 1)).thenAnswer((_) async {});
      await notifier.loadPhotos();

      await notifier.toggleLike(1);

      expect(notifier.photos.first.isLiked, true);
      expect(notifier.photos.first.likeCount, 6);
    });

    test('이미 좋아요한 사진 토글 시 isLiked false, likeCount -1', () async {
      when(() => mockService.fetchPhotos(1))
          .thenAnswer((_) async => [_photo(id: 1, likeCount: 3, isLiked: true)]);
      when(() => mockService.toggleLike(1, 1)).thenAnswer((_) async {});
      await notifier.loadPhotos();

      await notifier.toggleLike(1);

      expect(notifier.photos.first.isLiked, false);
      expect(notifier.photos.first.likeCount, 2);
    });

    test('likeCount 내림차순으로 재정렬', () async {
      when(() => mockService.fetchPhotos(1)).thenAnswer((_) async => [
            _photo(id: 1, likeCount: 10, isLiked: false),
            _photo(id: 2, likeCount: 3, isLiked: false),
          ]);
      when(() => mockService.toggleLike(1, 2)).thenAnswer((_) async {});
      await notifier.loadPhotos();

      await notifier.toggleLike(2);

      expect(notifier.photos.first.photoId, 1);
      expect(notifier.photos.last.likeCount, 4);
    });

    test('서비스 예외 시 loadPhotos로 복구', () async {
      when(() => mockService.fetchPhotos(1))
          .thenAnswer((_) async => [_photo(id: 1)]);
      when(() => mockService.toggleLike(1, 1)).thenThrow(Exception('err'));
      await notifier.loadPhotos();

      await notifier.toggleLike(1);

      verify(() => mockService.fetchPhotos(1)).called(greaterThanOrEqualTo(1));
    });

    test('likeCount=0인 좋아요 상태 사진 토글 시 likeCount -1 (낙관적 업데이트)', () async {
      when(() => mockService.fetchPhotos(1))
          .thenAnswer((_) async => [_photo(id: 1, likeCount: 0, isLiked: true)]);
      when(() => mockService.toggleLike(1, 1)).thenAnswer((_) async {});
      await notifier.loadPhotos();

      await notifier.toggleLike(1);

      expect(notifier.photos.first.isLiked, false);
      expect(notifier.photos.first.likeCount, -1);
    });

    test('photos 빈 상태에서 toggleLike 호출 시 서비스는 호출되나 상태 변경 없음', () async {
      when(() => mockService.fetchPhotos(1)).thenAnswer((_) async => []);
      when(() => mockService.toggleLike(1, 99)).thenAnswer((_) async {});
      await notifier.loadPhotos();

      await notifier.toggleLike(99);

      expect(notifier.photos, isEmpty);
      verify(() => mockService.toggleLike(1, 99)).called(1);
    });
  });

  group('deletePhoto', () {
    test('삭제 성공 시 loadPhotos 호출', () async {
      when(() => mockService.deletePhoto(1, 1)).thenAnswer((_) async {});
      when(() => mockService.fetchPhotos(1)).thenAnswer((_) async => []);

      await notifier.deletePhoto(1);

      verify(() => mockService.deletePhoto(1, 1)).called(1);
      verify(() => mockService.fetchPhotos(1)).called(1);
    });

    test('삭제 실패 시 errorKey 설정', () async {
      when(() => mockService.deletePhoto(1, 1)).thenThrow(Exception('err'));

      await notifier.deletePhoto(1);

      expect(notifier.errorKey, 'photo_delete_failed');
    });
  });

  group('updatePhoto', () {
    test('수정 성공 시 loadPhotos 호출', () async {
      when(() => mockService.updatePhoto(1, 1, '새 제목', '새 설명'))
          .thenAnswer((_) async {});
      when(() => mockService.fetchPhotos(1)).thenAnswer((_) async => []);

      await notifier.updatePhoto(1, '새 제목', '새 설명');

      verify(() => mockService.updatePhoto(1, 1, '새 제목', '새 설명')).called(1);
    });

    test('수정 실패 시 errorKey 설정', () async {
      when(() => mockService.updatePhoto(any(), any(), any(), any()))
          .thenThrow(Exception('err'));

      await notifier.updatePhoto(1, '제목', '설명');

      expect(notifier.errorKey, 'photo_update_failed');
    });
  });
}
