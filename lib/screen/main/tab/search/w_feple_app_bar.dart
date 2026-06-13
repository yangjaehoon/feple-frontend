import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/screen/main/s_main.dart';
import 'package:feple/screen/notification/notification_count_notifier.dart';
import 'package:feple/screen/notification/s_notification.dart';
import 'package:feple/screen/search/s_unified_search.dart';
import 'package:feple/injection.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:flutter/material.dart';

class FepleAppBar extends StatefulWidget {
  const FepleAppBar(this.appbarTitle, {super.key, this.showBackButton = false, this.extraTrailingActions = const []});

  final String appbarTitle;
  final bool showBackButton;
  final List<Widget> extraTrailingActions;

  @override
  State<FepleAppBar> createState() => _FepleAppBarState();
}

class _FepleAppBarState extends State<FepleAppBar> {
  final _countNotifier = sl<NotificationCountNotifier>();

  @override
  void initState() {
    super.initState();
    _countNotifier.addListener(_onCountChanged);
    _countNotifier.load();
  }

  void _onCountChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _countNotifier.removeListener(_onCountChanged);
    super.dispose();
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      SlideRoute(builder: (_) => const NotificationScreen()),
    );
    _countNotifier.load();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final titleStyle = Theme.of(context).appBarTheme.titleTextStyle;
    return Container(
      width: double.infinity,
      height: AppDimens.appBarHeight,
      color: colors.appBarColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildLeadingButton(context),
          _buildTitleLogo(context, titleStyle),
          const Spacer(),
          ...widget.extraTrailingActions,
          _buildSearchButton(context),
          _buildNotificationButton(colors),
        ],
      ),
    );
  }

  Widget _buildLeadingButton(BuildContext context) {
    if (widget.showBackButton) {
      return IconButton(
        tooltip: 'back'.tr(),
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
        onPressed: () => Navigator.of(context).pop(),
      );
    }
    return const SizedBox(width: 16);
  }

  Widget _buildTitleLogo(BuildContext context, TextStyle? titleStyle) {
    return Semantics(
      button: true,
      label: 'home'.tr(),
      child: GestureDetector(
        onTap: () => context.findAncestorStateOfType<MainScreenState>()?.goHome(),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/image/feple_clear_960.png',
              height: 50,
              width: 50,
            ),
            const SizedBox(width: 2),
            Text(
              widget.appbarTitle,
              style: titleStyle?.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchButton(BuildContext context) {
    return IconButton(
      tooltip: 'search'.tr(),
      icon: const Icon(Icons.search_rounded, color: Colors.white),
      onPressed: () => Navigator.push(
        context,
        SlideRoute(builder: (_) => const UnifiedSearchScreen()),
      ),
    );
  }

  Widget _buildNotificationButton(AbstractThemeColors colors) {
    final count = _countNotifier.count;
    return Stack(
      children: [
        IconButton(
          tooltip: 'notifications'.tr(),
          icon: const Icon(Icons.notifications_rounded, color: Colors.white),
          onPressed: _openNotifications,
        ),
        if (count > 0)
          Positioned(
            top: 8,
            right: 8,
            child: _buildUnreadBadge(count),
          ),
      ],
    );
  }

  Widget _buildUnreadBadge(int count) {
    return Container(
      padding: const EdgeInsets.all(2),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      decoration: BoxDecoration(
        color: AppColors.errorRed,
        shape: count > 9 ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: count > 9 ? BorderRadius.circular(8) : null,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
