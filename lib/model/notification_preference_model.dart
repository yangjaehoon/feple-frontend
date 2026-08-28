import 'json_reader.dart';

class NotificationPreferenceModel {
  final bool certEnabled;
  final bool commentEnabled;
  final bool festivalEnabled;
  final bool songRequestEnabled;
  final bool quietHoursEnabled;

  const NotificationPreferenceModel({
    required this.certEnabled,
    required this.commentEnabled,
    required this.festivalEnabled,
    required this.songRequestEnabled,
    required this.quietHoursEnabled,
  });

  factory NotificationPreferenceModel.fromJson(Map<String, dynamic> json) {
    return NotificationPreferenceModel(
      certEnabled: json.boolean('certEnabled', true),
      commentEnabled: json.boolean('commentEnabled', true),
      festivalEnabled: json.boolean('festivalEnabled', true),
      songRequestEnabled: json.boolean('songRequestEnabled', true),
      quietHoursEnabled: json.boolean('quietHoursEnabled'),
    );
  }

  NotificationPreferenceModel copyWith({
    bool? certEnabled,
    bool? commentEnabled,
    bool? festivalEnabled,
    bool? songRequestEnabled,
    bool? quietHoursEnabled,
  }) {
    return NotificationPreferenceModel(
      certEnabled: certEnabled ?? this.certEnabled,
      commentEnabled: commentEnabled ?? this.commentEnabled,
      festivalEnabled: festivalEnabled ?? this.festivalEnabled,
      songRequestEnabled: songRequestEnabled ?? this.songRequestEnabled,
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
    );
  }

  NotificationPreferenceModel toggleCert() => copyWith(certEnabled: !certEnabled);
  NotificationPreferenceModel toggleComment() => copyWith(commentEnabled: !commentEnabled);
  NotificationPreferenceModel toggleFestival() => copyWith(festivalEnabled: !festivalEnabled);
  NotificationPreferenceModel toggleSongRequest() => copyWith(songRequestEnabled: !songRequestEnabled);
  NotificationPreferenceModel toggleQuietHours() => copyWith(quietHoursEnabled: !quietHoursEnabled);
}
