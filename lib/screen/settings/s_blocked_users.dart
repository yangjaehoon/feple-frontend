import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/block_action_helper.dart';
import 'package:feple/common/widget/w_animated_list_item.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_profile_avatar.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/blocked_user_model.dart';
import 'package:feple/service/block_service.dart';
import 'package:flutter/material.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/common/util/forced_refresh.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({super.key});

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  final _service = sl<BlockService>();
  List<BlockedUserModel>? _list;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _hasError = false; });
    try {
      final result = await _service.getBlockedUsers();
      if (mounted) setState(() => _list = result);
    } catch (_) {
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _unblock(BlockedUserModel user) async {
    final success = await confirmAndToggleBlock(
      context,
      blockService: _service,
      userId: user.userId,
      nickname: user.nickname,
      block: false,
    );
    if (success && mounted) {
      setState(() => _list?.removeWhere((u) => u.userId == user.userId));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SecondaryAppBar(title: 'blocked_users'.tr()),
          Expanded(child: _buildBody(colors)),
        ],
      ),
    );
  }

  Widget _buildBody(AbstractThemeColors colors) {
    if (_hasError) {
      return ErrorState(message: 'load_error'.tr(), onRetry: _load);
    }
    if (_list == null) {
      return _buildSkeleton(colors);
    }
    if (_list!.isEmpty) {
      return EmptyState(
        icon: Icons.block_rounded,
        title: 'no_blocked_users'.tr(),
      );
    }
    return RefreshIndicator(
      color: colors.activate,
      onRefresh: () => withForcedRefresh(_load),
      child: ListView.separated(
        itemCount: _list!.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: colors.listDivider),
        itemBuilder: (_, i) => AnimatedListItem(index: i, child: _buildItem(_list![i], colors)),
      ),
    );
  }

  Widget _buildSkeleton(AbstractThemeColors colors) {
    final avatarSize = ResponsiveSize(context).w(44);
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: 6,
      separatorBuilder: (_, _) => Divider(height: 1, color: colors.listDivider),
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            SkeletonBox(
              width: avatarSize,
              height: avatarSize,
              borderRadius: BorderRadius.all(Radius.circular(avatarSize / 2)),
            ),
            const SizedBox(width: AppDimens.space16),
            const Expanded(child: SkeletonBox(width: 120, height: 15)),
            const SizedBox(width: AppDimens.space12),
            const SkeletonBox(
              width: 72,
              height: 36,
              borderRadius: BorderRadius.all(Radius.circular(AppDimens.radiusSmall)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BlockedUserModel user, AbstractThemeColors colors) {
    return ListTile(
      tileColor: colors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: ProfileAvatar(
        imageUrl: user.profileImageUrl,
        nickname: user.nickname,
        radius: ResponsiveSize(context).w(22),
      ),
      title: Text(
        user.nickname,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: AppDimens.fontSizeMd,
          color: colors.textTitle,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: OutlinedButton(
        onPressed: () => _unblock(user),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textSecondary,
          side: BorderSide(color: colors.listDivider),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          minimumSize: const Size(72, 36), // 최소 시각 크기
          // tapTargetSize 기본값(padded=48dp) — M3 최소 터치 타겟 준수
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimens.radiusSmall)),
        ),
        child: Text('unblock'.tr(), style: const TextStyle(fontSize: AppDimens.fontSizeSm)),
      ),
    );
  }
}
