#!/usr/bin/env bash
# lib/config.dart·lib/auth/keys.dart는 gitignore돼 있어 CI에서 시크릿으로 복원한다.
#
# Dependabot·포크 PR은 시크릿에 접근할 수 없어 이 값이 빈 문자열로 들어온다.
# 예전에는 빈 파일이 써져 baseUrl 상수가 사라지고 dio_client.dart 컴파일이
# 깨졌다 — 의존성과 무관하게 analyze·test가 전부 실패해 Dependabot PR이
# 구조적으로 머지 불가능했다. 그런 컨텍스트에서만($ALLOW_DUMMY) 커밋된 더미로
# 대체한다.
#
# 시크릿을 쓸 수 있는 컨텍스트에서 값이 비어 있으면 설정이 사라졌다는 뜻이므로
# 조용히 더미로 넘어가지 않고 즉시 실패시킨다 — 그러지 않으면 운영 설정 없이
# 통과한 green 빌드를 릴리스 시점에야 발견한다.
set -euo pipefail

# 공백·줄바꿈만 저장된 시크릿도 '없음'으로 취급한다. 그대로 쓰면 유효하지 않은
# Dart 파일이 만들어져, 이 스크립트가 없애려는 그 혼란스러운 지점(undefined
# name 'baseUrl')에서 실패한다.
is_blank() {
  [ -z "$(printf '%s' "${1:-}" | tr -d '[:space:]')" ]
}

restore() {
  local target="$1" value="${2:-}" fallback="$3" secret_name="$4"

  if ! is_blank "$value"; then
    printf '%s\n' "$value" > "$target"
    return
  fi

  if [ "${ALLOW_DUMMY:-}" != "true" ]; then
    echo "::error::$secret_name 시크릿이 비어 있습니다 — 시크릿을 쓸 수 있는 컨텍스트라 더미로 대체하지 않습니다 ($target)" >&2
    exit 1
  fi

  echo "$secret_name 미접근 컨텍스트 → CI 더미 사용: $target"
  cp "$fallback" "$target"
}

restore lib/config.dart "${CONFIG_DART:-}" .github/ci/config.dart.example CONFIG_DART
restore lib/auth/keys.dart "${KEYS_DART:-}" .github/ci/keys.dart.example KEYS_DART
