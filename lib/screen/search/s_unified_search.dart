import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/screen/search/w_search_result_tiles.dart';
import 'package:flutter/material.dart';

class UnifiedSearchScreen extends StatefulWidget {
  const UnifiedSearchScreen({super.key});

  @override
  State<UnifiedSearchScreen> createState() => _UnifiedSearchScreenState();
}

class _UnifiedSearchScreenState extends State<UnifiedSearchScreen> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  bool _loading = false;
  bool _searched = false;
  bool _hasError = false;

  List<dynamic> _artists = [];
  List<dynamic> _festivals = [];
  List<dynamic> _posts = [];
  List<_SuggestionItem> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNode.requestFocus();
    });
  }

  void _onTextChanged() {
    setState(() {
      _searched = false;
    });
    _debounce?.cancel();
    if (_controller.text.trim().isEmpty) {
      setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(
      const Duration(milliseconds: 300),
      () => _fetchSuggestions(_controller.text.trim()),
    );
  }

  Future<void> _fetchSuggestions(String keyword) async {
    try {
      final res = await DioClient.dio.get('/search', queryParameters: {'keyword': keyword});
      if (!mounted) return;
      final data = res.data as Map<String, dynamic>;
      final artists = (data['artists'] as List? ?? [])
          .map((a) => _SuggestionItem(a['name'] as String? ?? '', 'artist'))
          .where((s) => s.label.isNotEmpty)
          .toList();
      final festivals = (data['festivals'] as List? ?? [])
          .map((f) => _SuggestionItem(f['title'] as String? ?? '', 'festival'))
          .where((s) => s.label.isNotEmpty)
          .toList();
      setState(() => _suggestions = [...artists, ...festivals]);
    } catch (_) {
      // 연관검색어 실패는 무시
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
    try {
      final res = await DioClient.dio.get('/search', queryParameters: {'keyword': keyword.trim()});
      final data = res.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
          _artists   = (data['artists']   as List? ?? []);
          _festivals = (data['festivals'] as List? ?? []);
          _posts     = (data['posts']     as List? ?? []);
          _loading   = false;
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
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              height: AppDimens.appBarHeight,
              color: colors.appBarColor,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      focusNode: _focusNode,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                      cursorColor: Colors.white70,
                      decoration: InputDecoration(
                        hintText: 'search_hint'.tr(),
                        hintStyle: const TextStyle(color: Colors.white54),
                        border: InputBorder.none,
                        filled: false,
                        suffixIcon: _controller.text.isNotEmpty
                            ? IconButton(
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
                    icon: const Icon(Icons.search_rounded, color: Colors.white),
                    onPressed: () => _search(_controller.text),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: colors.loadingIndicator))
                : _searched
                    ? (_hasError ? _buildError() : _buildResults(colors))
                    : _controller.text.isEmpty
                        ? _buildEmptyHint()
                        : _buildSuggestions(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(AbstractThemeColors colors) {
    if (_suggestions.isEmpty) {
      return const SizedBox.shrink();
    }
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
        final s = _suggestions[index];
        return ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
          leading: Icon(
            s.type == 'artist' ? Icons.person_rounded : Icons.festival_rounded,
            color: colors.textSecondary,
            size: 20,
          ),
          title: _buildHighlightedText(s.label, _controller.text.trim(), colors),
          trailing: Icon(Icons.north_west_rounded, size: 16, color: colors.textSecondary),
          onTap: () => _selectSuggestion(s.label),
        );
      },
    );
  }

  Widget _buildHighlightedText(String label, String query, AbstractThemeColors colors) {
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
          if (matchIndex > 0)
            TextSpan(text: label.substring(0, matchIndex)),
          TextSpan(
            text: label.substring(matchIndex, matchIndex + query.length),
            style: TextStyle(
              color: colors.activate,
              fontWeight: FontWeight.w700,
            ),
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

  Widget _buildEmptyHint() {
    return EmptyState(icon: Icons.search_rounded, title: 'search_hint'.tr());
  }

  Widget _buildResults(AbstractThemeColors colors) {
    final total = _artists.length + _festivals.length + _posts.length;
    if (total == 0) {
      return EmptyState(icon: Icons.search_off_rounded, title: 'search_no_result'.tr());
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        if (_artists.isNotEmpty) ...[
          _sectionHeader('search_artists'.tr(), _artists.length, colors),
          ..._artists.map((a) => SearchArtistTile(data: a)),
          const SizedBox(height: 16),
        ],
        if (_festivals.isNotEmpty) ...[
          _sectionHeader('search_festivals'.tr(), _festivals.length, colors),
          ..._festivals.map((f) => SearchFestivalTile(data: f)),
          const SizedBox(height: 16),
        ],
        if (_posts.isNotEmpty) ...[
          _sectionHeader('search_posts'.tr(), _posts.length, colors),
          ..._posts.map((p) => SearchPostTile(data: p)),
        ],
      ],
    );
  }

  Widget _sectionHeader(String title, int count, AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(width: 3, height: 18,
              decoration: BoxDecoration(
                  color: colors.sectionBarColor,
                  borderRadius: BorderRadius.circular(AppDimens.barRadius))),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textTitle)),
          const SizedBox(width: 6),
          Text('($count)', style: TextStyle(fontSize: 13, color: colors.textSecondary)),
        ],
      ),
    );
  }
}

class _SuggestionItem {
  final String label;
  final String type; // 'artist' or 'festival'
  _SuggestionItem(this.label, this.type);
}
