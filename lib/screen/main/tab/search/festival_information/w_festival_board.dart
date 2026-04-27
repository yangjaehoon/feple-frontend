import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_board_preview_card.dart';
import 'package:feple/screen/main/tab/community_board/w_community_enlarge_post.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_post_list.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';

/// 페스티벌 상세 페이지에 삽입되는 게시판 미리보기 카드
class FestivalBoard extends StatefulWidget {
  final int festivalId;
  final String festivalName;

  const FestivalBoard({
    super.key,
    required this.festivalId,
    required this.festivalName,
  });

  @override
  State<FestivalBoard> createState() => _FestivalBoardState();
}

class _FestivalBoardState extends State<FestivalBoard> {
  final PostService _postService = sl<PostService>();
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _postService.fetchFestivalPosts(widget.festivalId);
  }

  void _refresh() => setState(() {
        _postsFuture = _postService.fetchFestivalPosts(widget.festivalId);
      });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return BoardPreviewCard(
      future: _postsFuture,
      headerIcon: Icons.festival_rounded,
      headerTitle: 'name_board'.tr(args: [widget.festivalName]),
      headerColor: colors.activate,
      onHeaderTap: () => Navigator.push(
        context,
        SlideRoute(
          builder: (_) => FestivalPostListScreen(
            festivalId: widget.festivalId,
            festivalName: widget.festivalName,
          ),
        ),
      ),
      onPostTap: (context, post) => Navigator.push(
        context,
        SlideRoute(
          builder: (_) => EnralgePost(
            boardname: 'name_board'.tr(args: [widget.festivalName]),
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
            color: colors.activate, size: AppDimens.iconSizeLg),
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
