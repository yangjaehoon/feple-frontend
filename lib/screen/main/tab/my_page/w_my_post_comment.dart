import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:fast_app_base/network/dio_client.dart';
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
    final resp = await DioClient.dio.get('/users/${widget.userId}/stats');
    return _UserStats(
      postCount: resp.data['postCount'] as int,
      commentCount: resp.data['commentCount'] as int,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: FutureBuilder<_UserStats>(
        future: _statsFuture,
        builder: (context, snapshot) {
          final postCount = snapshot.data?.postCount.toString() ?? '-';
          final commentCount = snapshot.data?.commentCount.toString() ?? '-';
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildStatCard(context,
                icon: Icons.verified_rounded,
                label: '인증 뱃지',
                value: '0',
                color: AppColors.sunnyYellow,
              ),
              _buildStatCard(context,
                icon: Icons.article_rounded,
                label: '게시글',
                value: postCount,
                color: AppColors.skyBlue,
              ),
              _buildStatCard(context,
                icon: Icons.chat_bubble_rounded,
                label: '댓글',
                value: commentCount,
                color: AppColors.kawaiiPink,
              ),
              _buildStatCard(context,
                icon: Icons.bookmark_rounded,
                label: '북마크',
                value: '0',
                color: AppColors.kawaiiMint,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final colors = context.appColors;
    return Container(
      height: 90,
      width: 75,
      decoration: BoxDecoration(
        color: colors.statCardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.listDivider),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withOpacity(0.03),
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
    );
  }
}

class _UserStats {
  final int postCount;
  final int commentCount;
  const _UserStats({required this.postCount, required this.commentCount});
}
