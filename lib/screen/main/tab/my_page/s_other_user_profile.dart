import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/util/navigation_guard.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_refreshable_center.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_report_sheet.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/certification_model.dart';
import 'package:feple/model/user_model.dart';
import 'package:feple/screen/main/tab/my_page/w_my_posts.dart';
import 'package:feple/screen/main/tab/my_page/w_other_user_certifications.dart';
import 'package:feple/screen/main/tab/my_page/w_other_user_link_card.dart';
import 'package:feple/screen/main/tab/my_page/w_other_user_profile_header.dart';
import 'package:feple/screen/main/tab/my_page/w_user_diary_feed_sheet.dart';
import 'package:feple/service/block_service.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/service/festival_diary_service.dart';
import 'package:feple/service/report_service.dart';
import 'package:feple/service/user_activity_service.dart';
import 'package:feple/service/user_service.dart';
import 'package:feple/common/util/block_action_helper.dart';
import 'package:flutter/material.dart';
import 'package:feple/common/util/forced_refresh.dart';

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
  final _blockService = sl<BlockService>();
  final _diaryService = sl<FestivalDiaryService>();
  final _reportService = sl<ReportService>();

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
    setState(() => _isBlockLoading = true);
    final success = await confirmAndToggleBlock(
      context,
      blockService: _blockService,
      userId: widget.userId,
      nickname: _user?.nickname ?? widget.nickname,
      block: willBlock,
      requireConfirm: willBlock,
    );
    if (!mounted) return;
    if (success) {
      setState(() => _isBlocked = willBlock);
      if (willBlock) Navigator.pop(context);
    }
    setState(() => _isBlockLoading = false);
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
              onRefresh: () => withForcedRefresh(_load),
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
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppDimens.shapeSheet)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMenuTile(
              ctx,
              icon: Icon(Icons.flag_outlined, color: colors.textTitle),
              title: Text('report_user'.tr()),
              onSelected: _showReportSheet,
            ),
            _buildMenuTile(
              ctx,
              icon: Icon(Icons.block_rounded, color: colors.error),
              title: Text(
                'block'.tr(),
                style: TextStyle(
                  color: colors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onSelected: _toggleBlock,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuTile(
    BuildContext sheetContext, {
    required Icon icon,
    required Text title,
    required VoidCallback onSelected,
  }) {
    return ListTile(
      leading: icon,
      title: title,
      onTap: () {
        Navigator.pop(sheetContext);
        onSelected();
      },
    );
  }

  void _showReportSheet() {
    showReportSheet(
      context,
      titleKey: 'report_user',
      onSubmit: (reason, detail) =>
          _reportService.submitUserReport(widget.userId, reason, detail: detail),
      duplicateErrorKey: 'report_user_duplicate',
    );
  }

  Widget _buildError() {
    return RefreshableCenter(
      child: ErrorState(message: 'load_error'.tr(), onRetry: _load),
    );
  }

  Widget _buildBody(AbstractThemeColors colors) {
    final nickname = _user?.nickname ?? widget.nickname;
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.only(bottom: AppDimens.scrollPaddingBottom),
      child: Column(
        children: [
          OtherUserProfileHeader(
            user: _user,
            fallbackNickname: widget.nickname,
            fallbackImageUrl: widget.profileImageUrl,
          ),
          const SizedBox(height: AppDimens.space8),
          OtherUserLinkCard(
            icon: Icons.article_rounded,
            label: 'posts'.tr(),
            trailing: _postCount == null
                ? SkeletonBox(
                    width: 28,
                    height: 20,
                    borderRadius: BorderRadius.circular(AppDimens.radiusXs))
                : Text(
                    _postCount!.toDisplayCount(context.locale.languageCode),
                    style: TextStyle(
                      fontSize: AppDimens.fontSizeXl,
                      fontWeight: FontWeight.w800,
                      color: colors.textTitle,
                    ),
                  ),
            onTap: () => guardedNavigate(() => Navigator.push(
                  context,
                  SlideRoute(
                    builder: (_) => MyPostsView(
                      userId: widget.userId,
                      title: 'user_posts'.tr(args: [nickname]),
                    ),
                  ),
                )),
          ),
          const SizedBox(height: AppDimens.space8),
          OtherUserLinkCard(
            icon: Icons.menu_book_outlined,
            label: 'festival_diary'.tr(),
            onTap: () => showAppBottomSheet(
              context,
              builder: (_) => UserDiaryFeedSheet(
                userId: widget.userId,
                nickname: nickname,
                diaryService: _diaryService,
              ),
            ),
          ),
          const SizedBox(height: AppDimens.space16),
          OtherUserCertifications(certifications: _certifications),
        ],
      ),
    );
  }
}
