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
  int _artistRefreshKey = 0;

  Future<void> _onRefresh() async {
    try {
      await context.read<FestivalPreviewProvider>().refresh();
    } catch (_) {}
    setState(() => _artistRefreshKey++);
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
                    CircleArtistWidget(key: ValueKey(_artistRefreshKey)),
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
