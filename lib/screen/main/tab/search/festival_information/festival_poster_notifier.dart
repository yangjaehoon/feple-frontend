import 'package:feple/common/app_events.dart';
import 'package:feple/model/certification_model.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FestivalPosterNotifier extends ChangeNotifier {
  final int festivalId;
  final CertificationService certService;
  final FestivalService festivalService;

  bool liked = false;
  bool descExpanded = true;
  bool isCertified = false;
  bool isPending = false;

  String get _descPrefKey => 'festival_desc_expanded_$festivalId';

  FestivalPosterNotifier({
    required this.festivalId,
    required this.certService,
    required this.festivalService,
  });

  Future<void> init() async {
    await Future.wait([loadLikeState(), loadDescState(), loadCertState()]);
  }

  Future<void> loadLikeState() async {
    try {
      liked = await festivalService.isLiked(festivalId);
      notifyListeners();
    } catch (e) {
      debugPrint('loadLikeState error: $e');
    }
  }

  Future<void> loadDescState() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getBool(_descPrefKey);
    if (saved != null) {
      descExpanded = saved;
      notifyListeners();
    }
  }

  Future<void> saveDescState(bool expanded) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_descPrefKey, expanded);
  }

  Future<void> loadCertState() async {
    try {
      final certs = await certService.getMyCertifications();
      final mine = certs.where((c) => c.festivalId == festivalId).toList();
      isCertified = mine.any((c) => c.status == CertStatus.approved);
      isPending = !isCertified && mine.any((c) => c.status == CertStatus.pending);
      notifyListeners();
    } catch (e) {
      debugPrint('[FestivalPoster] 인증 상태 로드 실패: $e');
    }
  }

  Future<void> toggleLike() async {
    final prev = liked;
    liked = !liked;
    notifyListeners();
    AppEvents.likeChanged.value++;
    try {
      await festivalService.toggleLike(festivalId);
    } catch (e) {
      liked = prev;
      notifyListeners();
      debugPrint('toggleLike error: $e');
    }
  }

  void toggleDesc() {
    descExpanded = !descExpanded;
    notifyListeners();
    saveDescState(descExpanded);
  }
}
