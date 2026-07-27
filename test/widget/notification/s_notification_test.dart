import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/notification_model.dart';
import 'package:feple/model/notification_page.dart';
import 'package:feple/model/notification_type.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/notification/s_notification.dart';
import 'package:feple/screen/notification/w_notification_card.dart';
import 'package:feple/service/artist_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/service/notification_feedable.dart';
import 'package:feple/service/post_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockNotificationFeedable extends Mock implements NotificationFeedable {}
class MockArtistService extends Mock implements ArtistService {}
class MockFestivalService extends Mock implements FestivalService {}
class MockPostService extends Mock implements PostService {}

NotificationModel _item(
  int id, {
  bool read = false,
  NotificationType? type,
  int? referenceId,
  String title = '',
  String? createdAt,
}) {
  return NotificationModel(
    id: id,
    type: type ?? NotificationType.newComment,
    title: title.isEmpty ? '알림 $id' : title,
    body: '본문 $id',
    read: read,
    referenceId: referenceId,
    createdAt: createdAt ?? DateTime.now().toIso8601String(),
  );
}

NotificationPage _page(List<NotificationModel> items, {bool hasMore = false}) =>
    NotificationPage(items: items, hasMore: hasMore);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockNotificationFeedable mockService;
  late MockArtistService mockArtistService;
  late MockFestivalService mockFestivalService;
  late MockPostService mockPostService;

  setUpAll(() {
    registerFallbackValue(NotificationFilter.all);
  });

  setUp(() {
    mockService = MockNotificationFeedable();
    mockArtistService = MockArtistService();
    mockFestivalService = MockFestivalService();
    mockPostService = MockPostService();

    if (sl.isRegistered<NotificationFeedable>()) {
      sl.unregister<NotificationFeedable>();
    }
    sl.registerSingleton<NotificationFeedable>(mockService);
    if (sl.isRegistered<ArtistService>()) sl.unregister<ArtistService>();
    sl.registerSingleton<ArtistService>(mockArtistService);
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
    sl.registerSingleton<FestivalService>(mockFestivalService);
    if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
    sl.registerSingleton<PostService>(mockPostService);
  });

  tearDown(() {
    if (sl.isRegistered<NotificationFeedable>()) {
      sl.unregister<NotificationFeedable>();
    }
    if (sl.isRegistered<ArtistService>()) sl.unregister<ArtistService>();
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
    if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
  });

  Future<void> pump(WidgetTester tester) async {
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
          child: const MaterialApp(home: NotificationScreen()),
        ),
      ),
    );
    await tester.pump();
  }

  group('NotificationScreen 로딩', () {
    testWidgets('로딩 중에는 스켈레톤을 보여준다', (tester) async {
      final completer = Completer<NotificationPage>();
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) => completer.future);

      await pump(tester);

      expect(find.byType(NotificationCard), findsNothing);

      completer.complete(_page([]));
      await tester.pump();
    });
  });

  group('NotificationScreen 에러', () {
    testWidgets('로드 실패 시 에러 상태를 보여주고 재시도하면 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return _page([_item(1, title: '복구된 알림')]);
      });

      await pump(tester);
      await tester.pump();

      expect(find.byType(ErrorState), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('복구된 알림'), findsOneWidget);
    });
  });

  group('NotificationScreen 빈 목록', () {
    testWidgets('알림이 없으면 안내 문구를 보여준다', (tester) async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([]));

      await pump(tester);
      await tester.pump();

      expect(find.text('no_notifications'.tr()), findsOneWidget);
    });
  });

  group('NotificationScreen 목록', () {
    testWidgets('섹션 헤더와 함께 알림 목록을 보여준다', (tester) async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([
                _item(1, title: '오늘 알림', createdAt: DateTime.now().toIso8601String()),
                _item(
                  2,
                  title: '예전 알림',
                  createdAt: DateTime.now()
                      .subtract(const Duration(days: 40))
                      .toIso8601String(),
                ),
              ]));

      await pump(tester);
      await tester.pump();

      expect(find.text('오늘 알림'), findsOneWidget);
      expect(find.text('예전 알림'), findsOneWidget);
      expect(find.text('notif_section_today'.tr()), findsOneWidget);
      expect(find.text('notif_section_earlier'.tr()), findsOneWidget);

      // AnimatedListItem의 stagger 딜레이 타이머를 흘려보내 pending timer 어서션을 피한다
      await tester.pumpAndSettle();
    });
  });

  group('NotificationScreen 필터', () {
    testWidgets('필터 칩을 탭하면 해당 필터로 다시 불러온다', (tester) async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([]));

      await pump(tester);
      await tester.pump();

      await tester.tap(find.text('notif_filter_cert'.tr()));
      await tester.pump();

      verify(() => mockService.fetchPage(0, filter: NotificationFilter.cert))
          .called(1);
    });
  });

  group('NotificationScreen 모두 읽음', () {
    testWidgets('안 읽은 알림이 있으면 모두 읽음 버튼이 활성화되고 탭하면 markAllRead가 호출된다', (tester) async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(1, read: false)]));
      when(() => mockService.markAllRead()).thenAnswer((_) async {});

      await pump(tester);
      await tester.pump();

      final button = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.done_all_rounded),
      );
      expect(button.onPressed, isNotNull);

      await tester.tap(find.widgetWithIcon(IconButton, Icons.done_all_rounded));
      await tester.pump();

      verify(() => mockService.markAllRead()).called(1);
    });

    testWidgets('안 읽은 알림이 없으면 모두 읽음 버튼이 비활성화된다', (tester) async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(1, read: true)]));

      await pump(tester);
      await tester.pump();

      final button = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, Icons.done_all_rounded),
      );
      expect(button.onPressed, isNull);
    });
  });

  group('NotificationScreen 개별 삭제', () {
    testWidgets('스와이프로 삭제하면 실행취소 스낵바가 보이고, 취소하지 않으면 서버 삭제가 확정된다', (tester) async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(1, title: '삭제될 알림')]));
      when(() => mockService.delete(1)).thenAnswer((_) async {});

      await pump(tester);
      await tester.pump();

      await tester.drag(find.text('삭제될 알림'), const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.text('삭제될 알림'), findsNothing);
      expect(find.text('notification_dismissed'.tr()), findsOneWidget);

      // 스낵바가 시간 초과로 닫히면(실행취소 버튼을 누르지 않았으므로) 서버 삭제가 확정된다
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      verify(() => mockService.delete(1)).called(1);
    });

    testWidgets('실행취소를 탭하면 알림이 되살아나고 서버 삭제는 호출되지 않는다', (tester) async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(1, title: '삭제될 알림')]));

      await pump(tester);
      await tester.pump();

      await tester.drag(find.text('삭제될 알림'), const Offset(-500, 0));
      await tester.pumpAndSettle();
      expect(find.text('삭제될 알림'), findsNothing);

      await tester.tap(find.text('undo'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('삭제될 알림'), findsOneWidget);
      verifyNever(() => mockService.delete(any()));
    });
  });

  group('NotificationScreen 전체 삭제', () {
    testWidgets('메뉴에서 전체 삭제를 확인하면 목록이 비워지고 실행취소 스낵바가 보인다', (tester) async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([_item(1, title: '알림A')]));
      when(() => mockService.deleteAll()).thenAnswer((_) async {});

      await pump(tester);
      await tester.pump();

      await tester.tap(find.byIcon(Icons.settings_rounded));
      await tester.pumpAndSettle();
      await tester.tap(find.text('notif_delete_all_confirm'.tr()));
      await tester.pumpAndSettle();

      expect(find.text('notif_delete_all_title'.tr()), findsOneWidget);
      await tester.tap(find.text('notif_delete_all_confirm'.tr()).last);
      await tester.pumpAndSettle();

      expect(find.text('알림A'), findsNothing);
      expect(find.text('notif_delete_all_dismissed'.tr()), findsOneWidget);
    });
  });

  group('NotificationScreen 알림 탭', () {
    testWidgets('댓글형 알림을 탭하면 읽음 처리되고 상세 조회를 시도한다', (tester) async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page([
                _item(
                  1,
                  read: false,
                  type: NotificationType.newComment,
                  referenceId: 100,
                ),
              ]));
      when(() => mockService.markRead(1)).thenAnswer((_) async {});
      final completer = Completer<Post>();
      when(() => mockPostService.fetchPost(100))
          .thenAnswer((_) => completer.future);

      await pump(tester);
      await tester.pump();

      await tester.tap(find.byType(NotificationCard));
      await tester.pump();

      verify(() => mockService.markRead(1)).called(1);
      // 상세 조회 진행 중에는 카드가 로딩 상태를 보여준다
      expect(
        tester.widget<NotificationCard>(find.byType(NotificationCard)).isLoading,
        true,
      );

      completer.completeError(Exception('조회 실패'));
      await tester.pump();
      await tester.pump();

      expect(
        tester.widget<NotificationCard>(find.byType(NotificationCard)).isLoading,
        false,
      );
    });
  });

  group('NotificationScreen 스크롤 상단 이동', () {
    testWidgets('스크롤을 내리면 상단 이동 버튼이 나타나고 탭하면 최상단으로 이동한다', (tester) async {
      when(() => mockService.fetchPage(0, filter: any(named: 'filter')))
          .thenAnswer((_) async => _page(
                List.generate(20, (i) => _item(i, title: '알림 $i')),
              ));

      await pump(tester);
      await tester.pump();
      tester.view.physicalSize = const Size(1080, 700);
      await tester.pump();

      await tester.drag(
        find.byWidgetPredicate(
          (w) => w is ListView && w.scrollDirection == Axis.vertical,
        ),
        const Offset(0, -2000),
      );
      await tester.pump();

      expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_upward_rounded));
      await tester.pumpAndSettle();
    });
  });
}
