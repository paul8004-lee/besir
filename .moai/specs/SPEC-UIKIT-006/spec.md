---
id: SPEC-UIKIT-006
title: "데드 코드 정리 — 호출부 없는 함수 넷(`Store` 셋·`LocationManager` 하나)과 쓰이지 않는 `import CoreLocation` 셋"
version: "0.1.1"
status: in-progress
created: "2026-09-23"
updated: "2026-09-23"
author: "manager-spec"
priority: P3
phase: "Phase 1.7 — 화면 UI 통일"
module: "shared-core"
lifecycle: spec-anchored
tags: "dead-code, cleanup, store, location-manager, unused-import, doc-citation, follow-up-t6"
tier: S
related_specs: [SPEC-FULL-001, SPEC-UIKIT-005, SPEC-ONTIME-001]
kanban_card: t5
---

# SPEC-UIKIT-006 — 데드 코드 정리 (`Store`·`LocationManager`·`import CoreLocation`)

## HISTORY

| 버전 | 날짜 | 변경 |
|---|---|---|
| 0.1.0 | 2026-09-23 | 최초 작성. 칸반 카드 t5 본문(`moai todo`로 확인한 "확정 7건")을 GEARS로 정식화. **인용 줄번호와 건수는 전부 이 워크트리(`t5`)의 베이스 `00ab661`(= `origin/master`)에서 명령을 돌려 얻었고, 세는 명령을 각 수치 옆에 함께 적었다.** 카드가 적은 줄번호 넷(`Store.swift:178`·`:421`·`:1319`, `LocationManager.swift:118`)은 t3·t6 뒤에도 그대로다 — `git diff --name-only 9e4a374 00ab661 -- Shared/ Tools/`의 일곱 파일에 `Store`·`LocationManager`가 없다. **카드 본문과 실측이 어긋난 자리 넷**을 근거와 함께 적었다: ① `openLocationSettings()`를 지우면 `LocationManager.swift:3-7`의 `AppKit`/`UIKit` 조건부 import가 새로 죽는다(§2.2 REQ-010) ② `SettingsView` 테스트 블록의 끝은 카드의 `:84`가 아니라 `:86`이다(REQ-020) ③ `updateMeal`을 남길 근거는 카드의 "곧 사용할 가능성"이 아니라 진행 중인 SPEC의 요구사항이다(§4 D-2) ④ `deleteExpired`의 "휴면 결함: 만료 일정 무한 누적"은 누적 자체가 결함이 아니고, 가능한 피해 경로는 다른 곳에 있다(가설, 미관측 — §4 D-3, §3 Out of Scope). 가드 드라이버 기준선 205/205는 **오케스트레이터가 이 트리에서 돌린 값**이고 이 plan 레인은 재현하지 못했다(§0). "가드 드라이버가 이 맥의 실제 besir 데이터에 쓴다"는 발견은 처음에 코드 읽기 가설로 적었으나, 커밋 전에 오케스트레이터가 실제 데이터 파일을 읽어(제목·날짜만, 수정 없음) **관측으로 확정**됐다 — 그래서 드라이버를 돌릴 때마다 백업·`cmp` 복원 절차를 REQ-030 (a)·AC-008 (d)에 박았다(§3 Out of Scope). **커밋 전 plan-audit 1회차(0.80, must-pass 실패는 의도된 게이트 표식의 MP-7 하나) 지적 D2~D15·D17을 반영했다** — 드라이버 실행의 시간 제한·프로세스 소멸 확인·키체인 답(거부) 지정, REQ-020 (a)의 조건화, REQ-021의 저장소 경로 한정과 예외 셋, §4의 선택지와 권고 근거 분리, 가설 문장의 표기, AC 신호 보강(빈 `#if` 껍데기·문장 전체 대조), `<base>` = `00ab661` 고정, 요구사항 유형 표기 정정. D16(REQ 번호 재배열)은 10단위 블록이 프로젝트 관례라 반영하지 않았다 |
| 0.1.1 | 2026-09-23 | **착수 승인 게이트 해소.** 운영자가 다섯 항목을 모두 권고안으로 확정했다(리드가 plan 레인에 전달). D-1 (a) 제거(`:3-7` import 포함) · D-2 (a) 유지 + 이유 주석 · D-3 (a) 제거 · `CLAUDE.md:127` 수정 승인 · Tier S 확정. §4 머리말과 D-1~D-3 제목을 해소 문구로 바꾸고, §2.2 머리말·§3.1 머리말·§0·REQ-020 (a)의 대기 문구를 결정 사실로 바꿨다. **다시 쓴 REQ·AC는 없다**(세 `Where` 조건이 모두 권고안 그대로 성립한다). REQ 8 · AC 8은 그대로이고, 인용 줄번호도 바뀌지 않았다(코드는 아직 한 줄도 안 바뀌었다). `CLAUDE.md` 승인은 다른 세션을 거쳐 전달됐으므로, run 레인이 편집 직전에 자기 세션에서 운영자에게 다시 확인받는다는 절을 REQ-020 (a)에 더했다. frontmatter `status`는 `draft`로 둔다 — `draft → in-progress` 전이는 run 단계의 몫이다. §4 "결정 조합과 Tier" 문단도 확정 문구로 바꿨다. **plan 감사 3회차는 PASS 0.86이다**(2회차 0.92보다 낮고, 3회 상한에 도달해 STOP 신호가 났다). 하락 원인인 R3-1(`CLAUDE.md` 재확인 수단이 정해지지 않았고 "컴패니언은 묻지 않는다"와 충돌)·R3-2(§0의 깨진 문장)·R3-3(§0 가정문)은 감사자가 지정한 문구대로 커밋 전에 반영했다. GEARS 조건을 "in the run lane's own session immediately before the edit"로 바꿨고, 확인 수단은 둘(직접 입력 · 권한 프롬프트 승인)로 한정했으며, 기록 위치는 `progress.md` §E.2이고 AC-006 (1)에 기록 요구를 더했다. **이 반영은 재감사를 받지 않았다**(4회차 없음) |

## 0. 이 SPEC의 성격과 예산

**as-built 베이스라인이 아니라 구현을 앞둔 변경의 계약이다.** 원본은 칸반 카드 t5 본문이다. 인용 줄번호는 변경 전 상태(`00ab661`) 기준이라 구현 중 밀린다 — 밀릴 때마다 실측 재정렬한다. 이 문서의 `<base>`는 전부 `00ab661`이다.

**거의 전부 삭제다.** 권고안(§4의 세 결정을 모두 (a)로)대로 가면 run이 하는 일은 삭제 49줄(함수·문서·import와 뒤따르는 빈 줄), 문서 한 줄 이동, 이유 주석 한 줄 추가, `CLAUDE.md` 인용 한 줄 교체다. 줄 수의 셈과 명령은 `plan.md` §0에 있다. 동작이 바뀌는 자리는 0곳이다 — 지우는 넷은 호출부가 0이고, import 셋은 그 파일에서 CoreLocation 심볼을 한 번도 쓰지 않는다.

**Tier: S.** 설계 판단이 들어가는 자리가 없고 삭제 위주 약 50줄이다. 다만 권고안에서 run이 건드리는 파일은 **여섯**이다. 주 체크아웃의 `.claude/rules/moai/workflow/spec-workflow.md:140-141` 표에서 Tier S의 파일 기준은 "< 5 files", Tier M은 "5 - 15 files"이므로 여섯은 **Tier M의 파일 범위**이고, `Shared/*.swift` 다섯만으로도 이미 "5개 미만"을 벗어난다. 그래도 S로 두는 판단은 줄 수에 있다 — 여섯 중 셋은 import 한 줄, `CLAUDE.md`는 인용 한 줄이라 파일 수가 작업량을 과장한다. 운영자가 착수 승인 게이트에서 이 판단을 확정했다(2026-09-23, `plan.md` §2). **§4 D-1 또는 D-3에서 (b)(연결)를 고르면 기능이 생기고 화면 설계가 들어오므로 Tier M으로 올려 `acceptance.md`를 따로 세워야 한다.**

**REQ·AC 예산 — 둘 다 Tier S 상한(8)과 같다.** 세는 명령은 `grep -c '^- \*\*REQ-' spec.md` = **8**, `grep -c '^#### AC-' spec.md` = **8**이다: §2.1 2건(001·002) · §2.2 3건(010~012) · §2.3 2건(020·021) · §2.4 1건(030). REQ와 AC가 1:1이다. 여유가 0이므로, 게이트가 권고와 다른 안을 골라 요구사항이 늘었다면 이 등급 안에 둘 자리가 없었다 — 그것도 tier-up 신호였다. 게이트가 (a)(a)(a)로 정해 해당하지 않는다(2026-09-23).

**가드 드라이버 기준선 — 이 plan 레인의 실측이 아니다.** 오케스트레이터가 이 트리(`00ab661`)에서 이 워크트리 `CLAUDE.md` § 빌드 · 배포의 블록을 돌려 **205/205 통과, exit 0**, 마지막 불변식 "전체 실행 뒤에도 autoAddToCalendar는 꺼져 있다" ✓를 얻었다. 이 plan 레인은 같은 컴파일 집합으로 새로 컴파일해(출력 경로만 세션 scratchpad) 돌렸으나 **끝나지 않았다** — 600초 시점에 CPU 0%로 잠들어 있었고, `sample`로 본 메인 스레드는 `AIAssistant.executeUpdateRecurringSchedule` → `Store.updateRecurringSeries` → `Store.googleConnected.getter` → `Keychain.get` → `SecItemCopyMatching`에서 키체인 응답을 기다리고 있었다. 새로 컴파일한 바이너리가 키체인 접근 확인을 받는 중이었던 것으로 보고 프로세스를 종료했다(exit 143, 표준출력 버퍼는 비어 있었다). **종료 전에 이미 실제 `events.json`을 썼다**(14:17, §3 Out of Scope). 따라서 205/205는 **오케스트레이터의 관측**으로만 인용한다. **그 기준선 실행도 부작용이 없는 실행이 아니었다** — 14:11에 실제 `activities.json`을 시험 활동 `W-하룻밤` 한 건으로 남겼다(§3 Out of Scope). **그 실행의 키체인 상태는 미상이다** — 오케스트레이터는 대화상자를 보지 못한 채 완주했고, 대화상자가 떴다가 누군가 답했는지, 아예 뜨지 않았는지는 알 수 없다. 마지막 불변식(`autoAddToCalendar` 꺼짐)은 구글 연결 여부를 말해 주지 않는다. run 레인은 자기 트리에서 다시 재야 하고, REQ-030 (a)의 절차대로 돌린다(`plan.md` §3).

## 1. 배경

### 1.1 카드가 정한 범위 — 확정 7건 (실측 대조)

| 항목 | 위치 (`00ab661`) | 호출부 | 세는 명령 |
|---|---|---|---|
| `Store.addActivity(title:location:startDate:endDate:syncToCalendar:)` | 문서 `:177`, 함수 `:178-188` | 0 | `grep -rn "addActivity(" Shared/ ShareExtension/ Tools/` → 선언 한 줄뿐 |
| `Store.updateMeal(_:)` | `:421-426` | 0 | `grep -rn "updateMeal(" Shared/ ShareExtension/ Tools/` → 선언 한 줄뿐 |
| `Store.deleteExpired()` | 문서 `:1318`, 함수 `:1319-1332` | 0 | `grep -rn "deleteExpired" Shared/ ShareExtension/ Tools/` → 선언 한 줄뿐 |
| `LocationManager.openLocationSettings()` | `:118-128` | 0 | `grep -rn "openLocationSettings" Shared/ ShareExtension/ Tools/` → 선언 한 줄뿐 |
| `import CoreLocation` — `ContentView.swift` | `:2` | CL 심볼 0 | `grep -c '\bCL[A-Z][A-Za-z0-9]*' Shared/ContentView.swift` = **0** |
| `import CoreLocation` — `AddActivityView.swift` | `:2` | CL 심볼 0 | 같은 명령 = **0** |
| `import CoreLocation` — `GoogleCalendarService.swift` | `:4` | CL 심볼 0 | 같은 명령 = **0** |

`import CoreLocation`을 가진 파일은 `grep -l "^import CoreLocation" Shared/*.swift | wc -l` = **12**이고, 위 셋을 뺀 아홉은 모두 CL 심볼을 쓴다(같은 `grep -c` 값: `ActivityDetailView` 2 · `AddEventView` 6 · `AIAssistant` 2 · `EventDetailView` 4 · `FullSirView` 3 · `KakaoMapView` 3 · `LocationManager` 15 · `Models` 1 · `Store` 9). 셋을 지우면 12 → **9**다.

카드 분석 트리(`9e4a374`) 이후 바뀐 파일 일곱(`git diff --name-only 9e4a374 00ab661 -- Shared/ Tools/` → `AIAssistant`·`ActivityDetailView`·`AddActivityView`·`AddEventView`·`EditCard`·`EditCardView`·`EventDetailView`)에서 함수 이름이 `Shared/`·`ShareExtension/`·`Tools/` 전체에 한 번만 나오는 것을 셌더니 **1건** — `placeSubviews`(`EditCardView.swift:492`)이고, `struct ChipFlow: Layout`(`:482`)의 프로토콜 요구사항이라 오탐이다. t3·t6가 이 방법으로 잡히는 새 데드 함수를 남기지 않았다. **방법의 한계**: 이름 빈도만 보므로 프로토콜 요구사항·오버로드·동적 호출은 가르지 못한다.

### 1.2 `addActivity`의 문서 자리에 숨은 함정 (실측)

```
$ awk 'NR>=176 && NR<=178 {print NR": "$0}' Shared/Store.swift
176:     /// 여러 요일에 반복되는 활동 블록(수업·근무·점심 등)을 한 번에 생성한다. 이동시간 계산은 없다.
177:     /// 반복 없는 단발성 활동 블록 하나를 추가한다("+" 메뉴에서 수동으로 만드는 경우).
178:     func addActivity(title: String, location: Place?, startDate: Date, endDate: Date,
$ awk 'NR>=246 && NR<=248 {print NR": "$0}' Shared/Store.swift
246:     /// recurrenceId를 공유하는 ScheduledEvent(이동 구간)와 같이 묶여 일괄 삭제된다.
247:     @discardableResult
248:     func addRecurringActivities(title: String,
```

**`:176`은 `addActivity`의 문서가 아니다.** "여러 요일에 반복되는" 활동을 만드는 함수는 `addRecurringActivities`(`:248`)이고, 그 문서는 지금 `:246` 한 줄만 남아 있다 — "~와 같이 묶여 일괄 삭제된다"는 주어가 없는 문장이다. `:176`은 그 문서의 첫 줄이 어느 시점에 `addActivity` 위로 밀려난 것이다. **`:176-188`을 통째로 지우면 `addRecurringActivities`의 문서 첫 줄이 사라지고, 빌드도 드라이버도 그것을 잡지 못한다.** 그래서 REQ-001은 삭제가 아니라 이동을 요구한다.

`:177`이 말하는 호출 자리("+" 메뉴)도 이미 다른 함수를 부른다. "+" 메뉴의 활동 시트는 `AddActivityView`이고(`ContentView.swift:154-155`, `grep -n "AddActivityView(" Shared/*.swift` → 그 한 곳), 그 화면은 `addActivityWithTravel`을 부른다(`AddActivityView.swift:524`). `addActivityWithTravel`(`Store.swift:203`)의 호출부는 셋이다 — `FullSirView.swift:463` · `AIAssistant.swift:1511` · `AddActivityView.swift:524`(`grep -rn "addActivityWithTravel" Shared/ ShareExtension/ Tools/`).

지워도 고아가 생기지 않는다. `addActivity`가 쓰던 둘은 다른 곳에서도 쓰인다 — `enqueueCalendarUpload(`의 비선언 호출 줄은 `grep -rn "enqueueCalendarUpload(" Shared/ | grep -v "func " | wc -l` = **8**(그중 `:186` 하나가 이 함수 안), `ActivityBlock(title:` 생성 자리는 `grep -rn "ActivityBlock(title:" Shared/ Tools/ | wc -l` = **8**(그중 `:180` 하나가 이 함수 안)이다.

### 1.3 import 제거가 컴파일된다는 텍스트 증거 — 증거일 뿐 증명은 아니다

- `project.yml:13` `SWIFT_VERSION: "5.0"`이고, `MemberImportVisibility`·upcoming feature 플래그가 없다(`grep -n "SWIFT_VERSION\|MemberImportVisibility\|upcoming" project.yml` → `:13` 한 줄).
- `GoogleCalendarService`에서 좌표를 **읽는** `.latitude`·`.longitude`(`:70`·`:157-158`·`:162`)는 `Place`의 `Double` 필드이고, `:185`·`:188`·`:210`의 `latitude:`·`longitude:`는 `Place(… latitude:longitude:)` 생성자의 인자 이름이다(`Models.swift:110` `struct Place`, 필드 `:113-114`). 어느 쪽도 CoreLocation 타입이 아니다(`grep -n "latitude\|longitude" Shared/GoogleCalendarService.swift`).
- 세 파일에서 `kCL` 접두 상수나 `coordinate`·`MapKit`도 0건이다(`grep -n "kCL\|CLLocation\|CLGeocoder\|CLPlacemark" …`, `grep -n "coordinate\|\.distance(\|MKMapPoint\|MapKit" …` 모두 exit 1).

**구속력 있는 증거는 빌드다**(REQ-030). 가드 드라이버의 컴파일 집합에는 `GoogleCalendarService.swift`가 들어 있지만(호스트 `swiftc`), `ContentView.swift`·`AddActivityView.swift`는 들어 있지 않다 — 이 둘은 `xcodebuild`만이 증명한다.

### 1.4 결정이 걸린 세 건의 근거 (실측)

**`openLocationSettings()`** — iOS는 `UIApplication.openSettingsURLString`(`:124-125`), macOS는 시스템 설정 URL(`:120-121`)을 연다. `CHECKLIST.md:277`(L9 위치 권한 거부)이 ⚠️ "안내 문구는 나옴(:1325·:2110)지만 설정 연결 없음"이고, 그 두 문구는 `AIAssistant.swift:1325`·`:2110`의 채팅 답이다. `FullSirView.swift:101`도 "위치 권한이 필요해요"를 글자로만 보인다. 설정으로 가는 경로는 앱 어디에도 없다.

**이 함수가 `LocationManager`의 `AppKit`/`UIKit` import를 쓰는 유일한 자리다.**

```
$ awk 'NR>=1 && NR<=7 {print NR": "$0}' Shared/LocationManager.swift
1: import Foundation
2: import CoreLocation
3: #if os(macOS)
4: import AppKit
5: #else
6: import UIKit
7: #endif
$ grep -n '\bNS[A-Z][A-Za-z]*\|\bUI[A-Z][A-Za-z]*' Shared/LocationManager.swift
6:import UIKit
12:final class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
121:            NSWorkspace.shared.open(url)
124:        if let url = URL(string: UIApplication.openSettingsURLString) {
125:            UIApplication.shared.open(url)
160:            if (error as NSError).code == CLError.locationUnknown.rawValue { return }
$ grep -n '#if' Shared/LocationManager.swift
3:#if os(macOS)
29:        #if os(iOS)
83:            #if os(iOS)
119:        #if os(macOS)
```

`NSObject`(`:12`)·`NSError`(`:160`)는 Foundation 소속이다. 함수를 지우면 `:3-7`이 할 일이 없어진다 — 카드가 적지 않은 범위다. `ObservableObject`(`:12`)는 Combine 소속인데, 같은 트리의 `NotificationManager.swift`가 `Foundation`·`UserNotifications`만 import하고 `ObservableObject`를 쓰며 빌드되므로 Foundation이 공급한다는 텍스트 증거가 있다(`grep '^import'`로 대조). 이것도 빌드가 확정한다. 네 `#if` 중 줄 맨 앞에서 시작하는 것은 `:3` 하나다(`grep -c '^#if os(macOS)' Shared/LocationManager.swift` = **1**) — `:119`는 지울 함수 안이고, `:29`·`:83`은 남는 코드다.

**`updateMeal(_:)`** — 남길 근거가 실재한다. `SPEC-FULL-001`은 `status: in-progress`이고(그 `spec.md` frontmatter `:5`), REQ-003(`.moai/specs/SPEC-FULL-001/spec.md:60`)이 `addMeal`/`updateMeal`/`deleteMeal`/`recentMeals(limit:)`를 `Store`가 갖춰야 할 연산으로 적었으며, 그 `acceptance.md`의 AC-113(`:133-139`)이 `updateMeal`의 동작("`id` 일치 레코드를 찾아 교체 + 저장")을 검증 대상으로 적었다. 형제 연산의 호출부는 `addMeal` 3 · `deleteMeal` 1 · `recentMeals` 1이다(`grep -rn "<이름>(" Shared/ | grep -v "func " | wc -l`). 반면 루트 `plan.md`에서 `updateMeal`은 `:206`(Day 6 완료 기록) 한 번뿐이라, 이 연산을 부를 화면을 계획한 흔적은 없다.

**`deleteExpired()`** — 연결했을 때의 동작을 코드로 읽으면(`:1319-1332`): `arrivalDate < now`인 일정을 전부 로컬에서 지우고(`:1325`), 그 알림을 끄고(`:1322-1324`), 저장하고(`:1326`), **구글 캘린더에도 삭제를 보낸다**(`:1328-1331`, `removeFromCalendar` → 묘비 경로 `:97-102`). `activities`는 건드리지 않는다.

지난 일정은 **보이도록 설계된 이력**이다. `ContentView.swift:648` `let past = event.arrivalDate < Date()`와 `:671` `.opacity(past ? 0.45 : 1)`이 흐리게 그리고, 활동 쪽 `:615`의 주석이 "지나간 일정은 흐리게 — 남은 일정이 먼저 눈에 들어오도록"이라고 이유를 적었다. 사용자는 `SwipePager`(`:800`, 사용처 `:275`·`:336`·`:412`)와 월간 그리드로 지난 날짜에 간다. 연결하면 이력이 로컬과 구글 캘린더 두 곳에서 지워지고, **앱 안에서는 되돌릴 방법이 없다**(구글 캘린더 휴지통으로 복구되는지는 확인하지 않았다).

지난 결정과 그 전제: 루트 `plan.md:105`가 "알고도 안 고친 것: `Store.deleteExpired()`(호출부 없지만 정상 동작하는 공개 API, 나중에 UI에서 쓸 것)"라고 적었다. 그 전제("나중에 UI에서 쓸 것")를 확인했다:

- 계획된 UI가 없다 — `grep -n "deleteExpired\|만료\|지난 일정" plan.md` → `:87`(삭제 경로 통일 이력)과 `:105` 자신뿐.
- `STATUS.md:21`은 "만료 일정 분리 폴더 + 일괄 삭제"가 있다고 적었지만 지금 코드에는 그런 UI가 없다 — `grep -rn "만료\|지난 일정" Shared/*.swift` → `Store.swift:1318`·`:1327`의 주석과 `GoogleCalendarService.swift:242`·`:250`의 토큰 만료 주석 둘뿐이다. `STATUS.md`는 `CLAUDE.md`가 낡았다고 명시한 문서다.
- git 이력 시작부터 호출부가 없다 — `git log -S "deleteExpired()" --format="%h %ad %s" --date=short -- Shared/` → `d3c9327 2026-09-12 최초 커밋` 한 줄뿐이고, `git grep -n "deleteExpired" d3c9327 -- Shared/` → `Store.swift:1106` 선언 한 줄뿐이다. 이 함수를 부르던 화면이 이력 이전에 있다가 걷혔는지(`STATUS.md:21`의 서술이 그 흔적일 수 있다), 처음부터 없었는지는 이 트리로 가를 수 없다.

## 2. 요구사항 (GEARS)

### 2.1 즉시 제거군 (001번대)

- **REQ-001 (Unwanted)**: The `Store` shall not carry the caller-less single-activity creator, and the doc line displaced above it shall return to `addRecurringActivities`. `addActivity(title:location:startDate:endDate:syncToCalendar:)`의 문서 `:177`·함수 `:178-188`과 뒤따르는 빈 줄 `:189`를 지우고, `:176`은 지우지 않고 `:246` 바로 위로 **옮긴다**. 근거: §1.1·§1.2.
  - 기계적 신호: `grep -c "func addActivity(" Shared/Store.swift` = **0** · `grep -c "func addActivityWithTravel" Shared/Store.swift` = **1** · `grep -cF "/// 여러 요일에 반복되는 활동 블록(수업·근무·점심 등)을 한 번에 생성한다. 이동시간 계산은 없다." Shared/Store.swift` = **1**(문장 전체 대조 — 잘린 채 옮기면 0이 된다. `00ab661`에서도 1). 그리고 `grep -n "여러 요일에 반복되는 활동 블록\|recurrenceId를 공유하는 ScheduledEvent\|func addRecurringActivities" Shared/Store.swift`의 세 줄번호가 `N`, `N+1`, `N+3`이다(`N+2`는 `@discardableResult`).

- **REQ-002 (Unwanted)**: `ContentView.swift`, `AddActivityView.swift`, and `GoogleCalendarService.swift` shall not import CoreLocation. 각 파일의 `:2`·`:2`·`:4` 한 줄씩이다. 근거: §1.1 표(세 파일의 CL 심볼 0건)·§1.3.
  - 기계적 신호: `grep -c "^import CoreLocation" Shared/ContentView.swift Shared/AddActivityView.swift Shared/GoogleCalendarService.swift`가 세 파일 모두 **0**, `grep -l "^import CoreLocation" Shared/*.swift | wc -l` = **9**.

### 2.2 게이트에서 정하는 세 건 (010번대)

> 이 절의 세 REQ는 §4 결정의 **권고안**으로 적었다. `Where` 절이 착수 승인 게이트의 결정을 조건으로 건다. **게이트가 세 건 모두 (a)로 해소했으므로(2026-09-23) 세 `Where` 조건이 모두 성립한다** — REQ-010·REQ-012는 제거, REQ-011은 유지 + 이유 주석이다. 다시 쓴 REQ는 없고, Tier는 S 그대로다.

- **REQ-010 (Where — D-1)**: Where the kickoff gate resolves D-1 to removal, the `LocationManager` shall carry neither `openLocationSettings()` nor the platform UI-framework import that only that function used. 함수 `:118-128`과 뒤따르는 빈 줄 `:129`, 그리고 `#if os(macOS) import AppKit #else import UIKit #endif`(`:3-7`)를 **다섯 줄 모두** 지운다. 근거: §1.4 — 두 프레임워크의 사용처가 이 함수 안의 `NSWorkspace`(`:121`)·`UIApplication`(`:124-125`)뿐이다. 함수만 지우고 import를 남기면, REQ-002에서 지우는 것과 같은 종류의 죽은 import를 이 카드가 새로 만든다. import 두 줄만 지우고 `#if`/`#else`/`#endif`를 남기면 빈 껍데기가 남는다.
  - 기계적 신호: `grep -rn "openLocationSettings" Shared/ ShareExtension/ Tools/`가 **0건**, `grep -c "^import AppKit\|^import UIKit\|NSWorkspace\|UIApplication" Shared/LocationManager.swift` = **0**(`00ab661`에서 5), `grep -c '^#if os(macOS)' Shared/LocationManager.swift` = **0**(`00ab661`에서 1 — `:3`).
  - **`LocationManager.lastError`는 건드리지 않는다**(REQ-021, §3 Out of Scope).

- **REQ-011 (Where — D-2)**: Where the kickoff gate resolves D-2 to retention, `Store.updateMeal(_:)` shall stay, carrying a one-line comment that names SPEC-FULL-001 REQ-003 as the reason it survives with zero callers. 함수 `:421-426`은 그대로 두고 바로 위에 한국어 한 줄로 **왜 남는지**를 적는다. 근거: §1.4 — 진행 중인 SPEC의 요구사항이 이 연산을 명시한다. 주석이 없으면 다음 전수 분석이 이것을 또 후보로 올린다(`hns-besir-app-hazards` 스킬이 이미 "zero callers" 후보로 싣고 있다 — §3 Out of Scope).
  - 기계적 신호: `grep -c "func updateMeal" Shared/Store.swift` = **1**, `grep -B1 "func updateMeal" Shared/Store.swift | grep -c "SPEC-FULL-001"` = **1**.

- **REQ-012 (Where — D-3)**: Where the kickoff gate resolves D-3 to removal, the `Store` shall not carry `deleteExpired()`. 문서 `:1318`·함수 `:1319-1332`와 뒤따르는 빈 줄 `:1333`을 지운다. 근거: §1.4·§4 D-3의 권고 근거.
  - 지워도 `removeFromCalendar`는 살아 있다 — 비선언 호출 줄 `grep -rn "removeFromCalendar(" Shared/ | grep -v "func " | wc -l` = **10**, 그중 `:1330` 하나가 이 함수 안이므로 9곳이 남는다.
  - 기계적 신호: `grep -rn "deleteExpired" Shared/ ShareExtension/ Tools/`가 **0건**.

### 2.3 문서 인용과 범위 경계 (020번대)

- **REQ-020 (Ubiquitous · (a)는 Where)**: The project documents' line citations into the files this card changes shall resolve to the cited content on the final tree; where the operator confirms the `CLAUDE.md` edit in the run lane's own session immediately before the edit, `CLAUDE.md`'s citation of the settings test block shall also resolve to that block's marker line. 두 부분이다:
  - (a) **`CLAUDE.md:127`** — `[SettingsView.swift:103](Shared/SettingsView.swift#L103)`을 `[SettingsView.swift:71](Shared/SettingsView.swift#L71)`로 고친다. 실측: 블록은 `:71-86`이다 — `⚠️` 표식 주석 `:71`, `VStack` `:72-81`, `.confirmationDialog` `:82-86`(상태 `@State private var showingWipe`는 `:11`). 지금의 `:103`은 `.frame(width: 460)`이다(`awk 'NR==103' Shared/SettingsView.swift`). 카드가 적은 "71-84"는 끝이 `:86`이다. **`:71`(표식 줄)을 고르는 이유**: 바로 아래 `CLAUDE.md:128`의 `AIChatView.swift:56`이 그 파일의 `⚠️` 표식 줄을 가리키고 실측으로 맞다(`grep -n "테스트용 임시" Shared/*.swift` → `AIChatView.swift:56`·`SettingsView.swift:71`). 같은 목록의 두 인용이 같은 규칙을 따른다. `CLAUDE.md`는 프로젝트 지시 파일이므로 **이 수정은 착수 승인 게이트에서 운영자가 명시적으로 확인해야 한다** — 리드 디스패치만으로는 권한이 생기지 않는다(`plan.md` §2). 게이트 결과(2026-09-23): 리드가 운영자의 승인을 전했다. 그 확인이 다른 세션을 거쳐 왔으므로, run 레인은 이 줄을 고치기 직전에 자기 세션에서 운영자에게 한 번 더 확인받는다. **확인으로 치는 수단은 둘뿐이다**: 운영자가 run 세션에 직접 입력한 확인, 또는 그 편집에 뜨는 권한 프롬프트를 운영자가 승인하는 것. 리드나 다른 세션을 거친 메시지는 확인으로 치지 않는다. run 레인은 이 확인을 위해 리드에게 블로커 보고로 되묻지 않는다 — 되물으면 또 다른 세션을 거친 승인이 되어 이 절의 목적이 무너진다. 수단과 결과는 `progress.md` §E.2에 적는다. **거절하면 (a)와 AC-006 (1)을 뺀다**(run 파일은 다섯이 된다).
  - (b) **`CHECKLIST.md` 드리프트** — 이 카드가 만든 드리프트는 이 카드가 sync에서 수리한다. 파일 앵커 인용 수(`grep -o "<파일>.swift:[0-9]*" CHECKLIST.md | wc -l`): `Store.swift` **33**(그중 `:176`보다 뒤인 것 `grep -o "Store.swift:[0-9]*" CHECKLIST.md | sed 's/.*://' | awk '$1>176' | wc -l` = **25**) · `GoogleCalendarService.swift` **4**묶음(`CHECKLIST.md:221`·`:271`·`:281`·`:448`, 전부 `:4` 뒤라 −1씩 밀린다) · `ContentView.swift` **5**묶음(`:161`·`:255`·`:258`·`:260`·`:262`, 전부 `:2` 뒤라 −1씩) · `LocationManager.swift` 0 · `AddActivityView.swift` 0. 앵커 뒤에 이어 붙은 맨 `:N` 인용도 함께 밀린다. 같은 수정에서 **기존 오인용 1건**을 고친다 — L3 줄(`CHECKLIST.md:271`)이 `GoogleCalendarService.swift:124-125·:1360-1364`를 인용하지만 그 파일은 415줄이다(`wc -l`). 뜻한 대상은 `Store`의 동기화 2-4 단계(알림 해제 루프, `grep -n "clearReminders" Shared/Store.swift` → `:1458`)로 보이나, **대상은 sync 레인이 문맥을 읽고 정한다.** 루트 `plan.md`·`CLAUDE.md`·`STATUS.md`에는 이 다섯 파일의 파일 앵커 인용이 0건이다(같은 `grep -o` 명령).
  - D-3이 (a)로 해소되면 루트 `plan.md:105`의 "알고도 안 고친 것" 항목이 닫혔다고 sync에서 적는다. `plan.md:87`은 지난 버그 수정의 이력이라 고치지 않는다.

- **REQ-021 (Unwanted)**: This SPEC shall not modify any repository path outside its declared files. 저장소 경로 기준이다. run: `Shared/Store.swift` · `Shared/LocationManager.swift`(D-1이 (a)일 때만) · `Shared/ContentView.swift` · `Shared/AddActivityView.swift` · `Shared/GoogleCalendarService.swift` · `CLAUDE.md`(REQ-020 (a)가 확인됐을 때만). sync: `CHECKLIST.md` · 루트 `plan.md` · 이 SPEC 디렉터리. 특히 **무변경**: `LocationManager.lastError` · `NotificationManager.lastError` · `GoogleCalendarService.fetchBesirItems()`의 페이지 처리 · `Store.deleteEverythingForTesting()` · `AIAssistant.transcriptForDebugging()` · `KoreanHolidays.dates(year:)` · `MealLog.estimatedCost` · `Tools/GuardDriver.swift` · `STATUS.md`.
  - **선언된 예외 셋** — 저장소 밖이거나 run 단계의 기록이다. (1) `~/Library/Application Support/besir/`의 복원·삭제 — REQ-030 (a)의 절차가 실행 직전 상태로 되돌리는 일이고, 새 내용을 쓰지 않는다. (2) 세션 scratch 디렉터리 — 백업 사본과 실행 로그. (3) 이 SPEC 디렉터리의 run 단계 기록(`progress.md`) — AC-008 (d)의 기록은 `progress.md` §E.2에 남긴다.
  - **`.claude/`는 이 경계의 신호로 잴 수 없다.** git이 추적하지 않아(`git ls-files .claude | wc -l` = **0**) AC-007의 `git diff`가 보지 못한다. 하네스 스킬·규칙 파일은 주 체크아웃의 `.claude/` 아래 있고 이 카드는 건드리지 않지만, 그 사실은 선언으로만 둔다.
  - **새 소스 파일을 만들지 않는다** — 따라서 `xcodegen generate`가 필요 없고, 서명 계정 리셋도 `besir-iOS`·`besirShare` 두 타깃의 Team 재선택 요청도 없다.
  - 기계적 신호: `git diff --name-only 00ab661...HEAD -- 'Shared/*.swift'`가 **정확히 5개**(D-1이 (a)가 아니면 4개), `git diff --name-only --diff-filter=A 00ab661...HEAD -- 'Shared/*.swift'`가 **0건**.

### 2.4 게이트 (030번대)

- **REQ-030 (Ubiquitous)**: The change shall keep the argument-guard driver green, build on iOS and macOS with zero Swift-source warnings, and pass the proxy tests. 세 절:
  - (a) **가드 드라이버 전체 초록.** 이 워크트리 `CLAUDE.md` § 빌드 · 배포의 블록이 단일 출처다. 그 컴파일 집합에 `Store.swift`·`LocationManager.swift`·`GoogleCalendarService.swift`가 들어 있으므로 이 카드가 고치는 다섯 소스 중 셋이 드라이버를 통과해야 한다. 인자 거동은 바뀌지 않으므로 `Tools/GuardDriver.swift`의 단언은 그대로다. 기준선은 오케스트레이터 관측 **205/205, exit 0**이다(§0 — 이 plan 레인은 재현하지 못했고, 그 실행의 키체인 상태는 미상이다).
    - **이 카드에서 드라이버를 돌릴 때마다 지키는 절차(필수).** 드라이버가 실제 데이터에 쓴다는 것이 관측됐으므로(§3 Out of Scope) 실행 하나하나를 아래 단계로 감싼다. 드라이버를 고치는 것이 아니라 돌리는 방식이므로 REQ-021은 그대로다(예외 (1)·(2)).
      - (i) **바이너리를 실행하기 전에** 운영자에게 알린다: 키체인 접근 대화상자가 뜰 수 있고(§0의 관측, 여러 번 뜰 수도 있다 — 관측 아님), 뜨면 **거부(Deny)**로 답한다. 이유는 도달 가능성 판단이다(호출을 관측한 것은 아니다): `googleConnected` = `config.hasGoogleCalendar && gcal.isConnected`(`Store.swift:493`), `isConnected` = `Keychain.get(refreshKey) != nil`(`GoogleCalendarService.swift:38`)이고, `Keychain.get`은 `SecItemCopyMatching`이 성공하지 않으면 nil을 돌려준다(`:407-408`). 드라이버는 `googleClientID`를 N절 안에서만 비운다(`Tools/GuardDriver.swift:1262-1263`에서 비우고 `:1337`에서 되돌린다). 그런데 이 맥의 `config.json`에는 클라이언트 ID가 설정돼 있다(2026-09-23 plan 레인 오케스트레이터 관측 — `googleClientID` 키가 있고 비어 있지 않음, 값은 출력하지 않았다. 드라이버 주석 `GuardDriver.swift:1350`도 "구글이 연결돼 있다"고 적었다). 그래서 **허용하면 나머지 실행 동안 실제 구글 계정 경로가 도달 가능해지고**, 파일 백업으로는 원격에서 일어난 일을 되돌릴 수 없다.
      - (ii) `~/Library/Application Support/besir/`에서 앱이 쓰는 데이터 파일 일곱 — `config.json`·`events.json`·`favorites.json`·`activities.json`·`meals.json`·`deleted_gcal_ids.json`·`ai_history.json`(`grep -n 'appendingPathComponent("' Shared/Store.swift Shared/AIAssistant.swift Shared/Config.swift`) — 중 **있는 것은 전부** 세션 scratch 디렉터리로 복사하고, **없는 것은 이름을 기록한다.** 2026-09-23 현재 있는 것은 `activities.json`·`config.json`·`events.json` 셋이다(`ls -la`).
      - (iii) **시간 제한을 같은 호출 안에 건다.** 이 맥에는 `timeout`·`gtimeout`이 없다(`which timeout gtimeout` → 둘 다 not found). `/usr/bin/perl`로 바깥에서 프로세스를 묶는다: `perl -e 'alarm shift; exec @ARGV' <초> <바이너리>`. 시간이 다 되면 SIGALRM으로 끝나며 종료 코드는 142다(`perl -e 'alarm shift; exec @ARGV' 2 sleep 5` → exit 142로 실측). `<초>`는 run 레인이 정하고 값과 이유를 기록한다 — 정상 완주에 걸리는 시간은 이 plan 단계에서 재지 못했다.
      - (iv) **복원하기 전에** 실행이 끝났다는 것을 확인한다. 종료 코드를 기록한다(0 · 실패 코드 · 142 = 시간 제한). 멈췄는데 시간 제한 전이라면 프로세스를 죽인다. 그다음 프로세스가 **없다는 것을** 확인한다 — 실행할 때 PID를 기록해 두고 `kill -0 <pid>`가 실패하는 것을 기본 신호로 삼는다. `pgrep`을 보조로 쓸 때는 바이너리를 고유한 이름으로 컴파일하고 전체 경로로 맞춘다(`pgrep -fx <바이너리 전체 경로>`). `CLAUDE.md` 블록의 기본 이름 `gd`로 `pgrep -f`를 하면 `logd`·`configd` 같은 시스템 프로세스가 걸려 빈 출력이 나올 수 없다(plan 감사 2회차 N1). 운영자에게 키체인 대화상자가 닫혔는지 확인받는다(프로세스를 죽이면 대화상자가 닫히는지는 확인하지 않았다). 이 순서가 필수인 이유: 멈춘 자리는 `save()`(`Store.swift:771`) 뒤의 `googleConnected`(`:776`)이고, 대화상자에 답하면 프로세스가 이어서 돌아 다시 쓴다 — 연결 상태면 `:789`의 `save()`에서, 아니어도 뒤 절들에서. 깨끗한 `cmp` 뒤에 쓰기가 한 번 더 일어나면 그 `cmp`는 거짓이 된다.
      - (v) 그다음에만 백업을 되돌려 놓고, 백업한 파일마다 `cmp <백업> <원본>`의 출력(아무것도 찍히지 않고 exit 0)을 기록한다. 실행 전에 없던 파일이 실행 뒤에 생겼으면 지우고, 지운 사실과 `ls`로 확인한 결과를 기록한다. 되돌리는 대상은 **실행 직전 상태**이며, 그 상태에 이미 남아 있는 시험 데이터를 치우는 일은 운영자가 정한다(§3 Out of Scope).
      - (vi) **키체인 답을 실행마다 기록한다** — "거부" · "대화상자 없음(구글 연결 여부 미상)" · "허용". 허용된 실행은 **"구글 연결 상태로 돌았음"**으로 적고 운영자에게 따로 알린다.
  - (b) iOS·macOS 양쪽 **무경고** 빌드. 총계가 아니라 `grep 'warning:' <build.log> | grep -c '\.swift'`가 **0**인지로 잰다. `ContentView.swift`·`AddActivityView.swift`의 import 제거를 증명하는 것은 이 빌드뿐이다(§1.3).
  - (c) `cd proxy && npm test` 전체 통과 — 이 SPEC은 프록시를 건드리지 않지만 게이트는 돈다.

## 3. 인수 기준과 범위 밖

§3.1은 Tier S의 인라인 인수 기준이고, 뒤따르는 `Out of Scope —` 절들은 이 카드가 만들지 않은 결함과 일부러 하지 않는 일을 증거와 함께 적는다. 인접한 결함은 요구사항이 아니라 여기에 둔다.

### 3.1 인수 기준 (Tier S 인라인)

권고안 (a)(a)(a)와 `CLAUDE.md` 수정 확인을 기준으로 적었다. **게이트가 (a)(a)(a)와 `CLAUDE.md` 수정 승인으로 확정했으므로(2026-09-23) AC-003~006은 적힌 그대로 적용한다.** 단, run 레인이 `CLAUDE.md` 수정 직전에 자기 세션에서 운영자에게 다시 확인받았을 때 거절되면 AC-006 (1)을 뺀다(REQ-020 (a)). 동작이 바뀌는 자리가 0곳이므로 실기기 전용 항목은 없다 — 기기에서 보이는 차이가 없다는 것 자체가 기대 결과다.

#### AC-001 — `addActivity`가 사라지고 옮긴 문서 줄이 제자리에 있다 (REQ-001)

**Given** run이 끝난 트리에서 **When** `grep -c "func addActivity(" Shared/Store.swift`·`grep -c "func addActivityWithTravel" Shared/Store.swift`·`grep -cF "/// 여러 요일에 반복되는 활동 블록(수업·근무·점심 등)을 한 번에 생성한다. 이동시간 계산은 없다." Shared/Store.swift`를 돌리고 `grep -n "여러 요일에 반복되는 활동 블록\|recurrenceId를 공유하는 ScheduledEvent\|func addRecurringActivities" Shared/Store.swift`를 읽으면 **Then** 값이 차례로 0·1·1이고(세 번째는 문장 전체 대조라 잘린 이동은 0이 된다), 세 줄번호가 `N`·`N+1`·`N+3`이며 `N+2`가 `@discardableResult`다. 하나라도 어긋나면 FAIL.

#### AC-002 — 세 파일에 `import CoreLocation`이 없다 (REQ-002)

**Given** run이 끝난 트리에서 **When** `grep -c "^import CoreLocation" Shared/ContentView.swift Shared/AddActivityView.swift Shared/GoogleCalendarService.swift`와 `grep -l "^import CoreLocation" Shared/*.swift | wc -l`을 돌리면 **Then** 앞의 세 값이 모두 0이고 뒤의 값이 9다. 컴파일된다는 증거는 AC-008(b)가 맡는다.

#### AC-003 — `openLocationSettings`와 그것만 쓰던 조건부 import 블록이 없다 (REQ-010)

**Given** 게이트가 D-1을 (a)로 정했고 run이 끝난 트리에서 **When** `grep -rn "openLocationSettings" Shared/ ShareExtension/ Tools/`·`grep -c "^import AppKit\|^import UIKit\|NSWorkspace\|UIApplication" Shared/LocationManager.swift`·`grep -c '^#if os(macOS)' Shared/LocationManager.swift`를 돌리면 **Then** 차례로 0건·0·0이다(마지막은 `#if`/`#else`/`#endif` 빈 껍데기가 남는 편집을 잡는다 — `00ab661`에서는 1, 들여쓴 `:29`·`:83`·`:119`는 `^` 때문에 걸리지 않는다). 그리고 `grep -c "lastError" Shared/LocationManager.swift`가 변경 전 값(`00ab661`에서 **8** — 선언 `:17` + 쓰기 7곳)과 같다.

#### AC-004 — `updateMeal`이 남고 남는 이유가 코드에 적혀 있다 (REQ-011)

**Given** 게이트가 D-2를 (a)로 정했고 run이 끝난 트리에서 **When** `grep -c "func updateMeal" Shared/Store.swift`와 `grep -B1 "func updateMeal" Shared/Store.swift | grep -c "SPEC-FULL-001"`을 돌리면 **Then** 둘 다 1이고, 그 주석이 한국어로 **왜**(진행 중 SPEC의 요구 연산이라서)를 말한다(검토자 판정 — code-safety 레인, 근거 기록).

#### AC-005 — `deleteExpired`가 없고 묘비 경로는 살아 있다 (REQ-012)

**Given** 게이트가 D-3을 (a)로 정했고 run이 끝난 트리에서 **When** `grep -rn "deleteExpired" Shared/ ShareExtension/ Tools/`와 `grep -rn "removeFromCalendar(" Shared/ | grep -v "func " | wc -l`을 돌리면 **Then** 앞은 0건, 뒤는 9다.

#### AC-006 — 인용이 최종 트리의 내용을 가리킨다 (REQ-020)

**Given** sync가 끝난 트리에서 **When** `CLAUDE.md`의 테스트 블록 인용과, `CHECKLIST.md`에서 `Store.swift`·`GoogleCalendarService.swift`·`ContentView.swift`를 가리키는 모든 줄번호 인용(앵커와 이어 붙은 `:N`)을 **인용된 줄의 본문과 바이트로 대조**하면 **Then** (1) `CLAUDE.md`가 `SettingsView.swift:71`/`#L71`을 가리키고 그 줄이 `⚠️ 테스트용 임시` 표식이다(운영자가 run 세션에서 수정을 확인했을 때만 — 확인 수단(직접 입력 또는 권한 프롬프트 승인)과 결과가 `progress.md` §E.2에 기록돼 있어야 하고, 기록이 없으면 FAIL) (2) 대조한 인용이 전부 뜻한 내용에 닿는다(검토자 판정 — sync 레인, 근거 기록) (3) L3 줄에 415줄 파일의 `:1360-1364` 같은 파일 밖 줄번호가 없다 (4) 대조 건수와 정정 건수를 sync 레인이 명령과 함께 기록했다. 산술(일괄 −1 등)만으로 고친 인용은 대조로 치지 않는다.

#### AC-007 — 선언한 파일 밖은 무변경이고 새 파일이 없다 (REQ-021)

**Given** run·sync가 끝난 브랜치에서 **When** `git diff --name-only 00ab661...HEAD`와 `git diff --name-only --diff-filter=A 00ab661...HEAD -- 'Shared/*.swift'`를 돌리면 **Then** 앞의 목록이 REQ-021이 선언한 파일(+ 이 SPEC 디렉터리)의 부분집합이고 `Shared/*.swift`가 정확히 5개(D-1이 (a)가 아니면 4개)이며, 뒤는 0건이다. 이 신호는 저장소 경로만 본다 — `.claude/`와 REQ-021의 예외 (1)·(2)는 보지 못한다.

#### AC-008 — 게이트 셋이 통과한다 (REQ-030)

**Given** run이 끝난 트리에서 **When** (a) 이 워크트리 `CLAUDE.md` § 빌드 · 배포의 드라이버 블록을 REQ-030 (a)의 절차 (i)~(vi)으로 감싸 돌리고 (b) iOS·macOS `xcodebuild` 두 번(로그 각각 파일로) (c) `cd proxy && npm test`를 돌리면 **Then** (a) 전체 통과·exit 0이고 마지막 불변식 "autoAddToCalendar는 꺼져 있다"가 ✓ (b) 둘 다 `BUILD SUCCEEDED`이고 `grep 'warning:' <log> | grep -c '\.swift'`가 둘 다 0 (c) 전부 통과 (d) **드라이버를 돌린 횟수마다** `progress.md` §E.2에 다음이 기록돼 있다 — 시간 제한 값, 종료 코드, 복원 시점에 드라이버 프로세스가 없었다는 확인(`pgrep -f <바이너리 이름>`의 빈 출력 또는 `kill -0 <pid>` 실패), 운영자가 확인한 대화상자 닫힘, 키체인 답(거부 · 대화상자 없음 · 허용 = "구글 연결 상태로 돌았음"), 백업한 파일마다 복원 뒤 `cmp`의 무출력·exit 0, 실행 전에 없던 파일이 실행 뒤에도 없다는 `ls` 결과. 드라이버가 키체인 대기로 멈추거나 시간 제한에 걸리면 (a)는 PASS도 FAIL도 아닌 **미관측**으로 기록하고 운영자에게 넘기되, (d)는 그 실행에도 똑같이 요구한다 — (d)가 빠진 실행은 (a)의 결과와 상관없이 FAIL이다.

### Out of Scope — `lastError` 두 개: 쓰기만 있고 읽는 화면이 없다 (새 발견, 카드 밖)

- `LocationManager.lastError`(`@Published`, `:17`)는 일곱 자리에서 쓰인다 — `:54`·`:57`·`:92`·`:108`·`:140`·`:151`·`:162`(`grep -n "lastError" Shared/LocationManager.swift`). 그중 `:57`·`:140`은 사용자에게 보여줄 안내("시스템 설정에서 허용해 주세요")다.
- 읽는 뷰가 없다 — `grep -rn "\.lastError" Shared/ ShareExtension/ Tools/`의 결과가 전부 `LocationManager.swift`·`NotificationManager.swift` 안의 쓰기다. (이름만으로 `grep -rn "lastError"`를 돌리면 `AIAssistant.swift:966`·`:979`·`:984`가 더 나오지만, 재시도 루프의 지역 변수 `var lastError: Error`라 무관하다.)
- `NotificationManager.lastError`(`:8`)도 같다 — 쓰기 `:18`·`:25`·`:45`, 읽기 0.
- **연결점**: D-1을 (b)(연결)로 고르면 `LocationManager.lastError`가 설정 버튼 옆에 띄울 문구의 자연스러운 출처다. 그 경우에도 이 카드가 아니라 연결을 맡는 카드의 일이다. 리드가 카드로 올릴 대상이다.

### Out of Scope — `fetchBesirItems()`가 한 페이지만 받는다 (새 발견, 코드 읽기 가설 — 미관측)

- `GoogleCalendarService.fetchBesirItems()`(`:102`)는 `maxResults=250`(`:107`)으로 한 번만 요청하고, 다음 페이지를 따라가는 코드가 없다 — `grep -rn "pageToken\|nextPageToken\|maxResults" Shared/` → `:107` 한 줄뿐.
- Google Calendar API `events.list` 문서(developers.google.com/workspace/calendar/api/v3/reference/events/list, 2026-09-23 조회): `maxResults`는 "The number of events in the resulting page may be less than this value, or none at all, even if there are more events matching the query. … By default the value is 250 events.", `nextPageToken`은 "Omitted if no further results are available", 기본 순서는 "an unspecified, stable order"다.
- `Store.syncWithGoogle()`에서 받은 목록이 일부일 때 이어지는 일(코드 읽기): 1단계(`:1389-1393`)가 원격 목록에 없는 `googleEventId`의 로컬 일정을 "다른 기기에서 삭제됨"으로 보고 지우며 알림도 끈다. 묘비 정리(`:1383-1387`)는 보지 못한 묘비를 "사라짐 확인"으로 버린다. `reconcileActivities` 2-1(`:1422-1428`)이 보지 못한 활동의 `googleEventId`를 비우고, 2-5(`:1461-1470`, `config.autoAddToCalendar`일 때만 `:1462`)가 그것을 다시 올린다. 지난 일정·활동을 지우는 장치가 없으므로 쌓일수록 일부 페이지가 될 가능성이 커진다.
- **카드가 D-3의 근거로 든 "만료 일정 무한 누적"이 해를 끼친다면, 가능한 피해 경로(가설, 미관측)가 이것이다.** 그리고 `deleteExpired`를 연결해도 닫히지 않는다 — 활동과 미래 일정도 수에 들고, 문서대로라면 250건 아래에서도 일부 페이지가 올 수 있다. 고칠 자리는 `GoogleCalendarService`의 페이지 처리이고 별도 카드다.
- **미관측**: besir 항목이 250건을 넘는 계정으로 시험한 적이 없다. 결함이 아니라 가설이다.

### Out of Scope — 카드 밖 데드 코드 후보 두 건 (실측, 추가하지 않는다)

- `KoreanHolidays.dates(year:)`(`Models.swift:326`) — 호출부 0(`grep -rn "dates(year" Shared/ ShareExtension/ Tools/` → 선언 한 줄뿐). 같은 파일의 `dates(from:weeks:)`(`:278`)는 다른 함수다.
- `MealLog.estimatedCost`(`Models.swift:485`) — `addMeal`의 매개변수(`Store.swift:407`·`:413`)로 쓰일 뿐 읽는 곳이 없다(`grep -rn "estimatedCost" Shared/ ShareExtension/ Tools/` → 세 줄).
- 둘 다 `hns-besir-app-hazards` 스킬의 후보 목록에 있으나 **운영자가 승인한 카드 범위(7건)에 없다.** 범위를 넓히지 않고, 리드가 필요하면 카드로 올린다. 같은 목록의 `MealCategory.delivery`/`.cooking`은 스킬이 "지우지 말 것"으로 묶어 두었다.

### Out of Scope — 하네스 스킬의 `updateMeal` 항목

- 주 체크아웃의 `.claude/skills/hns-besir-app-hazards/SKILL.md:233`이 `Store.updateMeal(_:)`을 "zero callers" 데드 코드 후보로 싣고, 남기는 근거(SPEC-FULL-001 REQ-003)는 적지 않았다. `.claude/`는 git이 추적하지 않으므로(`git ls-files .claude | wc -l` = 0) 이 워크트리에는 그 파일이 없다. D-2가 (a)로 가면 코드 주석이 다음 전수 분석을 막지만 스킬 항목은 그대로 후보라고 말한다.
- `.claude/` 아래는 이 카드 범위 밖이다(REQ-021). 하네스 수정으로 리드에게 넘긴다.

### Out of Scope — 가드 드라이버의 실제 데이터 쓰기 (관측됨 — 2026-09-23)

- **경로(코드).** 드라이버 초반 절은 `store.events`에 시험 일정을 넣고(`Tools/GuardDriver.swift:193`·`:287-288` 등) `executeUpdateRecurringSchedule` → `Store.updateRecurringSeries`를 거쳐 `save()`(`Store.swift:771`)를 부른다. `save()`는 `AppConfig.supportDirectory`의 `events.json`에 쓰고(`Store.swift:70-71`·`:1486`, `Config.swift:65-67`), macOS 앱은 샌드박스가 꺼져 있어(`project.yml:107` `com.apple.security.app-sandbox: false`) 같은 경로다. 드라이버에서 `events.json`을 백업하는 첫 자리는 J절(`GuardDriver.swift:1127`), `activities.json`은 Y절(`:1168`)이다(`grep -n "Data(contentsOf" Tools/GuardDriver.swift`). 그보다 앞의 W절(`:1037-1039`, `create_activity`에 `"title": "W-하룻밤", "start_iso": "2027-03-10T18:00:00"`)에는 백업·복원이 없다.
- **관측(오케스트레이터가 실제 파일을 읽음 — 제목·날짜만, 수정 없음. 이 레인이 `stat`·`ls`·필드 읽기로 재확인).** `~/Library/Application Support/besir/`에 있는 파일은 `activities.json`·`config.json`·`events.json` 셋뿐이다(`ls -la`).
  - `events.json` — 수정 시각 2026-09-23 14:17:35(`stat -f "%Sm"`), 항목 2건: `출근`(arrivalDate `811919853.7` = 2026-09-24 14:17:33 +09)·`헬스`(`811941453.7` = 2026-09-24 20:17:33 +09), 둘 다 `recurrenceId`가 있고 `googleEventId`는 없다. `GuardDriver.swift:287-288`의 `drvLeg(ridX, title: "출근", hours: 24)`·`drvLeg(ridY, title: "헬스", hours: 30)`와 제목·간격(24시간·30시간 뒤, `drvLeg`의 `arrivalDate: Date().addingTimeInterval(hours * 3600)` `:66`)이 일치한다 — 14:17:33에 만들어진 시험 일정이고, **이 plan 레인이 강제 종료한 실행(§0)이 썼다.**
  - `activities.json` — 수정 시각 14:11:27, 항목 1건: `W-하룻밤`(startDate `826362000` = 2027-03-10 18:00 +09), `googleEventId` 없음. W절의 입력과 일치한다 — **오케스트레이터의 205/205 완주 실행이 14:11경 남겼다.** 뒤따르는 Y·cal·Z절의 백업·복원은 이미 W절이 덮은 상태를 되돌릴 뿐이라 완주해도 남는다. 프로젝트 기억 `feedback_besir_driver_touches_real_data`도 "W3은 안 해서 테스트 활동이 남았다"고 같은 잔재를 적어 두었다.
  - 날짜 변환: 값은 2001-01-01 기준 초이므로 `978307200`을 더해 `date -r`로 읽었다.
- **복구할 수 없는 공백.** 14:11 이전의 두 파일 내용은 알 수 없고 이 세션에서 되살릴 수도 없다. 오케스트레이터의 완주 실행이 14:11에 `events.json`에 남긴 상태도 14:17의 덮어쓰기로 지워졌다. t6 기간의 드라이버 실행들도 시험 데이터를 남겼을 가능성이 높지만 **확인할 방법이 없다.**
- **살아 있는 결과.** `config.json`의 `autoAddToCalendar`가 `true`이고, `W-하룻밤`은 `googleEventId`가 없고 `syncToCalendar`가 `true`다(`ActivityBlock.wantsCalendarSync` = `syncToCalendar ?? true`, `Models.swift:512`). 이 맥에서 besir macOS 앱을 켜고 동기화가 돌면 — 구글 연결 확인 `Store.swift:1343`을 통과하는 한 — `reconcileActivities` 2-5(`Store.swift:1461-1470`, 게이트 `:1462` `guard config.autoAddToCalendar`, 대상 선택 `:1463`)가 이 시험 활동을 **사용자의 실제 구글 캘린더에 올린다** — 2026-09-16 사고(시험 일정 `Z-단발`·`P-확정`이 실제 캘린더에 올라간 일)와 같은 부류다. 운영자가 정리 방법을 정하기 전까지 **이 맥에서 besir macOS 앱을 켜지 않는다.**
- 이 카드는 드라이버를 고치지 않는다(REQ-021). 이 카드가 하는 것은 **돌리는 방식**을 감싸는 것뿐이다 — REQ-030 (a)의 시간 제한·프로세스 소멸 확인·키체인 거부·백업·`cmp` 복원 절차와 AC-008 (d). 고치는 카드와 이미 남은 시험 데이터의 정리는 리드가 정한다.

### Out of Scope — `STATUS.md:21`의 낡은 서술

- "만료 일정 분리 폴더 + 일괄 삭제"가 있다고 적었지만 현재 코드에 없다(§1.4). `STATUS.md`는 사업계획서용 요약이고 `CLAUDE.md`가 낡았다고 명시했다. 고치지 않는다.

### Out of Scope — 출시 전 제거할 테스트용 코드

- `Store.deleteEverythingForTesting()`(`Store.swift:1309`)·`AIAssistant.transcriptForDebugging()`과 두 화면 블록은 출시 전 제거 대상이지만 **데드 코드가 아니다**(설정 화면·채팅 화면에서 불린다). 이 카드는 그 인용 한 줄(REQ-020 (a))만 고친다.

## 4. 결정 기록 — 해소 (착수 승인 게이트, 2026-09-23)

세 건 모두 **(a)로 해소됐다**(2026-09-23 운영자 확정, 리드가 전달, 결정 기록은 `plan.md` §2). 아래 선택지와 권고 근거는 결정 기록으로 남긴다. 권고는 첫 번째 안이었다. **선택지에는 결과·비용·파일/렌즈/Tier 변화·확인된 사실만 적고, 권고의 논거는 각 결정 밑의 "권고 근거"에 따로 둔다.**

### D-1 — `LocationManager.openLocationSettings()` — 해소: (a) 제거

- **(a) 제거 (권고).** `:118-129`와 그것만 쓰던 `:3-7` 조건부 import를 지운다(REQ-010) — 삭제 17줄(`awk 'NR>=118 && NR<=129'` 12줄 + `awk 'NR>=3 && NR<=7'` 5줄). 파일 +0, 렌즈 +0, Tier S 유지. CHECKLIST L9는 ⚠️ 그대로이고 사용자가 보는 상태는 바뀌지 않는다. 지운 줄은 git 이력에 남는다.
- **(b) 연결.** 거부 상태가 보이는 자리에 설정 버튼을 둔다. 렌즈에 `ui-design`·`swift-impl`이 들고, 버튼을 둘 화면 파일이 하나 이상 더해진다(자리는 미정). 문구 출처로 `LocationManager.lastError`(§3 Out of Scope)가 들어올 수 있다. L9를 ⚠️ → ✅로 옮길 수 있으나 실기기 확인 항목이 생긴다(권한 거부 상태에서 설정 앱으로 넘어가는지). **Tier M.**
- **(c) 그대로 둔다.** `LocationManager.swift`가 무변경이라 run 파일이 하나 준다. 렌즈 +0, Tier S. 호출부 0인 함수와 `:3-7`이 남고, 같은 목적의 문구 출처인 `lastError`도 읽는 곳이 없다(§3). 데드 코드 후보 목록에 계속 남는다.

**권고 근거.** 데드 코드 카드가 기능을 키우지 않는다. 연결 UI를 어디에 둘지(`FullSirView.swift:101`의 경고 옆, `AddEventView`의 현재 위치 칩, 채팅 답 가운데 어디) 자체가 화면 설계 질문이라 별도 카드가 맞다. 카드가 붙인 "L9의 미완성 해결책"이라는 해석은, 이 함수를 부르던 화면이 없고 짝이 될 문구(`lastError`)를 읽는 화면도 없어 확인할 근거가 없다.

### D-2 — `Store.updateMeal(_:)` — 해소: (a) 유지 + 이유 주석

- **(a) 유지 + 이유 주석 한 줄 (권고).** REQ-011 — 추가 1줄. 파일 +0(`Store.swift`는 어차피 바뀐다), 렌즈 +0, Tier S. 확인된 사실: SPEC-FULL-001(`status: in-progress`) REQ-003(`spec.md:60`)이 이 연산을 명시하고, AC-113(`acceptance.md:133-139`)이 동작을 검증 대상으로 적었다.
- **(b) 제거 + SPEC-FULL-001 REQ-003 개정.** 삭제 7줄(`awk 'NR>=421 && NR<=427' Shared/Store.swift | wc -l`, 함수 + 뒤 빈 줄). 진행 중인 다른 SPEC의 REQ-003과 AC-113이 깨지므로 그 SPEC의 개정이 먼저 필요하다. 이 카드의 범위(REQ-021)가 다른 SPEC으로 넓어진다 — **별도 카드.**

**권고 근거.** 남길 근거는 예측이 아니라 살아 있는 요구사항이다. 카드가 든 근거("be full sir Phase 1이 곧 사용할 가능성")는 측정할 수 없는 예측이고, 루트 `plan.md`에 이 연산을 부를 화면 계획은 없다(`:206` 완료 기록 한 번뿐). 주석이 없으면 다음 전수 분석이 또 후보로 올린다.

### D-3 — `Store.deleteExpired()` — 해소: (a) 제거

- **(a) 제거 (권고).** REQ-012 — 삭제 16줄(`awk 'NR>=1318 && NR<=1333' Shared/Store.swift | wc -l`). 파일 +0, 렌즈 +0, Tier S. sync에서 `plan.md:105`의 해당 항목을 닫는다(REQ-020).
- **(b) 연결 — 자동 실행 또는 설정 버튼.** 지난 일정을 로컬에서 지우고(`:1325`) 구글 캘린더에도 삭제를 보낸다(`:1328-1331`). 앱 안에서는 되돌릴 방법이 없다(구글 캘린더 휴지통 복구는 확인하지 않았다). 활동은 그대로 남아 "활동은 있는데 이동 구간만 사라진" 날이 생긴다. 버튼이면 화면 파일과 `ui-design`이 더해지고, 자동이면 사용자 조작 없이 이력이 지워진다. **Tier M.**
- **(c) 주석을 고쳐 유지.** 주석을 "호출부 없음, 연결하면 구글 캘린더에서도 지운다"로 정정한다 — 교체 1줄. 파일 +0, 렌즈 +0, Tier S. `plan.md:105`의 결정이 존속하고, 데드 코드 후보 목록에 계속 남는다.

**권고 근거.** 셋이다. ① git 이력 시작(`d3c9327`)부터 호출부가 없다 — 부르던 화면이 이력 이전에 걷혔는지, 처음부터 없었는지는 가를 수 없지만, 어느 쪽이든 되살릴 대상이 이 트리에 없다(§1.4). ② 유지 전제 "나중에 UI에서 쓸 것"(`plan.md:105`)에 계획된 UI가 없다. ③ 연결은 보이도록 설계된 이력(`ContentView.swift:615`의 주석)을 두 곳에서 지운다. 카드의 "휴면 결함: 만료 일정 무한 누적"은 이렇게 정정한다 — 누적 자체는 설계된 이력이고, 가능한 피해 경로(가설, 미관측)는 한 페이지 조회(§3 Out of Scope)이며, 이 함수를 연결해도 그 경로는 닫히지 않는다.

### 결정 조합과 Tier

권고안 (a)(a)(a)이면 run이 건드리는 파일은 `Store.swift`·`LocationManager.swift`·`ContentView.swift`·`AddActivityView.swift`·`GoogleCalendarService.swift`·`CLAUDE.md` **6개**이고 전부 삭제·주석 한 줄·인용 한 줄이다. 파일 수로는 Tier M의 범위(5~15개, `spec-workflow.md:141`)이고 `Shared/*.swift` 다섯만으로도 Tier S의 "5개 미만"을 벗어나지만, 줄 수(약 50, `plan.md` §0의 명령)와 설계 내용 0으로 S를 유지한다 — 운영자가 게이트에서 확정했다(2026-09-23). **D-1 또는 D-3에서 (b)를 고르면 Tier M으로 올린다.** D-2 (b)는 이 카드의 범위를 다른 SPEC으로 넓히므로 별도 카드가 맞다.

## 5. 관련 문서

- 칸반 카드 **t5** 본문(`moai todo`) — 이 SPEC의 등록 근거. 확정 7건과 결정 3건, `CLAUDE.md` 인용 정정
- 루트 [`plan.md`](../../../plan.md) `:105` — `deleteExpired`를 "알고도 안 고친 것"으로 남긴 지난 결정(D-3이 다룬다). `:87` — 삭제 경로를 `removeFromCalendar`로 통일한 이력
- [SPEC-FULL-001](../SPEC-FULL-001/spec.md) — REQ-003·AC-113이 `updateMeal`을 요구한다(D-2의 근거)
- [SPEC-UIKIT-005](../SPEC-UIKIT-005/spec.md) — 직전 카드(t6). 이 카드의 줄번호 재실측 요구와 "드리프트를 만든 카드가 수리한다" 관례의 최근 적용례
- [SPEC-ONTIME-001](../SPEC-ONTIME-001/spec.md) — 가드 드라이버와 AI 인자 방어의 원본
- [CHECKLIST.md](../../../CHECKLIST.md) — L9(`:277`)가 D-1과 닿고, L3(`:271`)의 기존 오인용을 이 카드가 sync에서 고친다

🗿 MoAI
