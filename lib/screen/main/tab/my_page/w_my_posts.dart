import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/service/user_service.dart';
import 'package:feple/screen/main/tab/community_board/w_community_enlarge_post.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';

class MyPostsScreen extends StatefulWidget {
  final int userId;
  const MyPostsScreen({super.key, required this.userId});

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  List<Post> _posts = [];
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
      final data = await UserService().fetchPosts(widget.userId);
      final posts = data.map((e) => Post.fromJson(e)).toList();
      if (mounted) setState(() { _posts = posts; _loading = false; });
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  SkeletonBox(height: 15),
                  SizedBox(height: 6),
                  SkeletonBox(width: 80, height: 11),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const SkeletonBox(width: 50, height: 13),
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
        title: Text('my_posts'.tr()),
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
                            size: 48, color: colors.textSecondary.withValues(alpha: 0.4)),
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
                                borderRadius: BorderRadius.circular(AppDimens.shapeButton)),
                          ),
                        ),
                      ],
                    ),
                  )
                : _posts.isEmpty
                    ? _buildScrollable(
                        EmptyState(
                          icon: Icons.article_outlined,
                          title: 'no_posts'.tr(),
                        ),
                      )
                    : ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        itemCount: _posts.length,
                        separatorBuilder: (_, __) =>
                            Divider(thickness: 1, color: colors.listDivider),
                        itemBuilder: (context, index) {
                          final post = _posts[index];
                          return AnimatedListItem(
                            index: index,
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  SlideRoute(
                                    builder: (_) => EnralgePost(
                                      boardname: post.boardDisplayName,
                                      id: post.id,
                                      nickname: post.nickname,
                                      title: post.title,
                                      content: post.content,
                                      heart: post.likeCount,
                                    ),
                                  ),
                                ).then((_) => _load());
                              },
                              title: Text(
                                post.title,
                                style: TextStyle(
                                    color: colors.textTitle,
                                    fontWeight: FontWeight.w600),
                              ),
                              subtitle: Text(
                                post.boardDisplayName,
                                style: TextStyle(
                                    color: colors.textSecondary, fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.favorite_border_rounded,
                                      color: AppColors.kawaiiPink, size: 16),
                                  const SizedBox(width: 4),
                                  Text(post.likeCount.toString(),
                                      style: TextStyle(
                                          color: colors.textTitle,
                                          fontSize: 13)),
                                  const SizedBox(width: 8),
                                  Icon(Icons.chat_bubble_outline_rounded,
                                      color: colors.textSecondary, size: 15),
                                  const SizedBox(width: 4),
                                  Text(post.commentCount.toString(),
                                      style: TextStyle(
                                          color: colors.textTitle,
                                          fontSize: 13)),
                                ],
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
