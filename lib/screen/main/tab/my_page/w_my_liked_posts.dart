import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_my_page_list.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/my_page/w_saved_post_tile.dart';
import 'package:feple/service/user_activity_service.dart';
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
      itemBuilder: (context, post, reload) => SavedPostTile(
        post: post,
        leadingIcon: Icons.favorite_rounded,
        onReturn: reload,
      ),
      emptyIcon: Icons.favorite_border_rounded,
      emptyTitle: 'no_liked_posts'.tr(),
    );
  }
}
