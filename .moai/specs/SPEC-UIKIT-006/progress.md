# SPEC-UIKIT-006 — progress.md

칸반 카드 t5 · 데드 코드 정리. 2026-09-23 리드 디스패치를 받아 plan 레인 세션이 시작했다.
워크트리는 `.claude/worktrees/t5`(branch `WT-dead-code`, base `00ab661` = `origin/master`)다.

## §E.1 Plan-phase Audit-Ready Signal

- plan_complete_at: 2026-09-23T15:47+09:00
- plan_status: audit-ready
- kickoff_gate: **resolved 2026-09-23** — 운영자가 다섯 항목을 모두 권고안으로 확정했다(리드가 전달, 기록은 `plan.md` §2).
  D-1 (a) · D-2 (a) · D-3 (a) · `CLAUDE.md:127` 승인 · Tier S. 이 plan 세션은 운영자의 답을 직접 보지 않았다.
  `CLAUDE.md` 편집은 run 레인이 직전에 자기 세션에서 운영자에게 다시 확인받는다(REQ-020 (a)).
- (게이트 전 기록) kickoff_gate: pending — "구현 준비 완료"라는 뜻이 **아니다.** 세 결정(D-1~D-3)이 미해소이고,
  `CLAUDE.md` 수정과 Tier S 판정도 운영자가 확인해야 한다. 그래서 이 신호가 여는 다음 단계는 run 착수가 아니라
  **착수 승인 게이트**다(`plan.md` §2의 다섯 항목). `plan_status` 값은 스키마의 정식 값(`audit-ready`)으로 적었다.
  t6는 비정식 값 `audit-ready-for-kickoff-gate`를 썼는데, 감사 2회차가 이를 지적했다. 그래서 게이트 대기는 별도 줄에 적는다.
- plan 산출물: `spec.md` · `plan.md` · `progress.md`(이 파일). Tier S라 `acceptance.md`를 두지 않고,
  AC는 `spec.md` §3.1에 인라인했다.
- 작성 주체: `spec.md`·`plan.md`는 `manager-spec`이 썼다(서브에이전트, 오케스트레이터 실측을 넘겨받아
  재실측함). 이 파일은 plan 레인 오케스트레이터가 썼다. **`Shared/` 아래 변경은 0건이다.**

### 관측된 증거 — plan 레인 오케스트레이터가 이 트리에서 직접 돌린 명령

아래 값은 전부 이 세션이 `00ab661`에서 직접 실행해 얻었다. `manager-spec`이 독립으로 다시 잰 값은
`spec.md`에 명령과 함께 적혀 있고, 두 측정이 어긋난 자리는 아래 "교차 검증" 절에 따로 적었다.

| 명령 | 관측된 출력 | 쓰인 곳 |
|---|---|---|
| `git rev-parse --short HEAD` / `git branch --show-current` / `git rev-list --count --left-right origin/master...HEAD` | `00ab661` / `WT-dead-code` / `0 0` | 전 인용의 기준 트리 |
| `grep -n "func addActivity\|func updateMeal\|func deleteExpired\|func openLocationSettings" Shared/*.swift` | `LocationManager.swift:118` · `Store.swift:178` · `:421` · `:1319`(+ `addActivityWithTravel` `:203`) | §1.1 — 카드 줄번호가 그대로 |
| `grep -rn "<이름>(" Shared/ ShareExtension/ Tools/` (addActivity·updateMeal·deleteExpired·openLocationSettings) | 넷 모두 선언 한 줄뿐 | §1.1 호출부 0 |
| `grep -c '\bCL[A-Z][A-Za-z0-9]*' <file>` (import CoreLocation 12파일) | ContentView **0** · AddActivityView **0** · GoogleCalendarService **0**, 나머지 아홉은 1~15 | REQ-002 |
| `grep -n "SWIFT_VERSION\|MemberImportVisibility\|upcoming" project.yml` | `:13 SWIFT_VERSION: "5.0"` 한 줄 | §1.3 |
| `awk 'NR>=174&&NR<=189 \|\| NR>=244&&NR<=247' Shared/Store.swift` | `:176`이 "여러 요일에 반복되는 활동 블록…", `:246`이 "recurrenceId를 공유하는…", `:248` `func addRecurringActivities` | REQ-001 함정 |
| `grep -rn "addActivityWithTravel(" Shared/ \| grep -v "func "` | `FullSirView.swift:463` · `AIAssistant.swift:1511` · `AddActivityView.swift:524` | §1.2 |
| `grep -n "REQ-003" .moai/specs/SPEC-FULL-001/spec.md` · `grep -n "^status:" …` | `:60`에 `updateMeal` 명시 · `status: in-progress` | D-2 전제 |
| `git log -S "deleteExpired()" --format="%h %ad %s" --date=short -- Shared/` | `d3c9327 2026-09-12 최초 커밋` 한 줄 | D-3 전제 |
| `grep -rn "pageToken\|nextPageToken\|maxResults" Shared/` | `GoogleCalendarService.swift:107` 한 줄 | §3 페이지 가설 |
| `grep -rn "\.lastError" Shared/ \| grep -v "self.lastError\|^Shared/LocationManager.swift\|^Shared/NotificationManager.swift"` | **0건** | §3 lastError |
| `grep -n "테스트용\|일정 모두 삭제" Shared/SettingsView.swift` · `awk 'NR==103' Shared/SettingsView.swift` | `:71`(표식) · `:77` · `:84` / `:103`은 `.frame(width: 460)` | REQ-020 (a) |
| `grep -o "<File>.swift:[0-9]*" CHECKLIST.md \| wc -l` | Store 33 · GCS 4 · ContentView 5 · LocationManager 0 · AddActivityView 0 | REQ-020 (b) |
| 변경 파일 일곱에서 한 번만 나오는 함수 이름 계수 | `placeSubviews` 1건 — `struct ChipFlow: Layout`(`EditCardView.swift:482`)의 요구사항이라 오탐 | §1.1 끝 |

외부 문서 하나를 조회했다. Google Calendar API `events.list` 참조
(developers.google.com/workspace/calendar/api/v3/reference/events/list, 2026-09-23 WebFetch)에 따르면
`maxResults`는 "may be less than this value, or none at all, even if there are more events matching the query"이고
기본값은 250이다. 기본 순서는 "an unspecified, stable order"다.

### 게이트 — plan이 실제로 돌린 것 **하나**

```
$ cat Shared/EditCard.swift Shared/AIAssistant.swift Tools/GuardDriver.swift > <scratchpad>/gd_t5.swift
$ swiftc -o <scratchpad>/gd_t5 <scratchpad>/gd_t5.swift Shared/Store.swift Shared/Models.swift \
    Shared/Config.swift Shared/PlaceSearch.swift Shared/DirectionsService.swift \
    Shared/LocationManager.swift Shared/NotificationManager.swift \
    Shared/GoogleCalendarService.swift Shared/SharedInbox.swift -parse-as-library
build exit=0
$ <scratchpad>/gd_t5
run exit=0
  ✓ 불변식: 전체 실행 뒤에도 autoAddToCalendar는 꺼져 있다

205/205 통과
```

컴파일 집합은 이 워크트리 `CLAUDE.md` § 빌드 · 배포의 블록과 같고, 출력 경로만 세션 scratchpad로 바꿨다.
이 집합에 이 카드가 고칠 `Store.swift`·`LocationManager.swift`·`GoogleCalendarService.swift`가 들어 있으므로,
**205/205가 착수 전 기준선이다.** 호스트 `swiftc` 경고는 `grep -c "warning:" <build.log>`로 **24줄**이다.
이 수에는 캐럿 반복 줄이 섞여 있다. `manager-spec`이 위치 기준으로 다시 세니 12줄·11곳이었고,
전부 macOS 26 SDK 사용 중단 경고(DirectionsService·LocationManager·PlaceSearch)다. 호스트 SDK에서
나온 것이라 `xcodebuild` 게이트와 관계없다.

### 사고 기록 — 이 plan 단계의 드라이버 실행이 실제 앱 데이터를 덮어썼다 (관측됨)

**위 205/205 실행은 부작용이 없는 실행이 아니었다.** 드라이버 앞쪽 절이 백업 없이 `Store.save()`를 부르고,
`events.json`의 첫 백업은 J절(`Tools/GuardDriver.swift:1127`)에 있다. `activities.json`의 첫 백업은 Y절에 있다.
그래서 실행할 때마다 이 맥의 macOS 앱 데이터가 픽스처로 덮인다.

| 파일 (`~/Library/Application Support/besir/`) | 수정 시각 (`stat`) | 내용 (제목·날짜만 읽음) | 쓴 실행 |
|---|---|---|---|
| `activities.json` | 14:11:27 | `W-하룻밤` 1건 (2027-03-10 18:00 +09, `googleEventId` 없음) | 오케스트레이터의 205/205 완주 실행 |
| `events.json` | 14:17:35 | `출근`(2026-09-24 14:17:33 +09) · `헬스`(20:17:33) 2건, 둘 다 `recurrenceId` 있음 — `GuardDriver.swift:287-288`의 `drvLeg(… hours: 24/30)`와 일치 | `manager-spec`의 재현 실행(키체인 대기에서 멈춰 종료, exit 143) |

- **14:11 이전 내용은 이 세션에서 알 수도 없고 되살릴 수도 없다.** 전날 t6 레인들이 드라이버를 여러 번
  돌렸으므로 이미 픽스처였을 가능성이 있지만, 확인할 수는 없다.
- **당장의 위험**: `config.json`의 `autoAddToCalendar`가 `true`이고 `W-하룻밤`에는 `googleEventId`가 없다.
  macOS 앱을 실행해 동기화하면 `reconcileActivities` 2-5 단계(`Store.swift:1461-1470`)가 이 시험 활동을
  실제 구글 캘린더에 올릴 수 있다. 2026-09-16 사고와 같은 부류이고, 구글 연결 여부(`:1343`의 가드)는 확인하지 않았다.
  운영자에게 macOS 앱을 실행하지 말라고 알렸다.
- **이후 경과**: 리드에게 사실을 보고했다. 리드는 같은 사실을 직접 확인했다고 회신했다. 리드 회신에 따르면
  운영자 승인을 받아 APFS 13:12 스냅샷에서 원본 복원을 시도하고 있다. **복원은 이 세션이 관측하지 않았다** —
  이 파일을 쓸 때 두 파일의 `stat`은 여전히 14:17:35 / 14:11:27이다. 드라이버 구조 경화는 카드 **t8**로 등록됐다.
  `moai todo`에서 `t8 queued 드라이버 구조적 경화 — …`을 직접 확인했다.
- **새로 컴파일한 드라이버는 끝나지 않을 수 있다.** `manager-spec`이 재현하려고 돌린 실행은
  `Store.updateRecurringSeries` → `googleConnected` → `Keychain.get` → `SecItemCopyMatching`에서 600초 넘게
  CPU 0% 상태로 멈췄다(`sample` 관측). 오케스트레이터가 돌린 실행은 같은 절을 통과해 완주했다.
  두 실행이 왜 달랐는지는 밝히지 못했다.
- 이 카드가 run 단계에 남기는 방어는 `spec.md` REQ-030 (a) · AC-008 (d)다. 드라이버를 실행할 때마다
  ① 키체인 대화상자가 뜰 수 있다고 운영자에게 미리 알리고, ② 앱 데이터 파일 일곱을 백업하고,
  ③ 어떻게 끝나든 복원한 뒤 `cmp`로 대조하며, 실행이 새로 만든 파일은 지운다. 드라이버 코드는 고치지 않는다
  (REQ-021 — t8의 몫이다).

### Gaps — plan이 **돌리지 않은** 것 (증거 없음 ≠ 통과)

- **iOS 빌드 — 미실행.** `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build`
- **macOS 빌드 — 미실행.** `xcodebuild -scheme besir-macOS -derivedDataPath build build`. import 제거
  넷(`ContentView`·`AddActivityView`·`GoogleCalendarService`의 CoreLocation과 `LocationManager` `:3-7`)은 이 빌드에서만 증명된다.
- **프록시 — 미실행.** `cd proxy && npm test`
- **시뮬레이터 · 실기기 — 해당 없음(권고안 기준).** 동작이 바뀌는 자리가 0곳이다. D-1이나 D-3에서 (b)가
  선택되면 실기기 항목이 생기고 Tier M으로 올라간다.
- **페이지 가설 — 미관측.** besir 항목이 250건을 넘는 계정으로 시험한 적이 없다.

### 교차 검증 — 두 측정이 어긋난 자리

`manager-spec`이 넘겨받은 수치를 이 트리에서 다시 쟀다. 오케스트레이터의 값과 다른 것은 셋이었다.

- 드라이버 205/205 — `manager-spec`은 재현하지 못했다(위 키체인 대기). 그래서 `spec.md`는 이 값을
  **오케스트레이터 관측**으로만 인용한다.
- 호스트 경고 — 오케스트레이터의 "12종" 표현은 부정확했다. 실제는 12줄·11곳이다(위 게이트 절).
- 카드에 없던 범위 하나를 `manager-spec`이 찾았다. `openLocationSettings`를 지우면 `LocationManager.swift:3-7`의
  `AppKit`/`UIKit` 조건부 import도 쓰임이 없어진다. 그래서 REQ-010에 포함했다.

오케스트레이터도 `spec.md`의 인용 21곳과 계수 5종을 따로 다시 쟀고, **전부 일치했다**:
`ContentView.swift:154-155`·`:615`·`:648`·`:671`·`:800`·SwipePager 사용처 `:275`·`:336`·`:412`,
`Models.swift:278`·`:326`·`:485`, `project.yml:107`, `Store.swift:97-102`·`:1309`·`:1458`,
SPEC-FULL-001 `acceptance.md:133`·`:139`, CHECKLIST GCS 행 `:221`·`:271`·`:281`·`:448`,
ContentView 행 `:161`·`:255`·`:258`·`:260`·`:262`, `SettingsView.swift:103`. 계수는
`removeFromCalendar(` 10 · `enqueueCalendarUpload(` 8 · `ActivityBlock(title:` 8 ·
LocationManager `lastError` 8 · LocationManager `AppKit|UIKit|NSWorkspace|UIApplication` 5다.

### 미해소 결정 — 착수 승인 게이트에 올린다

- 결정 셋(D-1 `openLocationSettings` · D-2 `updateMeal` · D-3 `deleteExpired`)과 확인 둘(`CLAUDE.md:127` 수정 ·
  Tier S)은 `plan.md` §2에 있다. 미해소 표식은 **`plan.md`에만** 둔다. 그래서 이 파일은 표식 문자열을
  옮겨 적지 않는다. 옮겨 적으면 `grep -rc` 계수(plan.md 3 · 나머지 0)가 이 파일 때문에 깨진다.
- 권고는 (a)(a)(a)다 — 제거 · 유지 + 이유 주석 · 제거. 근거와 선택지별 결과는 `spec.md` §4에 있다.
- 컴패니언 레인은 운영자에게 직접 묻지 않는다. 리드가 게이트에서 제시한다.

### 카드 밖 발견 — 리드가 카드로 올릴지 정할 것

1. `GoogleCalendarService.fetchBesirItems()`가 한 페이지만 받는다(코드를 읽고 세운 가설, 미관측). 일부 페이지만
   받으면 동기화 1단계가 로컬 일정을 "다른 기기에서 삭제됨"으로 보고 지운다. 카드가 "만료 일정 무한 누적"으로
   부른 문제가 실제로 해를 끼치는 경로가 이것이다. `spec.md` §3.
2. `LocationManager.lastError`·`NotificationManager.lastError`는 값을 쓰기만 하고, 읽어서 보여주는 화면이 없다.
   D-1 (b)와 묶인다.
3. 드라이버가 실제 데이터를 덮어쓰고 키체인 대기에서 멈추는 문제 → **t8로 등록됨**(리드).
4. 카드 밖의 데드 코드 후보 두 건: `KoreanHolidays.dates(year:)`(`Models.swift:326`), `MealLog.estimatedCost`(`:485`).
5. 하네스 스킬 `hns-besir-app-hazards`가 `updateMeal`을 데드 코드 후보로 계속 싣고 있다(`.claude/` 수정 사항).
6. `STATUS.md:21`의 "만료 일정 분리 폴더 + 일괄 삭제"는 현재 코드에 없다(`STATUS.md`는 원래 낡은 문서로 지정돼 있다).

### 잔여 위험

- **줄번호 드리프트.** 인용은 `00ab661` 기준이다. run은 `plan.md` §1의 순서대로 파일 아래쪽부터 고쳐야
  윗부분 인용이 끝까지 유효하다. CHECKLIST 드리프트는 이 카드가 sync에서 본문 바이트를 대조해 수리한다.
- **`:176` 이동을 빠뜨리는 실패는 빌드도 드라이버도 잡지 못한다.** 그 실패를 잡는 것은 AC-001의 인접성 검사뿐이다.
- **import 제거는 텍스트로 예측만 했다.** 특히 `LocationManager`의 `ObservableObject`가 어디서 오는지는
  macOS·iOS 빌드가 확정한다.

## §F Phase 4 Mode Selection

**Mode: serial (sub-agent 순차).** 판단 근거는 셋이다.
- plan 단계는 문서 두 개와 실측이라 병렬로 나눌 구간이 없다. 연구 fan-out 스크립트(`FO-PLAN-1`)도 쓰지 않았다 —
  카드 본문이 대상과 줄번호를 이미 지목해 조사 범위가 좁았다.
- run 단계에서 M2와 M3은 같은 `Store.swift`를 고친다. 쓰기 에이전트 둘을 한 워크트리에 동시에 두면 경합만 생긴다.
- 전문가 배정은 `plan.md` §4 그대로다 — M2·M3 `swift-impl` · M4 `code-safety`. (b) 안이 채택되면 `ui-design`이 더해진다.

## §F.1 Phase 11 — 독립 감사

- **1차 시도: 중단, 결과 없음.** `plan-auditor` 서브에이전트가 API 429(세션 사용 한도)로 도중에 끝났다.
  아무 판정도 남기지 않았으므로 통과로도 실패로도 세지 않는다.
- **2차 시도 = 감사 1회차: FAIL, 점수 0.80**(Tier S 기준 0.75). 한도가 풀린 뒤 같은 범위로 새로 띄웠다.
  읽기 전용이었고, 드라이버·`xcodebuild`·`~/Library` 접근은 금지했다.
  - 필수 기준에서 FAIL은 **MP-7 하나**다. `plan.md` §2의 미해소 표식 3개는 착수 게이트용으로 일부러 둔 것이다.
    MP-1(조건부 — 10 단위 묶음 번호), MP-2, MP-3(lint `No findings`), MP-5, MP-6은 PASS이고 MP-4는 N/A다.
    항목별 점수는 명확성 0.75 · 완전성 0.75 · 검증 가능성 0.75 · 추적성 1.0이고, 조화평균이 0.80이다.
  - 인용 재측정 29건: 27건 일치, 1건 표현 부정확(D12 — `GoogleCalendarService` `:185`·`:188`·`:210`은
    `.latitude` 사용이 아니라 생성 인자다. 결론은 맞다), 1건 워크트리에서 경로가 풀리지 않음(D13 — `.claude/`는
    추적 파일이 아니다). 통과 기준으로 쓰는 계수는 **전부 일치**했다.
  - 요구한 수정은 D2~D8이다. 중요한 것은 D2(드라이버가 멈췄을 때 프로세스 종료를 확인하기 전에 복원하면,
    그 뒤에 파일이 다시 덮일 수 있다 — 멈춘 지점 `Store.swift:776`이 `save()` `:771` 뒤다)와
    D3(키체인 대화상자에 어떻게 답할지 정하지 않았다 — 허용하면 실제 구글 계정 경로에 닿을 수 있다.
    이는 도달 가능성 판단이고, 실제 호출은 관측하지 않았다)다. 나머지는 D4(REQ-020 (a) 거절 분기) · D5(REQ-021과
    `~/Library` 복원이 모순) · D6(선택지 본문에 권고 논거가 섞임) · D7(가설을 단정형으로 씀) ·
    D8(AC-003이 빈 `#if os(macOS)` 껍데기를 못 잡음)이다. 선택 수정은 D9~D17이다.
  - 교차 모델: `audit_multi`에서 GLM이 `inconclusive`("no content")를 돌려줘 fail-open으로 처리했다. codex는 off다.
  - 감사자가 확인하지 못한 것: `~/Library` 관측(금지했기 때문), 드라이버 기준선, 호스트 경고 수,
    Google 문서 인용(웹 도구가 없었다).
- **반영**: D2~D15와 D17을 `manager-spec`이 커밋 전에 반영했다. D16(REQ 번호를 연속 정수로 다시 매기기)은
  프로젝트 관례(10 단위 묶음)에 따라 반영하지 않았다.
- **감사 2회차(변경분만 대상): FAIL, 점수 0.92**(1회차 0.80 → 상승). 1회차 감사 에이전트를 이어서 불렀다.
  - 필수 기준 중 FAIL은 여전히 **MP-7 하나**이고, 게이트 전이라 예상한 결과다(표식은 `plan.md:68-70`).
  - D2~D15·D17은 **전부 해소**를 확인했다. D16은 반영하지 않았다(의도).
  - 항목별 점수: 명확성 1.0 · 완전성 1.0 · 검증 가능성 0.75 · 추적성 1.0. REQ 8 / AC 8, 1:1.
  - 수정이 새로 만든 결함은 선택 등급 둘이다. 둘 다 **오케스트레이터가 커밋 전에 직접 반영했다**:
    - N1 — 프로세스 소멸을 `pgrep -f <이름>`으로 확인하면, 기본 이름 `gd`가 `logd`·`configd` 같은 시스템 프로세스에 걸린다.
      실행 때 기록한 PID로 `kill -0`하는 것을 기본 신호로 바꿨다. `pgrep`은 고유 이름 바이너리에 `-fx <전체 경로>`로만 쓴다.
    - N2 — "config.json에 클라이언트 ID가 설정돼 있다"에 출처가 없었다. 오케스트레이터가 관측했다: 키가 있고
      비어 있지 않다(값은 출력하지 않았다). `GuardDriver.swift:1350` 주석(`awk 'NR==1350'`으로 확인)도 인용했다.
  - 반영 뒤 재측정: `grep -c '^- \*\*REQ-' spec.md` = 8 · `grep -c '^#### AC-' spec.md` = 8 ·
    미해소 표식 plan 3 / spec 0 / progress 0 · `moai spec lint` `✓ No findings`.
- **3회차는 착수 승인 게이트 뒤에 한다.** 대상은 결정 내용으로 바뀐 `plan.md` §2이고, (a)가 아닌 안이 나와 고쳐 쓴 REQ/AC가 있으면 그것도 포함한다.
- **착수 승인 게이트 해소(2026-09-23)** — 리드가 운영자의 확정을 전했다: (a)(a)(a) · `CLAUDE.md:127` 승인 · Tier S.
  plan 레인 오케스트레이터가 이를 `plan.md` §2와 `spec.md`(0.1.1)에 기록했다. 다시 쓴 REQ·AC는 없다.
- **감사 3회차(게이트 해소분만 대상): PASS, 점수 0.86** — 필수 기준 7개 모두 PASS이고, MP-7은 표식 0/0/0으로 해소됐다.
  항목별 점수: 명확성 0.75 · 완전성 1.0 · 검증 가능성 0.75 · 추적성 1.0.
  - **STOP 신호**: 2회차 0.92에서 점수가 내려갔고 3회 상한에도 도달했다. 원인은 게이트 기록 편집이 만든 문구 결함이다.
    - R3-1(차단 등급, minor): `CLAUDE.md` 재확인 수단이 정해지지 않았다. "컴패니언은 운영자에게 묻지 않는다"와
      칸반 규칙 "No question delegation"과 충돌하고, GEARS 조건이 여전히 "at the kickoff gate"였다.
    - R3-2(선택): §0 문장이 깨졌다.
    - R3-3(선택): §0에 가정문이 남았다.
  - 감사자는 **PASS-with-debt**를 권했다. 부채는 R3-1이고, run이 M4 전에 닫는다. 범위 축소는 불필요하다고 봤다.
  - **오케스트레이터가 R3-1~R3-3을 감사자가 지정한 문구대로 커밋 전에 반영했다.**
    - GEARS 조건을 "in the run lane's own session immediately before the edit"로 바꿨다.
    - 확인 수단을 둘로 한정했다: 운영자가 run 세션에 직접 입력한 확인, 또는 그 편집의 권한 프롬프트 승인.
      다른 세션을 거친 메시지는 확인으로 치지 않고, 리드에게 블로커로 되묻지도 않는다.
    - 기록 위치는 §E.2로 정했고, AC-006 (1)은 기록이 없으면 FAIL이다.
    - `plan.md` §2 첫 문장을 "게이트 결정을 묻지 않는다"로 좁히고 예외를 명시했다.
  - 기계 확인: `grep -c "착수 승인 운영자가"` = 0 · `grep -c "at the kickoff gate"` = 0 ·
    `grep -c "in the run lane's own session"` = 2(GEARS 줄 + HISTORY) · REQ 8 · AC 8 · 표식 0/0/0 · `moai spec lint` `✓ No findings`.
  - **이 반영은 재감사를 받지 않았다**(3회 상한 — 4회차 없음). PASS-with-debt를 문구 수정으로 닫은 것으로
    받을지, 연장 감사를 할지는 리드가 운영자에게 제시한다.
  - 감사자의 "N1·N2 이월(그대로)" 지적은 사실이 아니다. 둘 다 `924f924` 전에 반영됐다 —
    `grep -n "pgrep" plan.md spec.md`로 보면 `kill -0` 기본 신호와 `pgrep -fx` 한정 문구가 있고,
    "키가 있고 비어 있지 않음" 출처 문구도 두 파일에 각 1건 있다. 감사자가 옛 문구를 기준으로 판단한 것으로 보인다.

## §E.2 Run-phase 실행·운영자 확인 기록

### 드라이버 실행 1회 — REQ-030 (a) 절차 전 항목

- **실행**: 2026-09-23 16:33:06–16:43:06, 바이너리 `/tmp/besir-t5-run/gd_t5_m4`(세션 scratch, 고유 이름 — `pgrep -fx` 안전).
  `b8bbe1c` 트리에서 신선 컴파일(exit 0, 호스트 경고 24줄 — 기준선과 동일한 macOS 26 SDK 사용 중단, 카드 삭제분과 무관).
- **(i) 실행 전 고지·확인**: 키체인 대화상자 가능성(여러 번일 수 있음)과 거부 요청을 고지, 운영자 응답
  **"시작한다 (권장)"** — 이 세션 직접 입력.
- **(ii) 백업**: `~/Library/Application Support/besir/`에서 config.json(288B, mtime 09-09)·events.json(2B)·
  activities.json(2B) → `/tmp/besir-t5-run/backup-run1`(`cp -p`). 없던 것 4종 이름 기록:
  favorites.json·meals.json·deleted_gcal_ids.json·ai_history.json. 참고 — plan 레인이 관측했던 시험 데이터
  (`W-하룻밤`·`출근`·`헬스`)는 16:31에 이미 비워진 상태였다(이 세션은 관측만. 운영자쪽 정리·스냅샷 복원으로
  추정, 이 세션이 확인하지는 못함).
- **(iii) 시간 제한 600초 — 형태 변경 기록**: `perl -e 'alarm shift; exec @ARGV'` 형태는 워크트리 격리 가드가
  거부했다(정적 검증 불가 구조). 우회하지 않고 같은 보장을 가드가 읽는 평문으로 옮겼다: **같은 호출 안**
  `sleep 600 && kill -TERM` 감시자 + 도구 타임아웃 660초. 600초인 이유: 플랜 레인 관측 키체인 대기 행이
  600초 넘게 CPU 0%였으므로 정상 실행이면 이 안에 끝난다고 본 판단.
- **결과**: exit 0, **205/205 통과**, 마지막 불변식 "전체 실행 뒤에도 autoAddToCalendar는 꺼져 있다" ✓.
  로그 265줄, `✗` 0건("실패" 단어 매치 4줄은 전부 `✓`가 붙은 시나리오명 — 201·208·214·216행).
- **종료 시각 모호성**: 종료가 시작+정확히 600초(16:43:06)라 감시자 발화와 동시. exit 0이고 로그 끝에
  요약·불변식 줄이 온전하므로 **완주로 판정**(잘렸다면 이 줄들이 있을 수 없다). 프로세스 소멸 이중 확인:
  `kill -0 19080` 실패 ✓ · `pgrep -fx /tmp/besir-t5-run/gd_t5_m4` 빈 출력 ✓. 다음 드라이버 실행은 감시자를
  900초로 넓일 것을 권고한다(모호성 재발 방지).
- **(iv) 복원 전 확인**: 종료 코드 0 기록(위) → 프로세스 소멸 확인(위). 운영자 대화상자 확인 응답:
  **"모르겠음"** — 등장 여부 미상. 완주했으므로 미응답 대화상자로 멈추지는 않았고, 죽은 PID는 대화상자
  응답으로 되살지 않으므로 복원을 진행했다.
- **(v) 복원(16:45:50)**: 3종 `cp -p` 되돌림 → 파일마다 `cmp` **무출력·exit 0**. 실행이 쓴 내용
  (events.json 408B·activities.json 133B, config.json 무변경)이 2B·2B 실행 직전 상태로 되돌아갔다.
  없던 4종은 실행 뒤에도 없음(`ls` 확인) — 새 파일 삭제 대상 0건.
- **(vi) 키체인 답**: "모르겠음"(위 (iv)). 셋(거부·대화상자 없음·허용) 중 어느 것으로도 확정하지 못했다 —
  구글 연결 여부는 **미상**으로 남는다. 허용으로 볼 근거도 거부로 볼 근거도 없다.

### CLAUDE.md:127 수정 확인 — AC-006 (1)

- 운영자 응답 **"확인 — 교체한다 (권장)"** — 이 세션 AskUserQuestion 직접 입력, 편집 직전
  (REQ-020 (a)의 인정 수단 1번). 권한 프롬프트는 뜨지 않았다(직접 입력으로만 확인됨).
- 교체 실행: `[SettingsView.swift:103](Shared/SettingsView.swift#L103)` →
  `[SettingsView.swift:71](Shared/SettingsView.swift#L71)`. 실측 근거: `:71` = "⚠️ 테스트용 임시 버튼"
  표식 줄, `:103` = `.frame(width: 460)`, 같은 목록의 `AIChatView.swift:56` 인용과 같은 표식-줄 규칙.
  잔존 `SettingsView.swift:103` 인용 0건. **감사 3회차 부채 R3-1(재확인 수단 미정)은 이 기록으로 해소됐다.**

## §E.3 Run-phase Audit-Ready Signal

- run_complete_at: 2026-09-23T16:48+09:00
- run_status: audit-ready
- 구현 커밋: `b8bbe1c`(M2·M3 — Swift 5파일 +2/−50, spec.md `draft → in-progress` 전이 동반) +
  기록 커밋(이 커밋 — CLAUDE.md 인용 교체·§E.2·§E.3)
- **AC 판정**(그레프 신호는 전부 오케스트레이터가 specialist 보고와 별도로 독립 재측정):
  - AC-001 ✓ — `func addActivity(` 0 · `func addActivityWithTravel` 1 · 문서 문장 전체 대조 1 ·
    N=232 / N+1=233 / N+3=235(N+2=`@discardableResult`)
  - AC-002 ✓ — 세 파일 `^import CoreLocation` 0·0·0, 전체 9
  - AC-003 ✓ — `openLocationSettings` 0건 · AppKit/UIKit/NSWorkspace/UIApplication 0 ·
    `^#if os(macOS)` 0(빈 껍데기 없음) · `lastError` 8(변경 전과 동일)
  - AC-004 ✓ — `func updateMeal` 1 · `grep -B1`의 `SPEC-FULL-001` 1. 주석은 한국어로 사유만 서술 —
    code-safety 렌즈 판정 통과(전제를 현 트리에서 재검증: SPEC-FULL-001 `status: in-progress`,
    REQ-003이 `updateMeal` 명시)
  - AC-005 ✓ — `deleteExpired` 0건 · `removeFromCalendar(` 비선언 9
  - AC-006 (1) ✓ — 위 §E.2 확인 기록. (2)~(4)는 sync 레인 소관
  - AC-007 ✓ — `git diff --name-only 00ab661...HEAD` = Swift 정확히 5개 + CLAUDE.md + 이 SPEC 디렉터리.
    새 Swift 파일 0(`xcodegen generate` 불필요 — 돌리지 않았고, 서명 리셋도 없다)
  - AC-008 (a) ✓ 205/205·exit 0·불변식 ✓ (b) ✓ iOS·macOS 둘 다 `BUILD SUCCEEDED`,
    `grep 'warning:' <log> | grep -c '\.swift'` 0·0 (c) ✓ proxy 7/7·exit 0
    (d) ✓ §E.2에 전 항목 기록(드라이버 실행 횟수 1회)
- **code-safety 렌즈(M4)**: 결함 0건 — 렌즈 4개(await 인덱스 무효화·조용히 묻히는 실패·외부 한도·복제 계산)
  전부 실행("검사하지 않은 것 = 실패" 계약 준수). 고아 검사 `removeFromCalendar` 9 · `enqueueCalendarUpload` 7 ·
  `ActivityBlock(title:` 7 — 전부 기대치. `:176` 이동 정확성·삭제 자리 잔해 검사 통과. 관찰 1건
  (CLAUDE.md 이월)은 위 §E.2에 완료 기록.
- **하네스 전문가**: M2·M3 `swift-impl`, M4 `code-safety` — 디스패치 지정 그대로. `ui-design` 0명
  (뷰 파일 셋은 import 한 줄·화면 변화 0 — plan.md §4의 판단 그대로).
- **미관측·갭**: ① 키체인 등장 여부(운영자 "모르겠음" — 연결 여부 미상) ② 시뮬레이터·실기기 실행 —
  권고안 (a)(a)(a)는 동작이 바뀌는 자리 0이라 실기기 전용 항목이 없음(SPEC §3.1 머리말) ③ CHECKLIST
  드리프트 수리·루트 `plan.md:105` 항목 닫기 — sync 소관 ④ 드라이버 완주-감시자 동시 종료의 모호성 —
  완주 증거(요약 줄 존재·exit 0)로 판정, §E.2에 기록
- **드라이버 실행 횟수**: 1회(이 세션). 백업·시간 제한·소멸 확인·복원·cmp·키체인 답 기록 전 회 준수.
