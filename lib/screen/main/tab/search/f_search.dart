import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/responsive_size.dart';
import 'package:feple/provider/festival_preview_provider.dart';
import 'package:feple/screen/main/tab/search/w_circle_artist.dart';
import 'package:feple/screen/main/tab/search/w_festival_list_swiper.dart';
import 'package:feple/screen/main/tab/search/w_feple_app_bar.dart';
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
    context.read<FestivalPreviewProvider>().refresh();
    setState(() => _artistRefreshKey++);
  }

  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    final colors = context.appColors;
    return Container(
      color: colors.backgroundMain,
      child: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _onRefresh,
            color: colors.activate,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.only(
                top: rs.h(AppDimens.scrollPaddingTop),
                bottom: rs.h(AppDimens.scrollPaddingBottom),
              ),
              child: Column(
                children: [
                  const ConcertListSwiperWidget(),
                  CircleArtistWidget(key: ValueKey(_artistRefreshKey)),
                ],
              ),
            ),
          ),
          FepleAppBar("Feple"),
        ],
      ),
    );
  }
}
