import 'package:dio/dio.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/service/report_service.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// 신고 사유 선택 바텀시트.
///
/// [titleKey] — i18n 키 (report_post / report_comment / report_photo 등)
/// [onSubmit] — 선택된 사유와 상세 텍스트를 받아 실제 신고 API를 호출하는 콜백
/// [duplicateErrorKey] — 중복 신고 시 표시할 i18n 에러 키
Future<void> showReportSheet(
  BuildContext context, {
  required String titleKey,
  required Future<void> Function(ReportReason reason, String detail) onSubmit,
  String duplicateErrorKey = 'report_duplicate',
}) async {
  ReportReason? selected;
  final detailController = TextEditingController();

  await showAppBottomSheet<void>(
    context,
    builder: (ctx) {
      return StatefulBuilder(builder: (ctx, setModalState) {
        final colors = ctx.appColors;
        return Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom +
                MediaQuery.of(ctx).viewPadding.bottom +
                20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titleKey.tr(),
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: colors.textTitle,
                ),
              ),
              const SizedBox(height: 12),
              RadioGroup<ReportReason>(
                groupValue: selected,
                onChanged: (v) => setModalState(() => selected = v),
                child: Column(
                  children: ReportReason.values.map((r) {
                    final label = switch (r) {
                      ReportReason.spam => 'report_reason_spam'.tr(),
                      ReportReason.abuse => 'report_reason_abuse'.tr(),
                      ReportReason.obscene => 'report_reason_obscene'.tr(),
                      ReportReason.misinformation =>
                        'report_reason_misinformation'.tr(),
                      ReportReason.other => 'report_reason_other'.tr(),
                    };
                    return RadioListTile<ReportReason>(
                      value: r,
                      title: Text(label,
                          style: TextStyle(fontSize: 14, color: colors.textTitle)),
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: detailController,
                decoration: InputDecoration(
                  hintText: 'report_detail_hint'.tr(),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppDimens.radiusSmall)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: Text('report_cancel'.tr()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: selected == null
                          ? null
                          : () async {
                              Navigator.pop(ctx);
                              try {
                                await onSubmit(
                                    selected!, detailController.text.trim());
                                if (context.mounted) {
                                  context.showSuccessSnackbar(
                                      'report_success'.tr());
                                }
                              } on DioException catch (e) {
                                debugPrint('[Report] submit failed: $e');
                                if (!context.mounted) return;
                                final isConflict = e.response?.statusCode == 409;
                                context.showErrorSnackbar(
                                    isConflict ? duplicateErrorKey.tr() : 'report_failed'.tr());
                              }
                            },
                      child: Text('report_submit'.tr()),
                    ),
                  ),
                ],
              ),
            ],
          ),
          ),
        );
      });
    },
  );
  detailController.dispose();
}
