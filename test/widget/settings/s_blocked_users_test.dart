import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/blocked_user_model.dart';
import 'package:feple/screen/settings/s_blocked_users.dart';
import 'package:feple/service/block_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockBlockService extends Mock implements BlockService {}

BlockedUserModel _user({int id = 1, String nickname = '차단유저'}) =>
    BlockedUserModel(userId: id, nickname: nickname);

Future<void> _pump(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

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
        child: const MaterialApp(home: BlockedUsersScreen()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockBlockService mockService;

  setUp(() {
    mockService = MockBlockService();
    if (sl.isRegistered<BlockService>()) sl.unregister<BlockService>();
    sl.registerSingleton<BlockService>(mockService);
  });

  tearDown(() {
    if (sl.isRegistered<BlockService>()) sl.unregister<BlockService>();
  });

  group('BlockedUsersScreen 로딩', () {
    testWidgets('로딩 중에는 스켈레톤을 보여준다', (tester) async {
      final completer = Completer<List<BlockedUserModel>>();
      when(() => mockService.getBlockedUsers()).thenAnswer((_) => completer.future);

      await _pump(tester);

      expect(find.byType(SkeletonBox), findsWidgets);
      completer.complete([]);
      await tester.pumpAndSettle();
    });
  });

  group('BlockedUsersScreen 빈 목록', () {
    testWidgets('차단한 유저가 없으면 안내 문구를 보여준다', (tester) async {
      when(() => mockService.getBlockedUsers()).thenAnswer((_) async => []);

      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('no_blocked_users'.tr()), findsOneWidget);
    });
  });

  group('BlockedUsersScreen 목록 있음', () {
    testWidgets('차단 목록과 차단해제 버튼을 보여준다', (tester) async {
      when(() => mockService.getBlockedUsers())
          .thenAnswer((_) async => [_user(id: 1, nickname: '철수'), _user(id: 2, nickname: '영희')]);

      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('철수'), findsOneWidget);
      expect(find.text('영희'), findsOneWidget);
      expect(find.text('unblock'.tr()), findsNWidgets(2));
    });

    testWidgets('차단해제 확인 후 목록에서 제거된다', (tester) async {
      when(() => mockService.getBlockedUsers())
          .thenAnswer((_) async => [_user(id: 1, nickname: '철수')]);
      when(() => mockService.unblockUser(1)).thenAnswer((_) async {});

      await _pump(tester);
      await tester.pumpAndSettle();
      expect(find.text('철수'), findsOneWidget);

      await tester.tap(find.text('unblock'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('unblock_confirm'.tr(args: ['철수'])), findsOneWidget);
      await tester.tap(find.text('unblock'.tr()).last);
      await tester.pumpAndSettle();

      expect(find.text('철수'), findsNothing);
      verify(() => mockService.unblockUser(1)).called(1);
    });

    testWidgets('차단해제 다이얼로그에서 취소하면 목록이 유지된다', (tester) async {
      when(() => mockService.getBlockedUsers())
          .thenAnswer((_) async => [_user(id: 1, nickname: '철수')]);

      await _pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.text('unblock'.tr()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('cancel'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('철수'), findsOneWidget);
      verifyNever(() => mockService.unblockUser(any()));
    });
  });

  group('BlockedUsersScreen 에러', () {
    testWidgets('로드 실패 시 에러 상태와 재시도 버튼을 보여준다', (tester) async {
      var callCount = 0;
      when(() => mockService.getBlockedUsers()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return [_user(nickname: '재시도유저')];
      });

      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('load_error'.tr()), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('재시도유저'), findsOneWidget);
    });
  });
}
