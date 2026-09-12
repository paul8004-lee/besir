# SPEC-FULL-001 — design.md

> v0.3.0에서 신규 작성(plan-audit D3). 이 SPEC은 사후(as-built) 기준선 문서이므로, 이 design.md도 앞으로 만들 것을 설계하는 문서가 아니라 **이미 코드에 반영된 아키텍처 결정과 그 근거를 사후에 기록**한다. 원래 계획(plan.md 최초안)과 실제 구현이 갈라진 세 지점을 다룬다.

## D-1. `MealSuggestionService` 신규 생성 대신 기존 `PlaceSearch`/`Models.swift` 재사용 (Day 7, plan.md M3 참고)

**원래 계획**: `DirectionsService`와 같은 레벨의 신규 `MealSuggestionService`를 만들어 목적지 주변 장소 검색을 담당시킨다.

**실제 결정**: 신규 서비스 파일을 만들지 않고, 기존 `PlaceSearch.swift`에 `nearbyPlaces(category:keyword:near:radiusMeters:sort:limit:)`를, 기존 `Models.swift`에 관련 타입(`MealCategoryFilter`, `NearbySort`)을 추가했다.

**왜**: `Shared/`·`Resources/`에 새 소스 파일을 추가하면 `xcodegen generate`가 필요하고, 이 커맨드는 Xcode 서명 계정을 리셋시킨다(`No Account for Team`) — 그러면 사용자에게 besir-iOS·besirShare 두 타깃 모두 Team 재선택을 요청해야 한다. 기존 파일에 메서드를 추가하는 쪽이 이 부수 비용을 피한다. 또한 `nearbyPlaces`는 `search()`와 같은 프록시 호출 관례(`config.proxyRequest`, `/kakao/local/keyword`)를 그대로 재사용할 수 있어, 별도 서비스 계층이 제공할 추상화의 이득이 작았다.

**대가**: `PlaceSearch.swift`가 두 가지 책임(일반 장소 검색 + 목적지 주변 맛집 검색)을 갖게 됐다. 파일이 계속 커지면 분리를 재검토할 수 있으나, 현재 규모에서는 "같은 계산을 두 곳에 두지 않는다"는 계약(프록시 호출 관례 공유)을 지키는 쪽이 우선이었다.

**근거 REQ**: REQ-005~007(구 REQ-010~012).

## D-2. `Store.addEvent` 기반 신규 화면 대신 `Store.addActivityWithTravel` 재사용 (Day 10, plan.md M4b 참고)

**원래 계획**: `MealSuggestionService`(D-1의 계획)로 얻은 추천을 `Store.addEvent`로 새 일정을 만드는 흐름.

**실제 결정**: 신규 화면 `FullSirView.swift`를 만들되, 일정 등록은 기존 `Store.addActivityWithTravel`을 그대로 재사용했다 — 식당 선택 시 "식사 활동 블록(체류형) + 왕복 이동(이동형)"을 한 번에 등록하고, 출발·복귀 이동수단은 각각 선택한다.

**왜**: `Store`가 단일 허브라는 계약(CLAUDE.md 하드 계약 3)상, 새 서비스 계층을 만들기보다 이미 "활동+이동"을 함께 다루는 기존 함수를 재사용하는 편이 일관성이 높다. 식사는 "이동"이 아니라 "그 자리에 머무는 활동"에 왕복 이동이 붙는 구조라, `addEvent`(단일 이동 일정)보다 `addActivityWithTravel`(체류형 블록 + 왕복 이동)의 의미가 더 정확히 맞아떨어진다.

**근거 REQ**: REQ-013(구 REQ-030).

## D-3. `MealLog`의 연결 필드 — `scheduledEventId` 대신 `activityId` 채택 (Day 6/10, REQ-014/015 근거)

**원래 계획**: `MealLog`가 연결되는 대상은 "이동 일정"(`ScheduledEvent`)이므로 필드명은 `scheduledEventId`였다.

**실제 결정**: D-2에서 식사 등록이 `addActivityWithTravel`(활동 블록 생성)을 쓰기로 바뀌면서, `MealLog`가 실제로 묶이는 대상도 이동 일정이 아니라 **활동 블록**(`ActivityBlock`)이 됐다. 그래서 연결 필드명도 `activityId`로 바뀌었다(`scheduledEventId`는 optional 필드로 여전히 남아 있으나, be full sir 경로에서는 쓰이지 않는다).

이와 짝을 이루는 실행부 결정: `FullSirView.save()`는 `await store.addActivityWithTravel(...)`의 반환값(`activityId: UUID`)을 **직접** `MealLog.activityId`에 저장한다. 한때(plan.md 원문 체크리스트에 남아 있던 낡은 문구 기준) "제목·시작 시각으로 `store.activities`를 재검색해 되찾는" 방식이 고려됐으나, 이는 같은 이름·같은 시각의 활동이 이미 있으면 엉뚱한 쪽에 잘못 연결되는 버그 패턴이라 채택되지 않았다 — 반환값을 직접 쓰는 방식으로 확정됐다(커밋 `c6f851e`).

**왜**: 반환값 직접 사용은 "id로 직접 받는다"는 한 줄로 설명되는 단순한 계약이고, 재조회 방식이 갖는 동명이시각 충돌 위험이 전혀 없다. `Store`가 이미 생성 시점에 정확한 id를 돌려주므로, 이를 버리고 다시 찾는 것은 불필요한 재작업이자 위험의 원천이었다.

**근거 REQ**: REQ-014, REQ-015(구 REQ-031, REQ-032).

## 참고

- 이 세 결정 모두 spec.md §1(배경)·§2(REQ 본문)·§3(비기능 요구사항)에 이미 산발적으로 기록돼 있었다 — 이 design.md는 그 근거를 한 곳에 모아 Tier L 산출물 요건을 충족시킨 것이다.
- 새로운 설계 결정은 없다 — 전부 이미 코드로 확정·배포 가능 상태인 as-built 기록이다.
