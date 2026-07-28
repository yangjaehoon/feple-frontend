import 'package:feple/screen/main/tab/search/artist_page/w_song_list_skeleton.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SongListSkeleton 렌더링', () {
    testWidgets('기본값은 3개의 스켈레톤 항목을 보여준다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SongListSkeleton())),
      );

      expect(find.byType(Divider), findsNWidgets(2));
    });

    testWidgets('itemCount만큼 스켈레톤 항목을 보여준다', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: SongListSkeleton(itemCount: 1))),
      );

      expect(find.byType(Divider), findsNothing);
    });
  });
}
