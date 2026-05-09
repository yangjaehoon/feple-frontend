import 'package:feple/common/widget/w_named_board.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_festival_post_list.dart';
import 'package:flutter/material.dart';

class FestivalBoard extends StatelessWidget {
  final int festivalId;
  final String festivalName;

  const FestivalBoard({
    super.key,
    required this.festivalId,
    required this.festivalName,
  });

  @override
  Widget build(BuildContext context) {
    final svc = sl<PostService>();
    return NamedBoard(
      name: festivalName,
      headerIcon: Icons.festival_rounded,
      fetchPosts: () => svc.fetchFestivalPosts(festivalId),
      postListScreenFactory: () => FestivalPostListScreen(
        festivalId: festivalId,
        festivalName: festivalName,
      ),
    );
  }
}
