import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_board_preview_section.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/community_board/w_post_detail_card.dart';
import 'package:feple/service/block_service.dart';
import 'package:feple/service/comment_service.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/service/report_service.dart';
import 'package:feple/service/scrap_service.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockUserService extends Mock implements UserService {}
class MockPostService extends Mock implements PostService {}
class MockCommentService extends Mock implements CommentService {}
class MockScrapService extends Mock implements ScrapService {}
class MockReportService extends Mock implements ReportService {}
class MockBlockService extends Mock implements BlockService {}

Post _post({int id = 1, String title = '게시글 제목'}) => Post(
      id: id,
      title: title,
      content: '내용',
      likeCount: 0,
      nickname: '작성자',
      boardDisplayName: '게시판',
      certified: false,
      anonymous: false,
    );

void _registerServices() {
  if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
  sl.registerSingleton<PostService>(MockPostService());
  if (sl.isRegistered<CommentService>()) sl.unregister<CommentService>();
  sl.registerSingleton<CommentService>(MockCommentService());
  if (sl.isRegistered<ScrapService>()) sl.unregister<ScrapService>();
  sl.registerSingleton<ScrapService>(MockScrapService());
  if (sl.isRegistered<ReportService>()) sl.unregister<ReportService>();
  sl.registerSingleton<ReportService>(MockReportService());
  if (sl.isRegistered<BlockService>()) sl.unregister<BlockService>();
  sl.registerSingleton<BlockService>(MockBlockService());
  if (sl.isRegistered<UserService>()) sl.unregister<UserService>();
  sl.registerSingleton<UserService>(MockUserService());
}

void _unregisterServices() {
  for (final unregister in [
    () => sl.unregister<PostService>(),
    () => sl.unregister<CommentService>(),
    () => sl.unregister<ScrapService>(),
    () => sl.unregister<ReportService>(),
    () => sl.unregister<BlockService>(),
    () => sl.unregister<UserService>(),
  ]) {
    try {
      unregister();
    } catch (_) {}
  }
}

Future<void> _pump(WidgetTester tester, Widget child) async {
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
      child: ChangeNotifierProvider(
        create: (_) => UserProvider(sl<UserService>()),
        child: CustomThemeHolder(
          theme: CustomTheme.light,
          changeTheme: (_) {},
          child: MaterialApp(home: Scaffold(body: child)),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(_registerServices);
  tearDown(_unregisterServices);

  group('BoardPreviewSection 렌더링', () {
    testWidgets('boardName 미지정 시 name_board 형식의 제목을 사용한다', (tester) async {
      await _pump(
        tester,
        BoardPreviewSection(
          name: '아티스트',
          headerIcon: Icons.forum,
          fetchPosts: () async => [_post()],
          postListScreenFactory: () => const Scaffold(body: Text('목록 화면')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('name_board'.tr(args: ['아티스트'])), findsOneWidget);
      expect(find.text('게시글 제목'), findsOneWidget);
    });

    testWidgets('boardName을 지정하면 그대로 사용한다', (tester) async {
      await _pump(
        tester,
        BoardPreviewSection(
          name: '아티스트',
          boardName: '커스텀 게시판',
          headerIcon: Icons.forum,
          fetchPosts: () async => [],
          postListScreenFactory: () => const Scaffold(body: Text('목록 화면')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('커스텀 게시판'), findsOneWidget);
    });

    testWidgets('게시글이 없으면 emptyHint 문구를 보여준다', (tester) async {
      await _pump(
        tester,
        BoardPreviewSection(
          name: '아티스트',
          headerIcon: Icons.forum,
          fetchPosts: () async => [],
          postListScreenFactory: () => const Scaffold(body: Text('목록 화면')),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('be_first_to_discuss'.tr(args: ['아티스트'])), findsOneWidget);
    });
  });

  group('BoardPreviewSection 네비게이션', () {
    testWidgets('헤더를 탭하면 postListScreenFactory 화면으로 이동한다', (tester) async {
      await _pump(
        tester,
        BoardPreviewSection(
          name: '아티스트',
          headerIcon: Icons.forum,
          fetchPosts: () async => [],
          postListScreenFactory: () => const Scaffold(body: Text('목록 화면')),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('name_board'.tr(args: ['아티스트'])));
      await tester.pumpAndSettle();

      expect(find.text('목록 화면'), findsOneWidget);
    });

    testWidgets('게시글을 탭하면 PostDetailCard로 이동한다', (tester) async {
      await _pump(
        tester,
        BoardPreviewSection(
          name: '아티스트',
          headerIcon: Icons.forum,
          fetchPosts: () async => [_post(title: '탭할 게시글')],
          postListScreenFactory: () => const Scaffold(body: Text('목록 화면')),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('탭할 게시글'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(PostDetailCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });

  group('BoardPreviewSection 새로고침', () {
    testWidgets('BoardPreviewSectionState.refresh()가 목록을 다시 불러온다', (tester) async {
      var callCount = 0;
      final key = GlobalKey<BoardPreviewSectionState>();
      await _pump(
        tester,
        BoardPreviewSection(
          key: key,
          name: '아티스트',
          headerIcon: Icons.forum,
          fetchPosts: () async {
            callCount++;
            return callCount == 1 ? [_post(title: '첫번째')] : [_post(title: '갱신됨')];
          },
          postListScreenFactory: () => const Scaffold(body: Text('목록 화면')),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('첫번째'), findsOneWidget);

      await key.currentState!.refresh();
      await tester.pumpAndSettle();

      expect(find.text('갱신됨'), findsOneWidget);
      expect(callCount, 2);
    });
  });

  group('BoardPreviewSection onWriteTap', () {
    testWidgets('빈 목록에서 글쓰기 버튼을 탭하면 onWriteTap이 호출된다', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        BoardPreviewSection(
          name: '아티스트',
          headerIcon: Icons.forum,
          fetchPosts: () async => [],
          postListScreenFactory: () => const Scaffold(body: Text('목록 화면')),
          onWriteTap: () => tapped = true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('write_post'.tr()));
      expect(tapped, true);
    });
  });
}
