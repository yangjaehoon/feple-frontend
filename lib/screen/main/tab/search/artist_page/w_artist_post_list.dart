import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_board_post_list_screen.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/post_service.dart';
import 'package:flutter/material.dart';

class ArtistPostListScreen extends StatelessWidget {
  final int artistId;
  final String artistName;

  const ArtistPostListScreen({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  Widget build(BuildContext context) {
    final postService = sl<PostService>();
    return BoardPostListScreen(
      boardName: 'name_board'.tr(args: [artistName]),
      writeScreenTitle: 'name_board_write'.tr(args: [artistName]),
      fetchPosts: () => postService.fetchArtistPosts(artistId),
      onSubmitPost: (t, c, a, img) =>
          postService.createArtistPost(artistId: artistId, title: t, content: c, anonymous: a, imageObjectKey: img),
    );
  }
}
