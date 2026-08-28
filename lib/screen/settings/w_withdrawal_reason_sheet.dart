import 'package:feple/common/common.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/model/withdrawal_reason.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 탈퇴 사유 선택 바텀시트 — 실제 탈퇴 API는 호출하지 않고 선택된
/// (사유, 상세) 조합만 반환한다. 실제 삭제 확인은 호출부에서 별도
/// showConfirmDialog로 한 번 더 받는다(돌이킬 수 없는 작업이라 2단계 확인).
Future<(WithdrawalReason, String)?> showWithdrawalReasonSheet(BuildContext context) {
  return showAppBottomSheet<(WithdrawalReason, String)>(
    context,
    builder: (_) => const _WithdrawalReasonSheetContent(),
  );
}

class _WithdrawalReasonSheetContent extends StatefulWidget {
  const _WithdrawalReasonSheetContent();

  @override
  State<_WithdrawalReasonSheetContent> createState() => _WithdrawalReasonSheetContentState();
}

class _WithdrawalReasonSheetContentState extends State<_WithdrawalReasonSheetContent> {
  WithdrawalReason? _selected;
  final _detailController = TextEditingController();

  @override
  void dispose() {
    _detailController.dispose();
    super.dispose();
  }

  void _handleContinue() {
    final selected = _selected;
    if (selected == null) return;
    Navigator.pop(context, (selected, _detailController.text.trim()));
  }

  Widget _buildReasonList(AbstractThemeColors colors) {
    return RadioGroup<WithdrawalReason>(
      groupValue: _selected,
      onChanged: (v) => setState(() => _selected = v),
      child: Column(
        children: WithdrawalReason.values.map((r) {
          final label = switch (r) {
            WithdrawalReason.rarelyUsed => 'withdrawal_reason_rarely_used'.tr(),
            WithdrawalReason.notEnoughContent => 'withdrawal_reason_not_enough_content'.tr(),
            WithdrawalReason.bugsOrErrors => 'withdrawal_reason_bugs'.tr(),
            WithdrawalReason.privacyConcern => 'withdrawal_reason_privacy'.tr(),
            WithdrawalReason.other => 'withdrawal_reason_other'.tr(),
          };
          return RadioListTile<WithdrawalReason>(
            value: r,
            title: Text(
              label,
              style: TextStyle(fontSize: AppDimens.fontSizeMd, color: colors.textTitle),
            ),
            dense: true,
            contentPadding: EdgeInsets.zero,
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActions(AbstractThemeColors colors) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: colors.textSecondary,
              side: BorderSide(color: colors.listDivider),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
              ),
            ),
            child: Text('cancel'.tr()),
          ),
        ),
        const SizedBox(width: AppDimens.space12),
        Expanded(
          child: LoadingButton(
            label: 'withdrawal_reason_continue'.tr(),
            onPressed: _selected == null ? null : _handleContinue,
            backgroundColor: colors.error,
            borderRadius: AppDimens.radiusSmall,
            height: 48,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: colors.surface,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppDimens.shapeSheet)),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.viewInsetsOf(context).bottom +
              MediaQuery.viewPaddingOf(context).bottom +
              20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'withdrawal_reason_title'.tr(),
              style: TextStyle(
                fontSize: AppDimens.fontSizeXl,
                fontWeight: FontWeight.w700,
                color: colors.textTitle,
              ),
            ),
            const SizedBox(height: AppDimens.space12),
            _buildReasonList(colors),
            const SizedBox(height: AppDimens.space8),
            Semantics(
              label: 'withdrawal_reason_detail_hint'.tr(),
              child: TextField(
                controller: _detailController,
                decoration: InputDecoration(
                  hintText: 'withdrawal_reason_detail_hint'.tr(),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppDimens.radiusSmall),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: 2,
              ),
            ),
            const SizedBox(height: AppDimens.space16),
            _buildActions(colors),
          ],
        ),
      ),
    );
  }
}
