# 핵심 데이터 흐름

## 1. 수동 일정 등록 (be on-time sir)

```
AddEventView / AddActivityView (사용자 입력: 장소·시각·이동수단)
  → Store.addEvent / Store.addActivityWithTravel
      → DirectionsService (이동시간 계산) → ScheduleAnchor 기준 출발 시각 역산
      → events.json / activities.json 저장
      → NotificationManager (출발 알림 예약, iOS 64건 한도 내에서 가까운 것부터)
      → (구글 캘린더 연결 시) GoogleCalendarService.createEvent
```

**단일 출처 원칙**: 렌더링과 히트테스트가 같은 `ContentView.span(for:)`를 공유 — 예전엔 따로 계산하다 어긋난 적이 있어 통합됨.

## 2. AI 채팅 툴 호출 루프

```
AIChatView (사용자 메시지)
  → AIAssistant.callAI() → proxy POST /ai/chat (Gemini generateContent 와이어 포맷 고정)
      → proxy/src/index.js: 백엔드(OpenAI Responses API 우선, Workers AI 폴백)로 변환·전달
      → 모델이 함수 호출(예: create_activity) 반환
  → AIAssistant가 해당 executor 실행(예: executeCreateActivity)
      → Store.addActivityWithTravel(...) 등 호출 → 위 흐름 1과 합류
  → 결과를 다시 proxy에 함수 결과로 전송 → 모델이 최종 텍스트 응답
  → 대화 기록은 ai_history.json에 영구 저장(이미지 base64는 턴이 끝나면 텍스트로 치환, 최근 40턴만 유지)
```

## 3. 카카오톡 공유 → 일정 자동 등록

```
다른 앱(카카오톡 등)에서 "공유" → ShareViewController.viewDidLoad
  → SharedInbox.enqueue(text/image) — App Group 파일 큐(pendingShares.json)
  (익스텐션은 여기서 끝, Store/AIAssistant 관여 없음)

BesirApp이 포그라운드 진입(scenePhase == .active)
  → SharedInbox.drain() → AIAssistant.handleShared(text:imageData:mimeType:)
  → 흐름 2(AI 채팅 툴 호출 루프)와 동일한 경로 → 일정 자동 등록
  → AIChatView 자동 오픈으로 사용자에게 결과 표시
```

## 4. be full sir 식사 추천 → 일정 등록 (2026-09-12 Day 13 기준)

두 경로가 있고 최종적으로 같은 저수준 함수(`Store.addActivityWithTravel` + `Store.addMeal`)로 모인다.

**경로 A — 화면에서 직접**:
```
FullSirView: 기준 위치 선택(현재 위치 / 오늘 일정 목적지 / 직접 검색)
  → PlaceSearch.nearbyPlaces(category:near:) — 카카오 로컬 category_group_code(FD6/CE7)
  → 사용자가 식당 선택 → MealScheduleSheet
      → 출발지는 "직전 일정" 또는 현재 위치로, 복귀지는 "다음 일정" 또는 (없으면) 출발지로 자동 제안
      → save() → Store.addActivityWithTravel(travelFrom:returnTo:...) → 활동+왕복 이동 생성
      → Store.addMeal(activityId: 방금 만든 활동의 id) → meals.json에 기록("최근 먹은 것"에 반영)
```

**경로 B — AI 채팅에서**:
```
"저녁 뭐 먹지" → AIAssistant.recommend_meal → PlaceSearch.nearbyPlaces (검색만, 등록 안 함)
  → "그거로 일정 잡아줘" → AIAssistant.create_activity(place_query, travel_from_query, return_to_query, log_as_meal:true)
      → Store.addActivityWithTravel(...) → 활동+이동 생성
      → log_as_meal이 true면 Store.addMeal(activityId:)까지 같이 호출 → meals.json 기록
```

**일정 삭제 시 되돌림**: 활동을 지우면 `Store.removeUpcomingMeals` → `ScheduleLogic.mealsToRemove`가 "아직 안 먹은"(플랜만 있고 실제 과거가 아닌) 식사 기록을 같이 지운다. 이미 지난 식사는 실제 기록이라 남는다.

## 5. 구글 캘린더 동기화 (양방향)

```
Store.syncWithGoogle()
  1. 묘비 스냅샷 고정(deleted_gcal_ids.json) — 이번 라운드 삭제 판정 기준
  2. GoogleCalendarService.fetchBesirItems() — besir=1 태그 항목 한 번에 조회
  3. 로컬에만 있고 원격에 없음 → 업로드(googleEventId 저장)
  4. 원격에만 있고(besir 표시 있음) 로컬에 없음 → Store.reconcileActivities로 판정
     (제목·시각(±60초) 같으면 중복 무시 / 진짜 새 항목이면 가져오기 / besir가 모르면 캘린더에서 삭제)
  5. 묘비가 있는데 원격에 남아있으면 재삭제 시도, 원격 부재 확인된 묘비만 정리
```

모든 삭제 경로는 `Store.removeFromCalendar(_:)` 하나로 통일되어 있어(9곳), fire-and-forget 삭제가 조용히 실패해도 묘비가 다음 동기화에서 다시 잡아낸다.
