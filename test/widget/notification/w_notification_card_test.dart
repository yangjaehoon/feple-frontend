import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/model/notification_model.dart';
import 'package:feple/model/notification_type.dart';
import 'package:feple/screen/notification/w_notification_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

NotificationModel _item({
  int id = 1,
  bool read = false,
  String title = '알림 제목',
  String body = '알림 본문',
  NotificationType? type,
  String? imageUrl,
}) {
  return NotificationModel(
    id: id,
    type: type ?? NotificationType.newComment,
    title: title,
    body: body,
    read: read,
    imageUrl: imageUrl,
    createdAt: DateTime.now().toIso8601String(),
  );
}

Future<void> _pump(
  WidgetTester tester, {
  required NotificationModel item,
  VoidCallback? onTap,
  bool isLoading = false,
}) async {
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
          home: Scaffold(
            body: NotificationCard(
              item: item,
              onTap: onTap ?? () {},
              isLoading: isLoading,
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('NotificationCard 렌더링', () {
    testWidgets('제목과 본문을 보여준다', (tester) async {
      await _pump(tester, item: _item(title: '새 댓글', body: '댓글이 달렸어요'));

      expect(find.text('새 댓글'), findsOneWidget);
      expect(find.text('댓글이 달렸어요'), findsOneWidget);
    });

    testWidgets('안 읽은 알림이면 읽지 않음 표시가 보인다', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, item: _item(read: false));

      // TapScale의 Semantics가 버튼이라 하위 Text들의 라벨과 합쳐지므로
      // 정확한 문자열이 아닌 포함 여부로 검사
      expect(
        find.bySemanticsLabel(RegExp('unread_notification')),
        findsOneWidget,
      );
      handle.dispose();
    });

    testWidgets('읽은 알림이면 읽지 않음 표시가 없다', (tester) async {
      final handle = tester.ensureSemantics();
      await _pump(tester, item: _item(read: true));

      expect(
        find.bySemanticsLabel(RegExp('unread_notification')),
        findsNothing,
      );
      handle.dispose();
    });

    testWidgets('로딩 중이면 스피너를 보여준다', (tester) async {
      await _pump(tester, item: _item(), isLoading: true);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });

  group('NotificationCard 탭', () {
    testWidgets('탭하면 onTap이 호출된다', (tester) async {
      var tapped = false;
      await _pump(tester, item: _item(), onTap: () => tapped = true);

      await tester.tap(find.byType(NotificationCard));
      await tester.pump();

      expect(tapped, true);
    });

    testWidgets('로딩 중에는 탭해도 onTap이 호출되지 않는다', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        item: _item(),
        onTap: () => tapped = true,
        isLoading: true,
      );

      await tester.tap(find.byType(NotificationCard), warnIfMissed: false);
      await tester.pump();

      expect(tapped, false);
    });
  });
}
