import 'json_reader.dart';

// 자주 쓰이는 예매처는 URL 도메인으로 식별해 브랜드 로고를 보여준다 —
// 인터파크 티켓은 2026년 NOL 티켓으로 브랜드명이 바뀌었지만 도메인은
// interpark.com 계열 그대로라 로고만 NOL로 매칭한다.
enum TicketVendor {
  nol('assets/image/ticket_vendors/nol.png', ['interpark.com']),
  yes24('assets/image/ticket_vendors/yes24.png', ['yes24.com']),
  melon('assets/image/ticket_vendors/melon.png', ['melon.com']),
  ticketlink('assets/image/ticket_vendors/ticketlink.png', ['ticketlink.co.kr']);

  const TicketVendor(this.logoAsset, this.domains);

  final String logoAsset;
  final List<String> domains;

  static TicketVendor? fromUrl(String url) {
    final host = Uri.tryParse(url)?.host.toLowerCase();
    if (host == null || host.isEmpty) return null;
    for (final vendor in TicketVendor.values) {
      // host.contains(domain)는 'yes24.com.evil.net' 같은 호스트도 매칭시킬 수
      // 있으므로, 정확히 그 도메인이거나 그 서브도메인일 때만 매칭한다.
      if (vendor.domains.any((domain) => host == domain || host.endsWith('.$domain'))) {
        return vendor;
      }
    }
    return null;
  }
}

class TicketLink {
  final String? label;
  final String url;

  const TicketLink({this.label, required this.url});

  String? get vendorLogoAsset => TicketVendor.fromUrl(url)?.logoAsset;

  factory TicketLink.fromJson(Map<String, dynamic> json) {
    return TicketLink(
      label: json.strOrNull('label'),
      url: json.str('url'),
    );
  }
}
