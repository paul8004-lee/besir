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

### M3 — 카드 뷰 추출 (REQ-010~013) ✅

구현: `swift-impl` 전문가. 검증·커밋: run lane.

- **변경**: `Shared/EditCardView.swift` 신규 465줄(`EditCardView` internal + `ChipFlow` internal + 이동 전체,
  `import SwiftUI`만), `Shared/EditCard.swift` +13(`EditCardActions` — 7개 `@MainActor` 클로저),
  `Shared/AIChatView.swift` 612→164줄(호출부 `EditCardView(card:busy:actions:)` 교체 + 어댑터 1곳에
  AI 결합 집중), `besir.xcodeproj/project.pbxproj`(xcodegen — 신규 파일 2종 등록).
- **Claim**: AC-002 3조건 성립. REQ-011의 주석 속 이름 2건만 의미 보존하여 걷음(파일머리·datetimeRow).
- **Evidence** (run lane 직접 실행):
  1. `grep -c "AIAssistant" Shared/EditCardView.swift` → `0`.
  2. `grep -n "^private struct" Shared/EditCardView.swift` → 0건(둘 다 internal).
  3. `grep -c "import SwiftUI" Shared/EditCard.swift` → 여전히 `0`(EditCardActions 추가 후에도).
  4. `grep -rn '\.parts = ' Shared/` → 0건(AC-006 조건).
  5. xcodegen exit=0 → iOS `BUILD SUCCEEDED`·프로젝트 코드 경고 0(로그 유일 warning은
     appintentsmetadataprocessor 툴체인 공지) / macOS 동일(`build-ios.log`·`build-mac.log`).
  6. 드라이버(M3 트리): `205/205 통과`(`/tmp/gd-m3-run.txt`).
  7. 뷰 본문 465줄 전수 대조(run lane 직접 Read) — 이동 충실, 치환만 존재.
- **미검증(Gaps)**: 재렌더(D-1 보류 추론)·제스처·낭독은 런타임 — AC-007 실기기 항목.
- **후속 기록**: 디바운스 주석 "assistant가 한다" 문구가 verbatim 보존으로 남음(REQ-041 준수) —
  중립 컴포넌트 산문으로는 AI 냄새가 남아 t3(SPEC-UIKIT-003) 이름 통일 때 함께 다듪을 후보.

### M4 — 불변식 절 단위 대조 (REQ-020~022, 040~041) ✅

렌즈: `ui-design`(AC-003) · `code-safety`(AC-004·AC-006·위해·간결성). 둘 다 READ-ONLY. 판정·기록: run lane.

- **AC-003 (디자인 4절 + 접근성 9절)**: **14절 전부 PASS** — 원본(`git show fda161c`) 대비 줄 단위 대조.
  Theme 토큰 히스토그램(11종) 건수까지 일치, `Color.clear` 2건은 원본이 쓰던 같은 자리.
  렌즈가 새로 발견한 비치환 차이 1건: `_ =` 폐기 표시가 뷰(원본 :299)에서 어댑터
  (AIChatView.swift:125)로 이동 — `EditCardActions.rechooseTimeBasis`가 Void 클로저라 필연,
  원본도 반환값을 항상 버렸으므로 의미 보존. **수용**.
- **AC-004 (동작 4절)**: **4/4 PASS** — 디바운스(AIAssistant.searchPlaces:764 실구현 무변경),
  값 수용 상수 참조(EditCard.swift:106-129, 원본과 문단 일치), 장소 줄(후보 탭 유일 확정 경로),
  칩 줄바꿈(`arrange` 단일 함수, 가로 ScrollView 0건).
- **AC-006 (범위 경계)**: **4/5 PASS + 문언 갭 1건(시정 위임)** — 네 화면 무변경(diff --stat 0줄),
  PlaceField 위반 잔존 확인(고치지 않은 것이 통과), `.parts =` 0건, 날짜 리터럴 합 2(시정 기준).
  갭: AC-001 **조건 4**의 "GuardDriver가 변경 목록에 등장하면 별칭 누락" 문언이 이제 거짓 —
  REQ-004에 따른 머리말 1줄 갱신이 합법(별칭은 AIAssistant.swift:31-32에 존재, run lane 직접
  grep 확인). AC-006 조건 3의 "4개뿐"도 예외 목록(GuardDriver 머리말·pbxproj·문서) 못 박음 필요.
  → spec-amender 시정 위임(0.2.1 3차).
- **위해 렌즈 4종**(await 인덱스·조용한 실패·외부 한도·복제 계산): **신규 0건**(CONFIRMED 기준).
- **간결성**: 정리 대상 0건. 기록된 후보(접두 비교 3곳 흩어짐[원본부터]·"assistant가 한다" 주석)는 t3 소관.
- **t2/t3 전달 사항(휴면 위해, code-safety 발견)**: `EditCardView`는 비관찰 순수 값 뷰다. 네 화면이
  이 카드를 쓸 때 **소유자가 chooseValue 등으로 @Published 상태를 바꿔 재렌더를 일으켜야 한다** —
  안 그러면 동작은 실행돼도 화면이 갱신되지 않는다. AIChatView에선 부모 관찰로 자연 성립.
  plan.md §4 후속에 계약 조건으로 기록 위임(SPEC-UIKIT-002·003 완료 조건에 명시).

### M5 — 품질 게이트 (REQ-030~031) 🟡 기계 게이트 완료, 실기기 대기

게이트(run lane 직접 실행, ux-check가 드라이버 1회 독립 재실행으로 재확인):

| 게이트 | 결과 | 근거 |
|---|---|---|
| 가드 드라이버 (AC-005, REQ-030) | ✅ **205/205 통과**, 단언 추가 0건 | fda161c 베이스라인(205/205)과 대조 — 유일 차이는 사전 기록된 D4 줄순서 흔들림. `Tools/GuardDriver.swift` diff는 머리말 1줄(REQ-004) |
| iOS 빌드 (AC-008-2) | ✅ BUILD SUCCEEDED, 프로젝트 코드 경고 0 | `build-ios.log` — 유일 warning은 appintentsmetadataprocessor 툴체인 공지 |
| macOS 빌드 (AC-008-3) | ✅ BUILD SUCCEEDED, 프로젝트 코드 경고 0 | `build-mac.log` — 동일 |
| 프록시 npm test (AC-008-4) | ✅ 7/7 통과 | 본 SPEC은 프록시 무변경 — 게이트만 확인 |
| xcodegen (AC-008-1 전단) | ✅ exit=0, 신규 파일 2종 등록 | **Team 재선택(besir-iOS·besirShare)은 사용자 조치로 대기** |

- **AC-007 (실기기) — 대기**: ux-check가 15항목 확인 목록 작성(아래). 설치 전 사용자 조치:
  ① Xcode에서 두 타깃 Team 재선택, ② iPhone(8D9B807B…) 연결·잠금 해제.
  반증 신호 지점: 칩 탭 즉시 체크 / 검색 결과 줄 적림 / "생각 중…" 중 확인 버튼 잠김(D-1 재렌더),
  "찾는 중…" 동안 에디터 유지·글자 보존(@State 정체성).
- **잔여 위험**: 드라이버 J절 2단언은 MapKit 실경로 의존(환경민감 — 변경 전 바이너리에서도 1회
  203/205 관측, 재시도 초록). 드라이버 "결정적" 서술의 예외로 기록.

#### AC-007 실기기 확인 목록 (ux-check 작성, 사용자 전달용 전문은 리드 보고·사용자 안내에 동일)

1. 값 빠진 요청 → 카드 한 장, 줄 수 = 빈 인자 수 / 2. "말씀하신 대로" 문구 동일
3. 칩 탭 → 체크+굵기 즉시[재렌더] / 4. 기준칩 미선택 시작, 무기준 확정 불가
5. 에디터 첫 바퀴 "다음 정각", 확인 전 비확정 / 6. 출발 기준 확정 → 여유 줄 흐림+캡션
7. 장소 타이핑 중 에디터 유지·글자 보존[@State] → 결과 적림[재렌더] → 후보 탭 확정
8. 0건 문구(오프라인 혼합 없음) / 9. 범위 밖 값 → 열린 채 거절 표시
10. "생각 중…" 중 확인 잠김[재렌더] / 11. 전부 채우면 "등록하기" 1회 → 실제 등록
12. 줄 많은 카드 줄바꿈·전부 도달 / 13. 최대 글자 크기 칩 무잘림
14. 다크 모드 기기 설정 추종 / 15. VoiceOver 줄 이름+사유 결합 낭독, 잠김 사유 청취

## §E.3 Run-phase Audit-Ready Signal

run_status: audit-ready(기계 게이트 전부 초록 — 실기기 AC-007만 대기)
run_complete_at: 2026-09-18

- **완료**: M2(`f9cd9bb`)·M3(`bb09e01`)·M4(절별 대조 전 PASS + 문언 갭 시정)·M5 기계 게이트.
  변경: Swift 4파일 + GuardDriver 머리말 1줄 + pbxproj + 문서(AC-006 시정 기준과 일치).
- **미결(사용자 조치 2건)**: ① Xcode Team 재선택(besir-iOS·besirShare), ② 실기기 AC-007 15항목.
  이 둘이 닫히기 전까지 카드는 done이 아니고, 브랜치 통합(릴리스 분기 머지·푸시)도 하지 않는다.
- **브랜치**: `WT-ui-unify-1` 미푸시 — 이 워크트리가 작업의 유일한 사본이므로 폐기 금지.
- **sync 위임 사항**: SPEC status는 in-progress 유지(3-phase close는 sync 단계). 별칭 제거는
  t3(SPEC-UIKIT-003) 완료 조건에 명시됨(plan.md §4).

## §E.4 Sync-phase Audit-Ready Signal

(sync 단계에서 기록)

🗿 MoAI
