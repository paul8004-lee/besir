# SPEC-UIKIT-007 — progress.md

칸반 카드 t7 · 일정 편집이 저장된 출발지를 덮어쓰는 결함. 2026-09-23 리드 디스패치를 받아 plan 레인이 시작했다.
워크트리는 `.claude/worktrees/t7`(branch `WT-origin-overwrite`, base `73ceb43` = `origin/master`)다.

## §E.1 Plan-phase Audit-Ready Signal

- kickoff_gate: **resolved 2026-09-23** — 운영자가 결정했고 리드가 전했다(기록은 `plan.md` §2): D-1 (a) 한 줄 씨앗 ·
  D-2 (a) 한 자리 두 빌드 · Tier S. O-1은 카드가 아니다(리드 판정, Day 닫기 이월 목록). 이 plan 세션은 운영자의 답을
  직접 보지 않았다. 결정을 반영한 판은 `spec.md` 0.1.1이다.
- (게이트 전 기록) kickoff_gate: pending — 결정 둘(D-1·D-2)과 Tier 확인이 남아 있었고, 이 신호가 여는 다음 단계는
  run 착수가 아니라 착수 승인 게이트였다.
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
| (감사 1회차 반영 때) `grep -B8 'private func confirmedPlace' Shared/AddEventView.swift \| grep -c` `'도달 불가'`·`'편집 씨앗'` · `awk 'NR>=374 && NR<=380' Shared/AddEventView.swift` · `grep -n 'useCurrentLocation' Shared/App.swift` · `grep -n 'AddEventView()' Shared/*.swift` · `git check-ignore -v .moai/reports/plan-audit/SPEC-UIKIT-007-review-1.md` | `1` · `0` / 출발지 검색 기준 `near:` `:378` / `:90` / `ContentView.swift:151` / exit 1(무시 목록 밖 — `.gitignore`에 없어 커밋하면 diff에 잡힌다. 그래서 REQ-007·AC-002가 감사 보고서 경로를 뺀다) | AC-003 · `plan.md` §4 D14 · REQ-004 · AC-002 |

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

### 착수 승인 게이트 — 해소 기록 (2026-09-23)

- **D-1 → (a)** 한 줄 씨앗(`AddEventView.swift:166`에 `chosen: editing?.origin?.name`). REQ-005가 무조건형이 됐다.
- **D-2 → (a)** 한 자리 두 빌드. run이 수정 전에 `dd-a`를 빌드해 두고, 수정을 쓴 뒤 `dd`를 빌드한다. 운영자는 한 번
  앉아 `dd-a`로 AC-010·AC-009·파트 A를, `dd`로 파트 B를 돈다. 파트 A가 (다)면 수정 커밋을 되돌리고 멈춘다(REQ-008).
- **Tier S** 확정.
- 결정한 사람은 운영자이고, 리드가 plan 레인에 전했다. 컴패니언 레인은 운영자에게 직접 묻지 않았다.
  세 게이트 표식은 `plan.md` §2에서 걷었다.

### 카드 밖 발견 — 리드가 카드로 올릴지 정할 것

1. **O-1** — `Store.modifyEvent`가 nil 출발지를 목적지로 채운다(`Store.swift:345`, 코드 읽기 가설, 미관측). AI 편집으로
   0분 이동이 생길 수 있다. 같은 부류("사용자가 안 고른 값으로 저장")다. **리드 판정(2026-09-23): 카드 아님, Day 닫기
   이월 목록에 기록.**
2. 카드 본문의 "이번 Day 회귀 아님" 정정(위 절).
3. "현재 위치"라는 이름으로 저장된 출발지는 수리 뒤 옵션 칩과 같은 글자의 직접입력 칩으로 보인다 — 데이터는 맞다.

### 잔여 위험

- **파트 A가 (다)로 나올 가능성.** 결함은 코드 읽기로만 확정했다. 그 경우 수정을 되돌리고 멈춘다(REQ-008).
- **주석이 여섯 줄을 넘으면** 루트 `plan.md` 후속 14·17의 인용이 밀린다 — sync가 본문 바이트로 대조한다(AC-008).
- **스크립트의 ±2분 허용치**는 경로 조회 결과가 호출마다 조금 다를 수 있다는 가정이다. 실측한 값이 아니다.
- **한 자리의 순서는 `spec.md` §3.2 "함께 돌리기" 네 단계가 기준이다**(0.1.2). 위 해소 기록의 한 줄 요약에는 `dd`로 옮긴
  AC-009 보류 판정(5·6·8·10 이동 구간 출발지·11번)이 빠져 있다.
- **편집 시트의 출발지 칩은 이름만 보인다**(`EditCard.swift:181` — `.place`의 칩 글자는 값 그대로, 주소 없음). 그래서
  SPEC-UIKIT-005 AC-009 5번의 "주소까지 서로 다른 두 스타벅스"는 `dd`의 시트로도 이름까지만 가려진다 — 카카오 후보
  이름에 지점명이 들어 있으면 그것으로, 없으면 상세 화면 지도(`RouteMapView`, 출발점 = 저장된 출발지 좌표)로 가린다.
  AC-009 스크립트 쪽 전제라 이 카드에서 고치지 않고 리드에게 넘긴다(오케스트레이터 코드 읽기, 미관측).

## §E.2 Run-phase Evidence

### M1 — 수정 전 빌드(`dd-a`)

- **주장**: 파트 A 빌드는 `Shared/`·`project.yml`이 `73ceb43`과 같은 트리에서, `Shared/`를 고치기 **전에** 만들었다.
- **증거(이 run 레인이 직접 관측, 2026-09-23)**:
  - `git rev-parse --short HEAD` → `66f04e6` · `git branch --show-current` → `WT-origin-overwrite` ·
    `git log --oneline 73ceb43..HEAD` → `66f04e6`, `8cbb499`(둘 다 SPEC 문서 커밋)
  - `git diff --quiet 73ceb43 -- Shared/ project.yml` → exit **0**
  - 기준선 재확인: `wc -l Shared/AddEventView.swift` → **645** · `grep -c 'chosen: editing?.origin?.name'` → **0** ·
    `grep -c 'editing?.origin'` → **0**(plan §5 "측정된 기준선"과 일치)
  - 빌드 명령: `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .moai/state/verify/t7/dd-a build > .moai/state/verify/t7/dd-a-ios.log 2>&1`
  - 빌드 결과: exit **0** · 로그 끝 `** BUILD SUCCEEDED **` · `grep -c '^SwiftCompile'` → **42**(전체 컴파일) ·
    `.app` = `.moai/state/verify/t7/dd-a/Build/Products/Debug-iphonesimulator/besir.app`(보관 — 파트 A 설치에 씀)
- **Gaps**: dd-a 빌드의 경고 계수는 세지 않았다(무경고 게이트 AC-004는 수정 트리 `dd`에만 적용).

### M2 — 한 줄 수리 + 주석 재서술

- **주장**: 출발지 줄이 저장된 출발지 이름을 `chosen` 씨앗으로 받고(AC-001), 고친 자리는 둘뿐이며 둘째 진실이 없다(AC-002), `confirmedPlace` 위 주석이 거짓을 말하지 않는다(AC-003). 파일 길이는 645 그대로다(REQ-007).
- **증거(이 run 레인이 직접 관측, 2026-09-23 — 수정 뒤·커밋 전 워킹 트리에서, `git diff` 기준 `73ceb43`)**:
  - `grep -n 'chosen: editing?.origin?.name' Shared/AddEventView.swift` → `166:                  allowsCustom: true, chosen: editing?.origin?.name, busy: location.isLocating),` — 정확히 **1줄**(`:166`)
  - `grep -n '\.init(key: "origin_query"' Shared/AddEventView.swift` → `165:            .init(key: "origin_query", kind: .place, label: "출발지", options: originOptions,` — 165 + 1 = **166**(씨앗은 출발지 줄의 바로 다음 줄)
  - `grep -c 'chosen: editing?.destination.name'` → **1** · `grep -c 'editing?.origin'` → **1**(기준선 0 — REQ-005: 둘째 진실을 안 더했다)
  - `grep -B8 'private func confirmedPlace' Shared/AddEventView.swift`의 출력에서 `grep -c '프리필'` → **1** · `grep -c '도달 불가'` → **0** · `grep -c '편집 씨앗'` → **0**
  - `wc -l Shared/AddEventView.swift` → **645**
  - `git diff -U0 73ceb43 -- Shared/AddEventView.swift | grep '^@@'` → `@@ -166 +166 @@` · `@@ -534,3 +534,3 @@` — 헝크 **2개**, 둘 다 `-166`과 `:531-536` 안쪽(주석 531-533줄은 바이트 동일이라 git가 534-536만 보인다)
  - `git diff --name-only --diff-filter=A 73ceb43 -- Shared/` → 무출력(새 소스 파일 0 → `xcodegen generate` 불필요)
- **Gaps**: AC-002의 `73ceb43 HEAD` 기준 명령은 이 증거가 워킹 트리 기준이라는 점만 다르며, 커밋이 이 내용 그대로를 담으니 M4(run 종료)에서 `HEAD`판으로 재실측한다. 빌드 게이트(AC-004)와 시뮬레이터 양 파트(AC-005~007)는 M3의 몫이다. 주석의 AC-003 기록 항목(code-safety 렌즈 판독)도 M3 렌즈가 채운다.

### M3a — 빌드 게이트(AC-004, 수정 트리 `dd`)

- **주장**: 수정 커밋 `b73013b`의 트리가 iOS·macOS 양쪽에서 전체 컴파일·무경고로 빌드된다(AC-004).
- **증거(이 run 레인이 직접 관측, 2026-09-23, 커밋 `b73013b` 트리)**:
  - iOS: `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .moai/state/verify/t7/dd build > .moai/state/verify/t7/ios.log 2>&1` → exit **0** ·
    `grep -c 'BUILD SUCCEEDED'` → **1** · `grep -c '^SwiftCompile'` → **42** · `grep '^SwiftCompile' … | grep -c 'AddEventView.swift'` → **2**(컴파일+모듈) · `grep 'warning:' … | grep -c '\.swift'` → **0**
  - macOS: `xcodebuild -scheme besir-macOS -derivedDataPath .moai/state/verify/t7/dd build > .moai/state/verify/t7/macos.log 2>&1` → exit **0** ·
    `BUILD SUCCEEDED` **1** · `^SwiftCompile` **38** · `AddEventView.swift` **2** · swift 경고 **0**
  - 프록시: `git diff --quiet 73ceb43 HEAD -- proxy/` → exit **0** — `npm test`는 **돌리지 않았다**(무변경이라 선택 항목).
  - `.app` = `.moai/state/verify/t7/dd/Build/Products/Debug-iphonesimulator/besir.app`(한 자리 3단계 `dd` 덮어 설치에 씀)
- **Gaps**: dd-a(수정 전) 빌드의 경고 계수와 swiftc 진단은 잡지 않았다(AC-004는 수정 트리에만 적용).

### M3b — 렌즈(`ui-design`·`code-safety`) — D14·AC-003 기록 항목 포함

- **주장**: 두 렌즈 모두 이 카드 diff 귀속 결함 **0건**(렌즈를 안 돌린 게 아니라 돌리고 0건), AC-003 기록 항목 충족, D14는 결함이 아닌 허용 가능한 도달 가능성 변화다.
- **증거(두 렌즈 읽기 전용 보고 — run 레인이 위임해 받아 이 자리에 옮겨 적음. 렌즈는 progress.md를 직접 고치지 않았다)**:
  - **code-safety — 지적 0건.** H1(await 재사용): 세 가드(`:424`·`:433`·`:441`)가 전부 같은 `chosen` 진실을 읽고 어느 것도 `editing`을 직접 읽지 않음 — 씨앗이 가드 불일치를 만들 수 없음. 씨앗의 이름(`:166`)과 좌표(`:178`)는 `buildCard()`의 같은 동기 호출에서 함께 쓰임(반쪽 상태 관측 불가). H2(조용한 실패): fire-and-forget `Task` 2곳 무변경, 편집 오픈마다 `:459` 호출은 오히려 하나 감소. H3(외부 한도): `updateEvent` 알림 경로 무변경, `estimateAll` 호출 수 동일, 위치 요청은 편집 오픈 1회→**0회**(저장된 출발지 있는 경우). H4(복제 계산): 진실은 출발지 줄 `chosen` 하나 — `grep -c 'editing?.origin'` = **1** 실측. 간결성 통과(645줄 무변경). 남는 비대칭 하나(`submitCustom`이 이름만 쓰고 좌표를 안 씀)는 이 diff가 만든 경로가 아니고 살아 있는 경로에서 `:433`이 먼저 걸려 `:441`에 닿지 않으며 루트 `plan.md` 후속 14가 다루는 카드 밖 항목 — 기록만 남김.
  - **AC-003 기록 항목: 충족(code-safety 판독).** (1) "출발지 줄의 nil 읽기는 '없는 장소'로 끝나지 않고 **프리필(prefillOrigin)을 여는 신호다**"(`:535-536`) (2) "**fail-closed만 믿다가 저장된 출발지가 현재 위치로 조용히 바뀌었다**(1b98e14)"(`:536`). 옛 주석의 거짓 단언("도달 불가")은 사라지고 참이 된 조건과 "규율이 지킨다"를 함께 적었음(REQ-006 모양).
  - **ui-design — 지적 0건.** Q1(선택 칩): 렌더 경로가 목적지 줄과 완전히 동일(`EditCardView.swift:160-164`·`:122-124`, `EditCard.swift:181`), 첫 프레임부터 씨앗 표시(깜빡임 없음, `:52` `if let card` 이후 렌더), busy 스피너도 없음(`:424` 즉시 반환). 경계: 빈 이름 도달 불가(생성 경로 전부 비지 않음), 긴 이름 칩 오버플로는 **기존 문법·후속 15와 같은 부류**(목적지 줄이 이미 겪는 것 — 새 후속으로 안 올림), 즐겨찾기 라벨 우연 일치는 목적지 줄 규칙과 동일(§3 Out of Scope). Q2("현재 위치" 저장값): 데이터 정상, 두 칩이 글리프·굵기·채움으로 구분, 혼란 인구 좁음 — 후속 카드 불필요. §3.2 7번 실측에서 이 창이 자주 만들어지면 재검토한다는 조건을 Day 닫기 이월 목록에 한 줄 남기라고 권장(리드에게 전달함). Q3(VoiceOver): 칩 `.isSelected` trait(`EditCardView.swift:290`), 줄 컨테이너 라벨 — 목적지 줄과 같은 메커니즘, 갭 없음(실제 발화는 §3.3 실기기 이월).
  - **D14 — 양 렌즈 일치: 결함 아님, 후속 카드 불필요.** 카카오 우선 경로는 `near`를 파라미터로 받지도 않음(`PlaceSearch.swift:23-27` — `query`·`size`뿐), MapKit 폴백은 `near == nil`에 region만 건너뛰고 정상 강등(`:113-120`), 권한 거부 세션은 수정 전에도 같았음(`LocationManager.swift:50-53`). 잔여 위험: (앱 시작 측위 미완료 창)×(MapKit 폴백)×(편집 중 출발지 검색) 교집합의 **정렬 품질 저하**뿐. 목적지 검색 축은 오히려 순개선(편집 중 `originCoord`가 저장 출발지 좌표로 생존, `:541-545`·`:379`).
- **Gaps**: 두 렌즈 모두 코드 읽기 판정(빌드·시뮬레이터 미실행 — AC-004는 M3a가 채웠고 AC-005~007은 운영자 관측 몫). ui-design의 긴 이름 관찰은 후속 15 중복이라 루트 `plan.md`에 새 항목으로 올리지 않았다.

### M3c — 한 자리 시뮬레이터(관측자: 운영자, 2026-09-23) — AC-005·006·007 판정

- **주장**: AC-005 PASS(파트 A 3번 **(가)** — 결함 재현 목격), AC-006 PASS(파트 B 1~5), AC-007 PASS(파트 B 6~8 — 8번 동일 시간 관측을 그대로 기록). 같은 자리에서 SPEC-UIKIT-005 AC-009의 보류 판정과 6번, SPEC-UIKIT-003 AC-010을 돌았다(spec §3.2 "함께 돌리기").
- **증거(관측 주체는 운영자, 리드가 run 레인에 전언 — 이 레인은 직접 관측하지 않았다)**:
  - 파트 A(`dd-a` — 트리가 `73ceb43`과 같다는 것은 M1 증거 `git diff --quiet` exit 0): 3번 **(가)** — 저장된 출발지가 현재 위치 칩으로 바뀌는 치환을 운영자가 목격·확인(기존 설정값→현재 위치). **N₀·X·D·Y 수치는 운영자가 별도 기록하지 않아 판정만 수령했다**(리드 전언 그대로 적는다).
  - 파트 B(`dd` = 수정 커밋 `b73013b`의 빌드): 1~8 전 단계 통과 — 3번 출발지 줄 N₀ 칩·"현재 위치" 칩 미선택·소요시간 유지, 4번 저장 뒤에도 `약 X분`·출발 시각 유지, 5번 권한 "안 함"에서도 출발지 줄 N₀·저장 버튼 켜짐, 6번 새 일정 출발지 6초 안 프리필, 7번 저장된 이름 칩 유지·`약 Z분` 유지(앱 재실행 포함), 8번 "현재 위치" 칩 직접 탭·선택·재계산·취소 작동. **8번의 소요시간은 Z보다 길어지지 않고 동일하게 관측** — 운영자 판단 "강남역→강남역이면 같은 게 정상(7번 일정 생성 시점 위치 가능성)" + 칩 탭·재계산·취소 작동 확인으로 통과 확정(리드 수용). 관측을 받은 그대로 적는다.
  - AC-009 보류 판정(전부 `dd`에서): 5번 출발지 강남점 스타벅스 · 8번 홍대점 · 10번 이동 구간 출발지 홍대점 · 11번 `집` — 전부 통과(편집 시트에 저장된 출발지가 보존돼 보이는 것을 운영자가 확인, 판정마다 "취소"). 이어서 미뤘던 6번(출발지 `집` 교체·저장·소요시간 변화) 통과.
  - AC-010(`dd-a`): 16단계 중 15 통과. 16번 VoiceOver는 시뮬레이터에서 무반응(선택 항목 말기를 켜도) → **실기기 이월**(기존 Day 닫기 이월 항목에 합류 — 리드 관리).
  - **카드 밖 관찰(리드 지시 2026-09-23 — 이 카드 범위로 끌어들이지 않는다, Day 닫기 이월 목록에서 리드 관리)**: AC-009 7·9번 관측 FAIL — 되묻기/`create_activity` 카드에 장소 선택 줄이 나타나지 않고 모델이 텍스트로 재질문한 뒤 재호출로 등록됐다(`isSamePlace` 거절 경위, 운영자 대화 기록 존재). 부속 관찰 U-3(재질문마다 기존 답 재입력 — 카드가 전부 담으면 소멸, 운영자 제안)·U-4("스타벅스 홍대점" 요청이 대학로점으로 등록 — 이름→좌표 첫 결과 무조건 채택, 사후 문구로만 통보). AC-009 13번은 리드 재설명 뒤 "의도하지 않은 변화 없음" 판정.
- **Gaps**: 파트 A·B의 수치(N₀·X·D·Y·Z)는 운영자가 별도 기록하지 않아 이 파일에 값으로 남지 않는다 — AC-005·006의 "값 기록" 요건과의 차이를 그대로 밝힌다(판정 자체는 관측됐고 전달 경로는 리드 전언). 8번 동일 시간의 원인(생성 시점 위치)은 운영자 가설이며 이 카드가 검증하지 않았다.
- **잔여 위험**: §3.3 실기기 전용 셋(편집 뒤 출발 알림 실제 수신·구글 캘린더 항목 잔존·macOS 편집 시트)과 VoiceOver 실기기 발화는 Day 닫기 확인 몫이다.

### M4 — AC-002 HEAD판 재실측 + run 종결

- **주장**: 카드가 base `73ceb43`에서 건드린 경로는 허용 집합 안에만 있다(AC-002).
- **증거(run 종결 커밋 `ce9fa7a`의 HEAD에서 직접 관측, 2026-09-23)**:
  - `git diff --name-only 73ceb43 HEAD -- . ':!.moai/reports/plan-audit'` → `.moai/specs/SPEC-UIKIT-007/plan.md` · `progress.md` · `spec.md` · `Shared/AddEventView.swift` · 루트 `plan.md` — **허용 집합 밖 경로 0**(루트 `plan.md`은 REQ-007의 계획-실제 갱신 허용 대상)
  - `git diff -U0 73ceb43 HEAD -- Shared/AddEventView.swift | grep '^@@'` → 헝크 **2개**(`@@ -166 +166 @@` · `@@ -534,3 +534,3 @@`) — `bootstrap`·`prefillOrigin`·`confirmCurrentLocationAsOrigin`에 닿는 헝크 없음
  - `grep -c 'editing?.origin' Shared/AddEventView.swift` → **1** · `git diff --name-only --diff-filter=A 73ceb43 HEAD -- Shared/` → **무출력**(새 소스 파일 0 → `xcodegen generate` 불필요했음)
  - 루트 `plan.md` 헝크는 **하나**(`@@ -428,6 +428,7 @@` — Phase 1.7 표의 t7 행 삽입) — REQ-007의 이 카드 항목(§Phase 1.7 표의 t7 행)에만 닿는다. 후속 17·14는 무손대(닫기는 sync 몫, AC-008). 새 후속 항목은 없다(렌즈 관찰은 후속 15 중복이거나 카드 밖 — M3b).
  - 이 블록을 담는 커밋은 `progress.md`(허용 집합 내 경로)만 추가로 고치므로 위 경로 집합은 그대로다.
- **Gaps**: `wc -l` = 645·주석 grep 값 등 M2 신호는 커밋 후에도 불변임을 M2·M4 두 차례 측정으로 보였다(위 §M2·§M4). 머지가 없어 기준 `73ceb43`은 그대로 유효하다(AC-002 전제).

## §E.3 Run-phase Audit-Ready Signal

- run_status: **audit-ready**
- run_complete_at: 2026-09-23
- run 커밋: `b73013b`(M2 수리 — `draft → in-progress` 전이) · `8f13265`(M3a 빌드 게이트·M3b 렌즈 증거) · run 종결 커밋(M3c 시뮬레이터 증거·§E.3·루트 `plan.md` t7 행 — 이 파일을 담는 커밋 자체, SHA는 리드 보고와 §E.2 M4에 명시)
- AC 행렬: **AC-001 ✅**(M2 + 이 레인 재실측) · **AC-002 ✅**(M4 HEAD판 재실측 — 허용 집합 밖 경로 0·헝크 2개·`editing?.origin` 1·새 소스 파일 0, `plan.md` 헝크는 t7 표 행 하나) · **AC-003 ✅ + 기록 항목 충족**(M3b code-safety 판독) · **AC-004 ✅**(M3a — iOS·macOS 무경고, 프록시 무변경, `npm test` 미실행 기록) · **AC-005 ✅**(M3c — (가) 재현 목격, 수치 미기록 갭 명시) · **AC-006 ✅**(M3c) · **AC-007 ✅**(M3c — 8번 동일 시간 관측 그대로 기록) · **AC-008 ⬜**(sync 몫 — 후속 17 닫기·줄 수 변화 시 인용 재정렬)
- 리드 보고: run 종결 커밋 뒤 SHA·증거 경로를 전달한다(디스패치 signal: "M3 종료 후 커밋 SHA·증거 경로 보고").

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
    → 출력 없음, exit 1(패턴 문자열은 이 파일에 옮겨 적지 않는다 — 적으면 이 줄이 걸린다) · AC 헤더의 REQ 목록이 `plan.md` §0 매핑과 일치 · 게이트 표식 계수(`grep -c`, 이 줄을 쓰기 전 측정) → plan 3 · spec 0 ·
    progress 0 — **0.1.1 정정**: 이 줄이 패턴 문자열을 담고 있어 커밋된 판(`8cbb499`)을 세면 progress는 1이었다(2회차 N5).
    0.1.1 편집에서 문자열을 빼고 세 파일을 다시 셌고, 값은 plan 0 · spec 0 · progress 0이다(plan의 표식은 게이트 해소로
    걷혔다) · `moai spec lint .moai/specs/SPEC-UIKIT-007/spec.md` → `✓ No findings` · `git diff --quiet 73ceb43 HEAD -- Shared/ proxy/ project.yml`
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

- **3회차(마지막): PASS, 점수 0.90**(2회차 0.89 — 하락 없음). 보고서 `.moai/reports/plan-audit/SPEC-UIKIT-007-review-3.md`.
  적용 대상 must-pass 여섯 모두 PASS(MP-4 N/A) — MP-7은 게이트 해소로 표식 0건(세 파일). D1 해소 · N1·N3·N4·N5 해소 ·
  N2는 권고와 다른 해법(run이 루트 `plan.md`를 고칠 수 있게 — `CLAUDE.md:23` 사용자 지시가 optional 권고보다 앞선다)을
  감사자가 수용했다. 되돌아간 해소 항목 없음, 세 회차 연속 남은 결함 없음. 재시도 루프 종료.
  - **감사 뒤 반영(0.1.2, 재감사 없음 — 문서만, 코드 무변경)**: **R1** — 한 자리 순서가 AC-009의 증거를 지키게 했다
    (`dd-a`에서는 AC-009의 출발지 단계 5·8·10 일부·11과 편집 저장 단계 6을 보류하고, 파트 A 앞 초기화를 건너뛰며,
    `dd` 설치 직후 편집 시트를 열고 "취소"로 보류 판정 → 초기화 → 파트 B). 1번 도착 시각을 내일 오후 7:00으로 옮겨
    AC-009·AC-010 일정과 겹치지 않게 했다. 감사자가 "M3 자리 전 필수"로 지정한 항목이다. **R2** — REQ-007·AC-002의
    "이 카드 항목"을 후속 17 · Phase 1.7 표의 t7 행(추가 대상) · run 중 새로 덧붙이는 후속 항목으로 정의하고, 후속 14는
    카드 밖으로 못박았다(루트 `plan.md` 헝크가 셋 밖에 닿으면 FAIL).
  - 반영 뒤 이 레인의 재측정: 표식 0·0·0 · REQ 8 · AC 8 · `moai spec lint` → `✓ No findings` ·
    `git diff --quiet 73ceb43 -- Shared/ proxy/ project.yml CHECKLIST.md` → exit 0.
  - 교차 모델은 세 회차 모두 GLM 무응답(fail-open)·codex 꺼짐 — Claude 단독 판정이다.

- plan_complete_at: 2026-09-23
- plan_status: audit-ready
