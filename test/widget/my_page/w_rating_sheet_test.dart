import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/screen/main/tab/my_page/w_rating_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef RatingResult = ({int rating, String? review});

/// captured[0]에 시트가 반환한 결과를 담아둔다 (테스트에서 꺼내 확인하는 용도).
Future<void> _openSheet(
  WidgetTester tester, {
  int? initialRating,
  String? initialReview,
  required List<RatingResult?> captured,
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ko'), Locale('en')],
      startLocale: const Locale('ko'),
      fallbackLocale: const Locale('ko'),
      path: 'assets/translations',
      useOnlyLangCode: true,
      child: CustomThemeHolder(
        theme: CustomTheme.light,
        changeTheme: (_) {},
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  captured[0] = await showModalBottomSheet<RatingResult>(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => RatingSheet(
                      festivalTitle: '펜타포트',
                      initialRating: initialRating,
                      initialReview: initialReview,
                    ),
                  );
                },
                child: const Text('열기'),
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.tap(find.text('열기'));
  await tester.pumpAndSettle();
}

void main() {
  group('RatingSheet 렌더링', () {
    testWidgets('제목/페스티벌명/리뷰 입력창을 보여준다', (tester) async {
      await _openSheet(tester, captured: [null]);

      expect(find.text('rating_title'.tr()), findsOneWidget);
      expect(find.text('펜타포트'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('초기 별점이 없으면 완료 버튼이 비활성화된다', (tester) async {
      await _openSheet(tester, captured: [null]);

      final button = tester.widget<LoadingButton>(find.byType(LoadingButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('initialRating/initialReview로 미리 채워진다', (tester) async {
      await _openSheet(
        tester,
        initialRating: 3,
        initialReview: '재밌었어요',
        captured: [null],
      );

      expect(find.text('재밌었어요'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
      expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(2));
    });
  });

  group('RatingSheet 별점 선택', () {
    testWidgets('별을 탭하면 선택 상태가 반영되고 완료 버튼이 활성화된다', (tester) async {
      await _openSheet(tester, captured: [null]);

      await tester.tap(find.byIcon(Icons.star_outline_rounded).at(3)); // 4번째 별
      await tester.pump();

      expect(find.byIcon(Icons.star_rounded), findsNWidgets(4));
      final button = tester.widget<LoadingButton>(find.byType(LoadingButton));
      expect(button.onPressed, isNotNull);
    });
  });

  group('RatingSheet 제출', () {
    testWidgets('완료를 탭하면 별점과 리뷰를 담아 pop된다', (tester) async {
      final captured = <RatingResult?>[null];
      await _openSheet(tester, captured: captured);

      await tester.tap(find.byIcon(Icons.star_outline_rounded).first);
      await tester.pump();
      await tester.enterText(find.byType(TextField), '좋았습니다');
      await tester.tap(find.text('done'.tr()));
      await tester.pumpAndSettle();

      expect(captured[0]?.rating, 1);
      expect(captured[0]?.review, '좋았습니다');
    });

    testWidgets('리뷰를 비워두면 review는 null로 전달된다', (tester) async {
      final captured = <RatingResult?>[null];
      await _openSheet(tester, captured: captured);

      await tester.tap(find.byIcon(Icons.star_outline_rounded).first);
      await tester.pump();
      await tester.tap(find.text('done'.tr()));
      await tester.pumpAndSettle();

      expect(captured[0]?.rating, 1);
      expect(captured[0]?.review, isNull);
    });
  });

  group('RatingSheet 닫기', () {
    testWidgets('변경 사항이 없으면 확인 없이 바로 닫힌다', (tester) async {
      await _openSheet(tester, captured: [null]);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(RatingSheet), findsNothing);
      expect(find.text('discard_changes'.tr()), findsNothing);
    });

    testWidgets('변경 사항이 있으면 확인 다이얼로그를 보여준다', (tester) async {
      await _openSheet(tester, captured: [null]);

      await tester.tap(find.byIcon(Icons.star_outline_rounded).first);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('discard_changes'.tr()), findsOneWidget);
      expect(find.byType(RatingSheet), findsOneWidget); // 시트 유지
    });

    testWidgets('확인 다이얼로그에서 확인하면 시트가 닫힌다', (tester) async {
      await _openSheet(tester, captured: [null]);

      await tester.tap(find.byIcon(Icons.star_outline_rounded).first);
      await tester.pump();
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('discard'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(RatingSheet), findsNothing);
    });
  });
}
