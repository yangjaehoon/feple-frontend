import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/data/preference/prefs.dart';
import 'package:flutter/material.dart';

/// 관리자가 `/admin/app-config`에서 등록한 공지를 앱 상단에 배너로 보여주는 래퍼 위젯.
///
/// [OfflineBanner]와 달리 콘텐츠를 덮지 않고 밀어낸다 — 관리자가 직접 켜고 끄는
/// 지속적인 공지라 콘텐츠 일부를 계속 가리면 안 되기 때문. 닫으면 같은 문구는
/// 다시 뜨지 않고([Prefs.dismissedNoticeMessage]), 관리자가 문구를 바꾸면 다시 뜬다.
class NoticeBanner extends StatefulWidget {
  final String? message;
  final Widget child;

  const NoticeBanner({super.key, required this.message, required this.child});

  @override
  State<NoticeBanner> createState() => _NoticeBannerState();
}

class _NoticeBannerState extends State<NoticeBanner> {
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    _syncDismissed();
  }

  @override
  void didUpdateWidget(covariant NoticeBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.message != widget.message) _syncDismissed();
  }

  void _syncDismissed() {
    _dismissed = widget.message != null &&
        Prefs.dismissedNoticeMessage.get() == widget.message;
  }

  Future<void> _dismiss() async {
    final message = widget.message;
    if (message != null) await Prefs.dismissedNoticeMessage.set(message);
    if (mounted) setState(() => _dismissed = true);
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final show = message != null && message.isNotEmpty && !_dismissed;
    if (!show) return widget.child;

    final colors = context.appColors;
    return Column(
      children: [
        // OfflineBanner와 동일한 기법: SafeArea로 감싸는 대신 상태 표시줄 높이만큼
        // padding을 더해 배경색이 상태 표시줄 뒤까지 이어지게 한다 — SafeArea로
        // 감싸면 색이 상태 표시줄 아래에서 뚝 끊겨 그 위 영역이 배경색과 다르게 보인다.
        Container(
          width: double.infinity,
          color: colors.activate,
          padding: EdgeInsets.only(
            top: MediaQuery.paddingOf(context).top + 8,
            bottom: 8,
            left: 16,
          ),
          child: Row(
            children: [
              const Icon(Icons.campaign_outlined,
                  color: Colors.white, size: 18),
              const SizedBox(width: AppDimens.space8),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: AppDimens.fontSizeSm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              IconButton(
                onPressed: _dismiss,
                tooltip: 'close'.tr(),
                icon: const Icon(Icons.close_rounded,
                    color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
        Expanded(child: widget.child),
      ],
    );
  }
}
