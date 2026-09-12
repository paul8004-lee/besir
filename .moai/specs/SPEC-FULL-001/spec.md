---
id: SPEC-FULL-001
title: "be full sir Phase 1 MVP — 식사 추천 (구현 완료분 정리 + Day 8 미해결)"
version: "0.5.0"
status: in-progress
created: "2026-09-12"
updated: "2026-09-12"
author: "manager-spec"
priority: Medium
phase: "v0.1.1 target"
module: "be-full-sir"
lifecycle: spec-anchored
tags: "be-full-sir, phase1, meal, kakao-local"
tier: L
---

# SPEC-FULL-001 — be full sir Phase 1 MVP

## HISTORY

| 버전 | 날짜 | 변경 |
|---|---|---|
| 0.1.0 | 2026-09-12 | 최초 작성 — plan.md §6 "Phase 1 — be full sir MVP(Day 6~11)"의 **실제 구현 상태**를 사후(as-built) GEARS 형식으로 정식화. Day 6·7·9·10은 코드가 이미 완성돼 있어 "지금 코드가 하는 일"을 요구사항으로 문서화했고, Day 8(배달/요리 조사)은 아직 결론이 안 나 미해결 항목으로 남겼다. |
| 0.2.0 | 2026-09-12 | `/moai run` Phase 1 Plan Audit Gate(plan-auditor) 결과 반영(FAIL, 0.58점 → 정정 후 재검토 대상). **REQ-002 정정**: `MealLog` 디코드 실패가 "레코드 단위"라던 주장이 틀렸음을 코드 대조로 확인 — 실제로는 `events`/`activities`/`favorites`와 동일한 "배열 전체 디코드-또는-포기" 패턴(be full sir가 새로 만든 결함 아님, 코드는 고치지 않고 REQ 서술만 정정). **REQ-011 정정**: "섹션을 펼치면"이 아니라 "추천 보기 버튼을 탭하면"이 실제 트리거(`EventDetailView.swift:96-112`). REQ-021/023/041을 GEARS 형식(shall/Where 절)으로 재작성. `priority: medium`→`Medium`(스키마 enum 표기 일치). |
| 0.3.0 | 2026-09-12 | 두 번째 Plan Audit Gate 결과 반영(FAIL, 0.62점 → 정정). **D1(critical)**: frontmatter `tags:`가 YAML 리스트라 `moai spec lint`가 파싱 자체에 실패하던 것을 콤마 구분 문자열로 수정. **D2(critical)**: v0.2.0에서 "의도된 관례"로 유지하려 했던 REQ 번호 그루핑(구간별 십의 자리, 18개 REQ에 4개 구간 결번)을 감사자가 무조건 FAIL로 판정 — REQ-001~018로 전 구간 순차 재넘버링(아래 매핑표 참고)하고 plan.md/acceptance.md의 모든 인용도 함께 갱신. **D3(major)**: `tier: L`인데 Tier L 필수 산출물(design.md/research.md)이 없던 것을 보완 — plan.md M1(Day 8 조사)을 research.md로, 이미 확정된 아키텍처 결정 3건(PlaceSearch 재사용, Store.addActivityWithTravel 재사용, activityId 채택)을 design.md로 신규 작성. **D4(major)**: REQ-001(MealCategory conformance)·REQ-004(daysWithSchedule 제외, 신 번호)·REQ-008(recommend_meal 툴 선언, 신 번호)에 AC가 하나도 없던 추적성 공백을 acceptance.md에 AC-110~112 추가로 해소. **D6(major)**: (신)REQ-005(구 REQ-010)가 `search()`의 실제 파라미터를 `query`/`x`/`y`로 잘못 서술한 것을 `query`/`size`로 정정(`PlaceSearch.swift:9-27` 대조 — `x`/`y`는 MapKit 폴백 전용, 카카오 요청에는 안 실림). **D5(minor, optional)**: AC-101/102/105/107/108/109/202에 REQ 인용 보강. |
| 0.4.0 | 2026-09-12 | 세 번째(최종) Plan Audit Gate 결과 반영(FAIL, 0.75점 — Traceability 0.50만 미달, 다른 must-pass MP-1~7은 전부 PASS). REQ-by-REQ 독립 재점검으로 AC가 하나도 없던 4개 REQ에 acceptance.md 전용 AC 추가: **REQ-003**(Store.meals 배열 + CRUD)에 AC-113, **REQ-009**(recommend_meal이 `budget`을 받지 않음)에 AC-114, **REQ-011**(기준 위치 해석 우선순위 — 기존 AC-103은 "셋 다 없을 때"만 검증했고 "여러 후보가 동시에 있을 때의 우선순위"는 미검증이었음)에 AC-115, **REQ-018**(capability gate 조건 — 선언적 REQ라 PASS-by-declaration으로 처리)에 AC-116. 전체 REQ-001~018을 재점검하는 과정에서 REQ-014가 AC-204의 "REQ-013~015" **범위 표기**로만 인용돼 있어 리터럴 `REQ-014` 문자열이 없던 것도 함께 발견 — AC-204 인용을 "REQ-013, REQ-014, REQ-015"로 풀어써 리터럴 인용 공백을 마저 해소(18/18 REQ 전부 리터럴 AC 인용 확보). 코드는 건드리지 않음 — 전부 기존 구현에 대한 추적성 문서화. |
| 0.5.0 | 2026-09-12 | **M6(Day 12 실기기 테스트) 완료 + M7(Day 13 안정화) 완료 — 이번 버전은 코드를 건드린다.** 사용자가 실기기에서 AC-201~207을 직접 확인, 결과는 acceptance.md §2에 기록. **AC-204에서 버그 2건 발견 → 수정**: ① `FullSirView`(`MealScheduleSheet.applyDestinationSuggestion`)가 "다음 일정"이 없으면(흔한 경우) 복귀지를 비워둬 왕복 이동 중 복귀 편이 조용히 안 만들어짐 — 다음 일정이 없으면 출발지로 되돌아가는 것을 기본값으로 채우도록 수정. ② AI `create_activity`가 활동+이동만 만들고 `meals.json`에 기록하지 않음(REQ-014 취지상 AI 경로도 포함돼야 함) — `log_as_meal` 인자 추가, true면 `addMeal(activityId:)`까지 호출. 부수적으로 AI가 왕복 이동 생성 시 `return_to_query`를 종종 빠뜨리는 문제도 발견(모델 인자 누락 패턴, §1 참고) — 툴 설명 강화로 완화(100% 보장 아님, 재확인 필요). **사용자 승인 후 신규 요구사항 2건 추가**(AskUserQuestion으로 확인, 둘 다 "지금 추가" 선택): ③ "목적지 주변" 맛집 섹션을 `EventDetailView`(이동 일정)에서 `ActivityDetailView`(활동 일정)로 이전 — "식사하는 곳"인 활동 쪽이 더 자연스럽다는 실기기 테스트 의견 반영. ④ `FullSirView` 기준 위치에 직접 검색(`Basis.custom` + 기존 `PlaceField` 재사용) 추가 — 외곽 지역처럼 현재 위치·오늘 일정 목적지 둘 다 기준 삼기 어려운 경우 대응. 수정 후 iOS·macOS 무경고 재빌드 + 실기기 재설치·재실행 완료. **남은 것**: Day 8(M1, 배달/요리 조사) 결론 여전히 미해결(변경 없음), be on-time sir 회귀 확인과 STATUS.md 갱신은 다음 실기기 세션으로 이월. |

### REQ 번호 재매핑 (v0.2.0 → v0.3.0, D2)

번호만 바뀌었고 요구사항 본문·의미는 그대로다(REQ-001~004는 번호 변경 없음).

| 구 번호 | 신 번호 | 구 번호 | 신 번호 |
|---|---|---|---|
| REQ-001 | REQ-001 | REQ-023 | REQ-011 |
| REQ-002 | REQ-002 | REQ-024 | REQ-012 |
| REQ-003 | REQ-003 | REQ-030 | REQ-013 |
| REQ-004 | REQ-004 | REQ-031 | REQ-014 |
| REQ-010 | REQ-005 | REQ-032 | REQ-015 |
| REQ-011 | REQ-006 | REQ-033 | REQ-016 |
| REQ-012 | REQ-007 | REQ-040 | REQ-017 |
| REQ-020 | REQ-008 | REQ-041 | REQ-018 |
| REQ-021 | REQ-009 | | |
| REQ-022 | REQ-010 | | |

## 1. 배경

besir는 사업계획서상 다섯 서비스를 순서대로 붙여나가는 iOS·macOS 앱이다. **be full sir**(식사/맛집)는 두 번째 서비스이자 사업계획서가 명시한 MVP 핵심 축("be on-time sir + be full sir")이다. `PlaceSearch`(카카오 로컬 검색)가 이미 있어 신규 외부 연동 없이 구현 가능해 가장 리스크 낮은 신규 서비스로 선정됐다(plan.md §Phase 1 선정 이유).

**이 SPEC의 성격이 일반 SPEC과 다르다**: Day 6·7·9·10의 코드는 이미 작성·배포 가능한 상태로 완성돼 있고(실기기 확인·코드 검사만 남음), Day 8(배달/요리 카테고리 조사)만 미해결이다. 따라서 이 문서는 "앞으로 만들 것"이 아니라 **"지금 코드가 실제로 하는 일을 GEARS로 정식화하고, 아직 결정되지 않은 부분을 명시적으로 남기는"** 사후 기준선(as-built baseline) SPEC이다. 추가 요청사항이 들어오면 이 SPEC에 REQ를 더해나간다(사용자 지시).

**구현이 원래 계획(plan.md 최초안)과 달라진 부분**은 각 REQ에서 근거와 함께 명시한다 — 특히 `MealLog`의 연결 필드가 `scheduledEventId`가 아니라 `activityId`인 점, 신규 `MealSuggestionService`를 만들지 않고 기존 `PlaceSearch`/`Store.addActivityWithTravel`을 재사용한 점.

## 2. 요구사항 (GEARS)

### 2.1 데이터 모델 (Day 6, 완료 — 2026-09-10)

- **REQ-001 (Ubiquitous)**: `MealCategory`(외식/배달/요리) shall provide `title`/`systemImage` in the same shape as the existing `TransportMode` enum, and shall conform to `Codable`/`CaseIterable`/`Identifiable`.
- **REQ-002 (Ubiquitous, 정정됨 — plan-auditor 발견, 2026-09-12)**: `MealLog` shall carry `id`/`category`/`title`/`place`(optional)/`estimatedCost`(optional)/`scheduledEventId`(optional)/`activityId`(optional)/`plannedAt`(optional)/`loggedAt`, decoded/encoded via the existing `Codable` pattern (unknown/missing optional fields decode to `nil`, not a decode failure). **정정**: 이전 버전은 "알 수 없는 `category` 값은 그 레코드만 디코드 실패하고 나머지는 유지된다"고 적었으나 실제로는 그렇지 않다 — `Store.loadMeals()`는 `[MealLog]` 배열 전체를 한 번에 디코드하는 `try? JSONDecoder().decode([MealLog].self, ...) else { return }` 패턴이라, `category` 값 하나라도 알 수 없으면 **배열 전체**가 디코드 실패해 그 시점의 메모리 상 `meals`가 갱신되지 않는다(디스크 파일 자체는 안 건드림). 이건 `events`/`activities`/`favorites` 등 이 코드베이스의 **모든 영속 배열이 공유하는 기존 패턴**이며(`Store.swift`의 `loadActivities`/`loadFavorites`/`loadEvents`도 동일), be full sir가 새로 만든 결함이 아니다 — 그래서 이 SPEC은 코드를 고치지 않고 REQ 서술만 정정한다(기존 패턴과의 일관성을 깨는 게 오히려 더 큰 리스크).
- **REQ-003 (Ubiquitous)**: The `Store` shall hold a `meals: [MealLog]` published array, persisted to `meals.json` following the same 파일저장 패턴이 `events.json`에 이미 쓰인 패턴, with `addMeal`/`updateMeal`/`deleteMeal`/`recentMeals(limit:)` operations.
- **REQ-004 (Unwanted, GEARS "shall not")**: `meals`는 시간표 블록이 아니라 이력이므로, `Store`는 `meals` 항목을 `daysWithSchedule` 캐시에 포함시켜서는 안 된다(식당까지 가는 이동은 별도 `ScheduledEvent`가 담당한다).

### 2.2 목적지 주변 장소 검색 확장 (Day 7, 완료 — 2026-09-11)

- **REQ-005 (Ubiquitous, 정정됨 — plan-auditor D6 발견, 2026-09-12, 구 REQ-010)**: `PlaceSearch.nearbyPlaces(category:keyword:near:radiusMeters:sort:limit:)`는 기존 `PlaceSearch.search`와 동일한 프록시 호출 관례(`config.proxyRequest`, `/kakao/local/keyword` 엔드포인트)를 따르며, 카카오 로컬 API의 `category_group_code`(FD6 음식점/CE7 카페)·`x`·`y`·`radius`·`sort`·`size` 파라미터를 추가로 전달한다. 이 파라미터들은 기존 `search()`가 쓰는 `query`/`size` 파라미터와 충돌하지 않는다(둘 다 같은 엔드포인트를 쓰지만 `search()`는 `category_group_code`/`x`/`y`를 전달하지 않는 별개의 선택적 확장이다). **정정**: 이전 버전은 `search()`가 쓰는 파라미터를 `query`/`x`/`y`로 잘못 서술했다 — 코드 대조 결과(`PlaceSearch.swift:9-27`) `search()`는 실제로 `query`/`size`만 카카오에 전송하고, `x`/`y`는 MapKit 폴백 경로에서만 쓰이며 카카오 요청에는 실리지 않는다.
- **REQ-006 (Event-driven, 정정됨 — plan-auditor 발견, 2026-09-12, 구 REQ-011)**: **When** the user taps the "추천 보기"(또는 이미 조회했다면 "새로고침") 버튼 in `EventDetailView`'s "목적지 주변" section, the view shall call `nearbyPlaces` and display 3~5 results — **while** the button has not been tapped yet, no place-search network call fires (지연 조회 — 상세를 열기만 해서는 API를 쓰지 않는다). **정정**: 이전 버전은 "섹션을 펼치면(expand)"이라고 적었으나, 실제 UI에는 펼침/접힘 동작이 없다 — 섹션은 항상 보이고, 버튼 탭이 트리거다(`EventDetailView.swift:96-112`).
- **REQ-007 (Event-detected, 구 REQ-012)**: **When** the proxy is unavailable or returns zero results, `nearbyPlaces`는 빈 배열을 반환하고, 호출부는 크래시 없이 빈 상태 UI를 보여준다.

### 2.3 AI 추천 툴 `recommend_meal` (Day 9, 완료 — 2026-09-12)

- **REQ-008 (Ubiquitous, 구 REQ-020)**: The `recommend_meal` tool declaration shall follow the existing Gemini `generateContent`-format contract (uppercase type names, e.g. `"OBJECT"`/`"STRING"`; the proxy's `lowercaseSchemaTypes` translates them) — no new AI class is introduced; the tool is added to `AIAssistant`'s existing tool loop, declared at `AIAssistant.swift:604`, executed by `executeRecommendMeal`.
- **REQ-009 (Ubiquitous, 정정됨 — GEARS 형식 보완, 2026-09-12, 구 REQ-021)**: `recommend_meal` tool shall accept exactly the parameters `keyword`/`category`(restaurant·cafe)/`at_iso`/`place_query`/`radius_meters`, and shall NOT accept a `budget` parameter — be rich sir(Phase 3)의 지출 데이터가 아직 없어 주입할 값이 없기 때문이다(§4 Out of Scope 참고).
- **REQ-010 (Event-driven, 구 REQ-022)**: **When** `recommend_meal`이 실행되면, `PlaceSearch.nearbyPlaces`가 반환한 실제 검색 결과만 추천 목록에 포함하고, 모델이 검색 결과에 없는 가게를 지어내지 않도록 프롬프트가 지시한다.
- **REQ-011 (Ubiquitous, 정정됨 — GEARS 형식 보완, 2026-09-12, 구 REQ-023)**: `executeRecommendMeal`은 기준 위치를 `place_query`(우선) → `at_iso`(그 시각에 있을 장소) → 현재 위치 순으로 해석해야 한다(트리거가 있는 이벤트가 아니라 항상 적용되는 해석 규칙이므로 Ubiquitous로 재분류 — 원래 Event-driven 표기는 오분류였다).
- **REQ-012 (Event-detected, 구 REQ-024)**: **When** `place_query`/`at_iso` 둘 다 없고 위치 권한도 거부된 상태에서 `recommend_meal`이 호출되면, 크래시하지 않고 "어디 주변에서 찾을지 알려주세요(장소를 말해주시거나 위치 권한을 켜주세요)." 안내 문구로 끝난다. `radius_meters`가 없으면 1000m으로 대체한다.

### 2.4 전용 화면 및 활동+이동 등록 (Day 10, 완료 — 2026-09-12)

- **REQ-013 (Ubiquitous, 구 REQ-030)**: **원래 계획(신규 `MealSuggestionService` + `Store.addEvent`)과 다르게**, 신규 화면 `FullSirView`가 기준 위치(현재 위치 또는 오늘 일정의 목적지) → 카카오 로컬 검색 → 식당 선택 흐름을 제공하고, 기존 `Store.addActivityWithTravel`을 재사용해 "식사 활동 블록 + 왕복 이동"을 한 번에 등록한다. 출발·복귀 이동수단은 각각 선택한다.
- **REQ-014 (Ubiquitous, 구 REQ-031)**: 연결 필드는 계획의 `MealLog.scheduledEventId`가 아니라 **`activityId`**다 — 식사 기록이 묶이는 대상이 이동 일정이 아니라 활동 블록이기 때문이다.
- **REQ-015 (Event-driven, 구 REQ-032)**: **When** 식당을 선택해 저장하면, `FullSirView.save()`는 `await store.addActivityWithTravel(...)`의 반환값(`activityId: UUID`)을 **직접** `MealLog.activityId`에 저장한다 — 제목·시작 시각으로 `store.activities`를 재검색해 되찾는 방식은 쓰지 않는다(같은 이름·같은 시각의 활동이 이미 있으면 엉뚱한 쪽에 붙는 버그 패턴이었다 — 코드 주석·커밋 `c6f851e`로 확인, §3 참고).
- **REQ-016 (Event-driven, 구 REQ-033)**: **When** 일정을 삭제하면, `Store.removeUpcomingMeals`(→ `ScheduleLogic.mealsToRemove`)가 아직 안 먹은(미래) 식사 기록을 함께 삭제하고, 이미 지난 식사 기록은 실제로 먹은 기록이므로 남긴다.

### 2.5 배달/요리 카테고리 (Day 8, 조사 완료 — 무기한 보류)

- **REQ-017 (Unwanted, GEARS "shall not", 구 REQ-040)**: **While** 공식 API 개방 또는 딥링크 규격 공개가 확인되지 않은 동안(2026-09-12 조사 결과: 둘 다 미확인), 어떤 UI·AI 경로도 `MealCategory.delivery` 또는 `.cooking` 값을 갖는 `MealLog`를 생성해서는 안 된다. 현재 이 두 케이스는 `Models.swift`에 정의만 돼 있고 생성 경로가 없다 — 죽은 코드가 아니라 의도적으로 보류된 예약 케이스다.
- **REQ-018 (Where, capability gate — 정정됨, 2026-09-12, 구 REQ-041)**: **Where** 요기요·배민 공식 오픈 API가 개인 개발자에게 개방되거나 딥링크 경로·파라미터 규격이 공식 문서로 확인되는 상태가 되면, REQ-017의 생성 금지는 해제된다 — 단, 실제 구현 착수는 이 SPEC이 아니라 별도 후속 마일스톤/SPEC에서 다룬다(이 REQ는 "언제 금지가 풀리는가"라는 조건만 선언하며, 그 자체가 구현 작업 지시는 아니다). 조사 결론(2026-09-12, 웹 검색 기반)은 `plan.md` M1에 기록돼 있다(→ `research.md`로도 정리됨).

## 3. 비기능 요구사항 / 하드 계약 준수

- `Store`가 단일 허브다 — `meals` 배열은 `Store`에 직접 추가돼 있고, be full sir·be on-time sir 간 연계는 "A가 Store의 B를 읽는다" 형태(활동 삭제 → 식사기록 삭제)로 구현돼 있다. 별도 이벤트버스·영속화 레이어는 없다.
- 새 AI 클래스를 만들지 않는다 — `recommend_meal`은 `AIAssistant`의 기존 툴 루프에 추가된 것이다.
- 앱은 AI 백엔드를 모른다 — `recommend_meal` 선언도 Gemini `generateContent` 와이어 포맷을 그대로 따른다.
- 비밀값 없음 — 카카오 REST 키는 이미 프록시 시크릿에 있고, `recommend_meal`은 새 API 키를 요구하지 않는다.
- 같은 계산을 두 곳에 두지 않는다 — `nearbyPlaces` 호출은 `EventDetailView`와 `recommend_meal` 양쪽이 재사용하며 별도 복제가 없다.
- **REQ-015(구 REQ-032)의 id-직접-전달 방식은 이미 코드에 반영돼 있다** — plan.md의 Day 11 코드 검사 체크리스트 항목(§6 Phase 1 표, "`FullSirView.save()`가 ... `store.activities.last { 제목·시각 일치 }`로 방금 만든 활동을 되찾는다")은 **수정 전 상태를 기술한 낡은 문구**이며, 실제 코드(`FullSirView.swift`)는 이미 id를 직접 받는 방식으로 고쳐져 있다(커밋 `c6f851e` "식사 기록↔활동 연결을 id로 직접 받도록 수정"). plan.md 본문 갱신은 이 SPEC의 스코프 밖이며, plan.md §2 M2에 이 사실을 기록해 둔다.

## 4. Out of Scope

### Out of Scope — 배달앱 공식 API·URL scheme 연동 구현
- Day 8의 조사(요기요/배민 API 또는 딥링크 존재 여부 확인)까지만 이 SPEC 범위이며, 실제 연동 구현은 조사 결론이 나온 뒤 별도 마일스톤(또는 후속 SPEC)에서 다룬다.

### Out of Scope — be rich sir 예산 연동
- `recommend_meal`의 `budget` 인자, `MealLog.estimatedCost` 기반 지출 자동 태깅은 Phase 3(be rich sir)의 `Expense` 모델이 존재해야 가능하다 — 이번 스코프 밖이다.

### Out of Scope — 평점 기반 정렬·실제 리뷰 데이터
- 카카오 로컬 API는 평점을 제공하지 않는다. `NearbySort`는 거리순/정확도순만 지원하며, 별점·리뷰 기반 추천은 이 SPEC의 스코프 밖이다.

### Out of Scope — be healthy sir 칼로리 연동
- `MealLog.estimatedCalories` 필드와 `recommend_meal`의 칼로리 추정 파라미터 확장은 `SPEC-HEALTHY-001`(Phase 2)의 스코프다. 이 SPEC은 그 필드를 추가하지 않는다.

## 5. 의존 관계

- **선행**: be on-time sir(완성) — `Store.addActivityWithTravel`, `PlaceSearch`(기존 `search()`), `ScheduleLogic` 등 기존 인프라를 그대로 재사용한다. 신규 서비스 계층을 추가하지 않았다.
- **후행**: `SPEC-HEALTHY-001`이 `MealLog.estimatedCalories` 필드를 확장할 예정(§4 Out of Scope 참고). Day 8 결론에 따른 배달/요리 구현은 별도 후속 SPEC 후보.
