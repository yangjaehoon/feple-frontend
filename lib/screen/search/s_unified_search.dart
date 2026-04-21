import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/model/poster_model.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/screen/main/tab/community_board/w_community_enralgepost.dart';
import 'package:feple/screen/main/tab/search/artist_page/f_artist_page.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:flutter/material.dart';

class UnifiedSearchScreen extends StatefulWidget {
  const UnifiedSearchScreen({super.key});

  @override
  State<UnifiedSearchScreen> createState() => _UnifiedSearchScreenState();
}

class _UnifiedSearchScreenState extends State<UnifiedSearchScreen> {
  final _controller = TextEditingController();
  bool _loading = false;
  bool _searched = false;

  List<dynamic> _artists = [];
  List<dynamic> _festivals = [];
  List<dynamic> _posts = [];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String keyword) async {
    if (keyword.trim().isEmpty) return;
    setState(() { _loading = true; _searched = true; });
    try {
      final res = await DioClient.dio.get('/search', queryParameters: {'keyword': keyword.trim()});
      final data = res.data as Map<String, dynamic>;
      if (mounted) {
        setState(() {
        _artists  = (data['artists']  as List? ?? []);
        _festivals = (data['festivals'] as List? ?? []);
        _posts    = (data['posts']    as List? ?? []);
        _loading  = false;
      });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.backgroundMain,
      appBar: AppBar(
        backgroundColor: colors.appBarColor,
        foregroundColor: Colors.white,
        titleSpacing: 0,
        title: TextField(
          controller: _controller,
          autofocus: true,
          style: const TextStyle(color: Colors.white, fontSize: 16),
          cursorColor: Colors.white70,
          decoration: InputDecoration(
            hintText: 'search_hint'.tr(),
            hintStyle: const TextStyle(color: Colors.white54),
            border: InputBorder.none,
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.white70),
                    onPressed: () {
                      _controller.clear();
                      setState(() { _searched = false; _artists = []; _festivals = []; _posts = []; });
                    },
                  )
                : null,
          ),
          textInputAction: TextInputAction.search,
          onChanged: (_) => setState(() {}),
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
          ? const Center(child: CircularProgressIndicator())
          : !_searched
              ? _buildEmptyHint(colors)
              : _buildResults(colors),
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
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: colors.textTitle)),
          const SizedBox(width: 6),
          Text('($count)', style: TextStyle(fontSize: 13, color: colors.textSecondary)),
        ],
      ),
    );
  }
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
      trailing: Text('팔로워 $followerCount',
          style: TextStyle(fontSize: 11, color: colors.textSecondary)),
      onTap: () => Navigator.push(context, MaterialPageRoute(
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
        borderRadius: BorderRadius.circular(8),
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
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => FestivalInformationFragment(
          poster: PosterModel(
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
    final boardName = data['boardDisplayName'] as String? ?? '게시글';
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
          color: Colors.blueAccent.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.article_rounded, color: Colors.blueAccent, size: 22),
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
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => EnralgePost(
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
