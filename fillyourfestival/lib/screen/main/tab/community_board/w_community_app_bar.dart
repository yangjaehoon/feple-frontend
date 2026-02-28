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
    final colors = context.appColors;
    return Container(
      height: 60,
      color: colors.appBarColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 16),
            child: Text(
              "Community Board",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.3,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}
