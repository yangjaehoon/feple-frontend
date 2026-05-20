import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_my_page_list_screen.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_community_enlarge_post.dart';
import 'package:feple/screen/main/tab/community_board/w_like_comment_row.dart';
import 'package:feple/service/scrap_service.dart';
import 'package:flutter/material.dart';

class MyScrapsScreen extends StatelessWidget {
  const MyScrapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MyPageListScreen<Post>(
      title: 'my_scraps'.tr(),
      loader: () => sl<ScrapService>().fetchMyScraps(),
      skeletonBuilder: postListSkeleton,
      itemBuilder: (context, post, reload) {
        final colors = context.appColors;
        return ListTile(
          onTap: () async {
            await Navigator.of(context, rootNavigator: true).push(
              SlideRoute(
                builder: (_) => EnlargePost.fromPost(
                  boardname: post.boardDisplayName,
                  post: post,
                ),
              ),
            );
            reload();
          },
          leading: const Icon(Icons.star_rounded,
              color: AppColors.sunnyYellow, size: 22),
          title: Text(
            post.title,
            style: TextStyle(
                color: colors.textTitle, fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            post.boardDisplayName,
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
          ),
          trailing: PostStatRow(
            likeCount: post.likeCount,
            commentCount: post.commentCount,
          ),
        );
      },
      emptyIcon: Icons.star_border_rounded,
      emptyTitle: 'no_scraps'.tr(),
    );
  }
}
