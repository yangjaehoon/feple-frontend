import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/user_model.dart';
import 'package:feple/model/user_stats_model.dart';
import 'package:feple/screen/main/tab/my_page/w_my_posts.dart';
import 'package:feple/service/user_activity_service.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/material.dart';

class OtherUserProfileScreen extends StatefulWidget {
  final int userId;
  final String nickname;
  final String? profileImageUrl;

  const OtherUserProfileScreen({
    super.key,
    required this.userId,
    required this.nickname,
    this.profileImageUrl,
  });

  @override
  State<OtherUserProfileScreen> createState() => _OtherUserProfileScreenState();
}

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> {
  final _userService = sl<UserService>();
  final _activityService = sl<UserActivityService>();

  User? _user;
  int? _postCount;
  bool _hasError = false;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _hasError = false; });
    try {
      final results = await Future.wait([
        _userService.fetchUser(widget.userId),
        _activityService.fetchStats(widget.userId),
      ]);
      if (!mounted) return;
      setState(() {
        _user = results[0] as User;
        _postCount = (results[1] as UserStats).postCount;
      });
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SecondaryAppBar(title: _user?.nickname ?? widget.nickname),
          Expanded(
            child: RefreshIndicator(
              color: colors.activate,
              onRefresh: _load,
              child: _hasError ? _buildError() : _buildBody(colors),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(
          height: constraints.maxHeight,
          child: Center(child: ErrorState(message: 'load_error'.tr(), onRetry: _load)),
        ),
      ),
    );
  }

  Widget _buildBody(AbstractThemeColors colors) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: AppDimens.scrollPaddingBottom),
      child: Column(
        children: [
          _buildProfileHeader(colors),
          const SizedBox(height: 8),
          _buildPostsCard(colors),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(AbstractThemeColors colors) {
    final imageUrl = _user?.profileImageUrl ?? widget.profileImageUrl;
    final nickname = _user?.nickname ?? widget.nickname;
    final level = _user?.level;
    final bio = _user?.bio;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
      child: Column(
        children: [
          _buildProfileImage(imageUrl, nickname, colors),
          const SizedBox(height: 16),
          _user == null
              ? SkeletonBox(width: 120, height: AppDimens.fontSizeDisplay + 4,
                  borderRadius: BorderRadius.circular(AppDimens.radiusXs))
              : Text(
                  nickname,
                  style: TextStyle(
                    fontSize: AppDimens.fontSizeDisplay,
                    fontWeight: FontWeight.w800,
                    color: colors.textTitle,
                    letterSpacing: -0.5,
                  ),
                ),
          if (bio != null && bio.isNotEmpty) ...[
            const SizedBox(height: 8),
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
          const SizedBox(height: 4),
          if (level != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: colors.levelBadgeBg.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppDimens.cardRadius),
              ),
              child: Text(
                'Lv.$level',
                style: TextStyle(
                  fontSize: AppDimens.fontSizeSm,
                  fontWeight: FontWeight.w700,
                  color: colors.levelBadgeText,
                ),
              ),
            )
          else
            SkeletonBox(width: 56, height: 26,
                borderRadius: BorderRadius.circular(AppDimens.cardRadius)),
        ],
      ),
    );
  }

  Widget _buildProfileImage(String? imageUrl, String nickname, AbstractThemeColors colors) {
    final validImageUrl = (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.contains('feple_logo'))
        ? imageUrl
        : null;
    return Container(
      width: 110,
      height: 110,
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
        decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surface),
        child: validImageUrl != null
            ? CircleAvatar(
                radius: 48,
                backgroundImage: CachedNetworkImageProvider(validImageUrl, maxWidth: 144),
                backgroundColor: colors.backgroundMain,
              )
            : CircleAvatar(
                radius: 48,
                backgroundColor: colors.activate,
                child: Text(
                  nickname.isNotEmpty ? nickname[0] : '?',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 32,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildPostsCard(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TapScale(
        onTap: () {
          if (_isNavigating) return;
          _isNavigating = true;
          final nickname = _user?.nickname ?? widget.nickname;
          Navigator.push(
            context,
            SlideRoute(
              builder: (_) => MyPostsView(
                userId: widget.userId,
                title: 'user_posts'.tr(args: [nickname]),
              ),
            ),
          ).whenComplete(() { if (mounted) _isNavigating = false; });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppDimens.cardRadiusSmall),
            border: Border.all(color: colors.listDivider),
            boxShadow: [
              BoxShadow(
                color: colors.cardShadow.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Icon(Icons.article_rounded, color: colors.activate, size: 22),
              const SizedBox(width: 12),
              Text(
                'posts'.tr(),
                style: TextStyle(
                  fontSize: AppDimens.fontSizeMd,
                  fontWeight: FontWeight.w600,
                  color: colors.textTitle,
                ),
              ),
              const Spacer(),
              _postCount == null
                  ? SkeletonBox(width: 28, height: 20,
                      borderRadius: BorderRadius.circular(AppDimens.radiusXs))
                  : Text(
                      _postCount.toString(),
                      style: TextStyle(
                        fontSize: AppDimens.fontSizeXl,
                        fontWeight: FontWeight.w800,
                        color: colors.textTitle,
                      ),
                    ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: colors.textSecondary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

/// 커뮤니티 어디서든 프로필 이미지 탭 시 호출.
/// 본인이면 이동 없음, 타인이면 [OtherUserProfileScreen]으로 이동.
void navigateToUserProfile(
  BuildContext context, {
  required int? userId,
  required String nickname,
  String? profileImageUrl,
  required int? currentUserId,
}) {
  if (userId == null) return;
  if (userId == currentUserId) return;
  Navigator.push(
    context,
    SlideRoute(
      builder: (_) => OtherUserProfileScreen(
        userId: userId,
        nickname: nickname,
        profileImageUrl: profileImageUrl,
      ),
    ),
  );
}
