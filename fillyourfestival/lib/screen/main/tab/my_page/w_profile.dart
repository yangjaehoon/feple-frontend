import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:fast_app_base/screen/main/tab/my_page/w_change_nickname.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/user_provider.dart';

class ProfileWidget extends StatefulWidget {
  final int userId;
  const ProfileWidget({required this.userId, super.key});

  @override
  State<ProfileWidget> createState() => _ProfileWidgetState();
}

class _ProfileWidgetState extends State<ProfileWidget> {
  bool _fetched = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fetched) {
      context.read<UserProvider>().fetchUser(widget.userId);
      _fetched = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserProvider>().user;
    final colors = context.appColors;

    if (user == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: CircularProgressIndicator(color: colors.loadingIndicator),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      child: Column(
        children: [
          // Profile Image with kawaii ring
          Stack(
            children: [
              Container(
                width: 110,
                height: 110,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: colors.profileRingGradient,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: colors.cardShadow.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors.surface,
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundImage: NetworkImage(user.profileImageUrl),
                    backgroundColor: colors.backgroundMain,
                  ),
                ),
              ),
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: colors.surface,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: colors.cardShadow.withOpacity(0.08),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.kawaiiPink,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Nickname
          Text(
            user.nickname,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: colors.textTitle,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          // Level badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: colors.levelBadgeBg.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Lv.${user.level}',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.levelBadgeText,
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildActionButton(
                context,
                label: '닉네임 변경',
                icon: Icons.edit_rounded,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const ChangeNickname()),
                  );
                },
              ),
              const SizedBox(width: 12),
              _buildActionButton(
                context,
                label: '프로필 수정',
                icon: Icons.settings_rounded,
                onPressed: () {},
                isPrimary: true,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    final colors = context.appColors;
    return Container(
      decoration: BoxDecoration(
        gradient: isPrimary
            ? LinearGradient(
                colors: [colors.actionBtnGradientStart, colors.actionBtnGradientEnd],
              )
            : null,
        color: isPrimary ? null : colors.actionBtnSecondaryBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: isPrimary
                ? colors.cardShadow.withOpacity(0.3)
                : colors.cardShadow.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        border: isPrimary ? null : Border.all(color: colors.actionBtnSecondaryBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon,
                    size: 16,
                    color: isPrimary ? Colors.white : colors.textSecondary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: isPrimary ? Colors.white : colors.textTitle,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
