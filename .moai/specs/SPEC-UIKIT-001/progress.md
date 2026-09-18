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

- **AC-007 — ✅ 14항목 중 13 통과, 1건 이월 (2026-09-18 사용자 확인, lead 접수)**.
  **정정 기록(문언과 실측의 차이)**: AC-007/REQ-031(d)는 "실기기"를 요구하지만, 실제 확인은
  **iPhone 17 Pro 시뮬레이터**에서 수행됐다(2026-09-18 사용자 결정 — 이후 검증도 시뮬레이터 방식
  고정). Debug-iphonesimulator 빌드를 simctl install/launch 하고 사용자가 입력 문구·기대 결과
  스크립트로 직접 확인했다. 실기기 확인은 Day 닫기 이월 목록(⑪ 기기 전용 항목들)에 합류.
  통과: 카드 즉시 뜸·줄 수=빈 인자 수, "말씀하신 대로" 문구, **칩 탭 즉시 체크(재렌더 반증 1 — D-1
  추론 확증)**, 기준칩 미선택 시작·무기준 확정 불가, 에디터 "다음 정각", 출발 기준 여유 흐림+캡션,
  **타이핑 중 글자 보존·에디터 유지(@State 반증 — 확증)**, **검색 결과 적림(재렌더 반증 2)**, 0건 문구,
  범위 밖 거절(열린 채), **"생각 중…" 중 잠김(재렌더 반증 3)**, 등록 1회·실제 등록, 칩 줄바꿈·전부 도달,
  큰 글씨 무잘림, 다크 모드 추종.
  **이월(새 부채 아님)**: 항목 15 VoiceOver 낭독 — 사용자가 현재 확인 불가, Phase 1.6 이월 목록
  15번과 같은 항목이므로 Day 닫기 목록으로 이월.
  배포 경위(참고, 기기 쪽): 사용자 Team 재선택에도 `No Account for Team DFEME8ZQT9`(project.yml iOS
  타깃의 유령 팀 — 계정이 내린 새 프로파일은 전부 Y54D2W4F4T, 만료 9/25). **레포 무변경**
  `DEVELOPMENT_TEAM=Y54D2W4F4T` 오버라이드로 BUILD SUCCEEDED → 기기 설치 성공, 실행은 개인 팀
  프로파일의 기기 신뢰 단계에서 대기 중이었으나 위 시뮬레이터 방식 확정으로 기기 쪽은 이월 목록에
  합류. **후속(사용자 결정, 카드 범위 밖)**: iOS 타깃 팀 정규화(개인 팀 지속=7일마다 재설치 vs
  유료 멤버십 복원) — t2·t3 검증 방식에 영향.
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

run_status: audit-ready — **run 단계 종료(전 마일스톤 확정)**
run_complete_at: 2026-09-18

- **완료**: M2(`f9cd9bb`)·M3(`bb09e01`)·M4(절별 대조 전 PASS + 문언 갭 시정)·M5(기계 게이트 전부
  초록 + AC-007 시뮬레이터 13/14 통과 — 재렌더(D-1)·@State 반증 신호 전부 확증으로 통과).
  변경: Swift 4파일 + GuardDriver 머리말 1줄 + pbxproj + 문서(AC-006 시정 기준과 일치).
- **이월(Day 닫기 목록으로, 새 부채 아님)**: ⑮ VoiceOver 낭독(Phase 1.6 15번과 동일) · ⑪ 실기기
  전용 항목 일체(2026-09-18 사용자 결정: 검증은 시뮬레이터 방식 고정).
- **사용자 결정 대기(카드 밖)**: iOS 타깃 서명 팀 정규화(project.yml DFEME8ZQT9 유령화).
- **브랜치**: `WT-ui-unify-1` 미푸시 — 이 워크트리가 작업의 유일한 사본이므로 폐기 금지.
  릴리스 통합·푸시는 sync 단계와 함께 lead 지시에 따라 진행.
- **sync 위임 사항**: SPEC status는 in-progress 유지(3-phase close는 sync 단계). 별칭 제거는
  t3(SPEC-UIKIT-003) 완료 조건에 명시됨(plan.md §4).

## §E.4 Sync-phase Audit-Ready Signal

sync_status: audit-ready — **sync 단계 종료(3-phase close)**
sync_complete_at: 2026-09-18
sync_commit_sha: c156c4deff90c0fbb41614ebd5b4d85327dfdfec
실행: sync lane (session 53e1309e), lead 디스패치 2026-09-18 · lens `--security --deep`

### Claim

| # | 주장 | 판정 |
|---|---|---|
| S1 | 기계 게이트 4종이 HEAD 소스에서 전부 초록이다 | 성립(sync lane 직접 실행) |
| S2 | run 레인이 §E.2에 적은 grep 증거가 현재 트리에서 그대로 재현된다 | 성립 |
| S3 | "순수 추출"이라는 주장은 독립 렌즈의 반증 시도를 견딘다 | 성립(BLOCKER 0건) |
| S4 | 이 카드가 루트 `CHECKLIST.md`의 코드 근거 179건을 어긋나게 했다 | 성립 — **이 커밋에서 수리** |
| S5 | 커밋된 하네스 상태 파일 2건은 버전 관리 대상이 아니다 | 성립 — **이 커밋에서 제거** |
| S6 | 추출 과정에서 원본보다 넓어진 접근 범위·뜻이 바뀐 주석이 각 1건 있다 | 성립 — **이 커밋에서 원복** |
| S7 | AC 8건 중 7건 통과, AC-007만 13/14(시뮬레이터) | 성립 |

### Evidence

**S1 — 기계 게이트(전부 sync lane이 이 트리에서 직접 실행).** m1·i1 수정 뒤 재실행한 값이다.

| 게이트 | 명령 | 관측 |
|---|---|---|
| 프록시 (AC-008-4) | `cd proxy && npm test` | `7/7 통과`, exit=0 — `hns-besir-app-verify` 기준선 7과 일치 |
| 가드 드라이버 (AC-005) | CLAUDE.md 드라이버 블록(`cat Shared/EditCard.swift …`) | **`205/205 통과`**, `✗` 0건, exit=0. 마지막 단언 `불변식: 전체 실행 뒤에도 autoAddToCalendar는 꺼져 있다` 초록 |
| iOS 빌드 (AC-008-2) | `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build` | `** BUILD SUCCEEDED **`, exit=0. `warning:` 2건은 전부 `appintentsmetadataprocessor` 툴체인 공지 — `Shared/`·`ShareExtension/` 소스 경고 **0건** |
| macOS 빌드 (AC-008-3) | `xcodebuild -scheme besir-macOS -derivedDataPath build build` | `** BUILD SUCCEEDED **`, exit=0, `warning:` **0건** |

**게이트를 다시 돌린 이유(귀속 시정).** 워크트리에 있던 `build-ios.log`(10:04:42)·`build-mac.log`(10:04:50)는
마지막 소스 커밋 `bb09e01`(10:09:41)보다 **앞서 찍혀 HEAD에 귀속할 수 없었다**. §E.2·§E.3의 빌드 판정은
그 로그를 근거로 삼았으므로 근거가 비어 있었다. 위 표는 HEAD 소스에서 다시 잰 값이다 — 결론은 같지만
출처가 다르다.

**S2 — run 레인 grep 증거 재현(sync lane 직접 실행).**

- `grep -cE 'struct AskField|struct PendingAsk' Shared/AIAssistant.swift` → `0`
- `grep -E '^import' Shared/EditCard.swift` → `import Foundation` 한 줄
- `grep -nE 'typealias (AskField|PendingAsk)' Shared/AIAssistant.swift` → `:31`·`:32`
- `grep -c AIAssistant Shared/EditCardView.swift` → `0` / `grep -c '^private struct' …` → `0`
- `grep -rn "yyyy-MM-dd'T'HH:mm:ss" Shared/` → `AIAssistant.swift:2438`(`parseDate`, 무수정) + `EditCard.swift:29` = **2줄**. base도 2줄(둘 다 `AIAssistant.swift`) — 총수 2→2의 순수 이동, HISTORY 0.2.1의 시정 기준과 일치
- `git diff <merge-base> HEAD -- Shared/AddEventView.swift Shared/EventDetailView.swift Shared/AddActivityView.swift Shared/ActivityDetailView.swift` → 출력 없음(네 화면 무변경)
- `grep -rn '\.parts = ' Shared/` → 0건
- `git diff <merge-base> HEAD -- Tools/GuardDriver.swift` → 머리말 `cat` 명령 1줄뿐(REQ-005 — 드라이버 본문 무변경)

**S3 — 독립 렌즈(`code-safety`, READ-ONLY, sync lane 위임).** 원본 `AskCardView`+`ChipFlow`
(`fda161c:Shared/AIChatView.swift:154-612`)에 선언된 치환 8개를 적용한 뒤 `Shared/EditCardView.swift:3-465`와
diff → 차이 **22줄**, 전부 문서 주석 재작성·프로퍼티 선언 교체·재들여쓰기로 설명됨. **값↔참조 전환·캡처
변경·기본인자 추가·옵셔널 변화·액터 격리 변화·프로퍼티 래퍼 변화·부수효과 순서 변화는 0건.** 결합 9곳
(`:181`·`:238`·`:299`·`:344`·`:444`·`:495`·`:523`·`:534`·`:537`)을 새 경로에 하나씩 대응시켜 관측 가능한
효과가 같음을 확인했다. 위해 4종(await 인덱스·조용한 실패·외부 한도·중복 계산) 신규 **0건** —
중복 계산은 오히려 1건 해소(포매터·파서가 `BesirTime` 한 집으로). 보안 렌즈(계약 2 비밀값·PII, 주입,
컴포넌트 경계 권한) **0건**: 두 새 파일은 `import Foundation` / `import SwiftUI`만 하고 Store·캘린더·
알림·네트워크로 가는 자체 경로가 없다.

**S4 — `CHECKLIST.md` 코드 근거 수리(179건).** 이 카드가 `AIAssistant.swift`에서 117줄을 들어내고
`AIChatView.swift`를 612→164줄로 줄이면서 인용이 일괄로 밀렸다. base에서는 전부 정확했다 —
심볼 9개(`askFields` 559 · `searchPlaces` 859 · `recurringArgumentIssue` 1845 …)가 인용값과 완전 일치.

- 재매핑: `git diff -U0` 훅에서 옛→새 줄 사상을 만들고, 심볼 9개로 교차검증(**9/9 일치**).
- 적용: `AIAssistant.swift` 인용 **168건**(−95가 141건, −117이 27건) + AI 카드 뷰를 가리키던 **11건**을
  `Shared/EditCardView.swift`로(시작줄은 심볼 유일매치, 끝줄은 중괄호 짝으로 확정).
- **전수 검증**: 재매핑한 168건 전부에 대해 `base:AIAssistant.swift[옛 줄] == HEAD:AIAssistant.swift[새 줄]`
  바이트 비교 → **불일치 0건**.
- **보호 30건**: `Store.swift`·`GoogleCalendarService.swift`·`Models.swift`·`App.swift`·`ContentView.swift`·
  `EventDetailView.swift`·`GuardDriver.swift`를 가리키던 인용은 base 본문으로 하나씩 확인해 손대지 않았다.
  1차 자동 분류가 이 중 **9건을 `AIAssistant.swift`로 오귀속**했고(L54 `:639`, L218 2건, L220 6건 — 전부
  `Store.swift`), 감사 단계에서 잡아냈다. `:1248-1621`(`GuardDriver.swift`, 1622줄)도 같은 경로로 걸렀다.
- 판정(✅/⚠️/❌)은 한 칸도 바꾸지 않았다 — 바뀐 것은 근거가 사는 자리뿐이다. 머리말에 기준선 기록을 남겼다.

**S5 — 하네스 상태 파일 제거.** `.moai/specs/SPEC-UIKIT-001/.moai/state/context-usage.json`은
`session_id`·`writer_pid`·`captured_at`을 담은 기기 로컬 세션 상태이고, `config-cache.json`은 설정 전체
덤프다(키 **값**은 없어 계약 2 위반은 아니나 `ConversationLanguage:"en"`으로 실제 설정 `ko`와 모순되는
낡은 캐시다). `master`에 선례가 없고 `.gitignore`에도 규칙이 없었다 → `git rm --cached` 2건 +
`.gitignore`에 `.moai/state/`·`**/.moai/state/` 추가.

**S6 — 원본으로 되돌린 2건.**

- `Shared/EditCard.swift:14` — `BesirTime.whenFormatter`가 원본의 `private static`에서 `internal`로
  넓어져 있었다. 호출부는 같은 파일 `:20` **하나뿐**(전수 grep)이라 `private` 한 단어로 복구했고 호출부
  변경은 0줄이다. `DateFormatter`는 참조형이라, 열어두면 어느 화면에서든 `dateFormat`을 바꿔 앱 전체
  시각 문구를 조용히 틀 수 있다.
- `Shared/EditCard.swift:47` — 주석이 원본(`fda161c:Shared/AIAssistant.swift:30`)의 `되묻는 **주체**가`에서
  `되묻는 **주제**가`로 바뀌어 뜻이 달라져 있었다(묻는 주체 → 묻는 주제). REQ-011의 의미 보존에 맞춰 원복.
- 두 수정 뒤 드라이버·양쪽 빌드를 다시 돌렸다(위 S1 표가 그 값이다).

**S7 — AC 판정.** `acceptance.md` 매트릭스를 이 증거로 닫았다: AC-001·002·003·004·005·006·008 = ✅,
AC-007 = ⚠️ 13/14(시뮬레이터, ⑮ VoiceOver 이월).

### Baseline-attribution

- 트리: `.claude/worktrees/t1`, 브랜치 `WT-ui-unify-1`, sync 직전 HEAD `f6a3d34`.
- 비교 기준선: `git merge-base master HEAD` = `291db49`. 소스 기준 `291db49`와 `fda161c`가 동일함을 확인
  (`git diff --stat 291db49 fda161c -- Shared/ Tools/` 출력 없음) — SPEC이 인용하는 `fda161c`를 원본으로 썼다.
- S1의 네 값은 m1·i1 수정을 **포함한** 트리에서 이번 회차에 실행한 것이다. 수정 전 트리에서도 같은 네
  게이트를 돌려 동일한 값을 관측했다(드라이버 205/205, 양쪽 BUILD SUCCEEDED, 프록시 7/7).
- S3은 `code-safety`가 같은 트리 `f6a3d34`에서 READ-ONLY로 수행했고 빌드·테스트는 돌리지 않았다.

### Gaps (미검증)

1. **앱을 실행하지 않았다.** sync 단계의 동일성 판정은 전부 정적 독해와 기계 게이트다. 특히 `@ObservedObject`
   제거가 갱신 경로를 끊지 않는다는 판정은 `@Published` 선언과 쓰기 경로에서 **추론**한 것이다.
   AC-007의 시뮬레이터 13/14가 이 자리를 메우지만, 그것은 sync lane이 재측정하지 않은 run 단계의 관측이다.
2. **AC-003의 14절을 절 단위로 다시 대조하지는 않았다.** 대신 뷰 본문 전체의 정규화 diff(22줄 전수 설명)로
   갈음했다 — 더 넓은 증거지만 절 목록과 1:1로 맞춘 형태는 아니다.
3. **실기기 빌드는 돌리지 않았다.** 워크트리의 `build-device.log:924`에 툴체인 공지가 아닌 경고가 1건 있다
   (`All interface orientations must be supported unless the app requires full screen`). 시뮬레이터·macOS
   빌드에는 뜨지 않았고(`grep -c "interface orientations"` → 0/0), `Info-iOS.plist`·`project.yml`은 이 카드가
   건드리지 않았으므로 기존 것으로 보이나 **master 기준으로 확인하지 않았다**.
4. **`CHECKLIST.md`의 판정 자체는 재검증하지 않았다.** 이번 작업은 코드 근거의 **주소**만 고쳤다.
   각 행의 ✅/⚠️/❌가 여전히 옳은지는 별개 문제이고, 이 카드는 동작을 바꾸지 않았으므로 바뀔 이유는 없다.
5. **프록시 변환층 렌즈는 해당 없음.** 이번 diff에 `proxy/`가 없어 게이트만 돌렸다 — 0건이 아니라 무관이다.
6. **`project.pbxproj` 재생성 부산물의 무해함을 확인하지 않았다.** 빌드는 성공하므로, 영향이 있다면
   Xcode Run/Archive나 `devicectl install`의 경로 유도다(아래 m6).

### Residual-risk (잔여 위험)

- **드라이버 J절 2단언은 MapKit 실경로에 의존한다**(환경민감 — 변경 전 바이너리에서도 1회 203/205를
  관측하고 재시도에 초록으로 돌아온 이력). 드라이버 "결정적" 서술의 예외로 §E.2에 이미 기록돼 있다.
- **재렌더 논거는 계약이 아니라 SwiftUI 디핑의 성질에 기댄다.** `EditCardActions`가 클로저를 담아 SwiftUI가
  "변하지 않음"을 증명할 수 없으므로 부모 본문이 돌 때마다 자식도 돈다. 훗날 `EditCardActions`를
  `Equatable`로 만들거나 카드에 `.equatable()`을 붙이면 `busy`가 낡아 "생각 중…" 동안 확인 버튼이 잠기지
  않게 된다 — t2·t3가 이 컴포넌트를 쓸 때의 함정이다.
- **범위 가드는 컴포넌트가 아니라 소유자에 있다.** 여유 ≤ `Store.maxBufferMinutes`, 주 ≤
  `Store.maxRecurrenceWeeks`, 알림 ≤ 1440분 세 가드는 `AIAssistant.submitCustom` → `EditField.accepts`
  경로에 산다. t2·t3 어댑터가 `submitCustom: { _,_ in true }`로 주면 세 가드가 조용히 사라진다.
- **`BesirTime.isoFormatter`는 아직 internal이고 참조형이다**(m2). 왕복 형식의 단일 출처가 모듈 전역에서
  쓰기 가능하다 — 증상이 크래시가 아니라 "시각이 거절되거나 엉뚱하게 읽힌다"라 늦게 발견된다.
- **가드 드라이버는 사용자 실데이터를 `defer` 없이 바꿔 쓴다**(p1, 기존). 논리적 조기 이탈은 없지만
  (1126–1611 구간에 `return`·`exit(`·`fatalError`·`try!`가 없고 `drvCheck`는 카운터만 올린다) 런타임 트랩·
  Ctrl-C·강제 종료가 백업과 복원 사이에 끼면 사용자의 진짜 `events.json`·`activities.json`이 드라이버
  픽스처로 남는다.
- **시뮬레이터 13/14는 sync lane이 재측정하지 않은 주장이다.** 이 프로젝트에는 88/88 초록 다음 날 실기기
  결함 7건이 나온 기록이 있다.

### 이월 — §E.3에서 그대로 살린다(새 부채 아님)

- **⑮ VoiceOver 낭독** — 사용자가 현재 확인 불가. Phase 1.6 이월 목록 15번과 같은 항목이므로 Day 닫기
  목록으로 이월.
- **⑪ 실기기 전용 항목 일체** — 2026-09-18 사용자 결정으로 검증은 시뮬레이터 방식 고정.
- **사용자 결정 대기(카드 밖): iOS 타깃 서명 팀 정규화.** `project.yml`의 `DFEME8ZQT9`가 유령화됐다.
  sync 단계에서 새로 확인한 근거: 성공한 실기기 빌드는 커밋된 값을 명령줄로 **뒤집어야** 했고
  (`build-device.log:2` — `DEVELOPMENT_TEAM=Y54D2W4F4T`), 재생성된 `project.pbxproj`가 그 표류를 커밋된
  파일로 실체화했다(`:448`·`:465`·`:484`·`:632`가 `DFEME8ZQT9`, `:430`·`:651`의 macOS는 `Y54D2W4F4T`).
  **앞으로 문서대로 `xcodebuild … -allowProvisioningUpdates`만 치는 사람은 틀린 팀으로 간다.**
  팀 선택은 사용자 결정 사항(개인 팀 지속 = 7일마다 재설치 vs 유료 멤버십 복원)이라 이 카드에서 고치지
  않았다. 정하면 단일 출처인 `project.yml`에 넣고 실기기 절차의 오버라이드를 `CLAUDE.md`에 적어야 한다.

### 후속으로 넘긴 것

| # | 내용 | 행선지 |
|---|---|---|
| m2 | `BesirTime.isoFormatter`를 private로 + `isoString(_:)` 래퍼, 호출부 3곳 이동(약 6줄) | t2·t3 |
| m3 | `EditCard.parts`/`stated`가 가변이 되어 `parts == []`인 카드를 만들 수 있다 — `bubbles`에 섞이면 빈 모델 턴이 디스크에 남는다. t1에서는 닿지 않는다 | t2 완료 조건 |
| m4 | 접두(`arr:`/`dep:`)↔`ScheduleAnchor` 대응 7곳이 아직 집이 없다(개수 불변, 파일만 2→3) — `BesirTime.anchor(of:)`/`prefix(for:)` | t2 |
| m6 | 재생성된 `project.pbxproj`의 카드 범위 밖 변경(제품 참조 이름 ↔ `PRODUCT_NAME = besir` 불일치, `explicitFileType`↔`lastKnownFileType` 뒤바뀜 3건). 빌드는 성공하므로 지금 깨진 것은 없다 | 서명 팀 정규화와 함께 |
| p1 | `Tools/GuardDriver.swift`의 백업·복원 7쌍을 `defer`로(기계적) | 별건 |
| — | 순수 값 뷰 재렌더 계약 — 소유자 화면이 `@Published` 상태를 바꿔야 화면이 갱신된다 | plan.md §4에 기록됨(t2·t3 완료 조건) |

### 게이트 판정

**PASS (조건 해소됨).** 독립 렌즈의 병합 전 조건 둘 중 하나(하네스 상태 파일 제거)는 이 커밋에서 해소했고,
다른 하나(iOS 팀 ID)는 **사용자 결정이 필요한 카드 밖 항목**이라 위 이월 목록에 근거를 보강해 남겼다 —
앱 동작이 아니라 빌드·배포 경로에 한정되고, 이 카드가 만든 문제도 아니다. BLOCKER 0건, 기계 게이트 4종
초록, 위해 4종 신규 0건, AC 7/8 통과 + 1건 부분 통과.

**브랜치 `WT-ui-unify-1`은 여전히 미푸시이며 이 워크트리가 작업의 유일한 사본이다 — 폐기 금지.**
master 통합·push는 lead 소관.

🗿 MoAI
