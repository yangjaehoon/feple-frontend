import 'package:fast_app_base/common/common.dart';
import 'package:flutter/material.dart';

class FepleAppBar extends StatefulWidget {
  const FepleAppBar(this.appbarTitle, {super.key});

  final String appbarTitle;

  @override
  State<FepleAppBar> createState() => _FepleAppBarState();
}

class _FepleAppBarState extends State<FepleAppBar> {
  bool _showRedDot = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: 60,
      color: colors.appBarColor,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
          Text(
            widget.appbarTitle,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.search_rounded, color: Colors.white),
            onPressed: () {},
          ),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_rounded, color: Colors.white),
                onPressed: () {
                  setState(() {
                    _showRedDot = !_showRedDot;
                  });
                },
              ),
              if (_showRedDot)
                Positioned(
                  top: 10,
                  right: 10,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.redAccent,
                      border: Border.all(color: Colors.white, width: 1.5),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
