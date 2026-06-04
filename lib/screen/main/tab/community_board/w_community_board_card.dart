import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/common/widget/w_write_post_screen.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/community_board/w_board_preview_card.dart';
import 'package:feple/screen/main/tab/community_board/w_community_enlarge_post.dart';
import 'package:feple/screen/main/tab/community_board/w_community_post.dart';
import 'package:feple/common/app_events.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 게시판 미리보기 카드 — 3개 게시판(인기/자유/동행)이 공유하는 공용 위젯
class CommunityBoardCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final Color Function(AbstractThemeColors) headerColorFn;
  final String serviceBoardType;
  final String boardname;
  final bool showWriteButton;

  const CommunityBoardCard({
    super.key,
    required this.title,
    required this.icon,
    required this.headerColorFn,
    required this.serviceBoardType,
    required this.boardname,
    this.showWriteButton = true,
  });

  @override
  State<CommunityBoardCard> createState() => _CommunityBoardCardState();
}

class _CommunityBoardCardState extends State<CommunityBoardCard> {
  final PostService _postService = sl<PostService>();
  late Future<List<Post>> _postsFuture;

  @override
  void initState() {
    super.initState();
    _postsFuture = _postService.fetchPosts(widget.serviceBoardType);
    AppEvents.postChanged.addListener(_refresh);
  }

  void _refresh() {
    if (mounted) {
      setState(() {
        _postsFuture = _postService.fetchPosts(widget.serviceBoardType);
      });
    }
  }

  @override
  void dispose() {
    AppEvents.postChanged.removeListener(_refresh);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final rs = ResponsiveSize(context);
    return BoardPreviewCard(
      future: _postsFuture,
      headerIcon: widget.icon,
      headerTitle: widget.title,
      headerColor: widget.headerColorFn(colors),
      height: rs.h(AppDimens.boardCardHeight),
      emptyHint: 'be_first_to_discuss'.tr(args: [widget.title]),
      maxItems: 5,
      onHeaderTap: () => Navigator.push(
        context,
        SlideRoute(
          builder: (_) => CommunityPost(boardname: widget.boardname, boardType: widget.serviceBoardType),
        ),
      ),
      onPostTap: (context, post) => Navigator.of(context, rootNavigator: true).push(
        SlideRoute(
          builder: (_) => EnlargePost.fromPost(
            boardname: widget.boardname,
            post: post,
          ),
        ),
      ),
      onRetry: _refresh,
      onWriteTap: widget.showWriteButton ? () async {
        if (!context.mounted) return;
        final userId = context.read<UserProvider>().currentUserId;
        if (userId == null) {
          context.showInfoSnackbar('no_login_info'.tr());
          return;
        }
        await Navigator.push(
          context,
          SlideRoute(
            builder: (_) => WritePostScreen(
              title: 'write_post'.tr(),
              onSubmit: (t, c, a, img) async {
                await _postService.createPost(
                  boardType: widget.serviceBoardType,
                  title: t,
                  content: c,
                  anonymous: a,
                  imageObjectKey: img,
                );
                AppEvents.postChanged.value++;
              },
            ),
          ),
        );
      } : null,
    );
  }
}
