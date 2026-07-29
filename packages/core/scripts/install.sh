#!/usr/bin/env bash
# ══════════════════════════════════════════════════════════════════════════════
# 저장소 이전 마이그레이션 심 (T-431, 2026-07-29)
#
# 이 저장소(shawn-kim-axz/productune)는 2026-07-20에 동결되었어요 — 코드는
# https://github.com/shawn-kim-axz/productune-code 로 이전되었습니다.
#
# 이 파일은 아직 이 저장소를 origin으로 갖고 있는 기기를 위한 1회성 심입니다.
# `prdt update`가 (pull 후) 이 스크립트를 실행하는 것이 그런 기기에 닿는 유일한
# 채널이라, 진짜 설치 로직 대신 다음을 수행합니다:
#   1. 이전 안내 출력
#   2. 새 저장소를 fetch로 검증한 뒤 origin을 productune-code로 재설정
#   3. 이 클론을 새 저장소 HEAD로 전환 (checkout -B — cmd_update가 실행 전에
#      더티 체크를 이미 통과시켰으므로 안전)
#   4. 전환된 트리의 진짜 install.sh로 exec 위임 (이 파일은 그 시점에 새
#      내용으로 대체되어 있음 — 그래서 3~4단계는 `exec bash -c` 래퍼 안에서
#      실행: 셸이 이 파일을 더 읽지 않아 자기-덮어쓰기가 안전)
#
# 이후의 `prdt update`는 평소처럼 productune-code에서 pull --ff-only 하면 됩니다.
# (PRDT_NEW_ORIGIN 환경변수는 테스트 시뮬레이션용 오버라이드입니다.)
# ══════════════════════════════════════════════════════════════════════════════
set -euo pipefail

NEW_URL="${PRDT_NEW_ORIGIN:-https://github.com/shawn-kim-axz/productune-code.git}"
ROOT="$(cd "$(dirname "$0")/../../.." && pwd)"   # <clone root> (this file: packages/core/scripts/)

echo "════════════════════════════════════════════════════════════════"
echo "  productune 저장소 이전 안내"
echo "  이 저장소(shawn-kim-axz/productune)는 2026-07-20에 동결되었어요."
echo "  코드는 productune-code 로 이전되었습니다:"
echo "    $NEW_URL"
echo "  origin을 자동으로 재설정하고 최신 코드로 전환할게요."
echo "════════════════════════════════════════════════════════════════"

# 현재 브랜치 (detached면 main으로)
BRANCH="$(git -C "$ROOT" rev-parse --abbrev-ref HEAD)"
[ "$BRANCH" = "HEAD" ] && BRANCH="main"

# 새 저장소를 먼저 URL로 직접 fetch — 실패하면(오프라인 등) origin을 건드리기
# 전에 여기서 중단되므로, 재시도 시 기존 update 경로가 그대로 살아 있어요.
if ! git -C "$ROOT" fetch --quiet "$NEW_URL" "$BRANCH" 2>/dev/null; then
  BRANCH="main"
  git -C "$ROOT" fetch --quiet "$NEW_URL" "$BRANCH"
fi

git -C "$ROOT" remote set-url origin "$NEW_URL"

# 여기서부터는 이 파일 자신이 새 내용으로 대체되므로 exec 래퍼에서 실행.
exec bash -c '
  set -euo pipefail
  ROOT="$1"; BRANCH="$2"
  git -C "$ROOT" checkout -q -B "$BRANCH" FETCH_HEAD
  git -C "$ROOT" branch --set-upstream-to="origin/$BRANCH" "$BRANCH" >/dev/null 2>&1 || true
  echo "전환 완료 → productune-code/$BRANCH ($(git -C "$ROOT" rev-parse --short HEAD))"
  exec bash "$ROOT/packages/core/scripts/install.sh" "${@:3}"
' _ "$ROOT" "$BRANCH" "$@"
