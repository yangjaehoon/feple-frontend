import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/user_stats_model.dart';
import 'package:feple/service/user_activity_service.dart';
import 'package:feple/screen/main/tab/my_page/s_certification_list.dart';
import 'package:feple/screen/main/tab/my_page/w_my_comments.dart';
import 'package:feple/screen/main/tab/my_page/w_my_liked_posts.dart';
import 'package:feple/screen/main/tab/my_page/w_my_posts.dart';
import 'package:feple/screen/main/tab/my_page/w_my_scraps.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

class MyPostCommentWidget extends StatefulWidget {
  final int userId;
  const MyPostCommentWidget({super.key, required this.userId});

  @override
  State<MyPostCommentWidget> createState() => _MyPostCommentWidgetState();
}

class _MyPostCommentWidgetState extends State<MyPostCommentWidget> {
  late Future<UserStats> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _fetchStats();
  }

  Future<UserStats> _fetchStats() =>
      sl<UserActivityService>().fetchStats(widget.userId);

  void _refresh() => setState(() { _statsFuture = _fetchStats(); });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FutureBuilder<UserStats>(
        future: _statsFuture,
        builder: (context, snapshot) => _buildStatRow(context, snapshot),
      ),
    );
  }

  Widget _buildStatRow(
      BuildContext context, AsyncSnapshot<UserStats> snapshot) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildSkeleton();
    }
    if (snapshot.hasError) {
      return ErrorState(message: 'err_fetch_data'.tr(), onRetry: _refresh);
    }
    final stats = snapshot.data!;
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(child: _buildStatCard(
            context,
            icon: Icons.verified_rounded,
            label: 'certification_badge'.tr(),
            value: stats.certificationCount.toString(),
            color: colors.activate,
            onTap: () => Navigator.push(context, SlideRoute(builder: (_) => const CertificationListScreen())),
          )),
          const SizedBox(width: 6),
          Expanded(child: _buildStatCard(
            context,
            icon: Icons.article_rounded,
            label: 'posts'.tr(),
            value: stats.postCount.toString(),
            color: colors.activate,
            onTap: () => Navigator.push(context, SlideRoute(builder: (_) => MyPostsScreen(userId: widget.userId))),
          )),
          const SizedBox(width: 6),
          Expanded(child: _buildStatCard(
            context,
            icon: Icons.chat_bubble_rounded,
            label: 'comments'.tr(),
            value: stats.commentCount.toString(),
            color: colors.activate,
            onTap: () => Navigator.push(context, SlideRoute(builder: (_) => MyCommentsScreen(userId: widget.userId))),
          )),
          const SizedBox(width: 6),
          Expanded(child: _buildStatCard(
            context,
            icon: Icons.star_rounded,
            label: 'scraps'.tr(),
            value: stats.scrapCount.toString(),
            color: colors.accentColor,
            onTap: () => Navigator.push(context, SlideRoute(builder: (_) => const MyScrapsScreen())),
          )),
          const SizedBox(width: 6),
          Expanded(child: _buildStatCard(
            context,
            icon: Icons.favorite_rounded,
            label: 'liked_posts'.tr(),
            value: stats.likedPostCount.toString(),
            color: colors.accentColor,
            onTap: () => Navigator.push(context, SlideRoute(builder: (_) => MyLikedPostsScreen(userId: widget.userId))),
          )),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: const Row(
        children: [
          Expanded(child: SkeletonBox(height: 90, borderRadius: BorderRadius.all(Radius.circular(16)))),
          SizedBox(width: 6),
          Expanded(child: SkeletonBox(height: 90, borderRadius: BorderRadius.all(Radius.circular(16)))),
          SizedBox(width: 6),
          Expanded(child: SkeletonBox(height: 90, borderRadius: BorderRadius.all(Radius.circular(16)))),
          SizedBox(width: 6),
          Expanded(child: SkeletonBox(height: 90, borderRadius: BorderRadius.all(Radius.circular(16)))),
          SizedBox(width: 6),
          Expanded(child: SkeletonBox(height: 90, borderRadius: BorderRadius.all(Radius.circular(16)))),
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
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
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
                fontSize: AppDimens.fontSizeTiny,
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
