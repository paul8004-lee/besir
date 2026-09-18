# SPEC-UIKIT-001 — progress.md

card: t1 · worktree `.claude/worktrees/t1` · branch `WT-ui-unify-1` (base: 로컬 master `291db49` 머지)
plan-phase 커밋: `3511672` → `8f1a366` → `fda161c` (SPEC v0.2.0, Tier M, REQ 16 / AC 8)
run-phase 세션: run lane (session e8cc923a), 2026-09-18 디스패치 (운영자 run 진입 승인 완료)

## §E.1 Plan-phase Audit-Ready Signal

plan_status: audit-ready
plan_complete_at: 2026-09-18

- 산출물 3종(spec·plan·acceptance) 커밋 완료. M1(설계)은 plan 단계에서 `ui-design` 협의로 해소:
  D-1 = 클로저 묶음, D-2 = `Shared/EditCard.swift` + `Shared/EditCardView.swift` (spec.md §4).
- D-3(카드 밖 계약 6 우회·전송 버튼 라벨의 t1 포함 여부)은 **운영자 확정: 전부 t1 밖** —
  lead 디스패치(2026-09-18) "REQ-041 예외 절 불필요". 본 SPEC 범위에서 제외, 후속 항목으로 남김.
- **게이트 미실행 고지**: fda161c 시점에 드라이버·빌드·프록시 테스트는 한 번도 돌린 적 없다
  (plan 산출물은 문서뿐). run-phase(M2 착수 전)에서 베이스라인을 최초 실측했다 — §E.2 첫 항.

## §E.2 Run-phase Evidence

### 베이스라인 (M2 착수 전, 2026-09-18)

- 커맨드: CLAUDE.md 드라이버 블록(`cat Shared/AIAssistant.swift Tools/GuardDriver.swift …`)
- 관측: `205/205 통과`, exit=0. 출력 사본 `/tmp/gd-baseline.txt`.
- 잔여 위험(사전 기록): ① D4 단언 3건의 줄순서는 실행마다 흔들린다(같은 바이너리 재실행으로
  확인 — 반복 순서 비결정성, 변경 무관). ② J절 2단언("등록이 성공하고 이동시간도 계산됐다" 등)은
  MapKit 실경로에 의존하는 환경민감 단언이다 — **변경 전 바이너리 재실행에서 203/205 실패를 한 번
  관측**(일시적, 재시도 시 초록 복귀). 라벨 본문이 "빨개지면 환경 변화 신호"로 이를 예고한다.

### M2 — 필드 모델 중립화 (REQ-001~005) ✅

구현: `swift-impl` 전문가. 검증·커밋: run lane.

- **변경**: `Shared/EditCard.swift` 신규(`BesirTime` + `EditField` + `EditCard`, `import Foundation`만),
  `Shared/AIAssistant.swift`(구조체 2정의 → `typealias AskField = EditField`/`PendingAsk = EditCard`
  + 위탁 3줄 `when`/`parseDatetime`/`isoFormatter`), `CLAUDE.md`(드라이버 cat 줄),
  `Tools/GuardDriver.swift`(머리말 실행 명령 주석 1줄).
- **Claim**: AC-001의 6조건 중 5조건 성립, 1조건(5번 grep)은 계획 단계 측정 오류로 판정 기준 시정 필요.
- **Evidence** (전부 run lane 직접 실행):
  1. `grep -n "struct AskField\|struct PendingAsk" Shared/AIAssistant.swift` → 0건(exit=1).
  2. `grep -c "import SwiftUI" Shared/EditCard.swift` → `0`.
  3. `grep -rc "yyyy-MM-dd'T'HH:mm:ss" Shared/ | grep -v ':0'` → `EditCard.swift:1` + `AIAssistant.swift:1`.
     **fda161c 베이스라인에서 AIAssistant.swift 내 2건**(옛 isoFormatter + `parseDate`:2438)이었으므로
     총수 2→2, 순수 이동. `parseDate`는 모델이 보낸 ISO를 후보 형식으로 파싱하는 실행부 관대 파서로
     카드 왕복 형식의 복제가 아니고, 손대면 REQ-041 위반이라 고치지 않았다.
     → acceptance.md AC-001 조건 5("합이 1")는 parseDate의 선행 발생분을 못 잰 계획 오류.
     manager-spec 위임으로 시정 예정(AC 문구 + HISTORY).
  4. `git status --short` → 변경 4파일 + 신규 EditCard.swift (+ `.moai/state/` 미추적, 하네스 산출물).
     `git diff Tools/GuardDriver.swift` → 주석 1줄(REQ-005: 드라이버 본문 무변경).
  5. 드라이버(새 명령, EditCard.swift 포함): `205/205 통과`, exit=0 (`/tmp/gd-m2-run.txt`).
     baseline 대조: 유일한 차이가 D4 3단언의 줄순서 — 위 베이스라인 잔여 위험 ①으로 귀명.
- **미검증(Gaps)**: 앱 빌드(iOS·macOS)는 아직 — EditCard.swift가 xcodegen 대상에 없는 시점이라
  M3 직후 게이트에서 처음 돈다. 프록시 npm test도 M5.
- 참고 측정: `when` 호출부는 spec이 "13곳"으로 적었으나 실측은 `Self.when(` **12줄/20발생**(fda161c,
  M2 후 동일·전부 무수정 — REQ-002). 문서 시정 커밋에서 AC-001 조건 3·5와 함께 HISTORY 0.2.1로 반영.

### M3 — 카드 뷰 추출 (REQ-010~013) ⬜

### M4 — 불변식 절 단위 대조 (REQ-020~022, 040~041) ⬜

### M5 — 품질 게이트 (REQ-030~031) ⬜

## §E.3 Run-phase Audit-Ready Signal

(M5 완료 후 기록)

## §E.4 Sync-phase Audit-Ready Signal

(sync 단계에서 기록)

🗿 MoAI
