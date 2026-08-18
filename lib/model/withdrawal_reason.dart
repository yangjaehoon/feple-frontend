enum WithdrawalReason { rarelyUsed, notEnoughContent, bugsOrErrors, privacyConcern, other }

// 백엔드 WithdrawalReason enum 상수명과 매핑 — SCREAMING_SNAKE_CASE라
// name.toUpperCase()로는 안 되고(예: notEnoughContent → NOTENOUGHCONTENT,
// 백엔드는 NOT_ENOUGH_CONTENT) 값마다 명시적으로 매핑해야 한다.
extension WithdrawalReasonApi on WithdrawalReason {
  String get apiValue => switch (this) {
    WithdrawalReason.rarelyUsed => 'RARELY_USED',
    WithdrawalReason.notEnoughContent => 'NOT_ENOUGH_CONTENT',
    WithdrawalReason.bugsOrErrors => 'BUGS_OR_ERRORS',
    WithdrawalReason.privacyConcern => 'PRIVACY_CONCERN',
    WithdrawalReason.other => 'OTHER',
  };
}
