import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_my_page_list_screen.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/service/user_service.dart';
import 'package:feple/screen/main/tab/community_board/w_community_enlarge_post.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';

class MyCommentsScreen extends StatelessWidget {
  final int userId;
  const MyCommentsScreen({super.key, required this.userId});

  @override
  Widget build(BuildContext context) {
    return MyPageListScreen<_MyComment>(
      title: 'my_comments'.tr(),
      loader: () async {
        final data = await UserService().fetchComments(userId);
        return data.map((e) => _MyComment.fromJson(e)).toList();
      },
      skeletonBuilder: (colors) => ListView.separated(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: 5,
        separatorBuilder: (_, __) =>
            Divider(thickness: 1, color: colors.listDivider),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: const [
              SkeletonBox(
                width: 36,
                height: 36,
                borderRadius: BorderRadius.all(Radius.circular(18)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SkeletonBox(height: 14),
                    SizedBox(height: 6),
                    SkeletonBox(width: 120, height: 11),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      itemBuilder: (context, c, reload) {
        final colors = context.appColors;
        return ListTile(
          onTap: () => Navigator.push(
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
          ).then((_) => reload()),
          leading:
              Icon(Icons.chat_bubble_rounded, color: colors.activate, size: 20),
          title: Text(
            c.content,
            style: TextStyle(
                color: colors.textTitle, fontWeight: FontWeight.w600),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${c.boardDisplayName} • ${c.postTitle}',
            style: TextStyle(color: colors.textSecondary, fontSize: 12),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        );
      },
      emptyIcon: Icons.chat_bubble_outline_rounded,
      emptyTitle: 'no_comments'.tr(),
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
