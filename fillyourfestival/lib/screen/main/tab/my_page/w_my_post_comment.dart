import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:flutter/material.dart';

class MyPostCommentWidget extends StatefulWidget {
  const MyPostCommentWidget({super.key});

  @override
  State<MyPostCommentWidget> createState() => _MyPostCommentWidgetState();
}

class _MyPostCommentWidgetState extends State<MyPostCommentWidget> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatCard(
            icon: Icons.verified_rounded,
            label: '인증 뱃지',
            value: '5',
            color: AppColors.sunnyYellow,
          ),
          _buildStatCard(
            icon: Icons.article_rounded,
            label: '게시글',
            value: '23',
            color: AppColors.skyBlue,
          ),
          _buildStatCard(
            icon: Icons.chat_bubble_rounded,
            label: '댓글',
            value: '57',
            color: AppColors.kawaiiPink,
          ),
          _buildStatCard(
            icon: Icons.bookmark_rounded,
            label: '북마크',
            value: '10',
            color: AppColors.kawaiiMint,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      height: 90,
      width: 75,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.textMain,
            ),
          ),
        ],
      ),
    );
  }
}
