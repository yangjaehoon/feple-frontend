import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_model.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/search/w_search_result_tiles.dart';
import 'package:feple/service/search_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UnifiedSearchScreen extends StatefulWidget {
  const UnifiedSearchScreen({super.key});

  @override
  State<UnifiedSearchScreen> createState() => _UnifiedSearchScreenState();
}

class _UnifiedSearchScreenState extends State<UnifiedSearchScreen>
    with SingleTickerProviderStateMixin {
  static const _prefsKey = 'feple_recent_searches';
  static const _maxRecent = 10;

  final _searchService = sl<SearchService>();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;
  late final TabController _tabController;

  bool _loading = false;
  bool _searched = false;
  bool _hasError = false;

  List<Artist> _artists = [];
  List<FestivalPreview> _festivals = [];
  List<Post> _posts = [];
  List<SearchSuggestion> _suggestions = [];
  List<String> _recentSearches = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _controller.addListener(_onTextChanged);
    _loadRecentSearches();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  // ── recent searches ──────────────────────────────────────────────────────

  Future<void> _loadRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() => _recentSearches = prefs.getStringList(_prefsKey) ?? []);
  }

  Future<void> _addRecentSearch(String keyword) async {
    if (keyword.trim().isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    final list = List<String>.from(_recentSearches)..remove(keyword);
    list.insert(0, keyword);
    if (list.length > _maxRecent) list.removeLast();
    await prefs.setStringList(_prefsKey, list);
    if (mounted) setState(() => _recentSearches = list);
  }

  Future<void> _removeRecentSearch(String keyword) async {
    final prefs = await SharedPreferences.getInstance();
    final list = List<String>.from(_recentSearches)..remove(keyword);
    await prefs.setStringList(_prefsKey, list);
    if (mounted) setState(() => _recentSearches = list);
  }

  Future<void> _clearRecentSearches() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefsKey);
    if (mounted) setState(() => _recentSearches = []);
  }

  // ── search ────────────────────────────────────────────────────────────────

  void _onTextChanged() {
    setState(() => _searched = false);
    _debounce?.cancel();
    if (_controller.text.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(
      AppDimens.animNormal,
      () => _fetchSuggestions(_controller.text.trim()),
    );
  }

  Future<void> _fetchSuggestions(String keyword) async {
    try {
      final results = await _searchService.suggestions(keyword);
      if (mounted) setState(() => _suggestions = results);
    } catch (e) {
      debugPrint('[Search] 자동완성 로드 실패: $e');
    }
  }

  Future<void> _search(String keyword) async {
    if (keyword.trim().isEmpty) return;
    _debounce?.cancel();
    _focusNode.unfocus();
    setState(() {
      _loading = true;
      _searched = true;
      _hasError = false;
      _suggestions = [];
    });
    await _addRecentSearch(keyword.trim());
    try {
      final result = await _searchService.search(keyword);
      if (mounted) {
        _tabController.animateTo(0);
        setState(() {
          _artists = result.artists;
          _festivals = result.festivals;
          _posts = result.posts;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[Search] 검색 실패: $e');
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  void _selectSuggestion(String label) {
    _controller.text = label;
    _controller.selection = TextSelection.collapsed(offset: label.length);
    _search(label);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabController.dispose();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          _buildSearchBar(colors),
          Expanded(child: _buildContent(colors)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(AbstractThemeColors colors) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: AppDimens.appBarHeight,
        color: colors.appBarColor,
        child: Row(
          children: [
            IconButton(
              tooltip: 'back'.tr(),
              icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: const TextStyle(color: Colors.white, fontSize: AppDimens.fontSizeXl),
                cursorColor: Colors.white70,
                decoration: InputDecoration(
                  hintText: 'search_hint'.tr(),
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  filled: false,
                  suffixIcon: _controller.text.isNotEmpty
                      ? IconButton(
                          tooltip: 'clear'.tr(),
                          icon: const Icon(Icons.clear, color: Colors.white70),
                          onPressed: () {
                            _controller.clear();
                            setState(() {
                              _searched = false;
                              _artists = [];
                              _festivals = [];
                              _posts = [];
                              _suggestions = [];
                            });
                          },
                        )
                      : null,
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
              ),
            ),
            IconButton(
              tooltip: 'search'.tr(),
              icon: const Icon(Icons.search_rounded, color: Colors.white),
              onPressed: () => _search(_controller.text),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(AbstractThemeColors colors) {
    if (_loading) {
      return Center(child: CircularProgressIndicator(color: colors.loadingIndicator));
    }
    if (_searched) return _hasError ? _buildError() : _buildResults(colors);
    if (_controller.text.isEmpty) return _buildRecentSearches(colors);
    return _buildSuggestions(colors);
  }

  Widget _buildRecentSearches(AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'recent_searches'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
              if (_recentSearches.isNotEmpty)
                TextButton(
                  onPressed: _clearRecentSearches,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'clear_all'.tr(),
                    style: TextStyle(fontSize: 12, color: colors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
        if (_recentSearches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'no_recent_searches'.tr(),
              style: TextStyle(fontSize: 13, color: colors.textSecondary.withValues(alpha: 0.6)),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _recentSearches.length,
              itemBuilder: (_, index) {
                final keyword = _recentSearches[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  dense: true,
                  leading: Icon(Icons.history_rounded, size: 18, color: colors.textSecondary),
                  title: Text(
                    keyword,
                    style: TextStyle(fontSize: 14, color: colors.textTitle),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.close_rounded, size: 16, color: colors.textSecondary),
                    onPressed: () => _removeRecentSearch(keyword),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  onTap: () {
                    _controller.text = keyword;
                    _controller.selection =
                        TextSelection.collapsed(offset: keyword.length);
                    _search(keyword);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildSuggestions(AbstractThemeColors colors) {
    if (_suggestions.isEmpty) return const SizedBox.shrink();
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _suggestions.length,
      separatorBuilder: (_, __) => Divider(
        height: 1,
        thickness: 1,
        color: colors.listDivider,
        indent: 56,
        endIndent: 16,
      ),
      itemBuilder: (_, index) {
        final suggestion = _suggestions[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Icon(
            suggestion.type.icon,
            color: colors.textSecondary,
            size: 20,
          ),
          title: _buildHighlightedSuggestion(suggestion.label, _controller.text.trim(), colors),
          trailing: Icon(Icons.north_west_rounded, size: 16, color: colors.textSecondary),
          onTap: () => _selectSuggestion(suggestion.label),
        );
      },
    );
  }

  Widget _buildHighlightedSuggestion(String label, String query, AbstractThemeColors colors) {
    final lowerLabel = label.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matchIndex = lowerLabel.indexOf(lowerQuery);
    if (matchIndex == -1 || query.isEmpty) {
      return Text(label, style: TextStyle(color: colors.textTitle, fontSize: 15));
    }
    return RichText(
      text: TextSpan(
        style: TextStyle(color: colors.textTitle, fontSize: 15),
        children: [
          if (matchIndex > 0) TextSpan(text: label.substring(0, matchIndex)),
          TextSpan(
            text: label.substring(matchIndex, matchIndex + query.length),
            style: TextStyle(color: colors.activate, fontWeight: FontWeight.w700),
          ),
          if (matchIndex + query.length < label.length)
            TextSpan(text: label.substring(matchIndex + query.length)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return ErrorState(
      message: 'search_error'.tr(),
      onRetry: () => _search(_controller.text),
    );
  }

  Widget _buildResults(AbstractThemeColors colors) {
    final total = _artists.length + _festivals.length + _posts.length;
    if (total == 0) {
      return EmptyState(icon: Icons.search_off_rounded, title: 'search_no_result'.tr());
    }

    final keyword = _controller.text.trim();

    return Column(
      children: [
        _buildTabBar(colors),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildAllTab(colors, keyword),
              _buildCategoryTab(
                colors,
                items: _artists,
                builder: (d) => SearchArtistTile(data: d, highlightKeyword: keyword),
                emptyIcon: Icons.person_search_rounded,
              ),
              _buildCategoryTab(
                colors,
                items: _festivals,
                builder: (d) => SearchFestivalTile(data: d, highlightKeyword: keyword),
                emptyIcon: Icons.festival_rounded,
              ),
              _buildCategoryTab(
                colors,
                items: _posts,
                builder: (d) => SearchPostTile(data: d, highlightKeyword: keyword),
                emptyIcon: Icons.article_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabBar(AbstractThemeColors colors) {
    final labels = [
      'search_all'.tr(),
      'search_artists'.tr(),
      'search_festivals'.tr(),
      'search_posts'.tr(),
    ];
    final counts = [null, _artists.length, _festivals.length, _posts.length];

    return TabBar(
      controller: _tabController,
      isScrollable: true,
      tabAlignment: TabAlignment.start,
      labelColor: colors.activate,
      unselectedLabelColor: colors.textSecondary,
      indicatorColor: colors.activate,
      indicatorWeight: 2,
      labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
      tabs: List.generate(labels.length, (i) {
        final count = counts[i];
        return Tab(
          text: count != null && count > 0 ? '${labels[i]} ($count)' : labels[i],
        );
      }),
    );
  }

  Widget _buildAllTab(AbstractThemeColors colors, String keyword) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        if (_artists.isNotEmpty) ...[
          _sectionHeader('search_artists'.tr(), _artists.length, colors),
          ..._artists.map((d) => SearchArtistTile(data: d, highlightKeyword: keyword)),
          const SizedBox(height: 16),
        ],
        if (_festivals.isNotEmpty) ...[
          _sectionHeader('search_festivals'.tr(), _festivals.length, colors),
          ..._festivals.map((d) => SearchFestivalTile(data: d, highlightKeyword: keyword)),
          const SizedBox(height: 16),
        ],
        if (_posts.isNotEmpty) ...[
          _sectionHeader('search_posts'.tr(), _posts.length, colors),
          ..._posts.map((d) => SearchPostTile(data: d, highlightKeyword: keyword)),
        ],
      ],
    );
  }

  Widget _buildCategoryTab<T>(
    AbstractThemeColors colors, {
    required List<T> items,
    required Widget Function(T) builder,
    required IconData emptyIcon,
  }) {
    if (items.isEmpty) {
      return EmptyState(icon: emptyIcon, title: 'search_no_result'.tr());
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      itemCount: items.length,
      itemBuilder: (_, i) => builder(items[i]),
      separatorBuilder: (_, __) => Divider(height: 1, color: colors.listDivider),
    );
  }

  Widget _sectionHeader(String title, int count, AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 3,
            height: 18,
            decoration: BoxDecoration(
              color: colors.sectionBarColor,
              borderRadius: BorderRadius.circular(AppDimens.barRadius),
            ),
          ),
          const SizedBox(width: 8),
          Text(title,
              style: TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w800, color: colors.textTitle)),
          const SizedBox(width: 6),
          Text('($count)', style: TextStyle(fontSize: 13, color: colors.textSecondary)),
        ],
      ),
    );
  }
}
