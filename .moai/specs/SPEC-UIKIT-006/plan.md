# SPEC-UIKIT-006 — plan.md

> 이 문서는 **구현을 앞둔 계획**이다(as-built 아님). 원본은 칸반 카드 t5 본문(`moai todo`)이다.
> 줄번호는 전부 `00ab661`에서 실측했고, 세는 명령을 수치 옆에 적었다. 카드 본문과 실측이 어긋난
> 자리 넷은 `spec.md` HISTORY 0.1.0에 있다.

## 0. Tier 판단

**Tier: S**

권고안 (§2의 세 결정을 모두 (a)로) 기준으로 run이 하는 일과 줄 수:

| 파일 | 변경 | 줄 | 세는 명령 |
|---|---|---|---|
| `Shared/Store.swift` | `deleteExpired` 문서·함수·뒤 빈 줄 삭제 (REQ-012) | −16 | `awk 'NR>=1318 && NR<=1333' Shared/Store.swift \| wc -l` |
| `Shared/Store.swift` | `updateMeal` 위 이유 주석 (REQ-011) | +1 | — |
| `Shared/Store.swift` | `:176`을 `:246` 바로 위로 이동 (REQ-001) | 이동 1 | `awk 'NR==176 \|\| NR==246' Shared/Store.swift` |
| `Shared/Store.swift` | `addActivity` 문서·함수·뒤 빈 줄 삭제 (REQ-001) | −13 | `awk 'NR>=177 && NR<=189' Shared/Store.swift \| wc -l` |
| `Shared/LocationManager.swift` | `openLocationSettings`·뒤 빈 줄 삭제 (REQ-010) | −12 | `awk 'NR>=118 && NR<=129' Shared/LocationManager.swift \| wc -l` |
| `Shared/LocationManager.swift` | `AppKit`/`UIKit` 조건부 import 삭제 (REQ-010) | −5 | `awk 'NR>=3 && NR<=7' Shared/LocationManager.swift \| wc -l` |
| `ContentView` · `AddActivityView` · `GoogleCalendarService` | `import CoreLocation` 삭제 (REQ-002) | −3 | `grep -n "^import CoreLocation" Shared/ContentView.swift Shared/AddActivityView.swift Shared/GoogleCalendarService.swift` |
| `CLAUDE.md` | `:127` 인용 교체 (REQ-020 (a)) | 교체 1 | `grep -n "SettingsView.swift" CLAUDE.md` |

**삭제 49줄**(16 + 13 + 12 + 5 + 3), 이동 1줄, 추가 1줄, 교체 1줄이다. 파일 길이는
`wc -l`로 `Store.swift` 1495 · `LocationManager.swift` 178 · `ContentView.swift` 981 ·
`AddActivityView.swift` 629 · `GoogleCalendarService.swift` 415 · `CLAUDE.md` 150.

- **줄 수는 Tier S(300 미만)에 한참 못 미치지만, 파일 수는 Tier M의 범위다.** 주 체크아웃의
  `.claude/rules/moai/workflow/spec-workflow.md:140-141` 표에서 Tier S는 "< 5 files", Tier M은
  "5 - 15 files"이고, run 파일은 6개다. `Shared/*.swift` 다섯만으로도 이미 "5개 미만"을 벗어난다.
  S로 두는 이유: 여섯 중 셋은 import 한 줄, `CLAUDE.md`는 인용 한 줄이라 파일 수가 작업량을
  과장한다. 새 타입·새 화면·새 저장 경로·설계 분기가 하나도 없다. 이 판단은 착수 승인 게이트에서
  운영자가 확인한다(§2 항목 5).
- **REQ 8건 · AC 8건** — `grep -c '^- \*\*REQ-' spec.md` = **8**, `grep -c '^#### AC-' spec.md` = **8**.
  Tier S 상한(REQ 8 / AC 8)과 같아 여유가 0이다.
- **Tier M으로 올리는 조건**: D-1 또는 D-3에서 (b)(연결)를 고를 때. 기능이 생기고 화면 설계가
  들어오며(`ui-design`), 동작이 바뀌므로 실기기 확인 항목이 생긴다 — 인라인 AC로는 담을 수 없어
  `acceptance.md`가 필요하다. D-2 (b)는 등급이 아니라 **범위** 문제다(다른 SPEC 개정) — 별도 카드.
- `acceptance.md`·`design.md`·`research.md`는 없다 — Tier S는 `spec.md §3.1`에 AC를 인라인한다.

## 1. 마일스톤

**바뀌기 쉬운 결정부터 적었다.** 가장 바뀌기 쉬운 결정(게이트의 세 선택)이 맨 위에 있고, 그 결정에 따라
내용이 달라지는 마일스톤이 다음, 결정과 무관한 기계적 삭제가 그다음이다.

| M | REQ | AC | 요약 | 상태 |
|---|---|---|---|---|
| M1 | — (D-1~D-3) | — | **착수 승인 게이트** — 세 결정 · `CLAUDE.md` 수정 확인 · Tier 확인(§2). 고른 안이 M2의 내용과 §4의 렌즈 명단을 정한다 | ⬜ |
| M2 | REQ-010~012 | AC-003~005 | 결정된 세 건 — 권고안이면 `deleteExpired` 삭제, `updateMeal` 이유 주석, `openLocationSettings`와 그것만 쓰던 import 삭제 | ⬜ |
| M3 | REQ-001·002 | AC-001·002 | 즉시 제거군 — `addActivity` 삭제와 `:176` 이동, `import CoreLocation` 셋 | ⬜ |
| M4 | REQ-020 (a)·021·030 | AC-007·008 (AC-006 일부) | `CLAUDE.md:127` 인용 교체(**run의 마지막 편집**)·범위 대조·게이트 셋 | ⬜ |
| sync | REQ-020 (b) | AC-006 | `CHECKLIST.md` 드리프트 수리(본문 바이트 대조) + L3 기존 오인용 + D-3 (a)면 `plan.md:105` 항목 닫기 | ⬜ |

**실행 순서도 같다: M1 → M2 → M3 → M4 → sync.** M2와 M3은 같은 `Store.swift`를 고치므로 한
레인이 차례로 한다. **파일 안에서는 아래에서 위로 고친다** — `deleteExpired`(`:1318`) →
`updateMeal` 주석(`:421` 위) → `:176` 문구를 `:246` 위에 삽입 → `:176-189` 삭제 순서면, 아직 손대지
않은 윗부분의 SPEC 인용 줄번호가 끝까지 유효하다. `LocationManager.swift`도 `:118-129` → `:3-7`
순서다.

**`CLAUDE.md`를 run의 마지막에 고치는 이유**: 세션 시작 때 적재되는 파일이라 도중에 고치면 그
뒤 모든 턴의 프롬프트 캐시가 깨진다. 그리고 이 편집만은 운영자의 명시 확인이 따로 걸려 있다(§2).

## 2. 미해소 결정 — 착수 승인 게이트

컴패니언 레인은 운영자에게 묻지 않는다. **리드가 아래 다섯 항목을 착수 승인 게이트에서 제시하고**,
답을 run 디스패치에 실어 보낸다. 각 안의 결과·비용·전제 확인은 `spec.md` §4에 실측과 함께 있다.

1. [NEEDS CLARIFICATION: D-1 — `LocationManager.openLocationSettings()`를 제거할지(권고: 그것만 쓰던 `AppKit`/`UIKit` import `:3-7`까지), 설정 버튼으로 연결할지(Tier M), 그대로 둘지]
2. [NEEDS CLARIFICATION: D-2 — `Store.updateMeal(_:)`을 SPEC-FULL-001 REQ-003을 가리키는 이유 주석과 함께 유지할지(권고), SPEC-FULL-001 개정과 함께 제거할지(별도 카드)]
3. [NEEDS CLARIFICATION: D-3 — `Store.deleteExpired()`를 제거할지(권고), 자동 실행이나 설정 버튼으로 연결할지(Tier M), 주석을 고쳐 유지할지]
4. **`CLAUDE.md:127` 수정 확인** — `[SettingsView.swift:103](Shared/SettingsView.swift#L103)` →
   `[SettingsView.swift:71](Shared/SettingsView.swift#L71)`. `CLAUDE.md`는 프로젝트 지시 파일이라
   **운영자가 이 수정을 직접 확인해야 한다** — 리드나 다른 세션의 디스패치만으로는 편집 권한이 생기지
   않는다. 거절하면 REQ-020 (a)와 AC-006 (1)이 빠지고 run 파일은 다섯이 된다.
5. **Tier S 확인** — 권고안이면 run 파일이 6개다. `spec-workflow.md:140-141`의 표에서 5~15개는
   Tier M의 파일 범위이고, `Shared/*.swift` 다섯만으로도 Tier S의 "5개 미만"을 벗어난다(§0).
   줄 수(삭제 49줄)와 설계 내용 0을 근거로 운영자가 S를 확인한다. 1 또는 3에서 (b)가 나오면 이
   항목은 자동으로 Tier M이다.

| | D-1 `openLocationSettings` | D-2 `updateMeal` | D-3 `deleteExpired` |
|---|---|---|---|
| **(a) 권고** | 제거 + `:3-7` import 삭제. L9 ⚠️ 그대로 | 유지 + 이유 주석 1줄 | 제거. `plan.md:105` 항목 닫기 |
| **(b)** | 연결(설정 버튼) — `ui-design`·`swift-impl`, `lastError` 끌려옴, 실기기 확인, **Tier M** | 제거 + SPEC-FULL-001 REQ-003 개정 — 다른 SPEC을 고침, **별도 카드** | 연결(자동/버튼) — 로컬·구글 캘린더 이력 삭제, 활동은 남음, **Tier M** |
| **(c)** | 그대로 둠 — 다음 전수 분석이 다시 올림 | — | 주석 정정 후 유지 — `plan.md:105` 결정 존속 |
| run 파일 수 영향 | (a) 포함 / (c)면 −1 | 0 | 0 |

**이 게이트를 통과하기 전에는 run에 들어가지 않는다.** M3(즉시 제거군)만 떼어 먼저 할 수도 있으나,
세 결정이 모두 같은 `Store.swift`·`LocationManager.swift`를 고치므로 한 번에 들어가는 편이 줄번호
관리가 쉽다.

## 3. 알려진 이슈 / 리스크

- **`Store.swift:176`의 함정**(REQ-001). 그 줄은 `addActivity`의 문서가 아니라
  `addRecurringActivities`(`:248`) 문서의 첫 줄이 밀려난 것이다(나머지 한 줄이 `:246`).
  `:176-189`를 통째로 지우면 그 문서가 주어 없는 한 줄로 남는다. 빌드도 드라이버도 못 잡는다.
  반증 신호: AC-001의 인접성 검사(`N`·`N+1`·`N+3`)가 어긋난다.
- **import 제거의 증명은 빌드뿐이다**(REQ-002·REQ-010). 텍스트 증거(CL 심볼 0건, `SWIFT_VERSION: "5.0"`,
  `MemberImportVisibility` 없음)는 컴파일을 예측할 뿐이다. 가드 드라이버의 컴파일 집합에는
  `GoogleCalendarService.swift`·`LocationManager.swift`가 들어 있지만(호스트 `swiftc`),
  `ContentView.swift`·`AddActivityView.swift`는 들어 있지 않다 — 이 둘은 `xcodebuild`만 증명한다.
- **`LocationManager`의 `AppKit`/`UIKit` import를 지우면**(REQ-010) `ObservableObject`(`:12`)가 어디서
  오는지가 문제다. 같은 트리의 `NotificationManager.swift`가 `Foundation`·`UserNotifications`만으로
  `ObservableObject`를 쓰고 빌드되므로 Foundation이 공급한다고 본다 — 빌드가 확정한다. 깨지면
  `:3-7`을 되살리는 것이 아니라 필요한 모듈을 명시적으로 import하는 것이 맞는지 판단한다.
- **줄번호 드리프트**(REQ-020 (b)). `Store.swift` 앵커 인용 33건 중 25건이 `:176` 뒤라 밀리고, 밀리는
  폭은 구간마다 다르다(`addActivity` 삭제와 `:176` 이동이 만드는 폭, `updateMeal` 주석이 만드는 +1,
  `deleteExpired` 삭제가 만드는 폭이 겹친다). `GoogleCalendarService`·`ContentView`는 import 한 줄이라
  전부 −1이다. **import 셋만으로 인용 묶음 9개(GCS 4 + ContentView 5)가 밀리고, 동작상 이득은 0이다**
  — 카드가 제거를 이미 골랐으므로 비용으로만 적는다. t6 sync의 교훈대로 **산술은 귀속을 검증하지
  못한다** — 한 줄에 여러 파일 인용이 섞이므로, 인용마다 대상 파일을 문맥으로 확인하고 본문 바이트로
  대조한다.
- **가드 드라이버가 끝나지 않을 수 있다.** 이 plan 레인이 새로 컴파일한 바이너리는
  `Store.updateRecurringSeries` → `googleConnected` → `Keychain.get` → `SecItemCopyMatching`에서
  멈췄다(`sample` 관측, CPU 0%, 600초 초과). 새 바이너리가 운영자 화면에 키체인 접근 확인을 띄우는
  것으로 보인다. run 레인은 드라이버를 돌리기 전에 이것을 운영자에게 알리고, **대화상자가 뜨면
  거부(Deny)로 답해 달라고 요청한다.** 근거는 도달 가능성 판단이다(호출을 관측한 것은 아니다):
  `googleConnected` = `config.hasGoogleCalendar && gcal.isConnected`(`Store.swift:493`),
  `isConnected` = `Keychain.get(refreshKey) != nil`(`GoogleCalendarService.swift:38`)이고, 드라이버는
  `googleClientID`를 N절 안에서만 비운다(`GuardDriver.swift:1262-1263` → `:1337`에서 되돌림). 이 맥의
  `config.json`에는 클라이언트 ID가 있으므로(plan 레인 관측 — 키가 있고 비어 있지 않음, `GuardDriver.swift:1350` 주석도 같은 말), 허용하면 나머지 실행 동안 실제 구글 계정 경로가 도달
  가능해지고 파일 백업으로는 원격의 일을 되돌릴 수 없다. 키체인 답은 실행마다 기록하고, 허용된
  실행은 "구글 연결 상태로 돌았음"으로 적는다. 멈추면 AC-008 (a)를 **미관측**으로 기록한다 — 멈춘
  것을 통과로도 실패로도 적지 않는다. **205/205 기준선의 키체인 상태는 미상이다** — 오케스트레이터는
  대화상자를 보지 못한 채 완주했고, 대화상자가 떴다가 답해졌는지 아예 뜨지 않았는지 알 수 없다.
- **드라이버는 이 맥의 실제 besir 데이터에 쓴다 — 관측됨(2026-09-23, `spec.md` §3 Out of Scope).**
  지금 `~/Library/Application Support/besir/events.json`에는 이 plan 레인이 강제 종료한 실행이
  14:17에 남긴 `출근`·`헬스`(`GuardDriver.swift:287-288`의 시험 일정)가, `activities.json`에는
  오케스트레이터의 205/205 완주 실행이 14:11에 남긴 `W-하룻밤`(W절 `:1037-1039`, 백업 없음)이 있다.
  14:11 이전 내용은 되살릴 수 없다. `config.json`이 `autoAddToCalendar = true`라, **운영자가 정리
  방법을 정하기 전까지 이 맥에서 besir macOS 앱을 켜지 않는다** — 켜서 동기화가 돌면
  `reconcileActivities` 2-5(`Store.swift:1461-1470`)가 `W-하룻밤`을 실제 구글 캘린더에 올린다.
  이 카드는 드라이버를 고치지 않고(REQ-021), **돌릴 때마다** REQ-030 (a)의 절차를 지킨다:
  (i) 실행 전 운영자에게 키체인 대화상자 가능성을 알리고 거부로 답해 달라고 요청
  (ii) 데이터 디렉터리의 앱 파일 일곱 중 있는 것은 전부 세션 scratch로 복사, 없는 것은 이름 기록
  (iii) 같은 호출 안에 시간 제한 — 이 맥에는 `timeout`·`gtimeout`이 없으므로(`which` → not found)
  `perl -e 'alarm shift; exec @ARGV' <초> <바이너리>`(시간이 다 되면 exit 142, `sleep`으로 실측)
  (iv) **복원 전에** 종료 코드를 기록하고, 멈췄으면 죽인 뒤 프로세스가 없다는 것을 확인
  (실행 때 기록한 PID로 `kill -0 <pid>` 실패가 기본 신호. `pgrep`은 고유 이름 바이너리에
  `pgrep -fx <전체 경로>`로만 — 기본 이름 `gd`는 `logd` 등 시스템 프로세스에 걸린다), 운영자에게 대화상자가 닫혔는지
  확인받는다 — 멈춘 자리가 `save()`(`Store.swift:771`) 뒤의 `googleConnected`(`:776`)라, 대화상자에
  답하는 순간 프로세스가 이어서 돌아 다시 쓰고(연결 상태면 `:789`) 깨끗했던 `cmp`가 거짓이 된다
  (v) 그다음에만 되돌리고 파일마다 `cmp` 출력을 기록, 없던 파일이 생겼으면 지우고 `ls`로 확인
  (vi) 키체인 답 기록. AC-008 (d)가 이것을 재고, 기록은 `progress.md` §E.2에 남긴다(REQ-021 예외 (3)).
  되돌리는 대상은 **실행 직전 상태**다 — 이미 남은 시험 데이터는 그대로 두고 운영자 결정을 기다린다.
- **"드라이버 초록 ≠ 기기 동작"** — 이 카드는 권고안에서 동작이 바뀌는 자리가 0곳이라 실기기 전용
  항목이 없다. (b) 안이 하나라도 채택되면 그 규칙이 다시 걸리고 실기기 항목이 생긴다(Tier M).
- **하네스 스킬이 `updateMeal`을 계속 후보로 싣는다.** 주 체크아웃의
  `.claude/skills/hns-besir-app-hazards/SKILL.md:233`(`.claude/`는 git이 추적하지 않아
  `git ls-files .claude | wc -l` = 0 — 이 워크트리에는 없다). D-2 (a)의 코드 주석이 다음 분석자를
  막지만 스킬은 이 카드 범위 밖이다(REQ-021) — 리드에게 넘긴다.

## 4. 하네스 전문가 배정 (사용자 지시, 매번 적용)

`CLAUDE.md` § 작업을 시작할 때의 표를 **이 카드가 실제로 건드리는 것**으로 채운 명단이다.

| 마일스톤 | 부르는 전문가 | 조건 |
|---|---|---|
| plan 단계(이 문서) | **0명** | 읽기 전용 실측과 문서 작성뿐 |
| M1 (게이트) | **0명** | 결정뿐 |
| M2·M3 (`Store`·`LocationManager` 등) | `swift-impl` | Swift 기능 수정 |
| M2 (D-1 (b) 또는 D-3 (b) 버튼일 때만) | **+ `ui-design`** | 새 UI가 생긴다 — 이 경우 Tier M |
| M4 (범위 대조·게이트) | `code-safety` | 구현을 바꿨음 |
| — | `ai-tooling` **0명** | `AIAssistant.swift`·`proxy/`·AI 툴 무변경 |
| — | `ux-check` **이 카드 아님** | Day 닫기 때 앱 전체로 돈다 |

- **`ContentView.swift`·`AddActivityView.swift`는 SwiftUI 뷰 파일이지만 `ui-design`을 부르지 않는다.**
  바뀌는 것이 import 한 줄이고 화면 변화가 0이다 — `CLAUDE.md` 표의 조건은 "뷰를 건드리거나 새 화면
  설계"이지만 판단 기준은 명령이 아니라 하는 일이다. 이 판단을 여기 적어 두어 운영자가 반박할 수 있게 한다.
- `code-safety`는 구현이 끝난 뒤 한 번 돌린다. 매니페스트 Sprint Contract의 `hazard_coverage`는
  "검사하지 않은 것 = 실패"다 — 0건을 찾는 건 통과지만 렌즈를 안 돌린 채 끝내는 건 통과가 아니다.
  이 카드에서 렌즈가 특히 볼 자리: `:176` 이동이 맞게 됐는지, 지운 함수가 쓰던 헬퍼가 고아가 되지
  않았는지(`spec.md` §1.2·REQ-012의 호출부 계수).

## 5. 검증 계획

명령의 단일 출처는 이 워크트리의 `CLAUDE.md` § 빌드 · 배포와 `hns-besir-app-verify` 스킬이다 —
**명령을 새로 만들지 않고 그것을 돈다.** 각 명령은 자기 작업 디렉터리를 스스로 갖게 쓴다(병렬
호출의 `cd` 오염 전례).

| 대상 | 명령 | 통과 기준 |
|---|---|---|
| 인수 기준 신호 | `spec.md` §3.1 AC-001~005·AC-007의 `grep` 명령 | 각 AC의 값 |
| AI 인자 가드 | `CLAUDE.md` § 빌드 · 배포의 드라이버 블록(새 바이너리 이름으로 신선 컴파일)을 REQ-030 (a)의 절차로 감싼다 — 키체인 고지(답은 거부) → 데이터 디렉터리 백업 → `perl -e 'alarm shift; exec @ARGV' <초> <바이너리>`로 실행 → 종료 코드 기록 → 프로세스 소멸 확인(기록한 PID에 `kill -0` 실패)·대화상자 닫힘 확인 → 복원 → `cmp` → 키체인 답 기록 | 전체 통과·exit 0·마지막 불변식 ✓. 키체인 대기로 멈추거나 시간 제한(exit 142)에 걸리면 **미관측**. 어느 경우든 `progress.md` §E.2에 시간 제한 값·종료 코드·복원 시점 프로세스 없음·대화상자 닫힘·키체인 답·파일별 `cmp` 무출력·exit 0·없던 파일은 여전히 없음(AC-008 (d)) — 이것이 빠지면 FAIL |
| iOS 빌드 | `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build` | `BUILD SUCCEEDED` + `grep 'warning:' <log> \| grep -c '\.swift'` = **0** |
| macOS 빌드 | `xcodebuild -scheme besir-macOS -derivedDataPath build build` | 동일 |
| 프록시 | `cd proxy && npm test` | 전체 통과 |
| 범위 경계 | `git diff --name-only 00ab661...HEAD -- 'Shared/*.swift'` | **정확히 5개**(D-1이 (a)가 아니면 4개). 저장소 경로만 본다 — `.claude/`와 REQ-021 예외 (1)·(2)는 못 본다 |
| 새 파일 | `git diff --name-only --diff-filter=A 00ab661...HEAD -- 'Shared/*.swift'` | **0건** → `xcodegen generate` 불필요 |
| 인용 (sync) | 인용된 줄의 본문 바이트 대조 | AC-006 네 조건 |

**측정된 기준선.**

- 가드 드라이버: **205/205 통과, exit 0**, 마지막 불변식 ✓ — **오케스트레이터가 `00ab661`에서 관측한
  값이다.** 그 실행도 부작용이 없지 않았고(14:11 `activities.json`에 `W-하룻밤`), 그 실행의 키체인
  상태는 미상이다(대화상자를 본 사람이 없다 — 떴다가 답해졌는지 아예 안 떴는지 모른다). 이 plan 레인의
  재실행은 키체인 대기로 멈춰 종료했고(exit 143, 출력 버퍼 비어 있음), 종료 전에 `events.json`을
  썼다(14:17) — `spec.md` §0·§3. 컴파일은 이 레인에서도 끝났다(exit 0). 호스트 `swiftc`의 경고는
  `grep -cE '\.swift:[0-9]+:[0-9]+: warning:' <compile.log>` = **12줄**, 위치로는 **11곳**
  (`DirectionsService` 8 · `LocationManager` 3줄/2곳 · `PlaceSearch` 1 — `LocationManager.swift:25`의
  `CLGeocoder` 경고가 두 번 찍힌다)이고 전부 macOS 26 SDK 사용 중단 경고다. 호스트 SDK의 것이라
  `xcodebuild` 게이트와 무관하며, 이 카드가 지우는 줄과 겹치지 않는다(`:25`·`:167`은 남는 코드).
- 인수 기준 신호의 변경 전 값(이 레인 실측): `grep -l "^import CoreLocation" Shared/*.swift | wc -l`
  = 12 · `grep -c "lastError" Shared/LocationManager.swift` = 8 ·
  `grep -c "^import AppKit\|^import UIKit\|NSWorkspace\|UIApplication" Shared/LocationManager.swift` = 5 ·
  `grep -c '^#if os(macOS)' Shared/LocationManager.swift` = 1(`:3`) ·
  `grep -cF "/// 여러 요일에 반복되는 활동 블록(수업·근무·점심 등)을 한 번에 생성한다. 이동시간 계산은 없다." Shared/Store.swift` = 1 ·
  `grep -rn "removeFromCalendar(" Shared/ | grep -v "func " | wc -l` = 10.
- 드라이버를 감쌀 도구(이 레인 실측): `which timeout gtimeout` → 둘 다 not found · `/usr/bin/perl` 있음 ·
  `perl -e 'alarm shift; exec @ARGV' 2 sleep 5` → exit 142 · `which pgrep` → `/usr/bin/pgrep`.

**이 plan 단계에서 돌리지 않은 것(run의 몫):** iOS·macOS `xcodebuild`, `cd proxy && npm test`, 그리고
끝까지 돈 드라이버. **`xcodegen generate`는 돌리지 않는다** — 새 소스 파일이 0개(REQ-021)이므로
서명 계정 리셋도, `besir-iOS`·`besirShare` 두 타깃의 Team 재선택 요청도 없다. **이 문장이 지워져
있으면 새 파일을 만든 것이다.**

## 6. 후속 (본 SPEC 밖 — 리드가 카드로 올릴 대상)

- **`LocationManager.lastError`·`NotificationManager.lastError`가 쓰기만 있고 읽는 화면이 없다**
  (`spec.md` §3). 위치 권한 안내 문구("시스템 설정에서 허용해 주세요")가 사용자에게 닿지 않는다.
  D-1 (b)를 고르는 카드가 생기면 그 카드와 묶는다.
- **`fetchBesirItems()`의 한 페이지 조회**(코드 읽기 가설, 미관측) — 일부 페이지를 받으면 동기화
  1단계가 로컬 일정을 "다른 기기에서 삭제됨"으로 지운다. 고칠 자리는 `GoogleCalendarService`의
  `nextPageToken` 처리다. 재현하려면 besir 항목이 250건을 넘는 계정이 필요하다.
- **카드 밖 데드 코드 후보** — `KoreanHolidays.dates(year:)`(`Models.swift:326`, 호출부 0),
  `MealLog.estimatedCost`(`Models.swift:485`, 읽는 곳 0).
- **하네스 스킬의 `updateMeal` 항목에 유지 근거 추가** — 주 체크아웃의 `.claude/` 수정이라(git 미추적)
  하네스 쪽 일이다.
- **가드 드라이버의 실제 데이터 쓰기와 키체인 대기 — 둘 다 관측됨(2026-09-23).** 백업 없는 초반
  절(H절 `:287-288`)과 W절(`:1037-1039`)이 `~/Library/Application Support/besir/`의 `events.json`·
  `activities.json`에 시험 데이터를 남겼고(지금 남아 있다), 새로 컴파일한 바이너리는 키체인 확인에서
  멈췄다. 리드가 정할 것 둘: 드라이버를 고치는 카드, 그리고 **이미 남은 시험 데이터의 정리** — 정리가
  정해질 때까지 이 맥에서 besir macOS 앱을 켜지 않는다(켜면 `W-하룻밤`이 실제 구글 캘린더로 올라갈
  수 있다). 이 카드는 그때까지 REQ-030 (a)의 절차 — 키체인 거부, 시간 제한, 복원 전 프로세스 소멸
  확인, 백업·`cmp` 복원 — 로만 방어한다.

🗿 MoAI
