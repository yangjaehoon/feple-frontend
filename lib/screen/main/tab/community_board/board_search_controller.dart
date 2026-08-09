import 'dart:async';

import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/safe_change_notifier.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/service/post_service.dart';
import 'package:flutter/foundation.dart';

/// 게시판 검색바의 디바운스·race-guard·결과 상태를 담당.
/// [CommunityPost] 위젯 State에 직접 있던 검색 로직을 분리했다.
class BoardSearchController extends SafeChangeNotifier {
  final PostService postService;
  final String boardType;

  BoardSearchController({required this.postService, required this.boardType});

  bool _isSearching = false;
  List<Post>? _results;
  Timer? _debounce;
  // 응답이 늦게 도착했을 때 이미 지나간 키워드로 최신 결과를 덮어쓰지 않도록 가드
  // (submit이 디바운스를 우회해 즉시 호출되면서 이전 요청과 겹칠 수 있음)
  int _requestId = 0;

  bool get isSearching => _isSearching;
  List<Post>? get results => _results;

  /// 검색어가 입력된 상태(빈 문자열로 초기화되지 않은 상태)인지
  bool get isActive => _results != null;

  void schedule(String keyword) {
    _debounce?.cancel();
    _debounce = Timer(AppDimens.animNormal, () => search(keyword));
  }

  Future<void> search(String keyword) async {
    _debounce?.cancel();
    final requestId = ++_requestId;
    if (keyword.trim().isEmpty) {
      _results = null;
      safeNotify();
      return;
    }
    _isSearching = true;
    safeNotify();
    try {
      final results = await postService.searchInBoard(keyword.trim(), boardType);
      if (requestId != _requestId) return;
      _results = results;
      _isSearching = false;
      safeNotify();
    } catch (e) {
      debugPrint('[BoardSearchController] 검색 실패: $e');
      if (requestId != _requestId) return;
      _isSearching = false;
      safeNotify();
    }
  }

  void clear() {
    _debounce?.cancel();
    _results = null;
    _isSearching = false;
    safeNotify();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}
