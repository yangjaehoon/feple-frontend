import 'package:feple/common/common.dart';
import 'package:feple/common/util/asset_json_loader.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/model/open_source_package.dart';
import 'package:flutter/material.dart';

import 'w_opensource_item.dart';

/// 아래의 명령어를 통해서, 주기적으로 라이센스 json을 최신화 해주세요.
/// flutter pub run flutter_oss_licenses:generate.dart -o assets/json/licenses.json --json
class OpensourceScreen extends StatefulWidget {
  const OpensourceScreen({super.key});

  @override
  State<OpensourceScreen> createState() => _OpensourceScreenState();
}

class _OpensourceScreenState extends State<OpensourceScreen> {
  List<Package> packageList = [];

  @override
  void initState() {
    super.initState();
    initData();
  }

  Future<void> initData() async {
    try {
      final list = await LocalJson.getObjectList<Package>("json/licenses.json");
      if (!mounted) return;
      setState(() => packageList = list);
    } catch (e) {
      debugPrint('opensource license load error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SecondaryAppBar(title: 'opensource'.tr()),
          Expanded(
            child: ListView.separated(
              itemBuilder: (context, index) => OpensourceItem(packageList[index]),
              itemCount: packageList.length,
              separatorBuilder: (context, index) => const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Line(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
