import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_surface_card.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/user_stats_model.dart';
import 'package:feple/service/user_activity_service.dart';
import 'package:feple/screen/main/tab/my_page/s_certification_list.dart';
import 'package:feple/screen/main/tab/my_page/w_my_comments.dart';
import 'package:feple/screen/main/tab/my_page/w_my_liked_posts.dart';
import 'package:feple/screen/main/tab/my_page/w_my_posts.dart';
import 'package:feple/screen/main/tab/my_page/w_my_scraps.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/future_refreshable.dart';
import 'package:feple/common/util/navigation_guard.dart';
import 'package:feple/common/util/refresh_coordinator.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

class MyPostCommentView extends StatefulWidget {
  final int userId;
  const MyPostCommentView({super.key, required this.userId});

  @override
  State<MyPostCommentView> createState() => MyPostCommentViewState();
}

class MyPostCommentViewState extends State<MyPostCommentView>
    with
        NavigationGuard,
        FutureRefreshable<UserStats, MyPostCommentView>,
        RefreshableSection<MyPostCommentView> {
  @override
  Future<UserStats> fetchData() =>
      sl<UserActivityService>().fetchStats(widget.userId);

  @override
  Future<void> refreshSection() => refresh();

  Future<void> _navigate(Widget screen) => guardedNavigate(
    () => Navigator.push(context, SlideRoute(builder: (_) => screen)),
  );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: FutureBuilder<UserStats>(
        future: future,
        builder: (context, snapshot) => _buildStatRow(context, snapshot),
      ),
    );
  }

  Widget _buildStatRow(
    BuildContext context,
    AsyncSnapshot<UserStats> snapshot,
  ) {
    if (snapshot.connectionState == ConnectionState.waiting) {
      return _buildSkeleton();
    }
    if (snapshot.hasError) {
      return ErrorState.network(snapshot.error!, onRetry: refresh);
    }
    final stats = snapshot.data!;
    final colors = context.appColors;
    final lang = context.locale.languageCode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.verified_rounded,
              label: 'certification_badge'.tr(),
              value: stats.certificationCount.toDisplayCount(lang),
              color: colors.activate,
              onTap: () => _navigate(const CertificationListScreen()),
            ),
          ),
          const SizedBox(width: AppDimens.space6),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.article_rounded,
              label: 'posts'.tr(),
              value: stats.postCount.toDisplayCount(lang),
              color: colors.activate,
              onTap: () => _navigate(MyPostsView(userId: widget.userId)),
            ),
          ),
          const SizedBox(width: AppDimens.space6),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.chat_bubble_rounded,
              label: 'comments'.tr(),
              value: stats.commentCount.toDisplayCount(lang),
              color: colors.activate,
              onTap: () => _navigate(MyCommentsView(userId: widget.userId)),
            ),
          ),
          const SizedBox(width: AppDimens.space6),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.star_rounded,
              label: 'scraps'.tr(),
              value: stats.scrapCount.toDisplayCount(lang),
              color: colors.accentColor,
              onTap: () => _navigate(const MyScrapsView()),
            ),
          ),
          const SizedBox(width: AppDimens.space6),
          Expanded(
            child: _buildStatCard(
              context,
              icon: Icons.favorite_rounded,
              label: 'liked_posts'.tr(),
              value: stats.likedPostCount.toDisplayCount(lang),
              color: colors.accentColor,
              onTap: () => _navigate(MyLikedPostsView(userId: widget.userId)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: const Row(
        children: [
          Expanded(
            child: SkeletonBox(
              height: 90,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          SizedBox(width: AppDimens.space6),
          Expanded(
            child: SkeletonBox(
              height: 90,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          SizedBox(width: AppDimens.space6),
          Expanded(
            child: SkeletonBox(
              height: 90,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          SizedBox(width: AppDimens.space6),
          Expanded(
            child: SkeletonBox(
              height: 90,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
          SizedBox(width: AppDimens.space6),
          Expanded(
            child: SkeletonBox(
              height: 90,
              borderRadius: BorderRadius.all(Radius.circular(16)),
            ),
          ),
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
    return TapScale(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: colors.statCardBg,
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
          border: Border.all(color: colors.listDivider),
          boxShadow: CardShadows.subtle(colors),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppDimens.space6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: AppDimens.fontSizeTiny,
                fontWeight: FontWeight.w600,
                color: colors.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: AppDimens.fontSizeXl,
                fontWeight: FontWeight.w800,
                color: colors.textTitle,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
