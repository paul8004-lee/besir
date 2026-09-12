# 진입점 카탈로그

## 앱 진입점 — `@main struct BesirApp: App` (`Shared/App.swift`)

`init()`에서 순서대로 조립:

1. `NotificationManager()` 생성
2. `Store(notifications:)` 생성 (`NotificationManager` 주입)
3. `LocationManager()` 생성
4. `AIAssistant(store:location:)` 생성

이어서 `BGTaskScheduler` 등록(`com.iseongmin.besir.sync`)하고, `RootView()`를 4개의 `.environmentObject()`(Store/AIAssistant/LocationManager/NotificationManager로 추정)로 감싸 렌더링. 씬 단계가 `.active`가 될 때 `SharedInbox.drain()`을 호출해 공유받은 항목을 처리한다.

## 공유 확장 진입점 — `final class ShareViewController: UIViewController` (`ShareExtension/ShareViewController.swift`)

- `project.yml`에 `NSExtensionPrincipalClass`로 등록됨
- `viewDidLoad`에서 `extensionContext.inputItems`로부터 텍스트/이미지/URL 추출
- `SharedInbox.enqueue(...)` 호출 후 즉시 익스텐션 요청 완료
- **`Store`/`AIAssistant`를 직접 건드리지 않는다** — App Group 파일 큐를 통한 순수 전달만 담당

## 프록시 진입점 — `export default { async fetch(request, env) }` (`proxy/src/index.js`)

`X-App-Token` 검사(`/`, `/health` 제외) 후 라우팅:

| 경로 | 처리 |
|---|---|
| `POST /ai/chat` | 메인 경로 — `proxyOpenAI` 또는 `proxyWorkersAI`로 분기 |
| `POST /claude/messages` | 레거시, 현재 미사용 |
| `GET /kakao/directions` | `proxyKakaoDirections` |
| `GET /kakao/local/keyword` | `proxyKakaoKeyword` |
| `GET /odsay/*` | `proxyOdsay` |

## 앱 → 공유 처리 흐름 진입점 — `BesirApp.processSharedInbox()` (추정 위치 `App.swift`)

`SharedInbox.drain()` → `AIAssistant.handleShared(text:imageData:mimeType:)` → 이후는 일반 AI 채팅과 동일한 툴 호출 루프를 탄다.
