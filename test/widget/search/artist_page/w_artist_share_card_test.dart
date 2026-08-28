import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/widget/w_share_card_parts.dart';
import 'package:feple/screen/main/tab/search/artist_page/w_artist_share_card.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../common/common_widget_test_harness.dart';

void main() {
  testWidgets('아티스트 이름과 FEPLE 배지를 보여준다', (tester) async {
    await pumpCommonWidget(
      tester,
      const ArtistShareCard(artistName: '아이유', imageUrl: '', followerCount: 0),
    );

    expect(find.text('아이유'), findsOneWidget);
    expect(find.text('FEPLE'), findsOneWidget);
    expect(find.byType(FepleBrandBadge), findsOneWidget);
  });

  testWidgets('팔로워 수가 0보다 크면 축약 표기로 팔로워 줄을 보여준다', (tester) async {
    await pumpCommonWidget(
      tester,
      const ArtistShareCard(artistName: '아이유', imageUrl: '', followerCount: 12345),
    );

    // ko 로케일: 12345 -> "1.2만"
    expect(find.text('follower_count'.tr(args: ['1.2만'])), findsOneWidget);
    expect(find.byType(ShareCardInfoRow), findsOneWidget);
  });

  testWidgets('팔로워 수가 0이면 팔로워 줄을 숨긴다', (tester) async {
    await pumpCommonWidget(
      tester,
      const ArtistShareCard(artistName: '아이유', imageUrl: '', followerCount: 0),
    );

    expect(find.byType(ShareCardInfoRow), findsNothing);
  });
}
