import 'package:fast_app_base/screen/main/tab/concert_list/w_concert_list.dart';
import 'package:flutter/material.dart';

import '../home/w_fyf_app_bar.dart';

class ConcertListFragment extends StatefulWidget {
  const ConcertListFragment({super.key});


  @override
  State<ConcertListFragment> createState() => _ConcertListFragmentState();
}

class _ConcertListFragmentState extends State<ConcertListFragment> {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      child: const Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.only(
              top: 60,
              bottom: 50,
            ),
            child: Column(
              children: [
                ConcertListWidget(),
              ],
            ),
          ),
          FyfAppBar("페스티벌 일정 상세보기"),
        ],
      ),
    );
  }
}
