import 'package:feple/injection.dart';
import 'package:feple/model/artist_photo.dart';
import 'package:feple/screen/main/tab/search/artist_page/artist_background_photos_notifier.dart';
import 'package:feple/service/artist_photo_readable.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockArtistPhotoReadable extends Mock implements ArtistPhotoReadable {}

ArtistPhotoResponse _photo(int id) => ArtistPhotoResponse(
      photoId: id,
      url: 'https://example.com/$id.jpg',
      uploaderUserId: 10,
      uploaderNickname: 'user',
      createdAt: DateTime(2025),
      title: 'title $id',
      description: 'desc $id',
      likeCount: 0,
      isLiked: false,
      isAnonymous: false,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockArtistPhotoReadable mockService;
  late ArtistSwiperPhotosNotifier notifier;

  setUp(() {
    mockService = MockArtistPhotoReadable();
    if (sl.isRegistered<ArtistPhotoReadable>()) {
      sl.unregister<ArtistPhotoReadable>();
    }
    sl.registerSingleton<ArtistPhotoReadable>(mockService);
    notifier = ArtistSwiperPhotosNotifier(artistId: 1);
  });

  tearDown(() {
    sl.unregister<ArtistPhotoReadable>();
  });

  group('load', () {
    test('성공 시 최대 10장까지만 photos에 채우고 loaded true', () async {
      final photos = List.generate(15, (i) => _photo(i));
      when(() => mockService.fetchPhotos(1)).thenAnswer((_) async => photos);

      await notifier.load();

      expect(notifier.photos.length, 10);
      expect(notifier.photos, photos.take(10).toList());
      expect(notifier.loaded, true);
    });

    test('10장 미만이면 있는 만큼만 채움', () async {
      final photos = [_photo(1), _photo(2)];
      when(() => mockService.fetchPhotos(1)).thenAnswer((_) async => photos);

      await notifier.load();

      expect(notifier.photos, photos);
      expect(notifier.loaded, true);
    });

    test('서비스 예외 시 photos 비어있고 loaded true (크래시 없음)', () async {
      when(() => mockService.fetchPhotos(1)).thenThrow(Exception('network'));

      await expectLater(notifier.load(), completes);

      expect(notifier.photos, isEmpty);
      expect(notifier.loaded, true);
    });
  });
}
