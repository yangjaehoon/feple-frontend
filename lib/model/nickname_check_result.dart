class NicknameCheckResult {
  static const int minLength = 2;
  static const int maxLength = 8;

  static bool isValidLength(String nickname) =>
      nickname.length >= minLength && nickname.length <= maxLength;

  final bool available;
  final String code;

  const NicknameCheckResult({required this.available, required this.code});

  factory NicknameCheckResult.fromJson(Map<String, dynamic> json) {
    return NicknameCheckResult(
      available: json['available'] as bool,
      code: json['code'] as String? ?? 'INVALID',
    );
  }
}
