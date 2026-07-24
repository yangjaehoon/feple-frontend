import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/block_action_helper.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/blocked_user_model.dart';
import 'package:feple/service/block_service.dart';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _list!.length,
        separatorBuilder: (_, _) => Divider(height: 1, color: colors.listDivider),
        itemBuilder: (_, i) => _buildItem(_list![i], colors),
      ),
    );
  }

  Widget _buildSkeleton(AbstractThemeColors colors) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: 6,
      separatorBuilder: (_, _) => Divider(height: 1, color: colors.listDivider),
      itemBuilder: (_, _) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            const SkeletonBox(
              width: 44,
              height: 44,
              borderRadius: BorderRadius.all(Radius.circular(22)),
            ),
            const SizedBox(width: 16),
            const Expanded(child: SkeletonBox(width: 120, height: 15)),
            const SizedBox(width: 12),
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
      leading: _buildAvatar(user, colors),
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

  Widget _buildAvatar(BlockedUserModel user, AbstractThemeColors colors) {
    final imageUrl = user.profileImageUrl;
    final valid = imageUrl != null && imageUrl.isNotEmpty && !imageUrl.contains('feple_logo');
    return CircleAvatar(
      radius: 22,
      backgroundColor: colors.activate.withValues(alpha: 0.15),
      backgroundImage: valid ? CachedNetworkImageProvider(imageUrl, maxWidth: 88) : null,
      child: !valid
          ? Text(
              user.nickname.isNotEmpty ? user.nickname[0] : '?',
              style: TextStyle(fontWeight: FontWeight.w700, color: colors.activate),
            )
          : null,
    );
  }
}
