import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/navigation_guard.dart';
import 'package:feple/common/widget/w_guest_login_prompt.dart';
import 'package:feple/common/widget/w_settings_item.dart';
import 'package:feple/screen/notice/s_notice_list.dart';
import 'package:flutter/material.dart';

/// 비로그인 게스트가 마이페이지 탭에 들어왔을 때 보여주는 화면.
/// 계정이 없어도 필요한 것만 노출한다 — 로그인 유도 카드 + 공지·문의·약관·방침·버전.
/// (Apple 가이드라인: 이용약관·개인정보처리방침은 계정 없이도 앱 안에서 접근 가능해야 함)
class GuestMyPageView extends StatefulWidget {
  const GuestMyPageView({super.key});

  @override
  State<GuestMyPageView> createState() => _GuestMyPageViewState();
}

class _GuestMyPageViewState extends State<GuestMyPageView> with NavigationGuard {
  @override
  Widget build(BuildContext context) {
    // SettingsItem/버튼의 InkWell·FilledButton은 Material 조상을 요구한다.
    // 실제 앱은 MainScreen의 Scaffold가 제공하지만, 이 뷰만 독립 렌더링될 때도
    // 깨지지 않도록 자체적으로 감싼다.
    return Material(
      type: MaterialType.transparency,
      child: ListView(
        padding: const EdgeInsets.only(bottom: AppDimens.scrollPaddingBottom),
        children: [
          const _LoginPromptCard(),
          const SizedBox(height: AppDimens.space16),
          ...supportLinkItems(
            context,
            onNotices: () => guardedNavigate(() => Navigator.push(
                context, SlideRoute(builder: (_) => const NoticeListScreen()))),
          ),
          const SettingsItemDivider(),
          const AppVersionRow(),
        ],
      ),
    );
  }
}

class _LoginPromptCard extends StatelessWidget {
  const _LoginPromptCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 0),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppDimens.cardRadius),
        border: Border.all(color: colors.activate.withValues(alpha: 0.25)),
      ),
      child: const GuestLoginPrompt(
        icon: Icons.person_outline_rounded,
        messageKey: 'guest_login_required_mypage',
      ),
    );
  }
}
