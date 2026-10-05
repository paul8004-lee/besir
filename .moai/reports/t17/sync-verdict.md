# t17 sync 판정문 — SPEC-UIKIT-009 (1차)

- 카드 t17 · SPEC-UIKIT-009 · 판정 레인: sync 세션(`--deep`) · 2026-10-05
- 판정한 트리: `38bd215`(브랜치 `WT-edit-card-unify`), 누적 기준 `b2c3987`, 카드 기준 MA `42065af` · MB `61d84b4` · MC `7980190`
- **판정: FAIL.** 차단 2건(B1 · B2), 경고 4건, 메모 7건. 기계 게이트(드라이버 · iOS 빌드 · 범위 · 계약)는 전부 통과했고, 실패의 원인은 게이트가 보지 않는 자리에서 **직접 재현한** 두 결함이다.
- 문서 갱신(AC-021 인용 재사상 · CHECKLIST 행 · 루트 `plan.md`)은 하지 않았다. 수리 커밋이 `Store.swift`·`EditCard.swift`·`ActivityDetailView.swift`의 줄을 다시 움직이므로, 문서 커밋은 코드 커밋 **뒤에** 사상해야 한다(`feedback_besir_refactor_breaks_citations`, 2026-09-25 보강). 도구와 결정표는 준비·드라이런을 끝냈다(§6).

## 1. 주장(Claim)

| # | 주장 | 판정 |
|---|---|---|
| C1 | 최종 트리의 기계 게이트(AC-020)는 통과한다 | 참 — §2.1 |
| C2 | AC 24개 가운데 기계 몫 21개(AC-001~020 · 022)는 문면대로 충족, AC-021은 미판정, AC-023·024는 사람 대기 | 참 — §3 |
| C3 | 활동 카드의 구간 줄은 반복 회차에서 REQ-011대로 나타나지 않는다 | **거짓** — B1 |
| C4 | 활동 카드 저장에서 구간의 이동시간 미계산은 사실대로 보고된다(REQ-010) | **거짓** — B2 |

C3·C4가 거짓이라 카드는 `audit-ready`가 아니다.

## 2. 증거(Evidence)

모든 명령은 이 레인이 이 트리에서 직접 돌렸다. 로그는 `.moai/state/verify/t17-sync/`(gitignored, 이 워크트리 안)에 있다.

### 2.1 게이트(AC-020)

```text
$ (CLAUDE.md 가드 컴파일 명령) → driver-compile.log        compile_exit=0
$ /…/gd-s > driver-run.log                                  run_exit=0
468/468 통과
[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다
```

| 항목 | 관측 |
|---|---|
| ✓ / ✗ | `grep -c '^  ✓ '` = **468**, `grep -c '^  ✗ '` = **0** (기준 `t17-plan/driver-run.log` 357 / 0) |
| 뺀 수 | 기준 ✓ 라벨 정렬본과 `diff … \| grep -c '^<'` = **0**, 더한 라벨 `grep -c '^>'` = **111** (= AF 67 + AG 9 + AH 35, 357 + 111 = 468) |
| 접두별 하한 | AF-001 3 · 002 7 · 003 5 · 004 6 · 005 2 · 007 8 · 008 5 · 009 5 · 010 6 · 012 5 · 013 3 · 014 3 · 015 4 · 018 3 · 019 2 → AF 67(하한 66) · AG-006 6 · AG-011 3 → 9(하한 9) · AH-009 1 · 010 7 · 015 9 · 016 2 · 017 14 · 018 2 → 35(하한 28). **모든 AC 하한 이상.** 누적 하한 460 초과 |
| 컴파일 경고 집합 | 기준 24줄 / 최종 24줄, 줄·열 제거 정렬 `diff` exit 0 |
| iOS 빌드 | `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath …/dd build` → `ios-build.log:943 ** BUILD SUCCEEDED **` · `^SwiftCompile` **42** · 툴체인 안내를 뺀 `warning:` **0** |
| 샌드박스 잔여 | `ls -d $TMPDIR/besir-gd-*` → no matches (남은 것 없음) |
| 재현 기록(AC-020 (5) ⓐ) | 기준 `021f9fd` 트리를 `git archive`로 임시 디렉터리에 풀어 **독립 재실행**: `372/377 통과`, ✗ = `AF-004-01` · `AF-004-02` · `AF-004-05` · `AF-012-02` · `AF-012-05` — run 레인 §E.2 기록과 같은 다섯 라벨 |
| 도달 기록(ⓑ) | 게이트 온라인 실행에서도 `· AF-010-04 실패 분기 도달: 예`, `· AF-009-03 경쟁 도달: 예`. AC는 AF-010-04의 온라인 기대를 "아니오"로 적었다 — **기록일 뿐 판정이 아니다**(AC-010 (4)). 원인은 이 레인이 검증하지 못했다(run 레인은 MapKit ETA 한도로 적었다) |

### 2.2 명령 항목(grep · git diff) — 기대값과 관측

| AC | 명령 | 기대 | 관측 |
|---|---|---|---|
| 001 (2)(3) | `grep -c 'ActivityDetailView(activityId'` · `'AddEventView(editing'` · `'activity(forLeg:'` (EventDetailView) | 1 · 1 · ≥1 | 1 · 1 · 1 |
| 005 (3) | ContentView `linkedActivityId == nil` · `activity(forLeg:` | 0 · ≥1 | 0 · 1 |
| 006 (1)(3) | AddActivityView 빌더 다섯 · EditCard `import SwiftUI` | 0 · 0 | 0 · 0 |
| 006 (2) | 여섯 문구 `grep -rnF … Shared` | 각 1, 모두 `EditCard.swift` | 각 1: `EditCard.swift:343·:344·:496·:490·:507·:514` |
| 006 (9) | 아홉 키 리터럴 AddActivityView · ActivityDetailView · EditCard | 0 · 0 · 표 한 자리 | 0 · 0 · 9 (키마다 1: `uniq -c` 전부 1) |
| 011 (4) | `반복 일정의 한 회차입니다` | ≥1 | 1 |
| 013 (4) | `grep -cF 'store.events.filter { $0.title == event.title }'` | 0 | 0 |
| 014 (2) | `딸린 이동` | ≥1 | 2 |
| 010 (9) | ContentView `e.departureDate != nil` · `e.arrivalDate > dep`(두 파일) · `git grep -c … Store` · `events(on:)`·`recomputeDaysWithSchedule`의 `departureDate` · `failedBlockAnchor`(ContentView/Store) · `isListed(on:` · `listedSpan` | 0 · 0/0 · 무출력 exit 1 · 0/0 · ≥2/≥1 · ≥1 · ≥1 | 0 · 0/0 · 무출력 `exit=1` · 0/0 · 2/1 · 2 · 2 |
| 015 (8) | `overlapSlots`·`overlapColumns` 선언 줄 `grep -c 'ScheduledEvent\|ActivityBlock'` | 0 | 선언 `Models.swift:340`·`:395`, 0 |
| 016 | `gap \* CGFloat\|1 / CGFloat(p.columns)` ContentView · `columnEnds` ContentView/Models · `overlapSlots` ContentView/Models · `struct SlotRange` | 0 · 0/≥1 · 2/1 · 1 | 0 · 0/8 · 2/1 · 1 |
| 019 (1) | `git diff --name-only b2c3987 HEAD -- proxy project.yml Shared/AIAssistant.swift Shared/GoogleCalendarService.swift` | 무출력 | 무출력 |
| 019 (3) | 색 직접 사용 파이프 | 0 (양성 대조 1) | **0** · 양성 대조 `+ .foregroundStyle(.gray)` → **1** |
| 019 (4) | `ScheduleAnchor` 케이스 줄 | 1 = 기준 | `case arrival, departure` 1, 기준과 같다. 보조 신호(판정 아님): 추가된 비-Optional `let` 줄은 `LayoutItem`·`LayoutSlot`·`SlotRange` 같은 **저장되지 않는 새 타입** 안의 것뿐이고, 저장 모델의 옛 JSON 디코딩은 `AF-019-01·02` ✓가 판정한다 |
| 019 (5) | 추가된 `Image(systemName` | (갭) | 0 — 새 아이콘 전용 컨트롤 없음 |
| 019 (6) | `#if os`·`#elseif os`·`canImport(AppKit)` 정렬 집합 diff | 0 | 기준 37줄 = 최종 37줄(`#if os(iOS)` 25 · `#if os(macOS)` 12), diff **0**. 양성 대조: 한 줄 지운 사본 **1** · macOS 줄 더한 사본 **1** · iOS 줄 더한 사본 **0** |
| 019 갭 ⓑ | `.onTapGesture` 코드 줄 | 셋 불변 | 기준 `:618·:641·:674` → 최종 `:627·:650·:685`, 세 줄 모두 존재, `ContentView.swift:190` `#if os(macOS)`도 존재 |

### 2.3 범위(AC-022) — 카드마다 그 카드의 기준 커밋으로

| 카드 | `--name-only`(SPEC 디렉터리·보고서 제외) | `--numstat -- Shared Tools`에서 100줄 이상 | 새 소스 파일 |
|---|---|---|---|
| MA `42065af..61d84b4` | `Shared/Store.swift` · `Tools/GuardDriver.swift` (선언과 일치) | Store 293+32 · GuardDriver 850+0 → **2** | 0 |
| MB `61d84b4..7980190` | ActivityDetailView · AddActivityView · EditCard · EventDetailView · GuardDriver (선언과 일치) | ADV 172+104 · AAV 51+286 · EditCard 430+0 · GuardDriver 203+0 → **4**(한도 4 이하) | 0 |
| MC `7980190..38bd215` | ContentView · Models · Store · GuardDriver (선언과 일치) | ContentView 64+72 · Models 194+0 · GuardDriver 371+0 → **3** (Store 63+19 = 82, 100 미만) | 0 |

## 3. AC 전수 판정(24)

"문면 충족"은 AC가 적은 항목이 전부 기대값이라는 뜻이다. B1·B2는 AC가 보지 않는 자리의 결함이다.

| AC | 관측자 | 이 레인이 직접 본 것 | 판정 |
|---|---|---|---|
| 001 | 기계+사람 | AF-001 ✓ 3/3 · §2.2 (2)(3) · (4)=스크립트 4 | 기계 충족 · 사람 대기 |
| 002 | 기계 | AF-002 ✓ 7/7 | 충족 |
| 003 | 기계 | AF-003 ✓ 5/5. **주의**: 제목만 바뀐 힌트 없는 따라오기(뷰가 실제로 부르는 모양)를 보는 단언은 없다 — B2가 그 자리다 | 문면 충족 |
| 004 | 기계 | AF-004 ✓ 6/6, 기준 트리 ✗ 3건(01·02·05) 독립 재현 | 충족 |
| 005 | 기계+갭 | AF-005 ✓ 2/2 · (3) 0/1 · (4) 갭(앱에 매달린 링크를 넣을 수단 없음) | 기계 충족 · 갭 1 |
| 006 | 기계 | AG-006 ✓ 6/6 · §2.2 (1)(2)(3)(9) | 충족 |
| 007 | 기계 | AF-007 ✓ 8/8 | 충족 |
| 008 | 기계+갭 | AF-008 ✓ 5/5 · 캘린더 갭 유지. **W1**(편집 카드의 `.add`가 활동의 캘린더 제외를 따르지 않음)은 이 AC가 못 본다 | 문면 충족 · 갭 |
| 009 | 기계 | AF-009 ✓ 5/5(경쟁 도달 예) | 충족 |
| 010 | 기계+사람 | AF-010 ✓ 6(하한 5) · AH-010 ✓ 7/7 · (9) 명령 전부 기대값 · 사람 3 대기. **B2**: REQ-010의 뷰 쪽 | 문면 충족 · **REQ-010 위반(B2)** |
| 011 | 기계+사람(갭) | AG-011 ✓ 3/3 · (4)=1. **B1**: 시드만 보고 "장소를 고른 뒤"는 안 본다 | 문면 충족 · **REQ-011 위반(B1)** |
| 012 | 기계 | AF-012 ✓ 5/5, 기준 트리 ✗ 2건(02·05) 독립 재현 | 충족 |
| 013 | 기계+사람 | AF-013 ✓ 3/3 · (4)=0 · 스크립트 8·13 | 기계 충족 · 사람 대기 |
| 014 | 기계+사람 | AF-014 ✓ 3/3 · (2)=2 · 스크립트 10·11 | 기계 충족 · 사람 대기 |
| 015 | 기계 | AF-015 ✓ 4/4 · AH-015 ✓ 9(하한 8) · (8) 0 | 충족 |
| 016 | 기계 | AH-016 ✓ 2/2 · §2.2 (1)(2)(5). 렌더=히트는 점 사각형이 코드 열람으로 성립(드라이버의 AH-018 히트는 비율 히트) → N4 | 충족 |
| 017 | 기계 | AH-017 ✓ 14(하한 9) | 충족 |
| 018 | 기계+사람 | AF-018 ✓ 3/3 · AH-018 ✓ 2/2 · 스크립트 16·19 | 기계 충족 · 사람 대기 |
| 019 | 기계 | §2.2 (1)(3)(4)(6) + AF-019-01·02 ✓. (5) 새 아이콘 전용 컨트롤 0 | 충족 |
| 020 | 기계 | §2.1 (1)~(5) | 충족 |
| 021 | 기계 | 도구·결정표·드라이런(원장 237행) 완료, **문서 미적용** | **미판정**(수리 뒤) |
| 022 | 기계 | §2.3 | 충족 |
| 023 | 사람 전용 | 스크립트 1~13a 미실행 | 🟡 |
| 024 | 사람 전용 | 스크립트 14~22·20a·20b 미실행 | 🟡 |

## 4. 차단 결함

렌즈(`code-safety`, 독립 렌즈 보고)가 코드 읽기로 올린 차단 후보 둘을 이 레인이 **실행으로 재현**했다. 읽기만으로는 가설이다(`feedback_besir_reproduce_lens_positives`).

### B1 — 반복 회차 활동 카드에 구간 줄이 생기고, 저장하면 반복 삭제 뒤 매달린 링크가 남는다 (REQ-011 위반)

원인: 시드 가드(`Shared/EditCard.swift:579` `guard activity.recurrenceId == nil || outbound != nil || returnLeg != nil else { return f }`)는 **시드 때만** 돈다. 장소를 고르면 `LegCardForm.choose`(`:321`, 토글 줄 삽입 `:332-346`)가 반복 여부를 보지 않고 토글 줄을 넣는다. 저장하면 `LegSavePlanner`가 `.add`를 내고 `Store.addLeg`(`:461-505`)에는 반복 회차 검사가 없다.

재현 1 — 폼 전이(렌즈가 만든 탐침을 이 레인이 읽고 다시 실행: `lens-cs/probe.swift`):

```text
$ lens-cs/probe
seed leg rows: 0
after place change leg rows: ["outbound_enabled", "return_enabled"]
ops: [probe.LegSaveOp.add(role: probe.ScheduleAnchor.arrival, outerPlace: probe.Place(name: "집", …), mode: probe.TransportMode.transit, bufferMinutes: 10, notifyLeadMinutes: 30, notifyEnabled: true)]
```

재현 2 — Store 연쇄(이 레인이 새로 쓴 `repro/repro-b1.swift`, 드라이버와 같은 임시 홈 샌드박스, 지원 디렉터리가 샌드박스 밖이면 시작 거부):

```text
[전] 활동 1건(recurrenceId 있음=true), 구간 0건
[addLeg 결과] created(travelKnown: true)
[후] 명시적 구간 1건 — leg.recurrenceId=nil
[반복 전체 삭제 뒤] 활동 0건, 남은 구간 1건
[반복 전체 삭제 뒤] 활동 id를 가리키는 구간 1건 — store.activity(forLeg:)=nil (nil이면 매달린 링크)
```

의미: 이 카드가 REQ-006·012로 닫았다고 주장하는 "매달린 링크"가 다른 경로(반복 회차 편집)로 다시 생긴다. `deleteRecurringSeries`(`Store.swift:975-990`)는 `recurrenceId`로만 지워서 `recurrenceId`가 없는 명시적 구간을 남긴다. 알림·캘린더 항목도 함께 남는다(코드 읽기).

도달 경로: 반복 회차 활동을 편집 → 장소 변경 → 가는/오는 이동 `만들기` → 저장. (AI의 "반복 전체 삭제"는 CHECKLIST E2.)

수리 방향(제안): ① `LegCardForm`에 "반복 회차·명시 구간 없음" 상태를 시드에서 들고, `choose`의 토글 삽입을 건너뛴다. ② `Store.addLeg`도 같은 조건이면 거절한다(방어). ③ 드라이버: `AG-011-04`(반복 회차 폼에서 장소를 고른 뒤에도 구간 줄 0개), `AF-009-06`(반복 회차 활동에 `addLeg` → 거절).

### B2 — 활동 카드 저장의 따라오기(`realignLegs`) 결과가 버려져, 추정이 실패하면 이동시간이 조용히 사라진다 (REQ-010 위반)

원인: `Shared/ActivityDetailView.swift:334` `_ = await store.realignLegs(of: a.id)` — 힌트를 안 넘기고 결과도 버린다. `Store.realignLegs`(`:587-600`)는 제목·끝점·앵커가 하나라도 다르면 `updateEvent(travelSecondsHint: nil)`을 불러 **네트워크로 다시 추정**하고(`:1247-1248`), 추정이 실패하면 `applyEstimate`가 먼저 알림을 취소하고 `travelSeconds`·`departureDate`를 비운 채 끝난다(`:1267-1273`). 뷰의 안내 `messages`(`:367-375`)는 `ops` 루프(`:339`~)의 결과로만 채워진다.

재현 — `repro/repro-b2.swift`(같은 샌드박스, 구간 둘에 이동시간 1800초 힌트를 주고 **제목만** 바꾼 뒤 뷰와 같은 순서로 `modifyActivity` → `realignLegs(힌트 없음)`):

```text
# 추정 실패 주입 — 구간 수단 transit, 프록시 비움(이 환경에서 MapKit이 transit ETA를 못 준다)
[저장 전] 가는 편: title=원래 제목 travel=Optional(1800.0) dep=있음 … failedBlockAnchor=nil
[저장 전] 오는 편: title=원래 제목 (복귀) travel=Optional(1800.0) dep=있음 … failedBlockAnchor=nil
[제목만 바꾼 저장 뒤] 가는 편: title=새 제목 travel=nil dep=nil … failedBlockAnchor=있음(경고 블록)
[제목만 바꾼 저장 뒤] 오는 편: title=새 제목 (복귀) travel=nil dep=있음 … failedBlockAnchor=있음(경고 블록)
[realignLegs 결과] 가는 편=Optional(…LegOutcome.updated(travelKnown: false)) 오는 편=Optional(…LegOutcome.updated(travelKnown: false))
[뷰가 모으는 안내] (비어 있음 → dismiss, 사용자는 아무것도 못 본다)

# 양성 대조 — 수단 walk, 추정 성공
[제목만 바꾼 저장 뒤] 가는 편: title=새 제목 travel=Optional(13567.0) dep=있음 … failedBlockAnchor=nil
[realignLegs 결과] 가는 편=Optional(…LegOutcome.updated(travelKnown: true)) 오는 편=Optional(…LegOutcome.updated(travelKnown: true))
```

정확히 말하면 "오프라인"이 아니라 **추정 실패**를 주입한 재현이다. `sandbox-exec (deny network*)`는 이 프로세스의 직접 네트워크만 막고 MapKit(시스템 데몬)은 막지 못했다 — walk의 "오프라인" 실행도 추정에 성공했다(`b2-offline-walk.log`). 그래서 제품에서 같은 일을 일으키는 조건은 추정이 실패하는 모든 경우다: 네트워크 단절, 카카오 할당량 소진, 경로 없음.

의미: 지하철에서 활동 이름만 바꿔 저장해도 두 구간이 경고 블록이 되고, 기기에서는 출발 알림이 취소된 채 되살아나지 않는다(`applyEstimate`는 취소만 하고 재예약은 추정 성공 때만). 도착 기준 실패 구간은 `refreshUpcomingEstimates` 대상에서도 빠진다(SPEC plan §6, 기존 동작). 알림 취소의 기기 효과는 비번들 실행이라 관측하지 못했다(코드 읽기).

추가로 `progress.md` §E.2 MC code-safety ④(b)의 "재쓰기는 같은 hint 재사용이라 새 네트워크 조회를 만들지 않는다"는 사실이 아니다(뷰 경로의 hint는 항상 nil, 렌즈 N5).

수리 방향(제안): ① `Store.realignLegs`: 끝점이 그대로이고 제목·앵커만 다르면 `leg.travelSeconds`를 힌트로 넘겨 추정을 건너뛴다(네트워크 없음, 값 손실 없음). ② `ActivityDetailView.save()`: `realignLegs` 결과의 `travelKnown == false`를 `unknownTravel`에 합친다. ③ 드라이버: `AF-003-06`(제목만 바꾼 힌트 없는 따라오기 뒤 `travelSeconds`가 유지된다 — 현재 HEAD에서는 온라인에서도 1800이 아니라 새 추정값으로 바뀌므로 **✗가 되는** 회귀 단언).

## 5. 경고 · 메모

| id | 분류 | 내용 | 처분 |
|---|---|---|---|
| W1 | 경고 · 코드로 확정 | 편집 카드의 `.add`가 `syncToCalendar`를 안 넘겨(`ActivityDetailView.swift:350`) 기본 `true`(`Store.swift:469`) — "캘린더 안 함" 활동에 가는 편을 붙이면 그 구간이 구글 캘린더에 오를 수 있다(REQ-008) | **B1·B2와 같은 수리 커밋에서 닫기를 권고** — `addLeg`의 기본을 `activity.wantsCalendarSync`로 |
| W2 | 경고 · 가설(재현 안 함) | 한 번의 저장에서 같은 구간에 `updateEvent`가 두 번 돈다(realign → updateLeg, 또는 `activityIfChanged` 재쓰기). 둘째의 await 전 스냅샷이 그 사이 업로드 큐가 적은 `googleEventId`를 덮어 중복 캘린더 항목이 생길 수 있다 | 후속 카드 후보. 가설이므로 FAIL 근거로 쓰지 않았다 |
| W3 | 경고 · 가설(재현 안 함) | realign이 제거 연산보다 먼저 돌아 곧 지울 구간을 다시 쓰며 업로드를 큐에 올린다 | B2 수리 때 순서(제거 → 따라오기)를 함께 바꾸는 것을 권고(비용 거의 없음) |
| W4 | 경고(낮음) · 코드로 확정 | `AIAssistant.swift:2644` 실패 표지는 `departureDate == nil`, 시간표는 `failedBlockAnchor` — 갈라짐을 만든 것은 이 카드(SPEC `spec.md:222`가 받아들인 갭) | 후속 목록(SPEC plan §6에 이미 있음) |
| N1 | 메모 | 저장 중 잠금은 "닫기" 버튼만 막는다. 시트 쓸어 내리기·삭제 버튼(`:83`)은 안 막고, 주석(`:20-25`)의 "시트가 내려가는 것을 막는다"는 사실보다 넓다 | 후속 |
| N2 | 메모 | `EditCard.swift:590-606`의 `first{…}!`가 "장소 없는 활동 + 명시 구간"에서 트랩(탐침 exit 133). 현재 생산자 없음 | 후속(옛/손상 JSON만) |
| N3 | 메모 · 가설 | `ContentView.swift:726` `Dictionary(uniqueKeysWithValues:)`는 id 중복에서 트랩 — 중복을 만드는 경로를 못 찾음 | `uniquingKeysWith:`로 바꾸면 비용 없이 막힌다(후속) |
| N4 | 메모 | 렌더 `max(f.width,1)`(`ContentView.swift:740`)와 히트 raw 폭(`:760`)이 다르다 — 폭 < 1pt, 320pt 기준 108열부터 | 후속(`SlotRange.points`로 하한을 옮기면 단일 출처 회복) |
| N5 | 메모 | `progress.md` §E.2 ④(b) 서술이 거짓(§4 B2) | run 레인이 정정 |
| N6 | 메모 | `addActivityWithTravel`이 `LegOutcome`을 버리고 `made += 1`(기존 패턴) | 후속(AI 경로) |
| N7 | 메모 | REQ-012 이후 `deleteActivities`가 연결 구간까지 지우는데 AI 결과 `totalCount`는 제목·날짜가 맞은 것만 센다(`AIAssistant.swift:2908-2911`) | 후속(AI 경로) |

간결성 제안(렌즈, 수정 안 함): `realignLegs`의 둘째 `updateEvent` 블록을 `updateLeg`처럼 지역 `write`로 합치기 · `deleteActivity`가 `deleteActivities([a])`를 부르게 하기 · `linkedLegs`의 명시 분기가 `legs(of:)`를 부르게 하기 · `removeExplicitLegs`의 `linkedActivityId!` 제거.

### Card Cross-Check (후속 ↔ 대기열 카드)

| 후속 | 대기열 카드(`moai todo`로 확인) | 비고 |
|---|---|---|
| W4 · N6 · N7 (AI 경로) | SPEC plan §6이 t30·t18·t20 몫으로 적음 | t30(AI 카드 문법 통일)·t18(대화 메모리)·t20(수정 경로 출발지 대체)에는 이 항목 본문이 **없다** — 카드 요청 때 본문에 더해야 한다 |
| N1 · N2 · N3 · N4 · W2 | 대기열에 없음 | 새 카드 후보. 리드가 묶음을 정한다 |

## 6. 인용 재사상(AC-021) — 준비 상태

- 문서에는 아직 손대지 않았다. 도구는 `.moai/state/verify/t17-sync/cite/{extract,review,review2,apply}.py`(gitignored, 이 워크트리에 남는다). 드라이런 결과: 토큰 596개 추출 → 원장 **237행**(이력 보존 70 · 재사상 83 · 이동량 0 42 · 귀속 오류 19 · 재측정 2 · 서술 갱신 21), 미결정 0.
- 이번 드라이런에서 **자동 귀속이 틀린 것**을 잡았다: K9의 `span(for:on:) :542·557`(앞의 `Store.swift:38`에 끌려 `Store`로 귀속 — 실제는 `ContentView`) 2건, `weeksField :735-741`·`:140-142` 2건(`AIAssistant` 심볼), `gatedRows :179-182·:201-204` 2건(`AddEventView`). 그대로 옮겼다면 맞는 인용을 틀린 값으로 덮었을 것이다.
- 본문이 바뀌어 사상할 수 없는 좌표(`AddActivityView :509`→`:274`, K9의 `ContentView :92`→`isListed` `:88`, 후속 11·14번의 `anchored: false`·쓰기 줄 → `EditCard.swift:573·:575·:330`)는 재측정했다.
- 정책: 머리말(<178줄) 기준선 문단과 "당시/그날 좌표" 서술, 닫힌 카드 행은 옮기지 않는다. 표 행 · "현행"이라 밝힌 방어 서술 · 열린 후속(11·14) · "현 좌표" 문장은 옮긴다.
- 선재 드리프트(이 카드 소행 아님, 옮기지 않음): `AddEventView.swift:119` → 실제 `:138`(t11 삽입), `EditCard.swift:294`(2026-09-16 관찰 블록, base에서 이미 어긋남). t29(cite_check) 영역.
- 재sync에서 할 일: 수리 커밋이 끝나면 `extract.py`·`apply.py`의 `HEAD` 상수만 바꿔 다시 돌린다. 이어서 원장 문자열 대조 · 양성 대조 · CHECKLIST 행(K5·K8·K9 서술, D9~D11 · E6~E8 · K11 · K12 새 행, 이월 8번) · 루트 `plan.md`(카드 표 t17 행 — 현재 t16 행에서 끝남, 후속 11·14 좌표, 새 후속) 갱신.

## 7. 귀속(Baseline-attribution) · 못 본 것(Gaps) · 잔여 위험(Residual-risk)

**귀속.** 위 모든 수치는 이 레인이 `38bd215` 트리에서 §2의 명령으로 직접 얻은 것이다. 이전 측정에서 가져온 값은 기준 로그(`t17-plan/driver-run.log` 357/0, 경고 24줄)와 카드 기준 커밋 SHA뿐이고, 둘 다 비교 대상으로만 썼다. 로그 위치: `.moai/state/verify/t17-sync/{driver-compile,driver-run,ios-build,base021-compile,base021-run}.log`, `repro/{b1-store,b2-online,b2-offline,b2-online-walk,b2-offline-walk}.log`, `lens-cs/`.

**Gaps (관측하지 않은 것).**
- 시뮬레이터·실기기 동작 전부(AC-023·024의 스크립트 25단계). 알림 취소·재예약의 기기 효과(비번들 실행이라 `NotificationManager.center`가 늘 nil).
- `ui-design` 렌즈는 sync에서 다시 돌리지 않았다 — run 레인 MB·MC 보고(결함 0)는 읽기만 했고 재검증하지 않았다. 새 아이콘 전용 컨트롤이 0이라는 것(`Image(systemName` 0)만 직접 쟀다.
- W2·W3은 타이밍 의존 가설이라 재현하지 않았다. B2의 "알림이 취소된다"는 코드 읽기다. B1의 "알림·캘린더 항목이 남는다"도 코드 읽기다.
- 구글 연결 상태(키체인·OAuth)는 드라이버 불변식이 막아 둔 영역이라 건드리지 않았다.
- AF-010-04가 온라인 게이트에서 "도달: 예"인 원인(run 레인 주장: MapKit ETA 한도)은 검증하지 못했다.
- `GuardDriver.swift`의 AF·AG·AH 단언 본문 전수 열람은 하지 않았다(라벨 존재·수·✓만 쟀다).

**잔여 위험.**
- 이 FAIL은 렌즈와 이 레인이 본 범위에서 나온 것이다. 수리 뒤 재sync에서 렌즈를 **수리 diff에** 다시 돌려야 한다 — 같은 부류(뷰가 Store 결과를 버리는 자리)가 `ActivityDetailView.save()` 안에 더 있는지는 다시 봐야 한다.
- B1 수리는 `choose`와 `addLeg` 두 곳을 건드린다. 둘 중 하나만 고치면 다른 한쪽 경로(AI 등)로 다시 열린다.
- 드라이버 468/468이 초록인 트리에서 이 둘이 나왔다 — 기계 초록은 완료가 아니다(2026-09-15 88/88 다음 날 결함 7건 선례).

## 8. 재sync 체크리스트

1. 수리 커밋(B1 · B2, 권고 W1·W3) 후 `git rev-parse --short HEAD`를 §E.2 카드별 칸에 MD(t17-d 등)로 적는다.
2. 게이트 재실행: 드라이버(≥ 468 + 새 단언) · 뺀 수 0 · iOS 무경고 · 경고 집합 24줄 · AC-022 범위.
3. B1·B2 재현 하네스(`repro/repro-b1`·`repro-b2`)를 다시 돌려 기대 출력 확인: B1은 `addLeg` 거절 · 구간 0건, B2는 제목만 바꾼 따라오기 뒤 `travel=Optional(1800.0)` 유지.
4. `code-safety`를 수리 diff에 다시 돌린다.
5. 원장 재생성 → 문서 적용 → 양성 대조 → 새 행 · `plan.md` t17 행 · 이월 8번 갱신 → `progress.md` §E.4 갱신 → 3-phase close.

🗿 MoAI
