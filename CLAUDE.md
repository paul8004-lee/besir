# besir — 작업 지침

한국어로 답한다. 코드 주석도 한국어로 쓰되, **무엇을 하는지가 아니라 왜 그렇게 했는지**를 적는다
(기존 파일들의 주석 밀도·어조를 그대로 따라간다).

## 무엇을 만들고 있나

위치와 일정을 묶어주는 iOS·macOS 앱. 사업계획서상 다섯 서비스를 순서대로 붙여나간다.

| 서비스 | 내용 | 상태 |
|---|---|---|
| be on-time sir | 일정·이동시간·출발알람·캘린더 동기화 | 완성, 고도화 중 |
| be full sir | 식사/맛집 | Phase 1 진행 중 |
| be healthy sir | 운동·건강 | Phase 2 |
| be rich sir | 지출 | Phase 3 |
| be fun sir | 여가 | Phase 4 |

핵심 계산: **출발 시각 = 도착 시각 − 이동시간 − 버퍼**. 여기서 나온 값으로 로컬 알림을 예약한다.

## 먼저 읽을 것

- **[plan.md](plan.md)** — 1차 참조 스펙. Day별 실행 리스트, 품질 게이트, 지금까지의 모든 버그·수정 이력.
  작업 시작 전 해당 Day 항목을 읽고, 계획이 실제와 달라지면 **그 자리에서 이 파일을 갱신**한다.
- **[CHECKLIST.md](CHECKLIST.md)** — 사용자 관점 요구사항 체크리스트(상황 → ✅/⚠️/❌ → 코드 근거).
- **[STATUS.md](STATUS.md)** — ⚠️ **2026-06-30 기준이라 낡았다.** AI 백엔드 서술(Claude `claude-opus-4-8`)이
  현재와 다르고 be full sir·UI 개편·로고가 빠져 있다. 사업계획서용 요약이므로 참고만 하고,
  기술적 사실은 plan.md를 믿는다.

## 절대 깨면 안 되는 계약

1. **앱은 AI 백엔드를 모른다.** `AIAssistant.swift`는 Gemini `generateContent` 와이어 포맷으로만 말하고,
   백엔드 전환은 `proxy/src/index.js`의 변환 함수에서만 일어난다. 새 AI 툴을 추가할 때도 이 포맷을
   따른다 — 함수 선언 타입은 **대문자**(`"STRING"`/`"OBJECT"`), 프록시가 `lowercaseSchemaTypes`로 내린다.
2. **비밀값은 앱에 두지 않는다.** 카카오·ODsay·OpenAI 키는 전부 Cloudflare Worker 시크릿.
   새 키를 추가하면 `redactSecrets()`의 목록에도 반드시 넣는다(에러 본문에 섞여 나간다).
3. **`Store`가 단일 허브다.** 서비스가 늘어도 `Store`에 배열을 하나씩 더하고, 서비스 간 연계는
   "A가 Store의 B 배열을 읽는다"로 구현한다. 이벤트버스·별도 영속화 레이어를 만들지 않는다.
4. **새 서비스마다 AI 클래스를 만들지 않는다.** `AIAssistant`의 기존 툴 루프에 툴을 추가한다.
5. **같은 계산을 두 곳에 두지 않는다.** 렌더링과 히트테스트가 따로 계산하다 어긋난 적이 있어
   `ContentView.span(for:)`이 단일 출처가 됐다. `BesirMark`(Theme.swift)와 `Tools/MakeAppIcon.swift`의
   기하 상수도 같은 이유로 **양쪽을 동시에** 고쳐야 한다.
6. **색을 직접 쓰지 않는다.** 전부 `Theme` 토큰을 거친다. 다크 모드는 기기 설정을 따르며
   `preferredColorScheme`을 강제하지 않는다.

## 빌드 · 배포

```bash
# 새 소스 파일이나 Info.plist 키를 추가했을 때만
xcodegen generate

# 빌드
xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build
xcodebuild -scheme besir-macOS -derivedDataPath build build

# 프록시
cd proxy && npm test && npx wrangler deploy

# AI 인자 가드 드라이버 — 모델 없이 결정적으로 돈다(API 할당량 안 씀)
cat Shared/EditCard.swift Shared/AIAssistant.swift Tools/GuardDriver.swift > /tmp/gd.swift \
  && swiftc -o /tmp/gd /tmp/gd.swift Shared/Store.swift Shared/Models.swift \
       Shared/Config.swift Shared/PlaceSearch.swift Shared/DirectionsService.swift \
       Shared/LocationManager.swift Shared/NotificationManager.swift \
       Shared/GoogleCalendarService.swift Shared/SharedInbox.swift -parse-as-library \
  && /tmp/gd
```

드라이버는 스스로를 격리한다 — 실행마다 임시 홈을 만들어 그 안에서만 쓰고, 머리말에서 구글
클라이언트 ID를 비우며, 내부 기한(기본 900초, 명령줄 인자 하나로 덮을 수 있음)이 지나면
스스로 끝난다. 실제 지원 디렉터리는 시작·종료에 읽어서 바이트로 대조만 한다.
종료 코드: **0** 통과 · **1** 단언 실패(`P/T 통과` 줄이 찍혔을 때만 — 블록이 `&&`로
이어지므로 그 앞의 1은 컴파일 실패다) · **2** 샌드박스 거부 · **3** 실제 디렉터리 변화 감지 ·
**124** 기한 초과. 외부 감시자(`sleep`+`kill` 등)는 필요 없다 — 굳이 두면 `wait` 직후 거둔다.

AI 인자 가드를 고쳤으면 `Tools/GuardDriver.swift`의 단언도 같이 갱신한다 — 이유와 제약은
그 파일 머리말에 있다.

**⚠️ `xcodegen generate`를 돌리면 Xcode 서명 계정이 리셋된다**(`No Account for Team`).
돌린 뒤에는 사용자에게 **besir-iOS·besirShare 두 타깃 모두** Team 재선택을 요청해야 한다.
`Shared/`·`Resources/`에 파일을 추가했을 때만 필요하고, `Tools/`는 빌드 대상이 아니라 불필요하다.

실기기(iPhone, UDID `8D9B807B-F874-5AD8-A62C-BC1731A31A1F`)는 `xcodebuild -allowProvisioningUpdates`로
서명한 뒤 `xcrun devicectl device install app` → `process launch`. 기기가 `unavailable`이면
사용자에게 연결·잠금해제를 요청하고 기다린다.

베타 폴더 이름을 바꿀 땐 Xcode에서 그 프로젝트를 **먼저 닫는다**. "workspace disappeared" 경고가
뜨면 답은 **Close**다(Re-save를 누르면 옛 경로에 껍데기 폴더가 생긴다).

## 작업을 시작할 때 — 하네스 전문가 배정 (사용자 지시, 매번 적용)

besir 작업은 명령 이름(`/moai run`이든 자연어 요청이든)이 아니라 **하는 일**로 판단한다.
무엇을 건드릴지 정해지는 즉시 아래 표로 명단을 뽑고, 시작 전에 사용자에게 한 줄로 알린다.
**사용자가 매번 지목해야 한다면 그건 내 쪽 실패다.**

| 이 조건이면 | 부르는 전문가 |
|---|---|
| `Shared/`의 SwiftUI 뷰를 건드리거나 새 화면 설계 | `ui-design` |
| Swift 기능 신규·수정, `Store`에 배열 추가 | `swift-impl` |
| AI 툴·`proxy/`·AI 백엔드 변경 | `ai-tooling` |
| **구현을 바꿨음 / 실기기 배포 전 / Day 마무리** | `code-safety` |
| **실기기 배포 전 / Day 마무리 / "뭘 확인해야 하나"** | `ux-check` |

- 걸리는 조건이 없으면 부르지 않는다 — 0명도 정상적인 답이다.
- 읽기 전용(빌드 게이트, 문서 인용 대조, 코드 열람)은 직접 한다. 하네스를 부르는 기준은
  **"코드를 바꿨거나, 바꾼 것을 판정해야 할 때"**다.
- 매니페스트 Sprint Contract의 `hazard_coverage`는 **"검사하지 않은 것 = 실패"**다.
  0건을 찾는 건 통과지만, 렌즈를 안 돌린 채 끝내는 건 통과가 아니다.

## Day를 끝낼 때 (사용자 지시, 매번 적용)

1. **요구사항 체크리스트**를 새로 만든다 — AI 채팅만이 아니라 **앱 전체 기능**을 쓰다 마주칠 상황 전부.
   화면 조작, 수동 생성·편집·삭제, 즐겨찾기·설정, AI 채팅, 알림, 캘린더 연동, 공유 확장,
   그리고 경계 상황(오프라인, 위치 권한 거부, 이동시간 계산 실패, 검색 0건, 자정 넘김, 강제 종료, 기기 잠금).
   이전 회차의 ❌/⚠️가 해결됐는지 갱신한다.
2. **코드 버그 검사** — `await` 앞뒤로 인덱스를 재사용하는 곳, 실패가 조용히 묻히는
   fire-and-forget `Task { try? ... }`, 무한 증가하는 상태와 외부 한도(iOS 알림 **64건**, API 일일 할당량),
   강제 언래핑, 경계 조건, iOS·macOS 양쪽 **무경고** 빌드.
3. **간결성 검사** — 복제된 계산, 죽은 코드, 루프 안의 반복 저장/네트워크 호출, 일을 너무 많이 하는 함수.
   발견하면 **그 자리에서 정리**하고 무엇을 왜 합쳤는지 기록한다.
4. 구멍을 **해결한 뒤** 실기기에 배포하고, 사용자에게 체크리스트와 함께
   **실기기에서 직접 확인해야 할 목록**을 준다(실제 알림 수신, 제스처 느낌, 캘린더 앱에 보이는 모습 등
   빌드로 검증 불가능한 것). 이때 **내가 검증할 수 있는 것은 내가 다 하고, 정말 못 하는 것만 넘긴다.**
5. **베타는 이 시점에 만들지 않는다.** 사용자 확인 결과와 추가 요청을 **전부 반영한 뒤**,
   사용자가 다음 Day로 넘어가자고 할 때 만든다.
   (Day 7 직후 성급히 만들었다가 같은 날 수정 요청이 들어와 폐기한 적이 있다.)
6. 베타는 `~/Projects/besir-beta-v0.1.0`, `v0.1.1` … 순으로 올리고 `BETA.md`에 변경 내역·복원 방법을 적는다.
   **확정된 베타는 수정하지 않는다** — 이후 작업은 `besir/`에서만 하고 다음 베타를 새로 뜬다.

한 Day에 새로 만들거나 크게 고치는 파일은 **3~4개**로 제한한다. 계획에 없는 리팩터링은 하지 않는다.

## 출시 전에 반드시 제거할 테스트용 코드

전부 `⚠️ 테스트용 임시` 주석이 달려 있다.

- `Store.deleteEverythingForTesting()` + [SettingsView.swift:71](Shared/SettingsView.swift#L71)의 "일정 모두 삭제" 블록
- `AIAssistant.transcriptForDebugging()` + [AIChatView.swift:56](Shared/AIChatView.swift#L56)의 대화 복사 버튼

## AI 백엔드 (2026-09-13 현재)

OpenAI **`gpt-5.6-luna`**, `/v1/responses` 엔드포인트, `reasoning.effort = "medium"`.
모델과 추론 강도는 [proxy/src/index.js](proxy/src/index.js)의 상수 두 줄이다.

- chat completions가 아니라 responses를 쓰는 이유: 전자는 함수 도구 + `reasoning_effort` 조합을 거부한다.
- 인자 누락이 재발하면 `gpt-5.6-terra`로 올린다. 대화가 답답하면 effort를 `low`로 내린다.
- **폴백은 없다.** Workers AI 경로(`proxyWorkersAI`·`toOpenAIRequest`·`toGeminiShape`·
  `WORKERS_AI_MODEL`·`wrangler.toml`의 `[ai]`)는 2026-09-13 삭제됐다. `OPENAI_KEY`가 없으면
  `/ai/chat`이 503 `openai_key_missing`으로 즉시 끊긴다 — 조용히 다른 모델로 넘어가지 않는다.
  프록시는 Cloudflare **Worker**로 계속 돌아간다(`wrangler deploy`) — 없앤 건 Cloudflare
  **Workers AI**(모델 서비스)지 Worker가 아니다. 둘을 섞어 쓰지 않는다.
- 프록시 변환층은 조용히 깨지면 앱에서 "처리 중 문제가 생겼어요"로만 보인다.
  **배포 전 `cd proxy && npm test`를 돌린다.**

작은 모델에서 반복된 실패는 전부 **인자** 문제였다 — 선택 인자를 빠뜨리거나(`origin_query` 누락 →
출발지=도착지인 0분 일정), 비워둬야 할 인자를 채우거나(`mode`), 날짜 범위를 틀리거나,
호출하지도 않은 툴을 호출했다고 말하거나. 그래서 실행부가 방어적으로 짜여 있다
(`resolvedMode`/`resolveOrigin`이 빈 값을 저장된 선호값으로 대체, `isSamePlace` 50m 가드,
`list_schedules`가 빈 결과일 때 총 건수를 함께 돌려줘 모델이 스스로 고치게 함).
**모델을 바꿨다고 이 방어들을 먼저 걷어내지 않는다** — 테스트로 불필요해진 것을 확인한 뒤에 지운다.
