import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_board_post_list_screen.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/post_service.dart';
import 'package:flutter/material.dart';

class ArtistPostListScreen extends StatefulWidget {
  final int artistId;
  final String artistName;

  const ArtistPostListScreen({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  State<ArtistPostListScreen> createState() => _ArtistPostListScreenState();
}

class _ArtistPostListScreenState extends State<ArtistPostListScreen> {
  final _postService = sl<PostService>();

  @override
  Widget build(BuildContext context) {
    return BoardPostListScreen(
      boardName: 'name_board'.tr(args: [widget.artistName]),
      writeScreenTitle: 'name_board_write'.tr(args: [widget.artistName]),
      fetchPosts: () => _postService.fetchArtistPosts(widget.artistId),
      onSubmitPost: (t, c, a, img) => _postService.createArtistPost(
        artistId: widget.artistId,
        title: t,
        content: c,
        anonymous: a,
        imageObjectKey: img,
      ),
    );
  }
}
