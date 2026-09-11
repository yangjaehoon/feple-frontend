import 'package:feple/common/common.dart';
import 'package:feple/common/constant/store_links.dart';
import 'package:feple/common/util/external_link.dart';
import 'package:feple/common/widget/w_blocking_notice.dart';
import 'package:flutter/material.dart';

/// 현재 버전이 서버가 정한 최소 지원 버전 미만일 때 노출하는 화면.
/// 스토어로 보내는 것 외에 다른 진행 경로가 없다.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlockingNotice(
      icon: Icons.system_update,
      title: 'force_update_title'.tr(),
      message: 'force_update_message'.tr(),
      primaryLabel: 'force_update_action'.tr(),
      onPrimary: () => openExternalUrl(context, kAppDownloadUrl),
    );
  }
}
