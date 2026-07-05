import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/screen/main/s_main.dart';
import 'package:feple/screen/notification/notification_count_notifier.dart';
import 'package:feple/screen/notification/s_notification.dart';
import 'package:feple/screen/main/tab/search/s_unified_search.dart';
import 'package:feple/injection.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/navigation_guard.dart';
import 'package:flutter/material.dart';

class FepleAppBar extends StatefulWidget {
  const FepleAppBar(this.appbarTitle, {super.key, this.showBackButton = false, this.extraTrailingActions = const []});

  final String appbarTitle;
  final bool showBackButton;
  final List<Widget> extraTrailingActions;

  @override
  State<FepleAppBar> createState() => _FepleAppBarState();
}

class _FepleAppBarState extends State<FepleAppBar> with NavigationGuard {
  final _countNotifier = sl<NotificationCountNotifier>();

  @override
  void initState() {
    super.initState();
    _countNotifier.load();
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
          ListenableBuilder(
            listenable: _countNotifier,
            builder: (_, _) => _buildNotificationButton(colors),
          ),
        ],
      ),
    );
  }

  Widget _buildLeadingButton(BuildContext context) {
    if (widget.showBackButton) {
      return IconButton(
        tooltip: 'back'.tr(),
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.appColors.appBarIconColor),
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
              // 960px 원본을 50 logical px로 표시 — 3x 디바이스 기준 150 physical px로 디코딩 제한
              cacheWidth: (50 * MediaQuery.devicePixelRatioOf(context)).round(),
            ),
            const SizedBox(width: 2),
            Text(
              widget.appbarTitle,
              style: titleStyle?.copyWith(color: context.appColors.appBarIconColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchButton(BuildContext context) {
    return IconButton(
      tooltip: 'search'.tr(),
      icon: Icon(Icons.search_rounded, color: context.appColors.appBarIconColor),
      onPressed: () => guardedNavigate(() =>
          Navigator.push(context, SlideRoute(builder: (_) => const UnifiedSearchScreen()))),
    );
  }

  Widget _buildNotificationButton(AbstractThemeColors colors) {
    final count = _countNotifier.count;
    return Stack(
      children: [
        IconButton(
          tooltip: 'notifications'.tr(),
          icon: Icon(Icons.notifications_rounded, color: colors.appBarIconColor),
          onPressed: _openNotifications,
        ),
        if (count > 0)
          Positioned(
            top: 8,
            right: 8,
            // 탭은 아래 48x48 IconButton이 이미 처리 — 여기 별도 GestureDetector를
            // 두면 16x16짜리 중복·미달 터치 타겟만 추가될 뿐이라 제거
            child: IgnorePointer(child: _buildUnreadBadge(count, colors)),
          ),
      ],
    );
  }

  Widget _buildUnreadBadge(int count, AbstractThemeColors colors) {
    return Container(
      padding: const EdgeInsets.all(2),
      constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
      decoration: BoxDecoration(
        color: colors.error,
        shape: count > 9 ? BoxShape.rectangle : BoxShape.circle,
        borderRadius: count > 9 ? BorderRadius.circular(AppDimens.radiusSmall) : null,
        border: Border.all(color: Colors.white, width: 1.5),
      ),
      child: Text(
        count > 99 ? '99+' : '$count',
        style: const TextStyle(
          color: Colors.white,
          fontSize: AppDimens.fontSizeMini,
          fontWeight: FontWeight.w700,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
