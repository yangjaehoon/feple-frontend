import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_board_preview_card.dart';
import 'package:feple/screen/main/tab/community_board/w_community_enlarge_post.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_post_list.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';

/// 아티스트 페이지에 삽입되는 게시판 미리보기 카드
class ArtistBoard extends StatefulWidget {
  final int artistId;
  final String artistName;

  const ArtistBoard({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  State<ArtistBoard> createState() => _ArtistBoardState();
}

class _ArtistBoardState extends State<ArtistBoard> {
  final PostService _postService = sl<PostService>();
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _postService.fetchArtistPosts(widget.artistId);
  }

  void _refresh() => setState(() {
        _postsFuture = _postService.fetchArtistPosts(widget.artistId);
      });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BoardPreviewCard(
      future: _postsFuture,
      headerIcon: Icons.forum_rounded,
      headerTitle: 'name_board'.tr(args: [widget.artistName]),
      headerColor: colors.activate,
      onHeaderTap: () => Navigator.push(
        context,
        SlideRoute(
          builder: (_) => ArtistPostListScreen(
            artistId: widget.artistId,
            artistName: widget.artistName,
          ),
        ),
      ),
      onPostTap: (context, post) => Navigator.push(
        context,
        SlideRoute(
          builder: (_) => EnralgePost(
            boardname: 'name_board'.tr(args: [widget.artistName]),
            id: post.id,
            nickname: post.nickname,
            title: post.title,
            content: post.content,
            heart: post.likeCount,
          ),
        ),
      ),
      trailingBuilder: (post, colors) => [
        Icon(Icons.favorite_border_rounded,
            color: AppColors.kawaiiPink, size: AppDimens.iconSizeLg),
        const SizedBox(width: 4),
        Text(
          post.likeCount.toString(),
          style: TextStyle(
            fontSize: AppDimens.fontSizeMd,
            color: colors.textTitle,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        Icon(Icons.chat_bubble_outline_rounded,
            color: colors.activate, size: AppDimens.iconSizeMd),
      ],
      onRetry: _refresh,
    );
  }
}
