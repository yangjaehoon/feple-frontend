class NotificationPreferenceModel {
  final bool certEnabled;
  final bool commentEnabled;
  final bool festivalEnabled;
  final bool songRequestEnabled;

  const NotificationPreferenceModel({
    required this.certEnabled,
    required this.commentEnabled,
    required this.festivalEnabled,
    required this.songRequestEnabled,
  });

  factory NotificationPreferenceModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferenceModel(
      certEnabled: json['certEnabled'] as bool? ?? true,
      commentEnabled: json['commentEnabled'] as bool? ?? true,
      festivalEnabled: json['festivalEnabled'] as bool? ?? true,
      songRequestEnabled: json['songRequestEnabled'] as bool? ?? true,
    );
  }

  NotificationPreferenceModel copyWith({
    bool? certEnabled,
    bool? commentEnabled,
    bool? festivalEnabled,
    bool? songRequestEnabled,
  }) {
    return NotificationPreferenceModel(
      certEnabled: certEnabled ?? this.certEnabled,
      commentEnabled: commentEnabled ?? this.commentEnabled,
      festivalEnabled: festivalEnabled ?? this.festivalEnabled,
      songRequestEnabled: songRequestEnabled ?? this.songRequestEnabled,
    );
  }
}
