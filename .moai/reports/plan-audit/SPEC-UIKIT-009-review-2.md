Model: claude-opus-5-5

# SPEC Review Report: SPEC-UIKIT-009
Iteration: 2/3
Verdict: FAIL
Overall Score: 0.84

> Reasoning context ignored per M1 Context Isolation. 호출자가 넘긴 것은 작업 지시(경로·보고서 위치·재측정 범위)뿐이고 작성자 추론은 없었다. 판정 근거는 SPEC 디렉터리 산출물 일곱 개와 기준 트리 `b2c3987`의 코드·로그를 이 세션이 직접 읽거나 명령으로 잰 결과다.
>
> 입력 계약(Tier L): `spec.md`(228줄) · `plan.md`(303) · `acceptance.md`(457) · `design.md`(216) · `research.md`(125)를 전부 읽었고 `progress.md`(115) 전체와 `spec-compact.md`의 머리·REQ-022/023·AC 표 일부를 대조했다.
>
> 교차 모델 감사: 이 워크트리에는 `.moai/config/`가 없어 주 체크아웃 `/Users/iseongmin/Projects/besir/.moai/config/sections/workflow.yaml:77-82`를 읽었다 — `audit.model: multi`, gates `claude: required · codex: off · glm: advisory`. `mcp__moai__audit_multi`를 이 게이트로 호출한 결과는 `overall_verdict: fail`, GLM은 `inconclusive`("z.ai response carried no content", fail-open)였다. 교차 모델 의견은 사실상 없고 판정은 이 감사자의 것이다.
>
> Tier L 통과선 0.85는 주 체크아웃 `.claude/rules/moai/workflow/spec-workflow.md:142`에서 확인했다(REQ·AC 상한 25·25는 같은 파일 :150).

## Must-Pass Results

- [PASS] MP-1 REQ number consistency: `grep -o '^- \*\*REQ-[0-9]*' spec.md` → `001`~`023`, 빠짐·중복 없음, 세 자리 영채움 일정, `grep -c` = 23. AC는 `grep -o '^## AC-[0-9]*' acceptance.md` → `001`~`024`, 24건. 새 REQ-023(spec.md:L181)이 끝 번호로 붙어 순서가 깨지지 않았다.
- [PASS] MP-2 EARS/GEARS format compliance (판정 계층: **요구사항 계층 `spec.md`의 REQ-XXX만**. `acceptance.md`의 Given/When/Then은 검증 계층이라 여기서 채점하지 않았다): 23건 모두 GEARS 문형이다. 새 REQ-023은 "While a travel leg's travel time has not been computed …, the timetable shall draw that leg as the failed-estimate warning block; … shall read one shared predicate …; and the stored meaning … shall not change"(L181) — State-driven. 고친 이름표: REQ-009 "(Unwanted · Event-driven)"(L125), REQ-010 "(Event-driven)"(L127) — review-1 D12의 "Event-detected"는 사라졌다(`grep -o '^- \*\*REQ-[0-9]* ([^)]*)'`로 23개 이름표 전부 확인).
- [PASS] MP-3 YAML frontmatter validity: spec.md:L2-13에 12필드가 모두 있고 형이 맞다 — `version: "0.1.1"`(따옴표 semver, 0.1.0에서 올라감) · `status: draft` · `created`/`updated: "2026-09-30"` · `priority: P1` · `lifecycle: spec-anchored` · `tags` 쉼표 문자열. 거부 별칭은 없다. 선택 필드 `tier: L`(L14). 이 세션이 돌린 `moai spec lint --strict .moai/specs/SPEC-UIKIT-009/spec.md` → `✓ No findings — all SPEC documents are valid`.
- [N/A] MP-4 Section 22 language neutrality: 단일 언어(Swift, iOS·macOS 앱) SPEC이다.
- [PASS] MP-5 D7 cross-SPEC reconciliation: 일곱 파일에서 뽑은 참조는 SPEC-UIKIT-003·004·005·007·008(자기 자신 009 제외). 다섯 모두 `.moai/specs/<ID>/spec.md`가 있고 `status: completed`다. retired·superseded·archived가 없어 BLOCKING이 없다.
- [PASS] MP-6 D8 cross-platform discipline: `grep -c syscall` → 일곱 파일 모두 0. 자동 통과.
- [PASS] MP-7 clarification gate: `grep -rn 'NEEDS CLARIFICATION' plan.md research.md` → 무출력(exit 1). `grep -rc`로 SPEC 디렉터리 일곱 파일 모두 0. `plan.md` §2는 D-1~D-13 각각에 "해소 (2026-09-30): (x) 채택"(L72·L83·L93·L103·L114·L125·L135·L145·L156·L166·L176·L187·L197)과 D-14(L208)를 적었다. **단서**: 해소 출처가 "칸반 리드 경유 — 이 세션은 운영자의 답을 직접 보지 않았다"(plan.md:L68, progress.md:L7)라 운영자 답의 원문은 이 감사도 관측하지 않았다(Gaps 참고). 기준의 문자 조건(표식 0건)은 충족한다.

## Category Scores (0.0-1.0, rubric-anchored)

| Dimension | Score | Rubric Band | Evidence |
|-----------|-------|-------------|----------|
| Clarity | 0.75 | 0.75 | 대부분 해석이 하나다. 새 문장 좌표 표본 약 60곳을 다시 쟀는데 전부 일치했다(아래 § 재측정 표본). 모호한 곳: AC-015 Given(acceptance.md:L255)이 늦은 회차 L의 날짜·반복을 정하지 않아 (9)의 결과가 테스트 구성에 따라 갈린다(D16). REQ-023의 기하 설명(design.md:L99·L101·L103)이 실패한 오는 편의 모양을 "도착 = 출발"로 하나만 가정한다(D14) |
| Completeness | 1.0 | 1.0 | HISTORY 0.1.0·0.1.1(spec.md:L23-26) · WHY §0-§1 · WHAT §2(모듈 A~F, 새 F가 L174-181) · HOW `design.md` · REQ 23 · AC 24 · `### Out of Scope — …` 6개(L185·L191·L196·L202·L206·L211, 각 `-` 항목 있음) · frontmatter 12필드 · Tier L 산출물 다섯 |
| Testability | 0.75 | 0.75 | 0.1.0의 판단 항목 대부분이 grep 대리 지표나 명시한 갭으로 바뀌었다(AC-001 (3) L61 · AC-005 (3)(4) L117-118 · AC-016 (2) L280 · AC-019 (4)(5) L325-326). 남은 것: AC-010 (4)(L191)는 함의형 단언이라 기준 드라이버 환경(온라인)에서는 늘 ✓이고 재현이 되지 않는다(D15). AC-015 (9)는 L의 날짜에 따라 ✓/✗가 갈릴 수 있다(D16) |
| Traceability | 0.90 | 1.0 | REQ 23건 모두 AC가 있고 없는 REQ를 가리키는 AC가 없다. AC 매트릭스(acceptance.md:L17-42)를 거꾸로 읽은 REQ→AC가 `plan.md` §0(L22)과 23행 모두 같고, §1 카드 표(L33-36)의 AC 항목 열도 매트릭스 "카드" 열과 같다(이 세션이 행마다 대조). 흠 하나: 매트릭스와 §1이 AC-013 "(4)"를 가리키지만 AC-013에는 번호 (4)가 없다(D17) |

집계: 조화평균 4 / (1/0.75 + 1/1.0 + 1/0.75 + 1/0.90) = 4 / 4.778 ≈ **0.84**. Tier L 통과선 0.85에 못 미친다. 1회차 0.73에서 올랐으므로 점수 후퇴(STOP) 조건은 아니다. blocking 결함 넷(D14~D17)도 남아 있어 점수와 별개로 FAIL이다.

## Defects Found (structured defect-list)

번호는 review-1(D1~D13)에 이어 붙였다. D11은 review-1에서 넘어온 optional 항목이다.

D14. REQ023-STALE-SHAPE — spec.md:L181(REQ-023) · design.md:L99(§4 표 "오는 편 … 활동 끝 — `addEvent`가 받은 값 그대로") · L101(":89 … 실패한 오는 편은 도착 = 출발이라 … 도착일에만 나열 — 바꿀 필요 없음") · L103("오는 편은 활동 끝에서 아래로 자란다") · acceptance.md:L185(AC-010 Given의 실패 모양 둘) — REQ-023의 설계는 실패한 오는 편의 모양을 "`departureDate == arrivalDate` == 활동 끝, `travelSeconds` nil" 하나로 본다. 이 모양은 새로 만들 때(`addEvent` :587·:601, `updateEvent` :962·:976)만 맞다. **재추정 실패**는 다른 모양을 남긴다: `refreshUpcomingEstimates`(앱이 포어그라운드로 올 때마다 부른다 — `App.swift:25`·`:101`)가 출발 기준 구간을 `applyDepartureAnchoredEstimate(to:departureDate: dep)`로 다시 부르고(`Store.swift:1263-1264`), 거기서 추정이 실패하면 `travelSeconds = nil`(:1024)·`departureDate = dep`(:1025)만 대입되고 guard(:1031)에서 빠져 `arrivalDate`는 **옛 값(dep + 옛 이동시간)** 으로 남는다. 반복 통근 구간은 캐시 추정으로 만들어졌다가 이 경로로 다시 계산되므로(`Store.swift:650` 주석) 흔히 닿는 경로다. REQ-023 뒤 이 구간은 판정이 참이 되어 실패 분기로 그려지는데, 실패 분기는 `arrivalDate`에서 아래로 21.4분을 그리고 날짜로 자르지 않는다(`ContentView.swift:558-561`, 주석 "실패 블록은 도착일에만 나열되므로"). 그런데 나열은 여전히 `departureDate`로 판단하므로(`:89` `guard let dep = e.departureDate, e.arrivalDate > dep`) `arrivalDate > dep`인 이 구간은 `overlapsDay`로 출발일과 도착일 **둘 다**에 나열된다. 결과: (i) 자정을 넘지 않으면 경고 블록이 활동 끝이 아니라 옛 도착 시각에 떨어져 그려진다. (ii) 23:30 출발 · 00:10 도착처럼 자정을 넘으면 출발일 화면의 00:10 자리(맨 위)에 경고 블록이 하나 더 그려진다. 기준 트리는 이 구간을 일반 블록으로 날짜별로 잘라 그리므로(ii)는 REQ-023이 **새로 만드는 회귀**다. AC-010은 이 모양을 단언하지 않고(L185-196), AC-017 E7(L289·L296)은 실패하지 않은 구간만 다룬다. [증거 수준: 코드 읽기 — 인용한 좌표는 이 세션이 `awk`/`sed`로 확인했다. 드라이버·시뮬레이터로 재현하지 않았다. 새 코드가 아직 없으므로 도구로 확정할 수 없는 설계 결함 가설이다] — Severity: major — Class: blocking — Required fix: (1) REQ-023 근거와 `design.md` §4 표에 셋째 모양("재추정 실패: 출발 기준 · `departureDate` = 원래 출발 · `arrivalDate` = 옛 도착 · `travelSeconds` nil", `Store.swift:1263-1264`·`:1024-1031`)을 더한다. (2) 이 모양을 어디에 그릴지 정한다 — 예를 들어 출발 기준 구간의 실패 블록은 `departureDate`에서 아래로 그리거나, 판정이 참이면 나열(`:89`)도 같은 판정으로 도착일에만 세운다. 어느 쪽이든 나열·기하·히트테스트가 같은 판정을 읽게 한다(계약 5). (3) AC-010에 이 모양의 드라이버 항목(판정 참 · 그려질 자리 또는 나열될 날짜)을 더하고, AC-017에 자정을 넘는 재추정 실패 실례를 하나 더한다. `design.md` L101의 "바꿀 필요 없음"은 이 모양을 넣어 다시 판단한다.

D15. REQ020-UNREACHABLE — spec.md:L168(REQ-020 "… and the record shape of a return leg whose travel time was not computed — shall first be shown by an assertion run on the unmodified code") · acceptance.md:L191(AC-010 (4)) · L339(AC-020 (5) "재현되지 않은 결함(AC-010 (4)의 도달 '아니오' 포함)은 … REQ-023의 수리는 도달하지 못했어도 … 근거다") · L48 — 다섯째 재현은 추정이 실패하는 실행에서만 닿는다. 그런데 기준 드라이버는 온라인 추정을 **전제로 단언한다**: `driver-run.log:150` `✓ S 전제 — 이 환경에서 이동시간 조회가 된다`(`Tools/GuardDriver.swift:991`) · `:211` `✓ J: 등록이 성공하고 이동시간도 계산됐다(전제 — 빨개지면 환경 변화 신호)`(`:1369`). 그러니 게이트를 통과하는 실행(✗ 0, AC-020 (1))에서는 AC-010 (4)가 "실패 분기 도달: 아니오"가 되고, 도달시키려고 오프라인으로 돌리면 S·J 전제가 ✗가 된다. 한 실행에서 둘을 함께 얻을 수 없다. AC-010 (4)는 함의("`travelSeconds == nil`이면 …")라 온라인에서는 늘 ✓로 찍혀 AF 하한 4에 들어가지만 재현을 보이지 않는다. AC-020 (5)는 이를 알고 "재현 안 됨"으로 적고 수리를 코드 읽기와 D-14로 정당화하게 허용하지만, REQ-020의 규범 문장은 무조건 "shall first be shown"이다 — 요구사항과 수락 기준이 서로 어긋난다. — Severity: major — Class: blocking — Required fix: 둘 중 하나를 고른다. (a) REQ-020에서 다섯째 항목을 따로 적는다: "the return-leg failure shape, whose failure branch the online driver environment does not reach (premise assertions S and J), shall be recorded with its reach log; its repair rests on the constructed-record assertion AC-010 (7) and decision D-14". AC-020 (5)와 한 벌로 맞춘다. (b) 결정적으로 닿는 재현 수단을 AC-010 (4)에 적는다(예: 드라이버가 실패 분기를 확실히 타는 입력을 찾아 양성 대조로 확인). (a)가 좁다. L48의 "오프라인에서 실패한다"도 "기준 드라이버는 온라인 추정을 전제한다(S·J)"를 덧붙여 사실대로 쓴다.

D16. AC015-L-DATE — acceptance.md:L255(AC-015 Given "늦은 반복 회차 L(장소 P, 23:00–23:40)") · L266(9) · L268(11) — L의 날짜와 반복 id가 정해지지 않았다. L이 R과 같은 반복 r·같은 날(내일)이면 추정(`Store.swift:1128` 같은 날 + `:1129-1130` 장소 이름)이 R의 가는 편(도착 내일 12:00, 목적지 P)과 오는 편(출발지 P, 도착 13:20)을 L에게도 대응시킨다. `packingGroups`의 반환은 `[이벤트 id: 활동 id]` 사전(design.md:L114)이라 한 구간이 두 활동에 걸리면 나중 쓰기가 이기고, (9) "가는 편·오는 편 둘을 R에 대응"이 반복 순서에 따라 ✗가 될 수 있다. 같은 반복의 두 회차가 한 날에 오는 경우의 규칙도 design.md §5에 없다. — Severity: minor — Class: blocking — Required fix: Given에 L의 날짜(예: 모레)를 적거나 L을 다른 반복으로 둔다. 원한다면 design.md §5에 "추정이 한 구간을 두 활동에 대응시키면 …"(예: 먼저 대응한 것 유지 · 둘 다 낱개)을 한 줄 정한다.

D17. AC013-ITEM4 — acceptance.md:L31(매트릭스 "MB (4)·스크립트") · plan.md:L34(MB "013(4)·스크립트") vs acceptance.md:L233-238(AC-013) — AC-013의 번호 항목은 (1)–(3)뿐이고 grep 항목(L238)은 번호 없는 글머리다. 단일 출처 표가 없는 항목 번호를 가리킨다. — Severity: minor — Class: blocking — Required fix: L238의 grep 항목을 "4. (명령, MB)"로 번호 붙인다.

D18. COMPACT-WORDING — spec-compact.md:L4("권장과 다른 것은 D-8 (b)와 D-14 (b)(REQ-023)") vs spec.md:L217 · plan.md:L68("권장안과 다른 답은 **D-8 (b)** 하나다") — D-14는 권장안이 없던 결정이다. 요약본이 원문과 다르게 말한다. — Severity: minor — Class: optional — Required fix: spec-compact.md:L4를 "권장과 다른 것은 D-8 (b), 새로 더한 결정은 D-14 (b)(REQ-023)"로 고친다.

D19. AC024-REQ-MAP — acceptance.md:L42(AC-024 → REQ-010·015·017·018·023) vs L445(스크립트 20a: 과거 출발 알림 상태 — REQ-008·AC-007 (8)) · L446(스크립트 21: 자정 넘는 오는 편 + 편집이 활동 카드로 — REQ-002·REQ-001) — AC-024가 실행하는 스크립트의 REQ가 매트릭스 행에 다 들어 있지 않다. — Severity: minor — Class: optional — Required fix: AC-024 행의 대응 REQ에 001·002·008을 더하고 `plan.md` §0 REQ→AC에도 024를 붙인다.

D11. REQ-ATOMICITY/HOW (review-1에서 넘어옴) — spec.md:L123(REQ-008) · L153(REQ-016) · L166(REQ-019) — 한 REQ에 독립 `shall` 절 여럿·구현 방식 서술. 오케스트레이터 지시로 채택하지 않았다고 HISTORY 0.1.1(L26)에 적었다. — Severity: minor — Class: optional — Required fix: 없음(오케스트레이터 재량).

## 재측정 표본 (이 세션이 기준 트리 `b2c3987`에서 직접 확인)

- 트리: `git rev-parse --short HEAD` → `b2c3987` · `git branch --show-current` → `WT-edit-card-unify` · `git status --short` → `?? .claude/` · `?? .moai/reports/plan-audit/SPEC-UIKIT-009-review-1.md` · `?? .moai/reports/t17/` · `?? .moai/specs/SPEC-UIKIT-009/` · `git diff --stat b2c3987 -- Shared Tools` → 무출력(코드 변경 없음).
- **새 REQ-023 · 나뉜 REQ-010 근거**(Store `sed -n 994,1036p`): `:999` `travelSeconds = nil` · `:1000` `departureDate = nil` · `:1006` guard · `:1024` `travelSeconds = nil` · `:1025` `departureDate = departureDate` · `:1031` guard · `:1033` 도착 대입. `addEvent` `:584-587` 생성자에 `arrivalDate` · `:601` `(.departure, nil)`이 `departureDate: arrivalDate`로 넘김. `:1252` `guard let dep = e.departureDate` · `:1264` 재추정. ContentView `:511` `if e.departureDate != nil { travelBlockView … } else { failedEstimateBlockView … }` · `:558` `guard let dep = event.departureDate else {` · `:580` 출발 고정 최소 높이 · `:627` `failedEstimateBlockView` · `:89` 나열 guard. AIAssistant `:1846` `created.travelSeconds != nil` · `:2644` `e.departureDate == nil ? " ⚠️이동시간 계산 실패"` · `:2038`. EventDetailView `:204`(둘 다 요구) · `:259` · `:323`. AddEventView `:237` · Google `:172`. **전부 일치.**
- **plan.md §3 포함 관계**: `grep -n 'departureDate = \|travelSeconds = \|departureDate: nil\|travelSeconds: nil' Shared/*.swift` → `departureDate`를 nil로 만드는 곳은 `:1000` 하나, `travelSeconds`를 값으로 채우는 `:1007`·`:1032`·`:1189`·`:1203` 모두 같은 함수에서 `departureDate`도 채운다(`:1013`·`:1025`·`:1192`·`:1204`). 그 밖의 `departureDate` 대입은 `:1142`(shiftEvent)·`:1161`(adjustBuffer, `travelSeconds` guard 뒤)뿐이다. 주장이 참이다.
- **D-8 (b) 조회**: `linkedLegs` `:1118-1132`(명시적 우선 `:1120-1124`, 추정 `:1126-1130`, 같은 날 `:1128`), 호출 `moveActivity` `:1075`, `moveActivity(_:byMinutes:wholeSeries:)` `:1065`. `deleteActivity` 주석 `:368-370`("반복 일정이 만든 구간은 … 반복 전체 삭제로 처리"). Models `:186-190`(`:189`가 `Store.linkedLegs`를 가리킴) · `:199` `anchor`.
- **REQ-011 범위(D13)**: `:628` `func addRecurringEvents` · `:695` `}` · `:698` `func recurringSeries` · `grep -n linkedActivityId Shared/Store.swift | awk -F: '$1>=628 && $1<=695' | wc -l` → `0`. spec.md:L129와 research.md:L43이 같은 범위다.
- **AC-018 결정성(D5)**: `addEvent` 시그니처 `:580` `travelSecondsHint` · `:581` `linkedActivityId`. `awk 'NR>=189&&NR<=230' Shared/Store.swift | grep -c travelSecondsHint` → `0`. `addActivityWithTravel`의 오는 편은 `arrivalDate: endDate`·`anchor: .departure`(:222-226). `adjustBuffer` `:1152` guard · `:1158` `clampBuffer(event.bufferMinutes - deltaMinutes)`.
- **AC 기준값(0.1.1 새 대리 지표)**: `e.departureDate != nil` in ContentView **1** · `columnEnds` ContentView **8** / Models **0** · `activity(forLeg:` EventDetailView **0** / ContentView **0** · `AddEventView(editing` in EventDetailView **1** · `linkedActivityId == nil` in ContentView **1** · `딸린 이동` **0** · `store.events.filter { $0.title == event.title }`(-F) **1** · `gap \* CGFloat\|1 / CGFloat(p.columns)` **2** · `ScheduleAnchor` 케이스 줄 `case arrival, departure` **1** · ActivityDetailView `:68` "반복 일정의 한 회차입니다…". SPEC의 기준값과 전부 같다.
- **AC-019 파이프 양성 대조**(이 세션이 macOS grep으로 실행): (3)의 파이프에 `+ .foregroundStyle(.gray)` · 주석 줄 · `Theme.warn` 줄을 넣으면 `1`(심은 한 줄만 잡힘). (4) 보조 신호는 `var travelTimeUnknown: Bool { travelSeconds == nil }`을 잡지 않고 `var foo: Int`만 잡는다(`1`) — 보조 신호가 기본값 있는 비-Optional(`= 0`)을 놓치지만 판정은 (2)가 하므로(L325) 결함으로 세지 않았다.
- **통과 수(D4) 재유도**: AF = 3+7+5+6+2+8+5+5+4+5+3+3+4+3+2 = **65** · AG = 6+3 = **9** · AH = 4+8+2+8+2 = **24** · 합 **98**. 357+65 = **422** · +9 = **431** · +24 = **455**. 0.1.0 대비 +7 = 3+1−2−4+5+4 — 맞다. AC마다 항목을 다시 셌다: AC-005 드라이버 (1)(2) · AC-006 드라이버 (4)–(8)·(10) = 6, 명령 (1)(2)(3)(9) · AC-010 MA (1)–(4) · MC (5)–(8), 명령 (9) · AC-015 MC (1)–(7)·(13) = 8, MA (9)–(12) = 4, 명령 (8) · AC-016 드라이버 (3)(4), 명령 (1)(2)(5) · AC-019 드라이버 (2), 명령 (1)(3)(4), 갭 (5). 머리 문장의 하한과 모두 같다.
- **기준선 로그**(`.moai/state/verify/t17-plan/`): `grep -c '^  ✓ '` = 357 · `✗` = 0 · `tail -3` = `357/357 통과` / `[실제 데이터] 대조 통과 — …` / `run_exit=0` · `^SwiftCompile` 42/38 · 툴체인 안내를 뺀 `warning:` 0 · driver-compile `warning:` 24. 기존 라벨 접두는 AA·AB·AC·AD·AE·C·D·E·F·J·K·L·M·N·O·P·S·W·X이고 AF·AG·AH는 0건이라 충돌하지 않는다. **새로 본 것**: `:150` S 전제·`:211` J 전제가 온라인 추정을 요구한다(D15의 근거).
- 그 밖: Store `:38` `static func overlapsDay` · `:514`/`:517`/`:529` conflicts · `:1279-1281` · `:1303` · GuardDriver `:31-32` ✓/✗ · `:413` `store.events =` · `:481` `store.activities =` · EventDetailView `:75` `navigationTitle` · SettingsView `:78` "일정 모두 삭제". 전부 일치. **어긋난 좌표 0건.**

## Gaps (이 감사가 관측하지 않은 것)

- 드라이버·빌드·시뮬레이터를 실행하지 않았다. 기준선은 오케스트레이터 로그를 이 세션이 다시 센 값이다.
- D14는 코드 읽기에 근거한 가설이다. `refreshUpcomingEstimates` 재추정 실패를 오프라인으로 일으켜 보지 않았다. 새 코드가 아직 없으므로 REQ-023 뒤의 실제 그림도 관측할 수 없다.
- 운영자가 D-1~D-14에 실제로 무엇을 답했는지는 관측하지 않았다 — SPEC이 "칸반 리드 경유, 이 세션은 직접 보지 않았다"고 적은 전달 내용을 받아들였다. 오케스트레이터가 확인할 몫이다.
- `mcp__moai__spec_audit`/`spec_drift`는 부르지 않았다(워크트리 SPEC을 보지 못한다는 기록 — progress.md:L83). 대신 워크트리 CLI 린트를 돌렸다.
- GLM 교차 감사는 `inconclusive`, codex는 설정상 off라 교차 모델 의견은 없다.
- `spec-compact.md`는 머리(L4)·REQ-022/023(L43·L47)·AC 표 일부(L74-80)만 대조했다.

## Regression Check (Iteration 2+ only)

Defects from previous iteration:

- D1 (MP-7 표식 13건): **RESOLVED** — `grep -rn 'NEEDS CLARIFICATION' plan.md research.md` 무출력, 일곱 파일 모두 0건. plan.md §2에 결정마다 해소 줄(L72~L197)과 D-14(L208). 운영자 답 원문은 미관측(Gaps).
- D2 (카드 범위 고정 기준): **RESOLVED** — AC-022 Given(acceptance.md:L357)이 카드 기준 커밋 `<BASE>`를 쓰고 `b2c3987`을 쓰지 않는다고 명시, (1)(2)(3)이 `<BASE>`로 잰다(L360-362). plan.md §5(L255·L265), REQ-022(spec.md:L172 "both measured against that card's own base commit"), progress.md §E.2 카드별 칸(L103-107). `<BASE>` 부재는 갭으로 판정(L363).
- D3 (스크립트 20 기대가 코드 경로와 반대): **RESOLVED — 운영자 (b), 단 새 결함 D14로 이어짐** — REQ-023 신설(L181), REQ-010 근거를 역할별로 나눔(L127, 도착 기준 `:1000`/`:1006`, 출발 기준 `:1025`/`:1031`), 경계표 두 행(acceptance.md:L389-390), 스크립트 13a는 가는 편·MB 뒤(L434), 스크립트 20은 오는 편·"MC 뒤에만 참"(L444). 새로 만들 때의 모양에 대해서는 맞다. 재추정 실패 모양이 빠졌다(D14).
- D4 (통과 수 산술): **RESOLVED** — 위 § 재측정에서 65/9/24/98 · 422/431/455를 다시 유도했고 AC마다 드라이버·명령·갭을 가른 머리 문장이 항목 수와 같다. § 통과 수(L405)가 "드라이버 하한만 넣는다"를 규칙으로 적었다.
- D5 (AC-018 비결정성): **RESOLVED** — Given(L305)이 두 구간 모두 `travelSecondsHint: 1800`으로 `addEvent`를 직접 부르고, 기준 트리 `addActivityWithTravel`에 힌트가 없음을 명령(`… | grep -c travelSecondsHint` → 0, 이 세션도 0)으로 적었다. L313이 결정성을 명시.
- D6 (재현 목록 불일치 · C1 절): **RESOLVED** — REQ-020 목록 다섯(L168)과 AC-020 (5) 다섯(L339: AC-004 (1)·(5) · AC-012 (2) · AC-005 (1) · AC-010 (4))이 같다. REQ-003 근거에서 재현 주장을 뺐고(L106) AC-003이 이를 적었다(L92). 배치 절이 "on the behavior-preserving extraction commit (C1)"로 고쳐졌다. 다섯째 항목의 도달성은 새 결함 D15.
- D7 (lane 정의): **RESOLVED** — REQ-015 끝(L151) "the lane is the group's outer column range, and members may subdivide it per REQ-017". E6(design.md:L171 A [0,1] · O1/O2 [0,.5]/[.5,1])·E3b와 문장이 부딪치지 않는다.
- D8 (REQ 절 대응 AC 없음): **RESOLVED** — AC-003 (5) 재추정(L91) · AC-008 캘린더 갭 줄(L166) · AC-011 (4) 안내 문구 대리 지표 + 갭(L210-211) · AC-012 알림·캘린더 갭 줄(L225).
- D9 (plan 표와 AC 매트릭스 어긋남): **RESOLVED — 잔여 하나(D17)** — 매트릭스에 "카드(항목)" 열(L17-42)을 두고 단일 출처로 선언(L15). plan.md §0 REQ→AC(L22)를 매트릭스에서 거꾸로 유도한 값과 23행 모두 대조해 같았고, §1 AC 열(L33-36)도 같다. 접두 규칙을 "더하는 카드"로 정했다(acceptance.md:L9, plan.md:L28). 잔여: AC-013 "(4)" 번호 없음(D17).
- D10 (판단에 기대는 AC): **RESOLVED** — AC-001 (3) grep 둘 + 명시한 갭(L61) · AC-005 (3) grep + (4) 갭(L117-118) · AC-016 (2) `columnEnds` 0/≥1(L280) · AC-019 (4) 판정을 (2)로 옮기고 보조 신호는 기록만(L325) · (5) 갭(L326). 남은 판단 항목은 사람 전용(AC-023·024)이거나 갭으로 분류됐다.
- D11 (REQ 분할·HOW): **OPEN (optional, 채택 안 함)** — HISTORY 0.1.1(L26) "D11(REQ 분할)은 채택하지 않았다(REQ 상한 여유 2를 남긴다)". optional이라 판정에 넣지 않았다.
- D12 ("Event-detected" 이름표): **RESOLVED** — REQ-009 `(Unwanted · Event-driven)`(L125), REQ-010 `(Event-driven)`(L127). 23개 이름표 모두 GEARS 이름이다.
- D13 (반복 경로 범위 두 벌): **RESOLVED** — spec.md:L129와 research.md:L43이 모두 `:628-695`(닫는 괄호 `:695`, 다음 함수 `:698`)이고 이 세션의 측정도 같다(범위 안 `linkedActivityId` 0).

정체 감지: 두 회차에 걸쳐 그대로 남은 blocking 결함은 없다(D11은 optional). 새 blocking 넷(D14~D17)은 모두 0.1.1이 새로 쓴 문장에서 나왔다.

## Recommendation

manager-spec에 보낼 수정 지시(순서대로):

1. **(D14, 가장 무겁다)** REQ-023의 실패 모양에 재추정 실패(`refreshUpcomingEstimates`, `Store.swift:1263-1264` → `:1024-1031`: 출발 유지 · 도착은 옛 값 · `travelSeconds` nil)를 더하고, 그 구간을 그릴 자리와 나열할 날짜를 정한다. 나열(`ContentView.swift:89`)·기하(`:558`)·블록 선택(`:511`)이 같은 판정을 읽는지 REQ-023 문장에 넣는다. `design.md` §4 표·L101·L103을 고치고, AC-010에 이 모양의 드라이버 항목을, AC-017에 자정을 넘는 재추정 실패 실례를 더한다. 통과 수의 AH 합과 MC 바닥(455)을 다시 센다.
2. **(D15)** REQ-020의 다섯째 항목을 "도달 기록 + 구성한 레코드 단언(AC-010 (7)) + D-14"로 따로 적어 AC-020 (5)와 맞춘다. acceptance.md:L48에 기준 드라이버가 온라인 추정을 전제한다는 사실(`driver-run.log:150`·`:211`)을 적는다.
3. **(D16)** AC-015 Given에 L의 날짜(또는 다른 반복)를 적는다.
4. **(D17)** AC-013의 grep 항목에 번호 (4)를 붙인다.
5. D18·D19·D11은 optional이다 — 오케스트레이터가 판단한다.

review-1의 blocking 아홉 건은 모두 닫혔고, 새 문장의 좌표 표본 약 60곳도 어긋남이 0건이었다. 남은 결함은 새로 더한 REQ-023과 그 재현 경로에 몰려 있다. D14를 고치면 REQ-023의 설계가 실제 데이터 모양 셋을 모두 덮게 된다.
