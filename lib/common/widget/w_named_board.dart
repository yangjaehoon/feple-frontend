import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_board_preview_card.dart';
import 'package:feple/screen/main/tab/community_board/w_community_enlarge_post.dart';
import 'package:flutter/material.dart';

/// 아티스트·페스티벌 게시판 미리보기 카드 공통 위젯.
///
/// [fetchPosts] 로 데이터를 가져오고, 헤더 탭 시 [postListScreenFactory] 로 생성된
/// 전체 목록 화면으로 이동합니다.
class NamedBoard extends StatefulWidget {
  final String name;
  final IconData headerIcon;
  final Future<List<Post>> Function() fetchPosts;
  final Widget Function() postListScreenFactory;

  const NamedBoard({
    super.key,
    required this.name,
    required this.headerIcon,
    required this.fetchPosts,
    required this.postListScreenFactory,
  });

  @override
  State<NamedBoard> createState() => _NamedBoardState();
}

class _NamedBoardState extends State<NamedBoard> {
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = widget.fetchPosts();
  }

  void _refresh() => setState(() => _postsFuture = widget.fetchPosts());

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final boardname = 'name_board'.tr(args: [widget.name]);
    return BoardPreviewCard(
      future: _postsFuture,
      headerIcon: widget.headerIcon,
      headerTitle: boardname,
      headerColor: colors.activate,
      onHeaderTap: () => Navigator.push(
        context,
        SlideRoute(builder: (_) => widget.postListScreenFactory()),
      ),
      onPostTap: (context, post) =>
          Navigator.of(context, rootNavigator: true).push(
        SlideRoute(
          builder: (_) => EnlargePost.fromPost(boardname: boardname, post: post),
        ),
      ),
      onRetry: _refresh,
    );
  }
}
