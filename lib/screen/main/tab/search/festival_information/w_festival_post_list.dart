import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_board_post_list_screen.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/post_service.dart';
import 'package:flutter/material.dart';

class FestivalPostListScreen extends StatelessWidget {
  final int festivalId;
  final String festivalName;

  const FestivalPostListScreen({
    super.key,
    required this.festivalId,
    required this.festivalName,
  });

  @override
  Widget build(BuildContext context) {
    final svc = sl<PostService>();
    return BoardPostListScreen(
      boardname: 'name_board'.tr(args: [festivalName]),
      writeScreenTitle: 'name_board_write'.tr(args: [festivalName]),
      fetchPosts: () => svc.fetchFestivalPosts(festivalId),
      onSubmitPost: (t, c) =>
          svc.createFestivalPost(festivalId: festivalId, title: t, content: c),
    );
  }
}
