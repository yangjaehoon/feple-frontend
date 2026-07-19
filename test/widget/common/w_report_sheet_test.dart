import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/common/widget/w_report_sheet.dart';
import 'package:feple/model/report_reason.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'common_widget_test_harness.dart';

Widget _trigger({
  required Future<void> Function(ReportReason reason, String detail) onSubmit,
  String duplicateErrorKey = 'report_duplicate',
}) {
  return Builder(
    builder: (context) => ElevatedButton(
      onPressed: () => showReportSheet(
        context,
        titleKey: 'report_post',
        onSubmit: onSubmit,
        duplicateErrorKey: duplicateErrorKey,
      ),
      child: const Text('신고하기'),
    ),
  );
}

void main() {
  group('ReportSheet 렌더링', () {
    testWidgets('열면 제목, 사유 목록, 상세 입력, 액션 버튼이 보인다', (tester) async {
      await pumpCommonWidget(tester, _trigger(onSubmit: (_, _) async {}));

      await tester.tap(find.text('신고하기'));
      await tester.pumpAndSettle();

      expect(find.text('report_post'.tr()), findsOneWidget);
      expect(find.text('report_reason_spam'.tr()), findsOneWidget);
      expect(find.text('report_reason_abuse'.tr()), findsOneWidget);
      expect(find.text('report_reason_obscene'.tr()), findsOneWidget);
      expect(find.text('report_reason_misinformation'.tr()), findsOneWidget);
      expect(find.text('report_reason_other'.tr()), findsOneWidget);
      expect(find.text('report_cancel'.tr()), findsOneWidget);
      expect(find.text('report_submit'.tr()), findsOneWidget);
    });

    testWidgets('사유를 선택하기 전에는 제출 버튼이 비활성화된다', (tester) async {
      await pumpCommonWidget(tester, _trigger(onSubmit: (_, _) async {}));
      await tester.tap(find.text('신고하기'));
      await tester.pumpAndSettle();

      final loadingButton = tester.widget<LoadingButton>(find.byType(LoadingButton));
      expect(loadingButton.onPressed, isNull);
    });

    testWidgets('사유를 선택하면 제출 버튼이 활성화된다', (tester) async {
      await pumpCommonWidget(tester, _trigger(onSubmit: (_, _) async {}));
      await tester.tap(find.text('신고하기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('report_reason_spam'.tr()));
      await tester.pump();

      final loadingButton = tester.widget<LoadingButton>(find.byType(LoadingButton));
      expect(loadingButton.onPressed, isNotNull);
    });
  });

  group('ReportSheet 취소', () {
    testWidgets('취소 버튼을 탭하면 onSubmit 호출 없이 닫힌다', (tester) async {
      var submitted = false;
      await pumpCommonWidget(
        tester,
        _trigger(onSubmit: (_, _) async => submitted = true),
      );
      await tester.tap(find.text('신고하기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('report_cancel'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('report_post'.tr()), findsNothing);
      expect(submitted, false);
    });
  });

  group('ReportSheet 제출', () {
    testWidgets('사유+상세를 입력하고 제출하면 onSubmit이 호출되고 시트가 닫힌다', (tester) async {
      ReportReason? capturedReason;
      String? capturedDetail;
      await pumpCommonWidget(
        tester,
        _trigger(onSubmit: (reason, detail) async {
          capturedReason = reason;
          capturedDetail = detail;
        }),
      );
      await tester.tap(find.text('신고하기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('report_reason_abuse'.tr()));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '상세 내용입니다');

      await tester.tap(find.text('report_submit'.tr()));
      await tester.pumpAndSettle();

      expect(capturedReason, ReportReason.abuse);
      expect(capturedDetail, '상세 내용입니다');
      expect(find.text('report_post'.tr()), findsNothing);
    });

    testWidgets('409 Conflict면 중복 신고 에러 메시지를 보여주고 시트는 유지된다', (tester) async {
      await pumpCommonWidget(
        tester,
        _trigger(onSubmit: (_, _) async {
          throw DioException(
            requestOptions: RequestOptions(path: '/posts/1/report'),
            response: Response(
              requestOptions: RequestOptions(path: '/posts/1/report'),
              statusCode: 409,
            ),
          );
        }),
      );
      await tester.tap(find.text('신고하기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('report_reason_spam'.tr()));
      await tester.pump();
      await tester.tap(find.text('report_submit'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('report_duplicate'.tr()), findsOneWidget);
      expect(find.text('report_post'.tr()), findsOneWidget); // 시트 유지
    });

    testWidgets('그 외 오류면 일반 실패 메시지를 보여준다', (tester) async {
      await pumpCommonWidget(
        tester,
        _trigger(onSubmit: (_, _) async {
          throw DioException(
            requestOptions: RequestOptions(path: '/posts/1/report'),
            response: Response(
              requestOptions: RequestOptions(path: '/posts/1/report'),
              statusCode: 500,
            ),
          );
        }),
      );
      await tester.tap(find.text('신고하기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('report_reason_spam'.tr()));
      await tester.pump();
      await tester.tap(find.text('report_submit'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('report_failed'.tr()), findsOneWidget);
    });

    testWidgets('제출 중에는 LoadingButton이 로딩 상태가 된다', (tester) async {
      await pumpCommonWidget(
        tester,
        _trigger(onSubmit: (_, _) => Future.delayed(const Duration(milliseconds: 200))),
      );
      await tester.tap(find.text('신고하기'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('report_reason_spam'.tr()));
      await tester.pump();
      await tester.tap(find.text('report_submit'.tr()));
      await tester.pump();

      final loadingButton = tester.widget<LoadingButton>(find.byType(LoadingButton));
      expect(loadingButton.isLoading, true);

      await tester.pumpAndSettle();
    });
  });
}
