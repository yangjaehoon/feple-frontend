import 'package:feple/model/ticket_link.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TicketVendor.fromUrl', () {
    test('interpark.com 계열 도메인은 NOL 로고로 매칭', () {
      expect(TicketVendor.fromUrl('https://tickets.interpark.com/contents/1'), TicketVendor.nol);
      expect(TicketVendor.fromUrl('https://ticket.interpark.com/goods/1'), TicketVendor.nol);
      expect(TicketVendor.fromUrl('https://nol.interpark.com/1'), TicketVendor.nol);
    });

    test('yes24 티켓 도메인 매칭', () {
      expect(TicketVendor.fromUrl('https://ticket.yes24.com/Perf/1'), TicketVendor.yes24);
    });

    test('멜론티켓 도메인 매칭', () {
      expect(TicketVendor.fromUrl('https://ticket.melon.com/performance/index.htm?prodId=1'),
          TicketVendor.melon);
    });

    test('티켓링크 도메인 매칭', () {
      expect(TicketVendor.fromUrl('https://www.ticketlink.co.kr/product/1'), TicketVendor.ticketlink);
      expect(TicketVendor.fromUrl('https://ticketlink.co.kr/product/1'), TicketVendor.ticketlink);
    });

    test('알려지지 않은 예매처는 null', () {
      expect(TicketVendor.fromUrl('https://example.com/booking'), isNull);
    });

    test('파싱 불가능한 URL은 null', () {
      expect(TicketVendor.fromUrl('not a url'), isNull);
    });
  });

  group('TicketLink.vendorLogoAsset', () {
    test('알려진 예매처면 로고 에셋 경로 반환', () {
      final link = TicketLink(label: '인터파크', url: 'https://tickets.interpark.com/goods/1');

      expect(link.vendorLogoAsset, 'assets/image/ticket_vendors/nol.png');
    });

    test('알려지지 않은 예매처면 null 반환 (일반 아이콘으로 폴백)', () {
      final link = TicketLink(label: '기타', url: 'https://example.com/booking');

      expect(link.vendorLogoAsset, isNull);
    });
  });
}
