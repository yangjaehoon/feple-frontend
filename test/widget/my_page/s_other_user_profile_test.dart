import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/blocked_user_model.dart';
import 'package:feple/model/certification_model.dart';
import 'package:feple/model/user_model.dart';
import 'package:feple/model/user_stats_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/my_page/s_other_user_profile.dart';
import 'package:feple/service/block_service.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:feple/service/user_activity_service.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockUserService extends Mock implements UserService {}
class MockUserActivityService extends Mock implements UserActivityService {}
class MockCertificationService extends Mock implements CertificationService {}
class MockFestivalService extends Mock implements FestivalService {}
class MockBlockService extends Mock implements BlockService {}
class MockUserProvider extends Mock implements UserProvider {}

const _stats = UserStats(
  postCount: 12,
  commentCount: 0,
  certificationCount: 0,
  scrapCount: 0,
  likedPostCount: 0,
);

CertificationModel _cert({int id = 1, String title = '페스티벌'}) => CertificationModel(
      id: id,
      festivalId: id * 10,
      status: CertStatus.approved,
      festivalTitle: title,
    );

Future<void> _pump(
  WidgetTester tester, {
  int userId = 7,
  String nickname = '상대유저',
}) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final userProvider = MockUserProvider();
  when(() => userProvider.currentUserId).thenReturn(1);

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
          child: MaterialApp(
            home: OtherUserProfileScreen(userId: userId, nickname: nickname),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockUserService mockUserService;
  late MockUserActivityService mockActivityService;
  late MockCertificationService mockCertService;
  late MockFestivalService mockFestivalService;
  late MockBlockService mockBlockService;

  setUp(() {
    mockUserService = MockUserService();
    mockActivityService = MockUserActivityService();
    mockCertService = MockCertificationService();
    mockFestivalService = MockFestivalService();
    mockBlockService = MockBlockService();

    if (sl.isRegistered<UserService>()) sl.unregister<UserService>();
    sl.registerSingleton<UserService>(mockUserService);
    if (sl.isRegistered<UserActivityService>()) sl.unregister<UserActivityService>();
    sl.registerSingleton<UserActivityService>(mockActivityService);
    if (sl.isRegistered<CertificationService>()) sl.unregister<CertificationService>();
    sl.registerSingleton<CertificationService>(mockCertService);
    if (sl.isRegistered<FestivalService>()) sl.unregister<FestivalService>();
    sl.registerSingleton<FestivalService>(mockFestivalService);
    if (sl.isRegistered<BlockService>()) sl.unregister<BlockService>();
    sl.registerSingleton<BlockService>(mockBlockService);

    // 기본: 차단 목록 비어있음
    when(() => mockBlockService.getBlockedUsers()).thenAnswer((_) async => []);
  });

  tearDown(() {
    for (final u in [
      () => sl.unregister<UserService>(),
      () => sl.unregister<UserActivityService>(),
      () => sl.unregister<CertificationService>(),
      () => sl.unregister<FestivalService>(),
      () => sl.unregister<BlockService>(),
    ]) {
      try {
        u();
      } catch (_) {}
    }
  });

  void stubSuccess({
    AppUser? user,
    List<CertificationModel>? certs,
  }) {
    when(() => mockUserService.fetchUser(7))
        .thenAnswer((_) async => user ?? AppUser(id: 7, nickname: '상대유저'));
    when(() => mockActivityService.fetchStats(7)).thenAnswer((_) async => _stats);
    when(() => mockCertService.getPublicCertifications(7))
        .thenAnswer((_) async => certs ?? []);
  }

  group('OtherUserProfileScreen 렌더링', () {
    testWidgets('로딩 완료 후 닉네임과 게시글 수를 보여준다', (tester) async {
      stubSuccess(user: AppUser(id: 7, nickname: '아이돌팬', bio: '페스티벌 러버'));
      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('아이돌팬'), findsWidgets); // 앱바 + 헤더
      expect(find.text('페스티벌 러버'), findsOneWidget);
      expect(find.text('12'), findsOneWidget); // postCount
    });

    testWidgets('인증 내역이 없으면 안내 문구를 보여준다', (tester) async {
      stubSuccess(certs: []);
      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('no_certification'.tr()), findsOneWidget);
    });

    testWidgets('인증 내역이 있으면 인증 카드와 개수를 보여준다', (tester) async {
      stubSuccess(certs: [_cert(id: 1, title: '서울재즈'), _cert(id: 2, title: '펜타포트')]);
      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('서울재즈'), findsOneWidget);
      expect(find.text('펜타포트'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // 인증 개수
    });
  });

  group('OtherUserProfileScreen 로딩', () {
    testWidgets('로딩 중에는 스켈레톤을 보여준다', (tester) async {
      final completer = Completer<AppUser>();
      when(() => mockUserService.fetchUser(7)).thenAnswer((_) => completer.future);
      when(() => mockActivityService.fetchStats(7)).thenAnswer((_) async => _stats);
      when(() => mockCertService.getPublicCertifications(7)).thenAnswer((_) async => []);

      await _pump(tester);

      expect(find.byType(SkeletonBox), findsWidgets);
      completer.complete(AppUser(id: 7, nickname: '상대유저'));
      await tester.pumpAndSettle();
    });
  });

  group('OtherUserProfileScreen 에러', () {
    testWidgets('로드 실패 시 에러 상태와 재시도 버튼을 보여준다', (tester) async {
      var callCount = 0;
      when(() => mockActivityService.fetchStats(7)).thenAnswer((_) async => _stats);
      when(() => mockCertService.getPublicCertifications(7)).thenAnswer((_) async => []);
      when(() => mockUserService.fetchUser(7)).thenAnswer((_) async {
        callCount++;
        if (callCount == 1) throw Exception('네트워크 오류');
        return AppUser(id: 7, nickname: '복구된유저');
      });

      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.text('load_error'.tr()), findsOneWidget);

      await tester.tap(find.byType(FilledButton));
      await tester.pumpAndSettle();

      expect(find.text('복구된유저'), findsWidgets);
    });
  });

  group('OtherUserProfileScreen 차단', () {
    testWidgets('메뉴 버튼을 탭하면 차단 옵션 시트가 뜬다', (tester) async {
      stubSuccess();
      await _pump(tester);
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.more_vert_rounded));
      await tester.pumpAndSettle();

      expect(find.text('block'.tr()), findsWidgets);
    });

    testWidgets('이미 차단한 유저면 차단 아이콘이 표시된다', (tester) async {
      stubSuccess();
      when(() => mockBlockService.getBlockedUsers())
          .thenAnswer((_) async => [const BlockedUserModel(userId: 7, nickname: '상대유저')]);

      await _pump(tester);
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.block_rounded), findsOneWidget);
    });
  });
}
