# SPEC-UIKIT-007 — progress.md

칸반 카드 t7 · 일정 편집이 저장된 출발지를 덮어쓰는 결함. 2026-09-23 리드 디스패치를 받아 plan 레인이 시작했다.
워크트리는 `.claude/worktrees/t7`(branch `WT-origin-overwrite`, base `73ceb43` = `origin/master`)다.

## §E.1 Plan-phase Audit-Ready Signal

- kickoff_gate: pending — "구현 준비 완료"라는 뜻이 아니다. 결정 둘(D-1·D-2)과 Tier 확인이 남아 있고,
  이 신호가 여는 다음 단계는 run 착수가 아니라 **착수 승인 게이트**다(`plan.md` §2).
- 산출물: `spec.md` · `plan.md` · `progress.md`(이 파일). Tier S라 `acceptance.md`를 두지 않고 AC는 `spec.md` §3.1에 인라인했다.
- 작성 주체: 세 파일 모두 `manager-spec`(서브에이전트)이 썼다. 오케스트레이터가 넘긴 실측 F1~F16을 이 트리에서 다시 쟀다.
  **`Shared/` 아래 변경은 0건이다**(`git diff --quiet 73ceb43 HEAD -- proxy/ Shared/ project.yml` exit 0).
- 신호 줄(`plan_complete_at`·`plan_status`)은 파일 끝, §F.1 감사 자리 뒤에 둔다 — 감사 기록이 그 앞에 쌓인다.

### 관측된 증거 — 이 레인이 `73ceb43`에서 직접 돌린 명령

| 명령 | 관측된 출력 | 쓰인 곳 |
|---|---|---|
| `git rev-parse --short HEAD` · `git branch --show-current` | `73ceb43` · `WT-origin-overwrite` | 기준 트리 |
| `awk 'NR>=138 && NR<=190'` · `'NR>=418 && NR<=475'` · `'NR>=525 && NR<=545'` · `'NR>=565 && NR<=600' Shared/AddEventView.swift` | `:165-166` 출발지 줄에 `chosen:` 없음, `:169` 목적지 줄에 있음 · `:174`·`:177-178` 씨앗 · `:424`·`:433`·`:441` 가드 · `:447-449` 덮어쓰기 · `:465-466` 계산 가드 · `:531-539` 주석과 읽기 · `:573`·`:595` 저장 | spec §1.1·§1.2 (F1~F4) |
| `awk 'NR>=45 && NR<=60' Shared/LocationManager.swift` · `awk 'NR>=225 && NR<=245' Shared/EditCard.swift` | 권한 거부 즉시 반환 `:51-53` · `isReady` `:240` | §1.2의 4 (F5) |
| `grep -n 'updateEvent(' Shared/*.swift` · `awk 'NR>=925 && NR<=970'` · `'NR>=973 && NR<=997' Shared/Store.swift` | 호출부 `AddEventView.swift:595` · `Store.swift:343` / `updateEvent` `:930-970`, 알림 끄기 `:975`, 재예약 `:992-993`, 캘린더 `:963-969` | §1.3·§1.4 (F6·F7) |
| `grep -c 'editing' Shared/AddActivityView.swift` · `awk 'NR>=136 && NR<=146' Shared/ActivityDetailView.swift` · `awk 'NR>=546 && NR<=557' Shared/AIAssistant.swift` | `0` · `:141-144` `chosen:`과 좌표를 함께 심음 · `:550-555` 되묻기 카드 | §1.4 (F8) |
| `git log --format='%h %ad %s' --date=short -- Shared/AddEventView.swift` · `git show d3c9327:…` · `git show 1b98e14:…` | 이력 `d3c9327` → `1b98e14`(t2 M4) → `6032343` → `8158159` → `02481c6`(t6) / `d3c9327` `:73-74`·`:410`·`:425` 출발지 보존 / `1b98e14` `:148-149`·`:159`·`:396`·`:495-496` 결함 | §1.5 (F9) |
| `git worktree list` | 주 체크아웃 `291db49 [master]` | §1.6 가짜 음성 (F10) |
| `awk 'NR>=70 && NR<=82'` · `grep -n '로 약\|출발 시각' Shared/EventDetailView.swift` · `grep -n 'origin?\.name\|origin\.name' Shared/*.swift` | "편집" `:75` → 시트 `:79` · `:190`·`:197` · 상세에 출발지 이름 없음 | §1.6 (F11) |
| `awk 'NR>=165 && NR<=185' Shared/EditCard.swift` | `chosenLabel` `:171-174`, `.place`는 값 그대로 `:181` | §1.6 (F12) |
| `awk 'NR>=55 && NR<=66' CLAUDE.md` | 드라이버 컴파일 집합 `:59-63`에 `AddEventView.swift` 없음 | §0 (F13) |
| `grep -o 'AddEventView[.swift]*:[0-9]' CHECKLIST.md \| wc -l` · `grep -c 'AddEventView' CHECKLIST.md` | `0` · `6` | AC-008 (F14) |
| `awk 'NR>=800 && NR<=820' Shared/Store.swift` · `awk 'NR>=238 && NR<=252' Shared/AddEventView.swift` | `wantsCalendarSync` 판정 `:812` · 캘린더 줄은 `hasGoogleCalendar && autoAddToCalendar`일 때만 `:246` | 스크립트 P3 (F15) |
| `awk 'NR>=328 && NR<=352' Shared/Store.swift` · `Models.swift:155-160` · `GoogleCalendarService.swift:178-188` | `:345` nil 출발지 → 목적지 대체 · `var origin: Place?` `:158` · 좌표 없으면 nil `:181-185` | Out of Scope O-1 (F16) |
| `awk 'NR>=218 && NR<=236' Shared/ContentView.swift` · `awk 'NR>=55 && NR<=72'`·`'NR>=126 && NR<=162' Shared/LocationManager.swift` | "+" 메뉴 `이동 일정 추가` `:228` · 첫 측위 뒤 갱신 정지 `:61`·`:132` · 지명 대체값 `현재 위치` `:157` | 스크립트 1·7·8번 |
| `git check-ignore -v .moai/state/verify/t7/dd/x` | `.gitignore:28:**/.moai/state/` | AC-004 |
| `ID="SPEC-UIKIT-007"; [[ "$ID" =~ ^SPEC(-[A-Z][A-Z0-9]*)+-[0-9]{3}$ ]] && echo PASS` | `PASS` | frontmatter `id` |
| (감사 1회차 반영 때) `grep -B8 'private func confirmedPlace' Shared/AddEventView.swift \| grep -c` `'도달 불가'`·`'편집 씨앗'` · `awk 'NR>=374 && NR<=380' Shared/AddEventView.swift` · `grep -n 'useCurrentLocation' Shared/App.swift` · `grep -n 'AddEventView()' Shared/*.swift` · `git check-ignore -v .moai/reports/plan-audit/SPEC-UIKIT-007-review-1.md` | `1` · `0` / 출발지 검색 기준 `near:` `:378` / `:90` / `ContentView.swift:151` / exit 1(추적 대상 — 그래서 AC-002 범위 대조에서 뺐다) | AC-003 · `plan.md` §4 D14 · REQ-004 · AC-002 |

AC의 변경 전 값은 `plan.md` §5 "측정된 기준선"에 명령과 함께 있다.

### 오케스트레이터 실측·초안과 어긋난 자리

1. **F6의 줄 범위.** 넘겨받은 값은 `Store.swift:929-968`·캘린더 `:961-967`이었다. 실측: `:929`는 문서 주석이고
   함수는 `:930-970`, 캘린더 분기는 `:961-969`(주석 `:961-962`, 옛 항목 삭제 `:965`, 대기열 `:968`)다. 알림을 끄고
   다시 거는 자리는 `updateEvent` 본문이 아니라 `applyEstimate`(`:975`·`:992-993`)다. 결론("출발지 하나가 이동시간·
   출발 시각·알림·캘린더를 함께 바꾼다")은 같다. spec은 실측 값으로 적었다. (F5의 `:51-54`도 가드는 `:51-53`이고
   `:54`는 닫는 괄호다 — 결론 같음.)
2. **스크립트 1번의 메뉴 이름.** 초안의 "+" → "일정 추가"는 실제로 `이동 일정 추가`다(`ContentView.swift:228`). 고쳤다.
3. **스크립트 7·8번 — 위치 캐시.** `LocationManager`는 첫 측위 뒤 갱신을 멈추고(`:61`·`:132`), 칩 탭은 가진 좌표를
   곧장 쓴다(`AddEventView.swift:413-414`). 초안대로 같은 프로세스에서 위치만 바꾸면 8번이 옛 시청 좌표를 써
   `현재 위치(…중구…)`가 되고 소요시간도 그대로다 — 수리와 무관한 실패처럼 보인다. 7번에 앱 재실행을 넣었다.
   또 칩의 지명은 역지오코딩이 끝났을 때만 붙으므로(`:452`) 8번의 기대를 "칩 선택 + 소요시간이 Z보다 길어짐"으로
   바꿨다. **이 판단은 코드 읽기이고 시뮬레이터로 확인하지 않았다.**
4. (어긋남 아님) 수리 모양의 "`:231`"은 `AddEventView.swift:231`(이동 수단 줄, `allowsCustom: false, chosen: mode, busy: estimating`)이다 — 인자 순서의 근거로 맞다.

### 카드 본문 정정 (F9)

카드 t7은 "c5396b3 이전부터 존재(이번 Day 회귀 아님)"라고 적었다. 앞부분은 참이고 뒷부분은 사실이 아니다 —
결함은 `1b98e14`(2026-09-20, 카드 t2 · SPEC-UIKIT-002, Phase 1.7)에서 들어왔고, 그 직전 트리 `d3c9327`은 출발지를
지켰다. 루트 `plan.md:533`의 "t6가 만든 것 아님"은 참이다. 카드 본문 수정은 리드의 몫이다.

### Gaps — plan이 돌리지 않은 것 (증거 없음 ≠ 통과)

- **iOS·macOS 빌드 — 미실행.** plan은 문서만 바꾸므로 오케스트레이터가 작성 서브에이전트에 빌드를 돌리지 말라고 했다
  (리드 디스패치가 금지한 것은 드라이버뿐이다). `73ceb43`의 빌드 기준선은 run이 AC-004로 잰다.
- **프록시 테스트 — 미실행.** `proxy/`는 무변경이다(`git diff --quiet` exit 0).
- **가드 드라이버 — 미실행.** 금지이고, 이 경로에 닿지 않는다(`CLAUDE.md:59-63`).
- **시뮬레이터 — 미실행.** 결함의 존재 자체가 코드 읽기와 이력 대조로만 뒷받침된다. 파트 A가 첫 관측이 된다.
- **macOS 동작 — 미관측.** 같은 SwiftUI 코드이지만 따로 본 적이 없다.
- **nil 출발지 편집·출발 기준 일정·구글 연결 상태의 편집 저장 — 미관측.** 앞의 둘은 코드 읽기로 같은 경로라고 판단했다.
- **칩의 지명 문구(`…중구…`) — 예측.** `LocationManager.swift:154-157`의 조합 규칙에서 추정했다.

### 미해소 결정 — 착수 승인 게이트에 올린다

- D-1 수리 모양(권고 (a) 한 줄 씨앗) · D-2 수정 전 증거의 시점(권고 (a) 한 자리 두 빌드) · Tier S 확인.
  선택지와 사실, 권고 근거는 `plan.md` §2에 있다. 미해소 표식은 `plan.md`에만 두고 이 파일에는 옮겨 적지 않는다.
- 컴패니언 레인은 운영자에게 직접 묻지 않는다. 리드가 게이트에서 제시한다.

### 카드 밖 발견 — 리드가 카드로 올릴지 정할 것

1. **O-1** — `Store.modifyEvent`가 nil 출발지를 목적지로 채운다(`Store.swift:345`, 코드 읽기 가설, 미관측). AI 편집으로
   0분 이동이 생길 수 있다. 같은 부류("사용자가 안 고른 값으로 저장")다.
2. 카드 본문의 "이번 Day 회귀 아님" 정정(위 절).
3. "현재 위치"라는 이름으로 저장된 출발지는 수리 뒤 옵션 칩과 같은 글자의 직접입력 칩으로 보인다 — 데이터는 맞다.

### 잔여 위험

- **파트 A가 (다)로 나올 가능성.** 결함은 코드 읽기로만 확정했다. 그 경우 수정을 되돌리고 멈춘다(REQ-008).
- **주석이 여섯 줄을 넘으면** 루트 `plan.md` 후속 14·17의 인용이 밀린다 — sync가 본문 바이트로 대조한다(AC-008).
- **스크립트의 ±2분 허용치**는 경로 조회 결과가 호출마다 조금 다를 수 있다는 가정이다. 실측한 값이 아니다.

## §E.2 Run-phase Evidence

_<pending run-phase>_

## §E.3 Run-phase Audit-Ready Signal

_<pending run-phase>_

## §E.4 Sync-phase Audit-Ready Signal

_<pending sync-phase>_

## §F Phase 4 Mode Selection

**Mode: serial (sub-agent 순차).** 근거는 셋이다.
- plan 단계는 문서 셋과 실측이라 병렬로 나눌 구간이 없다. 조사 범위는 카드와 후속 17이 이미 지목했다.
- run 단계의 코드 변경은 한 파일 두 자리다. 쓰기 에이전트를 둘 이상 둘 이유가 없다.
- 전문가 배정은 `plan.md` §4 그대로다 — M2 `swift-impl` · M3 `ui-design`·`code-safety`. 파트 A·B는 사람이 돈다.

## §F.1 Phase 11 — 독립 감사

- **1회차: FAIL, 점수 0.79**(조화평균, Tier S 통과선 0.75). 보고서 `.moai/reports/plan-audit/SPEC-UIKIT-007-review-1.md`.
  항목별 점수는 명확성 0.75 · 완전성 0.90 · 검증 가능성 0.70 · 추적성 0.85다. 코드 인용은 전수 대조에서 어긋난 것이 없었다.
  - 필수 기준 FAIL은 둘이다. **MP-1**(REQ 번호 공백 005~009·012~019)은 재번호로 해소했다. **MP-7**(`plan.md` §2의
    게이트 표식 셋)은 작성 결함이 아니라 착수 승인 게이트가 아직 열리지 않았다는 신호라, 의도대로 두고 리드의
    게이트에 넘긴다(D1). MP-2·MP-3·MP-5·MP-6은 PASS, MP-4는 N/A다.
  - **반영(커밋 전, `manager-spec`)**: D2 재번호(옛 번호 10·11·20·21 → 005~008, 약식 표기·대역 서술·매핑표 포함) ·
    D3 REQ-007 run 범위에 이 SPEC 디렉터리, AC-002 첫째 명령을 저장소 전체 대조로 · D4 매핑 002→006·007 ·
    D5 프리필 칩의 두 형태(3·6번, AC-007) · D6 HISTORY 수 · D7 고른 후보의 이름 N₀ · D8 AC-003 기계 신호 ·
    D9 REQ-004 생성 인자 문형 · D11 nil 절반을 AC-001 첫째 grep에 묶음 · D12 (나)의 기록 값과 재시도 1회 · D13 `약 Z분`(±2분).
  - **일부 반영**: D10 — 비규범 꼬리에 "근거:"·"수리 모양(참고):" 표식을 달았고, AC-001의 글자 그대로 식은 D-1 (a)의
    일부로 명시했다. 요구사항 속 함수·변수 이름은 한 줄 수리의 계약이라 남겼다.
  - **유지**: D15 — `module: "shared-ui"`·`related_specs`·`kanban_card`. lint가 통과하고 자매 SPEC(UIKIT-005)이 같은 값을 쓴다.
  - **run에 넘김**: D14 — 편집 중 출발지 검색의 기준 좌표(`AddEventView.swift:378`)가 앱 시작 측위에만 기대게 되는 점.
    `plan.md` §4의 M3 렌즈 입력으로 적었다.
  - **교차 모델**: `audit_multi` overall `needs-attention`. GLM은 응답 본문 없이 `inconclusive`(fail-open), codex는 설정상
    꺼져 있다 — 판정은 Claude 단독이다.
  - **반영 뒤 이 레인의 재측정**: `grep -c '^- \*\*REQ-' spec.md` → `8` · `grep -c '^#### AC-' spec.md` → `8` ·
    감사 보고서 D2의 대상 줄 검색 패턴에 약식 표기(AC-006 헤더의 옛 목록)와 절 제목의 대역 표기를 더해 세 파일에 돌림
    → 출력 없음, exit 1(패턴 문자열은 이 파일에 옮겨 적지 않는다 — 적으면 이 줄이 걸린다) · AC 헤더의 REQ 목록이 `plan.md` §0 매핑과 일치 · 표식 `grep -c 'NEEDS CLARIFICATION'` → plan 3 · spec 0 ·
    progress 0 · `moai spec lint .moai/specs/SPEC-UIKIT-007/spec.md` → `✓ No findings` · `git diff --quiet 73ceb43 HEAD -- Shared/ proxy/ project.yml`
    → exit 0. 2회차 범위는 감사자 권고대로 D1~D6·D13의 델타와 회귀 확인이다. `Shared/`는 무변경이라 코드 인용을 다시 잴 필요가 없다.

- **2회차: FAIL, 점수 0.89**(1회차 0.79에서 상승 — STOP 신호 없음). 보고서 `.moai/reports/plan-audit/SPEC-UIKIT-007-review-2.md`.
  - 남은 필수 기준 FAIL은 **MP-7 하나**다(`plan.md` §2의 게이트 표식 셋). MP-1은 PASS로 돌아섰다. 1회차의 manager-spec 몫
    D2~D6·D13은 전부 해소, D10 일부 반영·D14 run 이관·D15 유지는 감사자가 수용했다.
  - **새 결함 N1~N5는 모두 optional이고, 게이트 결정을 반영하는 편집에서 한꺼번에 고친다**(감사자 권고). N1 — 감사 보고서
    경로 예외가 REQ-007의 비규범 꼬리에만 있다 · N2 — AC-002가 저장소 전체를 대조하므로 run 중 루트 `plan.md` 갱신이
    기계적으로 FAIL이 된다(`CLAUDE.md`의 "그 자리에서 갱신" 지시와 충돌 — "run 중 발견은 `progress.md`에 적고 sync가 옮긴다"
    한 문장이 권고안) · N3 — `73ceb43` 고정 기준이라 카드 브랜치에 병합이 들어오면 거짓 FAIL(가능성 낮음) · N4 — AC-005의
    "Y < X·출발 시각 > D"가 통과 조건인지 기록 값인지 흐리다 · N5 — 위 1회차 기록의 "progress 0"은 이 파일에 패턴 문자열이
    들어가 지금 세면 1이고, 관측 표의 "추적 대상"은 "무시 목록 밖"이 정확하다.
  - **3회차가 마지막이다(상한 3).** 게이트 없이 돌리면 D1이 같은 모양으로 남아 정체 결함이 된다 — 리드의 게이트 결정 뒤에
    결정 반영 + N1~N5를 한 편집으로 하고 그 델타만 3회차로 감사한다. 교차 모델은 두 회차 연속 GLM 무응답(fail-open)·codex 꺼짐
    — Claude 단독 판정이다.

- plan_complete_at: 2026-09-23
- plan_status: audit-ready
