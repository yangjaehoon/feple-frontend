import 'package:feple/common/common.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/service/block_service.dart';
import 'package:flutter/material.dart';

/// 차단/차단해제 확인 다이얼로그 → 서비스 호출 → 성공/실패 스낵바까지 처리하는 공용 플로우.
/// 목록 갱신, 화면 pop 등 호출부별로 다른 후처리는 반환된 성공 여부를 보고 호출부에서 직접 수행한다.
Future<bool> confirmAndToggleBlock(
  BuildContext context, {
  required BlockService blockService,
  required int userId,
  required String nickname,
  required bool block,
  bool requireConfirm = true,
}) async {
  if (requireConfirm) {
    final confirmed = await showConfirmDialog(
      context,
      title: (block ? 'block_title' : 'unblock_title').tr(),
      content: (block ? 'block_confirm' : 'unblock_confirm').tr(args: [nickname]),
      confirmLabel: (block ? 'block' : 'unblock').tr(),
    );
    if (!confirmed || !context.mounted) return false;
  }
  try {
    if (block) {
      await blockService.blockUser(userId);
    } else {
      await blockService.unblockUser(userId);
    }
    if (!context.mounted) return true;
    context.showSuccessSnackbar((block ? 'block_success' : 'unblock_success').tr(args: [nickname]));
    return true;
  } catch (_) {
    if (context.mounted) {
      context.showErrorSnackbar((block ? 'block_failed' : 'unblock_failed').tr());
    }
    return false;
  }
}
