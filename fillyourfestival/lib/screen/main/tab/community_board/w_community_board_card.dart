import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:fast_app_base/model/post_model.dart';
import 'package:fast_app_base/screen/main/tab/community_board/w_community_post.dart';
import 'package:fast_app_base/service/post_service.dart';
import 'package:flutter/material.dart';

/// 게시판 미리보기 카드 — 3개 게시판(인기/자유/동행)이 공유하는 공용 위젯
class CommunityBoardCard extends StatefulWidget {
  /// 헤더에 표시할 제목
  final String title;

  /// 헤더 앞 아이콘
  final IconData icon;

  /// 헤더 배경색 (context.appColors에서 가져옴)
  final Color Function(AbstractThemeColors) headerColorFn;

  /// PostService에 넘길 boardType (예: 'HotBoard')
  final String serviceBoardType;

  /// CommunityPost 페이지에 넘길 boardname (예: 'HotBoard')
  final String boardname;

  const CommunityBoardCard({
    super.key,
    required this.title,
    required this.icon,
    required this.headerColorFn,
    required this.serviceBoardType,
    required this.boardname,
  });

  @override
  State<CommunityBoardCard> createState() => _CommunityBoardCardState();
}

class _CommunityBoardCardState extends State<CommunityBoardCard> {
  final PostService _postService = PostService();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      height: 350,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.all(Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withOpacity(0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──
          _buildHeader(context, colors),
          // ── Post list ──
          Expanded(child: _buildPostList(colors)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AbstractThemeColors colors) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      width: double.infinity,
      height: 44,
      decoration: BoxDecoration(
        color: widget.headerColorFn(colors),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CommunityPost(boardname: widget.boardname),
            ),
          );
        },
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(widget.icon, color: Colors.white, size: 18),
                const SizedBox(width: 6),
                Text(
                  widget.title,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const Row(
              children: [
                Text(
                  "더보기",
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white70, size: 14),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostList(AbstractThemeColors colors) {
    return FutureBuilder<List<dynamic>>(
      future: _postService.fetchPosts(widget.serviceBoardType),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: colors.loadingIndicator),
          );
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Failed to load data: ${snapshot.error}',
              style: TextStyle(color: colors.textSecondary, fontSize: 13),
            ),
          );
        }

        final postDataList = snapshot.data!;
        if (postDataList.isEmpty) {
          return Center(
            child: Text(
              'No data available.',
              style: TextStyle(color: colors.textSecondary),
            ),
          );
        }

        return ListView.separated(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: postDataList.length,
          itemBuilder: (_, index) {
            final Post post = postDataList[index];
            return ListTile(
              dense: true,
              visualDensity: const VisualDensity(vertical: -3),
              minVerticalPadding: 0,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
              title: Text(
                post.title,
                style: TextStyle(
                  color: colors.textTitle,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              subtitle: Text(
                post.nickname,
                style: TextStyle(
                  color: colors.textSecondary,
                  fontSize: 12,
                ),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.favorite_border_rounded,
                      color: AppColors.kawaiiPink, size: 18),
                  const SizedBox(width: 4),
                  Text(
                    post.likeCount.toString(),
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.textTitle,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.chat_bubble_outline_rounded,
                      color: colors.activate, size: 16),
                ],
              ),
            );
          },
          separatorBuilder: (_, __) => Divider(
            thickness: 1,
            color: colors.listDivider,
            indent: 16,
            endIndent: 16,
          ),
        );
      },
    );
  }
}
