import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/model/song_model.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_song_list_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

class FakeUrlLauncherPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements UrlLauncherPlatform {
  final List<String> launchedUrls = [];
  bool returnSuccess = true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launchedUrls.add(url);
    return returnSuccess;
  }
}

SongModel _song({
  int id = 1,
  String title = '노래',
  String youtubeUrl = 'https://youtube.com/watch?v=abc',
  int festivalCount = 0,
}) =>
    SongModel(
      id: id,
      title: title,
      youtubeVideoId: 'abc',
      youtubeUrl: youtubeUrl,
      festivalCount: festivalCount,
    );

Future<void> _pump(WidgetTester tester, SongModel song, {int index = 0}) async {
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
        child: MaterialApp(
          home: Scaffold(body: SongListTile(song: song, index: index)),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  late FakeUrlLauncherPlatform fakeLauncher;

  setUp(() {
    fakeLauncher = FakeUrlLauncherPlatform();
    UrlLauncherPlatform.instance = fakeLauncher;
  });

  group('SongListTile 렌더링', () {
    testWidgets('순번과 제목을 보여준다', (tester) async {
      await _pump(tester, _song(title: '히트곡'), index: 2);

      expect(find.text('3'), findsOneWidget);
      expect(find.text('히트곡'), findsOneWidget);
    });

    testWidgets('페스티벌 공연 횟수가 있으면 뱃지를 보여준다', (tester) async {
      await _pump(tester, _song(festivalCount: 4));

      expect(find.text('festival_performed_count'.tr(args: ['4'])), findsOneWidget);
    });

    testWidgets('공연 횟수가 없으면 뱃지를 보여주지 않는다', (tester) async {
      await _pump(tester, _song(festivalCount: 0));

      expect(find.text('festival_performed_count'.tr(args: ['0'])), findsNothing);
    });
  });

  group('SongListTile 탭', () {
    testWidgets('탭하면 유튜브 URL을 실행한다', (tester) async {
      await _pump(tester, _song(youtubeUrl: 'https://youtube.com/watch?v=abc'));

      await tester.tap(find.byType(SongListTile));
      await tester.pump();

      expect(fakeLauncher.launchedUrls, ['https://youtube.com/watch?v=abc']);
    });

    testWidgets('유효하지 않은 URL이면 에러 스낵바를 보여주고 실행하지 않는다', (tester) async {
      await _pump(tester, _song(youtubeUrl: 'https://evil.example.com/x'));

      await tester.tap(find.byType(SongListTile));
      await tester.pump();

      expect(find.text('youtube_open_failed'.tr()), findsOneWidget);
      expect(fakeLauncher.launchedUrls, isEmpty);
    });
  });
}
