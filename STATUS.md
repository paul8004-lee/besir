# besir — 프로젝트 현황 (2026-06-30 기준)

> 이 문서는 사업계획서·발표자료 작성용 요약이자, 개발 재개 시 참고용 스냅샷입니다.

## 한 줄 소개
**besir** — 일정과 목적지를 입력하면 현재 위치 기준 이동시간을 계산해 **"언제 출발해야 하는지"를 알려주고 알람을 예약**하는 iOS·macOS AI 비서 앱. 구글 캘린더와 양방향 동기화.

## 핵심 사용 흐름
1. 일정 추가: 제목 + 도착지(검색) + 출발지(현재 위치/검색) + 도착 시각 + 이동수단(자동차/대중교통/도보) + 도착 여유(버퍼) + 알림 시점
2. 앱이 **실제 경로·이동시간 계산** → **출발 시각 = 도착 − 이동시간 − 버퍼** 산정
3. 출발 N분 전 **로컬 알림 예약**
4. 지도에 **실제 경로선** 표시(자동차=도로, 대중교통=지하철/버스 노선색, 도보)
5. 일정은 **구글 캘린더에 자동 등록** → 폰·맥·캘린더 전부 동기화

## 현재 기능 (구현 완료)
- **멀티플랫폼**: iOS 17+ / macOS 14+ 네이티브 앱(SwiftUI, 공유 코드베이스)
- **장소 검색**: 카카오 로컬 키워드 검색(프록시 경유)
- **이동시간 계산**: 자동차(카카오모빌리티), 대중교통(ODsay), 도보(MapKit)
- **실제 경로 지도**: 카카오맵(WKWebView) 위에 수단별 색상 경로선
- **출발 시각·로컬 알림**: 도착 역산 → 알림 예약
- **일정 편집/삭제**: 모든 필드 수정, 스와이프(iOS)·hover X(macOS) 삭제, 만료 일정 분리 폴더 + 일괄 삭제
- **구글 캘린더 연동(동기화 백엔드)**:
  - 일정 생성 시 자동 등록(설정 토글, 기본 ON)
  - 폰·맥이 같은 구글 계정으로 **양방향 실시간 동기화**(추가·삭제 전파)
  - 등록된 일정엔 "구글 캘린더에 등록됨" 표시
  - 새로고침: 폰=당겨서, 맥=툴바 버튼
- **AI 대화형 일정 등록**: 자연어로 말하면(예: "내일 3시 강남역에서 친구 만나기") Claude(`claude-opus-4-8`)가 제목·목적지·도착시각을 파악해 `create_schedule` 툴 호출 → 앱이 목적지를 카카오 검색으로 해석 + 현재 위치를 출발지로 삼아 일정 자동 등록. **반복 일정("매주 평일 9시 교육" 등)도 `create_recurring_schedule` 툴로 지원**(요일 배열+매일 도착시각 → 최대 12주치 개별 일정을 한 번에 생성, 같은 `recurrenceId`로 그룹화해 상세화면에서 전체 일괄 삭제 가능). 툴바 ✨ 버튼 → 채팅 화면(`AIChatView`/`AIAssistant`).
- **실기기 배포 완료**(iPhone), 보안 프록시로 키 보호

## 기술 아키텍처
- **앱**: SwiftUI 멀티플랫폼, XcodeGen(`project.yml`→`besir.xcodeproj`), 코드 `Shared/*.swift`
- **지도**: 카카오맵 JS SDK를 앱 내장 **로컬 HTTPS 서버**(LocalMapServer, 포트 8089, self-signed TLS)로 서빙 → WKWebView 로드(외부 스크립트 로드 제약 우회)
- **보안 프록시(핵심 차별점)**: Kakao REST 키·ODsay 키·**Anthropic(Claude) 키**를 앱에 두지 않고 **Cloudflare Worker**(`proxy/`, `https://besir-proxy.paul8004.workers.dev`)가 보관. 앱은 토큰으로 프록시만 호출 → **앱 추출로도 키 노출 안 됨**(앱스토어 안전). Claude 라우트: `POST /claude/messages`(본문을 Anthropic `/v1/messages`로 중계).
- **AI 일정 등록(대화형)**: `AIAssistant`가 시스템 프롬프트(현재 시각·위치 주입) + `create_schedule` 툴로 Claude 툴콜 루프를 돌림. 앱은 툴 입력의 `destination_query`를 카카오 검색으로 좌표화, 현재 위치를 출발지로 삼아 `Store.addEvent` 실행 → 기존 출발시각 역산·알림·캘린더 등록 파이프라인 그대로 재사용.
- **구글 캘린더**: OAuth 2.0 Authorization Code + **PKCE**(client secret 불필요), ASWebAuthenticationSession, refresh token은 Keychain. besir 이벤트는 `extendedProperties.private`에 메타데이터 저장해 구분/복원
- **영속화**: 로컬 events.json + 구글 캘린더 동기화

## 외부 의존 / 설정
- 카카오 개발자: JS 키(지도, 도메인 잠금 `localhost:8089`), REST 키(서버), 카카오맵 제품 활성화
- ODsay: 대중교통 API 키(서버, 도메인 `localhost` 검증)
- Cloudflare: Worker 배포(무료 티어), 시크릿으로 키 보관 — `wrangler secret put ANTHROPIC_KEY` 추가 후 재배포 필요(안 하면 `/claude/messages` 500)
- Anthropic: Claude API 키(서버 시크릿 `ANTHROPIC_KEY`). 모델 `claude-opus-4-8`
- Google Cloud: iOS OAuth 클라이언트(번들 `com.iseongmin.besir`) + Calendar API + 동의화면 Test users

## 알려진 한계 / 향후 과제
- 대중교통은 ODsay(수도권·도시 내) 기반 → **시외(예: 서울↔부산)는 경로선 미지원**, 자동차는 전국 가능
- 도보 길찾기는 카카오 미지원 → MapKit 사용(국내 정확도 편차)
- 동기화는 앱 활성화/수동 새로고침 시점(실시간 푸시 아님)
- 자연어(대화형) 일정 입력 = AI 비서 고도화 여지
- 프록시 남용 방지(레이트리밋)·앱 토큰 회전 = 정식 출시 전 강화 권장

## 빌드/실행
- 파일 추가 시: `cd ~/Projects/besir && xcodegen generate`
- iOS 시뮬레이터: `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build build`
- macOS: `xcodebuild -scheme besir-macOS -derivedDataPath build build`
- 실기기 배포: Xcode GUI에서 기기 선택 후 Run(무료 개인 팀 서명, CLI 서명 불가)

## 제출 대상
국제 유스 창업올림피아드 — besir 앱으로 지원(사업계획서 + 발표자료 작성 예정).
