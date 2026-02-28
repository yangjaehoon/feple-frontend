import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:flutter/material.dart';

class MyPostCommentWidget extends StatelessWidget {
  const MyPostCommentWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatCard(context,
            icon: Icons.verified_rounded,
            label: '인증 뱃지',
            value: '5',
            color: AppColors.sunnyYellow,
          ),
          _buildStatCard(context,
            icon: Icons.article_rounded,
            label: '게시글',
            value: '23',
            color: AppColors.skyBlue,
          ),
          _buildStatCard(context,
            icon: Icons.chat_bubble_rounded,
            label: '댓글',
            value: '57',
            color: AppColors.kawaiiPink,
          ),
          _buildStatCard(context,
            icon: Icons.bookmark_rounded,
            label: '북마크',
            value: '10',
            color: AppColors.kawaiiMint,
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
