import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:feple/common/app_events.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 네트워크 연결이 끊기면 상단에 배너를 표시하는 래퍼 위젯
class OfflineBanner extends StatefulWidget {
  final Widget child;

  const OfflineBanner({super.key, required this.child});

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  bool _isOffline = false;
  // checkConnectivity()는 비동기라, 결과가 도착하기 전에 스트림이 더 최신
  // 상태를 전달할 수 있다. 그때 늦게 온 결과로 덮어쓰면 _onConnectivityChanged의
  // 조기 반환 때문에 다음 연결 변화가 있을 때까지 배너가 틀린 채로 남는다.
  int _syncToken = 0;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  late final AnimationController _animCtrl;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: AppDimens.animNormal,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));

    _subscription =
        Connectivity().onConnectivityChanged.listen(_onConnectivityChanged);
    // 스트림은 "변화"만 알려주므로 현재 상태는 따로 확인해야 한다 — 오프라인인
    // 채로 이 화면에 들어오면 배너가 아예 뜨지 않는다.
    unawaited(_syncCurrentState());
    // connectivity_plus 문서: Android O부터 백그라운드 앱에는 연결 변화가
    // 전달되지 않으므로 앱이 resume될 때마다 상태를 다시 확인해야 한다.
    AppEvents.appResumed.addListener(_onAppResumed);
  }

  void _onAppResumed() => unawaited(_syncCurrentState());

  Future<void> _syncCurrentState() async {
    final token = ++_syncToken;
    try {
      final results = await Connectivity().checkConnectivity();
      // 이 조회가 시작된 뒤 스트림 이벤트나 더 최근 조회가 있었다면 버린다
      if (mounted && token == _syncToken) _onConnectivityChanged(results);
    } catch (e) {
      debugPrint('[OfflineBanner] 연결 상태 확인 실패: $e');
    }
  }

  void _onConnectivityChanged(List<ConnectivityResult> results) {
    // 스트림이 최신 상태를 알려줬으므로 진행 중인 조회 결과는 무효화한다
    _syncToken++;
    final offline =
        results.isNotEmpty && results.every((r) => r == ConnectivityResult.none);
    if (offline == _isOffline) return;
    if (mounted) {
      setState(() => _isOffline = offline);
      if (offline) {
        _animCtrl.forward();
      } else {
        _animCtrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    AppEvents.appResumed.removeListener(_onAppResumed);
    _subscription?.cancel();
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: SlideTransition(
            position: _slideAnim,
            child: Container(
              color: AppColors.offlineBannerBg,
              padding: EdgeInsets.only(
                top: MediaQuery.paddingOf(context).top + 8,
                bottom: 10,
                left: 16,
                right: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.wifi_off_rounded,
                      color: Colors.white70, size: 16),
                  const SizedBox(width: AppDimens.space8),
                  Flexible(
                    child: Text(
                      'offline_banner'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: AppDimens.fontSizeSm,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
