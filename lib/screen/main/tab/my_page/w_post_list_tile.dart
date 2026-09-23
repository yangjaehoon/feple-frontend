import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_post_detail_card.dart';
import 'package:feple/screen/main/tab/community_board/w_post_stat_row.dart';
import 'package:flutter/material.dart';

/// 스크랩·좋아요 목록처럼 "게시글 한 건 → 상세로 이동" 형태의 목록 타일.
/// 상세에서 돌아오면 좋아요·스크랩이 바뀌었을 수 있어 [onReturn]으로 목록을 갱신한다.
class PostListTile extends StatelessWidget {
  final Post post;
  final IconData leadingIcon;
  final VoidCallback onReturn;

  const PostListTile({
    super.key,
    required this.post,
    required this.leadingIcon,
    required this.onReturn,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ListTile(
      onTap: () => _openDetail(context),
      leading: Icon(leadingIcon, color: colors.accentColor, size: 22),
      title: Text(
        post.title,
        style: TextStyle(color: colors.textTitle, fontWeight: FontWeight.w600),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        post.boardDisplayName,
        style: TextStyle(
          color: colors.textSecondary,
          fontSize: AppDimens.fontSizeXs,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: PostStatRow(
        likeCount: post.likeCount,
        commentCount: post.commentCount,
      ),
    );
  }

  Future<void> _openDetail(BuildContext context) async {
    await Navigator.of(context, rootNavigator: true).push(
      SlideRoute(
        builder: (_) =>
            PostDetailCard.fromPost(boardName: post.boardDisplayName, post: post),
      ),
    );
    onReturn();
  }
}
