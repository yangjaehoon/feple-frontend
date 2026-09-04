import 'package:dio/dio.dart' show CancelToken;
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/debouncer.dart';
import 'package:feple/common/util/navigation_guard.dart';
import 'package:feple/common/util/request_scope.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_keyboard_dismiss.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_model.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_page.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/screen/main/tab/search/recent_search_store.dart';
import 'package:feple/screen/main/tab/search/w_recent_searches.dart';
import 'package:feple/screen/main/tab/search/w_search_input_bar.dart';
import 'package:feple/screen/main/tab/search/w_search_results.dart';
import 'package:feple/screen/main/tab/search/w_search_suggestions.dart';
import 'package:feple/service/artist_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/service/search_service.dart';
import 'package:flutter/material.dart';

class UnifiedSearchScreen extends StatefulWidget {
  const UnifiedSearchScreen({super.key});

  @override
  State<UnifiedSearchScreen> createState() => _UnifiedSearchScreenState();
}

class _UnifiedSearchScreenState extends State<UnifiedSearchScreen>
    with SingleTickerProviderStateMixin, NavigationGuard {
  final _searchService = sl<SearchService>();
  final _artistService = sl<ArtistService>();
  final _festivalService = sl<FestivalService>();
  final _recentSearchStore = RecentSearchStore();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _debounce = Debouncer(AppDimens.debounceSearch);
  late final TabController _tabController;

  bool _isLoading = false;
  bool _searched = false;
  bool _hasError = false;
  // 응답이 늦게 도착했을 때 이미 지나간 키워드로 최신 결과를 덮어쓰지 않도록 가드
  // (mock 기반 위젯 테스트처럼 취소를 존중하지 않는 경로에서도 동작)
  int _suggestionsRequestId = 0;
  int _searchRequestId = 0;
  // 새 요청이 이전 요청을 대체할 때 진행 중이던 실제 네트워크 요청을 중단한다.
  CancelToken _suggestToken = CancelToken();
  CancelToken _searchToken = CancelToken();

  List<Artist> _artists = [];
  List<FestivalPreview> _festivals = [];
  List<Post> _posts = [];
  // 키 입력마다 갱신되므로 setState(전체 화면 리빌드) 대신 별도 Listenable로 분리 —
  // 검색바(TextField)는 그대로 두고 본문 영역만 다시 그리기 위함 (build() 참고)
  final _suggestionsNotifier = ValueNotifier<List<SearchSuggestion>>([]);
  List<String> _recentSearches = [];
  // 제안 탭 → fetchById → 화면 전환까지 아무 피드백 없이 멈춰 보이는 걸 방지
  int? _navigatingSuggestionId;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _controller.addListener(_onTextChanged);
    _recentSearches = _recentSearchStore.load();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  // ── recent searches ──────────────────────────────────────────────────────

  Future<void> _addRecentSearch(String keyword) async {
    final list = await _recentSearchStore.add(_recentSearches, keyword);
    if (mounted) setState(() => _recentSearches = list);
  }

  Future<void> _removeRecentSearch(String keyword) async {
    final list = await _recentSearchStore.remove(_recentSearches, keyword);
    if (mounted) setState(() => _recentSearches = list);
  }

  Future<void> _clearRecentSearches() async {
    final list = await _recentSearchStore.clear();
    if (mounted) setState(() => _recentSearches = list);
  }

  // ── search ────────────────────────────────────────────────────────────────

  void _onTextChanged() {
    // setState 대신 필드만 갱신 — _controller 자체가 이미 Listenable이라 build()의
    // AnimatedBuilder가 이 변경을 감지해서 본문만 다시 그림 (검색바는 그대로 유지)
    _searched = false;
    if (_controller.text.trim().isEmpty) {
      _debounce.cancel();
      _suggestToken.cancel();
      _suggestionsNotifier.value = [];
      return;
    }
    _debounce.run(() => _fetchSuggestions(_controller.text.trim()));
  }

  Future<void> _fetchSuggestions(String keyword) async {
    final requestId = ++_suggestionsRequestId;
    _suggestToken.cancel();
    _suggestToken = CancelToken();
    final token = _suggestToken;
    try {
      final results = await withCancelScope(
        token,
        () => _searchService.suggestions(keyword),
      );
      if (mounted && requestId == _suggestionsRequestId) {
        _suggestionsNotifier.value = results;
      }
    } catch (e) {
      if (isRequestCancelled(e)) return;
      debugPrint('[Search] 자동완성 로드 실패: $e');
    }
  }

  Future<void> _search(String keyword) async {
    if (keyword.trim().isEmpty) return;
    final requestId = ++_searchRequestId;
    _debounce.cancel();
    _suggestToken.cancel(); // 진행 중이던 자동완성 요청 중단
    _searchToken.cancel();
    _searchToken = CancelToken();
    final token = _searchToken;
    _focusNode.unfocus();
    _suggestionsNotifier.value = [];
    setState(() {
      _isLoading = true;
      _searched = true;
      _hasError = false;
    });
    await _addRecentSearch(keyword.trim());
    try {
      final result =
          await withCancelScope(token, () => _searchService.search(keyword));
      if (mounted && requestId == _searchRequestId) {
        _tabController.animateTo(0);
        setState(() {
          _artists = result.artists;
          _festivals = result.festivals;
          _posts = result.posts;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (isRequestCancelled(e)) return;
      debugPrint('[Search] 검색 실패: $e');
      if (mounted && requestId == _searchRequestId) {
        setState(() { _isLoading = false; _hasError = true; });
      }
    }
  }

  void _selectSuggestion(SearchSuggestion suggestion) {
    _controller.text = suggestion.label;
    _controller.selection = TextSelection.collapsed(offset: suggestion.label.length);
    if (suggestion.id != null) {
      _navigateDirectly(suggestion);
    } else {
      _search(suggestion.label);
    }
  }

  Future<void> _navigateDirectly(SearchSuggestion suggestion) async {
    // 직전 text/selection 변경으로 예약된 자동완성 재조회를 취소 — 그대로 두면
    // 상세 화면으로 이동한 뒤 백그라운드에서 실행되어, 돌아왔을 때 방금 선택한
    // 항목의 자동완성 목록이 엉뚱하게 다시 떠 있게 됨
    _debounce.cancel();
    _suggestToken.cancel();
    await guardedNavigate(() async {
      _focusNode.unfocus();
      setState(() => _navigatingSuggestionId = suggestion.id);
      await _addRecentSearch(suggestion.label.trim());
      try {
        if (suggestion.type == SearchType.artist) {
          final artist = await _artistService.fetchArtistById(suggestion.id!);
          if (!mounted) return;
          await Navigator.push(context, SlideRoute(
            builder: (_) => ArtistScreen.fromArtist(artist),
          ));
        } else {
          final festival = await _festivalService.fetchById(suggestion.id!);
          if (!mounted) return;
          await Navigator.push(context, SlideRoute(
            builder: (_) => FestivalInformationFragment(poster: festival),
          ));
        }
      } catch (e) {
        debugPrint('[Search] 직접 이동 실패: $e');
        if (mounted) unawaited(_search(suggestion.label));
      } finally {
        if (mounted) setState(() => _navigatingSuggestionId = null);
      }
    });
  }

  @override
  void dispose() {
    _debounce.dispose();
    _suggestToken.cancel();
    _searchToken.cancel();
    _tabController.dispose();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    _suggestionsNotifier.dispose();
    super.dispose();
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: KeyboardDismiss(
        child: Column(
          children: [
            SearchInputBar(
              controller: _controller,
              focusNode: _focusNode,
              onSubmitted: _search,
              onSearch: () => _search(_controller.text),
              onClear: _onClearPressed,
            ),
            Expanded(
              // 키 입력마다 검색바(TextField)까지 통째로 리빌드되지 않도록, 본문만
              // _controller/_suggestionsNotifier 변경에 반응해서 다시 그림
              child: AnimatedBuilder(
                animation: Listenable.merge([_controller, _suggestionsNotifier]),
                builder: (context, _) => _buildContent(colors),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onClearPressed() {
    _controller.clear();
    _suggestionsNotifier.value = [];
    setState(() {
      _searched = false;
      _artists = [];
      _festivals = [];
      _posts = [];
    });
  }

  void _onRecentTap(String keyword) {
    _controller.text = keyword;
    _controller.selection =
        TextSelection.collapsed(offset: keyword.length);
    _search(keyword);
  }

  Widget _buildContent(AbstractThemeColors colors) {
    if (_isLoading) return _buildLoadingSkeleton(colors);
    if (_searched) {
      return _hasError
          ? _buildError()
          : SearchResultsView(
              artists: _artists,
              festivals: _festivals,
              posts: _posts,
              keyword: _controller.text.trim(),
              tabController: _tabController,
            );
    }
    if (_controller.text.isEmpty) {
      return RecentSearchesView(
        recentSearches: _recentSearches,
        onSelect: _onRecentTap,
        onRemove: _removeRecentSearch,
        onClearAll: _clearRecentSearches,
      );
    }
    return SearchSuggestionsView(
      suggestions: _suggestionsNotifier.value,
      highlightKeyword: _controller.text.trim(),
      navigatingId: _navigatingSuggestionId,
      onSelect: _selectSuggestion,
    );
  }

  Widget _buildLoadingSkeleton(AbstractThemeColors colors) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: 6,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            const SkeletonBox(width: 40, height: 40, borderRadius: BorderRadius.all(Radius.circular(20))),
            const SizedBox(width: AppDimens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(height: 14, width: 160),
                  SizedBox(height: AppDimens.space6),
                  SkeletonBox(height: 12, width: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return ErrorState(
      message: 'search_error'.tr(),
      onRetry: () => _search(_controller.text),
    );
  }
}
