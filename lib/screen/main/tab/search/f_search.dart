import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_adaptive_refresh_view.dart';
import 'package:feple/provider/festival_preview_provider.dart';
import 'package:feple/screen/main/tab/search/w_artist_discovery.dart';
import 'package:feple/screen/main/tab/search/w_feple_app_bar.dart';
import 'package:feple/screen/main/tab/search/w_festival_list_swiper.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchFragment extends StatefulWidget {
  const SearchFragment({super.key});

  @override
  State<SearchFragment> createState() => _SearchFragmentState();
}

class _SearchFragmentState extends State<SearchFragment> {
  final _artistDiscoveryKey = GlobalKey<ArtistDiscoverySectionState>();
  FestivalPreviewProvider? _festivalPreviewProvider;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // dispose()에서 context.read()로 다시 조회하면, 트리 해체(예: 로그아웃) 중
    // 이미 deactivate된 ancestor를 조회하려다 예외가 발생할 수 있어 미리 저장해둠
    _festivalPreviewProvider = context.read<FestivalPreviewProvider>();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _festivalPreviewProvider?.addListener(_onProviderChange);
    });
  }

  @override
  void dispose() {
    _festivalPreviewProvider?.removeListener(_onProviderChange);
    super.dispose();
  }

  void _onProviderChange() {
    if (!mounted) return;
    final provider = _festivalPreviewProvider;
    final err = provider?.refreshError;
    if (err == null) return;
    provider!.clearRefreshError();
    context.showErrorSnackbar(err);
  }

  Future<void> _onRefresh() async {
    await Future.wait([
      context.read<FestivalPreviewProvider>().refresh(force: true),
      _artistDiscoveryKey.currentState?.refresh() ?? Future.value(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    context.locale; // Subscribe to locale changes so labels re-translate immediately
    final colors = context.appColors;
    return ColoredBox(
      color: colors.backgroundMain,
      child: Column(
        children: [
          const FepleAppBar('Feple'),
          Expanded(
            child: AdaptiveRefreshView(
              onRefresh: _onRefresh,
              indicatorColor: colors.activate,
              padding: const EdgeInsets.only(bottom: AppDimens.scrollPaddingBottom),
              child: Column(
                children: [
                  const FestivalListSwiperWidget(),
                  ArtistDiscoverySection(key: _artistDiscoveryKey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
