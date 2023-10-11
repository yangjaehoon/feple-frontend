import 'package:fast_app_base/common/common.dart';
import 'package:flutter/material.dart';

class CommunityBoardAppBar extends StatefulWidget {
  const CommunityBoardAppBar({super.key});

  @override
  State<CommunityBoardAppBar> createState() => _CommunityBoardAppBarState();
}

class _CommunityBoardAppBarState extends State<CommunityBoardAppBar> {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: context.appColors.appBarBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            " Community Board",
            style: TextStyle(
              fontSize: 22,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {},
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.more_vert),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }

  void openDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }
}
