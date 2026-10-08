> **⚠️ 이 보고서가 평가한 것은 0.4.0(커밋 13ff5fb)이다. 이 보고서가 지적한 차단 결함 N4-1을 고친 0.4.1은 감사를 받지 않았다.**
> 칸반 리드 지시(2026-10-08): 감사 상한 3회를 한 번 넘기는 예외는 이 4회차가 마지막이고 5회차는 돌리지 않는다. 0.4.1의 수리 자가 점검 출력은 `.moai/reports/t43/progress.md` "재감사 결과" 절에 있다.

# SPEC 감사 보고서: SPEC-UIKIT-012

Iteration: 4 (3회 상한을 넘긴 일회성 예외 — 범위를 좁힌 재감사, 5회차 없음)
Verdict: FAIL
Overall Score: 0.80

- **문서 판정(게이트 표식 제외): FAIL — 0.80.** 3회차 차단 결함 셋(R3-1·R3-2·R3-3)은 모두 해소됐다(도구로 재현). 다만 0.4.0의 REQ-007 산식이 **출발이 남아 있는 경고 블록**(재추정 실패 모양)에 적용되면 끈 방향과 **반대로** 활동을 옮기는 새 결함이 하나 재현됐다(N4-1, major). 고칠 곳은 REQ-007·plan D-4의 한 조항과 드라이버 단언 하나다.
- **게이트 상태**: D-3(최소 길이)·D-6(구글)·D-8(SPEC-UIKIT-009)은 물을 준비가 됐다. **D-4(자정)도 물을 수 있다** — 권장 규칙의 실제 범위가 구체 예시(①②)로 적혔고 예시 산술은 맞다. 예 ③의 "그 밖의 시간대는 제한이 없다"와 (b)안의 결과 설명 누락은 문구 손질 거리다(N4-6, 판정 제외).
- **MP-7 원문 결과: FAIL** — `grep -rn '\[NEEDS CLARIFICATION' plan.md research.md` → `plan.md:54`·`:62`·`:77`·`:91`, `research.md:97`·`:98`·`:99`·`:100`(8줄, 4주제). `spec.md`·`acceptance.md` 0건. 의도된 착수 승인 게이트이며 문서 판정에서는 제외했다.

추론 맥락은 배제했다(Reasoning context ignored per M1 Context Isolation). 호출자의 요약과 `progress.md` §E.1 실측 표는 증거로 쓰지 않고 SPEC 다섯 파일과 코드만 읽었다. 워크트리 `.claude/worktrees/t43`, HEAD `13ff5fb`, `git diff --stat b59fcaa HEAD -- Shared Tools` 출력 없음(코드는 기준과 같다). 1~3회차 보고서는 해소 대조에만 썼다. 결함 주장은 실행으로 재현한 것만 차단으로 셌다 — 자정 규칙은 `Store.overlapsDay`·`ScheduledEvent.isListed(on:)`·`listedSpan`·`failedBlockAnchor` 본문을 그대로 옮기고 SPEC의 한계 산식(REQ-006·007·008, plan D-3·D-4)을 구현한 `swift -e` 스크립트로 돌렸다. 프로젝트 설정에 `audit_model`이 없어 교차 모델 감사는 하지 않았다.

## Must-Pass Results

- [PASS] MP-1 REQ 번호: `grep -o '^- \*\*REQ-[0-9]*' spec.md` → REQ-001~014 연속·중복 없음(spec.md:103~145). `grep -c '^## AC-' acceptance.md` = 12, AC-001~012 연속.
- [PASS] MP-2 GEARS(요구사항 층에서만 판정): REQ-001·002·010·011 "When …, the store shall"(spec.md:103·105·133·135), REQ-005·009 "While …"(:111·:127), REQ-003·006·007·012·014 "The … shall (not)"(:107·:117·:119·:139·:145), REQ-004·013 "The … shall"(:109·:143), REQ-008 "For a leg with an owning activity, the effective Δ shall …"(:121 — 한정어가 붙은 Ubiquitous, 1~3회차와 같은 판정). AC의 Given-When-Then은 검증 층이라 여기서 판정하지 않았다.
- [PASS] MP-3 프런트매터: spec.md:2~13 — `id`·`title`·`version: "0.4.0"`·`status: draft`·`created`/`updated: "2026-10-08"`·`author`·`priority: P1`·`phase`·`module`·`lifecycle: spec-anchored`·`tags`(쉼표 문자열). 거부 별칭 없음.
- [N/A] MP-4 언어 중립성: Swift 단일 언어 iOS 앱 SPEC.
- [PASS] MP-5 D7: 본문 참조 `SPEC-UIKIT-009`(12회)·`SPEC-UIKIT-011`(3회) — `grep '^status:'` 둘 다 `completed`. retired/superseded/archived 없음.
- [PASS] MP-6 D8: `grep -c syscall` 다섯 파일 모두 0.
- [FAIL] MP-7 명확화 게이트: 위 원문 결과(의도된 게이트 — 문서 판정 제외).

## Category Scores

| 차원 | 점수 | 띠 | 근거 |
|---|---|---|---|
| Clarity | 0.75 | 0.75 | REQ-008의 "the same requested value"(spec.md:121)가 바뀌지 않는 `finalizeDrag`가 실제로 넘기는 값(드래그에 담긴 유효 Δ, ContentView.swift:780·:783)과 다르게 읽힌다. id가 사라진 반복 구간에서 REQ-005와 REQ-008이 서로 다른 동작을 요구한다(N4-4). HISTORY 0.4.0 줄(spec.md:28)이 가는 편 경고 블록의 동률 처리를 스스로 엇갈리게 적었다(N4-5) |
| Completeness | 0.75 | 0.75 | 절 구성 완비(HISTORY :21, 배경 :44, 요구 :95, 불변 :147, 범위 밖 H3 4개 :161~:176, 결정 :181). 그러나 출발이 남은 경고 블록·깨진 레코드에 대한 REQ-007 적용이 빠져 있어 결함 동작이 된다(N4-1) |
| Testability | 0.75 | 0.75 | 구조 대조가 이제 실제로 돈다(R3-2 해소). AF-018-08~10·23·24 기대값은 실행으로 일치. 다만 S-14는 최소 길이 한계에 먼저 걸려 자정 경계를 관측할 수 없고(N4-2), AF-018-10의 "같은 구간 −15"는 앞 단계를 이어 적용하면 −10이 된다(N4-3) |
| Traceability | 1.0 | 1.0 | REQ 14개 모두 AC 매트릭스(acceptance.md:13~26)에 나온다. AF-018-01~24 24종이 plan.md·acceptance.md 양쪽에 모두 나온다(`grep -o 'AF-018-[0-9][0-9]' … \| sort -u` = 24, 24). 추가 21 → T = B + 21이 spec §0·REQ-013·plan §5·AC-011·progress에서 같다 |

조화평균 4 / (1/0.75 × 3 + 1/1.0) = **0.80**. 3회차 0.71보다 높다(STOP 신호 없음).

## A. 범위 1 — 3회차 차단 결함의 해소 재현

### A-1 R3-1 자정 0시 경계 — **해소(재현)**

`swift -e`로 앱의 나열 판정을 그대로 옮겨(`overlapsDay`: `guard end > start …; return start < d.end && end > d.start` — Store.swift:38-41, `isListed`·`listedSpan`·`failedBlockAnchor` — Models.swift:210-235) SPEC 산식을 돌렸다. 기준일은 `Calendar.current`(Asia/Seoul) 오늘+60일의 하루 시작이다. 실제 출력:

```
== 경계 ==
23:50→00:10: D0,D1
23:40→00:00: D0
23:45→00:05: D0,D1
00:00→00:20: D0
== 작업 예시 ==
AF-018-08 +60 → 35 출발 7일 23:35 도착 7일 23:55
AF-018-09 −30 → -20 출발 7일 00:00 도착 7일 00:20 나열 D0
AF-018-10 +15 → 5 출발 7일 23:55 도착 8일 00:15
AF-018-10 −15 새 픽스처 → -5 출발 7일 23:45 도착 8일 00:05 나열 D0,D1
AF-018-10 −15 연달아 → -10 출발 7일 23:45 도착 8일 00:05
AF-018-10 밤샘 −30 → -30
(0.3.0) −15 → -10 나열 D0
AF-018-23 0.4.0 allSatisfy = true 실패 0 []
AF-018-23 0.3.0 allSatisfy = false 실패 35 ["자정 -180→-10", "자정 -175→-10", "자정 -170→-10", "자정 -165→-10"]
AF-018-24 현재 → 20 출발 7일 23:35 도착 7일 23:55 | 사본 Δ 35 을 현재 구간에 → 출발 7일 23:50 도착 8일 00:10 | 사슬(드래그 값 35 재절단) → 20
== 시뮬레이터 ==
S-6 A=22:55 → Δ 60 7일 23:55
S-6 A=22:52 → Δ 65 7일 23:57
S-6 A=23:3 → Δ 55 7일 23:58
== 무작위 ==
Asia/Seoul 시행 30000 나열 변화 0 방향 반대 0 제외 0
America/New_York 시행 29999 나열 변화 0 방향 반대 0 제외 1
America/Santiago 시행 30000 나열 변화 0 방향 반대 0 제외 0
Europe/London 시행 29999 나열 변화 0 방향 반대 0 제외 1
```

- **경계**: 도착 0시 정각(23:40→00:00)은 D만 나열되고, 00:05면 D·D+1, 출발 0시 정각은 그 날 나열 — REQ-007이 근거로 든 반열린 규약과 같다.
- **작업 예시 손 계산**(분 단위, 엄격 부등식은 1분 안쪽, 0 쪽 5분 내림):
  - AF-018-08: 도착 23:20 + Δ < 24:00 → Δ ≤ 39, 출발 쪽 Δ ≤ 59 → 39 → **35**(도착 23:55). 일치.
  - AF-018-09: 출발 00:20 + Δ ≥ 00:00 → Δ ≥ −20, 도착 쪽 Δ ≥ −39, 가는 편 늘이기라 최소 길이 무관 → **−20**. 일치.
  - AF-018-10: +15 → 출발 쪽 Δ ≤ 9 → **+5**. −15 → 도착 00:10 + Δ > 00:00 → Δ ≥ −9 → **−5**(도착 00:05, 0시 정각이 아님). 밤샘 가는 편(F = L = D) −30 → **−30**. 일치.
  - AF-018-24: 현재 값 23:15→23:35 기준 도착 쪽 Δ ≤ 24 → **+20**(출발 23:35·도착 23:55·활동 끝 23:20, 틈 15 유지). 사본 기준이었다면 35이고 `shiftEvent`가 저장소의 현재 구간을 옮기므로 도착 00:10 — SPEC 서술과 같다.
  - S-6 세 예시, S-13(출발 23:40 + Δ < 24:00 → 19 → **15**, 출발 23:55)도 일치.
- **집합 불변 주장**: spec.md:119의 한 문장 증명은 옳다. 계산된 구간 12만 건 무작위 시행(DST가 있는 뉴욕·산티아고(0시 전환)·런던 포함)에서 나열 집합 변화 0, 끈 방향과 반대인 유효 Δ 0.
- **AF-018-23의 판별력**: 0.4.0 규칙은 격자 전부 통과, 0.3.0 규칙(도착 0시 허용)은 자정 걸친 구간에서 35건 실패 — `isListed(on:)` 기반 훑기가 0시 허용 규칙을 실제로 잡는다.
- **DST**: KST에는 없고, 규칙이 `dateInterval(of: .day)`의 절대 시각으로 정의돼 23·25시간 날에도 성립한다(위 무작위 시행).

남은 문제는 계산된 구간이 아니라 **경고 블록·깨진 레코드**에서 생긴다 → N4-1.

### A-2 R3-2 AC-007 구조 대조 — **해소(재현)**

acceptance.md:145-157의 명령을 그대로(macOS BSD `awk`/`grep`) 돌렸다.

```
$ awk '/func span\(for activity/,/^    }$/' Shared/ContentView.swift | wc -l   → 14
$ awk '/func span\(for event/,/^    }$/' … | wc -l                              → 35
$ awk '/func dragOffsetMinutes\(forEvent/,/^    }$/' … | wc -l                  → 4
$ awk '/func legDragShift|var legDragShift/,/^    }$/' … | wc -l               → 0   (기준에 도우미 없음 — 의도)
$ awk '/onChange: \{ dy in/,/\},/' … | wc -l                                   → 4
$ awk '/onBegin: \{ x, y in/,/\},/' … | wc -l                                  → 5
금지 패턴 계수(문자 그대로의 '<owner>') 여섯 줄                                  → 0 0 0 0 0 0
양성 대조(같은 범위의 아는 토큰): span(for event) 'minutesSinceMidnight' 4 · onBegin 'block(atX' 1 · onChange 'hourHeight' 1 · dragOffset 'activeDrag' 1
$ printf 'func span(for event: X) {\n        let o = store.owningActivity(forLeg: e)\n    }\n' | awk '/func span\(for event/,/^    }$/' | grep -c 'owningActivity'  → 1
같은 입력에서 그 줄을 뺀 것                                                       → 0
옛 꼴(이스케이프 없음) awk '/func span(for event/,…'  → awk: syntax error in regular expression func span(for event at
```

오류 없이 돌고, 범위가 실제로 잘리며, 금지 패턴이 있으면 1·없으면 0을 낸다. 옛 꼴의 오류도 재현했다 — 해소. 다른 "0건/값" G 명령도 같은 방식으로 돌렸다.

| AC | 명령(문서 원문) | 기준 트리 출력 | 문서 기대 |
|---|---|---|---|
| AC-003 | `awk '/func adjustTravelLeg/,…' \| grep -c 'adjustBuffer('` · `git diff --quiet b59fcaa -- Shared/AIAssistant.swift; echo $?` | `1` · `0` | 1 · 0 — 일치 |
| AC-004 | `grep -n 'minActivityMinutes' …` · `grep -c 'minActivityMinutes: CGFloat = 20' Shared/ContentView.swift` | `ContentView.swift:531`·`:555` · `1` | 기준 1(양성) — 일치 |
| AC-006 | `awk '/onChange: \{ dy in/,/\},/' … \| grep -c 'store\.'` · `grep -c 'startOfDay\|dateInterval(of: .day' Shared/ContentView.swift` | `0` · `0` | 기준 0 · 0 — 일치 |
| AC-007 | `dragOffsetMinutes(forEvent` 본문 출력 · 두 `span`의 `legDragShift\|activeDrag` 계수 | 본문 4줄(`return CGFloat(drag.deltaMinutes)`) · `0` · `0` | 일치 |
| AC-008 | `awk '/private func finalizeDrag/,…' \| grep -c 'if e.recurrenceId != nil'` | `1` | 1 — 일치 |
| AC-010 | 범위 `wc -l` · `Task\|await\|try?` · 저장 위치 `grep -n` · `addingTimeInterval(-` · 구글 · 강제 언래핑 · `Task {` | `24` · `0` · `for` `:14`, 닫는 괄호 `:22`, `save()` `:23` · `5` · `0` · `0` · `8` | 일치 |
| AC-011 | 결정성 `grep -c` · `git diff --name-only b59fcaa -- …` · `git status --porcelain -- …` · `ls Shared \| wc -l` | `0`(종료 코드 1 — `grep -c` 0건) · `0` · `0` · `27` | 일치 |

AC-007 둘째 묶음의 `diff <(…) <(…)`는 이 워크트리 가드가 거부해 그대로 돌리지 못했다. 같은 범위를 `git show b59fcaa:… | awk … | shasum`과 작업 트리 `awk … | shasum`으로 비교했다 — `offsetY` `2cd32a58…` = `2cd32a58…`, `finalizeDrag` `3027e8ee…` = `3027e8ee…`(20줄). 범위 추출 자체는 작동한다(N4-7은 명령 형식만의 문제).

### A-3 R3-3 드롭 시점 재읽기 — **해소(재현), 문구 잔여**

- 호출 사슬: `onBegin`이 `ActiveDrag(kind: found, deltaMinutes: 0)`으로 구간 **값**을 담고(ContentView.swift:460), `finalizeDrag`가 그 값 `e`를 `store.adjustTravelLeg(e, byMinutes: drag.deltaMinutes, …)`로 넘긴다(:780·:783). `adjustTravelLeg`의 서명(`_ event: ScheduledEvent, byMinutes:, wholeSeries:`, Store.swift:1387)은 id를 담고 있으므로 본문 첫 줄에서 `events.first { $0.id == event.id }`로 다시 읽고 없으면 `return`하면 된다 — 호출부를 바꾸지 않고 구현할 수 있다. `shiftEvent`도 이미 id로 다시 찾는다(:1440).
- AF-018-24 산술은 위 실행과 손 계산이 일치(+20). 실제 사슬에서는 드래그 값이 사본 기준 유효 Δ(35)이고 이것을 현재 값으로 다시 자르면 역시 20 — 결과는 같다.
- 두 번의 소유 조회가 갈리는 경우 데이터 손상은 없다: 드롭이 현재 값으로 소유와 한계를 다시 구하므로 어느 갈래로 가든 그 갈래의 한계 안에 머문다. 남는 것은 미리보기와 확정이 달라지는 경우뿐이고 plan.md:187에 적혀 있다. 동률 판정의 비교값(가는 편 도착, 오는 편 출발)은 재추정이 바꾸지 않는 쪽이라(도착 기준 재추정은 출발을, 출발 기준 재추정은 도착을 바꾼다 — Store.swift:1316-1330) 재추정만으로 소유가 바뀌지는 않는다.
- 문구 잔여는 N4-4.

## B. 범위 2 — 게이트 D-4 문구

- plan.md:62 원문의 예 ①: "23:00에 끝나는 활동 + 귀가 40분(도착 23:40) → 최대 +15(도착 23:55)". 손 계산: 출발 23:00 + Δ < 24:00 → Δ ≤ 59, 도착 23:40 + Δ < 24:00 → Δ ≤ 19 → 0 쪽 5분 내림 **15** — 맞다.
- 예 ②: "23:50→00:10 구간은 되돌리는 쪽도 −5까지만" — A-1 실행 결과 −5와 일치. 이미 넘은 구간의 되돌리기도 묶인다는 사실을 운영자가 읽을 수 있다.
- "같은 날 추정(`Store.swift:1430`)은 반복 추정 구간에만 해당하고 명시 연결 구간에는 해당하지 않는다 — 명시 구간까지 막는 근거는 … 나열 판정"이 게이트 본문(plan.md:62)·§9 ②(:223)·research.md:98·spec.md:80에 모두 있다.
- 세 안: (a) 막기(권장) · (b) 넘기기 허용 · (c) 반복 추정 구간만 막기(비용: 규칙 둘). 잘 정의돼 있고, (a)는 나열 집합 불변이 증명·실행으로 확인된 단일 규칙이라 권장값으로 방어할 만하다.
- 손질 거리(N4-6, 판정 제외): 예 ③ "그 밖의 시간대는 제한이 없다"는 정확하지 않다 — 이른 새벽 가는 편도 묶인다(AF-018-09: −30 요청이 −20에서 멈춘다, 위 실행). (b)안은 고르면 무엇이 생기는지(끄는 화면에서 블록이 사라지거나 하루 전체 높이로 그려짐 — 2회차 N-1, 반복 추정 구간의 연결 상실)를 적지 않아 (a)·(c)와 설명 밀도가 다르다.

## C. 범위 3 — 0.4.0 편집이 들여온 회귀

- **계수**: REQ 14 · AC 12 · AF-018 01~24(plan·acceptance 각 24종) · 추가 21(04~24) · T = B + 21 — 다섯 파일이 서로 맞다. 기존 드라이버의 계수 관례: `drvCheck`은 통과 시 `drvPass += 1`(GuardDriver.swift:34-37), 요약 `drvPass/(drvPass+drvFail)`(:5360), 종료 코드는 실패 수로만(:306). AF-019-01은 `if/else` 두 갈래에 같은 번호의 `drvCheck`이 있어 `grep -c 'drvCheck('`(513)가 실행 수와 다르다 — plan §5가 "513은 하한 근거로 쓰지 않는다"고 한 것과 맞고, 새 단언에 "번호 하나 = 조건 밖 한 번 실행" 규칙을 둔 것도 기존 AF-018-01~03(각각 무조건 한 호출, :3660·:3669·:3678 부근)과 같은 모양이다.
- **바뀐 인용 재측정**: Store.swift `:38`(`static func overlapsDay`)·`:40`(반열린 판정)·`:436`(@MX:WARN)·`:1304`(@MX:DEBT)·`:1409`(`save()`)·`:1430`(같은 날 대조)·`:1534`·`:1538`(알림 id 비움·재배정)·`:1547`(`refreshUpcomingEstimates`), Models.swift `:210`·`:212`·`:219`·`:229`·`:230`·`:235`, ContentView.swift `:458`·`:460`·`:463`·`:465`·`:470`·`:531`·`:540`·`:767`·`:780`·`:783`·`:899`, App.swift `:101`, GuardDriver.swift `:3770`(재추정)·`:3783`(초기화)·`:3806`·`:3809`·`:3812`·`:4274`, EventDetailView.swift `:352` — 모두 서술과 일치.
- **드라이버 작성 가능성**: AF-018 머리(:3637)와 `afInjectedLeg`(:3806)는 같은 함수 범위다(:3600~:3830 사이에 4칸 들여쓰기 닫는 줄 없음 — `awk` 실측). `afInjectedLeg`는 출발이 있으면 `travelSeconds = 1200`(:3812)이고 SPEC의 새 픽스처는 전부 20분 구간이라 맞는다. AF-018 절과 저장소 초기화(:3783) 사이에 저장소 전체를 훑는 단언이 없다(`awk 'NR>=3684&&NR<=3783' | grep store\.events…` — 추가·재추정 대상 구간 조회뿐). 기존 AF-018 픽스처 시각 `812_300_000`은 KST로 `2026-09-28 23:53:20`이라 AF-018-01 뒤 가는 편이 자정을 걸친다(23:33:20→00:23:20). 고쳐 쓴 AF-018-03의 +15는 새 출발 쪽 상한 25분 안이라 그대로 통과한다(실행: 상한 25, 하한 −22).
- **네트워크·벽시계**: 새 픽스처는 오늘+60일이고 `refreshUpcomingEstimates`는 120분 안만 본다(Store.swift:1547-1549) — 간섭 없음. 시각 비교는 같은 날 안의 상대값이다.
- **5분 단위 단일 상수(계약 5)**: REQ-008(spec.md:121)·plan §3·D-5가 "Store 상수 하나를 제스처 반올림과 한계 함수가 읽는다"로 일치. 제스처 반올림은 `onChange` 클로저(본문 = 메인 액터) 안이라 메인 액터 Store의 정적 상수를 읽어도 격리 문제가 없다. 다만 이것을 확인하는 G 대조는 없다(선택 사항).
- **소유 조회 두 번(onBegin·드롭)**: A-3대로 데이터 손상 경로 없음.
- 새로 찾은 회귀·누락은 아래 N4-1~N4-7.

## D. 범위 4 — 3회차 경미 항목

- R3-4: HISTORY 0.3.0 ④(spec.md:27)는 이제 "출발 없는 경고 블록 오는 편은 동률 비교에서 제외"로 REQ-004(:109)와 같고, 비대칭은 plan.md:187에 적혔다 — 해소. 다만 0.4.0 줄(spec.md:28)이 새 혼선을 들였다(N4-5).
- R3-5: plan.md:134~136·:149·:150과 acceptance.md:95가 AF-018-08~10·23·24를 모두 `afInjectedLeg(linked: <활동 id>, recurrence: nil)` 명시 연결로, 활동 시각(08 22:00–23:00, 09 00:40–03:40, 10 20:50–23:50·밤샘 22:00–06:00, 23 3시간 이상, 24 22:00–23:00)으로 적었다 — 해소(acceptance.md:100의 AF-018-09는 "00:40 시작"만 적어 plan보다 덜 구체적이지만 산술에 영향 없음).

## 3회차 결함 해소 대조

| 결함 | 판정 | 근거(이번 회차 실행) |
|---|---|---|
| R3-1 0시 경계 | **해소** | A-1 — 예시 전부 일치, 0.4.0 격자 통과·0.3.0 격자 35건 실패, 무작위 12만 건 나열 변화 0 |
| R3-2 헛도는 awk | **해소** | A-2 — 원문 명령 무오류, 범위 14·35·4·0·4·5, 양성 1·음성 0, 옛 꼴 오류 재현 |
| R3-3 드롭 사본 | **해소(문구 잔여 N4-4)** | A-3 — 호출부 무변경으로 구현 가능, AF-018-24 +20 일치 |
| R3-4 출발 없는 동률 | 해소(새 혼선 N4-5) | spec.md:27·:109, plan.md:187 |
| R3-5 픽스처 연결 | 해소 | plan.md:134~136·:149·:150, acceptance.md:95 |
| R3-6 5분 상수 | 해소 | spec.md:121, plan.md:69·:108 |
| R3-7 시뮬레이터 | 부분 해소 | S-11·S-6 전제 해소(acceptance.md:233·:238). 새 S-14가 자정 경계를 관측하지 못한다(N4-2) |
| R3-8 명령 위생 | 해소 | acceptance.md:191(`mkdir -p`)·:214(작업 트리 대 기준 + `git status --porcelain`) |
| R3-9 낡은 상태 줄 | 해소 | progress.md:13(0.4.0), spec.md:200(review-1·2·3) |
| R3-10 픽스처 시각 | 해소 | plan.md:121 |
| G-1 게이트 설명 | 해소(문구 손질 N4-6) | B절 — 예 ①② 산술 일치, 반복 추정 한정 근거, 셋째 안 |

같은 결함이 회차를 넘어 그대로 남은 정체는 없다.

## Defects Found

N4-1. FAILED-BLOCK-OPPOSITE-DRAG — spec.md:119(REQ-007 "the new departure (or the anchor time when the departure is missing) … and the new arrival shall be strictly after the start of L and strictly before the end of L"), plan.md:64(D-4 규칙·"끌기 전부터 … 옛 데이터는 조건을 다시 만족하는 쪽으로만 움직인다"), acceptance.md:184(AC-009가 출발 nil 가는 편만 다룸) / `Shared/Models.swift:210-213`·`:229-230`, `Shared/Store.swift:1316-1330`(`applyDepartureAnchoredEstimate`: `travelSeconds = nil`을 먼저 넣고 추정 실패 시 `return` — 출발과 옛 도착이 남는다, 드라이버 AF-010-10-a가 이 모양을 단언) — 출발 기준 오는 편의 재추정이 실패하면 `travelSeconds == nil`·출발 있음·옛 도착이 남는다. 이 구간은 경고 블록이라 앵커(= 출발)의 날 하루에만 나열되므로 F = L = 출발일인데, REQ-007은 나열에 쓰이지 않는 옛 도착에도 "L 끝보다 엄격히 앞"을 요구한다. 옛 도착이 자정을 넘었으면 0이 허용 구간 밖이 되고, 요청 Δ를 그 구간으로 자른 뒤 0 쪽 5분 내림을 하면 **끈 방향과 반대**인 Δ가 나온다. 재현(`swift -e`, 위 산식): 출발 23:50·옛 도착 00:10·`travelSeconds = nil`·활동 3시간 → 요청 +15 → **유효 −10**, +5 → −10, −5 → −10, −30 → −30. 미리보기가 같은 값을 쓰므로 손가락을 내려도 블록이 올라가고, 놓으면 활동 끝이 10분 당겨진다 — 이 블록은 아래로는 결코 끌 수 없고 어떤 끌기든 활동을 줄인다. 같은 구조가 깨진 레코드(`arrivalDate <= departureDate`, `listedSpan == nil` → 도착일 하루 나열, Models.swift:219-221·:234)에서도 생긴다. 0시 정각 도착 옛 데이터는 어김이 1분이라 내림이 0으로 구해 주지만(실행: +30 → 0, −5 → −5), "되돌리는 쪽으로만"은 어김이 5분 이상이면 성립하지 않는다. — Severity: major — Class: blocking — 재현됨 — Required fix: (1) REQ-007·plan D-4에 "경고 블록(`failedBlockAnchor != nil`)과 나열 구간이 없는 레코드는 나열되는 하루 d에 대해 앵커(경고 블록) 또는 도착(깨진 레코드)만 `d.시작 ≤ 새 값 < d.끝`을 지키고 다른 시각은 한계에 쓰지 않는다"를 더한다. (2) 일반 안전 조항으로 "유효 Δ는 요청 Δ와 부호가 반대일 수 없다 — 자른 값의 부호가 다르면 0"을 REQ-008에 더한다(어떤 옛 데이터든 반대 이동을 막는다). (3) AC-009에 출발 있는 출발 기준 경고 블록(출발 23:50·도착 00:10·`travelSeconds = nil`, 명시 연결) +15 → 유효 Δ ≥ 0이고 활동 끝이 당겨지지 않는다는 단언(AF-018-25)을 더하고 T = B + 22로 고친다.

N4-2. S14-MIN-LENGTH-MASK — acceptance.md:241-242(S-13 `자정` 23:20–23:40, S-14 "도착이 모레 0시 정각이 되지 않고 00:05 근처(B에 따라 5분 단위 직전)에서 멈춘다") / spec.md:117(REQ-006) — S-13 뒤 `자정`은 23:20–23:55(35분)이라 S-14의 −30은 최소 길이 한계(Δ ≥ 20 − 35 = −15)에 먼저 걸린다. 재현(같은 스크립트): B = 00:01/00:05/00:10/00:25 → S-14 유효 Δ 모두 **−15**, 도착 00:01/00:05/**00:10**/**00:25** — 도착이 B로 돌아갈 뿐 자정 한계는 한 번도 결정에 쓰이지 않는다. 기대 문구는 B = 00:10·00:25에서 틀리고, 이 단계는 R3-1 회귀를 사람 확인으로 잡겠다는 목적(:242 "사라지면 R3-1 결함")을 이루지 못한다. 활동이 2시간이고 요청이 −30이면 B = 00:10 → −20(도착 00:05), B = 00:25 → −30(도착 00:10)이다. — Severity: minor — Class: optional — 재현됨 — Required fix: S-13의 `자정`을 21:40–23:40(2시간)으로 만들고 S-14를 "1시간 위로 끈다"로 바꾼다. 그러면 유효 Δ = −(B분 + 14)를 0 쪽 5분 내림한 값, 도착은 0시 뒤 1~5분 안에서 멈춘다(B = 00:05 → 00:05, 00:07 → 00:02, 00:25 → 00:05). 기대를 "도착이 모레 00:01~00:05 사이에서 멈추고 블록이 남는다"로 적는다.

N4-3. AF018-10-SEQUENCE — acceptance.md:101, plan.md:136("+15 … && −15 … && 밤샘 …") / acceptance.md:109(AF-018-06~10은 유효 Δ 함수 반환값을 함께 본다) — "같은 구간 · −15"가 +15를 적용한 뒤의 같은 저장 구간을 뜻하면 출발 23:55·도착 00:15에서 시작해 유효 Δ는 **−10**이다(실행: "−15 연달아 → -10", 최종 위치는 23:45·00:05로 같다). 문서 기대 −5는 새 픽스처(23:50→00:10)에서만 맞는다. 반환값 대조를 넣으면 구현이 이어서 적용할 때 단언이 실패한다. — Severity: minor — Class: optional — 재현됨 — Required fix: AF-018-10의 세 하위 사례마다 "새 구간·새 활동으로 다시 만든다"를 적거나, 이어서 적용한다면 −15의 기대를 −10(도착 00:05)으로 고친다.

N4-4. DROP-WORDING — spec.md:121(REQ-008 "apply the store function again to the same requested value", "shall change nothing when the leg id no longer exists"), spec.md:111(REQ-005 "While a dragged leg has no owning activity … apply today's behavior unchanged"), plan.md:69 / `Shared/ContentView.swift:465`·`:780`·`:783`, `Shared/Store.swift:1391-1395` — (a) REQ-008은 제스처가 **유효 Δ**를 드래그 값에 담는다고 하면서 드롭은 "같은 요청 값"을 다시 자른다고 한다. 바뀌지 않는 `finalizeDrag`가 넘기는 값은 `drag.deltaMinutes` = 시작 때 사본으로 자른 유효 Δ다. 원래 요청 값을 쓰려면 `ActiveDrag`·`finalizeDrag`를 바꿔야 해 AC-007의 `finalizeDrag` 본문 불변과 부딪힌다. 결과는 안전하다(실행: AF-018-24에서 요청 60을 자르든 사슬의 35를 자르든 20). (b) id가 사라진 반복 구간을 "전체"로 놓으면 REQ-008은 "아무것도 하지 않는다", REQ-005는 소유 없음이니 "지금 동작" — 지금 코드는 끈 구간 값의 `recurrenceId`·역할 이름으로 다른 회차를 모두 옮긴다(:1391-1395). 두 요구가 다른 결과를 낸다. — Severity: minor — Class: optional — 재현됨(문구 대조·실행) — Required fix: (a) "the drop shall apply the store function to the value it receives (the drag's stored effective Δ) using only the current stored times"로 고친다. (b) "When the dragged leg's id no longer exists in the stored schedule, the drop shall change nothing, with or without an owner"로 REQ-008 앞쪽에 독립 조항으로 두고 REQ-005의 "today's behavior"에서 이 경우를 뺀다.

N4-5. HISTORY-TIE-PHRASE — spec.md:28("출발 없는 경고 블록은 가는 편·오는 편 모두 동률 비교에서 제외한다 — 가는 편은 도착이 있어 늘 비교되고, 오는 편만 출발이 없을 수 있다") vs spec.md:109(REQ-004 "outbound: leg arrival equals activity start; return: … a missing departure never equals") — 앞 절은 가는 편 경고 블록(출발 nil, 도착 있음)도 제외한다고 하고 뒤 절과 REQ-004는 가는 편을 도착으로 늘 비교한다. 한 문장이 스스로 엇갈린다. — Severity: minor — Class: optional — 재현됨(문구 대조) — Required fix: "동률은 가는 편이면 도착, 오는 편이면 출발로 잰다. 출발이 없는 오는 편은 동률이 성립하지 않는다"로 고친다.

N4-7. AC007-PROCESS-SUBST — acceptance.md:135-136 — `diff <(…) <(…)`는 이 워크트리의 가드가 거부한다(이번 회차도 거부됨, progress.md:209도 같은 사실을 적음). run 레인도 같은 가드 아래에서 돈다. — Severity: minor — Class: optional — 재현됨 — Required fix: 두 범위를 `.moai/state/verify/t43/`에 파일로 떨어뜨린 뒤 `diff`하거나 `| shasum` 두 값을 비교하는 꼴로 acceptance.md 명령 자체를 바꾼다(이번 회차 대체 실행: `offsetY` `2cd32a58…` 동일, `finalizeDrag` `3027e8ee…` 동일).

### 게이트 문구(문서 판정 제외)

N4-6. GATE-D4-EXAMPLE-3 — plan.md:62(예 ③ "그 밖의 시간대는 제한이 없다", 안 (b) "넘기기 허용") — 예 ③은 이른 새벽 가는 편의 한계(AF-018-09: −30 → −20, 실행)와 최소 길이 한계를 지운다. (b)는 고르면 생기는 일을 적지 않았다. — Severity: minor(게이트 준비도) — 재현됨(실행·문구) — Required fix: 예 ③을 "자정 앞뒤가 아니면 이 규칙은 걸리지 않는다(새벽 0시 근처 가는 편은 출발이 그 날 0시 앞으로 가지 않는다, 최소 길이 20분은 따로 걸린다)"로, (b)에 "끄는 화면에서 블록이 사라지거나 하루 전체 높이로 그려질 수 있고, 반복 추정 구간은 연결을 잃는다"를 더한다.

### 재현하지 못한 가설(차단 아님)

- H-1 도우미가 한 줄짜리 계산 속성(`private var legDragShift: … { … }`)이면 `awk '/var legDragShift/,/^    }$/'` 범위가 다음 함수의 닫는 줄까지 이어져 금지 패턴 계수가 이웃 함수 본문까지 센다 — 구현 모양에 달려 있어 지금 트리에서 재현할 수 없다. 대조 앞의 범위 `wc -l`을 사람이 읽으면 드러난다.
- H-2 픽스처 시각을 하루 시작에 초를 더해 만들면 DST 지역의 전환일에 벽시계가 어긋난다(뉴욕 2026-03-08 하루 시작 + 23시간 50분 = 03-09 00:50, 실행). 드라이버가 KST 기계에서 돌면 해당 없다 — 실행 환경 시간대를 확인하지 않았다.

## Regression Check

| 이전 결함 | 상태 | 근거 |
|---|---|---|
| R3-1 | RESOLVED | A-1 실행 |
| R3-2 | RESOLVED | A-2 실행 |
| R3-3 | RESOLVED(문구 잔여 N4-4) | A-3 |
| R3-4~R3-6, R3-8~R3-10 | RESOLVED | 위 대조표 |
| R3-7 | 부분(N4-2) | S-14 |
| G-1 | RESOLVED(문구 손질 N4-6) | B절 |
| D-1(MP-7 게이트) | 의도된 게이트 | plan.md:54·62·77·91 |

점수: 0.60 → 0.80 → 0.71 → **0.80**.

## Recommendation

이번이 마지막 회차이므로 판정 근거만 정리한다.

1. **N4-1(차단, major)**: REQ-007·plan D-4에 경고 블록·깨진 레코드의 한계를 "나열되는 하루 안의 앵커(또는 도착)"로 따로 적고, REQ-008에 "유효 Δ는 요청과 부호가 반대일 수 없다"를 더하고, AF-018-25를 추가해 T = B + 22로 고친다. 고치는 범위가 세 문장과 단언 하나라 착수 승인 전에 manager-spec이 반영하고 이 보고서의 N4-1 하나만 델타로 확인하면 된다.
2. 선택: N4-2(S-13·S-14 활동 길이와 끌기 양), N4-3(AF-018-10 하위 사례 초기화), N4-4(REQ-008 문구·id 소실 조항), N4-5(HISTORY 문장), N4-7(`diff` 명령 꼴).
3. 착수 승인: 게이트 4주제를 AskUserQuestion으로 닫는다(MP-7). D-4는 지금 문구로 물을 수 있고, N4-6의 예 ③·(b) 설명을 손보면 더 정확하다.

N4-1을 빼면 범위 1~3에서 재현된 차단 결함은 없다 — R3-1·R3-2·R3-3의 수정은 실행으로 확인됐다.

## 감사가 관측하지 못한 것

드라이버·iOS 빌드·시뮬레이터를 돌리지 않았다 — 기준 트리의 `498/498`과 AF-018 ✓/✗ 열은 코드 읽기 예상이다. 자정 규칙 재현은 앱 판정 본문을 옮긴 독립 스크립트이고 SPEC 산식은 문서에서 내가 구현한 것이다 — run이 만들 실제 Store 함수와 같다는 보증은 없다(특히 "초는 0 쪽 버림"을 시각에 적용하느냐 차이에 적용하느냐는 문서가 정하지 않았고, 두 해석 모두 한계 안쪽이라 안전함을 산술로만 확인했다). 미리보기의 손 느낌·배치·`span` 안 이동은 화면에서 보지 않았다. 출발 있는 경고 블록 오는 편의 옛 도착이 실제 데이터에서 자정을 얼마나 자주 넘는지(재추정은 출발 120분 안 구간만, 실패는 네트워크 상태에 달림)는 관측하지 않았다. 공유 상수의 메인 액터 격리 경고는 빌드 전 가설로 남는다. AC-007의 `diff <(…)` 원문은 가드 때문에 해시 비교로 대신했다. 드라이버가 도는 기계의 시간대는 확인하지 않았다. Tier M 통과 기준값은 이 워크트리에 규칙 파일이 없어 주 체크아웃의 `.claude/rules/moai/workflow/spec-workflow.md:141`에서 읽었다(**0.80**). 점수 0.80은 기준값에 닿지만, 재현된 차단 결함 N4-1이 남아 판정은 FAIL이다.

🗿 MoAI
