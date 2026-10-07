# t47 sync 판정문 — SPEC-UIKIT-011 장소 채택 항상-선택

판정일 2026-10-07 · sync 레인(`sync`) · 대상 트리 `83ac07f`(브랜치 `WT-always-select`, 코드 마지막 커밋 `61458e1`) · 기준 `d900a78`
**최종 PASS/FAIL은 리드가 이 증거를 읽고 정한다.** 이 레인의 권고는 아래 한 줄이다.

> **권고: PASS — 차단 0. 운영자 결정 1건(Q16 문구, 범위 확대 여부)과 시뮬레이터 S-1~S-12(AC-012·013 🟡)가 남는다.**

## 1. 게이트 — 이 레인이 이번에 직접 돌린 것

| 주장 | 명령 | 관측된 출력(원문 줄) | 로그(`.moai/state/verify/t47-sync/`) |
|---|---|---|---|
| 드라이버 통과 | `cat Shared/EditCard.swift Shared/AIAssistant.swift Tools/GuardDriver.swift > …/gd-sync.swift && swiftc … -parse-as-library && …/gd-sync` (워크트리 CLAUDE.md 레시피, **새 컴파일**) | `compile-exit=0` · `run-exit=0` · `492/492 통과` · `[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다` · ✓ 492 · ✗ 0 | `driver-run.log:577-578` · `driver.exit` |
| 신설 단언이 실제로 돈다 | `grep '✓ AI-1[4-9]\|✓ AI-2[0-2]'` | AI-14·15·16·17·18(a)~(d)·19(a)(b)·20·21(a)(b)·22(a)(b) = 15줄 전부 ✓ | `driver-run.log:555-569` |
| 지운 단언 15건이 없다 | `grep -c '✓ AA-1:'` · `'✓ AB-H04'` · `'✓ AI-6\|✓ AI-9\|…AI-12'` | HEAD `0 · 0 · 0` ↔ 기준 시대 로그(`.moai/reports/t42/gate-sync-driver.log`) `6 · 2 · 7`(양성 대조) | 같은 파일 |
| 런 레인 로그와 일치 | `diff <(✓ 줄 — gate-m8-final.log) <(✓ 줄 — 이번 로그)` | `LABEL-SETS-IDENTICAL` · 런 로그 mtime 21:29:19가 코드 마지막 커밋(`61458e1` 21:26:03) 뒤 | — |
| 코드가 `61458e1` 뒤 안 움직였다 | `git diff --stat 61458e1 HEAD -- Shared Tools proxy project.yml` | 빈 출력(그 뒤 두 커밋은 문서) | — |
| iOS 무경고 | `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .moai/state/verify/t47-sync/dd build` (**새 경로** — 공유 `build/`는 컴파일을 건너뛰어 경고가 안 나온다) | `build-exit=0` · `** BUILD SUCCEEDED **` · `^SwiftCompile` 42 · `AIAssistant.swift` 3회 등장 · `grep 'warning:' | grep -v appintentsmetadataprocessor | sort -u | wc -l` → 0 | `ios-build.log` |
| 드라이버 컴파일 경고 | `grep 'warning:' driver-compile.log \| grep -v deprecated` | 빈 출력 — 전부 MapKit·CLGeocoder 폐기 예고(기존 잡음) | `driver-compile.log` |
| proxy | `npm --prefix proxy test` | `7/7 통과` | — |
| 범위 | `git diff --name-only d900a78 HEAD -- Shared Tools proxy project.yml` | `Shared/AIAssistant.swift` · `Tools/GuardDriver.swift` 정확히 둘 | — |
| 선언 계약 | `git diff -U0 d900a78 HEAD -- Shared/AIAssistant.swift` 헝크 35개 vs 기준 `toolsJSON()` 구간 `:1503-1698` | 그 구간을 지나는 헝크 0(헝크가 `-954`에서 `-1745`로 건너뜀) · `grep -c '"type": "[a-z]'` 0 | `aiassistant.diff` |
| 샌드박스 잔여 | `ls -d $TMPDIR/besir-gd-*` | 없음 | — |

**로그 보존**: 위 로그 원본은 git 무시 경로(`.moai/state/`)라 워크트리 폐기와 함께 사라진다. 추적되는 사본을 `.moai/reports/t47/`에 뒀다 — `gate-sync-driver.log`(=`driver-run.log`) · `gate-sync-ios-build.log`(=`ios-build.log`) · `gate-sync-structural-head.log`·`gate-sync-structural-base.log`(=`g2-head.log`·`g2-base.log`). 이 표의 `driver-run.log:577-578`·`:555-569` 줄 번호는 사본에서도 같다.

변경량(실측): `git diff --shortstat d900a78 HEAD -- Shared/AIAssistant.swift Tools/GuardDriver.swift` → 445 추가 · 270 삭제.

## 2. AC별 판정

기준 트리 값은 같은 스크립트(`g2-structural.sh` — acceptance.md의 명령을 그대로 묶음)를 `d900a78` 파일에 돌려 얻었고 acceptance.md에 적힌 기준값과 전부 같았다. 출력은 `g2-base.log`(기준)·`g2-head.log`(HEAD)에 있다(스크립트 exit 1은 마지막 `grep -c`가 0건을 낸 정상 종료 값).

| AC | 판정 | 증거 |
|---|---|---|
| AC-001 | ✅ | AI-14·2·4·5(반전)·1·8 모두 ✓ |
| AC-002 | ✅ | AI-15·16·17·3×2 ✓ · 판정 본문 `isSamePlace\|.contains(` HEAD **0** / 기준 **2** |
| AC-003 | ✅ | `placeSearch.search(` **2** / 3 · 재시도·병합 이름 **0 0** / 6 2 · 드라이버 도우미 **0** / 10 |
| AC-004 | ✅ | AI-7·P-3·AD-E5 ✓(`driver-run.log:264`·`:377-379`) · 현재 위치 토큰은 측위가 필요해 시뮬레이터 S-9 |
| AC-005 | ✅ | AI-18 (a)~(d) ✓ |
| AC-006 | ✅ | AI-19 (a)(b) ✓ (한계: `drvPark`는 첫 실행을 건너뜀 — AC-008·S-8이 담당) |
| AC-007 | ✅ | AI-20 ✓ |
| AC-008 | ✅ | 수정: 보류 `:2927` < `store.modifyActivity(` `:2939`·`store.modifyEvent(` `:2957`(기준 보류 0줄). 반복: 머무는 갈래 `:2242`·`:2253` < 마지막 해석 `adoptPlace(` `:2275` < 첫 저장 `:2285`(기준은 해석 `:2250` > 저장 `:2202`). `@MX:WARN` 파일 전체 **1줄**(`:2268`) < `:2285`(기준 0) |
| **AC-009** | ✅ 실질 · **🟡 글자 기준 3건 불일치** | §3 |
| AC-010 | ✅ | AI-21·22 (a)(b) ✓ · 식사 추천: `adoptPlace(` `:2781` · 보류 `:2788` < `nearbyPlaces(` `:2808` · `resolveDestination(` 0 · 이동시간: `resolveOriginAdoption(` `:2855` · `adoptPlace(` `:2865` < 보류 `:2872` < `travelEstimates(` `:2874` · 래퍼 0 · `label: "활동 장소"` **1**(회귀선) |
| AC-011 | ✅ | ① 기준 492는 **런 레인이 관측**(`gate-m1-baseline.log` — 이 레인이 기준 트리에서 재실행하지는 않았다, Gaps) ② `492/492` ✗ 0 exit 0 · 총수 492 − 15 + 15 가 단언 단위로 맞음(위 표) ③ `drvAdoption(` **12** ④ 죽은 이름 **0·0** · 래퍼 이름 **0·0** · `creation: Bool = false` **0** · `func resolveDestination(_ query: String, creation` **0** · 빈 바인딩 **0**(기준 13·20 / 12·0 / 1 / 1 / 2) ⑤ 범위 ⑥ 선언 계약 ⑦ 빌드 ⑧ 샌드박스 |
| AC-012·013 | 🟡 운영자 | 시뮬레이터 S-1~S-12 — 실제 카카오 목록·카드 화면·카드 장수·확인 뒤 모델 발화. 새 빌드는 부팅된 iPhone 17 Pro에 설치돼 있다(런 레인 기록) |

## 3. AC-009 — 글자 기준 불일치 세 건의 분류

acceptance.md AC-009의 계수 13개 중 세 개가 글자 그대로는 기대와 다르다. **동작 결함이 아니라 기준 쪽 문제로 분류한다.**

| 계수 | 기대 | 관측 | 원인 |
|---|---|---|---|
| `이름이 다른 곳이나` | 0 | 1 | `AIAssistant.swift:1010` 주석 — "옛 문구는 '좁혀지지 않아요(이름이 다른 곳이나…)'라 이유를 말했는데 … 거짓이 된다"는 **이력 설명**이다. 모델에게 가던 문구(기준 `:957`)는 사라졌다 |
| `유일 일치` | 0 | 1 | `AIAssistant.swift:883` 주석 — "옛 판정(정확·유일 일치)의 이유였다". 같은 이력 설명 |
| `고칠 일정 '` | 1 | 0 | 맥락 줄은 `add("고칠 일정", "title_query")`(`:944`)가 `"\(label) '\(v)'"`(`:929`)로 조립해 **글자로는 소스에 없다**. 화면 문구는 같고 드라이버 AI-18 (b) `수정 카드에 '고칠 일정' 맥락 줄이 뜬다`가 ✓ |

- acceptance.md는 "조각이 달라지면 같은 규칙으로 표를 고치고 기준 값을 다시 잰 뒤 이유를 §E.2에 적는다"고 했으나 **런 레인의 §E.2에는 AC-009 계수 기록이 없다**(절차 누락 — 동작과 무관).
- 처리 선택지는 리드 몫이다: (가) 이력 주석 두 줄에서 옛 낱말을 빼 쓰기(코드, Q16 수리에 얹으면 무료) (나) `manager-spec`이 AC-009의 기준을 "이력 주석 제외·조립 문구는 드라이버로"로 고치기. 이 레인은 acceptance.md 본문을 고치지 않았다(소유권).

## 4. 렌즈 — 소스별 결과

세 렌즈 모두 읽기 전용으로 최종 HEAD를 독립 심사했다(런 레인의 `code-safety-run.md` 결함 0건은 H1~H4 범위의 판정이라 이번 WARN과 모순되지 않는다). **렌즈의 결함 주장은 코드 읽기 가설로 취급했고, 이 레인이 해당 줄을 직접 읽어 확인했다.** 차단급 주장이 없어 실행 재현 하네스는 돌리지 않았다(차단 0이라 FAIL을 만들지 않으므로 재현이 판정을 바꾸지 않는다).

| 렌즈 | 보고서 | 차단 | WARN | NOTE |
|---|---|---|---|---|
| `code-safety` (4위험 렌즈 + 간결성 + SPEC 질문 a~g) | `sync-lens-code-safety.md` | 0 | 2 | 11 |
| `ai-tooling` (AI 계약 6항목) | `sync-lens-ai-tooling.md` | 0 | 4 | 6 |
| 디자인·비평 (문안·카드 장수) | `sync-lens-design.md` | 1(조건부) → **이 레인이 WARN-범위 밖으로 재분류** | 5 | 8 |

**공통 뿌리 — 등록 전용 문구(Q16)**: 디자인 D-1(확인 버튼 `"등록하기"` — `EditCardView.swift:16`, `AIChatView.swift:110`이 문구를 안 넘김, **이 레인이 두 줄을 직접 읽어 확인**) · 디자인 D-2 = code-safety W-1 = ai-tooling W-2(`AIAssistant.swift:1427` 버린 카드 말풍선, **직접 확인**) · ai-tooling W-1(이미 열린 카드 가드가 열린 카드가 아니라 부른 도구로 문구를 고름 `:975-980`, **직접 확인**). 이 카드가 수정·조회에도 카드를 띄우며 드러났다. **BLOCKING을 WARN으로 낮춘 이유**: SPEC의 어떤 REQ·AC도 확인 버튼·말풍선 문구를 요구하지 않고(REQ-009·011은 줄 이름·캡션·맥락 줄·동사만), 고칠 파일 `AIChatView.swift`가 REQ-015 범위(소스 2파일) 밖이다 — 결함이 있으나 카드가 약속한 것을 어긴 것이 아니라 약속 밖에서 드러난 것이다. **그래도 사용자가 눈으로 보는 거짓 문구라 운영자 결정이 필요하다**(§6).

그 밖의 WARN(전부 후속으로 올림 — `plan.md` 후속 37~41):

- code-safety W-2 — 확정 열쇠가 다듬지 않은 `place.name`이라 이름에 앞뒤 공백이 있으면 확인 재실행이 사전을 놓쳐 같은 카드가 되풀이될 수 있다(`:1140` vs `:1415` 직접 읽음 — **메커니즘은 확인, 카카오 이름 공백 빈도는 미측정·실행 재현 안 함**). 후속 38.
- 디자인 D-3~D-6(캡션이 재검색 뒤에도 원래 질의를 말함 · 맥락 줄 ISO 날짜 · 맥락 줄이 질의를 적고 새 값은 안 보임 · 실행 전 카드와 후보 카드의 같은 값 이중 질문) — 후속 39·40(D-3은 39에 함께 올렸다).
- ai-tooling W-3·W-4 — 기준 장소 줄 현재 위치 칩 없음 · 바꿀 장소·점심 장소 줄 출구 없음(가설, t47 전보다 안전한 쪽) — 후속 41.
- code-safety NOTE 묶음(`query` 매개변수 미사용 · 점심 조건 이중 계산 · `verb == "등록하지"` 문자열 비교 · 낡은 주석·프롬프트 문장 `:1521`) — 후속 37.

**렌즈가 확인한 SPEC 질문(code-safety)**: 반복 등록에서 점심 카드보다 먼저 저장되는 갈래 없음 · 확인으로 시리즈가 두 번 생기는 경로 없음 · 확인 재실행은 재검색 없이 사전으로 풀림(예외 W-2) · 새 `try?`·`Task {`·강제 언래핑 0(양성 대조 포함) · 카카오 호출 질의당 2 → 1.

## 5. Gaps — 관측하지 않은 것

- **시뮬레이터 S-1~S-12** — 실제 카카오 목록의 모양·순서, 카드 장수(단발 두 장·반복+점심 최대 세 장 가설), 카드가 떠 있는 동안의 시간표, 확인 뒤 모델 발화, 수정·조회 카드의 버튼 글자(Q16).
- **"검색 → 보류" 첫 실행** — `PlaceSearch`가 구조체이고 `store.placeSearch`가 매번 새로 만들어져 검색 결과 주입 지점이 없다(`Shared/PlaceSearch.swift:6`, `Shared/Store.swift:788`). 드라이버의 `drvPark`는 보류된 상태에서 시작한다. 순서는 구조 대조(AC-008·010)와 코드 읽기가 전부이고 동작은 시뮬레이터 몫이다(`plan.md` 후속 35 — 이음새 수리 제안).
- **기준 492를 이 레인이 기준 트리에서 다시 재지 않았다** — 런 레인 로그(`gate-m1-baseline.log` mtime 20:49)와 t42 sync 로그(`:577`)가 같은 값이며, 총수 산술은 단언 단위(지운 15·더한 15)로 이 레인이 맞췄다.
- 실기기 · macOS(방침상 안 돌림) · 모델 실제 행동 · AI 일일 할당량 영향(추론: 카드 턴은 모델을 부르지 않고 확인이 한 번 부르므로 호출 수는 비슷).

## 6. 리드·운영자 결정

1. **Q16 — "등록" 전용 문구(후속 36).** (가) 병합 전 작은 수리: `AIChatView.swift`를 범위에 더해 확인 버튼 문구를 도구별로 넘기고, `cancelPendingAsk`(`:1427`)와 이미 열린 카드 가드(`:975-980`)가 열린 카드의 도구로 동사를 고르게 한다(`pendingActionVerb` `:954`를 재사용 — 같은 수리에 AC-009 이력 주석 두 줄도 얹을 수 있다). (나) 알고 받아들이고 후속 카드로. 이 레인은 코드를 고치지 않았다. 등록 문구는 운영자가 확정한 원문(`plan.md` §4)이라 도구별 분기를 어떻게 쓸지는 운영자 확인이 필요하다.
2. **문서 인용 재사상 순서(`plan.md` 기존 §6 (가)/(나))** — 이 레인은 (가)를 따라 **의미가 뒤집힌 행만** 다시 썼고(CHECKLIST Q1~Q8·Q16·요약·목록, 루트 `plan.md` t47 행·후속 31~41) 파일 전체의 줄번호 재사상은 하지 않았다. 다시 쓴 행은 이미 `83ac07f` 좌표라 t44 원장이 건너뛴다(`sync-doc-ledger.md`). **Q16 수리가 코드를 움직이면** 이 행들의 좌표 중 `:975-980`·`:1424-1429` 근처를 그 수리 커밋에서 다시 사상해야 한다.

## 7. 잔여 위험

- 검색으로 푸는 장소마다 카드가 선다 — 한 턴 여러 호출에서 t32 증상이 더 자주 보인다(`spec.md` §4 — 고치지 않음).
- 조회가 두 단계(카드 → 답)가 된다 — 운영자가 D-1 (b)로 고른 비용. 확인 뒤 모델이 고른 장소 이름을 답에 쓰는지는 S-11·S-12가 처음 본다. 프롬프트(`:1521`)는 아직 "조회라 되물을 필요가 없다"고 말한다(이 카드가 프롬프트를 바꾸지 않았다 — 모델 행동 영향은 미관찰).
- 같은 대화에서 원래 질의를 다시 말하면 다시 묻는다 — 운영자가 의도된 동작으로 확정(`spec.md` §3).
- 문구 조각은 운영자 확정 원문(D-3 (a))이지만 조회 동사 `조회하지`·`기준 장소`는 원문 밖 파생이다(착수 시 고지됨).

---

# 2차 판정 — Q16 병합 전 수리 `7dbcd9d` (2026-10-07)

판정 대상: 브랜치 `WT-always-select` HEAD `7dbcd9d`(1차 sync 커밋 `ef57171` 위, 수리 대상 코드는 `83ac07f`→`7dbcd9d`). 사양은 운영자 확정 문구(`decisions.md` §Q16): 확인 버튼 도구별 `등록하기·고치기·조회하기` · 버린 카드 말풍선과 열린 카드 가드의 동사는 **열린 카드의 도구** · 이력 주석 두 줄 정리 · acceptance.md 본문 금지.

> **권고: PASS 유지 — 차단 0.** 수리는 운영자 확정 사양을 단일 도구 카드에서 그대로 구현했고 모든 게이트를 통과한다. 다만 세 렌즈가 일치해 지목한 문제 셋(후속 42)이 남고, **수리의 세 문구를 덮는 저장소 드라이버 단언이 없다**(수리 커밋이 드라이버를 바꾸지 않았다). 병합 전 마이크로 수리 여부는 리드·운영자 몫이다(§8.6).

## 8.1 게이트 — 이 레인이 이번에 직접 돌린 것

| 주장 | 명령 | 관측된 출력 | 로그 |
|---|---|---|---|
| 수리 범위 | `git diff --name-only 83ac07f 7dbcd9d -- Shared Tools proxy project.yml` · `git diff --shortstat 83ac07f 7dbcd9d -- Shared` | `Shared/AIAssistant.swift` · `Shared/AIChatView.swift` 둘뿐(`Tools/`·`proxy/` 변경 없음) · 코드 +44 −19 | — |
| 드라이버 통과 | 1차와 같은 레시피, **새 컴파일** | `compile-exit=0` · `run-exit=0` · `492/492 통과` · ✗ 0 · `[실제 데이터] 대조 통과` | `gate-sync2-driver.log:577-578` |
| 단언 집합 불변 | `diff` (정렬한 ✓ 줄 — 1차 `gate-sync-driver.log` ↔ 이번) | 동일(`D4` 한 줄의 출력 *위치*만 다름 — 기존 비결정적 순서) | — |
| iOS 무경고 | `xcodebuild … -derivedDataPath .moai/state/verify/t47-sync2/dd build` (새 경로) | `build-exit=0` · `** BUILD SUCCEEDED **` · `^SwiftCompile` 42 · `AIChatView.swift`·`AIAssistant.swift` 컴파일 로그에 등장 · `grep 'warning:' \| grep -v appintentsmetadataprocessor \| sort -u \| wc -l` → 0 | `gate-sync2-ios-build.log` |
| 구조 대조 | `g2-structural.sh`(1차와 같은 스크립트) 두 번 출력의 `diff` | 모든 좌표가 **+21로 균일하게 이동**하고 순서 관계 유지: 수정 보류 `:2948` < `modifyActivity(` `:2960`·`modifyEvent(` `:2978` · 반복 `@MX:WARN` `:2289`(파일 전체 **1줄**) < 점심 해석 `:2296` < 첫 저장 `:2306` · 식사 추천 `adoptPlace(` `:2802` · 보류 `:2809` < `nearbyPlaces(` `:2829` · 이동시간 `:2876`·`:2886` < 보류 `:2893` < `travelEstimates(` `:2895` | `gate-sync2-structural-head.log` |
| AC-009 | 같은 스크립트 | 옛 문구 다섯 개 **0 0 0 0 0**(1차 `0 1 0 0 1` — 이력 주석 두 줄이 정리됨 ✓). 새 조각 `1 1 1 1 1 0 1 1` — `고칠 일정 '`는 조립 문구(`"\(label) '\(v)'"`)라 그대로 0(1차 분류와 같음, 판정문 §3) | 같은 파일 |
| 선언 구간 | `git diff -U0 83ac07f 7dbcd9d -- Shared/AIAssistant.swift` 헝크 8개 vs `toolsJSON()` `:1581-1776` | 헝크가 전부 `:882`~`:1443`, 선언 구간을 지나는 헝크 0 | — |
| proxy | 코드 변경이 없어 재실행하지 않았다(위 `git diff --name-only`) | 1차 `7/7 통과`가 마지막 실행 | — |
| 샌드박스 잔여 | `ls -d $TMPDIR/besir-gd-*` | 없음 | — |

## 8.2 수리 동작 재현 — 스크래치 하네스 (저장소 드라이버에는 이 단언이 없다)

**왜 따로 돌렸나**: 수리 커밋은 `Tools/GuardDriver.swift`를 바꾸지 않았다. 버튼 문구·버린 카드 말풍선·도구가 다른 가드 문구를 보는 단언이 하나도 없어(code-safety W-3, ai-tooling G-4가 같은 지적) 드라이버 `492/492`는 이 수리가 동작한다는 증거가 아니다. 그래서 드라이버 사본의 AI절 끝에 단언을 덧붙인 스크래치 하네스를 새로 컴파일해 돌렸다(드라이버의 격리·샌드박스를 그대로 물려받는다). 소스는 `.moai/reports/t47/sync2-q16-repro/`(`q16_block.swift`·`make_q16_driver.py` — 확장 `q16Mixed` 포함), 실행 출력은 `gate-sync2-q16-repro.log`다. **첫 컴파일은 `PendingAsk`가 `AIAssistant` 안의 별칭이라 실패했고(`error: cannot find 'PendingAsk' in scope`) 고친 뒤 다시 돌렸다** — 그 전의 결과는 없다.

| 단언 | 결과 | 관측된 원문 |
|---|---|---|
| Q16-1 버튼 낱말 | ✓ | 생성 셋 → `등록하기` · `update_schedule` → `고치기` · `check_travel_time`·`recommend_meal` → `조회하기` · 빈 값·모르는 도구 → `등록하기` |
| Q16-2 `toolName(of:)` | ✓ | 조회·수정·식사 추천·등록 카드가 각자 자기 도구 이름을 돌려준다 · 호출 없는 카드는 `""`(→ `등록하기`) |
| Q16-3 버린 카드 말풍선 | ✓ | `물어본 값을 받지 못해서 조회하지 않았어요.`(조회·식사 추천) · `…고치지 않았어요.` · `…등록하지 않았어요.` · 카드는 남지 않음 |
| Q16-4 열린 카드 가드 | ✓ | 아래 4조합 문구 · 카드는 한 장만 남음 |
| Q16-5 카드가 없을 때 | ✓ | 들어온 호출의 동사로 새 카드 한 장(`아직 조회하지/고치지/등록하지 않았어요 — …`, 수리 전과 같음) |
| **Q16-6 혼합 턴** | **✗ — 재현** | 한 턴 `[check_travel_time, create_schedule]` → 카드 호출 둘 · `toolName=check_travel_time` · **버튼=조회하기**. 순서를 바꾼 `[create_schedule, check_travel_time]`은 `등록하기` |

합계 `497/498 통과`(= 492 + 6, ✗ 1 = Q16-6), 실데이터 대조 통과. 이 하네스의 exit 1은 의도한 ✗에서 온 것이다.

**가드 문장의 실제 원문**(들어온 호출의 결과로 모델에게 가는 문장):

| 열림 | 들어옴 | 모델이 받는 문장의 앞 |
|---|---|---|
| 조회 | 등록 | `조회하지 않았어요 — 이미 같은 질문의 카드가 열려 있어요. 사용자가 그 카드에서 고르면 그 카드의 일만 진행돼요. …` |
| 수정 | 조회 | `고치지 않았어요 — 이미 같은 질문의 카드가 열려 있어요. … 그 카드의 일만 진행돼요. …` |
| 등록 | 조회 | `등록하지 않았어요 — 이미 같은 질문의 카드가 열려 있어요. … 그 등록만 진행돼요. …` |
| 수정 | 식사 추천 | `고치지 않았어요 — 이미 같은 질문의 카드가 열려 있어요. … 그 카드의 일만 진행돼요. …` |

양성 대조: 수리 전 코드의 같은 자리(`83ac07f:Shared/AIAssistant.swift:1427`)는 도구와 무관하게 `…그 등록은 진행하지 않았어요.`였다. 이 하네스의 기대 문자열은 그 글자와 다르므로 수리 전 코드에서는 구조적으로 통과할 수 없고, 새 API(`pendingConfirmTitle`·`toolName`)는 수리 전에 없다 — 그래서 수리 전 트리에서 하네스를 따로 돌리지 않았다(Gaps).

## 8.3 렌즈 — 소스별 결과 (읽기 전용, 수리 diff 범위, 최종 HEAD)

| 렌즈 | 보고서 | 차단 | WARN | NOTE |
|---|---|---|---|---|
| `code-safety` | `sync2-lens-code-safety.md` | 0 | 3 | 7 |
| 디자인·비평 | `sync2-lens-design.md` | 0 | 3 | 5 |
| `ai-tooling` | `sync2-lens-ai-tooling.md` | 0 | 2 | 4 |

1차 지적의 닫힘: 디자인 D-1(버튼) · D-2 = code-safety W-1 = ai-tooling W-2(말풍선) · ai-tooling W-1(가드 꼬리 문장) — **단일 도구 카드에서 닫혔다**(Q16-1~5 ✓). 세 렌즈가 **독립적으로 같은 세 지점**을 지목했다:

| # | 지점 | 렌즈 | 이 레인의 확인 | 판단 |
|---|---|---|---|---|
| ① | 혼합 턴에서 버튼·말풍선이 틀림 — `toolName(of:)`(`AIAssistant.swift:973-975`)가 카드의 **첫** functionCall만 읽는데 실행 전 카드는 한 턴의 호출을 전부 담고 줄은 생성 도구에서만 생김 | code-safety W-1 · 디자인 S2-2 · ai-tooling G-2 | **실행 재현**(Q16-6 ✗). 확인(누르기)이 호출을 전부 실행하는 것은 `resolvePendingAsk`→`runToolCalls(parts)`(`AIAssistant.swift:1393`, grep으로 확인) | **WARN** — 수리 전에는 늘 `등록하기`라 맞던 경로의 회귀(`[조회, 등록]` 순서만). 데이터 손실·저장 오류 없음, 모델이 혼합 턴을 실제로 보내는지는 미관찰. 수리는 한 줄(생성 도구가 있으면 그 이름을 먼저) |
| ② | 가드 문장의 **첫머리 동사**가 들어온 호출이 아니라 열린 카드의 도구 — 도구가 다른 조합에서 첫머리가 들어온 호출과 어긋남(위 표) | 디자인 S2-3 · ai-tooling G-1 | **원문 관측**(위 표). ai-tooling의 비교: 수리 전에는 `열림=수정·들어옴=조회` 등 두 조합이 문장 전체가 맞았고 이번에 첫머리가 어긋났다 | **운영자 결정** — 운영자가 "열린 카드의 도구로 동사 결정"을 확정했고 수리는 그대로 구현했다(결함이 아니라 확정 문구의 적용 범위). 렌즈 제안(첫머리는 들어온 호출, 꼬리만 열린 카드)은 확정 등록 문장의 적용 범위를 바꾼다 |
| ③ | `EditCardView.swift:16`의 머리글·확인 기본값을 쓰는 곳이 없어졌고 `AIChatView.swift:113`이 머리글 리터럴을 복사함(계약 5) | code-safety W-2 · 디자인 S2-1 · ai-tooling G-5 | **grep 확인**: `EditCardView(` 호출부 넷(`AddActivityView.swift:42`·`ActivityDetailView.swift:68`·`AddEventView.swift:68`은 `chrome: EditCardChrome(header: nil, confirmTitle: nil)`, `AIChatView.swift:112-114`는 문구 명시) 전부 `chrome:`을 넘긴다 | **운영자 결정** — Q16이 기본값을 "무변경"으로 확정했으나 그 전제("수동 편집 화면이 쓴다")는 성립하지 않는다 |

그 밖: 수리를 덮는 **드라이버 단언이 없다**(code-safety W-3 · ai-tooling G-4 — 확인: 수리 커밋의 변경 파일에 `Tools/`가 없음). 디자인 S2-4~S2-8 · code-safety NOTE 7 · ai-tooling NOTE 4는 보고서에 있다(수리 전부터 있던 접근성 항목, 주석의 근거 방향, 이름 없는 호출의 기본 갈래 `등록` 등 — 판정에 영향 없음).

**BLOCKING을 0으로 둔 이유**: ①은 재현됐지만 수리가 만든 회귀가 *드문 조합의 라벨*에 한정되고 사용자가 같은 메시지에서 요청한 두 일이 둘 다 실행된다(데이터·안전 영향 없음). ②는 확정 사양의 문구 선택이고 ③은 정리 사안이다. 어느 것도 SPEC의 REQ·AC를 어기지 않는다.

## 8.4 문서 점검 — 수리 레인이 다시 사상한 행

- **좌표 대조**(`cite_check.py` — 행마다 인용된 좌표의 HEAD 본문을 나란히 찍어 의미를 읽었다): CHECKLIST Q1~Q8·Q16, plan.md 후속 36~41의 인용이 의미까지 맞다. 어긋난 것은 **하나** — Q2의 `parkForUnclearPlaces` 범위 끝 `:984-1033`이 빈 줄을 가리켜 `:984-1032`로 고쳤다(범위 *끝*의 한 줄 오차 — 이 프로젝트에서 반복돼 온 유형). 후속 36의 `:1427`·`:975-980`·`:954`는 `83ac07f` 시점이라고 문장에 명시한 의도된 좌표다.
- **Q16 행이 근거를 과장했다**: 수리 레인이 ✅로 올리고 근거를 "드:492/492 재실행"으로 적었으나 드라이버에 이 세 문구의 단언이 없다. ⚠️로 내리고 이유 셋(혼합 턴·가드 첫머리·단언 없음)과 하네스 근거로 다시 썼다. 요약 줄(`CHECKLIST.md:305`·`:312`·`:313`)이 Q16을 아직 ❌로 말하던 **내부 불일치**도 맞췄다(⚠️ 목록으로 이동).
- plan.md: 후속 36의 "닫힘"을 "단일 도구 카드는 닫힘 — 남은 셋은 후속 42"로 바꾸고 후속 42를 신설, t47 행 꼬리에 2차를 더했다.
- **건드리지 않은 것**: `sync-doc-ledger.md`·`decisions.md`(수리 레인의 커밋되지 않은 변경 — 제 판정은 커밋된 `7dbcd9d`만 근거로 했다), `acceptance.md`(소유권).
- **t44 원장이 건너뛸 좌표 추가(HEAD `7dbcd9d` 기준)**: CHECKLIST Q2 `AIAssistant.swift:984-1032` · Q16 행의 좌표 전부 · plan.md 후속 42(`AIAssistant.swift:973`·`:992-998`·`:907`·`:1382`, `EditCardView.swift:16`, `AIChatView.swift:113`). 새 코드 변경이 들어오면 이 좌표를 그 커밋에서 다시 사상한다.

## 8.5 Gaps — 관측하지 않은 것

- **시뮬레이터 S-7·S-11·S-12의 버튼 글자·버린 카드 말풍선** — 하네스는 뷰가 부르는 함수(`toolName(of:)`·`pendingConfirmTitle`)까지만 본다. SwiftUI 뷰가 그 값을 실제로 그리는 모습은 화면 관측 몫이다.
- 모델이 `[조회, 등록]` 혼합 턴을 실제로 보내는지(①의 빈도).
- 수리 전 트리에서 같은 하네스를 돌린 양성 대조(위 이유로 생략).
- 1차에서 이월: 시뮬레이터 S-1~S-12 전체 · "검색 → 보류" 첫 실행 · macOS.
- 수리 레인의 커밋되지 않은 변경(`gate-q16-driver.log`·`build-q16/` 등)은 근거로 쓰지 않았다.

## 8.6 리드·운영자 결정

1. **병합 전 마이크로 수리(권장하지만 필수 아님)**: ① 혼합 턴 — `toolName(of:)`가 카드에 생성 도구가 있으면 그것을 먼저 고르게(생성 도구 목록 리터럴이 `AIAssistant.swift:907`·`:1382`에 두 벌이라 상수 하나로) · ② 하네스 Q16-1~6을 저장소 드라이버로 승격(①을 고친 뒤 총수 **498/498** 기대 — 소스는 `.moai/reports/t47/sync2-q16-repro/`). 이 둘은 코드 두 파일 몇 줄이고 SPEC 상태를 `completed`로 올리기 전이라 개정 절차가 붙지 않는다.
2. **운영자 결정**: 가드 첫머리 동사(후속 42 ②) · `EditCardView.swift:16` 기본값 처리(③).
3. 수리하지 않고 병합하면 후속 42로 남긴다(plan.md).
4. `spec.md`는 `implemented` 그대로다 — `completed`는 병합 커밋에서 리드가 올린다(1차와 같다).

🗿 MoAI
