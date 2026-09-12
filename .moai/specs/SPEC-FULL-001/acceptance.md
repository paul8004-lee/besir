# SPEC-FULL-001 — acceptance.md

Day 11(코드 검사)·Day 12(실기기 테스트) 체크리스트를 Given-When-Then AC로 전개한다. plan.md M5/M6에 대응. 두 Day 모두 아직 실행 전이라 원칙적으로 전부 ⬜지만, AC-104(FullSirView.save 재조회 방식)는 근본 질문이 spec.md §3/REQ-015(구 REQ-032)로 이미 코드에서 해소된 상태라 별도로 표시한다.

> **REQ 번호 안내(v0.3.0)**: 이 문서의 REQ 인용은 전부 v0.3.0 재넘버링(REQ-001~018) 기준이다. 구 번호와의 매핑은 spec.md HISTORY 아래 "REQ 번호 재매핑" 표 참고.

## 1. AC 매트릭스 — Day 11 코드 검사 (plan.md M5)

| AC | 상태 |
|---|---|
| AC-100 | ✅ PASS (2026-09-12, 코드 검사 완료 — 아래 근거) |
| AC-101 | ✅ PASS |
| AC-102 | ✅ PASS |
| AC-103 | ✅ PASS |
| AC-104 | ✅ PASS (근본 질문 + 검사 둘 다 완료) |
| AC-105 | ⚠️ 측정 불가(정적 검사 한계) — 아래 참고, 라이브 측정 필요 |
| AC-106 | ✅ PASS |
| AC-107 | ✅ PASS |
| AC-108 | ✅ PASS |
| AC-109 | ✅ PASS |
| AC-110 | ✅ PASS (신규 — v0.3.0 D4, REQ-001 추적성 보완) |
| AC-111 | ✅ PASS (신규 — v0.3.0 D4, REQ-004 추적성 보완) |
| AC-112 | ✅ PASS (신규 — v0.3.0 D4, REQ-008 추적성 보완) |
| AC-113 | ✅ PASS (신규 — v0.4.0 이터레이션3, REQ-003 추적성 보완) |
| AC-114 | ✅ PASS (신규 — v0.4.0 이터레이션3, REQ-009 추적성 보완) |
| AC-115 | ✅ PASS (신규 — v0.4.0 이터레이션3, REQ-011 추적성 보완) |
| AC-116 | ✅ PASS (선언적 REQ — 신규 — v0.4.0 이터레이션3, REQ-018 추적성 보완) |

### AC-100 — MealLog JSON 왕복·디코드 실패 범위 확인 (신규 — Day 6 데이터모델군 추적성 보완)

**Given** `meals.json`에 알 수 없는 `category` 값을 가진 레코드 하나가 섞여 있는 상태(수동으로 파일을 편집해 재현)
**When** 앱을 실행해 `Store.loadMeals()`가 이 파일을 읽으면
**Then** 배열 전체 디코드가 실패해 `meals`가 그 시점 메모리 값(보통 빈 배열 또는 이전 로드값)으로 남는다는 것을 확인한다 — "그 레코드만 스킵되고 나머지는 유지된다"는 동작이 **아님**을 확인한다(REQ-002 정정 내용의 실측 검증). 이 동작이 `events`/`activities`/`favorites`와 동일한 기존 패턴임도 함께 확인한다(코드 검사로 충분 — 실기기 불필요).

**검사 결과(2026-09-12, 코드 읽기로 확인)**: `Store.swift`의 `loadMeals`/`loadActivities`/`loadEvents`/`loadFavorites` 4곳 전부 동일하게 `try? JSONDecoder().decode([T].self, ...) else { return }` 패턴 — 배열 전체 디코드-또는-포기, 레코드 단위 격리 없음을 확인. `MealLog`에 커스텀 `init(from:)`도 없음. REQ-002 정정 내용과 일치. **PASS**.

### AC-101 — PlaceSearch 프록시 호출 관례 준수

**Given** `PlaceSearch.nearbyPlaces`가 `Shared/PlaceSearch.swift`에 구현돼 있고
**When** 코드 검사자가 `nearbyPlaces`의 요청 구성을 `DirectionsService`의 기존 프록시 호출 관례(`config.proxyRequest`)와 비교하면
**Then** 계획에 있던 `MealSuggestionService`는 만들지 않았고, `nearbyPlaces`가 기존 파일(`PlaceSearch.swift`)에서 같은 관례로 `/kakao/local/keyword`를 호출함을 확인한다(REQ-005 관련).

**검사 결과**: `nearbyPlaces`(`PlaceSearch.swift:57`)가 `search()`(9행)와 동일하게 `config.proxyRequest("/kakao/local/keyword", ...)`를 호출. 신규 서비스 파일 없음. **PASS**.

### AC-102 — 카카오 API 파라미터 충돌 없음

**Given** 프록시(`proxy/src/index.js`)와 앱(`PlaceSearch.swift`) 양쪽에 `category_group_code`·`x`·`y`·`radius`·`sort`·`page`가 추가돼 있고
**When** 코드 검사자가 기존 `search()`가 쓰는 `query`/`x`/`y` 파라미터와 나란히 놓고 비교하면
**Then** 두 세트가 같은 엔드포인트를 쓰되 파라미터 이름이 겹치지 않고, `search()` 호출 경로에는 `category_group_code`가 전달되지 않음을 확인한다(REQ-005 관련).

**검사 결과**: 프록시 `KAKAO_LOCAL_PASSTHROUGH = ["category_group_code","x","y","radius","sort","page"]`가 `query`/`size`와 분리돼 있고, `search()`는 이 파라미터들을 넘기지 않음(코드 확인). **PASS**.

### AC-103 — executeRecommendMeal 인자 방어

**Given** `executeRecommendMeal`이 `radius_meters`/`keyword`/`place_query`/`at_iso`를 optional로 받고
**When** (a) `radius_meters`가 없거나 (b) `keyword`가 빈 문자열이거나 (c) `place_query`/`at_iso` 둘 다 없고 위치 권한도 거부된 상태로 호출되면
**Then** (a)는 1000m로 대체되고, (c)는 크래시 없이 "어디 주변에서 찾을지 알려주세요(장소를 말해주시거나 위치 권한을 켜주세요)." 안내 문구로 끝난다(REQ-012와 일치).

**검사 결과**: `executeRecommendMeal`(`AIAssistant.swift:1184-`) 확인 — `radius = intValue(input["radius_meters"]) ?? 1000`, `place_query`/`at_iso`/현재위치 셋 다 없으면 guard로 안내 문구 반환 후 즉시 return(크래시 경로 없음). **PASS**.

### AC-104 — FullSirView.save()의 활동 재조회 방식 (근본 질문은 이미 해소됨)

**Given** plan.md M5(Day 11 원문 체크리스트)에 남아있는 문구가 "`await addActivityWithTravel` 직후 `store.activities.last { 제목·시작시각 일치 }`로 되찾는다"이고, 이 방식은 같은 제목·시각의 활동이 이미 있으면 엉뚱한 것에 붙는 버그 패턴이며
**When** 코드 검사자가 실제 `Shared/FullSirView.swift`의 `save()` 구현을 읽으면
**Then** 이미 `addActivityWithTravel`의 반환값(`activityId: UUID`)을 **직접** `MealLog.activityId`에 저장하도록 고쳐져 있음을 확인한다(REQ-015, 구 REQ-032, 커밋 `c6f851e` "식사 기록↔활동 연결을 id로 직접 받도록 수정") — 이 AC의 실행 자체는 ⬜(아직 코드 검사 Day가 오지 않음)이지만, 근본 질문(재조회 방식이 버그 패턴에 해당하는지)의 답은 spec.md §3에 이미 ✅로 기록돼 있다. Day 11이 실행되면 이 결과를 재확인만 하고 plan.md 원문 체크리스트 문구는 낡은 것으로 처리한다.

**검사 결과**: `FullSirView.swift:444` `let made = await store.addActivityWithTravel(...)` 확인 — 반환값을 직접 씀, 재조회 없음. **PASS**.

### AC-105 — 요청당 고정 토큰 재측정

**Given** `recommend_meal` 추가 전 기준선이 5,804토큰(시스템 1,812 + 툴 3,992)이고
**When** 코드 검사자가 `recommend_meal` 툴 선언을 포함한 현재 고정 토큰을 재측정하면
**Then** 5,804 대비 증가폭이 §1 최적화 기록에 반영되고, 급격한 증가(예: 원래 10,701 수준으로 되돌아감) 여부가 확인된다(REQ-008 관련).

**검사 결과(측정 불가 — 정적 검사 한계)**: `systemPrompt()`/`toolsJSON()` 함수 본문의 소스 문자 수(각 ~7,317자·~13,793자)는 확인했으나, 이건 Swift 소스 문법(따옴표·이스케이프·들여쓰기)까지 포함한 값이라 실제 전송되는 프롬프트 텍스트의 토큰 수와는 다르다 — 신뢰할 만한 토큰 수는 실제 토크나이저나 API 호출로만 측정 가능하다. **이 AC는 코드 검사만으로 완료할 수 없다** — 다음에 실제로 AI 채팅을 한 번 호출해 프록시 로그의 `usage` 필드(OpenAI 응답의 `usage.prompt_tokens`)를 직접 확인하는 것을 권장한다(Day 12 실기기 테스트 때 자연스럽게 겸사겸사 확인 가능).

### AC-106 — delivery/cooking 미생성 상태 유지

**Given** `MealCategory.delivery`/`.cooking`이 `Models.swift`에 정의만 돼 있고
**When** 코드 검사자가 UI·AI 전체 경로를 확인하면
**Then** 이 두 값을 실제로 생성하는 경로가 없음을 확인하고(REQ-017, 구 REQ-040), 이는 죽은 코드가 아니라 Day 8(M1) 조사 결론(2026-09-12, 공식 API·딥링크 규격 둘 다 미확인)에 따라 의도적으로 보류된 예약 케이스임을 확인한다.

**검사 결과**: `grep -rn "\.delivery\|\.cooking" Shared/*.swift` — `Models.swift`의 `title`/`systemImage` switch 안에서만 등장, 생성 경로 0건. **PASS**.

### AC-107 — Day 6~10 신규 코드의 await-이후-스테일 참조 재사용 일반 점검 (신규 — plan-auditor D3)

**Given** be full sir가 이번에 새로 만든 코드(`FullSirView.save()` 외에도 `executeRecommendMeal`, `Store.addMeal`/`updateMeal`/`deleteMeal` 등 `await`를 쓰는 모든 지점)
**When** 코드 검사자가 각 `await` 호출 앞뒤로 인덱스·식별자·배열 스냅샷을 재사용하는 곳이 있는지 훑으면
**Then** `FullSirView.save()`(REQ-015, 구 REQ-032, 이미 수정됨) 외에 같은 패턴(await 전에 잡아둔 인덱스/식별자를 await 후 그대로 재사용)이 남아있지 않음을 확인한다 — 있다면 Day 13으로 이월.

**검사 결과**: `addMeal`/`updateMeal`/`deleteMeal`은 전부 동기 함수(await 없음), `updateMeal`은 매번 새로 `firstIndex(where: id ==)`로 찾아 쓰므로 스테일 위험 없음. `FullSirView.swift`의 유일한 상태-변경 `await`(444행)는 이미 REQ-015(구 REQ-032)로 수정됨. 그 외 새 코드에서 같은 패턴 발견 안 됨. **PASS**.

### AC-108 — 식사 관련 신규 알림이 iOS 64건 한도에 미치는 영향 확인 (신규 — plan-auditor D3)

**Given** `Store.addActivityWithTravel`이 식사 활동 등록 시 왕복 이동(출발+복귀)마다 알림을 예약할 수 있는 구조이고, 이미 `Store.rescheduleNearestNotifications(limit:60)`이 iOS 64건 한도 대응으로 존재하고
**When** 코드 검사자가 be full sir로 식사를 여러 건 등록했을 때 새로 추가되는 알림 개수를 기존 반복 일정 알림과 합산해 확인하면
**Then** be full sir가 새로 기여하는 알림이 60건 한도 산정에 이미 포함돼 있는지(별도 큐를 만들지 않았는지) 확인한다(REQ-013 관련) — 별도라면 Day 13으로 이월.

**검사 결과**: `addActivityWithTravel`의 왕복 이동은 내부적으로 `await addEvent(...)`를 호출해 **같은 `events` 배열**에 들어가고, `rescheduleNearestNotifications`는 소스와 무관하게 `events` 전체를 훑어 가장 가까운 60건만 예약한다(`Store.swift:996-1011`) — 별도 큐 없음, 이미 같은 한도 관리 안에 포함돼 있음. **PASS**.

### AC-109 — 카카오 API 일일 할당량 소진 시 recommend_meal·목적지 주변 동작 확인 (신규 — plan-auditor D3)

**Given** 카카오 로컬 API가 일일 호출 한도를 소진해 오류를 반환하는 상황(직접 재현 어려우면 프록시 응답을 임시로 오류로 바꿔 시뮬레이션)
**When** `recommend_meal` 또는 "목적지 주변" 섹션이 이 상태에서 호출되면
**Then** AC-206(0건 처리)과 같은 빈 상태 UI로 자연스럽게 떨어지는지, 아니면 별도의 처리되지 않은 에러가 노출되는지 확인한다(REQ-005, REQ-007, REQ-010 관련) — 후자라면 Day 13으로 이월.

**검사 결과**: `nearbyPlaces`(`PlaceSearch.swift:77-90`)는 `try? await URLSession...data`, `try? JSONDecoder().decode(Resp.self, ...)` 둘 다 실패 시 `return []`로 떨어진다 — 카카오가 할당량 소진으로 `documents` 없는 에러 JSON을 돌려줘도 디코드 실패로 자동으로 빈 배열이 되어 AC-206과 같은 빈 상태 UI로 이어진다. 별도 에러 노출 경로 없음. **PASS**(단, 실제 할당량 소진 상황을 라이브로 재현한 것은 아니라 Day 12에서 한 번 더 확인 권장).

### AC-110 — MealCategory 데이터 모델 conformance 확인 (신규 — v0.3.0 D4, 추적성 공백 보완)

**Given** `MealCategory`가 `Models.swift`에 정의돼 있고
**When** 코드 검사자가 `TransportMode`와 동일한 형태(`title`/`systemImage`)와 프로토콜 conformance를 확인하면
**Then** `MealCategory`가 `Codable`/`CaseIterable`/`Identifiable`을 모두 준수하고, 세 케이스(외식/배달/요리) 각각에 대해 `title`/`systemImage`를 반환함을 확인한다(REQ-001).

**검사 결과(2026-09-12, 코드 읽기로 확인)**: `Models.swift:375` — `enum MealCategory: String, Codable, CaseIterable, Identifiable`. `id`(380행)는 `rawValue`. `title`(382-388행)·`systemImage`(390-396행) 모두 `.diningOut`/`.delivery`/`.cooking` 세 케이스를 빠짐없이 커버. **PASS**.

### AC-111 — meals가 daysWithSchedule 캐시에서 제외됨 확인 (신규 — v0.3.0 D4, 추적성 공백 보완)

**Given** `Store.swift`에서 `events`/`activities`는 `{ didSet { recomputeDaysWithSchedule() } }`을 갖고 `meals`는 갖지 않는 상태이고
**When** 코드 검사자가 `recomputeDaysWithSchedule()` 본문을 확인하면
**Then** 이 함수가 `events`/`activities`만 순회해 `daysWithSchedule` 집합을 채우고 `meals`는 전혀 참조하지 않음을 확인한다(REQ-004) — 식사 기록 추가/삭제가 월간 캘린더의 "일정 있음" 점 표시를 갱신시키지 않는다.

**검사 결과(2026-09-12, 코드 읽기로 확인 — plan-auditor가 이미 독립 검증한 내용의 AC화)**: `Store.swift` — `@Published var meals: [MealLog] = []`에는 `didSet`이 없음(같은 파일의 `events`/`activities` 선언에는 있음). `recomputeDaysWithSchedule()`은 `for e in events`/`for a in activities` 두 루프만 돌며 `meals`를 참조하는 코드가 없음. **PASS**.

### AC-112 — recommend_meal 툴 선언 형식 + AIAssistant 기존 tool loop 연결 확인 (신규 — v0.3.0 D4, 추적성 공백 보완)

**Given** `recommend_meal`이 `AIAssistant.swift`의 기존 툴 선언 배열과 기존 실행 디스패처(스위치문)에 추가돼 있고
**When** 코드 검사자가 선언부의 파라미터 타입 표기와 실행 분기를 확인하면
**Then** 선언의 `type` 필드가 Gemini `generateContent` 관례대로 대문자(`"OBJECT"`/`"STRING"`/`"INTEGER"`)로 돼 있고, 새 AI 클래스 없이 기존 툴 루프의 스위치 분기로 실행됨을 확인한다(REQ-008).

**검사 결과**: `AIAssistant.swift:604-616` — 선언 `"type": "OBJECT"`, 파라미터 `keyword`/`category`/`at_iso`/`place_query`는 `"type": "STRING"`, `radius_meters`는 `"type": "INTEGER"` — 전부 대문자. `AIAssistant.swift:694` — `case "recommend_meal": return await executeRecommendMeal(input)`로 기존 스위치문에 한 케이스만 추가돼 있음, 별도 AI 클래스·별도 실행 경로 없음. **PASS**.

### AC-113 — Store.meals 배열 + CRUD 연산 존재·동작 확인 (신규 — v0.4.0 이터레이션3, REQ-003 추적성 보완)

**Given** `Store`가 `meals: [MealLog]` published 배열과 `addMeal`/`updateMeal`/`deleteMeal`/`recentMeals(limit:)` 연산을 제공해야 하고, 영속화는 `events.json`과 같은 패턴을 따라야 한다는 REQ-003이 있고
**When** 코드 검사자가 `Store.swift`의 선언·구현을 확인하면
**Then** `meals`가 `@Published` 배열로 선언돼 있고, 네 연산이 각각 명시된 대로 동작함을 확인한다 — `addMeal`은 추가 후 `loggedAt` 내림차순 정렬 + 저장, `updateMeal`은 `id` 일치 레코드를 찾아 교체 + 저장, `deleteMeal`은 `id`로 제거 + 저장, `recentMeals(limit:)`은 앞에서부터 `limit`개만 반환한다(REQ-003).

**검사 결과(2026-09-12, 코드 읽기로 확인)**: `Store.swift:17` — `@Published var meals: [MealLog] = []`. `Store.swift:48-49` — `mealsURL`이 `AppConfig.supportDirectory`에 `meals.json`을 붙인 경로(`events.json`과 동일한 디렉터리 패턴). `Store.swift:348-363` — `addMeal(...)`이 `MealLog`를 만들어 `meals.append` 후 `loggedAt` 내림차순 정렬, `saveMeals()` 호출, 생성된 `meal` 반환. `Store.swift:365-370` — `updateMeal(_:)`이 `meals.firstIndex(where: { $0.id == updated.id })`로 찾아 교체 후 정렬·저장. `Store.swift:372-375` — `deleteMeal(_:)`이 `meals.removeAll { $0.id == id }` 후 저장. `Store.swift:389-391` — `recentMeals(limit:)`이 `Array(meals.prefix(limit))` 반환(기본 10). `Store.swift:393-398`/`400-404` — `saveMeals()`/`loadMeals()`가 `JSONEncoder`/`JSONDecoder` + `mealsURL`로 `events.json`과 동일한 파일저장 패턴을 씀. **PASS**.

### AC-114 — recommend_meal 파라미터에 budget 없음 확인 (신규 — v0.4.0 이터레이션3, REQ-009 추적성 보완)

**Given** `recommend_meal` 툴이 `keyword`/`category`/`at_iso`/`place_query`/`radius_meters` 다섯 개만 받고 `budget`은 받지 않아야 한다는 REQ-009가 있고(be rich sir Phase 3의 지출 데이터가 아직 없어 주입할 값이 없기 때문)
**When** 코드 검사자가 `AIAssistant.swift`의 `recommend_meal` 툴 선언부 `properties` 딕셔너리를 확인하면
**Then** `properties`에 정확히 `keyword`/`category`/`at_iso`/`place_query`/`radius_meters` 다섯 키만 있고 `budget` 키가 존재하지 않음을 확인한다(REQ-009).

**검사 결과(2026-09-12, 코드 읽기로 확인)**: `AIAssistant.swift:606-616` — `parameters.properties`에 `keyword`(609행)·`category`(610행)·`at_iso`(611행)·`place_query`(612행)·`radius_meters`(613행) 다섯 키만 존재. `grep -n "budget" Shared/AIAssistant.swift`도 0건(별도 확인). §4 Out of Scope("be rich sir 예산 연동")와 일치. **PASS**.

### AC-115 — 기준 위치 해석 우선순위: place_query → at_iso → 현재 위치 (신규 — v0.4.0 이터레이션3, REQ-011 추적성 보완)

**Given** `executeRecommendMeal`이 기준 위치를 `place_query`(우선) → `at_iso`(그 다음) → 현재 위치(마지막) 순으로 해석해야 한다는 REQ-011이 있고
**When** (a) `place_query`와 `at_iso`가 둘 다 주어지거나, (b) `place_query`는 없고 `at_iso`와 현재 위치가 둘 다 사용 가능하면
**Then** (a)에서는 `place_query`가 이기고, (b)에서는 `at_iso`가 현재 위치보다 이긴다 — AC-103(모두 없을 때의 방어)과 달리 이 AC는 여러 후보가 동시에 있을 때의 **우선순위 자체**를 검증한다(REQ-011).

**검사 결과(2026-09-12, 코드 읽기로 확인)**: `AIAssistant.swift:1189-1208`의 `executeRecommendMeal` 구현이 `basis`를 순차적인 `if basis == nil { ... }` 가드 체인으로 채운다 — ①`place_query`가 있으면 `resolveDestination(q)`로 `basis`를 즉시 채움(1191-1194행), ②`basis == nil`일 때만(= ①이 못 채웠을 때만) `at_iso`를 시도(1195-1200행), ③`basis == nil`일 때만(= ①·②가 둘 다 못 채웠을 때만) 현재 위치를 씀(1201-1208행). 따라서 `place_query`+`at_iso`가 둘 다 주어지면 ①에서 `basis`가 이미 채워져 ②는 실행되지 않고(place_query 승리), `place_query` 없이 `at_iso`+현재 위치가 둘 다 가능하면 ②가 먼저 `basis`를 채워 ③은 실행되지 않는다(at_iso 승리) — REQ-011이 서술한 우선순위와 정확히 일치. **PASS**.

### AC-116 — 배달/요리 capability gate 조건 미충족 상태 확인 (선언적 REQ, PASS-by-declaration — 신규 — v0.4.0 이터레이션3, REQ-018 추적성 보완)

**Given** REQ-018은 "요기요·배민 공식 오픈 API 개방 또는 딥링크 규격 공개가 확인되면 REQ-017의 생성 금지가 해제된다"는 조건만 선언하며, 그 자체가 구현 작업 지시는 아니라는 Where(capability gate) 요구사항이고
**When** 2026-09-12 현재 시점에 이 조건의 충족 여부를 `plan.md` M1 조사 결과(→ `research.md`로 정리됨)로 확인하면
**Then** 둘 다 미확인 상태이므로 REQ-017의 생성 금지가 계속 유지되고, REQ-018 자체는 조건의 선언일 뿐 이 시점에 코드로 검증할 동작이 없음을 확인한다 — 조건이 실제로 충족되는 시점이 오면 그때 다시 이 AC를 재평가한다(REQ-018).

**검사 결과**: `research.md`/`plan.md` M1의 조사 결론(2026-09-12, 웹 검색 기반)이 "공식 API 미개방·딥링크 규격 미공개"로 일치함을 확인. 이 REQ는 조건부 미래 진술이라 현재 코드 상에 대응하는 생성 경로가 없는 것 자체가 기대된 상태(REQ-017과 일관) — AC-106과 마찬가지로 delivery/cooking 생성 경로 0건임을 재확인. **PASS(선언적)** — 향후 조건이 바뀌면 별도 후속 SPEC에서 재검토(spec.md §5 후행 참고).

## 2. AC 매트릭스 — Day 12 실기기 테스트 (plan.md M6)

| AC | 상태 |
|---|---|
| AC-201 | ⬜ 미실행 |
| AC-202 | ⬜ 미실행 |
| AC-203 | ⬜ 미실행 |
| AC-204 | ⬜ 미실행 |
| AC-205 | ⬜ 미실행 |
| AC-206 | ⬜ 미실행 |
| AC-207 | ⬜ 미실행 |

### AC-201 — 목적지 주변 섹션 지연 조회 (정정됨 — plan-auditor 발견, 2026-09-12)

**Given** `EventDetailView`의 "목적지 주변" 섹션에 "추천 보기" 버튼이 보이는 상태이고(섹션 자체는 항상 표시됨 — 펼침/접힘 UI 없음)
**When** 사용자가 "추천 보기"(또는 재조회 시 "새로고침") 버튼을 탭하면
**Then** 그때 비로소 `nearbyPlaces` 호출이 일어나 3~5개 결과가 표시되고, 버튼을 탭하기 전에는 네트워크 호출이 발생하지 않는다(REQ-006, 구 REQ-011). **정정**: 이전 문구는 "섹션을 펼치면"이라 썼으나 실제 UI는 버튼 탭 트리거다(`EventDetailView.swift:96-112`).

### AC-202 — 기준 위치 전환에 따른 결과 차이

**Given** be full sir 화면에서 기준 위치를 현재 위치 또는 오늘 일정의 목적지로 선택할 수 있고
**When** 두 기준 위치를 번갈아 검색하면
**Then** 각각 그 위치 근처의 결과가 나오고, 거리순/정확도순 정렬을 바꿨을 때 실제로 순서가 달라진다(REQ-005~007 관련).

### AC-203 — AI 채팅이 검색 결과에 없는 가게를 지어내지 않음

**Given** AI 채팅에 "저녁 뭐 먹지"(기준 위치 없음)와 "이따 강남 갔을 때 근처에서"(`at_iso` 경로) 둘 다 물어보고
**When** `recommend_meal`이 실행되면
**Then** 추천 목록은 `nearbyPlaces`가 실제로 반환한 가게로만 구성되고, 모델이 검색 결과에 없는 가게를 지어내지 않는다(REQ-010, 구 REQ-022).

### AC-204 — 식당 선택 → 활동+이동 등록 + meals.json 기록

**Given** 사용자가 추천 목록에서 식당을 선택하고 출발·복귀 이동수단을 각각 고르면
**When** 저장하면
**Then** 캘린더에 식사 활동 블록 + 왕복 이동이 실제로 생기고, 출발·복귀 이동수단이 각각 반영되며, `meals.json`에도 해당 기록이 남는다(REQ-013, REQ-014, REQ-015, 구 REQ-030~032) — 특히 REQ-014(연결 필드가 `scheduledEventId`가 아니라 `activityId`)는 `meals.json`에 기록된 항목의 `activityId` 필드가 채워져 있는지로 확인한다.

### AC-205 — 일정 삭제 시 미래/과거 식사 기록 처리

**Given** 식사 기록과 연결된 일정(활동)이 있고, 그중 하나는 아직 안 먹은(미래) 것이고 다른 하나는 이미 지난(과거) 것이면
**When** 그 일정을 삭제하면
**Then** 미래 식사 기록은 함께 삭제되고, 이미 지난 식사 기록은 남는다(`Store.removeUpcomingMeals` → `ScheduleLogic.mealsToRemove`, REQ-016, 구 REQ-033) — Day 11의 `activityId` nil 문제(AC-104)와 직결되므로 AC-104 확인 후 테스트한다.

### AC-206 — 검색 0건 처리

**Given** 외곽 지역 등 카카오 로컬 검색 결과가 0건인 상황이고
**When** be full sir 검색 또는 목적지 주변 섹션을 조회하면
**Then** 크래시 없이 빈 상태 UI가 표시된다(REQ-007, 구 REQ-012).

### AC-207 — 위치 권한 거부 처리

**Given** 사용자가 위치 권한을 거부한 상태이고
**When** be full sir 화면에서 검색하거나 AI 채팅에서 `recommend_meal`을 기준 위치 없이 호출하면
**Then** 둘 다 크래시 없이 안내 문구로 끝난다(REQ-012, 구 REQ-024).

## 3. 품질 게이트 기준 (plan.md §5-1/5-2/5-3 공통 기준 적용)

- 강제 언래핑·강제 캐스팅 남용 없음, 실패 가능 지점은 `guard let`/`try?`/`if let` 처리.
- 네트워크·API 실패 시 무한 로딩이 아닌 명시적 실패 상태 UI(`failedEstimateBlockView` 패턴).
- 새 모델 영속화가 `events.json`과 같은 `Codable` + 파일저장 패턴을 따르고 `Store`에 `@Published`로 선언.
- async 클로저의 `Store`/`AIAssistant` 참조 순환 방지(`[weak self]`).
- UI 갱신이 메인 스레드에서 실행.
- 새 기능이 기존 함수 시그니처(`Store.addEvent`, AI 툴 스키마)를 깨지 않음.
- 카카오/AI 호출이 불필요하게 반복되지 않음(캐시 가능한 값은 캐시).
- iOS 시뮬레이터 + macOS 둘 다 빌드 무경고.
- 회귀 확인(항상 실행): be on-time sir 핵심 흐름(일정 수동 등록→출발 알람→구글 캘린더 동기화, 카카오톡 공유→AI 파싱→일정 자동 등록) 각 최소 1회.

## 4. Definition of Done

- [ ] Day 8(M1) 조사 결론 도출 — Implementation Kickoff Approval 전 필수 전제
- [ ] AC-101~106 전부 확인(Day 11)
- [ ] AC-201~207 전부 확인(Day 12), 문제 발견 시 Day 13으로 이월
- [ ] Day 13에서 발견 사항 전부 수정 또는 §7(리스크)에 "알려진 이슈"로 명시
- [ ] 회귀(be on-time sir) 이상 없음 확인
- [ ] `STATUS.md`에 be full sir MVP 완료 반영
