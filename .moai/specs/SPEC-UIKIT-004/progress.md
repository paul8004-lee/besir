# SPEC-UIKIT-004 — progress.md

## §F.1 Plan-phase Record

- **카드**: t4 (UI통일 2b) — 리드 디스패치 2026-09-20 접수(card picked 상태 확인).
- **워크트리**: `.claude/worktrees/t4`, 브랜치 `WT-ui-unify-2b`(EnterWorktree 자동 브랜치
  `worktree-t4`에서 개명 — 칸반 규율의 `WT-` 슬러그 규칙). base = `origin/master`(`9e4a374`,
  t1·t2a 포함 — 추가 머지 불필요, 리드 디스패치 참조 1).
- **SPEC-ID**: `SPEC-UIKIT-004` — 루트 `plan.md:428`이 t3에 `SPEC-UIKIT-003`을 예약해 뒀고
  `plan.md:427` t4 행이 "별도 SPEC — t4 plan에서 확정"이라 했으므로 004를 발급했다
  (SPEC-UIKIT-002 HISTORY 0.1.0의 "SPEC-UIKIT-003 아님" 표기와 정합).
- **Tier**: M — 리드 디스패치 참조 4가 REQ 상한 16(Tier M)을 명시(판정 질문의 skip 조건 —
  사용자 제공 tier).

### 이탈 기록 (프로세스에서 벗어난 것과 그 대체)

1. **Agent 스폰 불가** — 본 plan 세션의 서브에이전트 스폰이 "team file for session-… not
   found" 내부 오류로 전부 실패(2회 재시도 확인). 그 결과:
   - `manager-spec` 위임 대신 **orchestrator-direct 작성**(본 세션이 단일 작성자로 4종+본
     문서를 한 턴에 작성 — 단일 작성자·한 턴 병렬 Write 규칙은 지킴).
   - Phase 7 설계 협의(`ui-design` 전문가)·Phase 11 독립 감사(`plan-auditor`)는 GLM(z.ai)
     백엔드로 대체 수행(아래 협의·감사 기록). codex는 PATH에 없어 불가(codex_task 실측).
   - 감사 문서는 `.moai/reports/plan-audit/` 경로를 그대로 쓴다(리드가 읽는 증거 경로 유지).
2. **칸반 카드 작업자의 게이트 소관** — Tier 판정 질문·Decision Point 1·Phase 15 인간 게이트는
   리드/운영자 소관으로 넘긴다(칸반 디스패치 규율 "No question delegation"). 본 세션은
   audit-ready 신호와 완료 보고로 끝낸다.

### 설계 협의 기록 (D-4 크롬 매핑)

GLM 백그라운드 교차협의(job `job-20260920T054518Z-5c7707a5`) — 측정 사실 전체를 실어 D-4
초안 표 9줄에 대한 이견·누락을 물었다. **결과: 실패**("z.ai request failed: context canceled",
2026-09-20). D-4 표는 각 행이 자체 실측 근거를 가진 채로 확정됐고(spec.md §4 D-4), 시각적
승인 절차는 run M3의 `ui-design` 협의로 이월한다(plan.md §2 하네스 배정).

### 실측 개수 (세는 명령과 함께 — 제도화된 양식)

| 항목 | 명령 | 값 |
|---|---|---|
| REQ | `grep -c '^- \*\*REQ-' spec.md` | **14** |
| AC | `grep -c '^## AC-' acceptance.md` | **9** |
| 매핑(접두 비교) | `grep -rn 'prefix == "arr:"\|prefix == "dep:"\|hasPrefix("arr:")' Shared/*.swift` | 7(전환 5·유지 2) |
| 매핑(기준 삼항) | `grep -rn '? "arr:" : "dep:"' Shared/*.swift` | 3 |
| 화면 포매터 | `grep -c "DateFormatter()" Shared/EventDetailView.swift` | 3 |
| 시스템 보조색 | `grep -c '\.secondary\|\.tertiary' Shared/EventDetailView.swift` | 10 |
| 접근성 | `grep -c 'accessibility\|@ScaledMetric' Shared/EventDetailView.swift` | 0 |
| CHECKLIST 인용 | `grep -c '<파일>.swift:[0-9]' CHECKLIST.md` | EventDetailView 1·EditCard 2·AIAssistant 6·EditCardView 6·AddEventView 0 |

### 감사 (Phase 11 — 독립 채널 전멸 기록과 자체 검증)

**독립 감사 채널 3종이 전부 불능이었다**(2026-09-20, 본 세션):

| 채널 | 시도 | 결과 |
|---|---|---|
| plan-auditor 서브에이전트 | 2회 재시도 | 내부 오류 "team file for session-… not found" — 세션의 서브에이전트 팀 초기화 결함 |
| codex 백엔드 | `codex_task` | "codex binary not found in PATH" |
| GLM 백엔드 | 상담(background)·감사(foreground)·`glm_audit` 3회 | "context canceled" / "response carried no content" / verdict `inconclusive`("fall back to the active auditor") |

그래서 **작성자 자체의 기계적 검증**(독립 아님)만 수행했다 — 결과:
frontmatter 12/12 필드·거부 별칭 0(`sed`+`grep`), REQ 14 = GEARS 라벨 14(Ubiquitous 10·
Unwanted 4), AC 9와 REQ↔AC 매트릭스 전수 커버, 세는 grep 신호 4종의 사전·사후 값 내적 정합
(§1.3 7+3=10곳 → 전환 뒤 2+0), 인용 스팟체크 5건(`EditCardView:63-64`·`ContentView:449`·
`Theme.swift:55`·`EventDetailView:203`·`AddEventView:325-335`) 전부 일치.
보고서: `.moai/reports/plan-audit/SPEC-UIKIT-004-review-1.md` — **SELF-AUDIT 명시 판**.

**재감사 지시**: `/moai run` Phase 1의 Plan Audit Gate가 이 문서를 다시 감사해야 한다
(독립 plan-auditor 또는 가용 백엔드). 본 세션의 "audit-ready"는 *산출물 확정* 신호이지
*독립 승인*이 아니다 — 리드의 run 디스패치가 이 재감사 생략을 승인한 경우에만 건너뛴다.

### 완료 신호

- plan_complete_at: 2026-09-20T05:55:56Z
- plan_status: audit-ready — 단, 위 재감사 지시를 조건으로 한다(독립 감사 불능 특이사항)

🗿 MoAI

---

## §Run-phase Record

card: t4 · worktree `.claude/worktrees/t4` · branch `WT-ui-unify-2b`
plan-phase 커밋: `ab1b090` (SPEC v0.1.0, Tier M, REQ 14 / AC 9)
run-phase 세션: 리드 세션(2026-09-20 리드 디스패치 — t4 plan 세션이 워크트리 반납 후 인계, run은
리드 세션이 직접 수행)
Implementation Kickoff: 운영자 run 진입 승인(2026-09-20, 리드 디스패치로 전달) — 칸반
no-question-delegation 규율(§F.1 이탈 기록 2와 같은 구도). Tier M(운영자 제공)·직렬 모드·PR 없음
(칸반 카드 — master 통합·push는 리드/sync 소관).

### Phase 1 — Plan Audit Gate (2026-09-20)

- audit_verdict: INCONCLUSIVE → 운영자 승인 진행(inconclusive_acknowledged)
- audit_report: .moai/reports/plan-audit/SPEC-UIKIT-004-review-1.md (SELF-AUDIT 판)
- 일일 기록: .moai/reports/plan-audit/SPEC-UIKIT-004-2026-09-20.md — 채널 전멸 경위·대체 증거 사슬
- audit_at: 2026-09-20T06:45:00Z
- plan_artifact_hash: 60afc417e4e99206e31c2265a9d19ad4598aed74d4b31971e47c1254a83f43ca
- 스킵 3조건 불성립(review-1은 SELF-AUDIT). 독립 채널 복구 시 재감사 조건은 유효.

### Phase 4 — Mode Selection

표준(직렬). 소스 5종·단일 도메인(SwiftUI 화면 + 중립 타입), M2→M3→M4 연속 의존이라 병렬 쓰기
에이전트 없음. **이탈: 서브에이전트 스폰 결함(기계 공통, Phase 1 기록)으로 orchestrator-direct
구현** — 검증 렌즈는 살아있는 팀원(SendMessage)으로: T-001·T-002 swift 렌즈(m3-swift-impl 사후
검토), T-003 ui-design(m4-ui-design), T-004 code-safety(m4-code-safety). ai-tooling 미배정 —
AIAssistant 변경은 순수 매핑 치환 2줄(툴 선언·루프 무변경)이라 드라이버+code-safety로 덮는다
(plan §2 배정의 축소 사유). AC-009(시뮬레이터)는 리드 소관(standing 정책 2026-09-18) — run은
기계 게이트까지만(t2a §E.1과 동일 이관).

### Phase 6·7 — 과업 분해·AC 등록

tasks.md(T-001~T-004) 생성, AC-001~009 전부 ⬜로 TaskList 등록. methodology: tdd(quality.yaml) —
본 SPEC은 단언 추가를 금지(REQ-012·AC-004)하므로 드라이버 기존 205 단언이 특성화 네트로 동작,
RED 신규 작성 없음(SPEC 계약이 우선하는 지점을 여기에 기록한다).

## §E.2 Run-phase Evidence

### M2 — BesirTime 확장·N2 매핑 전환 (REQ-001~003·010~012 / AC-002~004 ✅, AC-001 🟡) ✅

구현: orchestrator-direct(스폰 결함, Phase 4 기록). 검증: 드라이버 2회(정예 전후)·swift 실측·grep 신호.

- **정예 0.1.1 경위(AC-003.3 → 해소)**: 세는 grep `func prefix(for:`이 관용 Swift 서명과 공존할 수
  없다(`for`는 키워드 — `prefix(for anchor:)`만 유효). SELF-AUDIT·리드 감사 모두 못 잡은 측정 결함을
  구현 중 포착: 서명은 관용형 유지, 세는 명령을 접두 일치 `func prefix(for`로 정정(spec HISTORY 0.1.1·
  acceptance AC-003.3). `anchor(ofPrefix:`는 단일 이름으로 원 grep 그대로 성립.
- **변경**: `EditCard.swift` +39줄 — `BesirTime.full`("M월 d일 (E) a h시 mm분")·`clock`("a h시 mm분")
  이사(패턴 불변), `anchor(ofPrefix:)`·`prefix(for:)` 신설(몸통 switch — 소유자 자신이 세는 신호를
  깨뜨리지 않는다). N2 전환 8곳 제자리 치환: AddEventView 5줄(:325·:335 직렬화, :476·:531·:554 판정)·
  EditCardView 1줄(:168)·AIAssistant 2줄(:826 직렬화, :885 여유 실림 방지 가드). 옵셔널 지점(:476·:885)은
  flatMap으로 nil≠매칭 의미 보존, :554·:168은 `?? .departure`로 "arr: 외 전부 출발" 삼항 의미 보존,
  :168은 통째 줄이라 parseDatetime을 먼저 거치게 했다(형식 지식의 호출부 유출 방지).
- **Claim**: AC-002·AC-003·AC-004 성립. AC-001은 EC 쪽(포매터 5벌·패턴 바이트 일치)만 성립 — EV의
  `DateFormatter()` 1건 잔여는 M3이 만든다(이사의 나머지 절반).
- **Evidence** (run 세션 직접 실행, 2026-09-20):
  1. 가드 드라이버 신선 컴파일 2회(정예 전후) — 모두 **205/205 통과**, exit=0,
     `Tools/GuardDriver.swift` diff 무변경(단언 추가 0건, REQ-012). 경고는 LocationManager·
     PlaceSearch·DirectionsService의 기존 툴체인 deprecation뿐(본 카드 무관).
  2. 패딩 실측(앱 실제 객체 — `Tools/padmain.swift` @main 스크래치로 드라이버 집합 컴파일 뒤 측정·삭제):
     `full: 9월 17일 (목) 오후 3시 05분` · `clock: 오후 3시 05분` · `when: 9월 17일 (목) 오후 3시 5분` ·
     `compact: 9/17 (목) 오후 3시 05분` · `shortTimeFmt(패턴): 오후 3:05` — AC-002 기대 표와 전건 일치.
  3. 세는 신호: 접두비교 grep **2**(AIAssistant:893 인자키·EditCard 라벨 조립 — 삽입로 :139→:178,
     0.1.1 기록), 삼항 grep **0**, EC `DateFormatter()` **5**·EV **3**(M3 전), EC `stepTime|shortTime`
     **0**, `^import SwiftUI` EC **0**, `func anchor(ofPrefix:` **1**·`func prefix(for` **1**(정정 명령).
  4. `git diff --stat` — 소스 4종(EditCard +39·AddEventView 5줄·EditCardView 1줄·AIAssistant 2줄).
     치환 3파일이 열거 8줄만 담는 것을 줄 수로 확인(REQ-041).
- **Gaps**: 화면 호출부(:179·:201)가 `BesirTime.full`·`clock`을 가리키는 것은 M3이 바꾼 뒤 AC-001.3으로
  닫는다. 화면 표기의 눈 확인은 AC-009(리드).

### M3 — EventDetailView 크롬 패스 (REQ-001 나머지·REQ-020~023 / AC-001 ✅·AC-005 ✅·AC-007 ✅) ✅

구현: orchestrator-direct. 검증: grep 신호 전종 + 최종 트리 양쪽 빌드 무경고.

- **정예 0.1.2 경위(첫 색 실측 2 → 해소)**: 연결선 `.fill(.quaternary)`→`Theme.line` 치환이 첫 패스에
  누락돼 첫 실측이 2로 나왔다 — 자리를 완성해 0으로 닫았고, 남은 1건은 원본부터 있던
  `.reduce(0)`(stepStartTime)의 `\.red` 오탐이라 신호를 `\.red[^u]`로 정정했다(spec HISTORY 0.1.2·
  REQ-021·AC-005.2). review-1이 주석으로 예고했던 오탐이다.
- **변경**(`EventDetailView.swift` 377→390줄):
  - 컨테이너 3곳(REQ-020): 출발 카드·대중교통 여정의 `.thinMaterial`/14 → `Theme.raised`+`Theme.radius`+
    `Theme.line` 스트로크(EditCardView:63-64 문법 그대로, padding 18은 이 화면 값으로 유지), 상세행
    블록을 같은 카드로 신규 감쌈(내용·순서 무변경, D-4 8번).
  - 색 13곳(REQ-021): `.secondary` 9→`Theme.muted`, `.tertiary` 1(ODsay 주의문)→`Theme.faint`,
    `.quaternary` 1(연결선)→`Theme.line`, 출발 숫자 `isPast ? .red : .green`→`Theme.nowLine`/`Theme.travel`,
    구글 등록됨 체크 `.green`→`Theme.travel`. 예외 유지: `.white` 글리프·`Color(hex:)` 노선색·`Theme.bg`.
  - 포매터(REQ-001 뒷절): `fullFmt`·`timeFmt` 블록 삭제, 호출부 `:179`→`BesirTime.full`·`:201`→
    `BesirTime.clock`. `shortTimeFmt`는 주석 그대로 로컬 유지(REQ-002).
  - 접근성 순증(REQ-023): 출발 시각+상태 캡션 `Group`+`.accessibilityElement(children: .combine)`,
    stepRow 헤드라인+예상 시각 `.combine`, 지도 `.accessibilityLabel("\(목적지) 지도")`. 38pt 고정 →
    `@ScaledMetric(relativeTo: .largeTitle)`(D-4 9번).
  - 지도 클립 12 유지 + 유지 사유 주석(D-4 2번).
- **Claim**: AC-001(전 3조건 — EV `DateFormatter()`=1·EC=5·호출부 BesirTime 지목)·AC-005(grep 4종)·
  AC-007(편집 컨트롤 0·시트 위임 무변경) 성립.
- **Evidence** (run 세션 직접 실행, 2026-09-20):
  1. grep: `thinMaterial` **0**, 색 신호 **0**(0.1.2 정정 패턴), 컨테이너 문법 **3**, EV `DateFormatter()`
     **1**·EC **5**, `accessibility|@ScaledMetric` **4**(0에서 순증), `TextField|Stepper|Toggle(|Picker(`
     **0**, `BesirTime.full|clock` 호출부 **2**.
  2. 빌드(최종 트리): iOS `** BUILD SUCCEEDED **` exit=0·macOS 동일 — 비-툴체인 warning **0건**
     (`grep "warning:" | grep -v appintentsmetadataprocessor` 빈 출력). 1차 초록(치환 누락 수정 전) 후
     정옐 0.1.2 수정이 들어가 최종 트리에서 재측정했다. 재측정 첫 회가 exit 66으로 실패한 것은 프록시
     호출의 `cd` 오염으로 `proxy/`에서 빌드가 시작된 것(t2a sync 정정 ②와 같은 함정) — 각 명령이 자기
     `cd`를 스스로 쓰는 형태로 재실행해 초록. 컴파일 오류는 아니었다.
  3. 프록시 `npm test` **7/7**(M3은 프록시 무관 — 게이트만).
- **Gaps**: 카드 질감·대비·큰 글씨 자람·낭독은 화면 증거 영역 — AC-009(리드, 시뮬레이터 스크립트).

### M4 — 대조·게이트·교차검토·검토 (REQ-030·031·040·041 / AC-006~008) 🔵(독립 검토 2인 대기)

#### 교차검토(spec-amender, 문서 렌즈) — CONDITIONAL-PASS → 6건 전부 처리

| # | 발견 | 처리 |
|---|---|---|
| 1 [높음] | REQ-020·D-4 #8 감쌈 범위 `:302-348`이 삭제 단추·다이얼로그까지 삼킴 — AC-006 8·9행 분할이 규범 | **구현 수정 + 정예 0.1.3**: 값 행(+배지)만 카드로, 삭제 단추 카드 밖 복원. 빌드·신호 재측정(아래 표) |
| 2 [높음] | 치환 "7줄"(AC-008 Given·spec-compact) vs 실측 8줄 | 정옐 0.1.3 — 8줄로 정정(실측 diff 5+1+2=8과 일치) |
| 3 [중간] | GLM 협의를 "수행"으로 서술(HISTORY 0.1.0·D-4 제목) vs §F.1 3회 실패 | 정옐 0.1.3 — "시도(전부 실패)"로 정정 |
| 4 [낮음] | AC 매트릭스 AC-005(REQ-022 없음)·AC-009(포괄 채널 미표기) | 정옐 0.1.3 — 표기 정정 |
| 5 [낮음] | REQ-012 Unwanted "shall not" 문면 아님 | 정옐 0.1.3 — "The form and the AI card shall not observably change." |
| 6 [낮음] | anchor(ofPrefix:) 옵셔널 → 치환부 적응 필요 | 구현이 이미 flatMap/?? 형태로 적응(M2 기록) + plan §2에 주의 문단 추가 |

#### AC-006 — 어포던스 11절 대조 (run 세션 직접, 원본 `9e4a374` 전문 대비) — 11/11 PASS

일괄 통과 없음, 절마다 대조. 형태가 바뀌는 것은 SPEC이 승인한 크롬(컨테이너·색·순증)뿐:
1. 내비게이션 제목=`event.title` 무변경 ✅ · 2. 헤더(목적지·주소·도착) 무변경 — 보조색 muted·`BesirTime.full` ✅ ·
3. 지도 280pt·카카오/기본 전환·클립 12 무변경(+유지 사유 주석·a11y 라벨 순증) ✅ ·
4. 출발 카드(수단·약 N분·큰 숫자·isPast 경고·남음+알림 문구) 무변경 — 컨테이너·색·@ScaledMetric·combine 순증 ✅ ·
5. 계산 실패 폴백 무변경 ✅ · 6. 여정(헤더·예상 시각·단계행·ODsay 주의문) 무변경 — 주의문 faint·stepRow combine 순증, 단계 시각 "오후 3:05" shortTimeFmt 그대로 ✅ ·
7. 캘린더 네 갈래 분기·문구·재시도 무변경(색만 :116 travel) ✅ ·
8. 상세행 값 행(+배지) 카드 감쌈(내용 무변경, 0.1.3 수정 후) ✅ ·
9. 삭제 — 단추 카드 **밖** 그대로·다이얼로그 2종 무변경(0.1.3 수정 후) ✅ ·
10. 편집 툴바→시트 `AddEventView(editing:)` 무변경 ✅ · 11. 상대시각 문구 `relativeText` 무변경 ✅.

#### 게이트 (0.1.3 최종 트리 — 삭제 단추 밖 복원 포함)

| 게이트 | 결과 | 관측 |
|---|---|---|
| 가드 드라이버 | ✅ **205/205**, exit=0 | 수정 전 트리(1c64a40)에서 3회째 측정 — detailRows 수정은 `EventDetailView.swift`로 **드라이버 컴파일 집합 밖**(cat·swiftc 인자에 없음)이라 측정 트리 유효성이 최종까지 유지(t2a F1 전례와 같은 귀속 논리). `Tools/GuardDriver.swift` 무변경 |
| iOS 빌드 | ✅ `** BUILD SUCCEEDED **`, exit=0 | 비-툴체인 warning **0건** |
| macOS 빌드 | ✅ `** BUILD SUCCEEDED **`, exit=0 | 비-툴체인 warning **0건** |
| 프록시 npm test | ✅ **7/7**, exit=0 | 본 카드는 프록시 무변경 — Swift와 무관이라 측정 유효 |
| diff 범위 | ✅ 신규 .swift **0건**(`origin/master...HEAD` Shared 필터 빈 출력) — 소스 5종(본체 2+치환 3, 치환 3파일 diff = 열거 8줄), `Tools/` 무변경 | xcodegen 불필요·Team 재선택 없음(REQ-040(d)) |

상시 신호(최종 트리): `thinMaterial` **0** · 색 신호(0.1.2 패턴) **0** · 컨테이너 문법 **3** ·
EV `DateFormatter()` **1**·EC **5** · 매핑 접두비교 **2**·삼항 **0**.

#### 독립 검토 2인 — 429 중단·재요청 (진행 중 🔵)

m4-ui-design(M3 크롬)·m4-code-safety(전체 diff) 첫 요청이 **429(5시간 사용량 한도)**로 중단됐다
(t2a M4가 밟은 것과 같은 함정, 리셋 15:57). 리셋 후 재요청 — 판정은 도착하는 대로 이 문서에
추가하고, 확정 결함이 있으면 수정 배치 후 게이트를 다시 돌린다.

#### AC-007 — 편집 표면 무증가 ✅

`TextField|Stepper|Toggle(|Picker(` EV **0건**, `readOnly|renderMode` EditCardView **0건**,
`.sheet` 제시 `AddEventView(editing: event)` 그대로(:79).

- **Gaps**: AC-009(시뮬레이터·실기기)는 리드 소관 이관 — acceptance의 10항목 스크립트 목록이 곧 인계물.
  검토 2인 판정 대기 중(위).
