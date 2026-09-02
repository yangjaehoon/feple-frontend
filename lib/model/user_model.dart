import 'json_reader.dart';

class AppUser {
  final int id;
  final String nickname;
  final String? profileImageUrl;
  final String? level;
  final String? bio;
  final DateTime? nicknameChangedAt;

  /// 서버가 아직 생년월일을 받지 못한 계정이면 true — 커뮤니티 진입 전 나이 확인 화면을 띄운다.
  final bool ageVerificationRequired;

  AppUser({
    required this.id,
    String? nickname,
    this.profileImageUrl,
    this.level,
    this.bio,
    this.nicknameChangedAt,
    this.ageVerificationRequired = false,
  }) : nickname = (nickname != null && nickname.isNotEmpty) ? nickname : 'guest';

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json.integer('id'),
      nickname: json.strOrNull('nickname'),
      profileImageUrl: json.strOrNull('profileImageUrl'),
      bio: json.strOrNull('bio'),
      level: json.strOrNull('level'),
      nicknameChangedAt: json.dateTimeOrNull('nicknameChangedAt'),
      ageVerificationRequired: json.boolean('ageVerificationRequired'),
    );
  }

  AppUser copyWith({bool? ageVerificationRequired}) => AppUser(
    id: id,
    nickname: nickname,
    profileImageUrl: profileImageUrl,
    level: level,
    bio: bio,
    nicknameChangedAt: nicknameChangedAt,
    ageVerificationRequired:
        ageVerificationRequired ?? this.ageVerificationRequired,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'nickname': nickname,
    'profileImageUrl': profileImageUrl,
    'bio': bio,
    'level': level,
    'nicknameChangedAt': nicknameChangedAt?.toIso8601String(),
    'ageVerificationRequired': ageVerificationRequired,
  };
}
