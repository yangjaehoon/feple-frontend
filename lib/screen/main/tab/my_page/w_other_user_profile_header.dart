import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_assets.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/common/widget/w_level_badge.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/model/user_model.dart';
import 'package:feple/screen/main/tab/my_page/w_profile_avatar_ring.dart';
import 'package:flutter/material.dart';

/// 타인 프로필 화면 상단 헤더 — 아바타 + 닉네임 + 레벨 뱃지 + 소개글.
/// [user]가 아직 로드 전이면 넘겨받은 fallback 값으로 그리고 닉네임은 스켈레톤.
class OtherUserProfileHeader extends StatelessWidget {
  final AppUser? user;
  final String fallbackNickname;
  final String? fallbackImageUrl;

  const OtherUserProfileHeader({
    super.key,
    required this.user,
    required this.fallbackNickname,
    this.fallbackImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final imageUrl = user?.profileImageUrl ?? fallbackImageUrl;
    final nickname = user?.nickname ?? fallbackNickname;
    final bio = user?.bio;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          _buildImage(context, imageUrl, nickname, colors),
          const SizedBox(height: AppDimens.space16),
          user == null
              ? SkeletonBox(
                  width: 120,
                  height: AppDimens.fontSizeDisplay + 4,
                  borderRadius: BorderRadius.circular(AppDimens.radiusXs),
                )
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        nickname,
                        style: TextStyle(
                          fontSize: AppDimens.fontSizeDisplay,
                          fontWeight: FontWeight.w800,
                          color: colors.textTitle,
                          letterSpacing: -0.5,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: AppDimens.space6),
                    LevelBadge(authorLevel: user?.level, fontSize: 22),
                  ],
                ),
          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: AppDimens.space8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                bio,
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
        ],
      ),
    );
  }

  Widget _buildImage(
    BuildContext context,
    String? imageUrl,
    String nickname,
    AbstractThemeColors colors,
  ) {
    final validImageUrl = isCustomAvatarUrl(imageUrl) ? imageUrl : null;
    final avatarSize = ResponsiveSize(context).w(110);
    return ProfileAvatarRing(
      size: avatarSize,
      child: validImageUrl != null
          ? CircleAvatar(
              radius: (avatarSize - 12) / 2,
              backgroundImage:
                  CachedNetworkImageProvider(validImageUrl, maxWidth: 144),
              backgroundColor: colors.backgroundMain,
            )
          : CircleAvatar(
              radius: (avatarSize - 12) / 2,
              backgroundColor: colors.activate,
              child: Text(
                nickname.isNotEmpty ? nickname[0] : '?',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 32,
                ),
              ),
            ),
    );
  }
}
