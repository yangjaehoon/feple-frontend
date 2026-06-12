import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/model/artist_model.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/post_model.dart';
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
  final Artist data;
  final String? highlightKeyword;
  const SearchArtistTile({super.key, required this.data, this.highlightKeyword});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final hasImage = data.profileImageUrl.isNotEmpty;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: CircleAvatar(
        radius: 24,
        backgroundColor: colors.certRingColor.withValues(alpha: 0.15),
        backgroundImage: hasImage ? CachedNetworkImageProvider(data.profileImageUrl) : null,
        child: hasImage ? null : Icon(Icons.person, color: colors.textSecondary),
      ),
      title: _buildHighlightedText(
        data.displayName(context.locale.languageCode == 'en'),
        highlightKeyword,
        TextStyle(fontWeight: FontWeight.w700, color: colors.textTitle),
        colors.activate,
      ),
      subtitle: Text(data.genre, style: TextStyle(color: colors.textSecondary, fontSize: 12)),
      trailing: Text(
        'follower_count'.tr(args: ['${data.followerCount}']),
        style: TextStyle(fontSize: 11, color: colors.textSecondary),
      ),
      onTap: () => Navigator.push(context, SlideRoute(
        builder: (_) => ArtistPage(
          artistName: data.name,
          artistId: data.id,
          followerCount: data.followerCount,
        ),
      )),
    );
  }
}

class SearchFestivalTile extends StatelessWidget {
  final FestivalPreview data;
  final String? highlightKeyword;
  const SearchFestivalTile({super.key, required this.data, this.highlightKeyword});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
      leading: ClipRRect(
        borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
        child: SizedBox(
          width: 44,
          height: 56,
          child: data.posterUrl.isNotEmpty
              ? CachedNetworkImage(
                  imageUrl: data.posterUrl,
                  fit: BoxFit.cover,
                  errorWidget: (_, __, ___) => _placeholder(colors),
                )
              : _placeholder(colors),
        ),
      ),
      title: _buildHighlightedText(
        data.displayTitle(context.locale.languageCode == 'en'),
        highlightKeyword,
        TextStyle(fontWeight: FontWeight.w700, color: colors.textTitle),
        colors.activate,
      ),
      subtitle: Text(
        '${data.location} · ${data.startDate}',
        style: TextStyle(color: colors.textSecondary, fontSize: 12),
      ),
      onTap: () => Navigator.push(context, SlideRoute(
        builder: (_) => FestivalInformationFragment(
          poster: FestivalModel(
            id: data.id,
            title: data.title,
            description: data.description,
            location: data.location,
            startDate: data.startDate,
            endDate: data.endDate ?? '',
            posterUrl: data.posterUrl,
            latitude: data.latitude,
            longitude: data.longitude,
            genres: data.genres,
            ageRestriction: data.ageRestriction,
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
  final Post data;
  final String? highlightKeyword;
  const SearchPostTile({super.key, required this.data, this.highlightKeyword});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

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
        data.title,
        highlightKeyword,
        TextStyle(fontWeight: FontWeight.w700, color: colors.textTitle),
        colors.activate,
      ),
      subtitle: Text(
        data.content,
        style: TextStyle(color: colors.textSecondary, fontSize: 12),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            data.boardDisplayName,
            style: TextStyle(fontSize: 10, color: colors.textSecondary),
          ),
          const SizedBox(height: 2),
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.favorite_border_rounded, size: 12, color: colors.textSecondary),
            const SizedBox(width: 2),
            Text('${data.likeCount}', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
            const SizedBox(width: 6),
            Icon(Icons.comment_rounded, size: 12, color: colors.textSecondary),
            const SizedBox(width: 2),
            Text('${data.commentCount}', style: TextStyle(fontSize: 11, color: colors.textSecondary)),
          ]),
        ],
      ),
      onTap: () => Navigator.of(context, rootNavigator: true).push(SlideRoute(
        builder: (_) => EnlargePost.fromPost(
          boardName: data.boardDisplayName,
          post: data,
        ),
      )),
    );
  }
}
