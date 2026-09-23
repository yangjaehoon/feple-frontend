import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_my_page_list.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/my_page/w_saved_post_tile.dart';
import 'package:feple/service/scrap_service.dart';
import 'package:flutter/material.dart';

class MyScrapsView extends StatelessWidget {
  const MyScrapsView({super.key});

  @override
  Widget build(BuildContext context) {
    return MyPageList<Post>(
      title: 'my_scraps'.tr(),
      loader: () => sl<ScrapService>().fetchMyScraps(),
      skeletonBuilder: postListSkeleton,
      itemBuilder: (context, post, reload) => SavedPostTile(
        post: post,
        leadingIcon: Icons.star_rounded,
        onReturn: reload,
      ),
      emptyIcon: Icons.star_border_rounded,
      emptyTitle: 'no_scraps'.tr(),
    );
  }
}
