# besir 아키텍처 개요

> 생성: 2026-09-12 (Explore 서브에이전트의 코드베이스 조사 기반). 최신 코드와 어긋나면 `/moai codemaps --force`로 다시 만든다.

## 한 줄 요약

**위치·일정을 묶어주는 iOS·macOS 앱**. `Shared/`의 SwiftUI 코드 하나가 `besir-iOS`·`besir-macOS` 두 타깃에 그대로 컴파일되고, `Store`(단일 `ObservableObject`)가 모든 도메인 배열(events/activities/meals/favorites)과 JSON 영속화를 쥔 허브다. 백엔드는 Cloudflare Worker(`proxy/`) 하나뿐이며, 앱은 실제 AI 백엔드가 무엇인지 모르고 항상 Gemini `generateContent` 와이어 포맷으로만 말한다(교체는 프록시의 변환 함수만 고치면 됨).

## 빌드 산출물 3개 + 백엔드 1개

| 대상 | 위치 | 비고 |
|---|---|---|
| `besir-iOS` | `Shared/` + `Resources/` | 메인 iOS 앱 |
| `besir-macOS` | `Shared/` + `Resources/` | 같은 소스, macOS 타깃 (조건부 `#if os(iOS)` 분기만 다름) |
| `besirShare` | `ShareExtension/` + `Shared/SharedInbox.swift` | 카카오톡 등에서 텍스트·이미지 공유 → besir로 전달하는 iOS 공유 확장 |
| Cloudflare Worker | `proxy/src/index.js` | 유일한 백엔드. AI(OpenAI/Workers AI)·카카오·ODsay 프록시 + 시크릿 보관 |

## 아키텍처 패턴

- **App 쪽**: DI 프레임워크·서비스 로케이터 없이, `BesirApp.init()`에서 의존성을 손으로 한 번 조립하고 `@EnvironmentObject`로 흘려보내는 가벼운 MVVM 스타일. 리포지토리/DAO 계층 없이 `Store`가 도메인 배열 + JSON 파일 저장을 직접 쥔다. 기능 간 연계는 이벤트버스가 아니라 "A가 Store의 B 배열을 읽는다"는 관례로 이뤄진다(`structure.md`에 명시).
- **확장 관례**: 새 기능은 새 저장 계층이 아니라 `Store`에 배열 하나 추가, 새 AI 클래스가 아니라 `AIAssistant`의 기존 툴 루프에 툴 추가, 새 최상위 내비게이션이 아니라 `RootView`의 서비스 선택에서 진입(`FullSirView`가 실제 사례).
- **Proxy 쪽**: 의도적으로 상태 없는 **번역 계층**. 앱은 항상 Gemini 와이어 포맷으로만 말하고, 실제 백엔드 선택(OpenAI Responses API 기본, Workers AI 폴백, Anthropic은 미사용 레거시)과 양방향 포맷 변환은 전부 `proxy/src/index.js`에 있다. 동시에 **시크릿 보관소** 역할도 한다 — 카카오·ODsay·OpenAI 키는 전부 Worker 시크릿, 앱 바이너리엔 비밀 아닌 값(카카오 JS 키, 프록시 URL, 앱 토큰)만 들어간다.
- **보안 경계**: 구글 캘린더만 예외적으로 앱이 OAuth+Keychain으로 직접 호출하고, 나머지 외부 API는 전부 프록시를 거친다.
- **데이터 모델**: `ScheduledEvent`(이동)·`ActivityBlock`(체류) 두 구조체가 `linkedActivityId`로 연결돼, 하나를 옮기거나 지우면 짝도 같이 움직이는 "연결 블록" 불변식이 `Store` 전반에 반복된다.

## 더 볼 문서

- [`modules.md`](modules.md) — 파일별 책임 목록
- [`dependencies.md`](dependencies.md) — 의존 관계 그래프
- [`entry-points.md`](entry-points.md) — 앱/공유확장/프록시 진입점
- [`data-flow.md`](data-flow.md) — 핵심 데이터 흐름 4가지
- 사업 맥락·서비스 로드맵은 `plan.md`, 기술 스택 상세는 `.moai/project/tech.md`, 폴더 구조는 `.moai/project/structure.md` 참고(이 codemaps는 그 위에 파일 단위 상세를 더한 것).
