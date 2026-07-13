import 'package:feple/common/common.dart';
import 'package:feple/screen/main/tab/community_board/w_board_post_list.dart';
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
    return BoardPostList(
      boardName: 'name_board'.tr(args: [widget.artistName]),
      writeScreenTitle: 'name_board_write'.tr(args: [widget.artistName]),
      fetchPage: ({int? cursor, int size = 20}) =>
          _postService.fetchArtistPostsPage(widget.artistId, cursor: cursor, size: size),
      onSubmitPost: (title, content, anonymous, imageObjectKey) => _postService.createArtistPost(
        artistId: widget.artistId,
        draft: PostDraft(title: title, content: content, anonymous: anonymous, imageObjectKey: imageObjectKey),
      ),
    );
  }
}
