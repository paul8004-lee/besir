> **⚠️ 이 보고서가 평가한 것은 0.6.1(커밋 `e28714e`)이다. 이 보고서가 지적한 재현된 차단 결함 N5-1을 고친 0.6.2는 감사를 받지 않았다.** 칸반 리드 지시(2026-10-08): 운영자가 승인한 두 번째 예외는 이 5회차가 마지막이고 6회차는 돌리지 않는다. 수리 자가 점검 출력은 `.moai/reports/t43/progress.md` "§13 5회차 감사 결과"에 있다. 주요 결함 N5-2·N5-3와 경미 결함은 리드 지시("차단 결함에 한해")에 따라 수리하지 않았다.
>
> **평가 대상: SPEC-UIKIT-012 0.6.1 · 커밋 `e28714e`(브랜치 `WT-leg-drag-resize`, 코드는 기준 트리 `b59fcaa`와 같다 — `git diff --stat b59fcaa HEAD -- Shared Tools proxy project.yml` 출력 없음).** 5회차(마지막, 범위를 좁힌 재감사). 4회차 보고서는 0.4.0(`13ff5fb`)을 평가했으므로 결론을 물려받지 않고 해소 여부만 대조했다.

# SPEC 검토 보고서: SPEC-UIKIT-012

Iteration: 5/5(운영자 예외 두 번째, 마지막)
Verdict: **FAIL**
Overall Score: **0.75**(Tier M 기준 0.80 미달)

추론 맥락은 M1 맥락 격리에 따라 무시했다. 호출자의 범위 지시만 따랐고, SPEC 자가 점검 표(`progress.md` §E.1·§H·§I)는 증거로 쓰지 않고 도구로 다시 쟀다.

## 판정 요약

- **문서 판정: FAIL — 0.75.** 재현된 차단 결함 1건(N5-1 — REQ-016의 같은 날 폴백이 다른 회차의 오는 편을 다시 집어 "전체" 이동에서 그 구간을 두 번 옮긴다), 재현된 주요 결함 2건(N5-2 — 0.6.0 압축으로 드라이버 픽스처 시각과 AC-007 명령 묶음이 문서에서 사라짐, N5-3 — 열린 질문 Q-5의 기본값 설명이 REQ-007과 다른 날을 기준으로 함).
- **MP-7 원문 결과: FAIL** — `grep -n '\[NEEDS CLARIFICATION' plan.md research.md` → `plan.md:126`·`:127`·`:128`, `research.md:116`·`:117`·`:118`(Q-3·Q-5·Q-9, 6줄). `spec.md`·`acceptance.md`에는 0건이다. 운영자가 착수 승인에서 볼 의도된 가정 표식이다. 각 질문이 제대로 서 있는지는 아래 MP-7 항에 적었다 — **Q-3·Q-9는 바르게 서 있고 Q-5는 잘못 서 있다**(N5-3).
- 범위 1~8 가운데 차단 결함이 재현된 범위는 5(REQ-016)다. 범위 1·2·4·6·8은 재현된 차단 결함이 없다. 범위 3은 설계상 논리 결함이 재현되지 않았다(가설 두 건). 범위 7은 계수는 맞지만 근거 자료가 문서에서 빠졌다(N5-2).

## Must-Pass 결과

- [PASS] MP-1 REQ 번호 일관성: `grep -o '^- \*\*REQ-[0-9]*' spec.md` → 001~009 · 015 · 010 · 011 · 016 · 012 · 013 · 014 — 집합으로 001~016, 빠짐·중복 없음. 배치 순서가 번호 순이 아닌 것(015가 009 뒤, 016이 011 뒤)은 결함이 아니다.
- [PASS] MP-2 GEARS(요구 층만 판정): REQ 16건 모두 "When …, the store shall"(001·002·010·011), "While …"(005·009·015 — 015는 While + when 복합), "The … shall / shall not"(003·004·006·007·008·012·013·014·016) 꼴. AC는 Given-When-Then 또는 단언 표로 검증 층이라 여기서 채점하지 않았다.
- [PASS] MP-3 프런트매터: `spec.md:2-14` — id·title·version `"0.6.1"`(따옴표)·status `draft`·created·updated `2026-10-08`·author·priority `P1`·phase·module·lifecycle `spec-anchored`·tags(쉼표 문자열) 12필드, `tier: M`. 거부 별칭 없음.
- [N/A] MP-4 언어 중립: Swift 단일 언어 iOS 앱 SPEC.
- [PASS] MP-5 D7: 참조 SPEC `SPEC-UIKIT-009`·`SPEC-UIKIT-011` 둘 다 `status: completed`(`grep '^status:'`) — 폐기·대체·보관 상태 아님. BLOCKING 없음.
- [PASS] MP-6 D8: `grep -c 'syscall' spec.md` → 0. 자동 통과.
- [FAIL — 의도된 표식] MP-7: 위 6줄. 잘 선 질문인지:
  - **Q-3**(위로 넘기기 대칭 연장, 기본 "첫날 0시에서 멈춤(AF-018-09: −30 → −20)"): 바르게 섰다. 기본값 예시를 독립 스크립트로 재계산해 −20이 나왔다(아래 B절).
  - **Q-5**(연장 상한, 기본 "끄는 날 다음 날 끝(최대 1,440분)"): **잘못 섰다.** REQ-007은 "끄는 날"이 아니라 "구간이 끌기 전 나열되는 첫날 F의 다음 날 끝"을 상한으로 쓴다. 자정을 걸친 구간을 둘째 날 화면에서 끌면 두 기준이 1,440분 차이 난다(N5-3, 재현).
  - **Q-9**(연장·자동 스크롤 대상, 기본 "연결된 구간 드래그만"): 바르게 섰다. REQ-015 근거 문장·`spec.md:212`·S-10 기대("연장·자동 스크롤 없음")와 같다.

## 범주 점수(루브릭 기준)

| 차원 | 점수 | 구간 | 근거 |
|---|---|---|---|
| Clarity | 0.75 | 0.75 | 대부분 한 가지로 읽히지만 경고 블록 위쪽 경계의 엄격성(N5-4, 결과 −15 대 −20), REQ-015 (1)의 "moved end"가 움직이지 않는 밤샘 활동 끝을 포함하는지(N5-5, 연장 0시간 대 6시간), REQ-012 "no ignored `try?`"와 저장 함수의 `try?`(N5-9)가 두 갈래로 읽힌다 |
| Completeness | 0.75 | 0.75 | 절 구성 완비(HISTORY `spec.md:21`, 배경 `:46`, 요구 `:135`, 불변 `:192`, 범위 밖 H3 넷 `:204`·`:208`·`:214`·`:220`, 결정 `:224`). 그러나 0.6.0 압축이 실행에 필요한 픽스처 정의와 AC-007 명령을 지웠고(N5-2), 판 표기 줄 다섯이 낡았다(N5-8) |
| Testability | 0.50 | 0.50 | AF-018-09·10·14·23·24·25의 기대값(`plan.md:169-179`)은 픽스처 시각 없이는 참·거짓을 정할 수 없다 — 0.5.0 판 픽스처로 재계산하면 모두 맞지만(B절) 그 정의는 지금 문서에 없다. AC-007 셋째 대조는 "범위 확인 6줄"을 명령 없이 가리킨다(`acceptance.md:103`). S-14 기대는 S-13 직후 상태에서 성립하지 않는다(N5-6) |
| Traceability | 1.0 | 1.0 | AC 매트릭스(`acceptance.md:13-29`)에서 REQ 001~016이 모두 한 번 이상 나온다(손 대조: 005 → AC-003, 012 → AC-010, 013 → AC-011, 015 → AC-012·013·016, 016 → AC-012·015). 매트릭스의 모든 AC가 있는 REQ를 가리킨다 |

조화 평균 0.71, 산술 평균 0.75 — 둘 다 0.80 미달.

## A. 범위 1 — N4-1 수리(경고 블록·깨진 레코드)

코드 재측정: `failedBlockAnchor`(`Models.swift:210-213`, 출발 기준이면 `departureDate ?? arrivalDate`), `listedSpan`(`:219-222`, 미계산이거나 출발 없음·도착 ≤ 출발이면 nil), `isListed(on:)`(`:229-235` — 앵커는 `isDate(inSameDayAs:)`로 **닫힌 하루**, 나열 구간은 `Store.overlapsDay` `Store.swift:38-41`로 **반열린**), 깨진 레코드는 도착일 하루(`:234`).

REQ-007 끝 문장(`spec.md:160`)은 "나열 시각 하나만 한계에 들고 F = L = 그 시각의 날, 아래 상한은 엄격"이다. 독립 스크립트(`scratchpad/r5/lim.swift` — 위 술어를 옮겨 적고 REQ-006·007·008 문장을 그대로 구현, 서울 시간대)로 실행했다:

```text
AF-018-25b +15 15                     ← 재추정 실패 모양(출발 23:50·옛 도착 00:10·travelSeconds nil): 4회차 0.4.0의 −10이 +15로 고쳐짐
AF-018-14 15 -15                      ← 경고 가는 편(정오) ±15
AF-018-25a +15 0 -15 -15 symmetric +15 -60   ← 상한 이미 넘은 옛 구간: 방향별 자르기 0, 대칭 자르기면 반대 부호 −60
```

유효 Δ가 요청과 반대 부호가 되지 않는 성질은 REQ-008의 "between 0 and the requested Δ inclusive"로 섰다. 0.5.0 자정 재작성(아래 상한 F 다음 날 끝)과 겹쳐도 경고 블록 사례는 상한 안쪽이다. **N4-1은 해소.** 남은 문구 흠은 하나다 — N5-4(위쪽 엄격성).

## B. 범위 2 — 0.5.0 자정 재작성과 풀이 예

같은 스크립트, 0.5.0 판 `plan.md` §5의 픽스처 정의(`git show 6745911:…/plan.md` 186~206행 — **지금 문서에는 없다**, N5-2)로 계산:

```text
AF-018-06 -55
AF-018-07 +5 0 -15 -15
AF-018-08 90 leg D/D+1 false true act D/D+1 true true
AF-018-09 -20
AF-018-10 +15 15 -15 -5 overnight -30 -30
AF-018-16 60,15 -15 -10
AF-018-24 cur -20
AF-018-26 1480 D,D+1,D+2 false true false
```

모두 `plan.md:166-180`·`acceptance.md:60-82`의 기대와 같다. 손 계산 대조(AF-018-26): 오는 편 23:00→23:20, F = D, 상한 = D+2 00:00 → Δ ≤ 24시간 40분 = 1,480(5의 배수), 새 도착 D+2 00:00 — 반열린 겹침이라 D+2에 나열되지 않는다(`overlapsDay`의 `end > d.start`가 거짓).

확인한 경계:
- **0 쪽 5분 내림·초 오프셋**: 출발 23:50:30·도착 D+1 00:10:30, −15 → 시각을 먼저 분으로 내리는 해석에서 **−5**(문서 문장 그대로). 실수 비교였다면 −10도 나열을 지키지만, REQ-008이 "times … first truncated toward zero"라고 정해 한 가지로 읽힌다(4회차 보고서가 남긴 모호함은 닫혔다).
- **DST**: 뉴욕 2026-10-31을 F로 두면 "F 다음 날 끝"까지 2,940분(25시간 날 포함). 서울은 일광 절약제가 없어 해당 없음. REQ-015의 "1,440 at every other time"과 기존 `minutesSinceMidnight`(`ContentView.swift:523-526`, 벽시계 성분) 산술도 같은 이유로 해당 없음.
- **놓은 뒤 끄던 날에서 통째로 사라지는 구간**: AF-018-08 결과 구간은 D+1에만 나열 — `plan.md:55`·S-6 서술과 같다.
- **밤샘 활동**: 가는 편 21:40→22:00, 활동 22:00–D+1 06:00, −30 → −30.
- **최소보다 짧은 활동**: 3분 활동 +5 → 0, −15 → −15(줄이기는 거절, 늘이기는 그대로).
- **AF-018-23 꼴 격자가 틀린 규칙에서 실패하는가**: 0.5.0이 적은 두 픽스처(하루짜리 22:10→22:30, 걸친 23:50→00:10)에 요청 −180…+180을 돌린 결과:

```text
SWEEP two fixtures req/sym/noCap/noDir/zeroIncl [0, 0, 0, 0, 35]
SWEEP +old 23h leg req/sym/noCap/noDir/zeroIncl [0, 0, 12, 0, 35]
```

  이 격자는 "0시 허용"(엄격 대신 이상) 규칙만 잡는다. 대칭 자르기·상한 없음·방향 무시 규칙은 0건으로 통과한다. 상한 없음은 AF-018-26이, 대칭 자르기·반대 부호는 AF-018-25 (a)가 따로 잡으므로 회귀선은 비지 않는다 — 다만 격자 자체의 판별력은 0.5.0 판의 주장("대칭 자르기·상한 없음 규칙에서 실패")보다 좁다(N5-7).

## C. 범위 3 — 끄는 중 가장자리 자동 스크롤

코드 구조(재측정):
- `ScrollView {` `ContentView.swift:417` → `HStack` → `GeometryReader { … }` `:426` → `.overlay(RescheduleOverlay(…))` `:456-479`. 오버레이의 `UIView`(`ScrollTouchFixView` `:893`)는 스크롤 콘텐츠 안에 있다. 조상 `UIScrollView`를 찾는 코드(`:856-861`)가 지금 실제로 `delaysContentTouches`를 끄는 데 쓰이므로, 오버레이의 조상 사슬에 스크롤 뷰가 있다는 것은 코드로 뒷받침된다(런타임 미관측).
- 따라서 `gr.location(in: gr.view)`(`:939`)는 콘텐츠 좌표이고, 손가락이 화면에 멈춘 채 콘텐츠가 s pt 움직이면 y가 s만큼 바뀐다. `y − startY`(`:947`)를 매 틱 다시 읽으면 보정이 끝나고, 오프셋을 더하면 두 번 더해진다는 SPEC 주장(`plan.md:93`)은 구조상 맞다.
- 분 변환은 `onChange` 한 곳(`:463-466`)이고 틱도 같은 클로저를 부르게 설계됐다(`plan.md:94`). `updateUIView`(`:911-916`)가 매 렌더 코디네이터의 클로저를 갈아 끼우므로 틱이 `self.onChange`를 부르면 최신 상태를 본다 — 계약 5 유지.
- `activeDrag`를 비우는 곳은 `onEnd` 하나뿐이다(`grep -n 'activeDrag' Shared/ContentView.swift` → 쓰기 `:460`·`:465`·`:469`). 다른 경로가 드래그를 끝내는 일은 없다. 한 페이저 안의 세 페이지가 같은 `activeDrag`와 `.scrollDisabled`(`:494`)를 공유하지만 길게 누르기는 지금 페이지의 오버레이만 받는다.
- 멈춤 경로: `.ended`·`.cancelled/.failed`(`:948-953`)·거절(`:944` — 거절이면 자동 스크롤이 시작되지 않으므로 무해)·`dismantleUIView`(지금 없음 — `grep -c 'func dismantleUIView'` → 0, 새로 둠)·`didMoveToWindow`(이미 오버라이드 `:855`)·틱 안 상태 검사. 목록은 빠짐없다.
- 멈춘 손가락: `UILongPressGestureRecognizer`는 움직일 때만 `.changed`를 보낸다 — 틱이 위치를 다시 읽는 설계가 맞다.
- 연장과 상한: 상한이 F 다음 날 끝이라 연장은 최대 1,440분(끄는 날 = F일 때). 손가락이 띠 깊숙이 있어도 콘텐츠 끝에서 스크롤이 멈추고, 끌린 블록 먼 끝이 24:00을 넘는 순간 한 시간이 늘어 다음 틱이 더 내려가는 되먹임은 상한에서 끝난다. 막히는 경우는 찾지 못했다.

판정한 결함·가설:
- **`scrollDisabled` 중 프로그램 스크롤 전제**(`plan.md:110`)는 〔가설〕로 표시돼 있고 대체안이 있다. 다만 대체안이 "멈춤 함수에서 되돌린다"고만 적어, 자동 스크롤을 하지 않는 드래그(활동 블록·연결 없는 구간 — Q-9 기본값)에서 사용자 팬을 누가 막는지 정하지 않았다. `.scrollDisabled`를 빼면 지금의 드래그 중 스크롤 잠금이 그 두 드래그에서 사라질 수 있고, `spec.md` §3 "바뀌지 않는 것"(`:195`)은 날짜 넘김 잠금만 적고 스크롤 잠금을 적지 않아 어느 AC·S도 그 회귀를 잡지 않는다(N5-10).
- **놓을 때 튀어 오름**(`plan.md:104`·S-17)은 사실로 서술됐다. 콘텐츠 높이가 줄 때 SwiftUI `ScrollView`가 오프셋을 새 최대로 당기는지는 확인되지 않았다 — `UIScrollView`는 `contentSize`가 줄어도 `contentOffset`을 스스로 고치지 않을 수 있다. 미재현 가설(N5-11).
- **틱의 런루프 모드**: `plan.md:106`은 `Timer`를 "스크롤 중 런루프 모드 문제로" 버리고 `CADisplayLink`를 골랐지만, 디스플레이 링크도 `add(to:forMode:)`로 넣은 모드에서만 돈다. `.default`로 넣으면 추적 모드에서 같은 문제가 생긴다. 모드를 정하지 않았다 — 미재현 가설(N5-12).
- 약한 대리 객체·멈춤 함수 하나·`@MainActor` 경고는 무경고 빌드 게이트가 맡는다(`plan.md:106`). 코디네이터가 찾은 스크롤 뷰를 약하게 잡아야 한다는 말은 없다(가설, 검증 못 함).
- 드라이버가 못 하는 것(UIKit 전부)은 `plan.md:122`·`acceptance.md:155`에 정확히 적혔다.

## D. 범위 4 — 그리기 최소 높이

- `span(for activity:on:)`(`ContentView.swift:543-556`)은 `max(Self.minActivityMinutes, end − start)`를 렌더(`positionedBlocks` `:717-720`)와 히트 테스트(`block(atX:y:)` `:753-765`)가 함께 읽는다 — 상수만 20 → 5로 바꾸면 REQ-006 "실제 길이, 5분 바닥, 잘린 반쪽도 5분" 그대로가 된다. 잘린 반쪽 특수 사례(주석 `:550-554`)는 바닥 5분으로 1~4분 반쪽도 보인다.
- 반폭 분할이 줄어든다는 주장(`spec.md:107`, `plan.md:47`): 묶음 안 배치 `overlapColumns`(`Models.swift:340-370`)는 `columnEnds[i] <= item.start`(`:362`·`:364`)면 겹침으로 보지 않는다. 5분 이상 활동 [s, s+L]과 끝에서 출발하는 오는 편은 맞닿기만 하므로 전폭이다. 5분 미만 활동만 5분으로 부풀어 반폭이 남는다. 주장과 같다.
- `minTravelMinutes = 16`(`:532`) 유지, AC-004 대조 기준값 실측: `grep -c 'minActivityMinutes: CGFloat = 5$'` 0 · `= 20` 1 · `minTravelMinutes: CGFloat = 16` 1(`acceptance.md:71`과 같다).
- Q-10 수용 위험은 `spec.md:107`·`:218`, `plan.md:131`·`:205`·`:234`, `acceptance.md:193`(S-18)에서 같은 말로 적혔다. 일관됨.

## E. 범위 5 — REQ-016(정확한 앵커 대조 우선)

- `estimatedLegs`(`Store.swift:1427-1434`)의 호출자는 `packingGroups`(`:446`)와 `linkedLegs`(`:1421`) 둘, `linkedLegs`의 호출자는 `moveActivity`(`:1371`) 하나다(`grep -n 'linkedLegs(for\|estimatedLegs(for' Shared/*.swift`). `research.md` §9의 표(`:125-143`)는 인용 줄을 재측정한 결과 모두 실재했다(`:325`·`:339`·`:353`·`:439`·`:446`·`:581`·`:587`·`:1547`·`:1630`, `AIAssistant.swift:2127`·`:2146`·`:2188`·`:2394`, `ContentView.swift:662`, `EventDetailView.swift:91-98`).
- 핀 뒤집기: AF-015 픽스처의 L 오는 편은 출발 = L 끝(`GuardDriver.swift:4291-4294`, `2*86400 + 23*3600 + 2400` 양쪽 같음)이라 정확한 대조로 든다 → AF-015-09는 {R 가는 편 → R, R 오는 편 → R, L 오는 편 → L}, AF-015-11은 포함으로 바뀐다. AF-015-12(`:4328-4337`)는 R의 두 구간이 정확한 대조로 잡히고 L 구간은 손대지 않으므로 그대로 참이다(라벨 문구 "(9)가 돌려준 구간들"은 (9)에 L이 들어가면서 부정확해진다 — 경미, 선택). AH-015-13(`:4788-4815`)은 O 도착 14:00 = A 시작, R 출발 15:00 = A 끝이라 결과 불변. 운영자 2차 답변이 근거이므로 뒤집기는 정당하다.
- 이웃 회차·자정 넘긴 활동·옛 드래그로 어긋난 구간을 짚었다. 대부분 지금보다 낫거나 같다. 예외 하나가 재현됐다 — **N5-1**: 밤샘 반복에서 한 회차의 오는 편이 정확히 맞지 않으면(옛 틈, 연결 없는 갈래로 옮겨진 구간, 활동 편집으로 끝만 바뀐 회차 — t49 갭, 삭제된 회차 구간), 그 회차는 같은 날 폴백으로 **앞 회차의 오는 편**을 집는다. 앞 회차도 정확한 대조로 같은 구간을 집으므로 "전체" 이동에서 그 구간이 두 번 옮겨진다. 지금 코드(같은 날만)에서는 앞 회차가 그 구간을 집지 못해 한 번만 옮겨졌다:

```text
$ ./req16   (scratchpad/r5/req16.swift — estimatedLegs :1427-1434와 moveActivity 루프 :1370-1374를 옮김)
old A0 (Optional(1), nil) A1 (Optional(3), Optional(2))
new A0 (Optional(1), Optional(2)) A1 (Optional(3), Optional(2))
moveActivity whole +30 shift per leg id: old [(key: 1, value: 30), (key: 2, value: 30), (key: 3, value: 30)]
moveActivity whole +30 shift per leg id: new [(key: 1, value: 30), (key: 2, value: 60), (key: 3, value: 30)]
```

  픽스처: 반복 활동 A0 D 22:00–D+1 02:00, A1 D+1 22:00–D+2 02:00(장소 P). A0 오는 편 #2 출발 D+1 02:00(정확), A1 오는 편 #4 출발 D+2 02:10(10분 틈). 결과 #2가 +60 — A0 끝(+30)과 30분 벌어진다. 같은 일이 구간 드래그 "전체"(REQ-010 "each through that occurrence's own same-role leg found by the forward leg lookup")에서도 일어난다 — A1의 정방향 조회가 #2를 돌려주므로 A1 끝이 움직이고 #2가 한 번 더 옮겨진다. REQ-001("출발이 끝과 같았으면 놓은 뒤에도 같다")과 REQ-003을 같은 데이터에서 동시에 만족할 수 없다.

## F. 범위 6 — 구글 분리

AC-010의 명령(`acceptance.md:122`)을 그 글자 그대로 macOS `awk`·BSD `grep`로 돌렸다:

```text
$ awk '/func updateActivity\(/,/^    }$/' Shared/Store.swift | grep -c 'Task {\|removeFromCalendar\|enqueueCalendarUpload\|googleEventId'
6          ← 양성 대조(작업 트리)
$ awk '/func adjustTravelLeg/,/^    }$/' Shared/Store.swift | grep -c '<같은 패턴>'
0          ← 회귀선(작업 트리)
기준 트리(git show b59fcaa:Shared/Store.swift > scratchpad/r5/base/Store.swift): 6 · 0
$ awk '/func adjustTravelLeg/,/^    }$/' Shared/Store.swift | wc -l   → 24(범위가 함수 하나로 끊긴다)
$ … | grep -c 'Task {\|await\|try?' → 0 · grep -c 'Task {' Shared/Store.swift → 8 · grep -c 'addingTimeInterval(-' → 5
```

남은 구글 의존: 없다. `grep -n '추적 \`Task\`\|googleConnected\|removeFromCalendar\|enqueueCalendarUpload\|구글'`로 네 문서를 훑은 결과 구글 언급은 HISTORY·대응표·범위 밖·REQ-012 근거·D-6 기록뿐이고, "드롭당 추적 `Task`" 가정은 `plan.md:67` ③에서 삭제로 기록됐다. 저장 순서와 `rescheduleNearestNotifications` 한 번은 구글과 무관한 규율로 남았다(`plan.md:67` ④, `spec.md:176`). 드롭 경로가 부르는 `save()`·`saveActivities()`·`rescheduleNotification(at:)`에도 구글 호출이 없다(`awk` 확인 — `save`·`saveActivities`는 파일 쓰기뿐, `rescheduleNotification` 패턴 0).

인계 파일 경계: `google-card-handoff.md`의 인용을 재측정했다 — `Store.swift:790` `googleConnected`, `:97`·`:101` `removeFromCalendar`, `:288` `guard googleConnected, let gid`, `:1073` `if googleConnected {`, `:1082` `await removeFromCalendar(gids)`, `:1113` `enqueueCalendarUpload`, SPEC-UIKIT-009 `spec.md:90`(F12 정의)·`:197`(범위 밖), `SettingsView.swift:61`. 모두 실재. SPEC 본문 어디도 t48의 존재에 기대지 않는다(REQ-012는 "구글을 부르지 않는다"로 자기완결).

## G. 범위 7 — 개수와 추적

- REQ 16(`grep -c '^- \*\*REQ-' spec.md` → 16), AC 15(`grep -c '^## AC-' acceptance.md` → 15, AC-014 결번). Tier M 상한은 요구·수락 기준 각 16, 서로 독립(주 체크아웃 `spec-workflow.md:146-152` 실측 — `spec.md:38`의 인용 줄과 같다). 상한 안.
- 드라이버 계수: 기존 AF 단언은 번호 하나에 `drvCheck` 하나다(`grep -o 'drvCheck("AF-01[58]-[0-9]*' Tools/GuardDriver.swift | sort | uniq -c` → AF-015-09·10·11·12, AF-018-01·02·03 각 1). `plan.md` §5 표의 범위 표기를 펼치면 추가 번호는 04·05·06·07·08·09·10·11·12·13·14·15·16·17·18·19·20·21·22·23·24·25·26·27 = **24**, 고쳐 쓰기 AF-018-02·03·AF-015-09·11 = 4. **T = B + 24** 맞다(`grep -o 'B + 2[0-9]'` → spec 2·plan 2·acceptance 1, 모두 `B + 24`).
- `grep -o 'AF-018-[0-9][0-9]' plan.md | sort -u | wc -l` → **20**(범위 표기 탓). 이 명령을 증거로 쓰는 자리는 `progress.md:112`·`:155`·`:208`·`:256`·`:289`(0.2.0~0.5.0 판 기록)뿐이고, 0.6.0·0.6.1 판의 개수 근거(`spec.md:43` → `plan.md` §5, `progress.md:402`의 펼친 설명)는 이 명령에 기대지 않는다. 지금 틀린 의존은 없다.
- REQ↔AC: Traceability 1.0(위 표).

## H. 범위 8 — 0.6.1 개정

`git diff --stat 12a0590 e28714e` → SPEC 다섯 파일만(acceptance 4·plan 17·progress 21·research 4·spec 13줄). 바뀐 줄을 모두 읽었다: Q-10(수용 위험, S-18), Q-11(t49, AC-007 해시 문장), Q-12(Tier M), 판 번호·HISTORY·§I 기록뿐이다. 다른 의미 변경은 없다.

AC-007의 해시 대조를 그 명령대로 돌렸다:

```text
기준(b59fcaa) realignReturnLeg: a6ca6f17d69f86a6e67d2eff7fa06759f5ff4a0d (8줄)
작업 트리     realignReturnLeg: a6ca6f17d69f86a6e67d2eff7fa06759f5ff4a0d
offsetY      2cd32a58b96328d29f74bde60f15579cd581b3b4 = 2cd32a58b96328d29f74bde60f15579cd581b3b4
finalizeDrag 3027e8ee6676bf96d0062dafbab4ab00598db5c1 = 3027e8ee6676bf96d0062dafbab4ab00598db5c1
```

`acceptance.md:102`의 `a6ca6f17…`·8줄과 같다. 남은 표식은 Q-3·Q-5·Q-9뿐이고 `plan.md`·`research.md`에만 있다(MP-7 항). 다만 0.6.1이 손대지 않은 낡은 줄이 남았다(N5-8 — 특히 `acceptance.md:220`이 Q-10·11·12를 아직 열린 질문으로 적는다).

## 4회차 결함 해소 대조

| 결함 | 상태 | 증거 |
|---|---|---|
| N4-1 경고 블록 반대 방향 | **해소** | REQ-007 끝 문장(`spec.md:160`), REQ-008 "0과 요청 사이"(`:162`). 스크립트 AF-018-25b +15 → +15. 문구 잔여 N5-4(경미) |
| N4-2 S-14가 최소 길이에 가림 | **해소(새 결함으로 대체)** | `자정`이 21:40–23:40(2시간)이라 최소 길이 한계 −175가 걸리지 않는다. 그러나 0.6.0에서 S-13이 "1시간쯤" 끌기로 바뀌어 S-14 기대가 성립하지 않는다(N5-6) |
| N4-3 AF-018-10 연달은 −15 | **해소** | `plan.md:170` "새 픽스처 −15 → −5". 스크립트 −5. 단 픽스처 시각이 문서에 없다(N5-2) |
| N4-4 드롭 문구 | **해소** | REQ-008 "apply the store function to the value it receives (the drag's stored effective Δ)" · "When the dragged leg's id no longer exists …, with or without an owner"(`spec.md:162`), REQ-005 "that still exists in the stored schedule"(`:151`) |
| N4-5 HISTORY 동률 문구 | **해소** | `spec.md:28` 〔0.5.0 정정 — N4-5 …〕가 REQ-004(`:149`)와 같다 |
| N4-6 게이트 D-4 예 ③ | **해소(대상 소멸)** | 게이트가 운영자 답변으로 닫혀 그 문구가 없다 |
| N4-7 `diff <(…)` 거부 | **해소** | AC-007이 `shasum` 두 줄 비교로 바뀌었고 이 회차에 그대로 돌았다(H절) |
| H-1 도우미 범위 `awk` | **미해소(명령이 사라짐)** | 0.4.1의 범위 확인 명령 묶음(`git show 6cabc93:…/acceptance.md` 144~160행)이 0.6.0에서 빠져 `acceptance.md:103`은 "범위 확인 6줄"만 가리킨다 — 판단 대상 명령이 없다(N5-2) |
| H-2 DST 픽스처 | **미해소 가설(해당 없음)** | 픽스처 구성 규칙이 문서에서 빠졌다. 서울(일광 절약제 없음) 기계에서는 해당 없음. 실행 환경 시간대는 확인하지 않았다 |

## Defects Found (구조화 결함 목록)

D1. **N5-1 REQ016-FALLBACK-DOUBLE-CLAIM** — `spec.md:180`(REQ-016 "fall back to today's same-day rule only for a role with no such leg"), `spec.md:176`(REQ-010), `research.md:130`(§9 `moveActivity` 행 "따라온다"만 적음) / 코드 `Store.swift:1427-1434`·`:1370-1374` — 밤샘 반복에서 오는 편이 정확히 맞지 않는 회차가 같은 날 폴백으로 앞 회차의 오는 편을 집어, `moveActivity` 전체 이동과 구간 드래그 "전체"에서 그 구간을 두 번 옮긴다. 재현(스크립트 출력 E절 — 구간 #2 +60, 활동 +30). 지금 코드에서는 +30 한 번이므로 REQ-016이 만드는 회귀다 — Severity: **blocker** — Class: blocking — 재현됨 — Required fix: REQ-016에 "폴백은 같은 반복의 다른 활동과 정확히 대조되는 구간을 고르지 않는다"(또는 "같은 반복 안에서 한 구간은 한 활동에만 대응한다")를 더하고, `research.md` §9 `moveActivity`·REQ-010 행에 이중 대응 검토를 적고, AF-018에 이 픽스처(밤샘 두 회차·뒤 회차 오는 편 10분 틈 → "전체" +30 뒤 앞 회차 오는 편 +30 정확히 한 번)를 단언 하나로 더한다(T = B + 25 — 계수 문장 셋 함께 갱신). `moveActivity` 본문은 REQ-014로 묶여 있으므로 고치는 자리는 `estimatedLegs`다.

D2. **N5-2 COMPRESSION-LOST-FIXTURES** — `plan.md:166-181`(§5 표), `acceptance.md:79-83`·`:103`·`:113` — 0.6.0이 §5를 줄이며 AF-018-09(활동 00:40–03:40)·10(활동 20:50–23:50·출발 23:50·도착 D+1 00:10, 밤샘 22:00–06:00)·14(정오)·23(두 픽스처·D−1…D+3 나열 대조)·24(사본·현재 값 시각)·25((a) 출발 23:00·도착 D+2 01:00, (b) 출발 23:50·옛 도착 00:10)의 픽스처 시각과, AC-007 "소유 조회는 onBegin에서만"의 범위 확인·금지 패턴 명령 묶음을 지웠다. `grep -c '23:50' plan.md` → 0(0.4.1 판 `git show 6cabc93:…/plan.md | grep -c '23:50'` → 5). 지금 문서만으로는 "−15 → −5"·"−30 → −20" 같은 기대의 참·거짓을 정할 수 없다 — Severity: major — Class: blocking — 재현됨 — Required fix: 0.5.0 판 §5 표의 픽스처 열(`git show 6745911:.moai/specs/SPEC-UIKIT-012/plan.md` 186~206행)을 행마다 되살리고(범위 행을 합친 것은 그대로 둬도 된다), AC-007 셋째 대조의 명령 여섯 줄과 금지 패턴 다섯 줄을 0.4.1 판 `acceptance.md` 144~160행에서 옮겨 온다.

D3. **N5-3 Q5-REFERENCE-DAY** — `plan.md:127`(Q-5 "기본은 끄는 날 다음 날 끝(최대 1,440분)"), `research.md:117`, `progress.md:428`(〔가정〕 "아래 상한은 끄는 날 다음 날 끝") 대 `spec.md:160`(REQ-007 "no later than the end of the day after F", F = 구간이 끌기 전 나열되는 첫날)·`plan.md:55`·`:103` — 자정을 걸친 오는 편(23:50→D+1 00:10)은 D+1 화면에도 나열되고(스크립트 `DRAGDAY listedD+1 true`) 거기서 끌 수 있다. REQ-007로는 요청 +3,000의 유효 Δ가 **1,430**, "끄는 날 다음 날 끝"으로는 상한이 **2,870**이다(스크립트 출력). 운영자는 착수 승인에서 REQ와 다른 기본값을 보고 답하게 된다 — Severity: major — Class: blocking — 재현됨 — Required fix: Q-5 문구와 `research.md:117`·`progress.md:428`을 "구간이 끌기 전 나열되는 첫날의 다음 날 끝(끄는 날이 그 첫날이면 연장 최대 1,440분, 둘째 날 화면에서 끌면 연장 없음)"으로 고치거나, 운영자 뜻이 "끄는 날 기준"이면 REQ-007의 F를 "드래그를 시작한 날"로 바꾸고 AF-018-26을 그대로 둔다.

D4. **N5-4 WARN-UP-STRICTNESS** — `spec.md:160`(경고 블록 문장: 위쪽은 "새 출발 ≥ F 시작"과 "새 도착 > L 시작"을 한 시각에 둘 다 적용하는지, 엄격은 아래만인지 정하지 않음) — 가는 편 경고 블록 00:20, 요청 −30: 엄격 해석 **−15**, 비엄격 해석 **−20**(스크립트 `WARN-UP strict -15 nonstrict -20`). 앵커 00:00은 그날에 나열되므로(`isListed` 닫힌 하루, 스크립트 `anchor0000 listed true`) 둘 다 나열을 지킨다 — Severity: minor — Class: optional — 재현됨 — Required fix: "경고 블록·깨진 레코드의 위쪽 한계는 새 나열 시각 ≥ F 시작(0시 포함)"처럼 한 문장으로 못박고, 단언을 원하면 AF-018-14에 0시 근처 하위 사례를 `&&`로 붙인다.

D5. **N5-5 EXTENSION-UNMOVED-END** — `spec.md:170`(REQ-015 (1) "when the moved end of that leg or of its owning activity lies after the end of the day") — 밤샘 활동(22:00–D+1 06:00)의 가는 편을 D 화면에서 끌면 활동 끝은 움직이지 않지만 이미 D 끝보다 360분 뒤다. "moved end"를 "옮긴 범위의 끝"으로 읽으면 끌기 시작부터 6시간이 연장되고, "움직인 끝"으로 읽으면 연장이 없다. 운영자 원문은 "00시에서 내리는 만큼"이다 — Severity: minor — Class: blocking(운영자 지시와의 일관성) — 재현됨(산술: 06:00 = 1,440 + 360 → 올림 6시간) — Required fix: "끌기로 움직인 끝(오는 편 도착·오는 편의 활동 끝, 가는 편 도착)만 연장 계산에 든다"로 고친다.

D6. **N5-6 S14-AFTER-S13** — `acceptance.md:189-190` — S-13이 오는 이동을 "1시간쯤" 내린 뒤 S-14는 "활동을 끌기 전 상태로 되돌린 뒤" 모레 화면에서 오는 이동을 1시간 위로 끈다. 그 상태의 구간은 출발 ≈ 모레 00:40으로 모레에만 나열(F = L = 모레) → 위쪽 한계 Δ ≥ 0시 − 00:40 = −40, 도착 = 00:00 + 이동시간(도착 B = 00:10이면 30분 → 00:30). 기대 "도착이 모레 00:01~00:05에서 멈추고"는 S-13 시작 상태(구간이 자정을 걸침)에서만 맞고, 실행 취소가 없어(`acceptance.md:174`) 그 상태로 되돌릴 방법도 적히지 않았다 — Severity: minor — Class: optional — 재현됨(산술) — Required fix: S-14를 "새 활동(21:40–23:40)과 자정을 걸치는 오는 편으로 새로 만든 뒤"로 독립시키거나 기대를 "출발이 모레 00:00에서 멈춘다"로 바꾼다.

D7. **N5-7 SWEEP-POWER** — `acceptance.md:83`(AF-018-23) — 0.5.0이 적은 두 픽스처의 −180…+180 격자는 "0시 허용" 규칙만 잡고(35건) 대칭 자르기·상한 없음·방향 무시 규칙에서 0건이다(B절 출력). 회귀선은 AF-018-25·26이 메운다 — Severity: minor — Class: optional — 재현됨 — Required fix: 격자 픽스처에 AF-018-25 (a)의 상한 초과 옛 구간을 더하거나, AC-005에 "격자의 판별력은 0시 규칙에 한정, 대칭·상한은 25·26이 맡는다"고 적는다.

D8. **N5-8 STALE-LINES** — `acceptance.md:3`("0.6.0 — 미감사"), `acceptance.md:220`("열린 질문 Q-3·5·9·10·11·12가 … 닫힌 뒤 run" — 10·11·12는 0.6.1에서 닫힘), `plan.md:3`("HEAD `6cabc93`", "0.6.0은 독립 감사를 받지 않았다"), `progress.md:8`("REQ 14 · AC 12"), `progress.md:13`(plan_status "0.6.0 draft") — Severity: minor — Class: optional — 재현됨(`sed -n` 출력) — Required fix: 다섯 줄을 0.6.1·감사 5회차 기준으로 고친다(특히 `acceptance.md:220`은 완료 정의 문장이다).

D9. **N5-9 REQ012-TRY** — `spec.md:184`(REQ-012 "no ignored `try?`") 대 드롭이 반드시 부르는 `save()`(`Store.swift` `func save()` — `try? FileManager…`·`try? data.write`)와 `saveActivities()` — 글자 그대로면 REQ-010·D-7이 요구하는 저장이 REQ-012를 어긴다. AC-010은 새 함수 본문만 세므로 실제 판정은 "새 코드에 무시된 `try?` 없음"이다 — Severity: minor — Class: optional — 재현됨(코드 열람) — Required fix: "no `Task`, no `await`, and no new ignored `try?` in the drop's own code (the existing persistence helpers excepted)"로 고친다.

D10. **N5-10 FALLBACK-SCROLL-LOCK** — `plan.md:110`(대체안: `.scrollDisabled` 제거 + 팬 끄기를 "멈춤 함수에서 되돌린다"), `spec.md:195`(§3이 스크롤 잠금을 불변으로 적지 않음) — 대체안이 쓰이면 자동 스크롤을 하지 않는 드래그(활동 블록·연결 없는 구간)에서 스크롤 잠금이 사라질 수 있고 이를 잡는 AC·S가 없다 — Severity: minor — Class: optional — 재현됨(문서 대조), 런타임은 미재현 — Required fix: 대체안 문장에 "팬 끄기는 모든 드래그의 시작(`onBegin` 수락)에서 켜고 `onEnd`에서 되돌린다"를 적고, §3에 "드래그 중 화면 스크롤 잠금"을 더하고, S-10에 "끄는 동안 화면이 손가락에 끌려 스크롤되지 않는다"를 붙인다.

D11. **N5-11 S17-CLAMP-ASSUMED** — `plan.md:104`, `acceptance.md:192`(S-17) — 연장이 사라질 때 화면이 하루 끝으로 "튀어 오른다"를 사실로 적었지만 콘텐츠 높이가 줄 때 오프셋이 자동으로 당겨지는지는 확인되지 않았다 — Severity: minor — Class: optional — **미재현 가설** — Required fix: 〔가설〕로 표시하고, 당겨지지 않으면 놓을 때 오프셋을 새 최대로 직접 맞춘다는 대안을 D-11에 한 줄 더한다.

D12. **N5-12 DISPLAYLINK-RUNLOOP-MODE** — `plan.md:106` — `Timer`를 런루프 모드 문제로 버린 근거는 `CADisplayLink`에도 똑같이 적용된다(넣은 모드에서만 돈다). 모드가 정해지지 않았다 — Severity: minor — Class: optional — **미재현 가설** — Required fix: "`add(to: .main, forMode: .common)`"을 명시하고 AC-016 G에 `grep -c 'forMode: .common'` 1을 더한다.

D13. **N5-13 AF015-12-LABEL** — `Tools/GuardDriver.swift:4331`("정확히 (9)가 돌려준 구간들이 +30분이다") — AF-015-09가 L 구간까지 돌려주게 되면 라벨이 단언 내용(R의 두 구간만)과 어긋난다. 단언 자체는 그대로 참 — Severity: minor — Class: optional — 재현됨(코드 열람) — Required fix: `plan.md` §5에 AF-015-12 라벨 문구 손질을 한 줄 적는다(단언 수 불변).

## Regression Check (4회차 대비)

위 "4회차 결함 해소 대조" 표와 같다. 4회차 차단 결함 N4-1은 해소됐다. 같은 결함이 세 회차 연속 남은 것은 없다(정체 없음). 점수는 4회차 0.80(0.4.0 평가) → 이번 0.75로 내려갔지만, 평가 대상이 0.4.0 → 0.6.1로 크게 바뀌었고(운영자 답변 둘, 요구 둘 추가) 이번이 마지막 감사이므로 STOP 신호는 착수 승인 경로로 넘긴다.

## Recommendation

1. **N5-1(차단)**: REQ-016에 폴백 배제 조항 한 문장, `research.md` §9 두 행, 드라이버 단언 하나(T = B + 25 — `spec.md:43`·`:188`, `plan.md:186`, `acceptance.md:130`의 계수 함께). 고치는 코드 자리는 `estimatedLegs` 하나다.
2. **N5-2(주요)**: 0.5.0 판 §5의 픽스처 열과 0.4.1 판 AC-007 명령 묶음을 지금 문서로 되살린다 — 기대값은 이번 재계산으로 모두 맞았으므로 새로 계산할 것은 없다.
3. **N5-3(주요)**: Q-5 문구를 REQ-007의 F 기준으로 고친 뒤 착수 승인에서 묻는다(또는 운영자 뜻에 맞춰 REQ-007을 바꾼다).
4. 경미 N5-4~N5-13은 run M0 또는 sync에서 처리해도 판정에 영향이 없다. 다만 N5-8의 `acceptance.md:220`(완료 정의)은 착수 승인 전에 고치는 편이 맞다.
5. 착수 승인: Q-3·Q-9는 지금 문구로 물을 수 있다. Q-5는 3번 뒤에 묻는다.

## 검증하지 못한 것

드라이버·iOS 빌드·시뮬레이터를 돌리지 않았다(코드 무변경 단계). AF 기대값 재계산은 앱 술어를 옮겨 적은 독립 스크립트이며, run이 만들 실제 Store 함수와 같다는 보증은 없다. REQ-016 회귀 재현도 `estimatedLegs`·`moveActivity` 루프를 옮겨 적은 모형이다 — 실제 `Store`를 부르지 않았다. 자동 스크롤에 관해서는 런타임을 하나도 관측하지 못했다: SwiftUI `ScrollView`가 `UIScrollView`로 구현되어 오버레이가 그 콘텐츠의 하위 뷰라는 것(코드 구조와 기존 `delaysContentTouches` 수리로만 뒷받침), `.scrollDisabled` 중 `setContentOffset`이 먹는지, 멈춘 손가락에서 `location(in:)`이 콘텐츠 이동을 반영하는지, 앱을 내릴 때 `.cancelled`가 오는지, 콘텐츠가 줄 때 오프셋이 당겨지는지, `CADisplayLink`가 길게 누르기 추적 중 어느 런루프 모드에서 도는지, 격리 경고. 짧은 활동의 실제 탭 가능성(S-18)과 감각 매개값도 화면 몫이다. `scratchpad/r5/`의 스크립트(`lim.swift`·`req16.swift`)와 기준 트리 사본은 이 회차의 증거로 남겨 두었다.
