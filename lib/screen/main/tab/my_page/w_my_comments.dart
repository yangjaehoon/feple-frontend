import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_my_page_list_screen.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/my_comment_model.dart';
import 'package:feple/service/user_activity_service.dart';
import 'package:feple/screen/main/tab/community_board/w_post_detail_card.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';

class MyCommentsScreen extends StatelessWidget {
  final int userId;
  const MyCommentsScreen({super.key, required this.userId});

  Widget _buildSkeleton(AbstractThemeColors colors) {
    Widget item() => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: const [
          SkeletonBox(
            width: 36,
            height: 36,
            borderRadius: BorderRadius.all(Radius.circular(18)),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(height: 14),
                SizedBox(height: 6),
                SkeletonBox(width: 120, height: 11),
              ],
            ),
          ),
        ],
      ),
    );
    return Column(
      children: [
        for (int i = 0; i < 5; i++) ...[
          item(),
          if (i < 4) Divider(thickness: 1, color: colors.listDivider),
        ],
      ],
    );
  }

  Widget _buildItem(
    BuildContext context,
    MyComment c,
    VoidCallback reload,
    AbstractThemeColors colors,
  ) {
    return ListTile(
      onTap: () async {
        await Navigator.of(context, rootNavigator: true).push(
          SlideRoute(
            builder: (_) => PostDetailCard(
              boardName: c.boardDisplayName,
              id: c.postId,
              nickname: c.postNickname,
              title: c.postTitle,
              content: c.postContent,
              heartCount: c.postLikeCount,
            ),
          ),
        );
        reload();
      },
      leading: Icon(Icons.chat_bubble_rounded, color: colors.activate, size: 20),
      title: Text(
        c.content,
        style: TextStyle(color: colors.textTitle, fontWeight: FontWeight.w600),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${c.boardDisplayName} • ${c.postTitle}',
        style: TextStyle(color: colors.textSecondary, fontSize: AppDimens.fontSizeXs),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return MyPageListScreen<MyComment>(
      title: 'my_comments'.tr(),
      loader: () => sl<UserActivityService>().fetchComments(userId),
      skeletonBuilder: _buildSkeleton,
      itemBuilder: (context, c, reload) {
        final colors = context.appColors;
        return _buildItem(context, c, reload, colors);
      },
      emptyIcon: Icons.chat_bubble_outline_rounded,
      emptyTitle: 'no_comments'.tr(),
    );
  }
}
