import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/screen/main/tab/community_board/w_community_enlarge_post.dart';
import 'package:feple/screen/main/tab/search/artist_page/f_artist_page.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/common/util/app_route.dart';
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
      appBar: AppBar(
        backgroundColor: colors.appBarColor,
        foregroundColor: Colors.white,
        toolbarHeight: AppDimens.appBarHeight,
        titleSpacing: 0,
        title: TextField(
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
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () => _search(_controller.text),
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: colors.loadingIndicator))
          : _searched
              ? (_hasError ? _buildError(colors) : _buildResults(colors))
              : _controller.text.isEmpty
                  ? _buildEmptyHint(colors)
                  : _buildSuggestions(colors),
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

  Widget _buildError(AbstractThemeColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded, size: 56,
              color: colors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text('search_error'.tr(),
              style: TextStyle(color: colors.textSecondary, fontSize: 15)),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: () => _search(_controller.text),
            icon: const Icon(Icons.refresh_rounded),
            label: Text('retry'.tr()),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyHint(AbstractThemeColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.search_rounded, size: 56,
              color: colors.textSecondary.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text('search_hint'.tr(),
              style: TextStyle(color: colors.textSecondary, fontSize: 15)),
        ],
      ),
    );
  }

  Widget _buildResults(AbstractThemeColors colors) {
    final total = _artists.length + _festivals.length + _posts.length;
    if (total == 0) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off_rounded, size: 56,
                color: colors.textSecondary.withValues(alpha: 0.3)),
            const SizedBox(height: 12),
            Text('search_no_result'.tr(),
                style: TextStyle(color: colors.textSecondary, fontSize: 15)),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        if (_artists.isNotEmpty) ...[
          _sectionHeader('search_artists'.tr(), _artists.length, colors),
          ..._artists.map((a) => _ArtistTile(data: a, colors: colors)),
          const SizedBox(height: 16),
        ],
        if (_festivals.isNotEmpty) ...[
          _sectionHeader('search_festivals'.tr(), _festivals.length, colors),
          ..._festivals.map((f) => _FestivalTile(data: f, colors: colors)),
          const SizedBox(height: 16),
        ],
        if (_posts.isNotEmpty) ...[
          _sectionHeader('search_posts'.tr(), _posts.length, colors),
          ..._posts.map((p) => _PostTile(data: p, colors: colors)),
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

// ── 아티스트 타일 ──
class _ArtistTile extends StatelessWidget {
  final dynamic data;
  final AbstractThemeColors colors;
  const _ArtistTile({required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    final imageUrl = data['profileImageUrl'] as String?;
    final name = data['name'] as String? ?? '';
    final genre = data['genre'] as String? ?? '';
    final followerCount = data['followerCount'] as int? ?? 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: colors.certRingColor.withValues(alpha: 0.15),
        backgroundImage: imageUrl != null && imageUrl.isNotEmpty
            ? CachedNetworkImageProvider(imageUrl) : null,
        child: imageUrl == null || imageUrl.isEmpty
            ? Icon(Icons.person, color: colors.textSecondary) : null,
      ),
      title: Text(name, style: TextStyle(fontWeight: FontWeight.w700, color: colors.textTitle)),
      subtitle: Text(genre, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      trailing: Text('follower_count'.tr(args: ['$followerCount']),
          style: TextStyle(fontSize: 11, color: colors.textSecondary)),
      onTap: () => Navigator.push(context, SlideRoute(
        builder: (_) => ArtistPage(
          artistName: name,
          artistId: data['id'] as int,
          followerCounter: followerCount,
        ),
      )),
    );
  }
}

// ── 페스티벌 타일 ──
class _FestivalTile extends StatelessWidget {
  final dynamic data;
  final AbstractThemeColors colors;
  const _FestivalTile({required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    final posterUrl = data['posterUrl'] as String? ?? '';
    final title = data['title'] as String? ?? '';
    final location = data['location'] as String? ?? '';
    final startDate = data['startDate'] as String? ?? '';

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        child: SizedBox(
          width: 44,
          height: 56,
          child: posterUrl.isNotEmpty
              ? CachedNetworkImage(imageUrl: posterUrl, fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _placeholder())
              : _placeholder(),
        ),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: colors.textTitle),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text('$location · $startDate',
          style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      onTap: () => Navigator.push(context, SlideRoute(
        builder: (_) => FestivalInformationFragment(
          poster: FestivalModel(
            id: data['id'] as int,
            title: title,
            description: data['description'] as String? ?? '',
            location: location,
            startDate: startDate,
            endDate: data['endDate'] as String? ?? '',
            posterUrl: posterUrl,
            latitude: (data['latitude'] as num?)?.toDouble(),
            longitude: (data['longitude'] as num?)?.toDouble(),
          ),
        ),
      )),
    );
  }

  Widget _placeholder() => Container(
    color: colors.certRingColor.withValues(alpha: 0.1),
    child: Icon(Icons.festival_rounded, color: colors.textSecondary.withValues(alpha: 0.4)),
  );
}

// ── 게시글 타일 ──
class _PostTile extends StatelessWidget {
  final dynamic data;
  final AbstractThemeColors colors;
  const _PostTile({required this.data, required this.colors});

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? '';
    final content = data['content'] as String? ?? '';
    final boardName = data['boardDisplayName'] as String? ?? 'search_posts'.tr();
    final likeCount = data['likeCount'] as int? ?? 0;
    final commentCount = data['commentCount'] as int? ?? 0;
    final nickname = data['nickname'] as String? ?? '';
    final id = data['id'] as int? ?? 0;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: colors.activate.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        ),
        child: Icon(Icons.article_rounded, color: colors.activate, size: 22),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: colors.textTitle),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(content, style: TextStyle(color: colors.textSecondary, fontSize: 12),
          maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(boardName, style: TextStyle(fontSize: 10, color: colors.textSecondary)),
          const SizedBox(height: 2),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.favorite_border_rounded, size: 12, color: colors.textSecondary),
            const SizedBox(width: 2),
            Text('$likeCount', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
            const SizedBox(width: 6),
            Icon(Icons.comment_rounded, size: 12, color: colors.textSecondary),
            const SizedBox(width: 2),
            Text('$commentCount', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
          ]),
        ],
      ),
      onTap: () => Navigator.push(context, SlideRoute(
        builder: (_) => EnlargePost(
          boardname: boardName,
          id: id,
          nickname: nickname,
          title: title,
          content: content,
          heart: likeCount,
        ),
      )),
    );
  }
}
