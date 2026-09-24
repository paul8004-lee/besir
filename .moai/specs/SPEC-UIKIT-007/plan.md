# SPEC-UIKIT-007 — plan.md

> 이 문서는 **구현을 앞둔 계획**이다(as-built 아님). 원본은 칸반 카드 t7 본문(`moai todo`)과 루트
> `plan.md:539`(후속 17)이다. 줄번호는 전부 `73ceb43`에서 실측했고, 세는 명령을 수치 옆에 적었다.

## 0. Tier 판단

**Tier: S** (운영자 확정, 2026-09-23 — §2 항목 3)

| 파일 | 변경 | 줄 | 세는 명령 |
|---|---|---|---|
| `Shared/AddEventView.swift` | 출발지 줄에 `chosen: editing?.origin?.name` (REQ-001) | 교체 1 | `awk 'NR==166' Shared/AddEventView.swift` |
| `Shared/AddEventView.swift` | `confirmedPlace(_:)` 위 주석 재서술 (REQ-006) | 교체 ≤ 6 | `awk 'NR>=531 && NR<=536' Shared/AddEventView.swift \| wc -l` = 6 |

- 소스 파일 1개, 코드 1줄, 주석 6줄 이내다. 파일 길이는 `wc -l Shared/AddEventView.swift` = **645**이고, 권고안은
  이 값을 바꾸지 않는다(REQ-007). Tier S 기준(< 300 LOC, < 5 files, `spec-workflow.md:140`) 안이다.
- **REQ 8건 · AC 8건** — `grep -c '^- \*\*REQ-' spec.md` = **8**, `grep -c '^#### AC-' spec.md` = **8**.
  Tier S 상한과 같아 여유가 0이다. REQ→AC: 001→001·006 · 002→006·007 · 003→006 · 004→007 ·
  005→002 · 006→003 · 007→002·004·008 · 008→005·006. (AC-005는 수정 전 재현이라 REQ-002를 검증하지 않는다.)
- **그래도 동작이 바뀐다.** 그래서 AC 셋(005~007)이 시뮬레이터 증거다. 인라인 AC로 담을 수 있어
  `acceptance.md`는 두지 않는다. `design.md`·`research.md`도 없다.
- **Tier M으로 올리는 조건**: run 중에 한 줄 씨앗으로 닫히지 않는 사실이 나와 `EditCard`의 씨앗 규칙 같은
  일반화가 필요해질 때다. 그러면 파일이 늘고 다른 화면이 끌려오므로 게이트로 돌아간다.

## 1. 마일스톤

**바뀌기 쉬운 결정부터 적었다.** 게이트(해소)가 맨 위이고, 그 결정이 순서를 정한 증거 수집이 다음,
한 줄 수리와 기계적 게이트가 그다음이다.

| M | REQ | AC | 요약 | 상태 |
|---|---|---|---|---|
| M0 | — (D-1·D-2·Tier) | — | **착수 승인 게이트** — §2의 세 항목 | ✅ D-1 (a) · D-2 (a) · Tier S — 2026-09-23 |
| M1 | REQ-008 | AC-005 | 수정 전 빌드 — **`Shared/`를 고치기 전에** `Shared/`·`project.yml`이 `73ceb43`과 같은 트리를 `.moai/state/verify/t7/dd-a`로 빌드하고, 그 `.app`을 자리까지 보관한다. SHA와 `git diff --quiet 73ceb43 -- Shared/ project.yml`의 exit 0을 기록 | ⬜ |
| M2 | REQ-001·005·006 | AC-001·002·003 | 한 줄 수리 + 주석 재서술. 커밋 메시지에 카드 id `t7` | ⬜ |
| M3 | REQ-002~004·007·008 | AC-004~007 | 수정을 `dd`로 빌드(새 DerivedData — 빌드 게이트) → 렌즈(`ui-design`·`code-safety`) → **한 자리**(spec §3.2 "함께 돌리기"): `dd-a` 설치 → SPEC-UIKIT-003 AC-010 → SPEC-UIKIT-005 AC-009(5·8·11번과 10번의 이동 구간 출발지는 판정 보류, 6번 보류, 편집 시트에서 저장 금지) → 파트 A(앞 초기화 없음) → `dd`를 덮어 설치 → 보류한 AC-009 판정(편집 시트 → "취소")과 6번, 판정마다 빌드 기록 → 초기화 → 파트 B | ⬜ |
| M4 | 전부 | AC-001~007 | run 종료 — `progress.md` §E.2·§E.3 | ⬜ |
| sync | REQ-007 | AC-008 | 루트 `plan.md` 후속 17 닫기(수정 SHA, 들어온 커밋 `1b98e14`), 줄 수가 바뀌었으면 후속 14·17 인용 재정렬 | ⬜ |

**파트 A가 (다)로 나오면**(재현 안 됨) M2의 수정 커밋을 되돌리고, 카드를 멈추고, 리드에게 보고한다(REQ-008).
수정이 먼저 쓰여 있으므로 되돌릴 커밋이 하나 생긴다 — 게이트는 그 비용을 알고 D-2 (a)를 골랐다.

## 2. 착수 승인 게이트 — 해소 (2026-09-23)

리드가 아래 항목을 착수 승인 게이트에서 제시했고, **운영자가 셋 모두 권고안으로 결정했다**(2026-09-23, 리드가
plan 레인에 전달). 이 plan 세션은 운영자의 답을 직접 보지 않았고, 리드의 전달로 기록한다. 채택하지 않은 안은
결정 기록으로 남긴다.

1. **D-1 수리 모양 — (a) 한 줄 씨앗.** `:166`에 `chosen: editing?.origin?.name`. 목적지 줄(`:169`)과 같은 모양이다.
   `:178`의 씨앗이 읽히고, `:149`의 첫 계산이 저장된 출발지로 돌며, `:424`가 곧장 돌아온다 — 카드 전환 전
   (`d3c9327` `:410`·`:425`)의 동작이다. 코드 변경 1줄, 함수 본문 무변경. REQ-005의 조건절을 걷었다.
   - 채택하지 않은 안 (b): 씨앗에 더해 `prefillOrigin`·`bootstrap`에 `editing?.origin != nil` 검사를 두는 안.
     "출발지가 정해졌다"의 두 번째 진실을 만든다 — 계약 5가 막는 모양이다(REQ-005).
2. **D-2 수정 전 증거의 시점 — (a) 한 자리 두 빌드.** run 레인이 `Shared/`를 고치기 전에 `73ceb43` 트리를 `dd-a`로
   빌드해 두고(M1), 수정을 쓴 뒤 `dd`로 빌드한다(M3). 운영자는 한 번 앉아 `dd-a`로 SPEC-UIKIT-003 AC-010 ·
   SPEC-UIKIT-005 AC-009 · 파트 A를, `dd`로 AC-009의 보류 판정과 파트 B를 돈다. 세부 순서(AC-009의 출발지 확인 단계
   보류, 편집 시트 저장 금지, 파트 A 앞 초기화 생략)는 감사 3회차 R1로 보탰고 spec §3.2 "함께 돌리기"가 정한다.
   파트 A가 (다)면 수정 커밋을 되돌리고 멈춘다(REQ-008).
   - 채택하지 않은 안 (b): 파트 A를 기록한 뒤에야 수정을 쓰는 안 — 운영자 시간 2회.
3. **Tier S — 확정.** 소스 파일 1 · 코드 1줄 · 주석 ≤ 6줄(§0). 동작이 바뀌지만 AC는 인라인 8건 안에 든다.
4. **O-1 — 카드 아님.** `Store.modifyEvent`의 nil 출발지 대체(spec §3 Out of Scope)는 리드 판정으로 카드를 만들지
   않고 Day 닫기 이월 목록에 기록했다(2026-09-23).

**게이트를 통과했다.** run 디스패치를 받으면 M1부터 착수한다.

## 3. 알려진 이슈 / 리스크

- **가짜 음성 — 잘못된 트리로 빌드하기.** 주 체크아웃의 로컬 `master`는 `291db49`(카드 전환 전)라 결함이
  없다(`git worktree list`). **이 자리의 시뮬레이터 증거는 전부 — 파트 A·B, SPEC-UIKIT-003 AC-010, SPEC-UIKIT-005
  AC-009 — `73ceb43` 이후 커밋의 워크트리에서 만든 빌드로 모은다.** 주 체크아웃의 빌드는 셋 모두에서 가짜 음성이다
  (리드가 운영자에게 전한 안내, 2026-09-23). 파트 A 빌드는 `git diff --quiet 73ceb43 -- Shared/ project.yml` exit 0인
  트리에서만 만들고, 이 확인을 `progress.md`에 SHA와 함께 적는다(AC-005).
- **파트 A (나) 가지.** 5초 안에 위치를 못 얻으면 출발지가 빈 채 남는다 — 결함의 다른 모양이다. N₀·X·D와
  "Y 없음(저장 회색)"을 적고 P1을 확인한 뒤 한 번만 다시 돈다. 다시 (나)면 그것을 결과로 받는다(AC-005).
  (다)만이 전제 반증이다.
- **경로 조회 실패.** 대중교통 소요시간이 안 뜨면 X를 잴 수 없다 — 스크립트 P4대로 그 파트를 자동차로 돌린다.
- **위치 캐시.** 칩 탭은 가진 좌표를 곧장 쓴다(`AddEventView.swift:413-414`, `LocationManager.swift:61`·`:132`).
  스크립트 7번이 앱을 다시 실행하는 이유다. 빠뜨리면 8번이 이 카드와 무관한 이유로 실패처럼 보인다.
- **줄 수 드리프트.** 주석이 여섯 줄을 넘으면 `:537` 뒤의 모든 인용이 밀린다. 루트 `plan.md` 후속 14
  (`:573-574`·`:601`)가 그 범위다. 권고는 여섯 줄 안의 재서술이고, 넘치면 sync가 본문 바이트로 대조한다(AC-008).
- **시뮬레이터 데이터와 캘린더.** "일정 모두 삭제"는 시뮬레이터 앱의 데이터만 지운다 — 이 맥의 macOS 앱
  데이터(`~/Library/Application Support/besir/`)와는 다른 컨테이너다. 편집 저장은 구글이 연결돼 있으면 캘린더에
  다시 올리므로(`Store.swift:961-968`) P3가 캘린더 줄을 "안 함"으로 둔다.
- **드라이버 초록은 여기서 증거가 되지 못한다.** 드라이버는 `AddEventView`를 컴파일하지 않는다(`CLAUDE.md:59-63`).
  이 카드의 동작 증거는 시뮬레이터뿐이다.

## 4. 하네스 전문가 배정 (사용자 지시, 매번 적용)

`CLAUDE.md` § 작업을 시작할 때의 표를 **이 카드가 실제로 건드리는 것**으로 채운 명단이다.

| 마일스톤 | 부르는 전문가 | 조건 |
|---|---|---|
| plan 단계(이 문서) | **0명** | 읽기 전용 실측과 문서 작성뿐 |
| M0·M1 | **0명** | 결정, 그리고 빌드·설치(읽기 전용 게이트는 직접 한다) |
| M2 | `swift-impl` | `Shared/`의 Swift 기능 수정 |
| M3 | `ui-design` | `Shared/`의 SwiftUI 뷰 파일을 건드림 — 편집 화면 출발지 줄의 상태(열자마자 선택된 칩, 옵션 칩과 직접입력 칩의 공존), "현재 위치"라는 이름의 저장값(spec §3 Out of Scope), 출발지 칩의 VoiceOver 낭독 |
| M3 | `code-safety` | 구현을 바꿨음 — 위험 부류(`await` 앞뒤 재사용 — `:433` 재확인은 무변경, fire-and-forget `Task` `:306`·`:459` 무변경, 조용한 실패) + 간결성. AC-003의 기록 항목(주석이 이유를 말하는지)도 이 렌즈 |
| — | `ai-tooling` **0명** | `AIAssistant.swift`·`proxy/`·AI 툴 무변경 |
| — | `ux-check` **이 카드 아님** | Day 닫기 때 앱 전체로 돈다 — 실기기 이월 목록(spec §3.3)은 그때 넘긴다 |

- 매니페스트 Sprint Contract의 `hazard_coverage`는 "검사하지 않은 것 = 실패"다. 0건을 찾는 건 통과지만 렌즈를
  안 돌린 채 끝내는 건 통과가 아니다.
- **M3 렌즈 입력(`code-safety`·`ui-design`) — plan 감사 1회차 D14, 코드 읽기, 미관측.** 수리 뒤 편집 시트는 열릴 때
  위치를 요청하지 않는다(`:424`가 곧장 돌아온다). 출발지 검색의 기준 좌표 `near: location.currentLocation`
  (`AddEventView.swift:378`)은 이제 앱 시작 측위(`App.swift:90` `location.useCurrentLocation()`)에만 기댄다. 시작
  측위가 실패한 세션에서는 편집 중 출발지 검색이 기준 좌표 없이 나간다. 결함이 아니라 수리가 바꾸는 도달
  가능성이다 — 렌즈가 판정하고 결과를 `progress.md` §E.2에 적는다.

## 5. 검증 계획

명령의 단일 출처는 이 워크트리의 `CLAUDE.md` § 빌드 · 배포(`:52`·`:53`)다. DerivedData 경로만 새로 둔다.

| 대상 | 명령 | 통과 기준 |
|---|---|---|
| AC-001~003 신호 | `spec.md` §3.1의 `grep`·`git diff` 명령 | 각 AC의 값 |
| iOS 빌드 | `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .moai/state/verify/t7/dd build > .moai/state/verify/t7/ios.log 2>&1` | `BUILD SUCCEEDED` · `^SwiftCompile` > 0 · `AddEventView.swift` 컴파일 ≥ 1 · `grep 'warning:' \| grep -c '\.swift'` = **0** |
| macOS 빌드 | `xcodebuild -scheme besir-macOS -derivedDataPath .moai/state/verify/t7/dd build > .moai/state/verify/t7/macos.log 2>&1` | 동일 |
| 프록시 | `git diff --quiet 73ceb43 HEAD -- proxy/` | exit 0 → `npm test` 선택(돌렸는지 기록) |
| 범위 | `git diff --name-only 73ceb43 HEAD -- . ':!.moai/reports/plan-audit'` · `git diff --name-only --diff-filter=A 73ceb43 HEAD -- Shared/` | `Shared/AddEventView.swift` · `.moai/specs/SPEC-UIKIT-007/` 아래 · (계획-실제 갱신을 했다면) 루트 `plan.md`뿐 · 새 소스 파일 0 → `xcodegen generate` 불필요. 카드 브랜치에 병합이 들어오면 기준을 `git merge-base origin/master HEAD`로 바꾸고 기록(AC-002) |
| 시뮬레이터 A | `dd-a` 빌드, spec §3.2 1~5번 | AC-005 |
| 시뮬레이터 B | 수정 빌드, spec §3.2 1~8번 | AC-006·007 |
| 문서 (sync) | 후속 14·17 인용 본문 바이트 대조(줄 수가 바뀐 경우) | AC-008 |

**측정된 기준선(이 레인, `73ceb43`)**: `grep -c 'chosen: editing?.origin?.name' Shared/AddEventView.swift` = 0 ·
`grep -c 'chosen: editing?.destination.name'` = 1 · `grep -c 'editing?.origin'` = 0 ·
`grep -B8 'private func confirmedPlace' Shared/AddEventView.swift`의 출력에서 `grep -c '프리필'` = 0 ·
`grep -c '도달 불가'` = 1(`:535`) · `grep -c '편집 씨앗'` = 0 · `grep -c 'hereMarker' Shared/AddEventView.swift` = 8 ·
`wc -l` = 645 · `grep -o 'AddEventView[.swift]*:[0-9]' CHECKLIST.md | wc -l` = 0.

**이 plan 단계에서 돌리지 않은 것(run의 몫)**: iOS·macOS `xcodebuild`, `npm test`, 시뮬레이터 두 파트.
**가드 드라이버는 run에서도 돌리지 않는다**(spec §0). **`xcodegen generate`는 돌리지 않는다** — 새 소스 파일이 0개다.

## 6. 후속 (본 SPEC 밖 — 리드가 카드로 올릴 대상)

- **O-1 — `modifyEvent`의 nil 출발지 대체**(`Store.swift:345`, 코드 읽기 가설, 미관측). AI 편집이 nil 출발지를
  목적지로 채워 0분 이동을 만들 수 있다. spec §3 Out of Scope. **리드 판정(2026-09-23): 카드 아님, Day 닫기 이월
  목록에 기록.**
- **카드 본문 정정** — "이번 Day 회귀 아님"은 사실이 아니다. 결함은 `1b98e14`(t2, Phase 1.7)에서 들어왔다(spec §1.5).
  카드 본문은 리드가 관리한다.
- **"현재 위치"라는 이름으로 저장된 출발지의 표시 모호성** — 데이터는 맞다. 고칠지 리드가 정한다.
- 루트 `plan.md` 후속 14(직접입력 경로의 잠재 결함)는 이 카드와 같은 화면이지만 강등된 항목이라 건드리지 않는다.
- **리드에게 — SPEC-UIKIT-005 AC-009 스크립트의 전제 오류.** 그 스크립트(`acceptance.md:241-242`·`:254`·`:261`·`:262-263`)는
  일정 상세가 출발지를 보여준다고 전제하지만, 상세는 목적지만 그린다(`EventDetailView.swift:172-175`). 출발지를 볼 곳은
  편집 시트뿐이고, 그 시트가 저장된 출발지를 보여주는 것은 이 카드의 수리 뒤부터다.

🗿 MoAI
