import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_dimensions.dart';
import 'package:fast_app_base/common/util/responsive_size.dart';
import 'package:fast_app_base/provider/poster/poster_provider.dart';
import 'package:fast_app_base/screen/main/tab/concert_list/w_concert_list.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../home/w_feple_app_bar.dart';

class ConcertListFragment extends StatefulWidget {
  const ConcertListFragment({super.key});

  @override
  State<ConcertListFragment> createState() => _ConcertListFragmentState();
}

class _ConcertListFragmentState extends State<ConcertListFragment> {
  @override
  Widget build(BuildContext context) {
    final rs = ResponsiveSize(context);
    return Container(
        color: context.appColors.backgroundMain,
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(
                top: rs.h(AppDimens.scrollPaddingTop),
                bottom: rs.h(AppDimens.scrollPaddingBottom),
              ),
              child: const Column(
                children: [
                  ConcertListWidget(),
                ],
              ),
            ),
            FepleAppBar("페스티벌 일정 상세보기"),
          ],
        ),
    );
  }
}
