import 'package:feple/screen/main/tab/search/artist_page/event_type_style.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_event_type_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('EventTypeIcon', () {
    testWidgets('설정된 아이콘과 색상을 보여준다', (tester) async {
      const config = EventTypeConfig(icon: Icons.tv_rounded, color: Colors.purple);

      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: EventTypeIcon(config: config))),
      );

      final icon = tester.widget<Icon>(find.byIcon(Icons.tv_rounded));
      expect(icon.color, Colors.purple);
    });
  });
}
