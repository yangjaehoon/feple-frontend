import 'dart:async';
import 'dart:math';

import 'package:feple/common/app_events.dart';
import 'package:feple/common/data/preference/item/preference_item.dart';
import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/model/poster_cert_state.dart';
import 'package:feple/model/certification_model.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/service/festival_interaction_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FestivalPosterNotifier extends SafeChangeNotifier {
  final int festivalId;
  final CertificationService certService;
  final FestivalInteractionService festivalService;

  bool liked = false;
  bool attending = false;
  int attendingCount;
  bool descExpanded = true;
  bool isCertified = false;
  bool isPending = false;
  bool hasInitError = false;
  bool isTogglingLike = false;
  bool isTogglingAttend = false;
  double averageRating = 0.0;
  int ratingCount = 0;
  bool ratingLoaded = false;
  bool ratingLoadFailed = false;
  int? certId;
  int? myRating;
  String? myReview;

  final void Function(String key)? onError;

  // 액션 버튼(좋아요·인증)/참석 행이 각자 필요한 변경에만 반응하도록 분리 —
  // 서로의 토글이나 평점뱃지·설명 섹션 변경에 불필요하게 리빌드되지 않게 함.
  // hasInitError(초기화 에러 표시)는 여러 로더가 공통으로 건드려서 계속
  // 전체 notifier(safeNotify)로 알림.
  final actionButtonsChanges = ChangeNotifier();
  final attendingChanges = ChangeNotifier();

  void _pingActionButtons() {
    if (!isDisposed) actionButtonsChanges.notifyListeners();
  }

  void _pingAttending() {
    if (!isDisposed) attendingChanges.notifyListeners();
  }

  @override
  void dispose() {
    actionButtonsChanges.dispose();
    attendingChanges.dispose();
    super.dispose();
  }

  PosterCertState get certState {
    if (isCertified) return PosterCertState.certified;
    if (isPending) return PosterCertState.pending;
    return PosterCertState.none;
  }

  String get _descPrefKey => 'festival_desc_expanded_$festivalId';

  FestivalPosterNotifier({
    required this.festivalId,
    required this.certService,
    required this.festivalService,
    this.attendingCount = 0,
    this.onError,
  });

  Future<void> init() async {
    hasInitError = false;
    await Future.wait([
      loadLikeState(),
      loadAttendingState(),
      loadDescState(),
      loadMyCertificationStatus(),
      loadRatingInfo(),
    ]);
  }

  Future<void> retryInit() => init();

  Future<void> loadLikeState() async {
    try {
      liked = await festivalService.isLiked(festivalId);
      safeNotify();
      _pingActionButtons();
    } catch (e) {
      debugPrint('loadLikeState error: $e');
      hasInitError = true;
      safeNotify();
    }
  }

  Future<void> loadAttendingState() async {
    try {
      attending = await festivalService.isAttending(festivalId);
      safeNotify();
      _pingAttending();
    } catch (e) {
      debugPrint('loadAttendingState error: $e');
      hasInitError = true;
      safeNotify();
    }
  }

  // defaultValue는 descExpanded의 초기값(true)과 동일 — 저장된 값이 없으면
  // 필드를 건드리지 않는 것과 같은 결과가 되도록 맞춤
  Future<void> loadDescState() async {
    descExpanded = PreferenceItem<bool>(_descPrefKey, true).get();
    safeNotify();
  }

  Future<void> saveDescState(bool expanded) async {
    await PreferenceItem<bool>(_descPrefKey, true).set(expanded);
  }

  Future<void> loadMyCertificationStatus() async {
    try {
      final detail = await certService.getMyCertificationStatus(festivalId);
      isCertified = detail.status == CertStatus.approved;
      isPending = detail.status == CertStatus.pending;
      certId = detail.certId;
      myRating = detail.myRating;
      myReview = detail.myReview;
      safeNotify();
      _pingActionButtons();
    } catch (e) {
      debugPrint('[FestivalPoster] 인증 상태 로드 실패: $e');
      hasInitError = true;
      safeNotify();
    }
  }

  Future<void> loadRatingInfo() async {
    try {
      final info = await certService.getFestivalRating(festivalId);
      averageRating = info.averageRating;
      ratingCount = info.ratingCount;
      ratingLoadFailed = false;
    } catch (e) {
      debugPrint('[FestivalPoster] 별점 정보 로드 실패: $e');
      ratingLoadFailed = true;
      hasInitError = true;
    } finally {
      ratingLoaded = true;
      safeNotify();
    }
  }

  Future<void> toggleLike() async {
    if (isTogglingLike) return;
    isTogglingLike = true;
    unawaited(HapticFeedback.lightImpact());
    try {
      await optimisticToggle(
        liked,
        apply: (v) {
          liked = v;
          _pingActionButtons();
        },
        action: () async {
          await festivalService.toggleLike(festivalId);
          AppEvents.festivalLikeChanged.value++;
        },
        onError: () => onError?.call('like_failed'),
      );
    } finally {
      isTogglingLike = false;
      safeNotify();
    }
  }

  Future<void> toggleAttending() async {
    if (isTogglingAttend) return;
    isTogglingAttend = true;
    unawaited(HapticFeedback.lightImpact());
    final prevAttending = attending;
    final prevCount = attendingCount;
    attending = !attending;
    attendingCount = attending
        ? attendingCount + 1
        : max(0, attendingCount - 1);
    safeNotify();
    _pingAttending();
    try {
      await festivalService.toggleAttending(festivalId);
    } catch (e) {
      attending = prevAttending;
      attendingCount = prevCount;
      safeNotify();
      _pingAttending();
      debugPrint('toggleAttending error: $e');
      onError?.call('attend_failed');
    } finally {
      isTogglingAttend = false;
      safeNotify();
    }
  }

  void toggleDesc() {
    descExpanded = !descExpanded;
    safeNotify();
    saveDescState(descExpanded);
  }
}
