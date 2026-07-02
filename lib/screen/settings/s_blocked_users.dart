import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
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
    final confirmed = await showConfirmDialog(
      context,
      title: 'unblock_title'.tr(),
      content: 'unblock_confirm'.tr(args: [user.nickname]),
      confirmLabel: 'unblock'.tr(),
    );
    if (!confirmed || !mounted) return;
    try {
      await _service.unblockUser(user.userId);
      if (!mounted) return;
      setState(() => _list?.removeWhere((u) => u.userId == user.userId));
      context.showSuccessSnackbar('unblock_success'.tr(args: [user.nickname]));
    } catch (_) {
      if (mounted) context.showErrorSnackbar('unblock_failed'.tr());
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
      return const Center(child: CircularProgressIndicator());
    }
    if (_list!.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.block_rounded, size: 48, color: colors.textSecondary.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text(
              'no_blocked_users'.tr(),
              style: TextStyle(fontSize: AppDimens.fontSizeMd, color: colors.textSecondary),
            ),
          ],
        ),
      );
    }
    return RefreshIndicator(
      color: colors.activate,
      onRefresh: _load,
      child: ListView.separated(
        itemCount: _list!.length,
        separatorBuilder: (_, __) => Divider(height: 1, color: colors.listDivider),
        itemBuilder: (_, i) => _buildItem(_list![i], colors),
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
      ),
      trailing: OutlinedButton(
        onPressed: () => _unblock(user),
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.textSecondary,
          side: BorderSide(color: colors.listDivider),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
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
