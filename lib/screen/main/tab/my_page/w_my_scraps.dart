import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_my_page_list_screen.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_community_enlarge_post.dart';
import 'package:feple/service/scrap_service.dart';
import 'package:flutter/material.dart';

class MyScrapsScreen extends StatelessWidget {
  const MyScrapsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MyPageListScreen<Post>(
      title: 'my_scraps'.tr(),
      loader: () => sl<ScrapService>().fetchMyScraps(),
      skeletonBuilder: (colors) => ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: 5,
        separatorBuilder: (_, __) =>
            Divider(thickness: 1, color: colors.listDivider),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppDimens.paddingHorizontal, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    SkeletonBox(height: 15),
                    SizedBox(height: 6),
                    SkeletonBox(width: 80, height: 11),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const SkeletonBox(width: 50, height: 13),
            ],
          ),
        ),
      ),
      itemBuilder: (context, post, reload) {
        final colors = context.appColors;
        return ListTile(
          onTap: () => Navigator.push(
            context,
            SlideRoute(
              builder: (_) => EnralgePost(
                boardname: post.boardDisplayName,
                id: post.id,
                nickname: post.nickname,
                title: post.title,
                content: post.content,
                heart: post.likeCount,
              ),
            ),
          ).then((_) => reload()),
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
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.favorite_border_rounded,
                  color: AppColors.kawaiiPink, size: 16),
              const SizedBox(width: 4),
              Text(post.likeCount.toString(),
                  style: TextStyle(color: colors.textTitle, fontSize: 13)),
              const SizedBox(width: 8),
              Icon(Icons.chat_bubble_outline_rounded,
                  color: colors.textSecondary, size: 15),
              const SizedBox(width: 4),
              Text(post.commentCount.toString(),
                  style: TextStyle(color: colors.textTitle, fontSize: 13)),
            ],
          ),
        );
      },
      emptyIcon: Icons.star_border_rounded,
      emptyTitle: 'no_scraps'.tr(),
    );
  }
}
