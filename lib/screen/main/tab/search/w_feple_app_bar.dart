import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/constant/store_links.dart';
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
import 'package:url_launcher/url_launcher.dart';

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
          // 같은 자리에 고객센터(카카오톡 문의) 아이콘을 대신 보여준다.
          if (isGuest)
            _buildSupportButton(context)
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

  Future<void> _openSupport(BuildContext context) async {
    final uri = Uri.parse(kCustomerServiceUrl);
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) context.showErrorSnackbar('link_open_failed'.tr());
  }

  // 비로그인 게스트가 앱 안에서 문의·신고 채널(카카오톡)에 닿을 수 있도록
  // (Apple 가이드라인 1.2) 알림 아이콘 자리에 대신 노출한다. 호출부(build)가
  // 게스트일 때만 렌더링하므로 여기서 로그인 여부를 다시 확인하지 않는다.
  Widget _buildSupportButton(BuildContext context) {
    return IconButton(
      tooltip: 'customer_service'.tr(),
      icon: Icon(Icons.headset_mic_rounded, color: context.appColors.appBarIconColor),
      onPressed: () => _openSupport(context),
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
