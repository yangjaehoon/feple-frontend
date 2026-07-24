import 'package:feple/common/data/preference/prefs.dart';
import 'package:flutter/foundation.dart';
import 'package:in_app_review/in_app_review.dart';

class AppReviewService {
  static const _postThreshold = 3;
  static const _followThreshold = 5;

  static Future<void> recordPostCreated() async {
    if (Prefs.reviewRequested.get()) return;
    final count = Prefs.postCreatedCount.get() + 1;
    await Prefs.postCreatedCount.set(count);
    if (count >= _postThreshold) await _maybeRequest();
  }

  static Future<void> recordArtistFollowed() async {
    if (Prefs.reviewRequested.get()) return;
    final count = Prefs.artistFollowedCount.get() + 1;
    await Prefs.artistFollowedCount.set(count);
    if (count >= _followThreshold) await _maybeRequest();
  }

  static Future<void> _maybeRequest() async {
    try {
      final review = InAppReview.instance;
      if (!await review.isAvailable()) return;
      await review.requestReview();
      await Prefs.reviewRequested.set(true);
    } catch (e) {
      debugPrint('[AppReview] 리뷰 요청 실패: $e');
    }
  }
}
