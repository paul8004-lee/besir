# t16 sync 재심사 렌즈 — code-safety --deep 2회차 (원문 보관)

- 대상: 브랜치 `WT-place-resolution` HEAD `894fdc1`(코드 = `8ad3abd`), 1차 판정 `7a1b171`
- 수행: 2026-09-28, sync 레인이 띄운 읽기 전용 렌즈(`hns-besir-app-code-safety-specialist`, **model: sonnet**). run 레인과 다른 손이다.
- **첫 시도는 결과 없이 끝났다** — 같은 프롬프트의 opus 스폰이 세션 사용량 한도(HTTP 429, 리셋 17:50 KST)로 도중에 종료돼 아무것도 돌려주지 않았다. 통과로 세지 않았고, 한도가 다른 모델로 한 번 다시 띄운 것이 이 반환문이다(공용 메모리의 429 대처 순서).
- 제약: 파일 수정·빌드·드라이버·npm 금지. 판정은 코드 읽기에 근거한다. C-1·C-2·C-3의 **실행 재현**(5fb6634 대조 포함)은 sync 레인이 따로 했고 결과는 `sync-verdict.md` §R2에 있다.

---

## 판정: FIX-FIRST

8ad3abd(D1~D5 수리)가 이전 4건(S-1~S-4)의 **좁은 재현 경로**는 정확히 닫았지만, 새로 만든 `stayingTokenForColocatedPick`/`locallyResolvedPlace` 게이트 자체가 국소적(로컬 두 단만 봄)이라 **D3 원래 결함이 일반적인 입력에서 그대로 재발**합니다(C-1, 확신). 여기에 새로 생긴 await가 대화 초기화 버튼과 경쟁하는 새 H1급 결함(C-2)과, D1이 명시적으로 노린 토큰 필터가 형제 함수 하나를 못 옮긴 잔여 누수(C-3)를 더했습니다. 드라이버 310/310은 세 결함 모두를 검사하지 않습니다 — AC-D3의 세 시나리오(ac4/ac5/ac6)가 전부 `place_query:"집"`(즐겨찾기)만 앵커로 써서, "즐겨찾기에 없는 장소"라는 가장 흔한 경우를 표본에서 빼먹었습니다.

## 발견 (심각도순, 전부 8ad3abd = HEAD 894fdc1)

| id | 등급 | 위치 | 무엇이 깨지나 | 재현 | 수리 모양 |
|---|---|---|---|---|---|
| **C-1** | **BLOCKING** | `Shared/AIAssistant.swift:1258-1274`(stayingTokenForColocatedPick), `:1279-1282`(locallyResolvedPlace), 실행 차단 `:1840-1842`(create_activity)·`:2035-2036`(recurring) | `locallyResolvedPlace`는 즐겨찾기·`confirmedPlaces` 두 단만 본다. 활동 장소(`place_query`/`destination_query`)가 **즐겨찾기에 없는 실제 장소명**이면 앵커가 로컬로 안 풀려 `stayingTokenForColocatedPick`이 `nil`을 돌려주고 토큰 교체가 안 된다. 이때 `:1887`("마지막 방어선")·`:2102`의 `isSamePlace` 실행부 폴백은 **닿지도 못한다** — 그 앞의 `missingAskedArguments`(:1840·:2035)가 `stayingOneShotActivity(input)`을 문자열로만 판정해 먼저 거절하기 때문이다(place 해석·검색은 이 거절 뒤에나 시작됨). | 발화: "OO빌딩 로비에서 점심"(place_query="OO빌딩 로비", 즐겨찾기 아님) → 머무는 카드가 출발지 줄만 물음 → 사용자가 **"현재 위치"**를 고름(가장 자연스러운 선택) → 확인 → `stayingOneShotActivity(input)`이 `"__current_location__" != "OO빌딩 로비"`로 거짓 → `missingAskedArguments`가 "이동수단, 도착 여유, 알림이(가) 비어 있어요"로 거절. D3가 고치려던 바로 그 증상이 그대로 재현된다. | `stayingTokenForColocatedPick`의 앵커 해석에 `adoptPlace`(네트워크 포함 전체 사다리)를 쓰거나, `missingAskedArguments`가 실행부의 `isSamePlace` 폴백보다 먼저 돌지 않게 순서를 바꾼다(예: place 해석 뒤로 이동). AC-D3에 즐겨찾기 아닌 앵커 시나리오 추가. |
| **C-2** | **BLOCKING** | `Shared/AIAssistant.swift:1176-1247`(resolvePendingAsk), `Shared/AIChatView.swift:63-68`(새 대화 버튼) | 이 diff가 `resolvePendingAsk`에 **처음으로** await(`stayingTokenForColocatedPick`→`currentPlace`, 위치 미획득 시 최대 3초)를 넣었는데, 그 await **뒤에** `contents.append(["role":"model",...])`(:1245)가 있다. `confirmAsk`는 `isThinking`을 이 구간 내내 켜 두고(:1154) `send`(:271)·카드 자체 확인 버튼은 이걸로 막히지만, **AIChatView의 "새 대화 시작" 툴바 버튼(:64)은 `isThinking`으로 `.disabled`되지 않는다.** | 머무는 카드에서 "현재 위치"를 고르고 확인 → GPS 미획득으로 최대 3초 대기 중 사용자가 "새 대화 시작"을 탭 → `resetConversation()`이 `contents=[]`·`bubbles=[인사말]`로 즉시 갈아엎음 → await가 끝난 옛 실행 컨텍스트가 그 뒤 `contents.append`로 **리셋된 새 대화의 첫 항목에 role:model을 꽂고**, `runToolCalls`가 그대로 실행돼 사용자가 버렸다고 믿은 등록이 조용히 완료된다. | 새 대화 버튼에 `.disabled(assistant.isThinking)` 한 줄(기존 send 버튼과 같은 패턴) — 최소 수정. 근본 수리는 `resolvePendingAsk`가 await 뒤 `contents`/`bubbles`의 세대(generation)를 재검증하는 것(H1 기존 패턴 — `setLookup`의 "줄 id로 다시 찾고 없으면 버린다"와 같은 결). |
| **C-3** | **BLOCKING** | `Shared/AIAssistant.swift:1895-1899`(unresolvedQueryText), `:2903-2904`(isInternalPlaceToken, 이 diff가 만든 단일 출처) | D1이 "토큰 낱말을 세 곳에 나열하면 하나만 고쳐지는 날이 온다"며 `isInternalPlaceToken`을 만들었는데, `unresolvedQueryText`는 여전히 자체 두 토큰짜리 인라인 필터(`q != noOutboundToken, q != noTravelToken`)를 쓴다 — `currentLocationToken`이 빠졌다. | 머무는 카드에서 "현재 위치"를 골랐는데 **위치 권한 거부·GPS 타임아웃**으로 `resolve()`(:1866-1867)가 끝내 `nil`을 돌려주면 `from==nil` → `unresolvedQueryText("travel_from_query",...)`가 `"__current_location__"`을 그대로 통과시켜 `"가는 편 출발지 '__current_location__' 위치를 찾지 못해..."`가 모델 쪽 텍스트로 나간다(S-1과 같은 노출 종류, 다른 함수). | `unresolvedQueryText`의 필터를 `!Self.isInternalPlaceToken(q)` 하나로 바꾼다. |
| **C-4** | OPTIONAL(=B-2 확인) | `:1887-1889`(isSamePlace 폴백)·`:1901`(unresolvedQueryText 호출) | `:1887-1889`은 로컬 변수 `from`만 `nil`로 바꾸고 `input["travel_from_query"]`(원본 문자열)는 그대로 둔다. `unresolvedQueryText`는 `input`을 다시 읽으므로, 이 폴백이 잡아준 경우도 거짓 "찾지 못해" 문구가 붙는다. | 모델이 카드 없이 **직접** `create_activity(place_query:"집", travel_from_query:"집")`을 한 번에 보내는 경로(문자열이 이미 같아 카드가 안 섬) — S-2가 확인-카드 갈래만 닫히고 이 직접-호출 갈래는 열려 있다. | :1889에서 `from=nil`로 바꿀 때 같은 지역에서 "이번 nil은 의도된 것"이라는 표시를 남기거나(플래그), `unresolvedQueryText` 호출 전에 이 케이스를 걸러낸다. |

## B-1~B-4 (ai-tooling 렌즈) 동의 여부

- **B-1** (R1이 `confirm_recurrence` 재호출의 정상 토큰까지 지운다) — **AGREE.** `confirm_recurrence`는 모델이 **같은 인자를 그대로** 재전송해야 인정되는 계약(:2256-2285)인데, `sanitizeModelArgs`(:960-967)는 모델 턴의 모든 함수 호출에 무조건 `echoedPlaceToken` 필터를 적용해 "앱이 재전송을 기대하는 값"과 "히스토리 에코"를 구분하지 못한다.
- **B-2** (실행부 50m 폴백이 여전히 해석 실패로 집계된다) — **AGREE.** 독립적으로 `:1887-1889`↔`:1901`을 추적해 C-4로 확인. `stayingTokenForColocatedPick`이 성공한 정상 경로는 이미 토큰으로 바뀌어 안전하지만, 폴백 갈래(:1887-1889) 자체는 원본 문자열을 바꾸지 않아 거짓 실패가 남는다.
- **B-3** (앵커를 주입 전 인자로 읽어 같은 카드에서 답한 앵커 줄을 놓친다) — **AGREE(구조상 타당, 직접 재현 안 함).** `preInjection`은 두 번째 루프 시작 전에 한 번 스냅숏되고 갱신되지 않으므로(:1196), 같은 카드에서 `place_query` 자체도 묻는 시나리오라면 그 답이 `args`엔 반영돼도 `preInjection`엔 없다 — 다만 create_activity 한 카드에 `place_query`와 `travel_from_query`가 동시에 미해결로 묶이는 정확한 입력 조합은 이번에 직접 만들어보지 않았다.
- **B-4** (앵커가 로컬 검색 불가면 절대 co-locate 안 된다) — **AGREE, 더 심각.** 내가 확인한 바로는 "co-locate 실패"가 단순히 최적화 기회를 놓치는 게 아니라 **:1887 폴백이 원천적으로 도달 불가**(C-1)라 D3 원래 버그가 그대로 재발한다.

## H1~H4 — 재확인 (2026-09-12/16 스냅숏 신뢰 안 하고 이 diff에서 직접 재검사)

- **H1.** 이 diff가 추가한 `await`는 정확히 둘(`git diff 5fb6634 8ad3abd | grep '^+.*await'` → :1228-1230, :1269 상당). `resolvePendingAsk`의 `idx`는 await 전(:1185)에만 쓰여 그 자체는 안전하지만, await **뒤**의 `contents.append`(:1245)가 `isThinking`으로 안 막히는 UI 액션(새 대화 버튼)과 부딪힌다 — C-2로 보고.
- **H2.** `git diff 5fb6634 8ad3abd -- Shared/AIAssistant.swift Shared/EditCard.swift | grep '^+' | grep -E 'Task \{|try\?|as!'` → **0건**. 이 diff는 fire-and-forget·강제 언래핑을 새로 만들지 않았다.
- **H3.** 새 헬퍼(`locallyResolvedPlace`)는 `store.favorites`(사용자 관리, 상한 있음)와 `confirmedPlaces`(대화 범위, 기존 상한 로직 그대로)만 읽는다. 새 무한 증가 상태 없음.
- **H4.** `adoptPlace`가 `locallyResolvedPlace`로 시작하도록 통합된 것은 **좋은 방향**(중복 제거, 계약 5 이행)이지만, `isInternalPlaceToken`을 "단일 출처"로 선언해 놓고 `unresolvedQueryText`를 옮기지 않아 **새 중복**을 하나 남겼다(C-3).

## 0건 판정의 표집 범위

- H2 0건: `Shared/AIAssistant.swift`·`Shared/EditCard.swift`의 5fb6634→8ad3abd diff 추가(`+`)줄 전체(218줄) 대상. `Tools/GuardDriver.swift` 추가분(186줄, 테스트 코드)은 표집하지 않음 — 테스트 코드의 H2류는 실기기에 영향 없음.
- H3 0건: 이 diff가 새로 추가한 두 함수(`stayingTokenForColocatedPick`, `locallyResolvedPlace`)만 표집. 기존 코드의 한도 방어는 재검사하지 않음(이미 이전 렌즈가 검사).
- C-1~C-4의 재현은 전부 **코드 읽기 기반**이며 드라이버·빌드·시뮬레이터로 실행 검증하지 않았다(제약).

## 검사한 클래스 — 아무것도 못 찾은 것

- H2(조용한 실패), H3(외부 한도), 강제 언래핑/캐스트: 이 diff의 추가분 전체를 읽고 0건 확인.

## 검사하지 못한 것 (이유)

- **드라이버·빌드·npm 재실행.** 임무 제약 — sync 레인이 이미 격리 사본에서 296/217/310 등 독립 재실측 완료(`sync-verdict.md` §1). 내 발견은 전부 실행으로 재검증되지 않았다.
- **B-3(앵커 co-답변 동시성)의 실제 두 필드 동시 미해결 카드.** 코드 구조로는 타당하나 정확한 모델 호출 인자 조합을 손으로 짜서 추적하지 않았다.
- **`create_recurring_schedule` 쪽 C-1의 완전 등가성.** `stayingRecurrence`(:773-778)가 origin/destination 양쪽 비지 않고 문자열 일치를 요구해 create_activity와 트리거 조건이 다르다 — 같은 `locallyResolvedPlace` 게이트를 공유하는 것은 확인했지만 카드-빌드 시점에 origin_query가 빈 채로 "머무는 카드"가 서는 정확한 조건은 재확인하지 않았다.
- **모델의 실제 재호출 빈도(B-1의 confirm_recurrence 실제 발생률), GPS/권한 실패의 실제 발생률(C-2·C-3의 현실 빈도).** 실기기·시뮬레이터 관측 영역, AC-014/015로 이월된 상태 그대로다.
- **EditCardView 렌더 실동작, 문서 인용 드리프트.** 임무 범위 밖.
