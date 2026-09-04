import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/login_gate.dart';
import 'package:feple/screen/main/s_main.dart';
import 'package:feple/screen/notification/notification_count_notifier.dart';
import 'package:feple/screen/notification/s_notification.dart';
import 'package:feple/screen/main/tab/search/s_unified_search.dart';
import 'package:feple/injection.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/navigation_guard.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FepleAppBar extends StatefulWidget {
  const FepleAppBar(
    this.appbarTitle, {
    super.key,
    this.showBackButton = false,
    this.extraTrailingActions = const [],
  });

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
    // 게스트(비로그인)에게 알림함은 계정 전용 기능이라 벨을 숨긴다(아래 build).
    // 개수 조회(/notifications/unread-count)도 게스트에겐 401이므로 생략한다.
    // UserProvider가 없는 컨텍스트(일부 위젯 테스트)는 기존 동작 유지 — 조회한다.
    final userProvider = context.read<UserProvider?>();
    if (userProvider == null || userProvider.user != null) {
      _countNotifier.load();
    }
  }

  Future<void> _openNotifications() async {
    await Navigator.push(
      context,
      SlideRoute(builder: (_) => const NotificationScreen()),
    );
    unawaited(_countNotifier.load());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final titleStyle = Theme.of(context).appBarTheme.titleTextStyle;
    // UserProvider가 없는 컨텍스트(일부 위젯 테스트)에서는 게스트로 보지 않는다(기존 동작).
    final isGuest =
        context.select<UserProvider?, bool>((p) => p != null && p.user == null);
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
          // 알림함은 계정 전용 — 로그인 유저는 알림 아이콘, 비로그인 게스트는
          // 같은 자리에 로그인 버튼을 보여준다(문의·약관·방침은 게스트 마이페이지에 있다).
          if (isGuest)
            _buildLoginButton(context, colors)
          else
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
    return const SizedBox(width: AppDimens.space16);
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

  // 비로그인 게스트에게 알림 아이콘 자리에 노출하는 로그인 CTA. 아이콘 버튼들과
  // 구분되도록 강조색 pill로 그린다. 호출부(build)가 게스트일 때만 렌더링한다.
  Widget _buildLoginButton(BuildContext context, AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.only(right: AppDimens.space8),
      child: TextButton(
        onPressed: () => openLoginScreen(context),
        style: TextButton.styleFrom(
          backgroundColor: colors.activate,
          foregroundColor: Theme.of(context).colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          minimumSize: Size.zero,
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimens.shapeButton),
          ),
        ),
        child: Text(
          'login'.tr(),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: AppDimens.fontSizeSm,
          ),
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
