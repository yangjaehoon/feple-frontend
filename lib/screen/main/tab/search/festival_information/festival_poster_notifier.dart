import 'dart:math';

import 'package:feple/common/app_events.dart';
import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/model/cert_state.dart';
import 'package:feple/model/certification_model.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/service/festival_interaction_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  CertState get certState {
    if (isCertified) return CertState.certified;
    if (isPending) return CertState.pending;
    return CertState.none;
  }

  String get _descPrefKey => 'festival_desc_expanded_$festivalId';

  FestivalPosterNotifier({
    required this.festivalId,
    required this.certService,
    required this.festivalService,
    this.attendingCount = 0,
  });

  Future<void> init() async {
    hasInitError = false;
    await Future.wait([loadLikeState(), loadAttendingState(), loadDescState(), loadCertState()]);
  }

  Future<void> retryInit() => init();

  Future<void> loadLikeState() async {
    try {
      liked = await festivalService.isLiked(festivalId);
      safeNotify();
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
    } catch (e) {
      debugPrint('loadAttendingState error: $e');
      hasInitError = true;
      safeNotify();
    }
  }

  Future<void> loadDescState() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_descPrefKey);
    if (saved != null) {
      descExpanded = saved;
      safeNotify();
    }
  }

  Future<void> saveDescState(bool expanded) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_descPrefKey, expanded);
  }

  Future<void> loadCertState() async {
    try {
      final status = await certService.getCertState(festivalId);
      isCertified = status == CertStatus.approved;
      isPending = status == CertStatus.pending;
      safeNotify();
    } catch (e) {
      debugPrint('[FestivalPoster] 인증 상태 로드 실패: $e');
      hasInitError = true;
      safeNotify();
    }
  }

  Future<void> toggleLike() async {
    if (isTogglingLike) return;
    isTogglingLike = true;
    try {
      await optimisticToggle(
        liked,
        apply: (v) => liked = v,
        action: () async {
          await festivalService.toggleLike(festivalId);
          AppEvents.festivalLikeChanged.value++;
        },
      );
    } finally {
      isTogglingLike = false;
      safeNotify();
    }
  }

  Future<void> toggleAttending() async {
    if (isTogglingAttend) return;
    isTogglingAttend = true;
    final prevAttending = attending;
    final prevCount = attendingCount;
    attending = !attending;
    attendingCount = attending ? attendingCount + 1 : max(0, attendingCount - 1);
    safeNotify();
    try {
      await festivalService.toggleAttending(festivalId);
    } catch (e) {
      attending = prevAttending;
      attendingCount = prevCount;
      safeNotify();
      debugPrint('toggleAttending error: $e');
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
