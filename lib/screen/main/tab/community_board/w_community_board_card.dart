import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_board_preview_card.dart';
import 'package:feple/screen/main/tab/community_board/w_community_enlarge_post.dart';
import 'package:feple/screen/main/tab/community_board/w_community_post.dart';
import 'package:feple/common/app_events.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';

/// 게시판 미리보기 카드 — 3개 게시판(인기/자유/동행)이 공유하는 공용 위젯
class CommunityBoardCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color Function(AbstractThemeColors) headerColorFn;
  final String serviceBoardType;
  final String boardname;

  const CommunityBoardCard({
    super.key,
    required this.title,
    required this.icon,
    required this.headerColorFn,
    required this.serviceBoardType,
    required this.boardname,
  });

  @override
  State<CommunityBoardCard> createState() => _CommunityBoardCardState();
}

class _CommunityBoardCardState extends State<CommunityBoardCard> {
  final PostService _postService = sl<PostService>();
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _postService.fetchPosts(widget.serviceBoardType);
    AppEvents.postChanged.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) {
      setState(() {
        _postsFuture = _postService.fetchPosts(widget.serviceBoardType);
      });
    }
  }

  @override
  void dispose() {
    AppEvents.postChanged.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final rs = ResponsiveSize(context);
    return BoardPreviewCard(
      future: _postsFuture,
      headerIcon: widget.icon,
      headerTitle: widget.title,
      headerColor: widget.headerColorFn(colors),
      height: rs.h(AppDimens.boardCardHeight),
      onHeaderTap: () => Navigator.push(
        context,
        SlideRoute(
          builder: (_) => CommunityPost(boardname: widget.boardname),
        ),
      ),
      onPostTap: (context, post) => Navigator.push(
        context,
        SlideRoute(
          builder: (_) => EnralgePost(
            boardname: widget.boardname,
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
        const Icon(Icons.star_border_rounded,
            color: AppColors.sunnyYellow, size: AppDimens.iconSizeLg),
        const SizedBox(width: 4),
        Text(
          post.scrapCount.toString(),
          style: TextStyle(
            fontSize: AppDimens.fontSizeMd,
            color: colors.textTitle,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        Icon(Icons.chat_bubble_outline_rounded,
            color: colors.activate, size: AppDimens.iconSizeMd),
        const SizedBox(width: 4),
        Text(
          post.commentCount.toString(),
          style: TextStyle(
            fontSize: AppDimens.fontSizeMd,
            color: colors.textTitle,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
      onRetry: _refresh,
    );
  }
}
