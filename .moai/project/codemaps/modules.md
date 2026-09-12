# 모듈 카탈로그

> `Shared/`는 iOS·macOS 두 타깃에 그대로 컴파일되는 공용 소스. 파일당 한 줄 책임 + 주요 의존 대상.

## 데이터 / 상태

| 파일 | 주요 타입 | 책임 |
|---|---|---|
| `Models.swift` | `TransportMode`, `Place`, `ScheduledEvent`, `ScheduleAnchor`, `ScheduleLogic`, `RecurrenceRule`, `KoreanHolidays`, `MealCategory`, `MealCategoryFilter`, `NearbySort`, `NearbyPlace`, `MealLog`, `ActivityBlock` 등 | 도메인 모델 + 순수 함수형 판단 로직(휴일 계산, 겹침 판정 등) 전부 — 의도적으로 I/O 없이 독립 테스트 가능하게 유지 |
| `Store.swift` | `final class Store: ObservableObject` | 단일 허브 — `events`/`activities`/`meals`/`favorites` 배열, JSON 영속화(`~/Library/Application Support/besir/`), 구글 캘린더 동기화·정합, 알림 예약, 겹침 판정 |

## 화면 (SwiftUI)

| 파일 | 주요 타입 | 책임 |
|---|---|---|
| `RootView.swift` | `RootView` | 서비스 선택(be on-time sir ↔ be full sir) + 전역 `AIChatView` 시트 호스팅 |
| `ContentView.swift` | `ContentView` (951줄) | 메인 캘린더 화면. `span(for:)`가 렌더링·히트테스트 공용 단일 출처 |
| `AddEventView.swift` / `EventDetailView.swift` | `AddEventView`, `ConflictBanner` / `EventDetailView` | 이동 블록(`ScheduledEvent`) 생성/조회 |
| `AddActivityView.swift` / `ActivityDetailView.swift` | `AddActivityView`, `PlaceField` / `ActivityDetailView` | 체류 블록(`ActivityBlock`) 생성/조회. `ActivityDetailView`엔 "목적지 주변" 맛집 추천 섹션도 있음(be full sir 연계) |
| `FullSirView.swift` (486줄) | `FullSirView` | be full sir 화면 — 기준 위치 선택(현재 위치/일정 목적지/직접 검색) → 맛집 검색 → 식사 일정 등록 |
| `FavoritesView.swift` | `FavoritesView` | 즐겨찾기 장소 CRUD |
| `SettingsView.swift` | `SettingsView` | 앱 설정, AI 기억 목록 관리 |
| `AIChatView.swift` | `AIChatView` | `AIAssistant`에 묶인 채팅 UI |
| `Theme.swift` | `Theme`(enum), `BesirMark` | 색 토큰 단일 출처 + 앱 로고 도형(기하 상수는 `Tools/MakeAppIcon.swift`와 손으로 동기화해야 함) |

## 서비스 (외부 I/O·계산)

| 파일 | 주요 타입 | 책임 |
|---|---|---|
| `AIAssistant.swift` (1545줄) | `final class AIAssistant: ObservableObject` | 대화형 AI 비서. Gemini `generateContent` 와이어 포맷으로만 말함. 툴 호출 루프 + 11개 툴 실행기 소유 |
| `GoogleCalendarService.swift` | `GoogleCalendarService`, `Keychain`(enum) | OAuth(PKCE, `ASWebAuthenticationSession`) + 구글 캘린더 양방향 동기화, Keychain 리프레시 토큰 저장 |
| `DirectionsService.swift` | `DirectionsService` | 이동시간·경로 계산(자동차/대중교통/도보), 폴백 체인 |
| `PlaceSearch.swift` | `PlaceSearch` | 카카오 로컬 키워드 검색(장소 자동완성 + 주변 음식점/카페), MapKit 폴백 |
| `KakaoMapView.swift` | `KakaoMapView`, `Coordinator` | `Resources/map.html`(카카오맵 JS SDK) 호스팅 WKWebView 래퍼 |
| `RouteMapView.swift` | `RouteMapView` | 계산된 경로(segments)를 `KakaoMapView` 위에 그림 |
| `LocalMapServer.swift` | `LocalMapServer` | WKWebView가 도메인 고정된 오리진으로 카카오 JS SDK를 로드하도록 하는 앱 내 로컬 HTTPS 서버(`localhost:8089`, `Resources/localhost.p12`) |
| `LocationManager.swift` | `LocationManager` | 위치 권한/현재 위치/역지오코딩, IP 기반 폴백 |
| `NotificationManager.swift` | `NotificationManager` | 로컬 알림 예약, iOS 64건 대기 한도 준수 |
| `SharedInbox.swift` | `SharedInbox`(enum) | App Group 파일 큐 — 공유 확장이 텍스트/이미지를 메인 앱에 넘기는 통로 |
| `Config.swift` | `AppConfig: Codable` | 설정(프록시 URL, 앱 토큰, 카카오 JS 키, 구글 클라이언트 ID, 사용자 선호), JSON 영속화, 프록시 요청 빌더 |
| `App.swift` | `BackgroundSync`(enum), `@main BesirApp` | 앱 진입점, `BGTaskScheduler` 등록, 환경객체 배선, 씬 단계 기반 동기화 |

## `proxy/src/index.js` (단일 파일, 454줄, 클래스 없이 함수만)

| 함수 | 책임 |
|---|---|
| `fetch(request, env)` | 라우터 진입점 |
| `toResponsesRequest` / `toOpenAIRequest` | Gemini→OpenAI 요청 변환(두 가지 OpenAI API 형태) |
| `responsesToGeminiShape` / `toGeminiShape` | 역변환(OpenAI→Gemini) |
| `proxyOpenAI` / `proxyWorkersAI` | 백엔드 호출자 |
| `proxyClaude` | 레거시, 현재 미사용 |
| `proxyKakaoDirections` / `proxyKakaoKeyword` / `proxyOdsay` | 카카오/ODsay 패스스루(서버 쪽에서 키 주입) |
| `redactSecrets` | 에러 본문에서 비밀값 제거 |
| `lowercaseSchemaTypes` | Gemini `"STRING"` → OpenAI `"string"` 스키마 타입 정규화 |

## 기타

| 파일 | 책임 |
|---|---|
| `ShareExtension/ShareViewController.swift` | 공유 시트에서 텍스트/이미지 추출 → `SharedInbox.enqueue` |
| `Tools/MakeAppIcon.swift` | 빌드 타깃이 아닌 앱 아이콘 생성 스크립트. `Theme.BesirMark`와 기하 상수 수동 동기화 필요 |
