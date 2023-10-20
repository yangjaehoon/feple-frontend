import 'package:fast_app_base/common/common.dart';
import 'package:flutter/material.dart';

import '../../w_menu_drawer.dart';

class FyfAppBar extends StatefulWidget {


  FyfAppBar(@required this.appbarTitle, {super.key});

  String appbarTitle ='';

  @override
  State<FyfAppBar> createState() => _FyfAppBarState();
}

class _FyfAppBarState extends State<FyfAppBar> {
  bool _showRedDot = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      color: context.appColors.appBarBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.menu),
            onPressed: ()=> openDrawer(context),
          ),
          Text(
            widget.appbarTitle,
            style: TextStyle(
              fontSize: 22,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {},
          ),
          Stack(
            children: [
              IconButton(
                icon: Icon(Icons.notifications),
                onPressed: () {
                  setState(
                    () {
                      _showRedDot = !_showRedDot;
                    },
                  );
                },
              ),
              if (_showRedDot)
                Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.red,
                      ),
                    ),
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
