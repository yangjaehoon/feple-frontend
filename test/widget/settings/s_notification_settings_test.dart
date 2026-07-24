import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/notification_preference_model.dart';
import 'package:feple/screen/settings/s_notification_settings.dart';
import 'package:feple/service/notification_preference_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockNotificationPreferenceService extends Mock
    implements NotificationPreferenceService {}

const _allEnabled = NotificationPreferenceModel(
  certEnabled: true,
  commentEnabled: true,
  festivalEnabled: true,
  songRequestEnabled: true,
);

Future<void> _pump(WidgetTester tester) async {
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
        child: const MaterialApp(home: NotificationSettingsScreen()),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() => registerFallbackValue(_allEnabled));

  late MockNotificationPreferenceService mockService;

  setUp(() {
    mockService = MockNotificationPreferenceService();
    if (sl.isRegistered<NotificationPreferenceService>()) {
      sl.unregister<NotificationPreferenceService>();
    }
    sl.registerSingleton<NotificationPreferenceService>(mockService);
  });

  tearDown(() {
    if (sl.isRegistered<NotificationPreferenceService>()) {
      sl.unregister<NotificationPreferenceService>();
    }
  });

  group('NotificationSettingsScreen 로딩', () {
    testWidgets('로딩 중에는 스켈레톤을 보여주고 Switch는 없다', (tester) async {
      final completer = Completer<NotificationPreferenceModel>();
      when(() => mockService.getPreferences()).thenAnswer((_) => completer.future);

      await _pump(tester);

      expect(find.byType(Switch), findsNothing);
      completer.complete(_allEnabled);
      await tester.pumpAndSettle();
    });
  });

  group('NotificationSettingsScreen 렌더링', () {
    testWidgets('4개 항목과 현재 값이 Switch에 반영된다', (tester) async {
      when(() => mockService.getPreferences()).thenAnswer((_) async =>
          const NotificationPreferenceModel(
            certEnabled: true,
            commentEnabled: false,
            festivalEnabled: true,
            songRequestEnabled: false,
          ));

      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('notif_cert'.tr()), findsOneWidget);
      expect(find.text('notif_comment'.tr()), findsOneWidget);
      expect(find.text('notif_festival'.tr()), findsOneWidget);
      expect(find.text('notif_song_request'.tr()), findsOneWidget);

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches.map((s) => s.value).toList(), [true, false, true, false]);
    });
  });

  group('NotificationSettingsScreen 토글', () {
    testWidgets('스위치를 탭하면 즉시 값이 바뀌고 updatePreferences가 호출된다', (tester) async {
      when(() => mockService.getPreferences()).thenAnswer((_) async => _allEnabled);
      when(() => mockService.updatePreferences(any())).thenAnswer((_) async {});

      await _pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).first);
      await tester.pump();

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches.first.value, false);
      final captured = verify(() => mockService.updatePreferences(captureAny()))
          .captured
          .single as NotificationPreferenceModel;
      expect(captured.certEnabled, false);
      expect(captured.commentEnabled, true);
      expect(captured.festivalEnabled, true);
      expect(captured.songRequestEnabled, true);
    });

    testWidgets('저장 실패 시 이전 값으로 롤백되고 에러 스낵바를 보여준다', (tester) async {
      when(() => mockService.getPreferences()).thenAnswer((_) async => _allEnabled);
      when(() => mockService.updatePreferences(any())).thenThrow(Exception('네트워크 오류'));

      await _pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byType(Switch).first);
      await tester.pumpAndSettle();

      final switches = tester.widgetList<Switch>(find.byType(Switch)).toList();
      expect(switches.first.value, true); // 롤백됨
      expect(find.text('save_failed'.tr()), findsOneWidget);
    });
  });

  group('NotificationSettingsScreen 에러', () {
    testWidgets('로드 실패 시 에러 상태와 재시도 버튼을 보여준다', (tester) async {
      var callCount = 0;
      when(() => mockService.getPreferences()).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return _allEnabled;
      });

      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('load_error'.tr()), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.byType(Switch), findsWidgets);
    });
  });
}
