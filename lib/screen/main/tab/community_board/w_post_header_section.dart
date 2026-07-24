import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_inline_badge.dart';
import 'package:feple/common/widget/w_level_badge.dart';
import 'package:feple/common/widget/w_profile_avatar.dart';
import 'package:flutter/material.dart';

class PostHeaderSection extends StatelessWidget {
  final String title;
  final String nickname;
  final String? profileImageUrl;
  final bool certified;
  final String? userRole;
  final bool anonymous;
  final String? authorLevel;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final VoidCallback? onAuthorTap;

  const PostHeaderSection({
    super.key,
    required this.title,
    required this.nickname,
    this.profileImageUrl,
    required this.certified,
    this.userRole,
    required this.anonymous,
    this.authorLevel,
    this.createdAt,
    this.updatedAt,
    this.onAuthorTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: AppDimens.fontSizeTitle,
            fontWeight: FontWeight.w700,
            color: colors.textTitle,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Semantics(
              button: !anonymous && onAuthorTap != null,
              label: anonymous
                  ? null
                  : 'view_author_profile'.tr(args: [nickname]),
              child: GestureDetector(
                onTap: (!anonymous && onAuthorTap != null) ? onAuthorTap : null,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: ProfileAvatar(
                    imageUrl: profileImageUrl,
                    nickname: nickname,
                    certified: certified,
                    userRole: userRole,
                    radius: 16,
                    anonymous: anonymous,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          nickname,
                          style: TextStyle(
                            fontSize: AppDimens.fontSizeSm,
                            color: colors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      InlineBadge(
                        userRole: userRole,
                        certified: certified,
                        size: 14,
                      ),
                      if (!anonymous) ...[
                        const SizedBox(width: 5),
                        LevelBadge(authorLevel: authorLevel, fontSize: 10),
                      ],
                    ],
                  ),
                  if (createdAt != null)
                    Row(
                      children: [
                        Text(
                          createdAt!.relativeTime,
                          style: TextStyle(
                            fontSize: AppDimens.fontSizeXxs,
                            color: colors.textSecondary.withValues(alpha: 0.65),
                          ),
                        ),
                        if (updatedAt != null &&
                            updatedAt!.difference(createdAt!).inSeconds >
                                10) ...[
                          const SizedBox(width: 4),
                          Text(
                            'edited'.tr(),
                            style: TextStyle(
                              fontSize: AppDimens.fontSizeTiny,
                              color: colors.textSecondary.withValues(
                                alpha: 0.45,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
