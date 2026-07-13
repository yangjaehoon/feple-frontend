import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/navigation_guard.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_level_badge.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/common/widget/w_tap_scale.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/certification_model.dart';
import 'package:feple/model/user_model.dart';
import 'package:feple/screen/main/tab/my_page/cert_status_style.dart';
import 'package:feple/screen/main/tab/my_page/w_my_posts.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/service/block_service.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/service/user_activity_service.dart';
import 'package:feple/service/user_service.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../provider/user_provider.dart';

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

class _OtherUserProfileScreenState extends State<OtherUserProfileScreen> with NavigationGuard {
  final _userService = sl<UserService>();
  final _activityService = sl<UserActivityService>();
  final _certService = sl<CertificationService>();
  final _festivalService = sl<FestivalService>();
  final _blockService = sl<BlockService>();

  AppUser? _user;
  int? _postCount;
  List<CertificationModel>? _certifications;
  bool _hasError = false;
  bool _isBlocked = false;
  bool _isBlockLoading = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _hasError = false; });
    try {
      final (user, stats, certifications) = await (
        _userService.fetchUser(widget.userId),
        _activityService.fetchStats(widget.userId),
        _certService.getPublicCertifications(widget.userId),
      ).wait;
      if (!mounted) return;
      setState(() {
        _user = user;
        _postCount = stats.postCount;
        _certifications = certifications;
      });
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
      return;
    }
    // 차단 여부는 부가 정보 — 조회 실패로 프로필 전체를 에러 화면으로 만들지 않음
    try {
      final blockedList = await _blockService.getBlockedUsers();
      if (mounted) setState(() => _isBlocked = blockedList.any((u) => u.userId == widget.userId));
    } catch (e) {
      debugPrint('[OtherUserProfile] blocked list fetch failed: $e');
    }
  }

  Future<void> _toggleBlock() async {
    final willBlock = !_isBlocked;
    if (willBlock) {
      final confirmed = await showConfirmDialog(
        context,
        title: 'block_title'.tr(),
        content: 'block_confirm'.tr(args: [_user?.nickname ?? widget.nickname]),
        confirmLabel: 'block'.tr(),
      );
      if (!confirmed || !mounted) return;
    }

    setState(() => _isBlockLoading = true);
    try {
      if (willBlock) {
        await _blockService.blockUser(widget.userId);
      } else {
        await _blockService.unblockUser(widget.userId);
      }
      if (!mounted) return;
      setState(() => _isBlocked = willBlock);
      final nickname = _user?.nickname ?? widget.nickname;
      context.showSuccessSnackbar(
        willBlock
            ? 'block_success'.tr(args: [nickname])
            : 'unblock_success'.tr(args: [nickname]),
      );
      if (willBlock) Navigator.pop(context);
    } catch (_) {
      if (mounted) context.showErrorSnackbar(willBlock ? 'block_failed'.tr() : 'unblock_failed'.tr());
    } finally {
      if (mounted) setState(() => _isBlockLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SecondaryAppBar(
            title: _user?.nickname ?? widget.nickname,
            actions: [_buildBlockButton(context, colors)],
          ),
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

  Widget _buildBlockButton(BuildContext context, AbstractThemeColors colors) {
    final onAppBar = Theme.of(context).colorScheme.onPrimary;
    if (_isBlockLoading) {
      return Padding(
        padding: const EdgeInsets.only(right: 12),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2, color: onAppBar),
        ),
      );
    }
    return IconButton(
      tooltip: _isBlocked ? 'unblock'.tr() : 'block'.tr(),
      icon: Icon(
        _isBlocked ? Icons.block_rounded : Icons.more_vert_rounded,
        color: onAppBar,
        size: 22,
      ),
      onPressed: _isBlocked ? _toggleBlock : _showBlockMenu,
    );
  }

  void _showBlockMenu() {
    final colors = context.appColors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.shapeSheet)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.block_rounded, color: colors.error),
              title: Text(
                'block'.tr(),
                style: TextStyle(color: colors.error, fontWeight: FontWeight.w500),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _toggleBlock();
              },
            ),
          ],
        ),
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
          const SizedBox(height: 16),
          _buildCertificationSection(colors),
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
                    const SizedBox(width: 6),
                    LevelBadge(authorLevel: level, fontSize: 22),
                  ],
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
        ],
      ),
    );
  }

  Widget _buildProfileImage(String? imageUrl, String nickname, AbstractThemeColors colors) {
    final validImageUrl = (imageUrl != null && imageUrl.isNotEmpty && !imageUrl.contains('feple_logo'))
        ? imageUrl
        : null;
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
        decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surface),
        child: validImageUrl != null
            ? CircleAvatar(
                radius: (avatarSize - 12) / 2,
                backgroundImage: CachedNetworkImageProvider(validImageUrl, maxWidth: 144),
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
      ),
    );
  }

  Widget _buildPostsCard(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TapScale(
        onTap: () {
          final nickname = _user?.nickname ?? widget.nickname;
          guardedNavigate(() => Navigator.push(
            context,
            SlideRoute(
              builder: (_) => MyPostsView(
                userId: widget.userId,
                title: 'user_posts'.tr(args: [nickname]),
              ),
            ),
          ));
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
  Widget _buildCertificationSection(AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Icon(Icons.verified_rounded, color: colors.activate, size: 18),
              const SizedBox(width: 6),
              Text(
                'certification_badge'.tr(),
                style: TextStyle(
                  fontSize: AppDimens.fontSizeMd,
                  fontWeight: FontWeight.w700,
                  color: colors.textTitle,
                ),
              ),
              if (_certifications != null) ...[
                const SizedBox(width: 6),
                Text(
                  '${_certifications!.length}',
                  style: TextStyle(
                    fontSize: AppDimens.fontSizeSm,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: MediaQuery.sizeOf(context).width * 0.385, // 150/390
          child: _certifications == null
              ? _buildCertSkeleton()
              : _certifications!.isEmpty
                  ? _buildCertEmpty(colors)
                  : _buildCertList(colors),
        ),
      ],
    );
  }

  Widget _buildCertSkeleton() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: 3,
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            SkeletonBox(width: 98, height: 98, borderRadius: BorderRadius.all(Radius.circular(49))),
            SizedBox(height: 6),
            SkeletonBox(width: 72, height: 11),
          ],
        ),
      ),
    );
  }

  Widget _buildCertEmpty(AbstractThemeColors colors) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.workspace_premium_outlined, size: 32, color: colors.activate.withValues(alpha: 0.4)),
          const SizedBox(height: 8),
          Text(
            'no_certification'.tr(),
            style: TextStyle(fontSize: AppDimens.fontSizeSm, color: colors.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildCertList(AbstractThemeColors colors) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      itemCount: _certifications!.length,
      itemBuilder: (_, i) => _buildCertItem(_certifications![i], colors),
    );
  }

  Future<void> _navigateToFestival(int festivalId) async {
    try {
      final festival = await _festivalService.fetchById(festivalId);
      if (!mounted) return;
      Navigator.push(context, SlideRoute(builder: (_) => FestivalInformationFragment(poster: festival)));
    } catch (e) {
      debugPrint('[OtherUserProfile] festival fetch error: $e');
    }
  }

  Widget _buildCertItem(CertificationModel cert, AbstractThemeColors colors) {
    final isEnglish = context.isEnglish;
    final ringColor = CertStatus.approved.displayColor(colors);
    return TapScale(
      onTap: () => _navigateToFestival(cert.festivalId),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: ringColor.withValues(alpha: 0.6),
                boxShadow: [
                  BoxShadow(
                    color: colors.cardShadow.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surface),
                child: CircleAvatar(
                  radius: MediaQuery.sizeOf(context).width * 0.113, // 44/390
                  backgroundColor: ringColor.withValues(alpha: 0.15),
                  backgroundImage: cert.posterUrl != null
                      ? CachedNetworkImageProvider(cert.posterUrl!, maxWidth: 132)
                      : null,
                  child: cert.posterUrl == null
                      ? Icon(Icons.photo_rounded, size: 26, color: colors.textTitle.withValues(alpha: 0.3))
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 6),
            SizedBox(
              width: MediaQuery.sizeOf(context).width * 0.272, // 106/390
              child: Text(
                cert.displayFestivalTitle(isEnglish),
                style: TextStyle(fontSize: AppDimens.fontSizeXxs, fontWeight: FontWeight.w600, color: colors.textTitle),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ),
          ],
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

/// 게시글 작성자 프로필로 이동 — [Post]의 userId/nickname/profileImageUrl은
/// 항상 함께 다니는 값이라 호출부마다 currentUserId만 따로 읽지 않도록
/// [navigateToUserProfile]을 감싼 진입점.
void navigateToPostAuthor(
  BuildContext context, {
  required int? userId,
  required String nickname,
  String? profileImageUrl,
}) {
  navigateToUserProfile(
    context,
    userId: userId,
    nickname: nickname,
    profileImageUrl: profileImageUrl,
    currentUserId: context.read<UserProvider>().currentUserId,
  );
}
