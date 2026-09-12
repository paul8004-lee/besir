# SPEC-FULL-001 — plan.md

## 0. Tier 판단

**Tier: M → L (2026-09-12, `/moai run` Plan Audit Gate 이후 상향)**.

근거:
- 영향 파일 7개(`Models.swift`, `Store.swift`, `PlaceSearch.swift`, `FullSirView.swift`, `AIAssistant.swift`, `EventDetailView.swift`, `proxy/src/index.js`) — Tier M 기준(5~15개 파일)에 해당.
- plan-auditor의 D1(REQ-002 정정)·D3(Day 11 체크리스트 3건 추가)·추적성 지적(Day6 데이터모델군 AC 추가) 반영 후 AC가 17개로 늘어 Tier M 상한(16)을 넘었다 — REQ도 18개로 상한 초과. Tier L 상한(25/25)로 올려 규모를 정직하게 반영한다.
- 신규 서비스 계층 없이 기존 인프라(`PlaceSearch`, `Store.addActivityWithTravel`)를 재사용한 확장이라 Tier L의 "> 1000 LOC 또는 헌법적 변경" 사유로 올린 것은 아니다 — 순수하게 REQ/AC 개수 초과가 이유다.
- **(v0.3.0 수정, D3)** Tier L을 선언한 이상 `research.md`/`design.md`도 Tier L 필수 산출물이라는 plan-auditor 지적을 반영해 두 파일을 신규 작성했다 — `research.md`는 아래 M1(Day 8 배달/요리 API 조사)의 내용을 그대로 옮긴 것이고, `design.md`는 이미 코드에 반영돼 있는 아키텍처 결정 3건(PlaceSearch/`Store.addActivityWithTravel` 재사용, `activityId` 채택)을 사후(as-built) 기록한 것이다. 신규 리서치를 새로 수행한 것은 아니다 — 이미 존재하던 조사·결정을 올바른 Tier L 파일 위치로 옮긴 것뿐이다.

이 SPEC은 **사후(as-built) 기준선** 문서라 M1~M4는 이미 완료된 작업의 정식화이고, M5(Day 8)만 실제 미해결 결정이다. 아래 마일스톤은 **결정 가역성(decision-reversibility)** 순서로 배치했다 — 아직 결론이 안 나 바뀔 가능성이 가장 큰 M5를 맨 앞에 두고, 이미 코드로 확정된 M2~M4를 데이터모델→API확장→UI 순으로, 기계적 검증 작업(M6~M8)을 맨 뒤에 둔다.

## 1. 마일스톤

### M1 — Day 8: 배달/요리 카테고리 조사 (완료 — 2026-09-12)

**상태**: ✅ 조사 완료, 결론: **당분간 구현하지 않는다(스코프 제외 유지)**.

**작업**: 요기요·배민 공식 오픈 API가 개인 개발자에게 열려있는지 웹 검색으로 확인 → 없으면 URL scheme 딥링크(`yogiyo://`, `baemin://` 등 존재 여부) 방식으로 결론.

**조사 결과**:
- **공식 오픈 API**: 배달의민족·요기요 둘 다 개인 개발자 대상 공식 오픈 API 프로그램을 찾지 못했다. 존재하는 것은 제휴사 수준의 주문연동 API(`woowabros/OrderRelaySampleCode` 등 — 배달대행업체 대상, 개인 앱 개발자가 신청 가능한 구조가 아님)뿐이다.
- **URL scheme 딥링크**: `yogiyo://` 스킴이 존재한다는 커뮤니티 자료(블로그)는 있으나 경로·파라미터 규격을 공식 문서로 확인할 수 없었다. `baemin://`/`baedalmin://`은 존재 여부조차 신뢰할 수 있는 자료로 확인되지 않았다.
- **결론**: 두 경로 모두 "그때그때 작동하다 앱 업데이트로 깨질 수 있는 비공식 방식"이라 신뢰도가 낮고, 설령 스킴이 맞다 해도 "앱을 그냥 여는 것"만 가능해 특정 식당·메뉴로 연결하는 의미 있는 딥링크는 만들 수 없다(경로 규격 비공개).
- **결정**: 배달·요리 카테고리는 **이번 MVP 스코프에서 계속 제외**한다. `MealCategory.delivery`/`.cooking`은 `Models.swift`에 열거형 케이스로 남겨두되(향후 공식 API가 열리거나 딥링크 규격이 공개되면 재검토), 이걸 만드는 UI·AI 경로는 추가하지 않는다 — **죽은 코드가 아니라 "의도적으로 보류된 예약 케이스"**로 취급한다.

**대상**: `plan.md`(이 파일 + 프로젝트 루트 `plan.md`, 조사 결과 기록) + `research.md`(v0.3.0에서 이 조사 내용을 정식 Tier L 리서치 문서로 옮김) — 코드 변경 없음.

**완료 기준**: 배달 카테고리 구현 방식이 확정되어 다음 세션 프롬프트에 바로 쓸 수 있음 — **확정됨: 구현하지 않음(보류)**.

**관련 REQ**: REQ-017(While 조사 미결 동안 delivery/cooking 생성 금지 — 이제 "무기한 보류 동안"으로 조건 갱신, 구 REQ-040), REQ-018(조사 결론 후 활성화, 조건부 — 트리거 조건이 "공식 API 개방 또는 딥링크 규격 공개 확인 시"로 구체화됨, 구 REQ-041).

### M2 — Day 6: 데이터 모델 (완료 — 2026-09-10)

**상태**: ✅ 완료.

**작업**: `Models.swift`에 `MealCategory`(외식/배달/요리)·`MealLog` 추가. `Store`에 `@Published var meals` + `meals.json` 로드/저장(`activities` 패턴) + `addMeal`/`updateMeal`/`deleteMeal`/`recentMeals(limit:)`. `meals`는 `daysWithSchedule` 캐시에 넣지 않음.

**대상 파일**: `Shared/Models.swift`, `Shared/Store.swift`

**관련 REQ**: REQ-001, REQ-002, REQ-003, REQ-004

**완료 기준**: iOS·macOS 빌드 무경고. JSON 왕복 12항목 검증 스크립트 통과(빈 배열, 세 카테고리, optional 필드 nil/비nil, loggedAt, 최신 우선 정렬, 모르는 카테고리 디코드 실패 시 기존 값 유지).

### M3 — Day 7: 목적지 주변 장소 검색 확장 (완료 — 2026-09-11)

**상태**: ✅ 완료.

**작업**: 프록시 `/kakao/local/keyword`에 `category_group_code`·`x`·`y`·`radius`·`sort`·`page` 파라미터 추가(배포 완료). `PlaceSearch.nearbyPlaces(category:near:radius:limit:)` — FD6/CE7 거리순. `EventDetailView`에 "목적지 주변" 섹션(펼쳤을 때만 조회).

*원래 계획은 `DirectionsService`와 같은 레벨의 신규 `MealSuggestionService`를 만드는 것이었으나, xcodegen 재생성(=서명 리셋) 회피를 위해 기존 파일(`PlaceSearch.swift`/`Models.swift`)에 넣는 쪽으로 바꿨다.*

**대상 파일**: `Shared/PlaceSearch.swift`, `Shared/Models.swift`, `Shared/EventDetailView.swift`, `proxy/src/index.js`

**관련 REQ**: REQ-005, REQ-006, REQ-007(구 REQ-010~012)

**완료 기준**: 일정 상세에서 목적지 주변 맛집 리스트 3~5개 표시 확인(강남역 좌표로 프록시 직접 호출해 결과 확인 완료).

### M4a — Day 9: AI 추천 툴 `recommend_meal` (완료 — 2026-09-12)

**상태**: ✅ 완료.

**작업**: `AIAssistant`에 `recommend_meal` 툴 추가(선언 `AIAssistant.swift:604`, 실행 `executeRecommendMeal`). Day 7의 `nearbyPlaces` 재사용, Gemini 형식 툴 선언 계약 유지. **계획과 다른 점**: `budget` 인자 미포함(Phase 3 미도래), 최근 `meals` 이력 미주입(고정 토큰 재증가 방지). 인자는 `keyword`/`category`/`at_iso`/`place_query`/`radius_meters`.

**대상 파일**: `Shared/AIAssistant.swift`

**관련 REQ**: REQ-008, REQ-009, REQ-010, REQ-011, REQ-012(구 REQ-020~024)

**완료 기준**: AI 채팅에 "저녁 뭐 먹을까"로 물으면 추천 응답 1회 성공.

### M4b — Day 10: 전용 화면 및 활동+이동 등록 (완료 — 2026-09-12)

**상태**: ✅ 완료.

**작업**: 계획의 `MealSuggestionService`+`Store.addEvent` 대신 신규 `FullSirView.swift` + 기존 `Store.addActivityWithTravel`로 구현. 식당 선택 → "식사 활동 블록 + 왕복 이동" 한 번에 등록, 출발·복귀 이동수단 각각 선택. 연결 필드는 `activityId`(계획의 `scheduledEventId`가 아님). 일정 삭제 시 미래 식사 기록만 함께 삭제.

**대상 파일**: `Shared/FullSirView.swift`(신규), `Shared/Store.swift`, `Shared/RootView.swift`

**관련 REQ**: REQ-013, REQ-014, REQ-015, REQ-016(구 REQ-030~033)

**완료 기준**: 추천 선택 → 활동+왕복 이동 등록 + `meals.json` 기록 확인.

**참고 — plan.md 원문과의 차이(중요)**: 아래 §2 "M6 코드 검사"의 원래 체크리스트 문구("`FullSirView.save()`가 `store.activities.last { 제목·시작시각 일치 }`로 되찾는다")는 **수정 전 상태를 기술한 낡은 문구**다. spec.md §3 및 REQ-015(구 REQ-032)가 이미 명시하듯, 실제 코드는 `addActivityWithTravel`의 반환값(`activityId: UUID`)을 직접 저장하도록 고쳐졌다(커밋 `c6f851e`). acceptance.md의 해당 AC 항목은 이 실제 상태를 반영해 작성한다.

### M5 — Day 11: 코드 검사 (완료 — 2026-09-12)

**상태**: ✅ 완료. AC-100~109 중 9건 PASS(코드 읽기로 확인, acceptance.md에 근거 기록), AC-105(토큰 재측정)만 정적 검사로 측정 불가 — Day 12 실기기 테스트 때 실제 AI 호출로 겸사겸사 확인 권장. 새로 발견된 결함 없음(D1~D3의 SPEC 서술 정정은 plan-phase에서 이미 반영 완료).

**작업**: §5-1 공통 체크리스트 + Phase 1 전용 6항목(acceptance.md AC-101~106) + plan-auditor D3 지적으로 추가된 3항목(AC-107 await-스테일 참조 일반 점검, AC-108 신규 알림의 iOS 64건 한도 영향, AC-109 카카오 API 할당량 소진 시 동작) + Day6 데이터모델군 추적성 보완(AC-100, MealLog 디코드 실패 범위 확인) — 전부 Given-When-Then으로 전개돼 있다.

**대상 파일**: `Shared/Models.swift`, `Shared/Store.swift`, `Shared/PlaceSearch.swift`, `Shared/FullSirView.swift`, `Shared/AIAssistant.swift`

**완료 기준**: 체크리스트 전 항목 확인, 발견 사항은 M7(Day 13 안정화)로 넘김.

### M6 — Day 12: 실기기 테스트 (미실행)

**상태**: ⬜ 미실행.

**작업**: §5-2 공통 절차 + Phase 1 전용 7항목(acceptance.md AC-201~207에 Given-When-Then으로 전개).

**완료 기준**: 체크리스트 전 항목 실행, 결과 기록.

### M7 — Day 13: 안정화 (미실행)

**상태**: ⬜ 미실행.

**작업**: §5-3 공통 기준 — M5·M6에서 발견된 문제 전부 수정하거나 "알려진 이슈"로 명시. 회귀 문제 최우선 수정. `STATUS.md` 갱신.

**완료 기준**: be full sir MVP 완료, 회귀(기존 be on-time sir 기능) 이상 없음.

## 2. 기술 접근

- 신규 AI 클래스·신규 서비스 계층을 만들지 않는다 — `recommend_meal`은 `AIAssistant`의 기존 툴 루프에, `FullSirView`는 기존 `Store.addActivityWithTravel`을 재사용해 얹었다.
- `Store`가 단일 허브 — `meals` 배열도 `Store`에 직접 추가.
- 앱은 AI 백엔드를 모른다 — Gemini `generateContent` 와이어 포맷 유지, 프록시가 실제 백엔드 전환을 흡수.
- 같은 계산 중복 금지 — `nearbyPlaces`는 `EventDetailView`와 `recommend_meal` 양쪽이 재사용.

## 3. 리스크

| 리스크 | 영향 | 대응 |
|---|---|---|
| Day 8 결론이 M5(Day 11) 이전에 안 나면 | `MealCategory.delivery`/`.cooking`이 죽은 코드인지 판정 불가 | Day 8을 Implementation Kickoff Approval 전에 반드시 해소 |
| `recommend_meal` 추가로 요청당 고정 토큰 증가 | AI 채팅 API 비용/응답 속도 | M5에서 재측정, 5,804 기준선 대비 증가폭 확인(§1 최적화 기록 유지) |
| `FullSirView.save()` 관련 plan.md 원문과 실제 코드 불일치 | 코드 검사 시 이미 고친 걸 다시 고치려는 혼선 | M4b 참고 문단 + acceptance.md에 실제 상태 명시 |

## 4. 의존 관계 (spec.md §5와 동일)

- 선행: be on-time sir(완성) — `Store.addActivityWithTravel`, `PlaceSearch(search())`, `ScheduleLogic`.
- 후행: `SPEC-HEALTHY-001`(estimatedCalories), Day 8 결론에 따른 배달/요리 구현(별도 후속 SPEC 후보).
