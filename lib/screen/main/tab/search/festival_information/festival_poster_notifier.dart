import 'package:feple/common/app_events.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/certification_service.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FestivalPosterNotifier extends ChangeNotifier {
  final int festivalId;
  final CertificationService certService;

  bool liked = false;
  bool descExpanded = true;
  bool isCertified = false;
  bool isPending = false;

  String get _descPrefKey => 'festival_desc_expanded_$festivalId';

  FestivalPosterNotifier({required this.festivalId, required this.certService});

  Future<void> init() async {
    await Future.wait([loadLikeState(), loadDescState(), loadCertState()]);
  }

  Future<void> loadLikeState() async {
    try {
      final resp = await DioClient.dio.get('/festivals/$festivalId/liked');
      liked = resp.data as bool;
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
      final mine = certs.where((c) => c['festivalId'] == festivalId).toList();
      isCertified = mine.any((c) => c['status'] == 'APPROVED');
      isPending = !isCertified && mine.any((c) => c['status'] == 'PENDING');
      notifyListeners();
    } catch (e) {
      debugPrint('[FestivalPoster] 인증 상태 로드 실패: $e');
    }
  }

  Future<void> toggleLike() async {
    try {
      final resp = await DioClient.dio.post('/festivals/$festivalId/like');
      liked = resp.data as bool;
      notifyListeners();
      AppEvents.likeChanged.value++;
    } catch (e) {
      debugPrint('toggleLike error: $e');
    }
  }

  void toggleDesc() {
    descExpanded = !descExpanded;
    notifyListeners();
    saveDescState(descExpanded);
  }
}
