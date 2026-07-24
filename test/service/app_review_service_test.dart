import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/data/preference/prefs.dart';
import 'package:feple/service/app_review_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  setUp(() async {
    // 각 테스트 전 모든 카운터를 기본값으로 초기화
    await Prefs.postCreatedCount.set(0);
    await Prefs.artistFollowedCount.set(0);
    await Prefs.reviewRequested.set(false);
  });

  group('AppReviewService.recordPostCreated', () {
    test('이미 리뷰 요청된 경우 카운트 증가 없음', () async {
      await Prefs.reviewRequested.set(true);
      await AppReviewService.recordPostCreated();
      expect(Prefs.postCreatedCount.get(), 0);
    });

    test('호출마다 카운트 1씩 증가', () async {
      await AppReviewService.recordPostCreated();
      expect(Prefs.postCreatedCount.get(), 1);
      await AppReviewService.recordPostCreated();
      expect(Prefs.postCreatedCount.get(), 2);
    });

    test('threshold(3) 미만에서는 reviewRequested 변경 없음', () async {
      await AppReviewService.recordPostCreated(); // 1
      await AppReviewService.recordPostCreated(); // 2
      expect(Prefs.reviewRequested.get(), false);
    });

    test('threshold(3) 도달 시 _maybeRequest 호출 — 테스트 환경에서 예외 없이 완료', () async {
      await Prefs.postCreatedCount.set(2);
      await expectLater(AppReviewService.recordPostCreated(), completes);
      expect(Prefs.postCreatedCount.get(), 3);
    });
  });

  group('AppReviewService.recordArtistFollowed', () {
    test('이미 리뷰 요청된 경우 카운트 증가 없음', () async {
      await Prefs.reviewRequested.set(true);
      await AppReviewService.recordArtistFollowed();
      expect(Prefs.artistFollowedCount.get(), 0);
    });

    test('호출마다 카운트 1씩 증가', () async {
      await AppReviewService.recordArtistFollowed();
      expect(Prefs.artistFollowedCount.get(), 1);
      await AppReviewService.recordArtistFollowed();
      expect(Prefs.artistFollowedCount.get(), 2);
    });

    test('threshold(5) 미만에서는 reviewRequested 변경 없음', () async {
      await Prefs.artistFollowedCount.set(3);
      await AppReviewService.recordArtistFollowed(); // 4
      expect(Prefs.reviewRequested.get(), false);
    });

    test('threshold(5) 도달 시 _maybeRequest 호출 — 테스트 환경에서 예외 없이 완료', () async {
      await Prefs.artistFollowedCount.set(4);
      await expectLater(AppReviewService.recordArtistFollowed(), completes);
      expect(Prefs.artistFollowedCount.get(), 5);
    });
  });
}
