# SPEC-UIKIT-012 — acceptance.md

수락 기준(0.7.2 — 0.6.1이 감사 5회차를 받았고, 0.6.2 이후 판은 미감사). 검증 수단은 셋이다.

- **D — 드라이버(결정적, 네트워크 없음)**: `Tools/GuardDriver.swift` AF-018·AF-015 절. 구간은 `afInjectedLeg`(`:3806-3817`), 활동은 `ActivityBlock` 값. 하위 사례마다 새 픽스처. 종료 코드 0 · 1 · 2 · 3 · 124.
- **G — 구조 대조**: `grep`·`awk`·`shasum`. `diff <(…)`는 워크트리 가드가 거부하므로 쓰지 않는다. 기준 트리 `b59fcaa`에서 다른 값이면 양성 대조, 같으면 회귀선. 기준 트리에 패턴이 아예 없는 대조는 손으로 만든 입력(`printf … | grep -c`)으로 명령이 작동함을 보인다.
- **S — 시뮬레이터(사람)**: 손 느낌·미리보기·연장·자동 스크롤·탭·대화상자·알림. UIKit 제스처·스크롤·타이머는 드라이버가 닿지 않는다.

"기준" 열은 코드 읽기 예상이다(run M1이 관측해 §E.2에 남긴다).

## AC 매트릭스

| AC | 제목 | REQ | 구분 |
|---|---|---|---|
| AC-001 | 오는 편 드래그 → 활동 끝 · 옛 틈 유지 | 001 · 003 | D |
| AC-002 | 가는 편 드래그 → 활동 시작 | 002 · 003 | D |
| AC-003 | 소유 없는 구간은 지금 동작 | 005 · 014 | D · G |
| AC-004 | 최소 5분 · 실제 길이 그리기 | 006 | D · G · S |
| AC-005 | 자정 넘기기 · 위로 자르기 · 아래 상한 | 007 | D |
| AC-006 | 유효 Δ 단일 함수 · 드롭 재읽기 · Δ = 0 | 008 | D · G |
| AC-007 | 미리보기 = 확정 | 009 | G · S |
| AC-008 | 소유 조회 · 반복 범위 · 대화상자 키 | 004 · 010 · 011 | D · G |
| AC-009 | 경고 블록 · 방향별 자르기 | 001 · 002 · 007 · 008 | D |
| AC-010 | 동기성 · 구글 미반영 · 저장 · 복제 · 언래핑 | 003 · 010 · 012 | G |
| AC-011 | 드라이버 마감 · 범위 · 빌드 | 013 · 014 | D · G |
| AC-012 | 시뮬레이터 | 001 · 002 · 006 · 007 · 009 · 010 · 011 · 015 · 016 | S |
| AC-013 | 끄는 중 시간표 연장 | 009 · 015 | G · S |
| AC-015 | 자정을 넘어도 한 묶음(정확한 앵커 시각 대조만) | 016 · 004 | D · G |
| AC-016 | 가장자리 자동 스크롤 | 015 | G · S |

(AC-014는 0.6.0에서 카드 t48 인계 파일로 옮겼다 — 번호를 다시 쓰지 않는다.)

## AC-001 — 오는 편 드래그 → 활동 끝 · 옛 틈 유지 ⬜

- **Given** 1시간 활동과 명시 연결된 오는 편 **When** ±15로 놓으면 **Then** 끝이 Δ, 시작 그대로, 출발 = 새 끝, 여유·이동시간·가는 편 동일.

| 단언 | 기대 | 기준 |
|---|---|---|
| AF-018-02(고쳐 쓰기) · AF-018-04 | +15 · −15 | ✗ |
| AF-018-22 | 틈 30분 오는 편 +15 → 틈 유지 | ✗ |

## AC-002 — 가는 편 드래그 → 활동 시작 ⬜

- **Given** 가는 편(여유 20) **When** ±15 **Then** 시작이 Δ, 끝 그대로, 도착 = 새 시작, 여유 20.

| 단언 | 기대 | 기준 |
|---|---|---|
| AF-018-03(고쳐 쓰기) · AF-018-05 | +15 · −15 | ✗ |

## AC-003 — 소유 없는 구간은 지금 동작 ⬜

AF-018-11·12·13·21(기준 ✓). **G**: `awk '/func adjustTravelLeg/,/^    }$/' Shared/Store.swift | grep -c 'adjustBuffer('` 1 이상(기준 1) · `git diff --quiet b59fcaa -- Shared/AIAssistant.swift; echo $?` 0.

## AC-004 — 최소 5분 · 실제 길이 그리기 ⬜

- **Given** 1시간 활동(오는 편)과 3분 활동(가는 편) **When** −60, +5, −15 **Then** 1시간 활동은 5분에서 멈추고(−55), 3분 활동은 +5가 0, −15는 적용(18분).

| 단언 | 기대 | 기준 |
|---|---|---|
| AF-018-06 | −55, 끝 = 시작 + 5분 | ✗ |
| AF-018-07 | +5 → 0 && −15 → −15 | ✗ |

**G** — 그리기 최소 높이가 5분이고 이동 구간 16분은 그대로:

```bash
grep -c 'minActivityMinutes: CGFloat = 5$' Shared/ContentView.swift
grep -c 'minActivityMinutes: CGFloat = 20' Shared/ContentView.swift
grep -c 'minTravelMinutes: CGFloat = 16' Shared/ContentView.swift
```

기대 **1 · 0 · 1**. 기준 **0 · 1 · 1**(첫째·둘째가 양성 대조, 셋째는 회귀선 — 이 레인 실측). 드래그 최소 길이는 Store 상수 하나(`grep -n '<run이 붙인 이름>.*= 5' Shared/Store.swift` 한 줄).

**S**: S-5 · S-18.

## AC-005 — 자정 넘기기 · 위로 자르기 · 아래 상한 ⬜

| 단언 | Given · When | Then | 기준 |
|---|---|---|---|
| AF-018-08 | 활동 22:00–23:00, 오는 편 23:00→23:20 · +90 | **+90**, 활동 D·D+1 나열, 구간 D+1만 | ✗ |
| AF-018-09 | 가는 편 00:20→00:40 · −30 | **−20** | ✗ |
| AF-018-10 | 걸친 오는 편 +15 · 새 픽스처 −15 · 밤샘 −30 | **+15 · −5 · −30** | ✗ |
| AF-018-26 | 오는 편 23:00→23:20 · +1500 | **+1480**, D+1만 | 해당 없음 |
| AF-018-23 | 요청 −180…+180 격자 | 위로 나열 불변 · 아래로 마지막 나열일 ≤ max(F+1, L) · 유효 Δ는 0과 요청 사이 | 해당 없음 |

## AC-006 — 유효 Δ 단일 함수 · 드롭 재읽기 · Δ = 0 ⬜

- **D**: AF-018-24(−30 → −20, 지운 구간 사본은 불변) · AF-018-15(Δ = 0). AF-018-06~10·26은 한계 함수 반환값 = 실제 변위를 `&&`로 함께 본다.
- **G**: `awk '/onChange: \{ dy in/,/\},/' Shared/ContentView.swift | grep -c 'store\.'` 1 이상, 기준 **0**(양성 대조).

## AC-007 — 미리보기 = 확정 ⬜

- **G**: `awk '/func span\(for event/,/^    }$/' Shared/ContentView.swift | grep -c 'legDragShift\|activeDrag'` · 같은 꼴 `span(for activity` — 1 이상 · 1 이상, 기준 **0 · 0**.
- **G — 바뀌지 않는 함수(해시)**:

```bash
git show b59fcaa:Shared/ContentView.swift | awk '/private func offsetY/,/^    }$/' | shasum
awk '/private func offsetY/,/^    }$/' Shared/ContentView.swift | shasum
git show b59fcaa:Shared/ContentView.swift | awk '/private func finalizeDrag/,/^    }$/' | shasum
awk '/private func finalizeDrag/,/^    }$/' Shared/ContentView.swift | shasum
```

기대 첫째 = 둘째(`2cd32a58…`), 셋째 = 넷째(`3027e8ee…`). 같은 꼴로 `Shared/Store.swift`의 `/private func realignReturnLeg/,/^    }$/`도 기준과 작업 트리의 해시가 같다(`a6ca6f17…`, 8줄) — 이 카드는 그 함수를 바꾸지 않는다(그 갭은 카드 t49, spec §4). **`moveActivity` 본문도 같은 대조에 든다**(REQ-014, 0.7.0 — 운영자 4차 답변): 기준 트리와 작업 트리에서 `awk '/func moveActivity\(/,/^    }$/' Shared/Store.swift | shasum`이 같아야 한다 — 기준 `ab65d72c…`(22줄, 이 레인 실측). 이 레인이 기준·작업 트리(코드 동일)에서 실제로 돌린 값.
- **G — 소유 조회는 `onBegin`에서만**(REQ-009, 감사 2회차 N-2). run이 붙인 Store 소유 조회 함수 이름을 `<owner>`, 뷰 도우미 이름을 `legDragShift`(다르면 그 이름)로 두고, 0.4.1 판의 명령 묶음을 그대로 돌린다:

```bash
# 범위 확인(빈 범위면 아래 계수가 거짓 0을 낸다 — 먼저 1줄 이상인지 본다)
awk '/func span\(for activity/,/^    }$/' Shared/ContentView.swift | wc -l
awk '/func span\(for event/,/^    }$/' Shared/ContentView.swift | wc -l
awk '/func dragOffsetMinutes\(forEvent/,/^    }$/' Shared/ContentView.swift | wc -l
awk '/func legDragShift|var legDragShift/,/^    }$/' Shared/ContentView.swift | wc -l
awk '/onChange: \{ dy in/,/\},/' Shared/ContentView.swift | wc -l
awk '/onBegin: \{ x, y in/,/\},/' Shared/ContentView.swift | wc -l
# 금지 패턴 계수
awk '/func span\(for activity/,/^    }$/' Shared/ContentView.swift | grep -c '<owner>'
awk '/func span\(for event/,/^    }$/' Shared/ContentView.swift | grep -c '<owner>'
awk '/func dragOffsetMinutes\(forEvent/,/^    }$/' Shared/ContentView.swift | grep -c '<owner>'
awk '/func legDragShift|var legDragShift/,/^    }$/' Shared/ContentView.swift | grep -c '<owner>'
awk '/onChange: \{ dy in/,/\},/' Shared/ContentView.swift | grep -c '<owner>'
awk '/onBegin: \{ x, y in/,/\},/' Shared/ContentView.swift | grep -c '<owner>'
```

기대(마감 트리): 범위 확인 여섯 줄 모두 **1 이상**, 금지 패턴 계수는 앞 다섯이 **0**, `onBegin`이 **1**. 기준 트리 실측(0.6.3 — `progress.md` §E.1 0.6.3 표): 범위 확인 **14 · 35 · 4 · 0 · 4 · 5**(넷째 0 = 도우미가 아직 없음), 손으로 만든 입력의 양성 대조 `printf 'func span(for event: X) {\n        let o = store.owningActivity(forLeg: e)\n    }\n' | awk '/func span\(for event/,/^    }$/' | grep -c 'owningActivity'` → **1**, 그 줄을 뺀 입력 → **0**. 프로세스 치환 `diff <(…)`는 쓰지 않는다(워크트리 가드가 거부 — 바뀌지 않는 함수는 위 `shasum` 비교).
- **G — 자르기 비교**: `awk '/func span\(for activity/,/^    }$/' Shared/ContentView.swift | grep -v '^ *//' | grep -c '1440'` · 같은 꼴 `span(for event` 기대 **0 · 0**, 기준 **1 · 1**(양성 대조).
- **S**: S-1·S-3·S-5·S-8.

## AC-008 — 소유 조회 · 반복 범위 · 대화상자 키 ⬜

AF-018-16(−15·−15·−10) · 18 · 19 · 20 · 17(✓). **G**: `awk '/private func finalizeDrag/,/^    }$/' Shared/ContentView.swift | grep -c 'if e.recurrenceId != nil'` 1, 기준 1.

## AC-009 — 경고 블록 · 방향별 자르기 ⬜

AF-018-14(경고 블록 ±15) · AF-018-25(이틀 넘는 구간 +15 → 0, −15 → −15, 옛 경고 블록 +15 → +15). 기준 ✗.

## AC-010 — 동기성 · 구글 미반영 · 저장 · 복제 · 언래핑 ⬜

`adjustTravelLeg`와 새 경로가 부르는 새 Store 함수 전부의 본문을 `.moai/state/verify/t43/`에 잘라 센다(`mkdir -p` 먼저).

| 대조 | 기대 | 기준 |
|---|---|---|
| `grep -c 'Task {\|await\|try?'` | **0**(함수마다) | `adjustTravelLeg` 0 — 회귀선. 패턴 작동: `grep -c 'Task {' Shared/Store.swift` 8 |
| **구글 미반영**(REQ-012, 0.4.1 대조 복원): `grep -c 'Task {\|removeFromCalendar\|enqueueCalendarUpload\|googleEventId'` | **0**(함수마다) | `adjustTravelLeg` **0**(회귀선). **양성 대조**: `awk '/func updateActivity\(/,/^    }$/' Shared/Store.swift \| grep -c 'Task {\|removeFromCalendar\|enqueueCalendarUpload\|googleEventId'` → **6**(이 레인 실측) — 구글 경로가 있으면 잡는다 |
| 저장 위치 | 저장·정렬·재예약 줄이 루프 닫는 괄호 뒤("전체": 재예약 1·`save()` 0, "이 일정만": `save()` 1) — 읽기 판정 | 루프 `:1400`–`:1408`, 저장 `:1409` |
| `grep -c 'addingTimeInterval(-' Shared/Store.swift` | 5(증가 0) | 5 |
| 강제 언래핑: `git diff b59fcaa -- Shared/Store.swift Shared/ContentView.swift \| grep '^+' \| grep -v '!=' \| grep -c '[])a-zA-Z]!'` | **0** | — |

## AC-011 — 드라이버 마감 · 범위 · 빌드 ⬜

1. 기준 실행: `P/T 통과` 원문(기대 `498/498`) → B.
2. 마감: ✗ 0 · exit 0 · **T = B + 25**(고쳐 쓴 5 — 02·03·21b·AF-015-09·11 · 더한 25 — AF-018-04~27·29, 0.7.3). AF-018-01~27·29·AF-015-09·11의 ✓ 줄을 §E.2에.
3. 결정성: `git diff b59fcaa -- Tools/GuardDriver.swift | grep '^+' | grep -c 'addRecurringEvents\|await store.addEvent'` 0.
4. 범위: `git diff --name-only b59fcaa -- Shared Tools proxy project.yml` ∪ `git status --porcelain -- Shared Tools proxy project.yml` = 정확히 `Shared/ContentView.swift` · `Shared/Store.swift` · `Tools/GuardDriver.swift`. `ls Shared | wc -l` = 27.
5. iOS 빌드 성공, 소스 경고 0(`CADisplayLink`·상수 격리 〔가설〕). 맥 빌드 없음.
6. `ls -d $TMPDIR/besir-gd-*`에 이번 실행분 없음.

## AC-012 — 시뮬레이터 ⬜

스크립트 S-1~S-11 · S-13 · S-14 · S-16~S-18(S-12·S-15는 t48로 옮김). 운영자가 "같음/다름 + 메모".

## AC-013 — 끄는 중 시간표 연장 ⬜

- **G**: `grep -c 'ForEach(0..<24' Shared/ContentView.swift` · `grep -c '24 \* hourHeight' Shared/ContentView.swift` 기대 **0 · 0**, 기준 **2 · 2**(양성 대조). 하루 한계 도우미 이름이 눈금·높이·두 `span`에서 각각 1 이상.
- **G**: 도우미 본문이 Store 소유 조회를 부르지 않는다(AC-007 금지 패턴과 같은 꼴).
- **S**: S-6 · S-13.

## AC-015 — 자정을 넘어도 한 묶음 ⬜

근거: 운영자 2차 Q-6 "자정을 넘겨도 가는 이동과 오는이동까지 한 묶음으로 결정하여 이동과 편집이 연계되던 연결성을 유지".

- **D**: AF-018-27(넘긴 추정 구간이 묶음에 남고 활동 이동에 따라온다 · 밤샘 반복에서 10분 어긋난 오는 편은 소유 없음이고, `moveActivity` "전체" +30에서 두 번 옮겨지는 구간이 없다 — 픽스처 시각은 `plan.md` §5 AF-018-27) · AF-015-09 · AF-015-11(고쳐 쓰기) · **AF-018-29**(출발 nil 복귀 구간 양성 대조 — 소유·묶음·활동 +30 연동, 0.7.3). 기준 ✗.
- **G**: `awk '/private func estimatedLegs/,/^    }$/' Shared/Store.swift | grep -c 'arrivalDate == activity.startDate\|anchorComparisonTime == activity.endDate'` 1 이상, 기준 **0**(양성 대조 — 0.7.3에서 출발 기준 대조가 `anchorComparisonTime` 헬퍼로 바뀌었다) · 같은 범위 `grep -c 'inSameDayAs'` **0**(같은 날 규칙 삭제 — 0.7.0), 기준 **1**(양성 대조).

## AC-016 — 가장자리 자동 스크롤 ⬜

드라이버는 이 기준에 닿지 않는다(UIKit 제스처·스크롤·`CADisplayLink`). G는 코드 구조를, S는 동작을 본다.

- **G — 타이머 하나, 멈춤 함수 하나, 모든 끝 경로**(run이 붙인 멈춤 함수 이름을 `<stop>`으로):

```bash
grep -c 'CADisplayLink(' Shared/ContentView.swift
grep -c 'invalidate()' Shared/ContentView.swift
awk '/func handleLongPress/,/^        }$/' Shared/ContentView.swift | grep -c '<stop>()'
grep -c 'func dismantleUIView' Shared/ContentView.swift
awk '/func dismantleUIView/,/^    }$/' Shared/ContentView.swift | grep -c '<stop>()'
```

기대: 생성 **1** · `invalidate()` **1**(멈춤 함수 안) · `handleLongPress` 안 멈춤 호출이 `.ended`·`.cancelled/.failed`·`onBegin` 거절 셋을 덮어 **3 이상** · `dismantleUIView` **1** · 그 안 멈춤 호출 **1**. 런루프 등록 대조(N5-12): `grep -c 'forMode: .common' Shared/ContentView.swift` 기대 **1**. 창에서 빠질 때(`didMoveToWindow`의 `window == nil`)와 틱 안 상태 검사 자리는 읽기 판정으로 줄번호를 §E.2에. 기준 트리는 다섯 명령 모두 **0**(패턴이 지금 없다 — 이 레인 실측: `grep -c 'setContentOffset\|stopAutoScroll\|dismantleUIView' Shared/ContentView.swift` → 0). **양성 대조**: `printf 'func stopAutoScroll() { link?.invalidate(); link = nil }\n' | grep -c 'invalidate()'` → 1, `printf 'let l = CADisplayLink(target: p, selector: #selector(tick))\n' | grep -c 'CADisplayLink('` → 1(이 레인 실측).
- **G — 오프셋을 두 번 더하지 않는다**: 틱 함수 본문에서 `setContentOffset` 1, 그리고 `onChange`로 넘기는 값이 `location(in:` 재읽기에서 나온다(읽기 판정). `contentOffset.y`를 `onChange` 인자에 더하는 식이 없다. 양성 대조: `printf 'func tick() { let off = scroll.contentOffset.y + v * dt; scroll.setContentOffset(CGPoint(x: 0, y: off), animated: false); onChange(gr.location(in: gr.view).y - startY) }\n' | grep -c 'setContentOffset'` → 1.
- **G — 막힘 없는 루프·새 `Task` 없음**: 오버레이 코디네이터 안 `while`·`Task {` 0건(기준 0 — 회귀선).
- **S**: S-6 · S-16 · S-17.

## 시뮬레이터 스크립트 (AC-012)

**사전 조건**: "일정 모두 삭제" → 일간 시간표 **내일**. 활동 `회의`(`회사`, 13:00–14:00)에 가는 편(`집`에서)·오는 편(`집`으로)을 붙이고 출발 시각을 적어 둔다. 실행 취소는 없다.

| S | 조작 | 기대 |
|---|---|---|
| S-1 | 오는 이동을 길게 눌러 30분 아래로 끌다 뗀다 | 끄는 동안 `회의` 끝과 오는 이동이 붙어 함께 내려간다(반폭 없음). `회의` 13:00–14:30. 튀지 않는다 |
| S-2 | 오는 이동 30분 위로 | 13:00–14:00 |
| S-3 | 가는 이동 30분 위로 | 12:30–14:00, 여유 그대로 |
| S-4 | 가는 이동 30분 아래로 | 13:00–14:00 |
| S-5 | 오는 이동을 2시간 위로 끌다 뗀다 → 55분 아래로 | 끄는 동안 `회의`가 5분 길이에서 멈춘다. `회의` 13:00–13:05가 **5분 높이**(약 손톱 반)로 그려지고 오는 이동이 그 바로 아래 전폭으로 붙는다(반폭으로 갈리지 않는다). 55분 아래로 끌면 13:00–14:00 |
| S-6 | 스크롤을 18시 근처로 둔다. 새 활동 `야간`(내일 22:00–22:30)에 오는 편을 붙인다. 화면을 22시가 보이게 내려 오는 이동을 길게 누르고 화면 **아래 가장자리**로 끌어 손가락을 멈춘다 → 시간표가 저절로 내려가 24:00 아래 다음 날 칸이 보이면 원하는 자리에서 뗀다 | 손가락을 멈춰도 시간표가 계속 내려간다. 24:00 아래에 다음 날 시간대가 생기며 `야간`이 늘어난다. 끌린 블록은 손가락 아래에 머문다(두 배로 빨리 가지 않는다). 놓은 뒤 내일 `야간`은 24:00까지, 모레 화면에 나머지와 오는 이동 |
| S-7 | 반복(AI 채팅 `다음 주 월요일부터 평일마다 9시까지 회사 출근, 6시 퇴근. 제목은 S7 출근. 집에서 출발할게. 지하철로 가고 여유 10분, 알림 10분 전`, `2주`) → 월요일 퇴근 이동 30분 아래로 "이 일정만" | 대화상자. 월요일 체류만 18:30, 화요일 그대로 |
| S-8 | 화요일 출근 이동 30분 위로 "전체" | 배치 떨림 메모. 모든 평일 체류 30분 일찍 시작 |
| S-9 | S-7 반복 삭제 → `… 점심은 12시부터 1시까지 <즐겨찾기 식당>. 제목은 S9 점심 …` → 수요일 출근 30분 위로 "전체" | 체류 시작만 당겨지고 점심 쪽 그대로 |
| S-10 | 연결 없는 단발 이동(`내일 오후 3시까지 회사 가야 해. 제목은 S10 단발 …`) 30분 아래로 | 지금과 같다(여유 10 → 0). 연장·자동 스크롤 없음 |
| S-11 | S-1·S-3을 다시 하고 상세를 연다 | 출발 시각 30분 이동, 알림은 "출발 − N분 전"(`Shared/EventDetailView.swift:352`) |
| S-13 | 새 활동 `자정`(내일 21:40–23:40)에 오는 편, 도착 모레 00:30(이동시간 50분). 오는 이동을 아래 가장자리로 끌어 1시간쯤 내려간 자리에서 뗀다 → 모레 화면. 이어 모레 화면에서 `자정`을 30분 아래로 끈다(활동 블록 드래그) | 내일 화면에 하루 전체 높이 블록이 생기지 않는다. 내일 `자정` 21:40–24:00, 모레 `자정` 00:00–00:40과 오는 이동. **활동을 끌면 오는 이동도 함께 30분 내려간다**(한 묶음). S-7 반복의 회차로 같은 일을 해도 같다 |
| S-14 | 새 활동 `새벽`(내일 22:50–23:50)에 오는 편(도착 모레 00:20, 이동시간 30분)을 붙인다. 모레 화면에서 오는 이동을 길게 눌러 1시간 위로 → 뗀다 | 도착이 모레 00:05에서 멈춘다(요청 −60 → 유효 −15 — 도착이 다음 나열일 시작을 지나야 해서). 출발 내일 23:35. 블록이 모레 화면에 남는다. N5-6 — S-13 상태와 무관한 독립 픽스처 |
| S-16 | S-6 상태에서 오는 이동을 다시 길게 눌러 아래 가장자리에 두고 시간표가 움직이는 동안 ① 뗀다 ② 다시 해서 홈 제스처로 앱을 내린 뒤 돌아온다 ③ 다시 해서 손가락을 가장자리에서 가운데로 옮긴다 ④ 다시 해서 **위** 가장자리로 끈다 | ① 떼는 즉시 스크롤이 멈춘다 ② 돌아왔을 때 화면이 혼자 움직이지 않는다 ③ 가운데로 오면 멈춘다 ④ 위로 스크롤되다 내일 0시(맨 위)에서 멈춘다. 어느 경우에도 손을 뗀 뒤 화면이 계속 미끄러지면 "다름" |
| S-17 | S-6처럼 다음 날 칸까지 내려간 상태에서 뗀다 | 연장이 사라지며 화면이 내일의 끝(24:00 아래)으로 한 번 튀어 오른다 — 튀는 정도를 메모 |
| S-18 | 구간 없는 활동 `짧음`(내일 10:00–10:05)과 `열분`(10:30–10:40)을 만들고 각각 탭한다. 이어 S-7 같은 반복의 체류를 10분짜리로 만든 회차에서 그 체류와 출근 이동을 각각 탭한다 | 5분 블록·10분 블록이 눌러지는지, 몇 번 만에 눌리는지 메모 — 결정된 수용 위험의 확인 단계, 불편하면 후속 카드(`plan.md` Q-10 닫음). 반복 출근 이동을 누르면 활동 편집이 아니라 이동 일정 폼이 열린다 — 운영자 근거와 다른 경로임을 확인 |

**드라이버로 대신할 수 없는 이유**: 미리보기·연장·자동 스크롤·튐·탭 범위·대화상자·알림은 화면과 기기만 안다.

## 경계 상황 대응표

| 경계 | 다루는 곳 |
|---|---|
| Δ = 0 | AF-018-15 |
| 최소 5분 · 이미 짧은 활동 · 5분 활동 그리기 | AF-018-06·07 · S-5 · S-18 |
| 아래로 자정 넘기기 · 자동 스크롤 | AF-018-08·10 · S-6 · S-13 · S-16 |
| 위로 0시 | AF-018-09·10 · S-14 · S-16 ④ |
| 아래 상한 · 상한 초과 옛 데이터 | AF-018-26·25 |
| 놓을 때 튀어 오름 | S-17 |
| 경고 블록 | AF-018-14·25 |
| 드래그 중 재추정 | AF-018-24 |
| 자정 넘긴 묶음(반복) | AF-018-27 · AF-015-09·11 · S-13 |
| 타이머 누수 · 앱 내림 | AC-016 G · S-16 ② |
| 소유 없음 · 모호 · 동률 | AF-018-11~13·20·21 · S-10 |
| 반복 26주 | AC-010 · S-8(2주) |
| 구글 | 범위 밖(t48) — AC-010이 드롭 경로 구글 0건을 대조 |

## 품질 게이트 · 완료의 정의

- AC-001~011·013·015·016의 D·G 전부 ✅(원문 출력과 함께 §E.2).
- AC-012·013·016의 S와 AC-004 S는 운영자 시뮬레이터 결과로 판정한다.
- 하네스: `swift-impl`·`ui-design`(구현), `code-safety`(판정).
- 질문은 전부 닫혔다 — Q-3·5·9는 착수 승인(2026-10-08, "위 설명대로 착수")에서, Q-10·11·12는 0.6.1에서, Q-13은 0.7.1에서.

🗿 MoAI
