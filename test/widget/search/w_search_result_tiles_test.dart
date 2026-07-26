import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/artist_model.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/community_board/w_post_detail_card.dart';
import 'package:feple/screen/main/tab/search/w_search_result_tiles.dart';
import 'package:feple/service/block_service.dart';
import 'package:feple/service/comment_service.dart';
import 'package:feple/service/post_service.dart';
import 'package:feple/service/report_service.dart';
import 'package:feple/service/scrap_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockPostService extends Mock implements PostService {}
class MockCommentService extends Mock implements CommentService {}
class MockScrapService extends Mock implements ScrapService {}
class MockReportService extends Mock implements ReportService {}
class MockBlockService extends Mock implements BlockService {}
class MockUserProvider extends Mock implements UserProvider {}

Artist _artist({String name = '아이유', String nameEn = '', String genre = 'KPOP'}) => Artist(
      id: 1,
      name: name,
      nameEn: nameEn,
      genre: genre,
      profileImageUrl: '',
      followerCount: 12345,
    );

FestivalPreview _festivalPreview({String title = '서울재즈'}) {
  final now = DateTime.now();
  return FestivalPreview(
    id: 1,
    title: title,
    location: '서울',
    posterUrl: '',
    startDate: now.toIso8601String(),
  );
}

Post _post({String title = '게시글 제목', String content = '내용', int likeCount = 3, int commentCount = 2}) =>
    Post(
      id: 1,
      title: title,
      content: content,
      likeCount: likeCount,
      commentCount: commentCount,
      nickname: '작성자',
      boardDisplayName: '자유게시판',
    );

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
      child: CustomThemeHolder(
        theme: CustomTheme.light,
        changeTheme: (_) {},
        child: MaterialApp(home: Scaffold(body: child)),
      ),
    ),
  );
  await tester.pump();
}

Future<void> _pumpWithUserProvider(WidgetTester tester, Widget child) async {
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
          child: MaterialApp(home: Scaffold(body: child)),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('SearchArtistTile', () {
    testWidgets('이름/장르/팔로워 수를 렌더링한다', (tester) async {
      await _pump(tester, SearchArtistTile(data: _artist(name: '아이유', genre: 'BALLAD')));

      expect(find.text('아이유'), findsOneWidget);
      expect(find.text('BALLAD'), findsOneWidget);
      expect(find.text('follower_count'.tr(args: ['12345'])), findsOneWidget);
    });

    testWidgets('highlightKeyword가 있으면 RichText로 렌더링한다', (tester) async {
      await _pump(
        tester,
        SearchArtistTile(data: _artist(name: '아이유'), highlightKeyword: '아이'),
      );

      expect(find.byType(RichText), findsWidgets);
    });

    testWidgets('프로필 이미지가 없으면 기본 아이콘을 보여준다', (tester) async {
      await _pump(tester, SearchArtistTile(data: _artist()));

      expect(find.byIcon(Icons.person), findsOneWidget);
    });
  });

  group('SearchFestivalTile', () {
    testWidgets('제목/위치/시작일을 렌더링한다', (tester) async {
      await _pump(tester, SearchFestivalTile(data: _festivalPreview(title: '펜타포트')));

      expect(find.text('펜타포트'), findsOneWidget);
      expect(find.textContaining('서울'), findsOneWidget);
    });

    testWidgets('포스터 URL이 없으면 기본 아이콘을 보여준다', (tester) async {
      await _pump(tester, SearchFestivalTile(data: _festivalPreview()));

      expect(find.byIcon(Icons.festival_rounded), findsOneWidget);
    });
  });

  group('SearchPostTile', () {
    testWidgets('제목/내용/게시판명/좋아요·댓글 수를 렌더링한다', (tester) async {
      await _pump(
        tester,
        SearchPostTile(data: _post(title: '검색된 글', content: '검색된 내용', likeCount: 5, commentCount: 7)),
      );

      expect(find.text('검색된 글'), findsOneWidget);
      expect(find.text('검색된 내용'), findsOneWidget);
      expect(find.text('자유게시판'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('탭하면 PostDetailCard로 이동한다', (tester) async {
      if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
      if (sl.isRegistered<CommentService>()) sl.unregister<CommentService>();
      if (sl.isRegistered<ScrapService>()) sl.unregister<ScrapService>();
      if (sl.isRegistered<ReportService>()) sl.unregister<ReportService>();
      if (sl.isRegistered<BlockService>()) sl.unregister<BlockService>();
      sl.registerSingleton<PostService>(MockPostService());
      sl.registerSingleton<CommentService>(MockCommentService());
      sl.registerSingleton<ScrapService>(MockScrapService());
      sl.registerSingleton<ReportService>(MockReportService());
      sl.registerSingleton<BlockService>(MockBlockService());
      addTearDown(() {
        if (sl.isRegistered<PostService>()) sl.unregister<PostService>();
        if (sl.isRegistered<CommentService>()) sl.unregister<CommentService>();
        if (sl.isRegistered<ScrapService>()) sl.unregister<ScrapService>();
        if (sl.isRegistered<ReportService>()) sl.unregister<ReportService>();
        if (sl.isRegistered<BlockService>()) sl.unregister<BlockService>();
      });

      await _pumpWithUserProvider(tester, SearchPostTile(data: _post(title: '검색된 글')));

      await tester.tap(find.text('검색된 글'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(PostDetailCard), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
