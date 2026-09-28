# t16 sync 재심사 렌즈 — ai-tooling(선언·인자 계약) 2회차 (원문 보관)

- 대상: 브랜치 `WT-place-resolution` HEAD `894fdc1`(코드 = `8ad3abd`), 1차 판정 `7a1b171`, base `aa7b792`
- 수행: 2026-09-28, sync 레인이 띄운 읽기 전용 렌즈(`hns-besir-app-ai-tooling-specialist`). run 레인과 다른 손이다.
- 제약: 파일 수정·빌드·드라이버·npm·라이브 요청 금지. 판정은 코드 읽기에 근거한다. 렌즈는 반환문을 넘긴 직후 사용량 한도(429)로 종료됐고, 반환문 자체는 끝까지 왔다.
- 이 파일은 렌즈 반환문을 고치지 않고 옮긴 것이다. B-1·B-2·B-3의 **실행 재현**(5fb6634 대조 포함)은 sync 레인이 따로 했고 결과는 `sync-verdict.md` §R2에 있다.

---

# t16 sync 재심사 — ai-tooling 렌즈(선언·인자 계약) 판정

- 대상: 워크트리 `.claude/worktrees/t16`, HEAD `894fdc1`. 코드는 `8ad3abd`와 같습니다(`git diff 8ad3abd HEAD -- Shared Tools proxy project.yml` 무출력).
- 비교 기준: 1차 FAIL 판정 `7a1b171`(검토 대상 `5fb6634`), base `aa7b792`.
- 줄 번호는 모두 `git show 8ad3abd:Shared/AIAssistant.swift` 사본에서 `awk`/`sed`로 찍어 확인한 값입니다.
- 읽기 전용으로 진행했습니다. 빌드, 드라이버, npm, 모델 요청은 돌리지 않았습니다.

## 판정: **FAIL** — 차단 6, 선택 2, 관찰 3

- **통과한 것**
  - 선언 계약: 도구 JSON과 시스템 프롬프트가 5fb6634와 바이트까지 같습니다.
  - 프록시 무변경.
  - 히스토리 모양.
  - 방어 함수 본문: `isSamePlace`, `resolveOrigin`, `executeListSchedules`, `modelSuppliableKeys`, `missingAskedArguments`, `runToolCalls`, `trimHistory`, `repairDanglingToolTurn`.
- **막는 것 여섯**
  - **B-1** R1 값 정화가 정당한 재호출까지 지웁니다. 머무는 반복에서 사용자가 고른 '이동 없음'이 재호출 때 사라지고, '이동 없음'이 없는 카드로 다시 묻습니다.
  - **B-2~B-4** REQ-010 50 m 절(A-2)은 "앵커와 선택이 모두 로컬에서 좌표를 아는 경우"에만 닫혔습니다. 거짓 실패 문구(D2)와 막힘(D3)이 세 경로에 남아 있습니다.
  - **B-5** D5 양성 대조 단언의 좌표가 1.4 km 떨어져 있어, 양성 대조 구실을 하지 못합니다.
  - **B-6** AC-011 (1)·(5)가 기계 판정으로 실패하는데, §E.3에는 ✅로 남아 있습니다.

## 1. REQ-013 — 선언은 통과, 경로·AC-011은 실패

- **toolsJSON**(함수 전체를 `sed`로 잘라냄, 세 커밋 모두 164줄)
  - aa7b792와 8ad3abd의 `diff` 결과는 `58c58` 한 줄입니다. 알려진 `create_recurring_schedule.origin_query` description 줄입니다.
  - 5fb6634와 8ad3abd는 `cmp` 결과 IDENTICAL입니다.
  - 타입 분포는 `ARRAY 1 · BOOLEAN 8 · INTEGER 6 · OBJECT 9 · STRING 44`이고, `grep -c '"type": "[a-z]'`는 0입니다.
- **systemPrompt**(함수 전체, 64줄): 5fb6634와 8ad3abd가 `cmp` IDENTICAL입니다. `callAI` 본문도 같습니다(`tools: [["functionDeclarations": toolsJSON()]]` 유지).
- **새 파일·프록시**
  - `git diff --name-only --diff-filter=A aa7b792 8ad3abd -- Shared/`는 0줄입니다.
  - `git diff aa7b792 8ad3abd -- proxy/ project.yml | wc -l`은 0입니다.
- **실패 (1)**: `Shared/EditCard.swift:244`의 `+    var clearedKeys: Set<String> = []`는 주석이 아닌 줄입니다.
  - REQ-013은 run 경로를 "comment lines of `Shared/EditCard.swift`"로 한정합니다.
  - AC-011 (1)의 필터를 돌리면 0줄이 아니라 1줄이 나옵니다.
- **실패 (5)**: AC-011 (5)는 `sanitizeModelArgs` 본문을 aa7b792판과 `cmp`해 무출력이어야 합니다. 실측은 DIFF입니다.
  - 강화 방향이라 REQ-013의 "weaken 금지" 자체는 지켜집니다.
  - 그러나 AC의 기계 대리 판정은 실패합니다.
- progress §E.3의 "AC-011 ✅"와 M7 머리말의 "REQ-013 유지"는 이 두 사실을 다루지 않습니다(B-6).

## 2. A-2 — REQ-010 절별 대조 (8ad3abd 코드 읽기)

### 시점과 흐름
- staying 여부는 주입 **전** 모양(`preInjection`, `:1196`)으로 판정합니다.
- 교체는 `:1228-1230` → `stayingTokenForColocatedPick`(`:1258-1274`)에서 일어납니다.
- 앵커와 선택 값의 좌표는 `locallyResolvedPlace`(즐겨찾기 → 확정 사전, `:1279-1284`)와 `currentPlace()`에서만 얻습니다.

### 절별 결과

| REQ-010 절 | 한 번짜리 활동 | 반복 |
|---|---|---|
| 출발지 줄 하나, 미선택으로 시작, 모델 값 캡션, '이동 없음' 칩 | ✓ `:584-592`·`:812-818` | ✓ `:538-544` |
| 카드가 수단·여유·알림을 묻지 않음 | ✓ | ✓(AC-D3c 키 = {origin_query, weeks}) |
| '이동 없음' 선택 → 활동만 | ✓ | ✓. 단 **재호출에서 선택이 지워짐(B-1)** |
| 같은 좌표·다른 이름 즐겨찾기('우리집') | ✓(앵커가 즐겨찾기·확정일 때) | ✓(같은 조건) |
| 카드에서 확정한 검색 장소 | ✓(`choose(field:place:)`가 `confirmedPlaces`에 기록) | ✓ |
| 현재 위치(위치 잡힘) | ✓(앵커 로컬일 때) | ✓(앵커 로컬일 때) |
| 앵커가 **같은 카드의 못 푸는 일반명사 줄**('회사' 즐겨찾기 없음) | ✗ **B-3** | ✗ B-3 |
| 앵커가 검색으로만 풀리는 이름 | ✗ **B-4** | ✗ B-4 |
| 활동 장소와 같은 문자열을 자유 입력(앵커 비로컬) | 등록은 활동만이지만 문구가 거짓(**B-2**) | ✓(`:2102`) |
| 모델이 보낸 편도 '우리집'→'집'(AC-008 (5)) | 발동 안 함 ✓(아래 이유) · 증거 ✗(**B-5**) | 범위 밖 |
| origin = destination은 사용자 선택으로만 확정 | ✓ | ✓ |

- 양성 대조가 코드상 발동하지 않는 이유: `preInjection`이 staying이 아니면 `:1266`에서 nil을 돌려주고, 실행부 절(`:1887`)은 `stayingOneShotActivity(input)`이 거짓이면 돌지 않습니다.

## 3. R1 값 정화 — 위치, 범위, 깨는 흐름

**위치**
- 정화는 `runLoop`의 `:428`(`fillStated(sanitizeModelArgs(parts))`) 한 곳에서만 돕니다.
- `resolvePendingAsk`는 이미 정화된 `ask.parts`에 카드 값을 얹고 다시 정화하지 않습니다(`:1196-1245`). 그래서 카드가 넣은 토큰은 실행부까지 살아갑니다.
- 후보 카드(`parkForUnclearPlaces`)도 실행부 `input`을 그대로 보류하므로 토큰이 보존됩니다.
- 재시도 경로는 `submit` 스냅숏 롤백뿐이고, 정화를 다시 거치지 않습니다.
- 히스토리 수리 두 곳(`repairDanglingToolTurn`, `stripInlineDataFromHistory`)은 정화와 무관합니다.

**범위**
- `:963-967`은 선언된 모든 키의 최상위 String 값을 세 토큰과 정확히 비교해 버립니다.
- 따라서 `origin_query`, `travel_from_query`, `return_to_query`, `destination_query`, `place_query`, `lunch_place_query`, `title`이 모두 덮입니다.
- 선언 속 배열(`weekdays`)에는 토큰이 실릴 자리가 없습니다.
- 빈틈 하나: 공백이 붙은 토큰(O-1).

**깨는 흐름(B-1)**
- 이 파일은 재호출을 "히스토리 값의 되울림"으로 설계했습니다(`:1619-1621` "겹침처럼 되돌아가는 응답을 받은 뒤의 재호출은 값이 이미 채워진 채 히스토리에 남아 있어 모델이 그대로 되울러 오고…").
- R1의 전제 "모델 턴의 토큰은 전부 에코"는 이 설계와 부딪칩니다. 앱 자신이 "같은 인자로 다시 호출"을 지시하는 결과 문구들이 있습니다.
  - `recurringArgumentIssue`(`:2038`)
  - `stayingEndAsk`(시각 문자열이 해석되지 않을 때 `:2044`)
  - `conflictPrompt`의 on_conflict
  - "현재 위치를 확인하지 못했어요"
- 경우별 결과:
  - **머무는 반복**: `origin_query`가 통째로 지워집니다. 그러면 `stayingRecurrence`(`:773-777`)가 거짓이 되고 비머무는 갈래(`:546-551`)로 갑니다.
    - `originField()`(`:638-643`)는 즐겨찾기와 현재 위치만 있고 '이동 없음'이 없습니다.
    - 수단·여유·알림 줄도 새로 뜹니다.
    - 5fb6634에서는 같은 재호출에 weeks 줄 하나만 떴습니다.
  - **한 번짜리 활동**: 출발지 줄이 '이동 없음'과 함께 다시 섭니다. REQ-010에는 맞지만, 사용자가 같은 답을 두 번 합니다.
  - **create_schedule·통근 반복**: 수단·여유·알림이 원래 카드 전용 키라, 재호출 카드는 base 때부터 떴습니다(O-3). 거기에 출발지 줄 하나가 더해집니다.
  - **확인·반복 확인**: `confirm_zero`와 `confirm_many`에는 장소 토큰이 없어 영향이 없습니다.

## 4. 모델에게 가는 문구

- 수리가 **새로 더하거나 바꾼 모델 대상 문자열은 0건**입니다.
  - 범위: 5fb6634→8ad3abd AIAssistant diff의 `+` 줄. 문자열 리터럴은 키 이름뿐입니다.
- 바뀐 것은 어떤 기존 문구가 나가는지입니다.
  - D2의 "찾지 못해"는 로컬 앵커 경로에서 사라졌습니다.
  - 그러나 폴백 경로(`:1887-1889` → `:1901`)에서는 여전히 나갑니다(B-2).
- A-3(`:941` "자동 진행 … 기다려"), A-4(`stayingEndAsk` 본문 md5 동일, 프롬프트·선언 동일), A-5(`:2337` "… 뒤 다시 등록해.")는 1차 판정대로 새 카드(R3)로 넘어갔고 이번 트리에서 바뀌지 않았습니다.

## 5. 히스토리 모양 — 통과

- `contents.append` 자리는 여섯으로, 5fb6634와 같습니다(`:205·305·419·438·468·1245`).
- `resolvePendingAsk`는 여전히 `:1245`(model fc) 바로 뒤에 `:1246` `runToolCalls` → `:468`(function)으로 이어집니다.
- 새 await(`currentPlace`, 최대 15×200 ms)는 `:1245`보다 **앞**에 있습니다.
  - `send`·`share`는 `!isThinking`(`:271`, `:279`)으로 막히므로, 끼어드는 user 턴은 없습니다.
- 가능한 모양은 1차 판정 그대로 둘입니다.
  - `[user → model(fc) → function]`
  - `[function → model(fc) → function]`
- 프록시 `toResponsesRequest`(`proxy/src/index.js:185`·`:194`)는 무변경이고, 두 모양을 모두 변환합니다.

## 발견 표 (좌표는 8ad3abd, 찍어서 확인함)

| id | 심각도 | 위치 | 무엇이 깨지나 | 재현(코드 읽기, 미실행) | 수정 방향 |
|---|---|---|---|---|---|
| B-1 | **차단** | `AIAssistant.swift:963-967`, `:546-551`, `:638-643`, `:2038` | 머무는 반복에서 '이동 없음'을 고른 뒤 앱이 재호출을 지시하면, 에코된 `origin_query` 토큰이 지워집니다. 호출이 비머무는 모양이 되어 '이동 없음' 없는 출발지 줄과 수단·여유·알림 줄이 뜹니다. 사용자가 다른 즐겨찾기를 고르면 통근 구간이 생깁니다. 사용자가 이미 고른 '이동 없음'을 지키지 않는 것이고, `:1619-1621`의 재호출 설계와도 어긋납니다. 드라이버에는 반복 에코 단언이 없습니다(AC-R1은 활동만 봅니다). | ① `drvAsk("create_recurring_schedule",{origin_query:"집",destination_query:"집",weekdays:[mon,wed,fri],arrival_time:"12:00",return_time:"13:00",every_n_weeks:2})` → 카드 {origin_query, weeks} ② '이동 없음'·'4주' → `drvResolvePendingAsk` → "…2주 간격으로만 … confirm_recurrence:true를 붙여 다시 호출해", 0건 ③ 같은 인자 + `origin_query:"__no_travel__"`, `confirm_recurrence:true`로 `drvAsk` → 카드 키 [origin_query(칩: 즐겨찾기·현재 위치), mode_this_time, buffer_minutes, notify_lead_minutes, weeks]. 5fb6634에서는 [weeks]였습니다. | 1차 A-1 제안의 구분을 되살립니다. `create_recurring_schedule`의 `origin_query` 토큰은 지우지 말고 `destination_query` 값으로 바꿉니다. 그러면 같은 값 신호가 살아 머무는 줄이 '이동 없음'과 함께 다시 서고, 이 값을 사용자 선택 없이 확정하지 않는다는 조건도 지켜집니다. 나머지 토큰과 키는 지금처럼 지웁니다. 또는 conflictConfirmAsk처럼 (도구·키·토큰·앵커 값)을 기록해, 앱이 주입한 조합과 맞는 재호출만 살립니다. 위 ①~③을 단언으로 추가합니다. |
| B-2 | **차단** | `:1887-1889` → `:1895-1901` | 실행부의 50 m 폴백은 `from = nil`로 두면서, `:1901` 집계는 여전히 `travel_from_query`를 "해석 실패"로 셉니다. 그래서 D2의 거짓 실패("⚠️ … 가는 편 출발지 'X' 위치를 찾지 못해 … 장소를 다시 정해달라고 해")가 이 폴백을 지나는 모든 경로에 남습니다. 주석(`:1882-1884`)은 이 자리를 마지막 방어선이라 부릅니다. | 활동 장소가 비로컬 검색 이름('스타벅스 강남점')인 머무는 카드에서, 출발지 줄에 같은 이름을 직접 입력합니다(`submitCustom`, `.place`는 자유 입력 허용). 또는 B-3 경로. 결과는 활동 1·이동 0인데, 요약에 "찾지 못해"가 붙습니다. | 1차 판정이 적은 모양대로, 교체 갈래에 표시를 세워 `:1901` 집계에서 뺍니다(한 줄). 비로컬 앵커 자유 입력 단언을 추가합니다. |
| B-3 | **차단** | `:1267`(`trimmedArg(preInjection, anchorKey)`) | 앵커를 주입 **전** 값에서 읽습니다. 머무는 카드에 앵커 줄(못 푸는 일반명사 `activityPlaceField`, `:560` / `destinationField`, `:537`)이 함께 있으면, 사용자가 그 줄에서 고른 좌표를 보지 못합니다. 결과: 현재 위치나 '우리집' 선택은 "아직 만들지 않았어요 — 이동수단, 도착 여유, 알림…"으로 막히고(D3), 두 줄에 같은 즐겨찾기를 고르면 B-2 문구가 나갑니다(D2). | 즐겨찾기 {집·우리집}만 있고 '회사'는 없는 상태에서 `create_activity{place_query:"회사", start_iso, end_iso}` → 카드 [place_query(못 푸는 값), travel_from_query(머무는 줄)] → 장소 줄에서 '집', 출발지 줄에서 '우리집' 선택 → 확인. `:1266`에서 '회사'가 로컬로 풀리지 않아 nil → 편도 → 막힘. | staying 판정만 `preInjection`으로 하고, 앵커는 그 시점의 `args`에서 읽습니다. `askFields`가 앵커 줄을 출발지 줄보다 먼저 만들므로(`:537`→`:543`, `:560`→`:591`) 루프 순서상 앵커 값이 이미 실려 있습니다. 한 번짜리·반복 단언을 하나씩 추가합니다. |
| B-4 | **차단**(또는 SPEC 개정) | `:1253-1256`·`:1882-1884` 주석, `:1266-1268` | 앵커가 검색으로만 풀리는 이름이면, 현재 위치나 다른 이름을 골랐을 때 '다른 출발지'로 취급됩니다. 그러면 수단·여유·알림을 묻고, 한 번짜리는 약 0분짜리 가는 이동 1건을 만듭니다. REQ-010의 "50 m 안이면 활동만"은 앵커의 종류를 가리지 않습니다. 주석의 "실행부 50 m 절이 방어선"은 이 선택들에는 거짓입니다. 그 절은 문자열이 같을 때만 돕니다. | "스타벅스 강남점에서 2시~5시 공부" → 머무는 카드 → 그 매장에서 '현재 위치' 선택 → "아직 만들지 않았어요 — 이동수단…" → 셋을 받은 재호출 → 가는 이동 1건. | 둘 중 하나입니다. (가) 머무는 요청이었다는 사실을 카드 기록(clearedKeys와 같은 방식)으로 호출에 실어, 실행부가 장소를 해석한 뒤 50 m를 먼저 재고 그다음에 부재를 따집니다. (나) `manager-spec`으로 REQ-010 50 m 절을 로컬 앵커로 좁히고 잔여 위험에 적습니다. 어느 쪽이든 두 주석을 사실대로 고칩니다. |
| B-5 | **차단**(증거, 1차 D5) | `Tools/GuardDriver.swift:2804` | AC-D5의 `place_query`가 '회사'(37.510, 127.010)이고 출발지는 '우리집'(37.500, 127.000)입니다. 거리는 약 1,418 m입니다. 편도 실행부에 일반 50 m 가드를 넣어도 이 단언은 통과하므로 양성 대조가 아닙니다. 게다가 `drvExecuteTool`(`:150-151`)은 정화를 거치지 않는데, 주석은 "값 정화(R1)가 … 살려야 이 선이 산다"고 적습니다. `AB-REQ010 한 번짜리 다른 출발지`(회사→집)도 같은 좌표 쌍이 아닙니다. | `grep -n '"place_query": "회사",' Tools/GuardDriver.swift` → `2804` | AC-008 (5)의 원문 쌍(`travel_from_query` '우리집', `place_query` '집')으로 바꾸고, 가능하면 `drvAsk` → 카드 → 확인 경로(정화 포함)로 돌립니다. 기대값은 가는 이동 1건, origin '우리집'입니다. |
| B-6 | **차단**(SPEC·증거) | `EditCard.swift:244`, `AIAssistant.swift:955-972` | AC-011 (1)은 비주석 줄 1줄로 실패하고, AC-011 (5)의 sanitize `cmp`도 DIFF입니다. REQ-013의 EditCard 경로 절도 벗어납니다. progress §E.3 "AC-011 ✅"는 8ad3abd에서 사실이 아닙니다. | §1의 명령 두 개 | `manager-spec` 개정으로 처리합니다. REQ-013·AC-011 (1)에 `clearedKeys` 저장 속성 예외를 넣고, AC-011 (5)의 sanitize 판정을 "키 필터 보존 + 값 필터 추가" 대조로 바꾼 뒤 §E.3을 다시 판정합니다. 또는 기록을 AIAssistant 쪽 상태로 옮깁니다. |
| O-1 | 선택 | `:2908-2910` vs `:794`·`:806`·`:2058`·`:1856-1861` | `echoedPlaceToken`은 정확히 일치할 때만 거릅니다. 반면 뒤따르는 판정은 전부 `trimmedArg`나 trim 뒤에 비교합니다. `" __no_travel__"`처럼 공백이 붙은 에코는 R1을 지나 머무는 신호로 받아들여집니다. | 공백 붙은 토큰으로 `drvAsk` | `echoedPlaceToken`에서도 trim한 뒤 비교합니다. |
| O-2 | 선택 | `:1897` | `unresolvedQueryText`가 토큰을 인라인으로 두 개만 나열합니다. `currentLocationToken`이 빠져 있어, 위치를 잡지 못하면 모델에게 "'__current_location__' 위치를 찾지 못해"가 갑니다. aa7b792:1497부터 있던 문제이지만, 새 주석(`:2899-2902`)의 "여기가 단일 출처"와 맞지 않습니다. | 비머무는 활동, 가는 편 줄에서 '현재 위치' 선택, 위치 없음 | `isInternalPlaceToken`을 쓰고, 현재 위치 실패는 전용 문구로 안내합니다(create_schedule `:1671`과 같은 방식). |
| O-3 | 관찰 | `:1436-1455` | create_schedule·통근 반복의 on_conflict나 위치 권한 재시도 재호출은 base 때부터 카드가 떴습니다(수단·여유·알림이 선언 밖 키). R1 뒤에는 출발지 줄이 하나 더 붙습니다. 데이터는 맞습니다. | — | B-1을 고칠 때 함께 판단합니다. |
| O-4 | 관찰 | `:1228-1230`·`:2911-2918` | 확인 경로에 await 창이 새로 생겼습니다(최대 3초). 초기화 버튼(`AIChatView.swift:64`)은 생각 중에도 눌리므로, `[model(fc), function]`으로 시작하는 히스토리가 가능합니다. 다만 `runToolCalls`의 네트워크 await 창에도 이미 있던 종류입니다. | — | 초기화를 `isThinking` 동안 막는 별도 카드 후보입니다. |
| O-5 | 관찰 | `:1253-1256` | 도우미 주석은 "좌표를 모르는 선택은 실행부 50 m 절이 본다"고 적지만, 그 절이 받는 것은 문자열이 같은 선택뿐입니다(B-4와 같은 사실의 주석 측면). | — | B-4와 함께 고칩니다. |

## A-1~A-8 상태

| id | 상태 | 근거 |
|---|---|---|
| A-1 | **CHANGED** | 모델이 보낸 토큰 에코는 세 토큰·모든 키에서 닫혔습니다(`:963-967`). 그러나 정당한 재호출까지 지웁니다(B-1). 공백 변형이 빠져 있습니다(O-1). |
| A-2 | **CHANGED(부분 폐쇄)** | 로컬 앵커 × {즐겨찾기·확정 장소·현재 위치} 선택은 닫혔습니다. B-2·B-3·B-4가 남아 있습니다. |
| A-3 | OPEN(R3 새 카드로 이관, 문구 `:941` 무변경) | — |
| A-4 | OPEN(R3 이관, 프롬프트·선언·`stayingEndAsk` 바이트 동일) | — |
| A-5 | OPEN(R3 이관, `:2337` 무변경) | — |
| A-6 | OPEN(R2 이관) | — |
| A-7 | **CLOSED** | `:442`가 `(:433-436)`을 인용하고, 그 줄은 ask 카드 경로입니다. `:2145-2147`의 사용처 다섯은 실제 호출(`:1057`·`:1272`·`:1700`·`:1888`·`:2102`)과 일치합니다. |
| A-8 | **OPEN** | B-5와 같습니다. |

## 0건 판정과 표집 범위

- 선언 변화 0(설명 한 줄 제외) — toolsJSON 함수 전체(164줄), 세 커밋
- 소문자 타입 0 — 8ad3abd AIAssistant 파일 전체 `grep`
- 시스템 프롬프트 변화 0 — systemPrompt 함수 전체, 5fb6634 대 8ad3abd
- 새 모델 대상 문자열 0 — 5fb6634→8ad3abd AIAssistant diff의 `+` 줄
- 방어·히스토리 함수 본문 변화 0 — §0에 적은 15개 함수 중 sanitize를 뺀 14개, 5fb6634 대 8ad3abd `cmp`
- 끼어드는 user 턴 0 — `contents.append` 여섯 자리와 `isThinking` 가드 두 곳
- 프록시·project.yml 변화 0 — 경로 diff

## 실행한 명령과 핵심 출력 (발췌)

```
git diff aa7b792 8ad3abd -- proxy/ project.yml | wc -l                 → 0
diff tools-aa7b792 tools-8ad3abd                                         → 58c58 (origin_query description)
cmp tools-5fb6634 tools-8ad3abd ; cmp sys-5fb6634 sys-8ad3abd            → IDENTICAL ; IDENTICAL
git diff aa7b792 8ad3abd -- Shared/EditCard.swift | grep '^[-+][^-+]' | grep -v '^[-+][[:space:]]*///\?'
                                                                         → +    var clearedKeys: Set<String> = []
sed -n '/private func sanitizeModelArgs/,/^    }$/p' (aa7b792 vs 8ad3abd) → DIFF ; isSamePlace·executeListSchedules → SAME
awk 1267 → let anchorQuery = Self.trimmedArg(preInjection, anchorKey),
awk 1887-1889 → if stayingOneShotActivity(input), let pickedFrom = from, let place, … from = nil
awk 1901 → if from == nil, let t = unresolvedQueryText("travel_from_query", "가는 편 출발지") …
awk 546  → if !filled("origin_query") { fields.append(originField()) }   (638-643: 즐겨찾기+현재 위치, '이동 없음' 없음)
grep contents.append (5fb6634 / 8ad3abd) → 205·305·419·438·468·1222 / 205·305·419·438·468·1245
grep '"place_query": "회사",' Tools/GuardDriver.swift → 2804 (AC-D5) ; 거리 ≈ 1418 m
```

## 미검증(갭)과 남는 위험

- **갭**
  - B-1~B-5의 재현은 모두 코드를 읽어 추론한 것입니다. 드라이버나 하네스로 관측하지 않았습니다(임무 제약).
  - 판정자가 재현 하네스에 B-1 ①~③과 B-3 절차를 더해 실행으로 확인하기를 권합니다.
  - 모델이 재호출에서 토큰을 실제로 되울리는지, 반복 주기 인자를 잘못 채우는 빈도도 관측하지 않았습니다.
  - 드라이버 310/310은 run 레인 로그 기준이고, 이 렌즈는 다시 돌리지 않았습니다.
- **남는 위험**
  - B-1의 방아쇠(`recurringArgumentIssue`, 해석되지 않는 시각 문자열)는 모델 오류를 거쳐야 닿습니다. 그 오류들은 과거에 관측돼 가드가 생긴 종류입니다.
  - B-4를 SPEC 개정으로 닫으면, 검색 장소에서 머무는 요청을 하며 현재 위치를 고른 경우 약 0분 이동이 생기는 동작이 문서화된 잔여 위험으로 남습니다.
