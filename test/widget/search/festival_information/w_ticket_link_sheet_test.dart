import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/data/preference/app_preferences.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/model/ticket_link.dart';
import 'package:feple/screen/main/tab/search/festival_information/w_ticket_link_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await AppPreferences.init();
  });

  Future<void> pump(WidgetTester tester, {required List<TicketLink> links}) async {
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
            home: Scaffold(body: TicketLinkSheet(links: links)),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  group('TicketLinkSheet 예매처 아이콘', () {
    testWidgets('알려진 예매처 링크는 브랜드 로고 이미지를 보여준다', (tester) async {
      await pump(tester, links: const [
        TicketLink(label: '인터파크', url: 'https://tickets.interpark.com/goods/1'),
      ]);

      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.confirmation_number_outlined), findsNothing);
    });

    testWidgets('알려지지 않은 예매처 링크는 기본 티켓 아이콘을 보여준다', (tester) async {
      await pump(tester, links: const [
        TicketLink(label: '기타', url: 'https://example.com/booking'),
      ]);

      expect(find.byType(Image), findsNothing);
      expect(find.byIcon(Icons.confirmation_number_outlined), findsOneWidget);
    });

    testWidgets('알려진/알려지지 않은 예매처가 섞이면 각각 올바르게 표시된다', (tester) async {
      await pump(tester, links: const [
        TicketLink(label: '예스24', url: 'https://ticket.yes24.com/Perf/1'),
        TicketLink(label: '기타', url: 'https://example.com/booking'),
      ]);

      expect(find.byType(Image), findsOneWidget);
      expect(find.byIcon(Icons.confirmation_number_outlined), findsOneWidget);
    });

    testWidgets('로고 유무와 무관하게 아이콘 박스 크기와 텍스트 시작 위치가 같다', (tester) async {
      await pump(tester, links: const [
        TicketLink(label: '예스24', url: 'https://ticket.yes24.com/Perf/1'),
        TicketLink(label: '기타', url: 'https://example.com/booking'),
      ]);

      // 로고 이미지가 담긴 박스와 폴백 아이콘이 담긴 박스가 동일 크기여야 한다
      final logoBox = tester.getSize(
        find.ancestor(of: find.byType(Image), matching: find.byType(SizedBox)).first,
      );
      final fallbackBox = tester.getSize(
        find.ancestor(
          of: find.byIcon(Icons.confirmation_number_outlined),
          matching: find.byType(SizedBox),
        ).first,
      );
      expect(logoBox, fallbackBox);
      expect(logoBox, const Size(28, 28));

      // 두 행의 라벨 텍스트가 같은 x에서 시작해야 세로로 정렬돼 보인다
      expect(
        tester.getTopLeft(find.text('예스24')).dx,
        tester.getTopLeft(find.text('기타')).dx,
      );
    });
  });

  group('TicketLinkSheet 렌더링', () {
    testWidgets('각 링크의 라벨(또는 라벨 없으면 URL)을 보여준다', (tester) async {
      await pump(tester, links: const [
        TicketLink(label: '인터파크', url: 'https://tickets.interpark.com/goods/1'),
        TicketLink(url: 'https://example.com/booking'),
      ]);

      expect(find.text('인터파크'), findsOneWidget);
      expect(find.text('https://example.com/booking'), findsOneWidget);
    });
  });
}
