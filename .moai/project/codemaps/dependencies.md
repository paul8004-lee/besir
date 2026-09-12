# 의존 관계 그래프

## 앱 쪽 (Swift)

```mermaid
graph TD
    App["App.swift · BesirApp"] -->|constructs, init 순서 중요| Notif["NotificationManager"]
    App --> Store["Store (ObservableObject 허브)"]
    App --> Loc["LocationManager"]
    App --> AI["AIAssistant"]
    App -->|renders| Root["RootView"]

    Root --> CV["ContentView"]
    Root --> Full["FullSirView"]
    Root --> Fav["FavoritesView"]
    Root --> Set["SettingsView"]
    Root --> Chat["AIChatView"]

    CV --> AEV["AddEventView / EventDetailView"]
    CV --> AAV["AddActivityView / ActivityDetailView"]

    Store --> GCal["GoogleCalendarService (per-call)"]
    Store --> Dir["DirectionsService (per-call)"]
    Store --> Places["PlaceSearch (per-call, View에서 직접도 씀)"]
    Store --> Notif
    Store --> Logic["ScheduleLogic (Models.swift, 순수 함수)"]

    AI --> Store
    AI --> Places
    AI --> Loc
    AI -->|POST /ai/chat| Proxy["proxy/src/index.js"]

    Map["KakaoMapView / RouteMapView"] --> LMS["LocalMapServer"]
    Map --> Dir

    Share["ShareExtension.ShareViewController"] --> Inbox["SharedInbox (App Group 파일)"]
    App -->|scenePhase active 시 drain| Inbox
    Inbox --> AI
```

## 프록시 쪽 (Cloudflare Worker)

```mermaid
graph LR
    Fetch["fetch(request, env)"] --> AIChat["/ai/chat → proxyOpenAI / proxyWorkersAI"]
    Fetch --> Legacy["/claude/messages → proxyClaude (미사용)"]
    Fetch --> KDir["/kakao/directions → proxyKakaoDirections"]
    Fetch --> KKey["/kakao/local/keyword → proxyKakaoKeyword"]
    Fetch --> Od["/odsay/* → proxyOdsay"]

    AIChat --> Conv["toResponsesRequest/toOpenAIRequest ↔ responsesToGeminiShape/toGeminiShape"]
```

## 주목할 결합 패턴

- **이벤트버스 없음** — `structure.md`에 명시된 관례대로 "A가 Store의 B 배열을 읽는다"는 형태로만 서비스 간 연계가 이뤄진다. `AIAssistant`·`ContentView`·`FullSirView` 전부 `Store`의 배열·메서드에 직접 접근.
- **`ActivityBlock` ↔ `ScheduledEvent` 양방향 결합** — 진짜 순환 임포트는 아니지만(둘 다 `Store` 내부), `linkedActivityId`로 연결된 두 블록을 옮기거나 지우는 메서드(`moveActivity`, `deleteActivity`, `modifyEvent`, `realignReturnLeg`)가 서로의 상태로 되돌아 들어간다 — "연결 블록" 불변식(`Store.swift:124-181`, `276-284` 주석 참고).
- **`Tools/MakeAppIcon.swift` ↔ `Theme.BesirMark`** — 컴파일러가 강제하지 않는 수동 동기화 의존성. 한쪽 기하 상수를 고치면 반드시 다른 쪽도 같이 고쳐야 한다(CLAUDE.md에도 명시).
- **구글 캘린더만 예외** — 나머지 외부 API는 전부 프록시를 거치지만, `GoogleCalendarService`는 앱에서 직접 OAuth+Keychain으로 구글 API를 호출한다.
