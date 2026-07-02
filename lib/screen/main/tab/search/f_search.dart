import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/provider/festival_preview_provider.dart';
import 'package:feple/screen/main/tab/search/w_circle_artist.dart';
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
  final _circleArtistKey = GlobalKey<CircleArtistWidgetState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FestivalPreviewProvider>().addListener(_onProviderChange);
    });
  }

  @override
  void dispose() {
    context.read<FestivalPreviewProvider>().removeListener(_onProviderChange);
    super.dispose();
  }

  void _onProviderChange() {
    if (!mounted) return;
    final provider = context.read<FestivalPreviewProvider>();
    final err = provider.refreshError;
    if (err == null) return;
    provider.clearRefreshError();
    context.showErrorSnackbar(err);
  }

  Future<void> _onRefresh() async {
    await context.read<FestivalPreviewProvider>().refresh(force: true);
    _circleArtistKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return ColoredBox(
      color: colors.backgroundMain,
      child: Column(
        children: [
          const FepleAppBar('Feple'),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              color: colors.activate,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(bottom: AppDimens.scrollPaddingBottom),
                child: Column(
                  children: [
                    const ConcertListSwiperWidget(),
                    CircleArtistWidget(key: _circleArtistKey),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
