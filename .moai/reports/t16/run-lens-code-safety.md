# SPEC-UIKIT-008 (card t16) — run-phase code-safety lens

- 일시: 2026-09-26 · 판정 레인: code-safety (읽기 전용)
- 대상 트리: `WT-place-resolution` HEAD `dbdb5b9` · diff 범위 `git diff aa7b792 HEAD -- Shared/ Tools/`
- 재료: `Shared/AIAssistant.swift`(+649/−84) · `Tools/GuardDriver.swift`(+837/−1) · `Shared/EditCardView.swift`(+12/−2) · `Shared/EditCard.swift`(주석 1줄) · `.moai/specs/SPEC-UIKIT-008/{spec,acceptance,progress}.md` · 게이트 로그 `.moai/state/verify/t16/`
- 방법: diff 헝크 전수 → 의심 지점마다 현재 트리에서 주변 함수 통돌(`runLoop`·`confirmAsk`·`resolvePendingAsk`·`pendingAsk`·`parkForUnclearPlaces`·`askFields`·`executeCreateSchedule`·`executeCreateActivity`·`executeCreateRecurringSchedule`·`makeStayingRecurrence`·`adoptPlace`·`resolveOriginAdoption`·`resolveOrigin`·`searchTopClearlyMatches`·`executeUpdateRecurringSchedule`·`EditCardView.fieldRow/placeSearchEditor`·GuardDriver AA/AB절). 드라이버 재실행 없이 게이트 로그 판독으로 대체(임무 제약).

## 판정

**FAIL — 차단 1건 (F-1).** 레인 권고: F-1은 `confirmAsk`에 `:446`과 같은 미러 가드 한 줄로 닫히는 자리다. 수정 후 드라이버(296 유지 또는 단언 1건 추가)·양측 빌드만 다시 돌리면 된다. F-2~F-4는 후속 카드·기록으로 넘겨도 된다.

## Charter coverage — 네 부류 + 간결성

| 부류 | 무엇을 봤는가 (함수/줄) | 판정 |
|---|---|---|
| H1 await 인덱스 무효화 | `executeCreateSchedule` :1600-1650(삼태 갈래), `executeCreateActivity` :1777-1840(resolve 클로저·50m 교체), `executeCreateRecurringSchedule` :1985-2040, `makeStayingRecurrence` :1916-1948, `parkForUnclearPlaces` :903-941, `resolvePendingAsk` :1162-1220, `adoptPlace`/`resolveOriginAdoption` :2795-2865, `setLookup` :1090(기존 패턴) | 0건 — 통과. 새 await 지점 전수에서 대기 전에 잡은 인덱스·식별자의 재사용이 없다. unclear 배열은 append-only, fields firstIndex(park :929)는 동기 구간 안, makeStayingRecurrence는 생성 뒤 rid 필터로 다시 읽고(:1931-1933) id로 찾는다. |
| H2 조용히 묻히는 실패 | 후보 카드 주차(park :903), 확인 주입(resolvePendingAsk :1183-1212 빈 키 선주입), D-5 턴 종료(runLoop :446), 머무는 요청 확인(원샷 50m 교체 :1830-1836), end-time-first 게이트(executeCreateActivity :1755-1758, executeCreateRecurringSchedule :1990-1996, makeStayingRecurrence :1917-1919), executeUpdateRecurringSchedule 머무는 그룹 문구 :2260-2270, resolveOrigin 래퍼의 unclear→first 평탄화 :2792-2800(조회 경로 전용 의도) | 발견 3건 — F-1(차단)·F-2·F-3. 주차·주입·end-time 게이트·점심 인자 낱명(:1941-1945)·거짓 "이미 삭제" 문구 제거는 드라이버 단언과 읽기가 일치한다. 빈 구멍은 카드가 열려 있는 채 모델을 부르는 확인 창(F-1)과 그 창의 곁가지(F-2·F-3)다. |
| H3 무한 증가·외부 한도 | makeStayingRecurrence(weeks→Store.addRecurringActivities Store.swift:244 min(max(weeks,1),26)), 후보 수(adoptPlace results.prefix(maxPlaceSuggestions) 5건), 카드 한 장 가드(:908), 활동 블록 알림 예약 여부(Store.swift:235-261 — 로컬 알림 없음, 캘린더 업로드는 큐 1회), bubbles/contents 증가 양상(기존 — trimHistory·cancelPendingAsk로 상환) | 0건 — 통과. 머무는 반복 블록 수는 통근 반복과 같은 26주 상한(활동은 로컬 알림 64건 한도에 닿지 않는다 — 알림은 events 경로만). 후보 lookup은 5건 상한. 새 무한 상태 없음. |
| H4 복제된 계산 | 카드 문자열 판정(stayingRecurrenceSignal :788-796) vs 실행부 50m(isSamePlace) — REQ-010이 수용한 분리(보고하지 않음). 그 밖: placeRow :740-749(줄 재료 단일 출처), filledValueLabels :873-895(맥락 줄 — 실행 전·후보 두 경로가 같은 함수), trimmedArg :815-822(부재 판정 단일 통로), weeksArgument :2163(weeks 읽는 단 한 곳), searchBoundPlace :756-762(unresolvedGenericPlace 재사용), EditCardView placeSearchOpen :89(술어 1곳, 칩 생산자 2곳이 함께 읽음 :120·:127) | 0건 — 통과(수용 분리 제외). 명세가 지정한 세 후보(되묻기 술어·맥락 줄·편집기 열림 술어)가 전부 한 곳에서 나온다. stayingOneShotActivity도 카드(askFields)와 실행부(50m 교체 :1831)가 같은 함수를 부른다. |
| 간결성 (죽은 코드·루프 내 반복 쓰기·일 많은 함수) | resolveOrigin 호출처(:2601 하나 — M6 기본값 갈래 제거 완료), stayingRecurrence 호출처(:795 하나 — stayingRecurrenceSignal 전용), UnclearPlaceList(정의 1 + AIAssistant 4 + GuardDriver 1 — 날 튜플 0), statedLabels(pendingAsk :856 생존), 캡션 함수 셋(unclearPlaceNote·sameNamePlaceNote·stayingOriginNote — 각 1~2 호출처), 루프 내 저장(makeStayingRecurrence — addRecurringActivities 내부 1회 save), 강제 언래핑/캐스트(diff 전수) | 0건 — 통과. M6가 정리한 죽은 가지가 실제로 정리됐고 이 카드가 새로 만든 죽은 코드는 없다. 새 강제 언래핑·캐스트 없음. GuardDriver AA/AB절은 단언마다 근거 주석을 달아 파일 관례를 따른다. |

### 게이트 로그 대조 (재실행 대신 판독)

- 드라이버: gate-driver.log 마지막 줄 `296/296 통과` · `[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다` — progress §E.2 M6와 일치.
- 컴파일 경고: `grep -c 'warning:' gate-compile.log` = 24 (base 동일 — MapKit·CoreLocation 지원중단 12진단+12캐럿) — 일치.
- iOS·macOS: ios.log·macos.log 각 `** BUILD SUCCEEDED **` 1 — 일치.
- 프록시(재실행 안 함): `git diff --name-only aa7b792 HEAD`에 proxy/ 0건 — 코드 무변경이므로 progress 기록 7/7을 근거로 쓴다.

### 계약 6종

1. 와이어 포맷 — `grep -c '"type": "[a-z]' Shared/AIAssistant.swift` = 0. 선언 변경은 origin_query 설명 1줄(후보 채택분)뿐. 유지.
2. 비밀값 — 앱 측 변경 없음. 유지.
3. Store 단일 허브 — `git diff aa7b792 HEAD -- Shared/Store.swift` 빈 출력. 유지.
4. 새 AI 클래스 없음 — 선언 키 무변경, 카드 전용 토큰(noTravelToken)은 선언 밖 키. 유지.
5. 같은 계산 두 곳 금지 — 위 H4 행 참조. 유지.
6. 색 토큰 — 새 UI 줄은 .foregroundStyle(Theme.muted)(EditCardView :324). 유지.

추가: isSamePlace 본문·sanitizeModelArgs 본문 base와 diff 무출력(무변경 확인). REQ-013 파일 범위 — 변경 파일 목록이 선언 집합과 정확히 일치(plan 커밋 예외분 포함).

## Findings

### F-1 (차단) D-5 턴 종료 가드가 runLoop 창에만 닿는다 — 확인(confirm) 창에서는 후보 카드가 열려 있는 채 모델이 호출된다

- Where: Shared/AIAssistant.swift:1146-1148(confirmAsk — resolvePendingAsk 뒤 무조건 runLoop(seed:)) · :1219(resolvePendingAsk가 실행부를 직접 돌림 — 이 안에서 parkForUnclearPlaces :936이 카드#2를 단다) · :446(runLoop의 가드는 runToolCalls 뒤에만 있다) · :846(pendingAsk는 한 장 가드가 없다)
- How it breaks — 도달 경로가 설계돼 있다(AC-003 10번 조합 = 드라이버 `AB-H01 머무는 반복 목적지 모호('이동 없음' 뒤)`, 시뮬레이터 스크립트 3·4번):
  1. 머무는 요청 카드#1에서 사용자가 '이동 없음'을 골라 확인 → resolvePendingAsk가 실행부를 돌린다 → 목적지가 검색에 맡겨진 값이면 parkForUnclearPlaces가 후보 카드#2를 달고 파크 문구를 결과로 돌려준다.
  2. confirmAsk는 summary를 받아 곧장 runLoop(seed:)를 부른다 — runLoop는 callAI로 즉시 모델을 호출한다(:388). :446의 가드는 이 루프의 runToolCalls 뒤에만 있으므로 확인 창에서는 카드가 열려 있는 채 모델이 돈다.
  3. 결정적 위반: 모델이 텍스트로 답하면 그 말풍선이 카드#2 아래에 붙는다 — REQ-005 "shall end that model turn without calling the model again" · AC-004 (2) 사람 절("카드 아래에 모델 말풍선이 붙지 않는다") 위반이 모델 순응 여부와 무관하게 매번 일어난다.
  4. 확률적 위반(이중 등록): 모델이 "인자를 바꿔 다시 호출하지 말고 기다려"를 무시하고 목적지를 명확한 이름으로 바꿔 재호출하면 — 이 문제 행동이 바로 parkForUnclearPlaces 중복 가드 주석(:905-906)과 H-2 재현의 전제다 — 그 재호출은 등록에 성공한다(카드가 열려 있어도 값이 찬 호출은 pendingAsk·askFields가 막지 않는다). 사용자가 이후 카드#2를 확인하면 같은 요청의 레코드 2건. 드라이버 AB-H03 [경로 제거] 특성화(h3Total == 2)가 보존한 실행부 모양이 앱에서 재현되는 것 — 그 단언의 "앱에서는 닿지 않는다"(:469 상세 문구)는 runLoop 창에만 참이고 확인 창에서는 거짓이다.
  5. 곁가지: 같은 창에서 모델 재호출이 인자를 비워 오면 pendingAsk(:846, 가드 없음)가 카드#3을 얹는다 — 카드#2는 화면에 남되 필드 id 불일치로 탭이 무시되는 "보이는데 안 되는 카드"가 된다(choose·submitCustom은 bubbles.lastIndex(ask != nil)만 본다, :1106).
- Fix (적용하지 않음): confirmAsk에서 resolvePendingAsk() 뒤에 :446과 같은 미러를 둔다 — `guard let summary = await resolvePendingAsk() else { return }` 바로 다음에 `if bubbles.contains(where: { $0.ask != nil }) { return }`. 확인 실행 중 다음 카드가 서면 그 턴은 카드가 표면이 된다(주 경로 :433-435와 같은 모양). 이 한 줄로 4·5가 함께 닫힌다(확인 창이 유일한 진입로다 — submit은 cancelPendingAsk :290로 카드를 먼저 접는다). 모델 루프는 드라이버 밖이므로 회귀 방지선은 AC-004 (2)의 코드 대조 형식(progress §E.2에 함수·줄번호 기록)으로 남긴다.
- Confidence: 코드 경로 읽기로 확정(1·2·3은 결정적 — 모델 순응 무관; 4는 이 모델의 문서화된 비순응 행동 전제, 프로젝트 하네스가 같은 전제로 가드를 여러 개 두고 있다).
- 근거 조항: REQ-005 (두 문장 모두) · AC-004 (2) · SPEC §1.4 "보류 뒤 루프 지속" · 공용 메모리 feedback_besir_dormant_hazard(머무는 반복 경로가 잠복 경로를 깨우는 모양 — 이번엔 park가 확인 창을 깨웠다).

### F-2 (선택) 혼합 배치에서 첫 호출의 등록 문구가 카드 때문에 사라진다

- Where: Shared/AIAssistant.swift:439-446 — runToolCalls가 한 턴에 두 호출을 실행해 call#1 등록 성공·call#2 후보 카드면 :446이 lastToolSummary(call#1의 등록 완료 문구 포함)를 버린 채 return한다.
- How it breaks: 한 발화에 모델이 호출 둘을 내면 call#1은 이미 등록됐는데 화면에는 후보 카드만 남는다. 사용자는 카드#2를 확인하고 모델 마무리 문구가 나올 때까지 첫 등록 사실을 채팅에서 볼 수 없다(기록·캘린더에는 존재). t16 이전에는 pendingAsk가 실행 전에 두 호출의 빈 인자를 함께 모아 이 "부분 실행 + 카드" 상태가 생기지 않았다 — park가 실행부 안으로 옮기면서 생긴 새 양상이다.
- Fix (적용하지 않음): :446에서 return하기 전에 파크 문구가 아닌 앞 호출의 등록 요약을 별도 말풍선으로 남기거나 카드의 stated에 실는다. 등록 자체는 성공이므로 후속 카드(t30)에서 풀어도 된다.
- Confidence: 확정(코드 읽기 — 사용자 노출 지연이지 데이터 소실 아님).

### F-3 (선택) 후보 중복 가드 문구가 다른 질의에도 "같은 질문의 카드"라고 말한다

- Where: Shared/AIAssistant.swift:909 — "등록하지 않았어요 — 이미 같은 질문의 카드가 열려 있어요. …"
- How it breaks: 이 가드는 모든 후속 모호 호출에 답한다(드라이버 AB-H02 픽스처처럼 목적지가 다른 호출 포함). 질의가 다르면 "같은 질문의 카드"는 사실이 아니다 — 모델이 이 문구를 사용자에게 옮기면 "방금 그 질문은 이미 물어봤다"는 거짓 전달이 된다. H-2 수리의 취지(거짓 "자동 진행" 대신 사실대로)에서 문구 하나가 미끄러진 자리다.
- Fix (적용하지 않음): "이미 다른 등록 확인 카드가 열려 있어요" 정도로 질의 동일성 주장을 뺀다. 드라이버 단언(AB-H02 두 줄 — "자동으로 진행" 부재·"등록하지 않았"/"다시 호출" 존재)은 그대로 통과하는 문구다.
- Confidence: 확정(문구·가드 조건 읽기).

### F-4 (선택·잔여 위험) noTravelToken("__no_travel__")이 히스토리에 남아 모델 에코에 노출된다

- Where: Shared/AIAssistant.swift:2831-2835(토큰 선언과 "모델은 보낼 수 없다" 주석) · 확인 뒤 히스토리 적재 resolvePendingAsk :1218(토큰이 실린 model 턴) · 신호 판정 stayingRecurrenceSignal :794(토큰 → 무조건 머무는 신호) · 실행부 :1994(stayingTokenOrigin → 출발지 해석 생략)
- How it breaks: 주석의 "도구 선언에 이 값이 오는 자리가 없으므로 모델은 보낼 수 없고"는 최초 주입에만 참이다. 확인 뒤 토큰이 실린 model 턴이 contents에 남고, 이 모델은 본 적 있는 인자를 채워 보내는 문서화된 습관이 있다(결함 K·H-8). 이후 다른 목적지의 반복 호출 origin_query에 토큰이 에코되면 stayingRecurrenceSignal이 참이 되어 출발지를 아무에게도 묻지 않은 채 머무는 반복으로 굳는다 — REQ-010 "출발지 = 목적지는 사용자의 선택으로만 확정"에 어긋나는 등록. 기존 토큰 둘(currentLocationToken·noOutboundToken)과 같은 노출 양상이지만 그 둘은 좌표 조회·구간 생략의 국소 효과인 데 반해 이 토큰은 등록 전체 모양(통근→머무는 반복)을 바꾸는 힘을 갖는다.
- Fix (적용하지 않음): 당장은 기록으로 남긴다(토큰 에코는 관측된 적 없다). 방어 후보: origin_query에 토큰이 와도 destination_query와 문자열이 같지 않으면(머무는 요청의 원 정의와 어긋나면) 출발지 줄을 다시 띄워 사용자 선택을 받게 한다 — stayingRecurrenceSignal의 토큰 갈래에 stayingRecurrence(args) 동시 충족 조건을 거는 것이다. t30·AC-014 실기기 확인 항목에 넣는 것을 권한다.
- Confidence: 의심(에코 경로는 재현된 적 없음 — 코드 읽기 기반 잔여 위험. 노출 메커니즘 자체는 확정).

## 검사했고 발견 없음 (classes checked, nothing found)

- H1(await 인덱스) — 위 표의 함수 전수. makeStayingRecurrence의 rid 재조회가 이미 올바른 패턴.
- H3(외부 한도) — weeks 26주 상한·후보 5건·카드 1장·활동 블록 무알림. 새 무한 상태 없음.
- H4(복제 계산) — REQ-010 수용 분리 제외 전부 단일 출처(placeRow·filledValueLabels·trimmedArg·weeksArgument·placeSearchOpen·searchBoundPlace).
- 간결성 — 죽은 코드 0(M6 정리 재검증 포함), 루프 내 반복 저장 0, 새 강제 언래핑/캐스트 0, 일 많은 함수 신규 0.
- 계약 1·3·4·5·6 — grep·diff로 무변경 확인(위 표). isSamePlace·sanitizeModelArgs·resolveOrigin 사다리 본문 무변경.
- 게이트 로그 진위 — driver 296/296·경고 24·양측 BUILD SUCCEEDED, 전부 로그와 대조 일치.

## 검사하지 않은 것 (classes not checked) — 이유 명시

- 드라이버·iOS·macOS 빌드·프록시 테스트 재실행 — 임무 제약("gate logs exist"). 로그 판독과 git diff --name-only로 근거를 대체했다.
- 사람 증거(AC-014·015 시뮬레이터 1~20번) — 이 렌즈는 코드 판정 렌즈다. F-1의 결정적 위반(카드 아래 말풍선)은 스크립트 3·4번에서 관측될 것으로 예상된다 — ux-check에 넘긴다.
- 모델 루프 실동작(callAI 응답 분포·재호출 빈도) — 드라이버가 프록시를 비우는 구조적 한계(SPEC §0이 이미 명시). F-1의 4·5는 이 한계 안에 있는 발견이다.
- EditCardView 나머지 렌더 경로(시각 줄 :206 selected: true 등) — M5 범위 밖 무변경 확인(diff 헝크 3개뿐)으로 충분했다.
- 루트 plan.md·CHECKLIST.md 인용 재사상(REQ-015) — sync 레인 몫. 이 렌즈는 코드만 판정했다.
