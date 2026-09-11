import 'package:feple/common/common.dart';
import 'package:feple/common/constant/store_links.dart';
import 'package:feple/common/data/preference/prefs.dart';
import 'package:feple/common/util/app_version.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/common/util/external_link.dart';
import 'package:feple/model/app_config_model.dart';
import 'package:flutter/material.dart';

/// 강제는 아니지만 최신 버전이 나왔을 때 띄우는 권장 업데이트 안내.
///
/// 하루 한 번만 노출한다([Prefs.recommendedUpdatePromptedOn]). 사용자가 "나중에"를
/// 눌러도 오늘은 다시 뜨지 않는다.
Future<void> maybePromptRecommendedUpdate(
  BuildContext context, {
  required AppConfigModel config,
  required String currentVersion,
}) async {
  if (config.maintenance) return;
  // 강제 업데이트 대상이면 별도 전용 화면이 처리하므로 여기서는 건너뛴다.
  if (isVersionBelow(currentVersion, config.minSupportedVersion)) return;
  if (!isVersionBelow(currentVersion, config.latestVersion)) return;

  final today = DateTime.now().toYMD;
  if (Prefs.recommendedUpdatePromptedOn.get() == today) return;
  if (!context.mounted) return;

  // 다이얼로그를 실제로 띄우는 시점에 오늘 날짜를 기록한다 — set() 도중 화면이
  // 사라지거나 다이얼로그가 실패해도 "오늘은 이미 띄웠음"으로 잘못 남지 않도록.
  await Prefs.recommendedUpdatePromptedOn.set(today);
  if (!context.mounted) return;

  final confirmed = await showConfirmDialog(
    context,
    title: 'recommended_update_title'.tr(),
    content: 'recommended_update_message'.tr(),
    confirmLabel: 'recommended_update_confirm'.tr(),
    destructive: false,
  );
  if (confirmed && context.mounted) {
    await openExternalUrl(context, kAppDownloadUrl);
  }
}
