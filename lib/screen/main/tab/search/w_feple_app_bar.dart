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
    this.showSupport = false,
    this.extraTrailingActions = const [],
  });

  final String appbarTitle;
  final bool showBackButton;

  /// 비로그인 게스트가 앱 안에서 문의·신고 채널(카카오톡)에 닿을 수 있도록(Apple
  /// 가이드라인 1.2) 고객센터 아이콘을 노출할지. 게스트가 처음 보는 메인 탭
  /// (검색·페스티벌 목록)에서만 true — 로그인하면 아이콘이 사라진다(설정에 문의 링크 있음).
  final bool showSupport;
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
    unawaited(_countNotifier.load());
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
          _buildSupportButton(context),
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

  // showSupport가 켜진 메인 탭에서, 비로그인 게스트에게만 노출한다.
  // 로그인 유저는 설정 화면에 문의 링크가 있으므로 앱바에서는 숨겨 정리한다.
  Widget _buildSupportButton(BuildContext context) {
    if (!widget.showSupport) return const SizedBox.shrink();
    final isGuest = context.select<UserProvider, bool>((p) => p.user == null);
    if (!isGuest) return const SizedBox.shrink();
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
