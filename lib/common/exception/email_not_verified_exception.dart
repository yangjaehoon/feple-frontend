class EmailNotVerifiedException implements Exception {
  /// 인증 메일이 실제로 발송됐는지. 발송이 실패해도(예: 재시도 과다) 이 예외로
  /// 흐름을 이어가 인증 화면을 띄우고, 화면이 재발송을 안내한다 — 발송 실패를
  /// 그대로 올리면 인증 화면에 못 들어가 인증을 마칠 방법이 사라진다.
  const EmailNotVerifiedException({this.verificationEmailSent = true});

  final bool verificationEmailSent;

  @override
  String toString() =>
      'EmailNotVerifiedException(verificationEmailSent: $verificationEmailSent)';
}
