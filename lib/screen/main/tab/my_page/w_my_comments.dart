import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/screen/main/tab/community_board/w_community_enlarge_post.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';

class MyCommentsScreen extends StatefulWidget {
  final int userId;
  const MyCommentsScreen({super.key, required this.userId});

  @override
  State<MyCommentsScreen> createState() => _MyCommentsScreenState();
}

class _MyCommentsScreenState extends State<MyCommentsScreen> {
  List<_MyComment> _comments = [];
  bool _loading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _hasError = false; });
    try {
      final resp = await DioClient.dio.get('/users/${widget.userId}/comments');
      final list = (resp.data as List).map((e) => _MyComment.fromJson(e)).toList();
      if (mounted) setState(() { _comments = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; _hasError = true; });
    }
  }

  Widget _buildSkeleton(AbstractThemeColors colors) {
    return ListView.separated(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      itemCount: 5,
      separatorBuilder: (_, __) => Divider(thickness: 1, color: colors.listDivider),
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const SkeletonBox(
              width: 36,
              height: 36,
              borderRadius: BorderRadius.all(Radius.circular(18)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(height: 14),
                  SizedBox(height: 6),
                  SkeletonBox(width: 120, height: 11),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(
        title: Text('my_comments'.tr()),
        backgroundColor: colors.appBarColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: colors.backgroundMain,
      body: RefreshIndicator(
        color: colors.activate,
        onRefresh: _load,
        child: _loading
            ? _buildSkeleton(colors)
            : _hasError
                ? _buildScrollable(
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.wifi_off_rounded,
                            size: 48,
                            color: colors.textSecondary.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('err_fetch_data'.tr(args: ['']),
                            style: TextStyle(color: colors.textSecondary),
                            textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        FilledButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: Text('retry'.tr()),
                          style: FilledButton.styleFrom(
                            backgroundColor: colors.activate,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24)),
                          ),
                        ),
                      ],
                    ),
                  )
                : _comments.isEmpty
                    ? _buildScrollable(
                        EmptyState(
                          icon: Icons.chat_bubble_outline_rounded,
                          title: 'no_comments'.tr(),
                        ),
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _comments.length,
                        separatorBuilder: (_, __) =>
                            Divider(thickness: 1, color: colors.listDivider),
                        itemBuilder: (context, index) {
                          final c = _comments[index];
                          return AnimatedListItem(
                            index: index,
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  SlideRoute(
                                    builder: (_) => EnralgePost(
                                      boardname: c.boardDisplayName,
                                      id: c.postId,
                                      nickname: c.postNickname,
                                      title: c.postTitle,
                                      content: c.postContent,
                                      heart: c.postLikeCount,
                                    ),
                                  ),
                                ).then((_) => _load());
                              },
                              leading: Icon(Icons.chat_bubble_rounded,
                                  color: colors.activate, size: 20),
                              title: Text(
                                c.content,
                                style: TextStyle(
                                    color: colors.textTitle,
                                    fontWeight: FontWeight.w600),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              subtitle: Text(
                                '${c.boardDisplayName} • ${c.postTitle}',
                                style: TextStyle(
                                    color: colors.textSecondary, fontSize: 12),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          );
                        },
                      ),
      ),
    );
  }

  Widget _buildScrollable(Widget child) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _MyComment {
  final int commentId;
  final String content;
  final int postId;
  final String postTitle;
  final String postContent;
  final String postNickname;
  final int postLikeCount;
  final String boardDisplayName;

  const _MyComment({
    required this.commentId,
    required this.content,
    required this.postId,
    required this.postTitle,
    required this.postContent,
    required this.postNickname,
    required this.postLikeCount,
    required this.boardDisplayName,
  });

  factory _MyComment.fromJson(Map<String, dynamic> json) {
    return _MyComment(
      commentId: json['commentId'] as int,
      content: json['content'] as String,
      postId: json['postId'] as int,
      postTitle: json['postTitle'] as String,
      postContent: json['postContent'] as String,
      postNickname: json['postNickname'] as String,
      postLikeCount: json['postLikeCount'] as int,
      boardDisplayName: json['boardDisplayName'] as String,
    );
  }
}
