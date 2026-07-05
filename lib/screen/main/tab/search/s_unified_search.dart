import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_model.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/search/artist_page/s_artist_page.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/screen/main/tab/search/search_style.dart';
import 'package:feple/screen/main/tab/search/w_search_result_tiles.dart';
import 'package:feple/service/artist_service.dart';
import 'package:feple/service/festival_service.dart';
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
  final _artistService = sl<ArtistService>();
  final _festivalService = sl<FestivalService>();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  bool _isNavigating = false;
  Timer? _debounce;
  late final TabController _tabController;

  bool _isLoading = false;
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
      _isLoading = true;
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
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[Search] 검색 실패: $e');
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
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
    if (_isNavigating) return;
    _isNavigating = true;
    _focusNode.unfocus();
    await _addRecentSearch(suggestion.label.trim());
    try {
      if (suggestion.type == SearchType.artist) {
        final artist = await _artistService.fetchArtistById(suggestion.id!);
        if (!mounted) return;
        await Navigator.push(context, SlideRoute(
          builder: (_) => ArtistScreen(
            artistId: artist.id,
            artistName: artist.name,
            artistNameEn: artist.nameEn,
            followerCount: artist.followerCount,
            profileImageUrl: artist.profileImageUrl,
          ),
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
      if (mounted) _search(suggestion.label);
    } finally {
      if (mounted) _isNavigating = false;
    }
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
              icon: Icon(Icons.arrow_back_ios_rounded, color: colors.appBarIconColor),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: TextStyle(color: colors.appBarIconColor, fontSize: AppDimens.fontSizeXl),
                cursorColor: Colors.white70,
                decoration: InputDecoration(
                  hintText: 'search_hint'.tr(),
                  hintStyle: const TextStyle(color: Colors.white54),
                  border: InputBorder.none,
                  filled: false,
                  suffixIcon: _buildClearSuffix(),
                ),
                textInputAction: TextInputAction.search,
                onSubmitted: _search,
              ),
            ),
            IconButton(
              tooltip: 'search'.tr(),
              icon: Icon(Icons.search_rounded, color: colors.appBarIconColor),
              onPressed: () => _search(_controller.text),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildClearSuffix() {
    if (_controller.text.isEmpty) return null;
    return IconButton(
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
    );
  }

  Widget _buildContent(AbstractThemeColors colors) {
    if (_isLoading) return _buildLoadingSkeleton(colors);
    if (_searched) return _hasError ? _buildError() : _buildResults(colors);
    if (_controller.text.isEmpty) return _buildRecentSearches(colors);
    return _buildSuggestions(colors);
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
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(height: 14, width: 160),
                  SizedBox(height: 6),
                  SkeletonBox(height: 12, width: 100),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches(AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildRecentHeader(colors),
        if (_recentSearches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'no_recent_searches'.tr(),
              style: TextStyle(fontSize: AppDimens.fontSizeSm, color: colors.textSecondary.withValues(alpha: 0.6)),
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
                  title: Text(keyword, style: TextStyle(fontSize: AppDimens.fontSizeMd, color: colors.textTitle)),
                  trailing: IconButton(
                    tooltip: 'delete'.tr(),
                    icon: Icon(Icons.close_rounded, size: 16, color: colors.textSecondary),
                    onPressed: () => _removeRecentSearch(keyword),
                  ),
                  onTap: () {
                    _controller.text = keyword;
                    _controller.selection = TextSelection.collapsed(offset: keyword.length);
                    _search(keyword);
                  },
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildRecentHeader(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'recent_searches'.tr(),
            style: TextStyle(fontSize: AppDimens.fontSizeSm, fontWeight: FontWeight.w700, color: colors.textSecondary),
          ),
          if (_recentSearches.isNotEmpty)
            TextButton(
              onPressed: _clearRecentSearches,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.padded,
              ),
              child: Text(
                'clear_all'.tr(),
                style: TextStyle(fontSize: AppDimens.fontSizeXs, color: colors.textSecondary),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(AbstractThemeColors colors) {
    if (_suggestions.isEmpty) return const SizedBox.shrink();
    final artists = _suggestions.where((s) => s.type == SearchType.artist).toList();
    final festivals = _suggestions.where((s) => s.type == SearchType.festival).toList();
    return ListView(
      padding: const EdgeInsets.only(bottom: 8),
      children: [
        if (artists.isNotEmpty) ...[
          _buildSuggestionGroupHeader('search_artists'.tr(), colors),
          ..._buildSuggestionTiles(artists, colors),
        ],
        if (festivals.isNotEmpty) ...[
          _buildSuggestionGroupHeader('search_festivals'.tr(), colors),
          ..._buildSuggestionTiles(festivals, colors),
        ],
      ],
    );
  }

  Widget _buildSuggestionGroupHeader(String label, AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 2),
      child: Text(
        label,
        style: TextStyle(
          fontSize: AppDimens.fontSizeXs,
          fontWeight: FontWeight.w700,
          color: colors.textSecondary,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  List<Widget> _buildSuggestionTiles(List<SearchSuggestion> items, AbstractThemeColors colors) {
    return List.generate(items.length, (i) {
      final suggestion = items[i];
      return Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
            leading: _buildSuggestionLeading(suggestion, colors),
            title: _buildHighlightedSuggestion(suggestion.displayLabel(context.isEnglish), _controller.text.trim(), colors),
            trailing: Icon(Icons.north_west_rounded, size: 16, color: colors.textSecondary),
            onTap: () => _selectSuggestion(suggestion),
          ),
          if (i < items.length - 1)
            Divider(height: 1, thickness: 1, color: colors.listDivider, indent: 72, endIndent: 16),
        ],
      );
    });
  }

  Widget _buildSuggestionLeading(SearchSuggestion suggestion, AbstractThemeColors colors) {
    final imageUrl = suggestion.imageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      return Icon(suggestion.type.icon, color: colors.textSecondary, size: 20);
    }
    if (suggestion.type == SearchType.artist) {
      return CircleAvatar(
        radius: 20,
        backgroundColor: colors.textSecondary.withValues(alpha: 0.2),
        backgroundImage: CachedNetworkImageProvider(imageUrl),
      );
    } else {
      return ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedNetworkImage(
          imageUrl: imageUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          placeholder: (_, _) => Container(
            width: 40,
            height: 40,
            color: colors.textSecondary.withValues(alpha: 0.2),
          ),
          errorWidget: (_, _, _) => Icon(suggestion.type.icon, color: colors.textSecondary, size: 20),
        ),
      );
    }
  }

  Widget _buildHighlightedSuggestion(String label, String query, AbstractThemeColors colors) {
    final lowerLabel = label.toLowerCase();
    final lowerQuery = query.toLowerCase();
    final matchIndex = lowerLabel.indexOf(lowerQuery);
    if (matchIndex == -1 || query.isEmpty) {
      return Text(label, style: TextStyle(color: colors.textTitle, fontSize: AppDimens.fontSizeLg));
    }
    return RichText(
      text: TextSpan(
        style: TextStyle(color: colors.textTitle, fontSize: AppDimens.fontSizeLg),
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
      labelStyle: const TextStyle(fontSize: AppDimens.fontSizeSm, fontWeight: FontWeight.w700),
      unselectedLabelStyle: const TextStyle(fontSize: AppDimens.fontSizeSm, fontWeight: FontWeight.w400),
      tabs: List.generate(labels.length, (i) {
        final count = counts[i];
        return Tab(
          text: count != null && count > 0 ? '${labels[i]} ($count)' : labels[i],
        );
      }),
    );
  }

  Widget _buildAllTab(AbstractThemeColors colors, String keyword) {
    final hasArtists = _artists.isNotEmpty;
    final hasFestivals = _festivals.isNotEmpty;
    final hasPosts = _posts.isNotEmpty;
    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        if (hasArtists) ...[
          _sectionHeader('search_artists'.tr(), _artists.length, colors, isFirst: true),
          ..._artists.map((d) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchArtistTile(data: d, highlightKeyword: keyword),
          )),
        ],
        if (hasFestivals) ...[
          _sectionHeader('search_festivals'.tr(), _festivals.length, colors, isFirst: !hasArtists),
          ..._festivals.map((d) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchFestivalTile(data: d, highlightKeyword: keyword),
          )),
        ],
        if (hasPosts) ...[
          _sectionHeader('search_posts'.tr(), _posts.length, colors, isFirst: !hasArtists && !hasFestivals),
          ..._posts.map((d) => Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SearchPostTile(data: d, highlightKeyword: keyword),
          )),
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
      separatorBuilder: (_, _) => Divider(height: 1, color: colors.listDivider),
    );
  }

  Widget _sectionHeader(String title, int count, AbstractThemeColors colors, {bool isFirst = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isFirst) Divider(height: 1, thickness: 1, color: colors.listDivider),
        Padding(
          padding: EdgeInsets.fromLTRB(16, isFirst ? 16 : 20, 16, 8),
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
                      fontSize: AppDimens.fontSizeLg, fontWeight: FontWeight.w800, color: colors.textTitle)),
              const SizedBox(width: 6),
              Text('($count)', style: TextStyle(fontSize: AppDimens.fontSizeSm, color: colors.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}
