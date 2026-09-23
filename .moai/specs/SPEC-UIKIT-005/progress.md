# SPEC-UIKIT-005 — progress.md

칸반 카드 t6 · 장소 사전 이름-키 충돌 수리(잔여 두 화면). plan 레인 세션이 2026-09-22 리드 디스패치로 개시.
워크트리 `.claude/worktrees/t6` (branch `WT-place-dict`, base `c5396b3`).

## §E.1 Plan-phase Audit-Ready Signal

- **plan_status: audit-ready-for-kickoff-gate** — "구현 준비 완료"가 **아니다.** D-1(`AIAssistant`의 단사성 기법)이 미해소인 채로 나가므로, 이 신호가 여는 다음 문은 run 착수가 아니라 **착수 승인 게이트**다(아래 § 미해소 결정).
- plan_complete_at: 2026-09-22T15:07+09:00
- plan 산출물: `spec.md` · `plan.md` · `acceptance.md` · `progress.md`(이 파일) — **미커밋.** 지시대로 커밋하지 않았고, `git status --short`가 `?? .moai/specs/SPEC-UIKIT-005/` 한 줄이다. `Shared/` 아래 변경 0건.
- 등록 근거: 루트 `plan.md` §Phase 1.7 후속 **8번**(t3 sync의 `--deep` 렌즈가 올린 계통 회귀) + 2026-09-22 운영자 승인(t3 병합 후 · t5 앞).

### 관측된 증거 — 명령과 그 출력

인용 줄번호는 전부 아래 명령을 이 트리(`c5396b3`)에서 돌려 얻었다. **기억하거나 어림한 값은 없다** — SPEC-UIKIT-001 HISTORY 0.1.1이 어림 인용 27건으로 run을 없는 코드로 보낸 것이 이 관례의 이유다.

| 명령 | 관측된 출력 | 쓰인 곳 |
|---|---|---|
| `git rev-parse --short HEAD` / `git branch --show-current` | `c5396b3` / `WT-place-dict` | 전 인용의 기준 트리 |
| `grep -n "\[String: Place\]" Shared/AddEventView.swift Shared/AIAssistant.swift` | `AddEventView:19` · `AIAssistant:49` | §1.1 남은 둘 |
| `grep -n "\[UUID: Place\]" Shared/AddActivityView.swift Shared/ActivityDetailView.swift` | `ActivityDetailView:20` · `AddActivityView:24` | §1.1 t3가 닫은 둘 |
| `grep -c "kind: .place" Shared/AddEventView.swift` / `… Shared/AIAssistant.swift` | **2** / **5** | §1.1 장소 줄 수 |
| `grep -c "confirmedPlaces\[" Shared/AddEventView.swift` | **6** | §1.4 (나) 접점 |
| `grep -c "confirmedPlaces" Shared/AIAssistant.swift` | **7** | §1.5 접점 |
| `grep -n "fields.remove" Shared/AddEventView.swift` | `:266` **단건**(`.notify` 줄) | REQ-020 근거 |
| `wc -l Shared/AddEventView.swift Shared/AIAssistant.swift` | **619** / **2443** | Tier 판단 |
| `grep -c "resolveOrigin(" Shared/AIAssistant.swift` | **5**(선언 1 포함 → 호출 4) | D-1 A안 비용 |
| `grep -c "resolveDestination(" Shared/AIAssistant.swift` | **9**(선언 1 포함 → 호출 8) | D-1 A안 비용 |
| `grep -c "unresolvedGenericPlace(" Shared/AIAssistant.swift` | **5**(선언 1 포함 → 호출 4) | D-1 A안 비용 |
| `grep -rn "isSamePlace" Shared/` | `AIAssistant:1297`(유일 호출) · `:1613`(범위를 적은 주석) · `:2279`(선언) | §1.3 경로별 증상 |
| `grep -n "isSamePlace\|origin == \|sameCoord" Shared/Store.swift` | **0건** | §1.3 · §3 Out of Scope |
| `grep -n "이름이 겹칠 수 있어" Shared/Models.swift` | `:108` | §1.2 |
| `grep -n "item.name ?? p.name ?? query" Shared/PlaceSearch.swift` | `:126` | §1.2 |
| `grep -n "모호한 이름" Shared/AIAssistant.swift` | `:2317` | §1.2 |
| `grep -n "bubbles\[b\].ask?.fields.firstIndex" Shared/AIAssistant.swift` | `:739`(따라서 조회 절은 `:738-739`) | §4 D-1 A안 선례 |
| `[[ "SPEC-UIKIT-005" =~ ^SPEC(-[A-Z][A-Z0-9]*)+-[0-9]{3}$ ]]` | **PASS** | SPEC ID 자기점검 |
| `grep -rn "SPEC-UIKIT-005" .moai/ *.md` | **0건**(작성 전) | ID 중복 없음 |
| `grep -c '^- \*\*REQ-' spec.md` / `grep -c '^## AC-' acceptance.md` | **11** / **9** | Tier M 상한(16/16) 아래 |
| `grep -c '^### Out of Scope — ' spec.md` | **7** | 범위 배제 절 |

### 게이트 — plan이 실제로 돌린 것 **하나**

```
$ cat Shared/EditCard.swift Shared/AIAssistant.swift Tools/GuardDriver.swift > /tmp/gd_t6.swift \
  && swiftc -o /tmp/gd_t6 /tmp/gd_t6.swift Shared/Store.swift Shared/Models.swift \
       Shared/Config.swift Shared/PlaceSearch.swift Shared/DirectionsService.swift \
       Shared/LocationManager.swift Shared/NotificationManager.swift \
       Shared/GoogleCalendarService.swift Shared/SharedInbox.swift -parse-as-library \
  && /tmp/gd_t6
205/205 통과
```

**이 205/205는 이 plan 세션이 `c5396b3`에서 직접 실행해 관측한 값이다 — t3 기록의 인용이 아니다.** 두 값이 우연히 같지만 귀속이 다르므로 그렇게 적는다(t3의 205/205는 t3의 최종 트리에 대한 t3 sync의 측정이고, 이것은 t6 착수 시점 이 트리에 대한 측정이다). 임시 산출물 `/tmp/gd_t6*`는 실행 후 삭제했다.

이 트리에서 드라이버가 초록이라는 사실이 **착수 전 베이스라인**이며, run이 `AIAssistant.swift`를 고친 뒤 이 값과 비교할 기준점이다. 컴파일 집합이 `cat Shared/EditCard.swift Shared/AIAssistant.swift Tools/GuardDriver.swift …`로 시작하므로 **이 카드의 모든 `AIAssistant` 변경이 이 게이트를 통과해야 한다** — t3와 다른 점이다.

### Gaps — plan이 **돌리지 않은** 것 (증거 없음 ≠ 통과)

아래 넷은 이 plan 세션에서 **한 번도 실행되지 않았다.** 어느 것도 "통과"로 읽어서는 안 되고, run이 자기 트리에서 직접 재어 §E.2에 적는다.

- **iOS 빌드 — 미실행.** `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build` 를 돌리지 않았다. t3 sync가 t3 최종 트리에서 "Swift 소스 경고 0"을 기록했으나 **그것은 t3의 트리에 대한 t3의 측정**이므로 이 카드의 베이스라인이 아니다.
- **macOS 빌드 — 미실행.** `xcodebuild -scheme besir-macOS -derivedDataPath build build` 를 돌리지 않았다. 위와 같은 귀속.
- **프록시 — 미실행.** `cd proxy && npm test` 를 돌리지 않았다. 이 카드는 `proxy/`를 건드리지 않지만 게이트는 run이 돈다.
- **시뮬레이터 · 실기기 — 미실행, 그리고 plan이 할 수 있는 일이 아니다.** 이 카드가 고치는 값은 **좌표**이고 좌표는 화면에 찍히지 않는다. "두 줄에 같은 상호의 다른 지점을 고른다"는 조작은 사람만 할 수 있고, `acceptance.md` AC-009가 그 목록이다. 드라이버가 `AIAssistant.swift`를 컴파일한다는 사실은 **인자 경로**를 덮을 뿐 이 조작을 덮지 않는다.

### 미해소 결정 — 착수 승인 게이트에 올린다

**D-1: `AIAssistant`의 단사성 기법 — A안(인자 슬롯 열쇠) vs B안(확정 시점 이름 구분).**

- 미해소 표식은 **`plan.md` §2에만** 있다 — `spec.md`·`acceptance.md`·이 파일에는 두지 않는 관례다(표식 자체를 세는 명령은 `grep -rc` 한 줄이며, SPEC 디렉터리 전체에서 값이 `plan.md` **1**, 나머지 셋 **0**이어야 한다. 이 줄이 표식 문자열을 그대로 싣지 않는 이유가 그것이다 — 실으면 자기가 말하는 계수를 자기가 깨뜨린다).
- 두 안의 비용·새 위험·보임새·렌즈 명단 대조는 `spec.md` §4 D-1과 `plan.md` §2. **권고는 B안**이며, 근거 셋은 ① 읽는 자리 12곳을 건드리지 않아 회귀 면적이 작다, ② 대화 범위 오염이 추가 가드 없이 닫힌다, ③ 결함의 **관측 불가능성**을 함께 고친다.
- **이 결정이 두 가지를 함께 정한다**: M3의 내용, 그리고 M4 렌즈 명단에 `ui-design`이 드는지(B안일 때만 든다 — 확정 칩 글자가 바뀐다). 따라서 **게이트 전에는 `plan.md` §4의 해당 칸이 정해지지 않는 것이 맞다.**
- **M2(`AddEventView`)는 이 결정과 무관하다** — 게이트 대기 중에도 착수 가능하고, 그 사실을 `plan.md` §2 끝줄이 적고 있다.

해소된 결정 둘은 기록만 남긴다: **D-2**(`AddEventView`에 `reseed`/`forgetPlaces`를 옮기지 않는다 — 실측 근거 REQ-020), **D-3**(현재 위치 확정 시 `card == nil`이면 쓰지 않는다 — REQ-004).

### plan 레인 교차 검증 — 인용 정정 1건

plan 레인이 SPEC의 인용을 트리에 대고 독립 재측정했고, **한 건이 두 줄 어긋나 있었다**: §4 D-1 A안의 "같은 조회를 이미 하는 자리"를 `:740-741`로 적었으나 실제는 **`:738-739`**다(`:740`은 `chosen` 대입, `:741`은 닫는 괄호). 레인이 `spec.md:244`를 정정하고 세는 명령(`grep -n "bubbles\[b\].ask?.fields.firstIndex" Shared/AIAssistant.swift`)을 붙였으며, 이 세션이 같은 명령으로 **`:739`**를 재확인했다. HISTORY 0.1.0 행에 정정 사실을 적었다(t3 관례 — 틀린 인용은 덮지 않고 정정으로 남긴다).

나머지 인용은 레인의 독립 재측정과 **전부 일치**했고, 여기에는 이 세션이 브리프를 정정한 세 건도 포함된다 — `:2317`(브리프는 `:2318`), 해석부 호출부 **12곳**(브리프는 ~9곳), `isSamePlace` 증상 분기(`:1297` 유일 호출 · `:1613` 주석이 `create_schedule` 전용임을 명시).

### 잔여 위험 (plan이 적는다)

- **줄번호 드리프트.** 이 SPEC의 인용은 `c5396b3` 기준이고 run이 두 파일을 고치면 밀린다. 밀릴 때마다 실측 재정렬한다. 같은 드리프트가 t5와 `CHECKLIST.md`로 흘러가며, **`CHECKLIST` 인용은 이 카드가 sync에서 본문 바이트 대조로 수리한다**(드리프트를 만든 카드가 수리한다는 t1 이후의 관례).
- **AC-005의 기계 절이 비어 있다.** A안과 B안은 바뀌는 자리가 겹치지 않아 세는 명령이 다르다. 고르기 전에 채우면 고르지 않은 안의 신호를 세게 되므로 비워 둔 것이 맞고, **M1 직후 run이 채운다.**
- **가장 조용한 실패 모양**은 `AddEventView`의 즐겨찾기 경로다(REQ-003). 지금 그 칩이 동작하는 유일한 이유가 "`chosen`의 라벨이 곧 사전 열쇠"이므로, 열쇠만 바꾸고 쓰기 자리를 안 만들면 **즐겨찾기로 고른 일정이 좌표 없이 저장되고 빌드도 드라이버도 잡지 못한다.** AC-003 (4)가 그 반증 신호다.
- **plan 세션은 코드를 한 줄도 건드리지 않았다.** `git status --short`가 새 SPEC 디렉터리 한 줄뿐이므로, run이 받는 트리는 `c5396b3` 그대로다.

### 인계 — plan 레인이 워크트리를 놓는다 (2026-09-22)

리드 요청으로 plan 레인 세션([79cd2f], pid 29072)이 `ExitWorktree(keep)`로 `.claude/worktrees/t6`의 세션 잠금을 놓았다 — run이 `EnterWorktree`를 거부당하고 있었기 때문이다. **`keep`이다**: 브랜치 `WT-place-dict`가 아직 미푸시라 이 나무가 작업의 **유일한 사본**이고, 리드가 병합할 때까지 없애지 않는다.

놓기 직전에 레인이 자기 트리에서 직접 확인한 것 — `git status --short` **빈 출력**(미커밋 잔여 0건), HEAD `8e68316`, 브랜치 `WT-place-dict`. 리드가 같은 사실을 주장했으나 레인이 다시 쟀다(읽고 옮기는 것과 재는 것은 다르다).

**run이 받는 상태**: 소스는 `c5396b3` 그대로이고, 이 브랜치가 더한 것은 `.moai/specs/SPEC-UIKIT-005/` 네 파일뿐이다. **먼저 할 일은 M2가 아니라 M1** — D-1(`plan.md` §2)이 운영자 판정을 기다린다. M3은 그 게이트 전에 착수하지 않는다. M2(`AddEventView`)는 게이트와 무관해 먼저 착수할 수 있다.

### 게이트 통과 — D-1 해소, run 레인 착수 (2026-09-22)

- **D-1 = B안(확정 시점 이름 구분)** — 운영자 확정 2026-09-22, 리드 디스패치로 이 레인에 전달됐다. 바로 위 인계 기록의 "운영자 판정을 기다린다" 서술보다 디스패치가 새 사실이다.
- 결정이 함께 정한 것: **M3의 내용**(B안 — 되읽는 자리 셋 `:2322`·`:2371`·`:2393`과 호출부 12곳은 무변경, 쓰기 자리 `:748`에서 구분 열쇠)과 **M4 렌즈 명단에 `ui-design` 포함**(REQ-022의 유일한 예외 — 겹치는 이름의 확정 칩 글자).
- 미해소 표식(대괄호 영문 표식)을 `plan.md` §2에서 해소 문구로 바꿨다. 계수는 위 '미해소 결정' 절이 적은 세는 명령 그대로 — 이 세션이 편집 직전에 재니 **plan.md만 1·나머지 셋 0**(기록과 일치), 편집 뒤 **전 파일 0**.
- 같은 회차 편집: `plan.md` §1 M1 상태 ⬜→✅(B안, 2026-09-22)·§4 `ui-design` 칸 확정(부른다), `spec.md` §4 D-1 머리말 해소 문구·frontmatter `status: draft → in-progress`·HISTORY 0.1.1행, `acceptance.md` AC-005 A안 절 표시.
- **AC-005 기계 절 정리.** plan 문서는 AC 매트릭스 서두에서 "고르기 전에는 그 절이 비어 있는 것이 맞다"고 적었으나 실제로는 두 갈래(A안·B안)가 **모두** 기록된 채 넘어왔다 — 잔여 위험 절의 "비어 있다" 서술과도 어긋난다. run은 절을 새로 채우는 대신 **A안 절에 채택 안 됨 표시**만 붙였다. B안 절이 이미 그대로 판정에 쓸 수 있어, 새로 쓰면 같은 내용의 소유자가 둘이 된다(계약 5).
- run 레인이 받아서 다시 잰 상태: HEAD `c198719`, `git status --short` 빈 출력, 브랜치 `WT-place-dict`. 소스는 `c5396b3` 그대로다.

## §F Phase 4 Mode Selection

**Mode: serial (sub-agent 순차)** — 근거 셋:

- **M3이 운영자 결정에 막혀 있다.** D-1이 해소되기 전에는 `AIAssistant` 쪽에 착수할 내용 자체가 정해지지 않는다. 병렬로 띄울 두 번째 일감이 게이트 뒤에 있으므로 병렬화할 span이 애초에 없다.
- **두 파일이 파일로는 독립이지만 커밋 대상 브랜치가 하나다.** `Shared/AddEventView.swift`와 `Shared/AIAssistant.swift`는 서로를 읽지 않아 기술적 의존이 없지만(`plan.md` §1), 쓰기 가능한 에이전트 둘을 한 워크트리에 동시에 두는 것은 얻는 것 없이 쓰기 경합만 만든다. 마일스톤별 커밋이 순서의 기계적 보증이 된다.
- **M2가 M3의 학습이다.** `AddEventView`는 t3 본보기가 거의 그대로 통하는 쪽이라 불변식의 모양이 빨리 확인된다. 본보기가 통하지 않는 M3에는 그 모양을 손에 쥔 채 들어가는 편이 낫다(`plan.md` §1 각주).

구현 주체는 `plan.md` §4 배정표 그대로 — M2 `swift-impl` · M3 `ai-tooling`(+B안이면 `ui-design`) · M4 `code-safety` 후 `ux-check`. M1은 결정뿐이라 **0명**이고, plan 단계(이 문서)도 읽기 전용 실측과 문서 작성뿐이라 **0명**이다.

## §E.2 Run-phase Evidence

### M2 — AddEventView 재키잉 (2026-09-22, 구현 swift-impl · 코드 `02481c6`)

- 구현 주체는 plan.md §4 배정표대로 `swift-impl` 전문가. 오케스트레이터가 diff 전문을 대조하고 핵심 신호를 다시 잰 뒤 수용했다.
- 변경: `Shared/AddEventView.swift` 하나(40 삽입·14 삭제). REQ-001~004 + 편집 씨앗 `fields[2].id`/`fields[1].id`(§1.4 (라)). 다른 파일·새 파일 0(REQ-021 — `git status --porcelain`로 확인, xcodegen 불필요).
- 기계 신호 13종(AC-001~004): **12종 초록, 1종은 스펙 자기모순** — AC-001 (1)의 총수 계수(`[String: Place]`=0)가 AC-002 (3)의 `favoritePlaces: [String: Place]`=1과 양립 불가(실측: 총수 1 = 전부 favoritePlaces 선언, `confirmedPlaces: [String: Place]` = **0**). REQ-001·AC-001의 신호를 confirmedPlaces 선언으로 좁혀 정정(spec.md HISTORY 0.1.2).
- 오케스트레이터 재실측(전문가 보고만 믿지 않고): `confirmedPlaces[` = **5** · `confirmedPlaces: [String: Place]` = **0** · `favoritePlaces` = **3** · `confirmedPlace(` 선언 1+호출 6(새 자리 없음) · `confirmedPlaces[Self.hereMarker]` = **0** · `hereMarker` = **8** · `reseed|forgetPlaces` = **0**.
- 빌드(swift-impl이 실행, 로그 `build-ios.log` 142,290B·`build-macos.log` 76,676B — 워크트리 루트 미추적): iOS·macOS 모두 `BUILD SUCCEEDED`. swift 경고 수는 오케스트레이터가 로그에서 다시 잼 — **0 / 0**. 로그에 `AddEventView.swift` 컴파일 단계가 이번 실행분으로 확인됐다.
- 드라이버·프록시는 M4에서 통째로 돌린다 — 이 단계에서 그 컴파일 집합 파일들은 무변경이라 결과가 베이스라인과 결정적으로 같다(REQ-030 (b)).
- **사람 전용 증거 이월**(AC-009가 덮는다): AC-003 (4) 즐겨찾기 칩→이동시간 계산(가장 조용한 실패 지점), AC-004 (3) 현재 위치 프리필, AC-009 전체.
- **후속 등록 1건(REQ-021 계약)**: 직접입력(`submitCustom`)이 장소 줄의 옛 좌표를 지우지 않는다 — 줄 신원 키가 연 실패 모양(옛 좌표가 새 이름에 실려 저장 통과). `AddActivityView`도 같은 구조(오케스트레이터가 `:423-429` 직접 확인). 루트 `plan.md` 후속 **14번**으로 등록, M4 code-safety 렌즈가 재판정한다.

### M3 — AIAssistant B안 단사성 (2026-09-22, 구현 ai-tooling · 코드 `84328e3`)

- 구현 주체는 plan.md §4 배정표대로 `ai-tooling` 전문가. 오케스트레이터가 diff 전문 대조·드라이버 직접 재실행·신호 재측정 뒤 수용했다.
- 변경: `Shared/AIAssistant.swift` 하나(+41/−4). ① `choose(field:place:)`가 신규 `private static confirmedPlaceKey(for:in:)`로 열쇠를 고른다 — 후보 ①이름 ②이름·주소(주소 비면 건너뜀) ③이름·좌표(`%.4f`), 결정적(카운터·시각·랜덤 금지). 다른 좌표에 점유된 후보는 건너뛰고 같은 지점(`isSamePlace` 50m)이면 기존 열쇠를 재사용한다(재선택이 열쇠를 늘리지 않는다). 폴백 `candidates.last ?? place.name`(강제 언래핑 없음). ② `chosen`에도 같은 문자열. ③ 선언 주석 갱신("조회 열쇠 → 좌표, 값은 원래 Place").
- REQ-012 확인(전문가 조사·보고): 사전 값은 원래 `Place`, 해석부 반환은 사전 값 그 자체(재생성 없음), 성공 요약 문구는 전부 해석된 `Place.name`(create_schedule·반복·활동·check·수정 경로 전부), `isSamePlace` 거절 문구도 `origin.name`. 실패 경로 문구는 모델의 원시 질의를 되울러서 찍는데, 정확한 echo면 사전 조회가 먼저 성공하므로 구분 문자열이 도달할 수 없다.
- 기계 신호(오케스트레이터 재측): AC-005 (2) `git diff c5396b3 -- Shared/AIAssistant.swift | grep -c "resolveDestination(_ query\|resolveOrigin(_ query\|unresolvedGenericPlace(_ raw"` = **0**(작업트리 포함). diff hunk가 선언 주석·choose 영역 둘뿐이라 무변경이 구조적으로도 증명된다. `confirmedPlaces[` 첨자 자리 = 쓰기 1 + 읽기 3.
- 드라이버: **205/205 통과** — 오케스트레이터가 이 트리에서 직접 재실행(exit 0). 인자 거동 무변 → `Tools/GuardDriver.swift` 무수정(AC-007 (5) 일치 — 드라이버의 choose 호출 셋이 전부 fresh() 새 인스턴스·고유 이름이라 열쇠=이름 경로만 돈다).
- 결정성 자기점검(전문가 스크래치 8/8, 실행 뒤 삭제·잔여 없음 오케스트레이터 확인): 빈 사전→이름 / 이름 충돌→주소 후보 / 같은 지점 재확정→기존 열쇠 재사용 / 주소까지 같은 다른 지점→좌표 후보 / 주소 비면 좌표로 바로 / 같은 입력 반복→같은 열쇠 / 후보 점유 시 좌표 후보의 같은 지점 재사용. 후보 순서는 (이름, 주소, 좌표)에서만 파생 — 사전 상태와 무관한 순수함수.
- 빌드(전문가 실행): iOS·macOS `BUILD SUCCEEDED`, swift 경고 0/0(로그 `build-ios-m3.log`·`build-macos-m3.log`). 호스트 swiftc의 macOS 26 사용중단 경고는 드라이버 컴파일 환경 것·범위 밖 파일이며 xcodebuild 게이트와 무관.
- **M4 안건 1건(전문가 발견, 보고만)**: 확정 거품 요약 줄(`chosenLine`)이 `chosenLabel`을 그대로 찍으므로 겹칠 때 구분 문자열이 **칩과 함께 이 줄에도** 보인다. REQ-022가 "확정 칩"으로만 적은 것보다 표면이 하나 더 있다 — ui-design 렌즈가 판정하고 스펙 문구를 그 판정에 맞춰 정정한다(현행 줄번호도 렌즈에서 재실측). Store·도구 반환 요약에는 닿지 않는다.
- 사람 전용 증거 이월: AC-005 (4)·AC-006·AC-009 7~14번(시뮬레이터).

### M4 — 대조·게이트·렌즈 (2026-09-22, code-safety + ui-design — 둘 다 읽기 전용)

- **게이트(전부 run 레인 직접 실측)**: 드라이버 **205/205**(M3 항 — 최종 트리에서 재실행) · 프록시 **7/7**(`cd proxy && npm test`, 오케스트레이터 실행) · iOS·macOS `BUILD SUCCEEDED`·swift 경고 **0/0**(최종 트리 = `84328e3` 코드 상태 그대로 — 이후 커밋은 문서뿐이므로 `build-ios-m3.log`·`build-macos-m3.log`가 최종 트리 측정이다).
- **범위(AC-007, 커밋 범위 실측)**: `git diff --name-only c5396b3...HEAD -- 'Shared/*.swift'` = **AddEventView·AIAssistant 정확히 둘** · `--diff-filter=A` **0건**(xcodegen 불필요·Team 재선택 요청 없음) · `reseed|forgetPlaces` **0** · GuardDriver diff **공백**(인자 거동 무변과 일치 — AC-007 (5)) · 보이는 변화 = B안이 강제하는 **세 표면**뿅(ui-design 전수 목록 8항 중 표면 1·2·3만 변화, 나머지 무변경 확인).
- **ui-design 판정 4건**: ① chosenLine 표면 — **(a) 채택**: 칩·거품 줄·재탭 검색창 씨앗 세 표면이 모두 chosen을 그대로 심는 자리다. 한 표면만 숨기면 칩과 거품이 다른 말을 하고 `EditCard`·`EditCardView`는 REQ-021로 못 고쳐 숨김이 구조적으로 절반만 된다. REQ-022·AC-007 (6)·AC-009 (12)(13) 정정 반영(spec HISTORY 0.1.3). ② 보이는 변화 전수 — 세 표면 외 0건. ③ 칩 길이 — **장소 확정 칩은 감기지 않는다**(ChipFlow가 이상적 폭으로 재고 lineLimit·fixedSize 없음; 시각 줄 칩만 감김 modifier 보유). 정적으로 넘침 실재 → **후속 15번** 등록, AC-009 (14)가 실측 지점. ④ Theme 토큰 — diff 추가 줄에서 색·폰트 직접 지정 **0건** 준수(기존 위반 2자리는 후속 16번).
- **code-safety(hazard_coverage 10/10 회전)**: 4대 부류(인덱스 재사용·조용한 실패·외부 한도·복제 계산) **0건**. **should-fix 1건 = 직접입력 옛 좌표(후속 14번) — 유지·격상**: 회귀 방향이 등록 문구보다 심하다(위치 권한 켠 새 일정의 프리필 출발지에 직접입력하면 현재 위치가 그 이름으로 저장 — **기본 흐름 도달**, 즐겨찾기 라벨 타이핑은 정확→부정확, 모르는 이름은 무동작→오저장). 카드 밖 판정 근거 삼중: 쌍둥이가 REQ-021 금지 파일에 있다, AC-003 (1) 계수 신호 재작성이 선행돼야 한다, 수리엔 시뮬레이터 증거가 붙어야 한다. note 4건 — 죽은 폴백(기각, 후보 ③이 원리상 항상 반환 — %.4f↔50m 수학은 구현 검증으로 확인), 마법 인덱스(기각 — §1.4 (라) 의도적·주석 충분), paraphrase↔`ConflictAsk` 반향 비교(관측 메모 — 그릇된 좌표 경로 없음), 쓰기 줄 lockstep(`AddEventView:276`↔`AddActivityView:179` — 후속 14번 수리 때 판정 주석으로 못박는다).
- **후속 등록·갱신(루트 plan.md)**: **14번 격상**(기본 흐름 도달·"Day 닫기·실기기 확인 전 처리" 명기) · **15번 신규**(장소 확정 칩 감김 — `EditCardView` 소관) · **16번 신규**(기존 Theme 위반 2자리 — `AIChatView:114`·`AddActivityView:575`).
- **AC 상태 갱신(acceptance.md 매트릭스)**: AC-001·002·007·008 ✅ · AC-003·004·005 🟡(사람 몫은 AC-009가 덮는다) · AC-006·009 ⬜(시뮬레이터·실기기 실행 대기).
- **줄번호 드리프트 앵커(sync 인용 재정렬용 실측 — 스펙 인용은 전부 `c5396b3` 기준임을 문서가 밝힌다)**: AddEventView `confirmedPlaces` 선언 `:22` · `favoritePlaces` `:26` · choose 쓰기 `:276` · 현재 위치 쓰기 `:447` · `confirmedPlace(_:)` `:537`. AIAssistant `confirmedPlaces` `:52` · `choose(field:place:)` `:761` · `confirmedPlaceKey` `:778` · `isSamePlace` `:2316` · `resolveOrigin` `:2346` · `unresolvedGenericPlace` `:2403` · `resolveDestination` `:2425`.

## §E.3 Run-phase Audit-Ready Signal

- **run_status: audit-ready-for-personal-evidence** — 기계 몫은 전부 통과했고, 카드를 닫는 나머지는 **사람 몫**(AC-006·AC-009)뿐이다. "기계 초록 = 완료"가 아니다(드라이버 초록 다음 날 실기기 결함 7건의 이력 — 이 SPEC §0도 그 문장으로 시작한다).
- run_complete_at: 2026-09-22T17:05+09:00 (M1~M4)
- 커밋: `ebd841c`(M1 게이트) · `02481c6`(M2 코드) · `27d35a5`(M2 문서) · `84328e3`(M3 코드) · `1727585`(M3 문서) · 본 커밋(M4 문서 — 스펙 정정 0.1.3·AC 갱신·후속 3건·이 블록).
- 코드 범위: 두 파일 정확히(REQ-021) · 새 파일 0. 게이트: 드라이버 205/205 · iOS·macOS 무경고 0/0 · 프록시 7/7 — 전부 이 레인 실측.
- 렌즈: code-safety **10/10** · ui-design **4/4**(B안 확정으로 명단 포함 — plan.md §4).
- **운영자 실행 대기**: AC-009 시뮬레이터 14단계(초기화: 설정 → "일정 모두 삭제" 직후 · 즐겨찾기 `집` 1건 등록) + 실기기 4건. AC-006은 그 11번 단계 안에서 함께 돈다. 결과는 이 파일 §E.2에 추가 기록한다.
- **Day 닫기 인계(ux-check)**: t6 사람 증거 + 후속 14번(격상 — **Day 닫기 전 처리**) + 칩 감김 실측(AC-009 (14)·후속 15번)을 UI통일 Day 이월 목록에 합친다.
- **sync 인계**: `CHECKLIST.md` 본문 바이트 대조 수리(드리프트를 만든 카드가 수리 — t1 이후 관례) · 루트 `plan.md` §Phase 1.7 t6 행 갱신 · 스펙 인용 재정렬(§E.2 M4의 드리프트 앵커) · AC-006·009 관측 결과 반영 후 상태 승격.

## §E.4 Sync-phase Audit-Ready Signal

- **sync_status: closed-for-machine-evidence** — 문서 수명주기는 닫혔고(`spec.md` frontmatter
  `completed`), **동작 검증은 닫히지 않았다.** AC-006·AC-009가 ⬜인 채 운영자 실행 대기다. 이
  프로젝트에서 기계 초록은 완료가 아니다 — 2026-09-15 드라이버 88/88 다음 날 실기기 결함 7건이
  그 문장의 출처이고, 이 SPEC §0도 같은 말로 시작한다.
- sync_complete_at: 2026-09-23
- sync_commit_sha: a32ad08 — 다음 커밋에서 백필했다(001·002·003·004와 같은 스키마 필드).
- 커밋: `ebd841c`(M1 게이트) · `02481c6`(M2 코드)·`27d35a5`(M2 문서) · `84328e3`(M3 코드)·
  `1727585`(M3 문서) · `42c29c0`(M4 문서) · `a32ad08`(sync 종결) · 본 커밋(sha 백필). 코드 커밋은
  `02481c6`·`84328e3` 둘뿐이고 나머지는 문서다. sync 커밋의 sha는 **다음 커밋에서** 채운다 —
  커밋은 자기 sha를 담을 수 없고 amend로 적으면 그 순간 다시 어긋나지만(이 sync가 한 번 겪었다),
  별도 백필 커밋은 그 문제에 걸리지 않는다. 001~004가 쓰는 방식이다.
- 이 sync가 만진 파일 넷: `CHECKLIST.md` · 루트 `plan.md` · `spec.md` · `acceptance.md` ·
  이 파일. `Shared/` 아래 변경 **0건** — 코드 상태는 `42c29c0` 그대로다.

### §E.4.1 Claim — 이 sync가 주장하는 것

1. `CHECKLIST.md`의 `AIAssistant.swift` 인용이 최종 트리에 맞게 다시 걸렸다.
2. `AddEventView.swift`는 이 문서에 드리프트를 만들지 않았다.
3. 대조 중 t6 이전부터의 오인용 3건이 잡혀 함께 고쳐졌다.
4. 루트 `plan.md` §Phase 1.7에 t6 행이 생겼고 후속 8번이 닫혔다.
5. `spec.md`에 인용 기준선 재정렬표(12앵커)가 생겼다.
6. AC-008의 기계 게이트 넷이 **이 레인의 실행으로** 통과했다.
7. 판정(✅/⚠️/❌)은 한 칸도 바뀌지 않았다.
8. 본문(근거 문장)을 고친 행은 **P3 하나**다 — t6의 B안이 "이름은 인자에"를 낡게 만들었다.

### §E.4.2 Evidence — 돌린 명령과 관측된 출력

| 명령 | 관측된 출력 |
|---|---|
| `cat Shared/EditCard.swift Shared/AIAssistant.swift Tools/GuardDriver.swift > gd.swift && swiftc … && ./gd` | `205/205 통과`, `exit=0` |
| `cd proxy && npm test` | `7/7 통과` |
| `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build` | `exit=0`, `BUILD SUCCEEDED` 1건, 경고 필터 출력 **공백** |
| `xcodebuild -scheme besir-macOS -derivedDataPath build build` | `exit=0`, `BUILD SUCCEEDED` 1건, 경고 필터 출력 **공백** |
| `git diff --numstat c5396b3..HEAD -- Shared/` | `41 4 Shared/AIAssistant.swift` · `40 14 Shared/AddEventView.swift` |
| `git diff -U0 c5396b3..HEAD -- Shared/AIAssistant.swift \| grep '^@@'` | 헝크 넷 → 이동 폭 +3(:46~746) · +14(:747) · +37(:750~) |
| 인용 바이트 대조(옛 줄 vs 새 줄, 전수) | 154조각 중 **149 일치**, 2는 재작성 구간, 3은 정정 대상 |
| `grep -o '\| ✅ \|' CHECKLIST.md \| wc -l` (⚠️·❌ 동일) | **102 / 8 / 2** — 옛판과 동일 |
| 변경 줄 비교(숫자 외 문자 변화) | 인용 재정렬 판에서 **0건** — 판정·본문 무변경의 기계 증명. P3 본문 정정은 그 확인을 마친 뒤 따로 넣었다 |
| `grep -c '^- \*\*REQ-' spec.md` / `grep -c '^## AC-' acceptance.md` | **11** / **9** — §0 예산 그대로 |
| 앵커 12종 `grep -n` (양쪽 트리) | §E.2 M4 기록과 **전부 일치**(아래 귀속 참조) |

### §E.4.3 Baseline-attribution — 무엇에 대고 쟀나

- 게이트 넷의 기준 트리는 **`42c29c0` + 문서 변경**이다. 두 측정(M4와 이 sync) 사이에 `Shared/`
  커밋은 없으므로 게이트가 덮는 코드 상태는 같다. 그래도 §E.2 M4의 값을 **인용하지 않고 다시
  돌렸다** — 같은 숫자라도 귀속이 다르기 때문이다(§E.1이 같은 이유로 205/205를 두 번 적었다).
- 인용 대조의 옛 트리는 **`c5396b3`**(`git archive`로 전 소스를 꺼내 비교), 새 트리는 작업 트리다.
- §E.2 M4가 적어 둔 앵커 12종은 이 레인이 양쪽 트리에서 각각 `grep -n`으로 다시 재어 **전부
  일치**함을 확인한 뒤 `spec.md` 표에 옮겼다 — 옮겨 적기 전에 셌다.

### §E.4.4 Gaps — 돌리지 않은 것 (증거 없음 ≠ 통과)

- **인용의 의미를 전수 감사하지 않았다.** 오인용 3건은 바이트 대조를 하다 **걸린** 것이지 찾아서
  나온 것이 아니다. 심볼이 인용 구간 안에 있는지 보는 기계 점검이 58조각에만 닿고(나머지는 앞에
  붙은 심볼이 없다), 그 58 중 14건이 걸려 11건은 정당한 호출점 인용임을 확인, 3건이 위의 정정이다.
  **심볼 없는 211조각은 이 점검이 닿지 않았다.** 같은 부류가 더 있는지는 세지 않았다 — ux-check의
  체크리스트 재작성 몫으로 넘긴다.
- **AC-006·AC-009를 돌리지 않았다.** 시뮬레이터 14단계·실기기 4건은 운영자 실행 대기다.
- **실기기 배포를 하지 않았다.** 이 sync는 문서만 만졌다.
- **`--deep` 렌즈는 돌렸다** — 처음에는 "이 sync의 변경이 문서뿐이라 볼 대상이 없다"고 적고
  넘어갔는데, 그것은 렌즈가 판정할 대상을 **이 sync의 diff**로 잘못 읽은 것이다. 리드가 지정한
  `lens: --deep`은 **카드의 코드 작업**에 대한 게이트이고, M4의 code-safety 10/10은 코드를 쓴
  레인이 스스로 내린 판정이라 게이트가 될 수 없다. 독립 패스 결과는 §E.4.7에 있다.

### §E.4.5 Residual-risk — 관측하고도 남는 위험

- **귀속은 사람이 읽어 정했다.** `AIAssistant` 귀속 156조각은 문맥과 함께 읽었지만(고쳐 쓰는
  쪽이 거기까지다) 나머지 113조각은 귀속 목록으로만 훑었고, 어느 쪽도 기계 증명이 아니다. 첫 판이 남의
  파일 인용 다섯을 밀었던 실패가 이 절차의 이유이고, 같은 실패가 남아 있을 확률은 0이 아니다.
  다음 카드가 `AIAssistant.swift`를 다시 밀면 이 판이 새 기준선이 되므로, 틀린 귀속은 그때 증폭된다.
- **후속 14번이 열려 있다.** 직접입력이 옛 좌표를 지우지 않아 기본 흐름에서 오저장까지 간다 —
  t6의 재키잉이 연 방향이다. **Day 닫기·실기기 확인 전에 처리해야 한다.**
- **칩 감김(후속 15번)은 정적 판정이다.** B안의 구분 문자열이 실제로 넘치는지는 AC-009 (14)가
  잴 자리이고, 아직 재지 않았다.
- `git archive`로 꺼낸 비교본은 이 세션의 스크래치에 있다 — 감사 시점에 남아 있지 않다. 대조를
  다시 하려면 `c5396b3`에서 다시 꺼내야 한다(명령은 §E.4.2에 있다).

### §E.4.6 Day 닫기 인계 (ux-check)

1. AC-009 시뮬레이터 14단계 + 실기기 4건 (초기화: 설정 → "일정 모두 삭제" 직후 · 즐겨찾기 `집` 1건).
   AC-006은 11번 단계 안에서 함께 돈다.
2. 후속 **15번**(칩 감김, AC-009 (14)가 실측 지점) · **16번**(기존 Theme 위반 2자리) ·
   **17번**(편집 시 출발지가 현재 위치로 대체 — 시뮬레이터 증거가 붙어야 하는 수리) ·
   **18번**(주석 2건 범위 과다). **14번은 Day 닫기 전 처리 목록에서 빠졌다** — 렌즈가 전제를
   반증해 강등됐다(§E.4.7 F1).
3. `CHECKLIST.md` 인용의 **의미** 전수 감사 — 이 sync가 넘긴 Gap(§E.4.4 첫 항).


🗿 MoAI

### §E.4.7 sync 게이트 `--deep` 렌즈 (독립 패스, 2026-09-23)

read-only code-safety 패스를 카드의 코드 diff(`c5396b3..HEAD -- Shared/`)에 돌렸다. run 레인의
M4 패스와 **같은 렌즈지만 다른 손**이다 — M4는 코드를 쓴 레인이 자기 출력을 판정한 것이라
게이트로 세지 않는다.

**네 부류(인덱스 재사용·조용한 실패·외부 한도·복제 계산)는 0건 — run 레인 판정에 동의한다.**
카드는 오히려 복제를 하나 없앴다(`choosePlace`의 별도 좌표 쓰기가 `choose`의 한 자리로 모였다).
`Task {`·강제 언래핑은 diff에 한 줄도 추가되지 않았다.

**10/10에는 동의하지 않는다 — 간결성·죽은 코드 패스가 카드가 새로 쓴 줄 하나를 놓쳤고, 후속
14번의 심각도가 검증되지 않은 전제 위에 서 있었다.** 발견 여섯 중 셋은 **이 레인이 호출 사슬과
옛 트리를 직접 다시 재어 확인**했고(F1·F2·F3), 나머지 셋은 읽기 판정을 그대로 수용했다.

| # | 내용 | 처리 |
|---|---|---|
| F1 | 후속 14번의 "기본 흐름 도달"이 **도달 불가**다 — 장소 줄에는 자유 텍스트 확정 경로가 없다(`EditCardView:310`이 `.place`를 `placeSearchEditor`로 보내고, `submitCustom` 호출부는 `textCustomEditor` 안의 `:383`·`:384`뿐). 저장되는 이름 서술도 틀렸다(`save()`는 `Place`를 넘긴다) | **루트 `plan.md` 14번 강등** — 기전·심각도·처리 시점 전부 고쳐 적음 |
| F2 | `AddEventView:178`이 **읽힐 수 없는 죽은 쓰기**이고, 그 뒤에 **편집 시 출발지가 현재 위치로 대체되는** 동작이 가려져 있다(`origin_query` 줄에 `chosen:`이 없다). **t6 이전부터 같다** | **후속 17번 신설** — 동작이 바뀌는 수리라 시뮬레이터 증거가 필요해 sync에서 고치지 않았다 |
| F3 | `resolveOrigin`이 즐겨찾기(`:2350`)를 확정 장소(`:2359`)보다 먼저 보므로, 즐겨찾기 라벨과 겹치는 이름은 첫 줄이 여전히 즐겨찾기로 풀린다 — 개선은 맞지만 "넷 전부 닫힘"은 과하다 | **후속 8번 문구에 잔여 명시** |
| F4 | `AIAssistant:756`의 "유일한 보임새 변화" 주석이 틀렸다 — `resolvePendingAsk`(`:905-907`)가 `chosenLabel`로 사용자 말풍선을 만들어 채팅 기록에도 찍힌다. spec HISTORY 0.1.3의 세 표면 판정과 코드 주석이 어긋나 있다 | **후속 18번 ①** |
| F5 | 사전 증가 차원이 "이름 수"에서 "탭한 지점 수"로 바뀌었는데 천장을 명시하지 않았다(한도 위반은 아님) | **후속 18번 ②** |
| F6 | `%.4f` ↔ 50m 짝 판정은 **옳다** — 최악 `≈15.7m`(적도)·서울 `≈14.2m`로 둘 다 50m 안이라 후보 ③ 충돌은 원리상 없고, 폴백을 강제 언래핑 대신 남긴 선택도 옳다. 다만 두 상수를 묶는 것이 주석뿐이다 | 결함 아님 — 상수 결합은 14번에 이미 적혀 있다 |

**렌즈가 검사하지 않은 것**: macOS 빌드(iOS만 쟀다), 가드 드라이버(읽기 전용 지시 + 이 프로젝트의
드라이버 실데이터 사고 이력 때문에 고의로 돌리지 않았다 — 따라서 AI 인자 경로 판정은 전부 코드
읽기 근거다), 프록시(diff가 닿지 않음), `AddActivityView`·`ActivityDetailView`·`EditCardView`의
카드 밖 부분, AC-006·AC-009. **macOS 빌드와 드라이버는 이 sync 레인이 따로 돌려 통과시켰다**
(§E.4.2) — 렌즈의 공백을 레인의 측정이 덮는다.
