import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_board_post_list_screen.dart';
import 'package:feple/common/widget/w_named_board.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/post_service.dart';
import 'package:flutter/material.dart';

class FestivalTicketBoard extends StatelessWidget {
  final int festivalId;
  final String festivalName;

  const FestivalTicketBoard({
    super.key,
    required this.festivalId,
    required this.festivalName,
  });

  @override
  Widget build(BuildContext context) {
    final svc = sl<PostService>();
    final boardname = 'ticket_board'.tr();
    return NamedBoard(
      name: festivalName,
      boardname: boardname,
      headerIcon: Icons.confirmation_number_rounded,
      fetchPosts: () => svc.fetchFestivalTicketPosts(festivalId),
      postListScreenFactory: () => BoardPostListScreen(
        boardname: boardname,
        writeScreenTitle: 'ticket_board_write'.tr(),
        fetchPosts: () => svc.fetchFestivalTicketPosts(festivalId),
        onSubmitPost: (t, c) =>
            svc.createFestivalTicketPost(festivalId: festivalId, title: t, content: c),
      ),
    );
  }
}
