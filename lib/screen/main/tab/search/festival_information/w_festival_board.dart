import 'package:feple/injection.dart';
import 'package:feple/screen/main/tab/community_board/w_board_preview_section.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/screen/main/tab/search/festival_information/s_festival_board.dart';
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
    final postService = sl<PostService>();
    return BoardPreviewSection(
      name: festivalName,
      headerIcon: Icons.local_fire_department_rounded,
      fetchPosts: () => postService.fetchFestivalPopularPosts(festivalId),
      postListScreenFactory: () => FestivalBoardScreen(
        festivalId: festivalId,
        festivalName: festivalName,
      ),
    );
  }
}
