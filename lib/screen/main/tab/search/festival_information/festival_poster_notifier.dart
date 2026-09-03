import 'dart:async';
import 'dart:math';

import 'package:feple/common/app_events.dart';
import 'package:feple/common/data/preference/item/preference_item.dart';
import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/model/poster_cert_state.dart';
import 'package:feple/model/certification_model.dart';
import 'package:feple/model/ticket_link.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/service/festival_detail_service.dart';
import 'package:feple/service/festival_interaction_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class FestivalPosterNotifier extends SafeChangeNotifier {
  // FestivalInformationFragment가 상세 API를 재조회해 최신 FestivalModel을
  // 넘겨줄 때마다 updatePoster()로 갱신된다 — 이 notifier가 직접 재조회하지
  // 않는 이유는 FestivalPoster의 유일한 호출부인 그 화면이 이미 같은
  // festivalId로 재조회를 하고 있어서, 여기서 또 하면 같은 API를 화면 진입마다
  // 두 번 호출하게 되기 때문(festivalId는 최초 poster 기준으로 고정, 이후
  // poster가 교체돼도 같은 페스티벌이므로 바뀌지 않는다).
  FestivalModel poster;
  int get festivalId => poster.id;
  final CertificationService certService;
  final FestivalInteractionService festivalService;
  final FestivalDetailService detailService;

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
  List<TicketLink> ticketLinks = const [];

  final void Function(String key)? onError;

  // 액션 버튼(좋아요·인증)/참석 행이 각자 필요한 변경에만 반응하도록 분리 —
  // 서로의 토글이나 평점뱃지·설명 섹션 변경에 불필요하게 리빌드되지 않게 함.
  // hasInitError(초기화 에러 표시)는 여러 로더가 공통으로 건드려서 계속
  // 전체 notifier(safeNotify)로 알림.
  final actionButtonsChanges = ChangeNotifier();
  final attendingChanges = ChangeNotifier();
  // poster(제목·설명·날짜·위치 등 정적 정보) 교체는 좋아요/참석/액션버튼과
  // 무관하므로 별도 리스너블로 분리 — updatePoster() 시에만 알림.
  final posterChanges = ChangeNotifier();

  void _pingActionButtons() {
    if (!isDisposed) actionButtonsChanges.notifyListeners();
  }

  void _pingAttending() {
    if (!isDisposed) attendingChanges.notifyListeners();
  }

  void _pingPoster() {
    if (!isDisposed) posterChanges.notifyListeners();
  }

  @override
  void dispose() {
    actionButtonsChanges.dispose();
    attendingChanges.dispose();
    posterChanges.dispose();
    super.dispose();
  }

  PosterCertState get certState {
    if (isCertified) return PosterCertState.certified;
    if (isPending) return PosterCertState.pending;
    return PosterCertState.none;
  }

  String get _descPrefKey => 'festival_desc_expanded_$festivalId';

  // 비로그인 게스트 여부. 좋아요·참석·내 인증 상태는 계정이 있어야 의미가
  // 있으므로 게스트면 init()에서 해당 조회를 건너뛴다 (별점 요약·예매 링크·
  // 설명 펼침 상태는 비계정 정보라 그대로 로드).
  final bool isGuest;

  FestivalPosterNotifier({
    required this.poster,
    required this.certService,
    required this.festivalService,
    required this.detailService,
    this.isGuest = false,
    this.onError,
  }) : attendingCount = poster.attendingCount;

  Future<void> init() async {
    hasInitError = false;
    await Future.wait([
      if (!isGuest) loadLikeState(),
      if (!isGuest) loadAttendingState(),
      loadDescState(),
      if (!isGuest) loadMyCertificationStatus(),
      loadRatingInfo(),
      loadTicketLinks(),
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
    descExpanded = BoolPreferenceItem(_descPrefKey, true).get();
    safeNotify();
  }

  Future<void> saveDescState(bool expanded) async {
    await BoolPreferenceItem(_descPrefKey, true).set(expanded);
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

  // FestivalPosterState.didUpdateWidget에서 widget.poster가 바뀔 때 호출된다
  // (FestivalInformationFragment의 상세 재조회 결과). attendingCount는
  // toggleAttending()이 낙관적으로 관리하는 별도 값이라 여기서 재동기화하지
  // 않는다 — 최신 값이 도착하는 도중 사용자가 참석 토글을 누르면 낙관적으로
  // 갱신된 로컬 상태가 덮어써질 수 있기 때문.
  void updatePoster(FestivalModel newPoster) {
    poster = newPoster;
    _pingPoster();
  }

  // 목록/검색 등 미리보기용 화면에서 넘어온 FestivalModel에는 예매 링크가 실려
  // 있지 않으므로, 진입 경로와 무관하게 항상 이 notifier에서 직접 조회한다.
  // 없어도 티켓 버튼만 안 보일 뿐 나머지 정보는 정상 표시되므로 실패해도
  // hasInitError(재시도 안내)는 띄우지 않는다.
  Future<void> loadTicketLinks() async {
    try {
      ticketLinks = await detailService.fetchTicketLinks(festivalId);
      safeNotify();
      _pingActionButtons();
    } catch (e) {
      debugPrint('[FestivalPoster] 예매 링크 로드 실패: $e');
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
    try {
      await optimisticToggle(
        attending,
        apply: (v) {
          attending = v;
          // apply는 낙관적 적용(반대값)과 실패 시 롤백(원래값) 양쪽에서 호출된다 —
          // 롤백 호출(v == prevAttending)은 공식으로 재계산하지 않고 원래 카운트를 그대로 복원
          attendingCount = v == prevAttending
              ? prevCount
              : (v ? prevCount + 1 : max(0, prevCount - 1));
          _pingAttending();
        },
        action: () => festivalService.toggleAttending(festivalId),
        onError: () => onError?.call('attend_failed'),
      );
    } finally {
      isTogglingAttend = false;
      safeNotify();
    }
  }

  void toggleDesc() {
    descExpanded = !descExpanded;
    safeNotify();
    unawaited(_saveDescStateSafely(descExpanded));
  }

  Future<void> _saveDescStateSafely(bool expanded) async {
    try {
      await saveDescState(expanded);
    } catch (e) {
      debugPrint('saveDescState error: $e');
    }
  }
}
