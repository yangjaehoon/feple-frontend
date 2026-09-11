import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/data/preference/prefs.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_notice_banner.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Widget _host(Widget child) => CustomThemeHolder(
      theme: CustomTheme.light,
      changeTheme: (_) {},
      child: MaterialApp(home: child),
    );

void main() {
  // AppPreferences._prefs는 late final이라 init은 프로세스(테스트 파일)당 1회만 가능.
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  setUp(() async {
    // 각 테스트를 독립시키기 위해 이전 테스트가 남긴 dismissed 값을 지운다.
    await AppPreferences.setValue<String>(Prefs.dismissedNoticeMessage, null);
  });

  group('NoticeBanner', () {
    testWidgets('message가 null이면 배너 없이 child만 보여준다', (tester) async {
      await tester.pumpWidget(_host(
        const NoticeBanner(message: null, child: Text('content')),
      ));

      expect(find.text('content'), findsOneWidget);
      expect(find.byIcon(Icons.campaign_outlined), findsNothing);
    });

    testWidgets('message가 있으면 배너와 child를 함께 보여준다', (tester) async {
      await tester.pumpWidget(_host(
        const NoticeBanner(message: '공지사항입니다', child: Text('content')),
      ));

      expect(find.text('공지사항입니다'), findsOneWidget);
      expect(find.text('content'), findsOneWidget);
    });

    testWidgets('닫기를 누르면 배너가 사라지고 같은 문구로 다시 안 뜬다', (tester) async {
      await tester.pumpWidget(_host(
        const NoticeBanner(message: '공지', child: Text('content')),
      ));
      expect(find.text('공지'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pump();

      expect(find.text('공지'), findsNothing);
      expect(Prefs.dismissedNoticeMessage.get(), '공지');

      // 같은 문구로 새로 pumpWidget해도(예: 앱 재시작) 다시 뜨지 않는다.
      await tester.pumpWidget(_host(
        const NoticeBanner(message: '공지', child: Text('content')),
      ));
      expect(find.text('공지'), findsNothing);
    });

    testWidgets('닫은 뒤 문구가 바뀌면 다시 뜬다', (tester) async {
      await Prefs.dismissedNoticeMessage.set('옛 공지');

      await tester.pumpWidget(_host(
        const NoticeBanner(message: '새 공지', child: Text('content')),
      ));

      expect(find.text('새 공지'), findsOneWidget);
    });
  });
}
