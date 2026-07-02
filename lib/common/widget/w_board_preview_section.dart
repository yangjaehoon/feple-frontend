import 'package:feple/common/common.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_board_preview_card.dart';
import 'package:feple/screen/main/tab/community_board/w_post_detail_card.dart';
import 'package:flutter/material.dart';

/// 아티스트·페스티벌 게시판 미리보기 카드 공통 위젯.
///
/// [fetchPosts] 로 데이터를 가져오고, 헤더 탭 시 [postListScreenFactory] 로 생성된
/// 전체 목록 화면으로 이동합니다.
class NamedBoard extends StatefulWidget {
  final String name;
  final String? boardName;
  final IconData headerIcon;
  final Future<List<Post>> Function() fetchPosts;
  final Widget Function() postListScreenFactory;
  final VoidCallback? onWriteTap;

  const NamedBoard({
    super.key,
    required this.name,
    this.boardName,
    required this.headerIcon,
    required this.fetchPosts,
    required this.postListScreenFactory,
    this.onWriteTap,
  });

  @override
  State<NamedBoard> createState() => NamedBoardState();
}

class NamedBoardState extends State<NamedBoard> {
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = widget.fetchPosts();
  }

  void refresh() {
    setState(() { _postsFuture = widget.fetchPosts(); });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final boardName = widget.boardName ?? 'name_board'.tr(args: [widget.name]);
    return BoardPreviewCard(
      future: _postsFuture,
      headerIcon: widget.headerIcon,
      headerTitle: boardName,
      headerColor: colors.activate,
      emptyHint: 'be_first_to_discuss'.tr(args: [widget.name]),
      onHeaderTap: () => Navigator.push(
        context,
        SlideRoute(builder: (_) => widget.postListScreenFactory()),
      ),
      onPostTap: (context, post) async {
        await Navigator.of(context, rootNavigator: true).push(
          SlideRoute(
            builder: (_) => PostDetailCard.fromPost(boardName: boardName, post: post),
          ),
        );
        if (mounted) refresh();
      },
      onRetry: refresh,
      onWriteTap: widget.onWriteTap,
    );
  }
}
