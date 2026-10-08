# 카드 t43 — sync 증거 (SPEC-UIKIT-012, 구현 c50754a)

작성: sync 레인, 2026-10-08. 워크트리 `.claude/worktrees/t43`, 브랜치 `WT-leg-drag-resize`, 구현 HEAD `c50754a` 위에 문서·주석 수리를 얹었다. **최종 PASS/FAIL 판정은 리드 몫이다** — 이 문서는 재현된 증거와 못 본 것을 낸다. 병합·push·PR·`--patch`는 하지 않았다(결함은 고치지 않고 아래에 적었다).

증거 파일은 `.moai/state/verify/t43/sync/`(git 무시 폴더 — 이 문서가 원문을 인용한다)에 있다.

## 1. 결론 (한 문단)

**차단 1건 — 가장자리 자동 스크롤의 띠 판정 좌표 오류(`Shared/ContentView.swift:1218`).** 시간표를 조금이라도 스크롤한 상태에서 구간을 끌면 화면 한가운데 손가락도 "아래 띠"로 읽혀 최대 속도를 넘겨 아래로 폭주한다. UIKit 좌표 변환을 실제로 돌려 재현했고 제가 같은 바이너리를 다시 돌려 같은 출력을 봤다(§3.1). 드라이버는 이 경로를 닿지 못하므로 522/522가 초록이어도 잡지 못한다. 그 밖에 **주의 4건**(§3.2 출발 없는 복귀 구간의 짝 상실 — 기준 트리 대비 회귀이며 SPEC 결정이 필요, §4.1 초가 0이 아닌 활동의 반폭 분할, §4.2 "다음 날 00" 눈금 폭, 속도 상한 없음)과 정보 항목이 있다. 기계 게이트(드라이버 522/522 두 번, iOS 무경고 빌드, 해시 대조)와 문서 수리는 끝났다.

## 2. 기계 게이트 (제가 직접 돌린 것)

| # | 주장 | 명령 | 관측 원문 |
|---|---|---|---|
| G1 | 드라이버 522/522, exit 0 (1회차) | CLAUDE.md 드라이버 블록 그대로 — 단 파일은 세션 스크래치에 컴파일(`/tmp/gd`는 다른 레인과 겹칠 수 있어 쓰지 않았다) | `run1-exit=0` · `522/522 통과` · `[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다` · `grep -c '✗'` → 0, `grep -c '✓'` → 522 (`driver-run1.log`) |
| G2 | 같은 결과가 문서·주석 수리 뒤 트리에서도 | 위와 같은 블록을 다시 컴파일·실행 | `run2-exit=0` · `522/522 통과` · 실제 데이터 대조 통과 · `✗` 0 / `✓` 522 (`driver-run2.log`) |
| G3 | iOS 무경고 빌드 (주석 수리 뒤) | `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build` | `build-exit=0` · `grep -c 'BUILD SUCCEEDED'` → 1 · `grep 'warning:' … | grep -v appintentsmetadataprocessor | sort -u` → 빈 출력. 날 경고 1줄은 `appintentsmetadataprocessor … Metadata extraction skipped`(필터가 제외하는 도구 줄) (`build-ios.log`) |
| G4 | `moveActivity`·`realignReturnLeg` 본문 무변경 | `awk '/func moveActivity\(/,/^    }$/' Shared/Store.swift | shasum` 외 | `ab65d72c40fb86a311fe8b9eabe27d7a96d3a758` · `a6ca6f17d69f86a6e67d2eff7fa06759f5ff4a0d` — 기준과 같음(주석 수리 뒤에도) |
| G5 | 드라이버 샌드박스 잔여 없음 | `ls -d "$TMPDIR"besir-gd-*` | `no matches found` |

**드라이버 첫 실행은 실패 없이 522였다** — 브리프가 경고한 네트워크 의존 실패(513/522)는 이 세션에서 나타나지 않았다. 재실행은 문서 수리 뒤 검증을 겸한 것이다.

기준선: 구현 단계 증거(`run-progress.md` §3.1)의 B = 498, T = 522와 같다. 이 세션의 baseline 재측정은 하지 않았다.

## 3. 렌즈 `--deep` (code-safety 전문가, 읽기 전용)

### 3.1 [차단 · 재현됨] 자동 스크롤 띠 판정이 콘텐츠 좌표를 보이는 창 좌표로 읽는다

- 위치: `Shared/ContentView.swift:1218` — `let fingerY = gr.location(in: scroll).y`. 바로 위 주석(`:1216-1217`)은 "location(in: scroll)이 곧 보이는 창 안 위치"라고 하지만 `UIScrollView`의 `bounds.origin.y`는 `contentOffset.y`라서 이 값은 **콘텐츠 좌표**다.
- 결과: `:1222`·`:1224`의 띠 판정과 `:1223`·`:1225`의 속도식이 `contentOffset`만큼 어긋난다. 속도식에는 상한이 없다(`min(…, autoScrollMaxSpeed)` 없음). 아래로 감기면 offset이 커지고 → fingerY가 더 커지고 → 속도가 더 커지는 되먹임이 생긴다. offset이 띠 높이(약 72pt)를 넘으면 위쪽 띠는 다시 걸리지 않는다.
- 재현: 보이는 높이 600 · 콘텐츠 1344(24시간 × 56pt) · 오버레이는 콘텐츠 안 — 앱의 띠·속도 식을 그대로 옮겨 Mac Catalyst UIKit의 실제 `UIScrollView`에서 점 변환을 했다 (`scrollcoord.swift`, 렌즈가 컴파일한 바이너리를 제가 다시 실행).

```text
$ …/lens-deep/scrollcoord
offset=0.0 visibleY=10.0 inScroll=10.0 band=72.0 speed=-516.6666666666667
offset=0.0 visibleY=300.0 inScroll=300.0 band=72.0 speed=0.0
offset=0.0 visibleY=590.0 inScroll=590.0 band=72.0 speed=516.6666666666667
offset=448.0 visibleY=10.0 inScroll=458.0 band=72.0 speed=0.0
offset=448.0 visibleY=300.0 inScroll=748.0 band=72.0 speed=1833.3333333333333
offset=448.0 visibleY=590.0 inScroll=1038.0 band=72.0 speed=4250.0
```

  offset 0 세 줄이 양성 대조(설계대로)다. offset 448(08시까지 스크롤한 상태)에서는 화면 한가운데 손가락이 1833pt/초, 아래 가장자리는 600을 넘는 4250pt/초이고 위쪽 띠는 0이다.
- 재현의 한계: 앱 자체를 시뮬레이터에서 돌리지는 않았고, `UIGestureRecognizer.location(in:)` 대신 `overlay.convert(_:to: scroll)`로 같은 좌표계 변환을 했다. 둘은 같은 bounds 좌표계를 쓴다(UIKit 문서).
- 수리 방향(제안, 적용 안 함 — 구현 전문가 몫): `gr.location(in: scroll).y - scroll.contentOffset.y`로 판정하고 속도에 `min(…, autoScrollMaxSpeed)` 상한(손가락이 스크롤 영역 밖일 때 600 초과도 함께 막는다 — plan D-11 "깊이 ≥ 띠 높이면 최대 속도"). 고친 뒤 S-16에서 **스크롤한 뒤에** 끄는 경우를 반드시 본다.
- 이것이 S-16의 첫 관측에서 터질 결함이다. 드라이버·구조 대조(AC-016)는 이 줄이 어떤 좌표계를 읽는지 보지 못한다.

### 3.2 [주의 · 렌즈가 기준 트리와 대조 재현] 반복 생성에서 첫 회차 이동시간 추정이 실패하면 2회차부터의 복귀 구간이 활동과 짝을 잃는다 (REQ-016 정확 대조의 회귀)

- 위치: `Shared/Store.swift` `estimatedLegs`의 `departureDate == activity.endDate`(AC-016 대조 두 줄 중 하나). 원인 경로는 `addRecurringEvents`의 `.departure` 갈래(`Store.swift:993-1001` — 제가 읽어 확인): 첫 회차만 `applyDepartureAnchoredEstimate`를 부르고, `cachedTravelSeconds == nil`이면(첫 추정 실패) 2회차부터는 추정 함수를 부르지 않아 `departureDate`가 nil로 남는다. `refreshUpcomingEstimates`도 `departureDate`가 nil인 구간을 대상에서 빼므로 영구히 남는다. 오프라인에서 AI로 반복 일정을 만들면 닿는 경로다.
- 재현(렌즈, 같은 하네스를 새 트리와 `git show b59fcaa:Shared/Store.swift`로 꺼낸 기준 트리에 각각 실행):

```text
새 트리   F3 dep-nil return leg: owner=false packed=false
          F3 positive control dep 18:00: owner=true packed=true
          F3 after activity +30, dep-nil leg arrival shift=0.0s
기준 트리 F3 dep-nil return leg: owner=n.a. packed=true
          F3 positive control dep 18:00: owner=n.a. packed=true
          F3 after activity +30, dep-nil leg arrival shift=1800.0s
```

  결과: 그런 회차에서는 활동을 옮겨도 복귀 구간이 남고, 화면에서 다른 묶음으로 그려지며, 복귀 구간을 끌어도 활동이 따라오지 않는다. 기준 트리에서는 같은 날 규칙이 계속 짝지었다.
- 문서와의 관계: `research.md` §10 표는 "재추정 실패 — 출발 유지"만 다루고 이 생성 모양은 없다. D-10 표의 "AI 반복 생성 → 성립" 전제가 이 경우에는 맞지 않는다. REQ-004가 "출발이 없는 오는 편은 동률이 성립하지 않는다"고 명시하고 AF-018-21b가 고정하므로 **수리는 SPEC 수정이 필요한 결정**이다(리드·운영자 판단). 제안: 출발 기준 구간의 대조 시각을 `departureDate ?? arrivalDate`(앱의 `failedBlockAnchor`와 같은 규칙)로 두는 것.
- 제가 렌즈 하네스를 다시 돌리지는 않았다 — 근거 코드는 읽어 확인했고 숫자는 렌즈 보고 그대로다. 이 항목은 차단으로 세지 않는다(운영자 확인 전제 "옛 틈 없음"과 다른 모양이지만 현실 조건이 오프라인 생성이다).

### 3.3 그 밖의 `--deep` 결과

- **CADisplayLink 수명**: 시작은 `startAutoScrollIfNeeded` 한 곳(`guard displayLink == nil`로 이중 시작 없음), 멈춤은 `stopAutoScroll` 하나로 `.ended`·`.cancelled/.failed`·onBegin 거절·`dismantleUIView`·`didMoveToWindow(nil)`·틱 상태 검사·`activeRecognizer`/`dragScrollView` nil이 모두 모인다. 약한 대리 객체·`.common` 모드 올바름, 순환 참조 없음. [정보] 코디네이터가 stop 없이 사라지면 링이 `target == nil`로 매 프레임 헛돈다 — `AutoScrollProxy.tick`에서 target이 nil일 때 `link.invalidate()` 권장.
- **`effectiveDragMinutes` 경계**: 손 계산 11건을 실제 `Store.swift`(샌드박스)로 실행해 전부 일치(5분 바닥 −20→−15, 0쪽 스냅 −13→−10, 7분59초 활동 −5→0, 자정 정확 도착 ±, 경고 블록 +1500→1440, 3분 활동 −5→0/+5→+5, 깨진 활동 5). 미리보기(onChange)와 드롭이 같은 함수를 부르며 출력에 다시 적용해도 값이 같다(멱등). 방향 판정 `anchor == .departure`가 네 곳 같은 규칙. [정보] 초를 0쪽으로 자르므로 도착이 D+1 23:55:30이면 +5가 상한을 30초 넘긴다(REQ-008대로의 동작, 이틀 걸친 구간이어야 닿음, AF-018-26은 초 0 픽스처라 못 봄).
- **드라이버 단언 게임화**: 기대값을 손으로 다시 계산한 것 — AF-018-06·07·09·10 A/B/C·14·16·24·25 A/D/B·26·27(#4)·AF-015-09·11·AF-018-02·03 — 전부 리터럴 기대값이 SPEC 산식과 일치, 구현 출력을 기대로 삼지 않았다. 구현이 틀리면 실패하는 대조(AF-018-24 사본 시각, 27 #4 옛 같은 날 대조, 06·26 한계 없음)도 확인. [정보] 기능이 틀려도 통과하는 단언: AF-018-15(Δ=0 첫 줄 반환)·17(표지 불변만)·14·25(b)(한계와 멀리 떨어진 경고 블록)·23 격자(함수가 늘 0이어도 통과 — 0이 아닌 값 대조 없음, 06·26이 보완). 고의로 기대를 맞춘 단언은 못 찾았다.
- **표준 위험**: 추가된 줄에서 `await`/`Task {`/`try?`/강제 언래핑 → `git diff b59fcaa..c50754a -U0 -- Shared/Store.swift Shared/ContentView.swift | grep -nE "^\+.*(Task \{|try\?|await |[a-zA-Z)}\]]!|as! )"` 0줄(양성 대조: 같은 정규식을 드라이버 diff에 돌리면 44줄). [정보] "전체" 경로는 회차마다 `shiftEvent → rescheduleNotification`을 요청하지만 끝의 `rescheduleNearestNotifications`(60건)가 정리 — 64건 상한 최종 상태 안전, 저장은 활동 1·이벤트 1(기존 모양). [정보] `span(for event:)` 드래그 갈래가 기존 갈래의 "16분 최소 높이 늘리는 방향" 규칙을 다시 쓴다(두 갈래가 어긋날 자리). 〔가설〕 "전체" 경로 `peers`는 owner의 recurrenceId가 아니라 구간의 `recurrenceId`로 거른다 — 명시 연결 구간은 recurrenceId가 없다는 §1.3 (라)를 믿으면 닿지 않는다(미실행).

## 4. 렌즈 `--design` (ui-design 전문가, 읽기 전용; `--critique` 안 돌림)

결론 차단 0 · 주의 3 · 정보 4. 렌즈가 인용한 줄번호는 diff 출력 기준이라 실제 파일과 어긋나서(`:200`·`:215-216`·`:222`가 사이드바 코드), **실제 위치를 제가 다시 찾아 확인**했다.

- **색 · 다크 모드 — 0건.** 새로 들어간 줄의 색 리터럴 0(주석 1줄만 매치), `preferredColorScheme` 0, `Theme.swift` 무변경, 연장 구간 글자 `Theme.faint`·구분선 `Theme.line`. 양성 대조 `grep -c "Theme\.faint" Shared/ContentView.swift` → 6.
- **남은 리터럴**: `h < 24`(`:434`, 자정 의미 — 유지), `1440`(`:606`·`:613` 하루 한계 도우미 자신 — 유지), `24 * 3600`(`:608`), `0..<24`·`24 * hourHeight` 0건. 히트 테스트(`block(atX:)` `:893`)는 `placed`를 읽고 `placed`는 두 `span`을 거쳐 `dayLimitMinutes`를 읽는다 — 계약 5 충족.

### 4.1 [주의 · 부분 재현] 초가 0이 아닌 활동이 새로 반폭으로 갈라진다

- 위치: `Shared/ContentView.swift:651-652` — 활동 `span`이 `timeIntervalSince(dayStart) / 60`(초 포함)로 계산. 기준 `b59fcaa:ContentView.swift:548-549`는 `minutesSinceMidnight`(`:567-569`, 시·분만 — 초 버림)였고, 저장된 구간의 `span`은 지금도 `minutesSinceMidnight`(`:707` 등)다. 제가 두 코드를 직접 대조해 확인했다.
- 재현(렌즈): 활동 10:00:30–11:00:30 + 출발 11:00:30 오는 편 → 기준 `a[0.0,1.0] ret[0.0,1.0]`(전폭) → 새 트리 `a[0.0,0.5] ret[0.5,1.0]`(반폭), `ScheduleLogic.overlapSlots`를 실제 `Models.swift`로 돌림. span 입력 숫자는 손 계산(`span`이 private라 직접 호출 못 함).
- 현실 가능성: 폼의 시각 줄 기본값이 `nextWholeHour()`(초 0 — `EditCardView.swift:228`)이고 반복 생성은 `second: 0`이라 일반 데이터에서는 닿지 않는다. 초가 있는 외부 가져오기·AI 생성이 닿을 수 있으나 이 세션은 실제 데이터에 초≠0이 있는지 확인하지 않았다.
- 제안(적용 안 함): 활동 `span`도 `minutesSinceMidnight` 계열로 분 단위로 내리거나 구간 `span`과 같은 함수를 쓴다.

### 4.2 [주의 · 〔가설〕] "다음 날 00" 눈금 라벨이 28pt 칸에 안 들어간다

- 위치: `Shared/ContentView.swift:434-437` — `String(format: "다음 날 %02d", h - 24)` + `.font(.caption2)` + `.lineLimit(1).minimumScaleFactor(0.6)` + `.frame(width: 28 …)`.
- 측정(렌즈, macOS AppKit 글꼴로 11pt 대용 측정 — iOS 화면에서 보지 않음): `00` 14.0pt · `다음 날 00` 48.8pt(필요 축소율 0.57 < 하한 0.6 → 말줄임/잘림 예상). 대안 폭 `익일 00` 36.2 · `+1 00` 29.3 · `00⁺` 17.7. 자정 구분선은 다른 시각 구분선과 같은 `Theme.line`이라 "다음 날" 표시는 이 글자뿐이다. 큰 글자 크기에서 더 심해진다.
- 처리: 디자인 결정(문구·구분선 강조)이라 운영자 몫. S-6에서 사람 눈으로 확인한다.

### 4.3 짧은 블록 (`minActivityMinutes` 20 → 5) — 렌즈가 `overlapSlots` 실행 + 손 계산

- 5분 활동 높이 4.67pt, 10분 9.33, 19분 17.73, 20분 18.67. 반폭 분할은 **5·10·19분이 붙은 오는 편과 겹치던 것이 사라지고 전폭**이 된다(20분 바닥에서는 반폭이었음). 탭 면적은 5분만 절반으로 줄고(2,800→1,400pt²) 10분은 같고 19분은 넓어진다. 세로 높이는 이전에도 44pt 권장에 못 미쳤다. S-18 외의 히트 테스트 영향은 못 찾았다.
- [정보] 20분보다 짧은 활동은 제목이 보이지 않는다(위아래 패딩 4pt + `.clipped()`). 5분 블록은 테두리 색 띠만 남아 활동·이동 구분이 색 하나에만 기댄다. 〔가설〕 접근성: `ContentView.swift`에 `accessibility`·`ScaledMetric`·`dynamicTypeSize` 0건(기준부터의 공백) — 잘린 `Text`의 VoiceOver 프레임이 4.7pt 블록을 벗어나면 활성화 지점이 이웃으로 떨어질 수 있음(미실행).

### 4.4 미리보기 기하 — 손 계산 4건이 코드와 일치

(1) 하루 경계를 일부 넘는 경우 — 활동 22:00–23:00 + 오는 편 +90 → 눈금 25칸·높이 1,400pt, 활동 y=1,232·높이 140, 구간 y=1,372·높이 28. (2) 이웃 페이지에서 완전히 밖으로 나간 경우 — `(0, 0)`으로 건너뛰어 그리지도 누르지도 않음. (3) 0시 바로 위로 끄는 가는 편 −25 — 구간 `(0, 16)`·활동 `(5, 115)`가 겹쳐 묶음 안 반폭(드래그 전에는 전폭 — 미리보기 도중 폭이 한 번 바뀜, 저장된 구간에도 같은 기존 규칙이라 회귀 아님). (4) 경고 블록 +30 — 높이 20pt, 한계 이상이면 `(0, 0)`. 이중 이동 방지 `dragOffsetMinutes(forEvent:)`가 소유 있는 구간의 평행이동을 0으로 만든다. 〔가설〕 출발 기준 경고 블록에 옛 도착이 앵커보다 늦게 남은 경우 `max(dep ?? arr, arr)`이 연장을 부풀릴 수 있음(미실행).

### 4.5 자동 스크롤 감각값

- 코드로 판단: 띠 `max(0.12 × 보이는 높이, 44)`(보이는 높이 650이면 78pt), 최대 600pt/초 → 60Hz 프레임당 10pt·120Hz 5pt, 5분 한 칸 4.67pt라 최대 속도에서 프레임마다 1~2칸 건너뜀, 다음 날 끝까지 최대 속도로 약 4.5초. **속도 상한 없음**은 §3.1과 같은 뿌리(손가락이 스크롤 영역 밖이면 600 초과).
- 사람이 시뮬레이터에서만 판단: 실제 속도감·띠 크기, `.scrollDisabled` 아래 `setContentOffset` 동작(D-11 〔가설〕), 놓을 때 튀어 오름(S-17), 연장·스크롤 순서 어긋남, 60/120Hz 차이. **제가 본 것은 없다.**

## 5. 문서 수리 (드리프트를 만든 카드가 고친다)

수리한 곳 — `git diff --stat`: `CHECKLIST.md` 6행 · `plan.md` 1행 · `Shared/Store.swift` 주석 1행 (8 insertions / 8 deletions).

| 대상 | 바꾼 것 |
|---|---|
| 루트 `plan.md:190` | "이동 블록만 옮기면 활동은 고정하고 버퍼만 조정"에 2026-10-08 t43 SPEC-UIKIT-012로 바뀐 뜻(연결된 이동 블록은 활동 가장자리를 함께 옮기고 연결 없는 이동 블록만 이전 방식)을 덧붙임 |
| `CHECKLIST.md` K13 (`:202`) | ❌ → ✅, 근거를 `adjustTravelLeg` `Store.swift:1418` → `applyLinkedLegDrag` `:1454` · `owningActivity` `:429` · `effectiveDragMinutes` `:1523` · `adjustBuffer` `:1648` · `shiftEvent` `:1636` 새 좌표로 다시 씀. 증거는 "드라이버 522/522·exit 0, **시뮬레이터 미관측** — 끄는 중 미리보기·24:00 아래 연장·가장자리 자동 스크롤·5분 블록 탭은 S-1~S-18 운영자 몫"으로 정직하게 적음 |
| `CHECKLIST.md` D8 (`:93`) | 제스처 `ContentView.swift:897-899` → `:1062-1064`, 반복 대화상자 `:176-181` → `:183-188`, 적용 `:772`·`:780` → `:912`·`:920` |
| `CHECKLIST.md` K7 (`:196`) | 적용 `:772`·`:780` → `:912`·`:920` |
| `CHECKLIST.md` 요약 (`:313`) | ❌ 현존에서 K13 제거, 괄호로 사유 한 줄 |
| `CHECKLIST.md` K5·K9 (`:194`·`:198`) | **목록 밖에서 추가**: 이 카드가 다시 쓴 `span` 두 함수 인용 `:543`·`:558` → `:620`·`:656`, 같은 행의 `columnFrame` `:738` → `:878`, `block(atX:)` `:753` → `:893`, K9의 `:87-88` → `:94-95`·`:100` → `:107` |
| `Shared/Store.swift:547` 주석 | "오는 편을 끌어 벌어진 틈은 이 저장으로 닫힌다" → "옛 버전에서 오는 편을 끌어 벌어진 틈은 …" (t43 이후에는 소유 구간 드래그가 틈을 만들지 않으므로). 줄 수 불변 — 인용 좌표 영향 없음 |
| 드라이버 AF-018 머리 주석 | 구현 단계에서 이미 갱신됨(`GuardDriver.swift:3641-3644`) — 고칠 것 없음. 드라이버의 다른 `Store.swift:698-700`·`:1001`·`:1026` 인용은 §6 t44 몫 |
| SPEC-UIKIT-009 | 본문 동결 — 건드리지 않음 |

### 5.1 바이트 대조

```text
$ git diff -U0 -- CHECKLIST.md plan.md > …/sync/doc-diff.txt
$ python3 -I …/sync/check.py …/sync/doc-diff.txt <워크트리>      (추가된 줄의 인용을 원문 소스 줄과 대조)
인용 22건 (중복 제거 18건)
ContentView.swift:1062-1064 | 시작: let longPress = UILongPressGestureRecognizer(target: context.coordinator, / 끝: longPress.minimumPressDuration = 0.35
ContentView.swift:183-188   | 시작: .confirmationDialog(pendingMove?.message ?? "", isPresented: Binding( / 끝: Button("이 일정만 이동") { pendingMove?.apply(false); pendingMove = nil }
ContentView.swift:912       | store.moveActivity(a, byMinutes: drag.deltaMinutes, wholeSeries: whole)
ContentView.swift:920       | store.adjustTravelLeg(e, byMinutes: drag.deltaMinutes, wholeSeries: whole)
ContentView.swift:620 / :656 | private func span(for activity: …) / private func span(for event: …)
ContentView.swift:878 / :893 | private func columnFrame(… / private func block(atX x: …
ContentView.swift:94-95     | private func events(on date: Date) … / store.events.filter { $0.isListed(on: date, calendar: calendar) }
ContentView.swift:107       | return Store.overlapsDay(start: a.startDate, …
Store.swift:38 / :134       | static func overlapsDay(… / private func recomputeDaysWithSchedule() {
Store.swift:1418 / :1454 / :429 / :1523 / :1648 / :1636 | func adjustTravelLeg / private func applyLinkedLegDrag / func owningActivity / func effectiveDragMinutes / private func adjustBuffer / private func shiftEvent
--- 양성 대조(틀린 좌표를 일부러 읽는다) ---
ContentView.swift:1 | import SwiftUI
```

18건 모두 이름이 맞는 심볼이 그 줄에 있다. 양성 대조(`:1` → `import SwiftUI`)로 도구가 실제 줄을 읽는 것을 보였다. `Store.swift` 변경은 주석 1줄뿐: `git diff -U0 -- Shared/Store.swift | grep '^[+-]'`가 그 두 줄(-/+)만 낸다.

## 6. 못 본 것 · 잔여 위험 · 인계

**못 본 것(Gaps)**
- 시뮬레이터·실기기 전부 — S-1~S-11·S-13·S-14·S-16~S-18, 다크 모드 외관, 큰 글자 크기, VoiceOver. `--critique` 안 돌림(브리프대로).
- `.scrollDisabled(true)` 상태에서 `setContentOffset`이 먹는지(D-11 〔가설〕 — §3.1이 고쳐져야 의미 있게 볼 수 있다).
- private `span`·`positionedBlocks`·히트 테스트의 연장 중 실행 수치 — 손 계산만.
- §3.2 렌즈 하네스(F3)와 §4.1의 span 입력은 제가 재실행하지 않았다(§3.1 바이너리는 재실행함).
- 실제 데이터에 초≠0 활동·출발 없는 복귀 구간이 있는지.

**잔여 위험**: 위 §3.1(차단) 수리 전에는 S-16이 폭주로 보인다 · §3.2는 오프라인 반복 생성 데이터에서 연결 상실(SPEC 결정 필요) · §4.1·§4.2는 시각 결함 · 기존 수용 위험(S-18 짧은 활동 탭, t48 구글, t49 끝 편집 추정 복귀, t50 옛 틈)은 그대로.

**리드에게 묻는 결정**
1. §3.1 차단 — 이 카드에서 `ContentView.swift` 두 줄(좌표 보정 + 속도 상한)을 고친 뒤 다시 sync할지, 별도 수리 카드로 갈지.
2. §3.2 — REQ-004/016을 `departureDate ?? arrivalDate`로 넓히는 SPEC 수정을 할지, 수용 위험(t50 계열)으로 올릴지.
3. K13 상태 — 브리프대로 ✅로 적었다. 다만 이 파일의 관례(Q7·Q9)는 화면 미관측이면 ⚠️라서, §3.1 차단이 있는 동안은 ⚠️로 바꾸는 쪽이 더 맞을 수 있다.

**t44(인용 재사상) 인계**: 이 카드가 `Store.swift`(+27행 @`:420` 부근, +150행 @`:1451` 부근 등)와 `ContentView.swift`(+7행 @`:67`, +140행 안팎 이후 구간)의 줄을 밀었다. 위 표의 행은 이미 새 좌표(`c50754a`)이므로 t44 원장이 건너뛰면 된다. 그 밖의 `CHECKLIST.md` 인용(`ContentView.swift`/`Store.swift` 약 49건)·`plan.md` 6건·`Tools/GuardDriver.swift` 주석 `Store.swift:698-700`·`:1001`·`:1026`은 손대지 않았다.

## 7. 좁은 재검증(fix1) — 2026-10-08, 수리 HEAD `1cce4a4`

범위는 `git diff 183e07f..1cce4a4`(Store 16줄·ContentView 28줄·GuardDriver 36줄)와 CHECKLIST·SPEC 문서 변경이다. 리드의 브리프(`resync-brief.md`)대로 **드라이버 전체 실행·iOS 빌드는 하지 않았다**(리드 몫) — 예외로, 항목 4의 "옛 규칙이면 실패하는가"를 보려고 독립 경로에서 드라이버를 옛 규칙 Store 사본에 컴파일해 1회 돌렸고 리드에게 먼저 알렸다(게이트 숫자로는 쓰지 않는다). 자기 코드를 자기가 판정하지 않았다: 아래 전부 sync 레인이 직접 돌린 것이다. 증거 원본은 `.moai/state/verify/t43/sync/`(`scrollcoord-fix1.swift`·`resync/main.swift`·`resync-span/main.swift`·`driver-oldrule-negative-control.log`·`doc-diff-fix1.txt`), 바이너리는 세션 스크래치다.

### 7.0 판정 요약

| # | 항목 | 판정 |
|---|---|---|
| 1 | [차단] 자동 스크롤 좌표·상한 | **해소** — 고친 식을 좌표 하네스에 넣어 재현 |
| 2 | [회귀] 출발 없는 복귀 구간 | **해소** — F3 `owner=true packed=true` +1800초, 옛 규칙에서는 실패 재현 |
| 3 | [주의] 활동 span 분 내림 | **해소** — 초 0 데이터 항등 5,174,850건, 재현 값 `[0,1]`로 복귀 (복제 산술) |
| 4 | 드라이버 단언 게임화 | **통과** — 손 계산 일치, AF-018-29는 옛 규칙에서 실제로 실패(522/523, ✗ 그 하나) |
| 5 | 문서 | **부분** — K13 ⚠️·인용 18건·B + 25 대부분 일치, 한 줄 낡음(`plan.md:268`) |

새 차단 결함은 없다. 아래 §7.6에 정보·주의 3건이 있다.

### 7.1 [차단 해소] 자동 스크롤 좌표 · 상한

**코드 순서** (`git diff 183e07f..1cce4a4 -- Shared/ContentView.swift`): `autoScrollTick`에서 `fingerY = gr.location(in: scroll).y - scroll.contentOffset.y`, 띠 비례식 뒤에 `speed = min(max(speed, -autoScrollMaxSpeed), autoScrollMaxSpeed)`가 오고, 그 **다음에** `guard speed != 0`·`if speed > 0 { scrolledDown = true }`·`setContentOffset`이 이어진다 — 클램프가 셋 모두보다 앞이다. 반대쪽 띠(`-`)도 대칭 클램프.

**재현** — 이전 §3.1 하네스를 확장(`scrollcoord-fix1.swift`, 보이는 높이 600 · 콘텐츠 1344 · 오버레이는 콘텐츠 안, Mac Catalyst UIKit 실제 `UIScrollView` 점 변환; `old`는 183e07f의 식, `new`는 고친 식 — 식은 앱 소스에서 옮겨 쓴 복제본이다):

```text
$ xcrun swiftc -target arm64-apple-ios17.0-macabi -sdk …/MacOSX.sdk -Fsystem …/iOSSupport/System/Library/Frameworks -o …/scrollcoord-fix1 scrollcoord-fix1.swift && …/scrollcoord-fix1
offset=0.0 visibleY=-80.0 raw=-80.0 fixedFinger=-80.0 old=-1266.67 new=-600.0
offset=0.0 visibleY=10.0 raw=10.0 fixedFinger=10.0 old=-516.67 new=-516.67
offset=0.0 visibleY=300.0 raw=300.0 fixedFinger=300.0 old=0.0 new=0.0
offset=0.0 visibleY=590.0 raw=590.0 fixedFinger=590.0 old=516.67 new=516.67
offset=0.0 visibleY=680.0 raw=680.0 fixedFinger=680.0 old=1266.67 new=600.0
offset=448.0 visibleY=-80.0 raw=368.0 fixedFinger=-80.0 old=0.0 new=-600.0
offset=448.0 visibleY=10.0 raw=458.0 fixedFinger=10.0 old=0.0 new=-516.67
offset=448.0 visibleY=300.0 raw=748.0 fixedFinger=300.0 old=1833.33 new=0.0
offset=448.0 visibleY=590.0 raw=1038.0 fixedFinger=590.0 old=4250.0 new=516.67
offset=448.0 visibleY=680.0 raw=1128.0 fixedFinger=680.0 old=5000.0 new=600.0
```

(표는 소수 둘째 자리까지 줄였다. 원문은 `…/scrollcoord-fix1` 실행 출력.) offset 0 행은 양성 대조 — 옛 식과 새 식이 같다(설계대로). offset 448에서는 가운데 손가락이 1833 → **0**, 아래 가장자리가 4250 → **516.67**, 위쪽 띠가 0 → **−516.67**(다시 걸린다), 스크롤 영역 밖(−80·680)은 ±600으로 잘린다. 이전에 "속도 상한 없음"이던 `old` 열이 offset 0·영역 밖에서 ±1266을 내는 것도 같이 닫혔다.

**`AutoScrollProxy.tick`** 의 `guard let target else { link.invalidate(); return }` — `target`은 `weak var`라 이 갈래는 코디네이터가 이미 사라졌을 때만 닿는다. 코디네이터가 살아 있으면 `target`이 non-nil이라 지나가고, `startAutoScrollIfNeeded`의 `guard displayLink == nil`은 **살아 있는 코디네이터의** 필드라서 죽은 코디네이터의 링을 끊는 이 갈래와 만나지 않는다 — 재시작을 막지 않는다(코드 열람; 실행 재현은 하지 못했다, 코디네이터 해제 시점을 만들 수단이 없다).

한계: 이전과 같이 `gr.location(in:)` 대신 같은 bounds 좌표계를 쓰는 `overlay.convert(_:to: scroll)`를 썼다. 앱 시뮬레이터 실행은 하지 않았다.

### 7.2 [회귀 해소] 출발 없는 복귀 구간

`git diff`로 확인한 변경: `Store.swift` 파일 끝의 `private extension ScheduledEvent { var anchorComparisonTime }` — `(anchor ?? .arrival) == .departure ? (departureDate ?? arrivalDate) : arrivalDate`(Models.swift의 `failedBlockAnchor`와 같은 규칙) — 와 이를 읽는 두 자리(`owningActivity`의 동률 필터 `:441`, `estimatedLegs`의 출발 대조 `:1628`)뿐이다.

**재현** — 이전 F3 하네스를 `resync/main.swift`로 다시 쓰고(같은 시나리오 + AF-018-29 복제 + 동률·도착 기준·밤샘), **같은 소스를 수리 트리 Store와, 두 줄을 옛 규칙(`departureDate ==`)으로 되돌린 Store 사본에 각각 컴파일**해 돌렸다(`sed 's/\.anchorComparisonTime == /.departureDate == /g'`, `diff`가 정확히 그 두 줄만 다름을 보였다). 실제 `Store.swift`·`Models.swift`를 쓴다(샌드박스 홈, 실행 전후 실제 지원 디렉터리 3파일 mtime·크기 동일 — activities.json 9/23 16:31:28 · config.json 9/9 12:26:52 · events.json 10/5 14:50:37).

```text
수리 트리 (1cce4a4)                                          옛 규칙 사본
F3 dep-nil leg: owner=true packed=true                       F3 dep-nil leg: owner=false packed=false
F3 control dep 18:00: owner=true packed=true                 F3 control dep 18:00: owner=true packed=true
F3 activity +30: dep-nil leg arrival+1800.0s dep+nil         F3 activity +30: dep-nil leg arrival+0.0s dep+nil
AF29 replica: owned=true grouped=true arrivalShift=1800.0    AF29 replica: owned=false grouped=false arrivalShift=0.0
              depNil=true  => PASS                                          depNil=true  => FAIL
TIE dep present 13:00→13:20: owningActivity=nil packingGroup=점심   (동일)
TIE dep nil, arrival 13:00:  owningActivity=nil packingGroup=점심   TIE dep nil, arrival 13:00: owningActivity=nil packingGroup=nil
21b-new dep nil arrival=end+20m: owner=nil                   (동일)
ARR: exact owner=L off-by-1s owner=nil                       (동일)
N5-1 groups: #1=A0 #2=A0 #3=A1 #4=none                       (동일)
N5-1 moveActivity(A0,+30,whole): arrival shifts #1..#4 = 1800.0, 1800.0, 1800.0, 0.0   (동일)
```

판독:
- F3(이전 §3.2의 회귀 모양) — 수리 트리에서 `owner=true packed=true`, 활동 +30에 구간 arrival **+1800초**, departure는 nil 유지. 옛 규칙에서는 같은 입력이 `false/false/+0`이라 이 하네스가 회귀를 실제로 잡는다(양성 대조).
- **새 이중 주장(한 구간을 두 활동이 소유)** — 같은 끝 활동 둘(체류 11–13·점심 12–13) + 복귀 구간 한 개로 출발 있음/없음을 나란히 돌렸다. 둘 다 `owningActivity=nil`(동률 → 소유 없음)이고 `packingGroup=점심`으로 **똑같다**: 같은 끝 활동 둘이 한 구간을 각자 집는 `packingGroups`의 동작은 출발 있는 구간에서 이미 있던 것이고, 출발 nil 구간이 그와 같은 모양이 됐을 뿐 새 종류의 이중 주장이 아니다. `owningActivity`는 동률을 막는다.
- 도착 기준 갈래 — 정확히 맞으면 소유, 1초 어긋나면 `nil`(변함없음). AF-018-21b 새 모양(출발 nil · arrival = 끝 + 20분) → `nil`.
- N5-1 밤샘 어긋남 모양(AF-018-27) — 묶음 `#1·#2 → A0, #3 → A1, #4 없음`, "전체" +30에 `#1·#2·#3 = +1800`, `#4 = 0` — 수리 트리와 옛 규칙이 같다(헬퍼가 이 모양을 바꾸지 않는다). 손 계산(`#4` 출발 D+2 02:10 ≠ A1 끝 02:00)과 일치.
- `moveActivity`·`realignReturnLeg` 본문은 이 diff에 없다(리드가 해시 확인).

### 7.3 [주의 해소] 활동 span 분 단위 내림

`ContentView.swift`의 `span(for activity:)`는 private이라 직접 못 부르므로 세 판의 산술만 소스에서 그대로 옮겼다(`resync-span/main.swift` — **복제본**; 하루 한계는 평소 1440, 한국 시간대이므로 일광절약 없음). `baseline` = b59fcaa(`minutesSinceMidnight` + 같은 날 판정 0/1440), `v183` = 183e07f(초 포함 소수 분), `head` = 1cce4a4(`floor`).

```text
GRID checked=269448 baseline≠head=0 baseline≠v183(양성 대조: 0보다 커야 도구가 차이를 잡는다)=185544
ZERO-SECONDS 전수 checked=5174850 mismatch=0
PACK b59fcaa: act=(600.0,660.0) ret=(660.0,680.0) → act[0.0,1.0] ret[0.0,1.0]
PACK 183e07f: act=(600.5,660.5) ret=(660.0,680.0) → act[0.0,0.5] ret[0.5,1.0]
PACK 1cce4a4: act=(600.0,660.0) ret=(660.0,680.0) → act[0.0,1.0] ret[0.0,1.0]
```

- 초 0·1·30·59 격자(269,448 입력)에서 `b59fcaa`와 `1cce4a4`가 **한 건도 다르지 않다**(초가 있는 입력도 기준선과 같은 "초 버림" 의미). 양성 대조: 같은 격자에서 183e07f는 185,544건 다르다.
- 초 0 데이터는 시작 −300…+1700분 × 길이 1…3000분 **전수 5,174,850건 불일치 0** — 분 내림이 항등이다(실제 `ScheduleLogic.overlapSlots`를 `Models.swift`로 돌림).
- 이전 §4.1 재현 값: 활동 10:00:30–11:00:30 + 출발 11:00:30 오는 편이 `[0,1]`(전폭)로 돌아온다(183e07f는 `[0,0.5]`/`[0.5,1]`).
- 끄는 중 미리보기: 드롭의 `effectiveDragMinutes`는 초를 0쪽으로 자른 정수 분만 더하므로 활동의 초는 그대로 남고 `span`이 내림하는 값은 저장 뒤와 같다 — 활동 쪽에서 어긋나는 자리는 없다. **다만** [정보] 끌리는 구간 자신의 드래그 갈래(`span(for event:)`의 `shift != 0` 분기, `:668-692`)는 이번 diff에 없어 여전히 초를 포함한 소수 분으로 계산한다(저장된 구간은 `minutesSinceMidnight`). 초가 0이 아닌 데이터에서만, 끄는 동안만 일어나며 어긋남은 1분 미만(<1pt)이다 — 예: 도착 기준 구간의 도착이 활동 시작 10:00:30이면 끄는 중 구간 끝 600.5 · 활동 시작 600 → 미리보기 동안 반폭 가능성(손 계산, 실행하지 않음). 초 0 데이터에는 영향 없다.

### 7.4 드라이버 단언 게임화 점검

- **AF-018-21b 고쳐 쓰기**(`git diff`): 픽스처가 `arrival: ba.endDate` → `arrival: ba.endDate.addingTimeInterval(1200)`로 바뀌었다. 손 계산: 출발 nil이므로 비교 시각 = arrival = 끝 + 20분 ≠ 어느 활동의 끝 → 후보 0 → 소유 없음 → `adjustTravelLeg(+15)`은 소유 없음 갈래(REQ-005: 출발 기준 구간은 통째로 이동)라 `departureDate`는 nil 유지, `arrivalDate`는 +15분 — 새 기대값 `b.arrivalDate == legB.arrivalDate + 15분`과 일치(§7.2의 `21b-new … owner=nil`로 소유 없음도 실행 확인). 구현 출력을 따라 쓴 기대가 아니라 SPEC 산식(REQ-005)에서 나온 값이다.
- **AF-018-29 신규**: 손 계산 — 활동 12:00–13:00(반복) + 출발 nil 복귀(arrival = 13:00): 비교 시각 = arrival = 활동 끝 → 소유 성립·배치 묶음, 활동 +30분 → arrival +1800초, departure nil 유지. 기대값(`+1800`·`depNil`)은 리터럴이다.
- **옛 규칙에서 실제로 실패하는가 — 실제 드라이버를 실행**:

```text
$ (driver 소스 + 옛 규칙 StoreOld.swift 컴파일, 독립 경로 …/scratchpad/resync/gd-old-bin)
old-driver-exit=1
522/523 통과
[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다
$ grep -n '✗' gd-old-run.log
515:  ✗ AF-018-29 출발 nil 복귀 구간(대조 시각 = arrival = 활동 끝) → 소유 성립·배치 묶음 && 활동 +30에 arrival도 +30(departure는 nil 유지)
$ grep -c '✓' gd-old-run.log → 522
```

  옛 규칙이면 523개 중 **정확히 AF-018-29 하나만** 실패한다 — 기능이 틀리면 실제로 실패하는 대조다. 샌드박스 잔여 `$TMPDIR/besir-gd-*` 없음, 실제 지원 디렉터리 3파일 불변.
- [정보] 커버리지 구멍(결함 아님): 21b가 "출발 nil + 동률"에서 "출발 nil + 끝 불일치"로 바뀌면서, 출발 nil · arrival == 끝 · 같은 끝 활동 둘(= 동률) 모양은 드라이버가 고정하지 않는다. §7.2의 `TIE dep nil` 실행이 `owningActivity=nil`임을 보였으므로 현재 동작은 올바르나 단언은 없다.

### 7.5 문서

- **CHECKLIST K13 ⚠️** — 행 근거 "드라이버 523/523·exit 0(fix1 후, B 498 + 25)" · "화면 미관측 + sync 차단 수리 뒤 S-16 확인 필요"가 사실이다: 523은 리드 관측(브리프)이고 제가 옛 규칙 사본에서 본 `522 ✓ + 1 ✗ = 523`이 총 단언 수로 일치한다. 화면 관측은 없다. ⚠️ 요약 줄(`CHECKLIST.md:313`)에도 K13이 올라가 있다.
- **인용 재대조** — `git diff -U0 183e07f..HEAD -- CHECKLIST.md`의 추가 줄을 `check.py`로 원문 줄과 대조: **22건(중복 제거 18건) 전부 이름이 맞는 심볼이 그 줄에 있다**(`ContentView.swift:1071-1073` 제스처 · `:183-188` 대화상자 · `:916`·`:924` 적용 · `:620`·`:660` span · `:882` columnFrame · `:897` block(atX:) · `:94-95`·`:107` · `Store.swift:38`·`:134`·`:1418`·`:1454`·`:429`·`:1523`·`:1648`·`:1636`). 양성 대조(`ContentView.swift:1` → `import SwiftUI`) 정상. 원문은 `doc-diff-fix1.txt`.
- **T = B + 25 = 523** — `spec.md` §0 표(고쳐 쓰기 5 · 추가 25)·REQ-013(AF-018-21b + 29, T = B + 25)·`plan.md` §5 통과 수 줄(`:213`)·`acceptance.md` AC-011(`:149`)이 같다. 이력 행(`spec.md:136`·`plan.md:282` 대응표, HISTORY의 옛 `B + 24`)은 이력이라 둔다.
- **낡은 곳 2** — (a) `plan.md:268` §9 ③ "`Store`·`ContentView`·`GuardDriver`(고쳐 쓰기 4 · 추가 24)"는 현재형 문장인데 5 · 25로 안 바뀌었다. (b) SPEC `progress.md`는 0.7.3(fix1) 항목이 없고 마지막 "현재 수치" 줄이 `T = B + 24`(0.6.0, `:361`)에 머문다 — fix1의 증거는 `run-progress.md` §5에 있다. 둘 다 문서 드리프트이고 구현·게이트에는 영향 없다.

### 7.6 새 결함 · 남은 주의 · 못 본 것

- **새 차단 없음.** 수리 diff 안에서 새로 만든 결함을 찾지 못했다.
- [정보] 끌리는 구간 자신의 드래그 미리보기 span이 초를 포함한 소수 분을 쓰는 비대칭(§7.3) — 초 0이 아닌 데이터에서만.
- [정보] 드라이버가 "출발 nil · arrival == 끝 · 동률"을 고정하지 않는다(§7.4).
- [정보] 문서 낡음 2곳(§7.5) — `plan.md:268`, SPEC `progress.md` 현재 수치.
- 못 본 것: 시뮬레이터·실기기 전부(S-16에서 **스크롤한 뒤에** 끄는 경우를 반드시 본다 — 이번 수리의 사람 눈 확인), `gr.location(in:)` 실제 호출(변환만 재현), `span` 복제 산술의 실제 함수 호출, 코디네이터 해제 시 `tick`의 `invalidate` 실행, 일광절약 시간대. 이전 §3·§4의 범위 밖 항목("다음 날 00" 눈금 폭 등)은 브리프대로 다시 열지 않았다.
