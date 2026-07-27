import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/song_request_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/my_page/s_song_request_list.dart';
import 'package:feple/screen/main/tab/my_page/w_my_song_requests.dart';
import 'package:feple/service/song_request_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSongRequestService extends Mock implements SongRequestService {}
class MockUserProvider extends Mock implements UserProvider {}

SongRequestModel _request({
  int id = 1,
  String songTitle = '노래 제목',
  SongRequestStatus status = SongRequestStatus.pending,
}) {
  return SongRequestModel(id: id, songTitle: songTitle, status: status);
}

void main() {
  late MockSongRequestService mockService;

  setUp(() {
    mockService = MockSongRequestService();
    if (sl.isRegistered<SongRequestService>()) {
      sl.unregister<SongRequestService>();
    }
    sl.registerSingleton<SongRequestService>(mockService);
  });

  tearDown(() {
    if (sl.isRegistered<SongRequestService>()) {
      sl.unregister<SongRequestService>();
    }
  });

  Future<void> pump(WidgetTester tester, {int? userId = 1}) async {
    SharedPreferences.setMockInitialValues({});
    await EasyLocalization.ensureInitialized();

    final userProvider = MockUserProvider();
    when(() => userProvider.currentUserId).thenReturn(userId);

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
          child: ChangeNotifierProvider<UserProvider>.value(
            value: userProvider,
            child: const MaterialApp(
              home: Scaffold(body: MySongRequestsView()),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('MySongRequestsView 렌더링', () {
    testWidgets('신청곡 목록을 미리보기로 보여준다', (tester) async {
      when(() => mockService.fetchAllMyRequests(1)).thenAnswer(
        (_) async => [
          _request(id: 1, songTitle: '노래A', status: SongRequestStatus.approved),
          _request(id: 2, songTitle: '노래B'),
        ],
      );

      await pump(tester);
      await tester.pump();

      expect(find.text('노래A'), findsOneWidget);
      expect(find.text('노래B'), findsOneWidget);
      expect(find.text('song_status_approved'.tr()), findsOneWidget);
    });

    testWidgets('3개 초과면 더보기 버튼을 보여준다', (tester) async {
      when(() => mockService.fetchAllMyRequests(1)).thenAnswer(
        (_) async => List.generate(5, (i) => _request(id: i, songTitle: '노래$i')),
      );

      await pump(tester);
      await tester.pump();

      expect(find.text('+ 2'), findsOneWidget);
    });

    testWidgets('신청 이력이 없으면 빈 상태를 보여준다', (tester) async {
      when(() => mockService.fetchAllMyRequests(1)).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      expect(find.text('song_request_no_history'.tr()), findsOneWidget);
    });

    testWidgets('로그인 유저가 없으면 조회하지 않는다', (tester) async {
      await pump(tester, userId: null);
      await tester.pump();

      verifyNever(() => mockService.fetchAllMyRequests(any()));
    });
  });

  group('MySongRequestsView 에러', () {
    testWidgets('조회 실패 시 에러 상태를 보여주고 재시도하면 다시 불러온다', (tester) async {
      var callCount = 0;
      when(() => mockService.fetchAllMyRequests(1)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return [_request(songTitle: '복구된 신청곡')];
      });

      await pump(tester);
      await tester.pump();

      expect(find.text('err_fetch_data'.tr()), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pump();

      expect(find.text('복구된 신청곡'), findsOneWidget);
    });
  });

  group('MySongRequestsView 전체보기', () {
    testWidgets('전체보기를 탭하면 신청곡 목록 화면으로 이동한다', (tester) async {
      when(() => mockService.fetchAllMyRequests(1)).thenAnswer((_) async => []);

      await pump(tester);
      await tester.pump();

      await tester.tap(find.text('see_all'.tr()));
      await tester.pumpAndSettle();

      expect(find.byType(SongRequestListScreen), findsOneWidget);
    });
  });
}
