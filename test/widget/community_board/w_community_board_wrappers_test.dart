import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/constant/board_types.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/screen/main/tab/community_board/w_community_free_board.dart';
import 'package:feple/screen/main/tab/community_board/w_community_hot_board.dart';
import 'package:feple/screen/main/tab/community_board/w_companion_board_card.dart';
import 'package:feple/service/post_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPostService extends Mock implements PostService {}

void main() {
  late MockPostService mockPostService;

  setUp(() {
    mockPostService = MockPostService();
    if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
    sl.registerSingleton<PostService>(mockPostService);
    when(() => mockPostService.fetchPosts(any())).thenAnswer((_) async => <Post>[]);
  });

  tearDown(() {
    if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
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
          child: MaterialApp(home: Scaffold(body: child)),
        ),
      ),
    );
    await tester.pump();
  }

  group('CommunityFreeBoard', () {
    testWidgets('자유 게시판 타이틀로 조회하고 글쓰기 버튼을 보여준다', (tester) async {
      await pump(tester, const CommunityFreeBoard());
      await tester.pump();

      verify(() => mockPostService.fetchPosts(BoardTypes.free)).called(1);
      expect(find.text('free_board'.tr()), findsOneWidget);
      expect(find.text('write_post'.tr()), findsOneWidget);
    });
  });

  group('CommunityHotBoard', () {
    testWidgets('인기 게시판 타이틀로 조회하고 글쓰기 버튼이 없다', (tester) async {
      await pump(tester, const CommunityHotBoard());
      await tester.pump();

      verify(() => mockPostService.fetchPosts(BoardTypes.hot)).called(1);
      expect(find.text('hot_board'.tr()), findsOneWidget);
      expect(find.text('hot_board_empty'.tr()), findsOneWidget);
      expect(find.text('write_post'.tr()), findsNothing);
    });
  });

  group('CompanionBoardCard', () {
    testWidgets('동행 게시판 타이틀로 조회하고 글쓰기 버튼을 보여준다', (tester) async {
      await pump(tester, const CompanionBoardCard());
      await tester.pump();

      verify(() => mockPostService.fetchPosts(BoardTypes.mate)).called(1);
      expect(find.text('companion_board'.tr()), findsOneWidget);
      expect(find.text('write_post'.tr()), findsOneWidget);
    });
  });
}
