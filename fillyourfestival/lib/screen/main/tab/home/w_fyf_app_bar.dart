import 'package:fast_app_base/common/common.dart';
import 'package:flutter/material.dart';



class FyfAppBar extends StatefulWidget {
  const FyfAppBar(this.appbarTitle, {super.key});

  final String appbarTitle;

  @override
  State<FyfAppBar> createState() => _FyfAppBarState();
}

class _FyfAppBarState extends State<FyfAppBar> {
  bool _showRedDot = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.skyBlue,
            AppColors.skyBlueLight,
          ],
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.menu_rounded, color: Colors.white),
            onPressed: () => openDrawer(context),
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

  void openDrawer(BuildContext context) {
    Scaffold.of(context).openDrawer();
  }
}
