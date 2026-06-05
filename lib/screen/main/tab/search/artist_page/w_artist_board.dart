import 'package:feple/common/widget/w_named_board.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_post_list.dart';
import 'package:flutter/material.dart';

class ArtistBoard extends StatelessWidget {
  final int artistId;
  final String artistName;

  const ArtistBoard({
    super.key,
    required this.artistId,
    required this.artistName,
  });

  @override
  Widget build(BuildContext context) {
    final postService = sl<PostService>();
    return NamedBoard(
      name: artistName,
      headerIcon: Icons.forum_rounded,
      fetchPosts: () => postService.fetchArtistPosts(artistId),
      postListScreenFactory: () => ArtistPostListScreen(
        artistId: artistId,
        artistName: artistName,
      ),
    );
  }
}
