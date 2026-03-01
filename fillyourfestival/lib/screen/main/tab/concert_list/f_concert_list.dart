import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_dimensions.dart';
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
    return Container(
        color: context.appColors.backgroundMain,
        child: const Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.only(
                top: AppDimens.scrollPaddingTop,
                bottom: AppDimens.scrollPaddingBottom,
              ),
              child: Column(
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
