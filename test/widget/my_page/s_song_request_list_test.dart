import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/song_request_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/my_page/s_song_request_list.dart';
import 'package:feple/service/song_request_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSongRequestService extends Mock implements SongRequestService {}
class MockUserProvider extends Mock implements UserProvider {}

SongRequestModel _req({
  int id = 1,
  String songTitle = '노래제목',
  SongRequestStatus status = SongRequestStatus.pending,
  String? artistName,
}) =>
    SongRequestModel(
      id: id,
      songTitle: songTitle,
      status: status,
      artistName: artistName,
    );

Future<void> _pump(WidgetTester tester, UserProvider userProvider) async {
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
      child: ChangeNotifierProvider<UserProvider>.value(
        value: userProvider,
        child: CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: const MaterialApp(home: SongRequestListScreen()),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockSongRequestService mockService;
  late MockUserProvider mockUserProvider;

  setUp(() {
    mockService = MockSongRequestService();
    mockUserProvider = MockUserProvider();
    when(() => mockUserProvider.currentUserId).thenReturn(42);
    if (sl.isRegistered<SongRequestService>()) sl.unregister<SongRequestService>();
    sl.registerSingleton<SongRequestService>(mockService);
  });

  tearDown(() {
    if (sl.isRegistered<SongRequestService>()) sl.unregister<SongRequestService>();
  });

  group('SongRequestListScreen 로딩', () {
    testWidgets('로딩 중에는 스켈레톤을 보여준다', (tester) async {
      final completer = Completer<List<SongRequestModel>>();
      when(() => mockService.fetchAllMyRequests(42)).thenAnswer((_) => completer.future);

      await _pump(tester, mockUserProvider);

      expect(find.byType(SkeletonBox), findsWidgets);
      completer.complete([]);
      await tester.pumpAndSettle();
    });
  });

  group('SongRequestListScreen 빈 목록', () {
    testWidgets('신청 내역이 없으면 안내 문구를 보여준다', (tester) async {
      when(() => mockService.fetchAllMyRequests(42)).thenAnswer((_) async => []);

      await _pump(tester, mockUserProvider);
      await tester.pumpAndSettle();

      expect(find.text('song_request_no_history'.tr()), findsOneWidget);
    });
  });

  group('SongRequestListScreen 목록 있음', () {
    testWidgets('노래 제목과 상태 배지, 아티스트명을 보여준다', (tester) async {
      when(() => mockService.fetchAllMyRequests(42)).thenAnswer((_) async => [
            _req(id: 1, songTitle: '좋은날', status: SongRequestStatus.approved, artistName: '아이유'),
            _req(id: 2, songTitle: '밤편지', status: SongRequestStatus.pending),
          ]);

      await _pump(tester, mockUserProvider);
      await tester.pumpAndSettle();

      expect(find.text('좋은날'), findsOneWidget);
      expect(find.text('밤편지'), findsOneWidget);
      expect(find.text('아이유'), findsOneWidget);
      expect(find.text('song_status_approved'.tr()), findsWidgets);
      expect(find.text('song_status_pending'.tr()), findsWidgets);
    });
  });

  group('SongRequestListScreen 필터', () {
    testWidgets('상태 필터를 선택하면 해당 상태만 표시된다', (tester) async {
      when(() => mockService.fetchAllMyRequests(42)).thenAnswer((_) async => [
            _req(id: 1, songTitle: '승인곡', status: SongRequestStatus.approved),
            _req(id: 2, songTitle: '대기곡', status: SongRequestStatus.pending),
          ]);

      await _pump(tester, mockUserProvider);
      await tester.pumpAndSettle();
      expect(find.text('승인곡'), findsOneWidget);
      expect(find.text('대기곡'), findsOneWidget);

      await tester.tap(find.text('song_status_approved'.tr()).first);
      await tester.pumpAndSettle();

      expect(find.text('승인곡'), findsOneWidget);
      expect(find.text('대기곡'), findsNothing);
    });
  });

  group('SongRequestListScreen 에러', () {
    testWidgets('로드 실패 시 에러 상태와 재시도 버튼을 보여준다', (tester) async {
      var callCount = 0;
      when(() => mockService.fetchAllMyRequests(42)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return [_req(songTitle: '재시도곡')];
      });

      await _pump(tester, mockUserProvider);
      await tester.pumpAndSettle();

      expect(find.byType(FilledButton), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('재시도곡'), findsOneWidget);
    });
  });

  group('SongRequestListScreen 유저 없음', () {
    testWidgets('로그인 유저가 없으면 로드하지 않는다', (tester) async {
      when(() => mockUserProvider.currentUserId).thenReturn(null);

      await _pump(tester, mockUserProvider);
      await tester.pump(const Duration(milliseconds: 100));

      verifyNever(() => mockService.fetchAllMyRequests(any()));
    });
  });
}
