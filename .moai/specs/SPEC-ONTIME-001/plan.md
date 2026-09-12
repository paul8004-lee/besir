# SPEC-ONTIME-001 — plan.md (as-built)

> spec.md와 마찬가지로 이 문서도 **사전 설계 계획이 아니라 as-built 베이스라인**이다. 아래 M1~M9는 "앞으로 만들 작업"이 아니라 "이미 완료된 기능을 spec.md REQ 그룹에 매핑한 것"이며, M10~M11만 실제로 남은 작업(라이브 재검증)이다.

## 0. Tier 판단

**Tier: L**

- 근거: be on-time sir가 건드리는 파일이 15개를 훌쩍 넘김(`ContentView`, `Store`, `AIAssistant`, `GoogleCalendarService`, `NotificationManager`, `DirectionsService`, `KakaoMapView`/`RouteMapView`, `LocalMapServer`, `ShareViewController`, `SharedInbox`, `App.swift`(`enum BackgroundSync`가 들어 있는 파일 — `BackgroundSync`는 별도 파일이 아니다), `FavoritesView`, `AddEventView`, `EventDetailView`, `ActivityDetailView`, `Models.swift` 등) + 전체 LOC가 1000줄을 훨씬 초과 + besir의 다른 4개 서비스가 이 SPEC의 `Store` 계약에 의존하는 구조적(constitutional) 성격.
- spec.md frontmatter에 이미 `tier: L`로 반영됨.
- 다만 design.md/research.md는 만들지 않는다 — as-built 문서라 "설계 결정"이 아니라 "코드 확인"이 필요하고, 이는 이미 spec.md 작성 시 코드베이스 직접 확인으로 갈음했다.

## 1. 마일스톤 (spec.md REQ 그룹 매핑, 전부 이미 구현됨)

의사결정 가변성이 낮은 순(변경 가능성이 낮은, 이미 안정화된 것)부터가 아니라 — 이 문서는 as-built이므로 "리스크가 큰 것 먼저"로 정렬한다. 핵심 계산(M1)과 데이터 정합성(M5 캘린더 동기화)이 가장 회귀 위험이 크므로 앞에 둔다.

**M 번호는 리스크 순, AC 번호는 spec.md 절 순이라 둘이 어긋난다.** M1/M10/M11만 같은 번호의 AC와 맞고 M2~M9는 다른 AC를 가리키므로(예: M5=§2.7=AC-007인데 AC-005=§2.5=M2), 아래 표에 `AC` 열을 두어 대응을 명시한다. 번호 체계는 양쪽 다 재배열하지 않는다 — 필요한 것은 재번호가 아니라 이 crosswalk다.

| M | REQ 그룹 (spec.md §) | AC | 요약 | 상태 |
|---|---|---|---|---|
| M1 | §2.1 REQ-001~003 | AC-001 | 출발시각 역산(`Store`), 도착/출발 앵커 입력, 실패 시 고정 블록·겹침 배너 | ✅ 구현됨 |
| M2 | §2.5 REQ-040~043 | AC-005 | 구글 캘린더 양방향 동기화, tombstone, reminders 정책 | ✅ 구현됨 |
| M3 | §2.3 REQ-020~022 | AC-003 | 복합 반복 출퇴근(왕복+점심), 반복 그룹 전체/단건 분기 | ✅ 구현됨 |
| M4 | §2.6 REQ-050~053 | AC-006 | 통합 스와이프 캘린더, 드래그 재조정, 활동↔이동 블록 연동, 렌더/히트테스트 단일 출처(`span(for:)`) | ✅ 구현됨 |
| M5 | §2.7 REQ-060~063 | AC-007 | AI 채팅 11개 툴, Gemini 와이어 포맷 고정, 장기 기억 | ✅ 구현됨 |
| M6 | §2.9 REQ-080~081 | AC-009 | 백그라운드 동기화, 알림 64건 한도 대응 | ✅ 구현됨 |
| M7 | §2.2 REQ-010~011 | AC-002 | 즐겨찾기 장소, AI "집" 우선 매칭 | ✅ 구현됨 |
| M8 | §2.4 REQ-030 | AC-004 | 카카오맵 경로선 렌더링 | ✅ 구현됨 |
| M9 | §2.8 REQ-070~071 | AC-008 | Share Extension(App Group 큐), 오표시 버그 수정 | ✅ 구현됨 |

## 2. 남은 리스크 — 미검증 마일스톤 (plan.md 원본 line 194 인용)

plan.md(프로젝트 루트) §6 Phase 0.5 "남은 리스크" 항목을 그대로 마일스톤화한다. **둘 다 완료로 표시하지 않는다** — 빌드·설치는 됐지만 실기기 라이브 재확인이 없었다(2차 코드 점검 이후).

| M | AC | 내용 | 확인 방법 | 상태 |
|---|---|---|---|---|
| M10 | AC-010 | 알림 예약 갱신 회귀 확인 — `Store.rescheduleNearestNotifications(limit: 60)`이 기존 예약을 전부 지웠다 새로 까는 방식이라, 반복 일정 생성·앱 포그라운드 복귀 시마다 알림이 정상적으로 재예약되는지 | 실기기에서 반복 일정 생성 → 알림 도착 확인, 앱 백그라운드→포그라운드 전환 반복 후 알림 유실 여부 확인 | ⬜ 미확인 |
| M11 | AC-011 | 렌더/히트테스트 통합(`ContentView.span(for:)`) 후 회귀 확인 — 탭·드래그가 렌더링과 어긋나지 않는지, 특히 자정 넘김 블록·겹친 블록 히트테스트 | 실기기에서 자정 걸친 일정 탭/드래그, 겹친 블록 탭 시 올바른 상세정보가 뜨는지 확인 | ⬜ 미확인 |

## 3. 향후 `/moai run SPEC-ONTIME-001` 실행 시 예상 작업

이 SPEC은 대부분 이미 구현·상용화되어 있으므로, 향후 run-phase는 신규 구현이 아니라 다음 두 가지가 대부분을 차지할 것으로 예상한다:

1. **검증** — M1~M9는 코드 존재를 확인하는 회귀 테스트/스팟체크 위주. M10~M11은 실기기 라이브 재확인이 필수(빌드 검증만으로는 acceptance.md의 ⬜ 항목을 ✅로 바꿀 수 없음).
2. **갭 채우기** — 사용자가 추가 요청사항을 얹으면(예: 새 REQ), 그 부분만 신규 구현으로 처리하고 HISTORY에 버전 갱신 기록.

새 REQ를 추가할 때는 spec.md를 직접 갱신(HISTORY 버전 bump)하고, 이 plan.md에도 해당 마일스톤을 추가한다 — 이 문서를 새로 쓰지 않는다.

## 4. PRESERVE 목록

이 SPEC의 범위(§ Out of Scope 참고)를 벗어나는 아래 항목은 건드리지 않는다:

- be full sir(`Shared/PlaceSearch.swift`, `Shared/Models.swift`의 `MealCategory`/`MealLog` 등) — SPEC-FULL-001 소관
- `proxy/src/index.js`의 AI 백엔드 전환 세부 구현 — CLAUDE.md/프로젝트 루트 plan.md §1 SSOT
- be healthy/rich/fun sir 관련 코드 — 각자의 SPEC 소관
