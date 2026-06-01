import 'package:feple/common/common.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/service/user_activity_service.dart';
import 'package:feple/screen/main/tab/my_page/s_certification_list.dart';
import 'package:feple/screen/main/tab/my_page/w_my_comments.dart';
import 'package:feple/screen/main/tab/my_page/w_my_liked_posts.dart';
import 'package:feple/screen/main/tab/my_page/w_my_posts.dart';
import 'package:feple/screen/main/tab/my_page/w_my_scraps.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';

class MyPostCommentWidget extends StatefulWidget {
  final int userId;
  const MyPostCommentWidget({super.key, required this.userId});

  @override
  State<MyPostCommentWidget> createState() => _MyPostCommentWidgetState();
}

class _MyPostCommentWidgetState extends State<MyPostCommentWidget> {
  late Future<_UserStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStats();
  }

  Future<_UserStats> _fetchStats() async {
    final stats = await sl<UserActivityService>().fetchStats(widget.userId);
    int certCount = 0;
    try {
      final certIds = await sl<CertificationService>().getApprovedFestivalIds();
      certCount = certIds.length;
    } catch (e) {
      debugPrint('[MyPage] certCount fetch failed: $e');
    }
    return _UserStats(
      postCount: stats['postCount'] as int,
      commentCount: stats['commentCount'] as int,
      certificationCount: certCount,
      scrapCount: stats['scrapCount'] as int? ?? 0,
      likedPostCount: stats['likedPostCount'] as int? ?? 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FutureBuilder<_UserStats>(
        future: _statsFuture,
        builder: (context, snapshot) => _buildStatRow(context, snapshot),
      ),
    );
  }

  Widget _buildStatRow(
      BuildContext context, AsyncSnapshot<_UserStats> snapshot) {
    final postCount = snapshot.data?.postCount.toString() ?? '-';
    final commentCount = snapshot.data?.commentCount.toString() ?? '-';
    final certCount = snapshot.data?.certificationCount.toString() ?? '-';
    final scrapCount = snapshot.data?.scrapCount.toString() ?? '-';
    final likedCount = snapshot.data?.likedPostCount.toString() ?? '-';
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(child: _buildStatCard(
            context,
            icon: Icons.verified_rounded,
            label: 'certification_badge'.tr(),
            value: certCount,
            color: context.appColors.activate,
            onTap: () => Navigator.push(context, SlideRoute(builder: (_) => const CertificationListScreen())),
          )),
          const SizedBox(width: 6),
          Expanded(child: _buildStatCard(
            context,
            icon: Icons.article_rounded,
            label: 'posts'.tr(),
            value: postCount,
            color: context.appColors.activate,
            onTap: () => Navigator.push(context, SlideRoute(builder: (_) => MyPostsScreen(userId: widget.userId))),
          )),
          const SizedBox(width: 6),
          Expanded(child: _buildStatCard(
            context,
            icon: Icons.chat_bubble_rounded,
            label: 'comments'.tr(),
            value: commentCount,
            color: context.appColors.activate,
            onTap: () => Navigator.push(context, SlideRoute(builder: (_) => MyCommentsScreen(userId: widget.userId))),
          )),
          const SizedBox(width: 6),
          Expanded(child: _buildStatCard(
            context,
            icon: Icons.star_rounded,
            label: 'scraps'.tr(),
            value: scrapCount,
            color: context.appColors.accentColor,
            onTap: () => Navigator.push(context, SlideRoute(builder: (_) => const MyScrapsScreen())),
          )),
          const SizedBox(width: 6),
          Expanded(child: _buildStatCard(
            context,
            icon: Icons.favorite_rounded,
            label: 'liked_posts'.tr(),
            value: likedCount,
            color: context.appColors.accentColor,
            onTap: () => Navigator.push(context, SlideRoute(builder: (_) => MyLikedPostsScreen(userId: widget.userId))),
          )),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    VoidCallback? onTap,
  }) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: colors.statCardBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.listDivider),
          boxShadow: [
            BoxShadow(
              color: colors.cardShadow.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: colors.textTitle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserStats {
  final int postCount;
  final int commentCount;
  final int certificationCount;
  final int scrapCount;
  final int likedPostCount;
  const _UserStats({
    required this.postCount,
    required this.commentCount,
    required this.certificationCount,
    required this.scrapCount,
    required this.likedPostCount,
  });
}
