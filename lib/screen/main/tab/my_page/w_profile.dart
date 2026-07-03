import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_level_badge.dart';
import 'package:feple/screen/main/tab/my_page/w_edit_profile.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../../../../provider/user_provider.dart';
import '../../../../model/user_model.dart';

class ProfileWidget extends StatefulWidget {
  final int userId;
  const ProfileWidget({required this.userId, super.key});

  @override
  State<ProfileWidget> createState() => ProfileWidgetState();
}

class ProfileWidgetState extends State<ProfileWidget> {
  bool _fetched = false;
  bool _hasError = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_fetched) {
      _fetched = true;
      _fetchUser();
    }
  }

  void refresh() => _fetchUser();

  Future<void> _fetchUser() async {
    setState(() => _hasError = false);
    try {
      await context.read<UserProvider>().fetchUser(widget.userId);
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.select<UserProvider, User?>((p) => p.user);
    final colors = context.appColors;

    if (_hasError && user == null) {
      return ErrorState(message: 'load_error'.tr(), onRetry: _fetchUser);
    }

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
          _buildProfileImage(user, colors),
          const SizedBox(height: 16),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _buildNicknameText(user, colors),
              const SizedBox(width: 6),
              _buildLevelBadge(user, colors),
            ],
          ),
          if (user.bio != null && user.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                user.bio!,
                style: TextStyle(
                  fontSize: AppDimens.fontSizeSm,
                  color: colors.textSecondary,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
          const SizedBox(height: 16),
          _buildActionButton(
            context,
            colors,
            label: 'edit_profile'.tr(),
            icon: Icons.edit_rounded,
            onPressed: () {
              Navigator.push(
                context,
                SlideRoute(
                    builder: (context) => const EditProfileWidget()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImage(User user, AbstractThemeColors colors) {
    final avatarSize = MediaQuery.sizeOf(context).width * 0.282; // 110/390
    return Container(
      width: avatarSize,
      height: avatarSize,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.profileRingColor,
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.2),
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
          radius: (avatarSize - 12) / 2,
          backgroundImage: (user.profileImageUrl != null &&
                  user.profileImageUrl!.isNotEmpty)
              ? CachedNetworkImageProvider(user.profileImageUrl!,
                  maxWidth: 144) as ImageProvider
              : const AssetImage('assets/image/feple_logo.png'),
          backgroundColor: colors.backgroundMain,
        ),
      ),
    );
  }

  Widget _buildNicknameText(User user, AbstractThemeColors colors) {
    return Text(
      user.nickname,
      style: TextStyle(
        fontSize: AppDimens.fontSizeDisplay,
        fontWeight: FontWeight.w800,
        color: colors.textTitle,
        letterSpacing: -0.5,
      ),
    );
  }

  Widget _buildLevelBadge(User user, AbstractThemeColors colors) {
    return LevelBadge(authorLevel: user.level, fontSize: 22);
  }

  Widget _buildActionButton(
    BuildContext context,
    AbstractThemeColors colors, {
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.actionBtnPrimary,
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 16, color: Theme.of(context).colorScheme.onPrimary),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: AppDimens.fontSizeSm,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onPrimary,
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
