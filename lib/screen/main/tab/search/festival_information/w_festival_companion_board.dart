import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_board_post_list_screen.dart';
import 'package:feple/common/widget/w_named_board.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/post_service.dart';
import 'package:flutter/material.dart';

class FestivalCompanionBoard extends StatelessWidget {
  final int festivalId;
  final String festivalName;

  const FestivalCompanionBoard({
    super.key,
    required this.festivalId,
    required this.festivalName,
  });

  @override
  Widget build(BuildContext context) {
    final svc = sl<PostService>();
    final boardname = 'companion_board'.tr();
    return NamedBoard(
      name: festivalName,
      boardname: boardname,
      headerIcon: Icons.group_rounded,
      fetchPosts: () => svc.fetchFestivalCompanionPosts(festivalId),
      postListScreenFactory: () => BoardPostListScreen(
        boardname: boardname,
        writeScreenTitle: 'companion_board_write'.tr(),
        fetchPosts: () => svc.fetchFestivalCompanionPosts(festivalId),
        onSubmitPost: (t, c) =>
            svc.createFestivalCompanionPost(festivalId: festivalId, title: t, content: c),
      ),
    );
  }
}
