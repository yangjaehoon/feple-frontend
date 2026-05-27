import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/screen/main/tab/community_board/w_community_enlarge_post.dart';
import 'package:feple/screen/main/tab/search/artist_page/f_artist_page.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';

Widget _buildHighlightedText(
  String text,
  String? keyword,
  TextStyle baseStyle,
  Color highlightColor,
) {
  if (keyword == null || keyword.isEmpty) {
    return Text(text, style: baseStyle, maxLines: 1, overflow: TextOverflow.ellipsis);
  }
  final lower = text.toLowerCase();
  final lowerKw = keyword.toLowerCase();
  final spans = <TextSpan>[];
  int start = 0;
  for (final match in RegExp(RegExp.escape(lowerKw)).allMatches(lower)) {
    if (match.start > start) {
      spans.add(TextSpan(text: text.substring(start, match.start)));
    }
    spans.add(TextSpan(
      text: text.substring(match.start, match.end),
      style: TextStyle(color: highlightColor, fontWeight: FontWeight.w700),
    ));
    start = match.end;
  }
  if (start < text.length) spans.add(TextSpan(text: text.substring(start)));
  return RichText(
    text: TextSpan(style: baseStyle, children: spans),
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
  );
}

class SearchArtistTile extends StatelessWidget {
  final dynamic data;
  final String? highlightKeyword;
  const SearchArtistTile({super.key, required this.data, this.highlightKeyword});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
      title: _buildHighlightedText(
        name,
        highlightKeyword,
        TextStyle(fontWeight: FontWeight.w700, color: colors.textTitle),
        colors.activate,
      ),
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

class SearchFestivalTile extends StatelessWidget {
  final dynamic data;
  final String? highlightKeyword;
  const SearchFestivalTile({super.key, required this.data, this.highlightKeyword});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
                  errorWidget: (_, __, ___) => _placeholder(colors))
              : _placeholder(colors),
        ),
      ),
      title: _buildHighlightedText(
        title,
        highlightKeyword,
        TextStyle(fontWeight: FontWeight.w700, color: colors.textTitle),
        colors.activate,
      ),
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

  Widget _placeholder(AbstractThemeColors colors) => Container(
    color: colors.certRingColor.withValues(alpha: 0.1),
    child: Icon(Icons.festival_rounded, color: colors.textSecondary.withValues(alpha: 0.4)),
  );
}

class SearchPostTile extends StatelessWidget {
  final dynamic data;
  final String? highlightKeyword;
  const SearchPostTile({super.key, required this.data, this.highlightKeyword});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final title = data['title'] as String? ?? '';
    final content = data['content'] as String? ?? '';
    final boardName = data['boardDisplayName'] as String? ?? 'search_posts'.tr();
    final likeCount = data['likeCount'] as int? ?? 0;
    final commentCount = data['commentCount'] as int? ?? 0;
    final nickname = data['nickname'] as String? ?? '';
    final id = (data['id'] as num?)?.toInt() ?? 0;
    final profileImageUrl = data['profileImageUrl'] as String?;
    final imageUrl = data['imageUrl'] as String?;
    final postUserId = (data['userId'] as num?)?.toInt();
    final createdAtStr = data['createdAt'] as String?;
    final updatedAtStr = data['updatedAt'] as String?;

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
      title: _buildHighlightedText(
        title,
        highlightKeyword,
        TextStyle(fontWeight: FontWeight.w700, color: colors.textTitle),
        colors.activate,
      ),
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
      onTap: () => Navigator.of(context, rootNavigator: true).push(SlideRoute(
        builder: (_) => EnlargePost(
          boardname: boardName,
          id: id,
          nickname: nickname,
          title: title,
          content: content,
          heart: likeCount,
          profileImageUrl: profileImageUrl,
          imageUrl: imageUrl,
          postUserId: postUserId,
          createdAt: createdAtStr != null ? DateTime.tryParse(createdAtStr) : null,
          updatedAt: updatedAtStr != null ? DateTime.tryParse(updatedAtStr) : null,
        ),
      )),
    );
  }
}
