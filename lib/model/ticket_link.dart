class TicketLink {
  final String? label;
  final String url;

  const TicketLink({this.label, required this.url});

  factory TicketLink.fromJson(Map<String, dynamic> json) {
    return TicketLink(
      label: json['label'] as String?,
      url: json['url'] as String,
    );
  }
}
