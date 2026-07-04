import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_my_page_list.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_post_detail_card.dart';
import 'package:feple/screen/main/tab/community_board/w_like_comment_row.dart';
import 'package:feple/service/user_activity_service.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';

class MyLikedPostsView extends StatelessWidget {
  final int userId;
  const MyLikedPostsView({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return MyPageList<Post>(
      title: 'my_liked_posts'.tr(),
      loader: () => sl<UserActivityService>().fetchLikedPosts(userId),
      skeletonBuilder: postListSkeleton,
      itemBuilder: (context, post, reload) {
        final colors = context.appColors;
        return ListTile(
          onTap: () async {
            await Navigator.of(context, rootNavigator: true).push(
              SlideRoute(
                builder: (_) => PostDetailCard.fromPost(
                  boardName: post.boardDisplayName,
                  post: post,
                ),
              ),
            );
            reload();
          },
          leading: Icon(Icons.favorite_rounded, color: colors.accentColor, size: 22),
          title: Text(
            post.title,
            style: TextStyle(color: colors.textTitle, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            post.boardDisplayName,
            style: TextStyle(color: colors.textSecondary, fontSize: AppDimens.fontSizeXs),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: PostStatRow(
            likeCount: post.likeCount,
            commentCount: post.commentCount,
          ),
        );
      },
      emptyIcon: Icons.favorite_border_rounded,
      emptyTitle: 'no_liked_posts'.tr(),
    );
  }
}
