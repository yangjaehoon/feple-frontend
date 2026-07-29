import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/util/block_action_helper.dart';
import 'package:feple/service/block_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockBlockService extends Mock implements BlockService {}

void main() {
  late MockBlockService mockBlockService;

  setUp(() {
    mockBlockService = MockBlockService();
  });

  Future<bool?> pumpAndTap(
    WidgetTester tester, {
    required bool block,
    bool requireConfirm = true,
    bool confirmTap = true,
  }) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    bool? result;
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
                builder: (context) => TextButton(
                  onPressed: () async {
                    result = await confirmAndToggleBlock(
                      context,
                      blockService: mockBlockService,
                      userId: 1,
                      nickname: '유저',
                      block: block,
                      requireConfirm: requireConfirm,
                    );
                  },
                  child: const Text('실행'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.tap(find.text('실행'));
    await tester.pumpAndSettle();

    if (requireConfirm) {
      final confirmLabel = (block ? 'block' : 'unblock').tr();
      if (confirmTap) {
        await tester.tap(find.text(confirmLabel));
      } else {
        await tester.tap(find.text('cancel'.tr()));
      }
      await tester.pumpAndSettle();
    }

    return result;
  }

  group('confirmAndToggleBlock 차단', () {
    testWidgets('확인하면 blockUser를 호출하고 true를 반환한다', (tester) async {
      when(() => mockBlockService.blockUser(1)).thenAnswer((_) async {});

      final result = await pumpAndTap(tester, block: true);

      verify(() => mockBlockService.blockUser(1)).called(1);
      expect(result, isTrue);
      expect(find.text('block_success'.tr(args: ['유저'])), findsOneWidget);
    });

    testWidgets('취소하면 blockUser를 호출하지 않고 false를 반환한다', (tester) async {
      final result = await pumpAndTap(tester, block: true, confirmTap: false);

      verifyNever(() => mockBlockService.blockUser(any()));
      expect(result, isFalse);
    });

    testWidgets('blockUser 실패하면 에러 스낵바를 보여주고 false를 반환한다', (tester) async {
      when(() => mockBlockService.blockUser(1)).thenThrow(Exception('실패'));

      final result = await pumpAndTap(tester, block: true);

      expect(result, isFalse);
      expect(find.text('block_failed'.tr()), findsOneWidget);
    });
  });

  group('confirmAndToggleBlock 차단해제', () {
    testWidgets('확인하면 unblockUser를 호출하고 true를 반환한다', (tester) async {
      when(() => mockBlockService.unblockUser(1)).thenAnswer((_) async {});

      final result = await pumpAndTap(tester, block: false);

      verify(() => mockBlockService.unblockUser(1)).called(1);
      expect(result, isTrue);
    });
  });

  group('confirmAndToggleBlock requireConfirm=false', () {
    testWidgets('확인 다이얼로그 없이 바로 실행한다', (tester) async {
      when(() => mockBlockService.blockUser(1)).thenAnswer((_) async {});

      final result = await pumpAndTap(tester, block: true, requireConfirm: false);

      verify(() => mockBlockService.blockUser(1)).called(1);
      expect(result, isTrue);
    });
  });
}
