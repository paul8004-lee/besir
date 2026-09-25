# besir 개발 로드맵 (2026-09-10 기준)

> 소스: `besir 사업계획서.pdf` + `STATUS.md` + 개발 메모리(2026-06-29~09-09).
> 목적: 사업계획서의 5개 서비스(be healthy/on-time/full/fun/rich sir)를 **어떤 순서로, 어떤 파일/API 단위로** 만들지 정하고, Claude Code(Pro 플랜)가 매일 새 세션에서 그대로 실행할 수 있을 만큼 구체적인 작업 리스트로 쪼갠다.
> **이 문서는 앞으로 진행되는 besir 세션들의 1차 참조 스펙이다** — 매일 작업 전 이 파일에서 해당 Day 항목을 읽고 시작하고, 계획이 실제와 달라지면(설계 변경, API 제약 발견 등) 이 파일을 그 자리에서 갱신한다.

## 1. 현재 상태 요약 (2026-09-12 갱신 — Phase 1 Day 9·10 실제 구현 반영)

> 아래는 세션 `Besir 앱 세션 동기화`(로컬 세션, cwd `~/Projects/besir`)의 실제 진행 내역을 읽어 갱신한 최신 상태다. **Phase 0(AI 파이프라인)은 최초 계획과 다른 아키텍처로 이미 완료됐고, 그 사이 계획에 없던 be on-time sir 고도화 작업이 상당량 추가로 진행됐다.**

- **be on-time sir**: 완성 + 고도화 진행 중. 일정 등록→이동시간 역산→출발알람→카카오맵 경로선→구글 캘린더 양방향 동기화까지 안정 동작. 여기에 더해 **즐겨찾기 장소, 출퇴근 왕복+점심 이동을 포함한 복합 반복 일정, AI 대화 기록 영구 저장, 월/주/일 통합 스와이프 캘린더 UI(드래그로 5분단위 일정 이동 포함)**까지 이번 세션에서 추가됨(§6 Phase 0.5 참고).
- **be full sir**: Phase 1 Day 6·7·9·10·8 전원 완료 — Day 8(배달/요리 조사)은 2026-09-24 종결(결론은 §6 Day 8 행). 전용 화면 `FullSirView`(기준 위치=현재 위치 또는 오늘 일정의 목적지 → 카카오 로컬 검색 → 고른 식당을 "식사 활동 블록 + 왕복 이동"으로 등록), 일정 상세의 "목적지 주변" 섹션, AI 툴 `recommend_meal`까지 동작. **Day 9·10은 계획과 다른 방식으로 구현됐다**(§6 Phase 1 표에 사유 기록) — 신규 `MealSuggestionService` 없이 기존 `PlaceSearch`/`Store.addActivityWithTravel`을 재사용했고, 연결 필드는 `scheduledEventId`가 아니라 `activityId`다. 아직 실기기 확인(Day 12)·코드 검사(Day 11) 전이다.
- **AI 파이프라인(카카오톡 등에서 공유 텍스트/이미지 → 일정 자동 등록) — 완료, 아키텍처가 최초 계획과 다름**:
  - ~~Anthropic Claude API 배포~~ → **Google Gemini 시도 후 폐기** → Cloudflare Workers AI(`@cf/mistralai/mistral-small-3.1-24b-instruct`) → **현재 OpenAI `gpt-5.6-luna`로 확정(2026-09-12)**.
  - **와이어 포맷은 의도적으로 Gemini `generateContent` 형식을 그대로 유지** — 앱(`AIAssistant.swift`)은 백엔드가 뭐든 몰라도 되고, 백엔드 전환은 프록시의 번역 함수만 고치면 됨. **이 계약을 앞으로도 지킬 것.** 실제로 이번 OpenAI 전환에서 앱 코드는 한 줄도 안 고쳤다 — 계약이 값을 한 첫 사례다.
  - 이미지 입력도 `inlineData`(base64) → 백엔드별 이미지 파트로 프록시가 번역해 지원(텍스트+이미지 둘 다 동작 확인).

- **AI 백엔드 OpenAI 전환(2026-09-12, 완료·배포됨)**:
  - **왜 옮겼나**: 비용이 아니라 **함수 호출 신뢰도**. mistral-small-3.1-24b는 선택 인자를 빠뜨리고(`origin_query` 누락 → 출발지=도착지인 0분 일정), 비워둬야 할 인자를 채우고(`mode`), 날짜 범위를 틀리고, 호출하지도 않은 툴을 호출했다고 말하는 실패가 반복됐다. 툴 11개에 중첩 인자를 쓰는 구조에서 이건 그대로 사용자 경험이 된다.
  - **모델**: `gpt-5.6-luna`($0.20/$1.20, 캐시 입력 $0.02). 측정된 고정 비용 5,804토큰/요청(시스템 1,812 + 툴 3,992) 기준 작업당 약 6원. 인자 누락이 재발하면 `gpt-5.6-terra`($2/$12)로 올린다 — `proxy/src/index.js`의 `OPENAI_MODEL` 한 줄.
  - **⚠️ chat completions가 아니라 `/v1/responses`를 쓴다**: 전자는 "Function tools with reasoning_effort are not supported"로 거부한다(실측). 도구를 쓰려면 추론을 꺼야 하는데, 인자 누락을 줄이려고 옮겨온 마당에 앞뒤가 안 맞아 엔드포인트를 바꿨다. Responses는 대화가 `messages`가 아니라 평평한 `input` 아이템 배열이고 도구 호출·결과가 `function_call`/`function_call_output` 아이템으로 들어간다.
  - **같이 고친 버그**: `tool_call_id`를 턴마다 0부터 다시 세어 히스토리에 같은 id가 중복됐다(mistral은 넘어갔지만 OpenAI에서는 호출↔결과 짝이 틀어질 수 있음). 대화 전체에서 유일한 번호를 쓰도록 수정.
  - **테스트**: `proxy/test/convert.test.mjs`(7건) — 변환층이 조용히 깨지면 앱에서는 "처리 중 문제가 생겼어요"로만 보여 원인을 못 찾는다. **배포 전 `cd proxy && npm test` 필수.** 실제 호출로 1턴 도구 호출·다중 턴 도구 결과 재전송 모두 확인.
  - **폴백 제거(2026-09-13)**: luna로 확정돼 `proxyWorkersAI`·`toOpenAIRequest`·`toGeminiShape`·`WORKERS_AI_MODEL`·`wrangler.toml`의 `[ai]` 바인딩·폴백 테스트 4건을 모두 삭제(테스트 11→7건). **이제 백엔드는 하나뿐이라 `OPENAI_KEY`가 없으면 `/ai/chat`이 503 `openai_key_missing`으로 즉시 끊긴다** — 예전처럼 조용히 다른 모델로 넘어가지 않는다. `toolCallId`는 `toResponsesRequest`도 쓰므로 남겼다(지우면 현역 경로가 깨진다).
  - **아직 안 한 것**: strict 함수 호출(구조화 출력). 켜려면 모든 선택 인자를 `required` + nullable로 바꾸고 앱이 명시적 `null`을 "없음"으로 처리해야 해서 회귀 위험이 있다. luna로 테스트 시퀀스를 돌려보고 인자 누락이 남으면 그때 켠다.
  - **실행부 방어는 남겨둔다**: `resolvedMode`/`resolveOrigin`의 빈 값 처리, `isSamePlace` 50m 가드, `list_schedules`의 자기교정 브랜치. 모델을 바꿨다고 먼저 걷어내지 않고, 테스트로 불필요해진 것을 확인한 뒤 지운다. (luna도 `mode_this_time`을 빈 문자열로 채우는 것이 실측됐다 — 앱이 이미 trim 후 빈 값을 "없음"으로 보기 때문에 문제되지 않았다.)
  - `ANTHROPIC_KEY`·`GEMINI_KEY` 시크릿은 여전히 남아 있으나 쓰이지 않는다(지워도 무방).
- **Share Extension(카카오톡/사진 등에서 공유 → besir로 전달) — 구현 완료, 실기기 라이브 테스트로 최소 1회 이상 성공 확인**:
  - 최초 계획한 "URL scheme 핸드오프"가 아니라 **App Group 파일 큐** 방식으로 구현됨: `ShareExtension/ShareViewController.swift`(공유 시트에서 텍스트/이미지 추출) → `Shared/SharedInbox.swift`(`group.com.iseongmin.besir` 앱그룹 컨테이너의 `pendingShares.json`에 큐잉) → `Shared/App.swift`가 앱 포그라운드 진입(`scenePhase == .active`) 시 `SharedInbox.drain()`으로 꺼내 `AIAssistant`에 전달 → `AIChatView` 자동 오픈.
  - 실기기 라이브 테스트에서 **공유→일정 실제 등록까지 성공 확인됨**. 다만 확인 메시지를 받아오는 2차 API 호출만 실패해 성공했는데도 "처리 중 문제가 생겼어요"로 잘못 표시되는 버그가 있었고 → 이미 수정됨(성공한 결과는 그대로 보여주고 에러로 표시하지 않도록).
  - 카카오톡 자체의 "말풍선 꾹 눌러 ChatGPT로 보내기" 메뉴는 카카오-OpenAI 특별 제휴라 일반 개발자는 접근 불가로 확인됨 → besir는 iOS 표준 공유 시트(공유 → besir 아이콘 선택) 경로로 동작.
- **Day 5(캘린더 UI 라이브 재테스트) — ✅ 완료(2026-09-10 같은 세션에서 재확인 및 추가 수정까지 마침)**: 월간 스와이프 렉·탭→상세정보 미표시 두 수정 모두 실기기에서 정상 동작 확인. 그 과정에서 라이브 테스트로 추가 발견된 문제들도 전부 그 자리에서 수정 완료:
  - 시간표 블록 위에서 빠른 스크롤이 막히던 문제(UIScrollView `delaysContentTouches` 문제) → `RescheduleOverlay`를 UIKit `UIViewRepresentable`(`UILongPressGestureRecognizer`+`UITapGestureRecognizer`, `shouldRecognizeSimultaneouslyWith` true)로 재구현해 해결.
  - 겹친 블록(점심 이동처럼 넓은 활동 안에 짧은 이동 구간이 중첩) 히트 테스트 우선순위 버그, 최소 렌더 높이와 히트 테스트 범위 불일치 버그, 이동시간 계산 실패 블록의 히트 테스트 방향이 반대였던 버그 — 전부 `ContentView.block(at:)` 수정으로 해결.
  - 활동 블록도 탭해서 정보 보기/편집 가능하도록 `ActivityDetailView`(신규) 추가, `Store.updateActivity`/`deleteActivity` 추가.
  - 반복 일정 삭제 UI 통일(§1 하단 "삭제 UI 개선" 항목 참고).
  - 출발 시각 기준(귀가 등) 수동 일정 생성 지원 — `AddEventView`에 출발/도착 두 필드 + 자동 anchor 판별, `Store.addEvent`/`updateEvent`에 `anchor` 파라미터 추가.
  - 활동 블록 수동 추가 화면(`AddActivityView`, 신규) + "+" 메뉴화.
  - 주간 스트립도 좌우 스와이프로 다음 주 이동 가능(`SwipePager` 재사용).
  - **AI 대화 히스토리 role 순서 버그 수정**: 툴 실행 후 텍스트만 있는 마무리 턴이 히스토리에 안 남아 `...function → user` 순서가 되면서 Workers AI가 매 요청을 거부하던 근본 원인 발견·수정(`runLoop()`). 기존 대화도 자동 복구(`repairDanglingToolTurn`). "새 대화 시작" 버튼 추가.
  - **AI 장기 기억 기능 추가**(계획에 없던 추가 기능, `ai_memory.json`): `remember_fact` 툴 — 이동수단 등 선호를 한 번 물어보면 저장해두고 재대화에도 유지. 설정 화면에 기억 목록 관리 UI 추가.
  - **AI 반복 일정 수정 기능 추가**(계획에 없던 추가 기능): `update_recurring_schedule` 툴 — 방금 만든 반복 일정의 이동수단/버퍼/알림을 새로 만들지 않고 그대로 갱신(`Store.updateRecurringSeries`).
  - **AI 일정 삭제 기능 추가**(계획에 없던 추가 기능): `list_schedules`(실제 데이터 조회, 할루시네이션 방지) + `delete_schedule`(제목 기반 삭제, 반복 그룹 내 제목이 다른 구간까지 잘못 지워지지 않도록 제목 일치분만 삭제, `confirm_many`로 recurrenceId 없는 낱개 중복 대량 삭제도 지원) 툴 추가. `EventDetailView`도 recurrenceId 없이 제목만 같은 낱개 중복을 일괄 삭제하는 옵션 추가.
  - **다음 세션 시작 시 참고**: 위 항목 전부 아이폰 실기기에서 라이브 확인 완료. 다음 할 일은 Phase 1(Day 6, be full sir MVP 데이터 모델 설계)로 진행.
- **개발 워크플로 규칙(2026-09-10, 사용자 지시 — 앞으로 Day가 끝날 때마다 계속 적용)**:
  1. **요구사항 체크리스트**를 항상 새로 만든다(`CHECKLIST.md`, 형식: 상황 → ✅/⚠️/❌ → 코드 근거).
     **범위는 AI 채팅에 한정하지 않는다** — 사용자가 besir의 **전체 기능**을 써보면서 마주칠 수 있는 모든 상황을 담는다:
     - 화면 조작: 월간/주간/일간 전환, 좌우 스와이프, 블록 탭·꾹눌러 드래그, 겹친 블록 선택
     - 수동 생성·편집·삭제(+ 메뉴, 상세 화면), 즐겨찾기, 설정
     - AI 채팅(생성·조회·수정·삭제·기억)
     - 알림(수신 시점, 껐을 때, 반복 일정 뒷 회차)
     - 구글/애플 캘린더 연동(등록·수정·삭제 전파, 중복, 알림 중복)
     - 공유 확장(다른 앱에서 텍스트·이미지 공유)
     - 경계·예외 상황: 오프라인, 위치 권한 거부, 이동시간 계산 실패, 장소 검색 0건, 자정을 넘기는 일정, 앱 강제 종료 후 복귀, 기기 잠금 상태
     새로 생긴 기능 영역은 섹션을 추가하고, 이전 회차의 ❌/⚠️는 해결됐는지 갱신한다.
  2. **코드 버그 검사**를 함께 한다. 최소 항목:
     - `await` 앞뒤로 인덱스·스냅샷을 재사용하는 곳(배열이 바뀌어 엉뚱한 항목을 덮어쓰거나 범위 초과 — 실제로 `refreshUpcomingEstimates`에서 발생했음)
     - fire-and-forget `Task { try? ... }`로 실패가 조용히 묻히는 곳(삭제가 실패해도 아무도 모르던 문제)
     - 무한 증가하는 상태(대화 히스토리·묘비 목록·저장 파일)와 외부 한도(iOS 알림 64건, API 일일 할당량)
     - 강제 언래핑·경계 조건(자정 넘김, 빈 배열, 같은 시각 인접)
     - iOS·macOS 양쪽 **무경고** 빌드
  3. **간결성 검사**를 함께 한다. 같은 계산이 두 곳에 복제돼 있지 않은지(렌더링과 히트테스트가 따로 계산하다 어긋났던 `span(for:)` 건이 전형), 죽은 코드·미사용 심볼, 루프 안에서 반복되는 저장/네트워크 호출, 한 함수가 너무 많은 일을 하는지. 발견하면 **그 자리에서 정리**하고 무엇을 왜 합쳤는지 기록한다.
  4. 위에서 나온 구멍을 **해결하고**, 체크리스트와 **실기기 확인 목록을 사용자에게 보여준다**
     (빌드로는 검증 불가능한 것: 실제 알림 수신, 제스처 느낌, 캘린더 앱에 보이는 모습, 화면 레이아웃 등).
     실기기 배포도 이 시점에 한다 — 사용자가 직접 확인해야 하니까.
  5. **베타는 아직 만들지 않는다.** 사용자가 확인한 결과와 추가 요청을 **전부 반영한 뒤**,
     사용자가 다음 Day로 넘어가자고 할 때 비로소 그 시점의 코드로 베타를 만든다.
     (성급히 만들면 곧바로 수정이 들어와 베타가 실제로 쓸 수 없는 스냅샷이 된다 — v0.1.1을
     Day 7 직후 만들었다가 같은 날 수정 요청이 들어와 폐기한 적이 있다.)
  6. 베타 버전 이름은 **`besir-beta-v0.1.0`, `v0.1.1`, `v0.1.2` …** 순으로 올린다(`~/Projects/` 아래, `BETA.md`에 변경 내역·복원 방법 기재).
  7. 베타는 확정 후 **수정하지 않는다**. 이후 작업은 `besir/`(작업본)에서만 하고, 다음 베타를 새로 뜬다.
  - **주의**: `xcodegen generate`를 돌리면 Xcode 서명 계정이 리셋돼 실기기 빌드가 깨진다(`No Account for Team`). 새 소스 파일이나 Info.plist 키를 추가했을 때만 돌리고, 돌린 뒤엔 사용자에게 besir-iOS·besirShare 두 타깃 Team 재선택을 요청해야 한다. 베타 폴더 이름을 바꿀 땐 Xcode에서 그 프로젝트를 먼저 닫는다(안 그러면 "workspace disappeared" 경고가 뜨고, Re-save를 누르면 옛 경로에 껍데기 폴더가 생긴다 — Close가 정답).
- **베타 v0.1.1 — 확정(2026-09-24)**: Day 7 직후 한 번 만들었다가, 같은 날 사용자 확인 결과 수정 요청 4건이 들어와 **폐기**했다. 위 규칙 5번은 이 경험에서 나왔다. **네 건 모두 반영 완료(2026-09-12)**: ① 이동수단 분리 → `addActivityWithTravel`의 `outboundMode`/`returnMode`로 출발·복귀를 따로 고른다, ② 활동 겹침 경고 → **없애지 않고** "막지 않고 알려만 주는" 배너로 바꿨다(잠깐 빠져나갔다 오는 등 일부러 겹치게 잡는 경우가 있어서 — `AddEventView.swift:279`), ③ UI 분리 → `RootView`에 서비스 선택을 두고 be full sir를 `FullSirView`로 분리, ④ 식사 추천 AI → `recommend_meal` 툴. **확정(2026-09-24)**: 경로 `~/Projects/besir-beta-v0.1.1/`, 소스 커밋 `8d6761c`(origin/master `5a357cc` + Day 8 조사 문서). UI통일 Day(t1~t9) 확인 완료(실기기 7/8·시뮬레이터 13/14) + Day 8 종결 + 운영자의 다음 Day 선언 — 규칙 5·6번의 조건을 전부 채워 떴다. 변경 내역·복원 방법은 베타 폴더의 `BETA.md`.
- **베타 v0.1.0 확정(2026-09-10)**: 경로 `~/Projects/besir-beta-v0.1.0/`. Phase 1 Day 6 착수 직전 + 코드 점검 2차 + 캘린더 중복/알림 수정 + 백그라운드 동기화 + 삭제 묘비까지 반영된 상태. 실기기 설치·실행 확인 완료.
- **(구) 베타 버전 확정(2026-09-10)**: `~/Projects/besir-beta-20260910/` — Phase 1 착수 직전 상태 **+ 아래 "전체 코드 점검 2차"의 수정까지 전부 반영된** 버전을 베타로 확정(사용자 결정). 실기기 빌드·설치·실행 완료 시점의 소스와 동일(빌드 산출물·node_modules·Xcode 개인설정 제외, `BETA.md`에 내역·복원 방법 기재). Phase 1 작업 중 이 베타로 되돌아갈 수 있다.
- **AI 사용량(Workers AI neurons) 최적화(2026-09-11)**: 사용자가 "9시가 지났는데 여전히 소진"이라고 보고. 확인 결과 **UTC 자정 초기화라는 내 어제 설명이 틀렸다**(UTC 00:14에도 여전히 4006). 정확한 초기화 주기는 이쪽에서 확인 불가(wrangler OAuth 토큰 권한이 account(read)뿐) — 사용자가 Cloudflare 대시보드 Workers & Pages → AI → 사용량에서 확인해야 함.
  - **진짜 원인은 요청당 비용**: 시스템 프롬프트(≈3,961토큰) + 툴 선언 11개(≈6,740토큰) = **매 요청 고정 10,701토큰**. 대화 내용과 무관하게 매번 실려 감. 일정 하나 등록 = 2~3왕복 = 21,000~32,000토큰.
  - **내가 악화시킨 부분**: 9/10에 툴을 6개→11개로 늘리며 요청당 비용을 약 30% 올렸다(기능만 보고 비용을 보지 않음).
  - **수정**: 시스템 프롬프트를 산문→개조식으로(3,961→1,812), 툴 설명·파라미터 설명을 압축(6,740→3,992). 공통 파라미터(`mode`/`notifyFlag`/`calFlag`)는 변수로 묶어 반복 제거. **합계 10,701→5,804 토큰(46% 감소, 요청 횟수 1.8배)**.
  - **줄이지 않은 것**: 실제 버그를 막으려 넣은 규칙 — 지어내기 금지(list_schedules/recommend_meal/check_travel_time), 설정값 임의 추측 금지, 삭제는 텍스트 확인 후 1회 호출, 재호출 규칙 3종(`on_conflict`/`date`/`confirm_many`), create_activity로 이동까지 한 번에.
  - **미검증**: 할당량이 소진된 상태라 압축본이 실제로 같은 품질로 동작하는지 확인 못 함. 할당량 복구 후 최우선 확인 필요.
- **AI "처리 중 문제가 생겼어요" 재발(2026-09-10) — 이번엔 진짜 할당량 소진**: curl로 프록시 직접 호출해 확인 — `AiError 4006: you have used up your daily free allocation of 10,000 neurons`. **코드 버그 아님**(Cloudflare Workers AI 무료 티어 일일 한도, UTC 자정=KST 오전 9시 초기화).
  - 다만 앱이 모든 실패를 "처리 중 문제가 생겼어요" 하나로 뭉뚱그려 보여줘, 지난번 히스토리 버그 때도 이번에도 원인 판단이 어려웠다 → `AIAssistant.AIError`(`.quotaExceeded`/`.server`) + `classify(status:body:)` 추가, 할당량 소진이면 초기화 시각과 대안(+ 버튼 수동 등록)을 안내하는 문구를 따로 보여준다. 할당량 오류는 **재시도하지 않는다**(결과가 같은데 요청만 낭비).
  - **참고**: 요청 1건마다 시스템 프롬프트(~1.5k 토큰) + 툴 선언(~1.5k 토큰)이 매번 실려 가고, 반복 일정 생성 한 번에 2~3회 왕복한다. 앞서 고친 히스토리 무한 증가(이미지 base64 영구 보존·턴 무제한)가 그동안 사용량을 크게 부풀렸을 것으로 보임 — 그 수정 이후의 실사용량은 아직 관찰 안 됨.
- **삭제한 일정이 동기화로 되살아나던 문제(2026-09-10, 수정 완료 / 베타·Day6 양쪽 반영 / 실기기 설치는 xcodegen 서명 리셋 해결 후)**: 사용자 보고 — besir에서 전체 삭제했는데 동기화가 구글에서 다시 불러와 남아 있음.
  - **원인**: 모든 삭제 경로가 `Task { try? await gcal.deleteEvent(id:) }` — **fire-and-forget + `try?`**라 네트워크·토큰 문제로 실패해도 아무도 모른다. 로컬에서만 사라진 일정을 다음 `syncWithGoogle` 2단계("원격에 있는데 로컬엔 없음 → 가져오기")가 **"다른 기기에서 새로 추가된 것"으로 오해해 되살렸다**. 직전에 추가한 `reconcileActivities` 2-2도 같은 구조라 활동 블록에 대해 같은 문제가 있었다.
  - **수정**: 삭제 묘비(`deleted_gcal_ids.json`, `Store.deletedGoogleEventIds`) 도입. 모든 삭제 경로(9곳: `deleteEvent`/`deleteEvents`/`deleteActivity`/`deleteActivities`/`deleteRecurringSeries`/`deleteExpired`/`updateEvent`/`updateActivity`/`updateRecurringSeries`의 교체 삭제 + `reconcileActivities` 정리)를 `Store.removeFromCalendar(_:)` 하나로 통일 — 먼저 묘비를 남기고 삭제를 시도한다. `syncWithGoogle`은 ① 묘비 스냅샷을 라운드 시작에 고정 ② 묘비가 있는데 원격에 남아 있으면 재삭제 ③ 묘비 id는 events·activities 양쪽 가져오기에서 제외 ④ 원격에서 사라진 게 확인된 묘비만 정리(무한 누적 방지).
  - **주의**: 묘비를 "삭제 성공 직후"가 아니라 "다음 동기화가 원격 부재를 확인했을 때" 지운다 — 성공 직후 지우면 이미 목록을 받아둔 동기화가 되살릴 틈이 남는다.
- **백그라운드 동기화(2026-09-10, 수정 완료 / 베타·Day6 양쪽 반영)**: `BGTaskScheduler`(`BGAppRefreshTask`, 식별자 `com.iseongmin.besir.sync`)로 앱이 포그라운드에 없을 때도 동기화. `App.swift`의 `BackgroundSync`에서 App.init 시 등록하고 background 전환마다 재예약. `project.yml`에 `UIBackgroundModes: [fetch]` + `BGTaskSchedulerPermittedIdentifiers` 추가.
  - **함께 고친 것(없으면 백그라운드 동기화가 사실상 동작 안 함)**: ① 키체인 접근성이 기본값(`WhenUnlocked`)이라 **잠금 화면에서 구글 토큰을 못 읽어 동기화가 통째로 실패**했다 → `AfterFirstUnlock`으로 저장 + 기존 항목은 앱 시작 시 `Keychain.upgradeAccessibility`로 승급. ② 동기화 도중 백그라운드 전환 시 앱이 정지돼 캘린더 쓰기가 절반만 끝날 수 있었다 → `beginBackgroundTask`로 마무리 시간 확보.
  - **iOS 제약(사용자에게 안내함)**: 실행 시점은 iOS가 정하며 보장되지 않음(수십 분~몇 시간). 앱 전환기에서 강제 종료하면 백그라운드 태스크가 아예 실행되지 않음. 설정의 "백그라운드 앱 새로 고침"이 꺼져 있으면 동작 안 함. 확실한 실시간 동기화는 silent push(APNs + 서버)가 필요 — 미결정.
- **캘린더 중복·알림 수정(2026-09-10, 베타에 반영 후 실기기 설치 완료 / Day 6 버전에도 동일 반영, 설치는 안 함)**: 사용자 보고 — besir엔 활동 블록이 1건인데 구글·애플 캘린더엔 2건씩, 그리고 활동 블록에 10분 전 알림이 켜져 있음.
  - **원인 ①(중복)**: `syncWithGoogle`이 `events`만 대조하고 `activities`는 **올리기만 할 뿐 아무도 검사하지 않았다**. `googleEventId`를 저장하기 전에 앱이 종료되거나, `deleteActivity`/`deleteRecurringSeries`의 fire-and-forget `Task { try? await gcal.deleteEvent }`가 조용히 실패하면 캘린더에만 남는 찌꺼기가 **영구히** 쌓였다(정리하는 코드가 아예 없었음).
  - **원인 ②(알림)**: `reminders: useDefault=false, overrides=[]`는 이번 세션에 넣었지만 **그 전에 만들어진 이벤트**는 구글 캘린더 기본 알림(10분 전)을 그대로 갖고 있었다. 애플 캘린더는 구글 계정을 구독하므로 그대로 따라 울림.
  - **수정**: `GoogleCalendarService`에 `fetchBesirItems()`(이동 일정·활동·원본 정보를 한 번의 요청으로) + `RemoteItem` + `parseActivity` + `clearReminders(id:)`(PATCH) 추가. `Store.reconcileActivities(remote:)` 추가 — besir 기준으로 ① 원격에서 사라진 활동은 로컬 gid만 비우고 재업로드 ② 캘린더에만 있는 활동은 가져오되 같은 제목·시간(±60초)이면 중복으로 보고 안 가져옴 ③ besir가 모르는 besir 표시 항목은 캘린더에서 삭제 ④ 알림 남아 있는 항목 전부 해제 ⑤ 못 올린 활동 업로드. 활동 이벤트에 좌표(`locLat`/`locLng`)도 저장해 다른 기기 복원이 손실 없게 함.
  - **주의**: ③은 `besir=1` 태그가 붙은 항목만 대상이라 사용자의 다른 캘린더 일정은 건드리지 않는다. 다만 besir 표시가 붙었는데 복원이 안 되는 옛 항목(필드 누락 등)도 정리 대상이 된다.
- **전체 코드 점검 2차(2026-09-10, 완료 — iOS·macOS 빌드 무경고 + 실기기 설치 완료)**: 1차 점검(보안·미사용 코드)에 이어 버그·성능 관점으로 다시 훑어 아래를 수정. **라이브 재확인은 아직 안 함**.
  - **알림 iOS 64건 제한(가장 큰 실사용 결함)**: iOS는 앱당 예약 대기 알림을 64개만 유지하고 초과분을 조용히 버린다. 12주 반복 × 하루 4구간 = 240건이라 **3주쯤 뒤 회차부터는 알림이 아예 오지 않는데도 앱은 예약된 줄 알고 있었다**. `Store.rescheduleNearestNotifications(limit:60)` 추가 — 가까운 것부터 60건만 실제로 예약하고, 앱 foreground 진입 시 + 반복 일정 생성 직후 다시 채운다. `NotificationManager.cancelAll()` 추가.
  - **`refreshUpcomingEstimates` 인덱스 무효화**: 대상을 인덱스로 잡고 `await`를 거쳐 `events[idx] = ...`로 되쓰고 있었다 — 그 사이 동기화·삭제로 배열이 바뀌면 **엉뚱한 일정을 덮어쓰거나 범위를 벗어나 크래시**. id 기준으로 다시 찾도록 수정.
  - **AI 히스토리 무한 증가**: ① 공유받은 이미지 base64가 `contents`에 영구히 남아 **이후 모든 요청에 매번 다시 업로드**되고 `ai_history.json`도 계속 커졌다 → 턴이 끝나면 텍스트 설명으로 치환(`stripInlineDataFromHistory`). ② 대화 턴 수 제한 없음 → 언젠가 컨텍스트 한도를 넘겨 대화가 통째로 실패 → 최근 40턴만 유지(`trimHistory`, user 턴 경계에서 자름). ③ 실패한 턴이 히스토리에 남아 같은 실패를 무한 반복하던 문제 → 실패 시 턴 이전 상태로 롤백.
  - **구글 토큰 매 호출 재발급**: `store.gcal`이 접근할 때마다 새 인스턴스라 토큰을 캐시할 곳이 없어 **API 호출 1건마다 OAuth refresh 왕복이 1건씩 더** 붙었다(반복 일정 60건 등록 = 120 요청). `expires_in` 기반 타입 단위 캐시 추가.
  - **자정을 넘기는 블록 렌더링 오류**: 이동 구간은 도착일 기준으로 목록에 들어가는데 출발 시각(예: 23:30)을 그대로 세로 위치로 써서 **도착일 화면의 엉뚱한 자리**에 최소 높이로 그려졌다. 렌더링·히트테스트가 공유하는 `span(for:)` 하나로 통합하면서 같이 수정(기존엔 두 곳에 같은 계산이 중복돼 "보이는데 탭이 안 되는" 버그의 원인이었음 — 주석에도 경고가 달려 있었다).
  - **성능**: 반복 그룹 드래그/AI 일괄 삭제가 **건수만큼 JSON 인코딩+디스크 쓰기**를 반복하던 것 → 루프 후 1회로(`shiftEvent`/`adjustBuffer`에서 `save()` 제거, `Store.deleteEvents`/`deleteActivities` 추가). `daysWithSchedule` 키를 `DateComponents`→`Int`(yyyyMMdd)로(해시 비용, 그리드 1장당 126회 조회). 주간/월간 셀의 `DateFormatter`를 매 프레임 생성하던 것 → static 캐시. `list_schedules`의 회차 수 세기 O(n²)→O(n).
  - **미사용 코드 제거**: `ContentView.changeMonth/changeDay`(SwipePager로 대체된 뒤 남아 있던 것), `LocationManager.originLabel/isDenied`, `App.swift`의 버려지는 StateObject 기본값 2개.
  - **알고도 안 고친 것**: ~~`Store.deleteExpired()`(호출부 없지만 정상 동작하는 공개 API, 나중에 UI에서 쓸 것)~~ → **2026-09-23 제거(t5 / `SPEC-UIKIT-006`)** — 전제였던 "나중에 UI에서 쓸 것"에 계획된 UI가 없었고 git 이력 시작(`d3c9327`)부터 호출부가 없었다. 연결했다면 흐리게 보이도록 설계된 지난 일정을 로컬과 구글 캘린더 두 곳에서 되돌릴 수 없이 지웠을 것이다(SPEC §4 D-3), `SwipePager`의 빠른 연속 스와이프 시 `asyncAfter(0.22)` 경합(실사용에서 재현 안 됨), 1차 점검에서 남긴 `LocalMapServer`의 `as! SecIdentity`·`FavoritesView`의 `ForEach(id:\.name)`·미사용 `/claude/messages` 라우트.
- **~~뒤로 미룬 것~~ → 2026-09-12 완료**: AI 백엔드를 Workers AI → OpenAI(`gpt-5.6-luna`)로 전환. 사용자가 직접 꺼내 진행했다(§1 "AI 백엔드 OpenAI 전환" 참고).
- **삭제 UI 개선(2026-09-10, 완료, 실기기 설치까지 완료·라이브 재확인 전)**: `EventDetailView`/`ActivityDetailView`의 삭제 버튼이 반복 일정일 때 "반복 일정 전체 삭제"/"일정 삭제" 두 버튼을 항상 나란히 보여주던 것 → **삭제 버튼 하나만 남기고, 반복 일정이면 탭 시 "전체 반복 일정 삭제 / 이 일정만 삭제 / 취소" `confirmationDialog` 메뉴**를 띄우도록 통일(단발 일정은 바로 단순 확인). `ActivityDetailView`는 기존에 전체 삭제 옵션 자체가 없었는데 이번에 `EventDetailView`와 동일하게 추가됨. iOS·macOS 빌드 성공 + 아이폰 실기기 설치·실행까지 완료 — **다음에 폰을 만지면 최우선으로 이 메뉴가 실제로 뜨는지 라이브 확인 필요**(반복 일정 상세→삭제 탭→메뉴 2개 뜨는지, 각각 실제로 올바른 범위만 지워지는지, 단발 일정은 단순 확인만 뜨는지).
- **be healthy / be full / be fun / be rich sir**: 여전히 코드 없음. 사업계획서상 "초안 기획" 단계 그대로 — 데이터 모델부터 새로 설계해야 함(아래 Phase 1부터 시작).

## 2. 사업계획서 기준 우선순위 근거

8장(향후 계획)이 명시: "MVP 범위 확정: 우선 **be on-time sir(일정) + be full sir(음식)** 연동을 핵심으로 한 최소 기능 제품 개발". 4장(연계 구조)을 보면 **be on-time sir가 다른 4개 서비스 전부와 연결되는 허브**(운동 장소·음식점·여가활동을 전부 "일정+위치" 기반으로 추천)이므로, 이미 완성된 be on-time sir를 축으로 다른 서비스를 하나씩 "일정에 연동되는 서브 서비스"로 붙여나가는 순서가 사업계획서와도, 기존 코드 재사용 관점에서도 맞다.

우선순위: **(0) AI 파이프라인 완성 → (1) be full sir → (2) be healthy sir → (3) be rich sir → (4) be fun sir → (5) 통합/베타**. 근거는 각 Phase 서두에 기술.

## 3. 전체 아키텍처에 새로 추가되는 것들 (사전 결정)

새 서비스마다 매번 재논의하지 않도록, 이 로드맵 전체에 적용되는 공통 설계를 먼저 고정한다.

- **데이터 저장**: 기존 `events.json`과 같은 패턴으로 서비스별 JSON 파일을 `~/Library/Application Support/besir/`(macOS)/앱 컨테이너(iOS)에 추가. 예: `meals.json`, `expenses.json`. `Codable` 구조체 + `Store`에 배열 하나씩 추가하는 기존 관례를 그대로 따름(새 영속화 레이어를 만들지 않음).
- **Store를 계속 단일 허브로 사용**: 지금처럼 `Store`(ObservableObject)에 `events`뿐 아니라 `meals`, `healthGoals`, `expenses`, `funActivities`를 나란히 추가. 서비스 간 연계(4장 표)는 전부 "A 서비스가 Store의 B 서비스 배열을 읽어서 추천에 활용"하는 형태로 구현 — 별도 이벤트버스/메시징 불필요.
- **AI 확장은 툴 추가 방식 유지**: `AIAssistant`의 기존 툴 루프(`create_schedule`/`create_recurring_schedule`)에 새 툴(`recommend_meal`, `log_expense` 등)을 계속 추가하는 구조 유지. 새 서비스마다 별도 AI 클래스를 만들지 않음. **백엔드는 현재 OpenAI `gpt-5.6-luna`(프록시 `/ai/chat` → `/v1/responses`)이고 와이어 포맷은 Gemini `generateContent` 형식으로 고정돼 있다 — 새 툴을 추가할 때도 이 포맷(함수 선언은 대문자 타입 `"STRING"`/`"OBJECT"` 등, 프록시가 `lowercaseSchemaTypes`로 자동 소문자 변환)을 그대로 따르면 되고, 백엔드를 또 바꿔도 앱 코드는 안 건드려도 된다(2026-09-12 OpenAI 전환에서 실증됨).**
- **카카오 로컬 API 카테고리 재사용**: `PlaceSearch`가 이미 프록시 `/kakao/local/keyword`를 호출 중. 카카오 로컬 API는 `category_group_code` 파라미터로 `FD6`(음식점), `CE7`(카페) 필터를 지원 — be full sir의 "맛집 추천"은 이 파라미터만 추가하면 새 API 없이 구현 가능(Day 6에서 확인).
- **HealthKit/외부 연동은 각 Phase 시작 전 "조사 전용 Day"를 하나 둔다** — 실제 API 문서를 그 시점에 확인하고 설계를 확정한 뒤 구현일에 들어간다(사업계획서에 없는 세부는 지금 확정하지 않음).

## 4. Claude Pro 플랜으로 일할 때의 작업 단위 원칙

- **하루 = 새 세션 1~2개, 한 세션 = 아래 표의 한 Day 항목 전체**(그 이상 묶지 않음). 컨텍스트 0에서 시작해도 "무엇을, 어느 파일에, 어떻게" 프롬프트만 보고 끝낼 수 있게 아래 표에 파일 경로/함수 시그니처까지 명시했다.
- **조사(Research) Day와 구현(Implement) Day를 분리**했다 — 외부 API 제약을 그날 알아내고, 구현은 다음 세션에서 결과를 그대로 프롬프트에 넣어 시작한다.
- **한 Day당 새로 만들거나 크게 고치는 파일은 최대 3~4개**로 제한(그 이상이면 다음 Day로 분리). 리팩터링은 계획에 없는 한 하지 않는다(기존 CLAUDE 지침과 동일하게 범위 최소화).
- 매일 끝에 **완료 기준(빌드 성공 + 시뮬레이터에서 1회 동작 확인)**을 두어 하루치가 실패해도 다음 Day로 깨끗하게 넘어간다.
- 날짜(Day 1, 2, 3...)는 **순서 보장용**이지 캘린더 마감이 아니다. 막히면 다음 세션으로 그대로 밀면 된다.

## 5. 품질 게이트 — 코드 검사 / 실기기 테스트 / 안정화 (매 Phase 공통 기준)

각 Phase는 기능 구현 Day들 뒤에 **코드 검사 → 실기기 테스트 → 안정화** 3일을 고정으로 붙인다. 이 3일의 세부 체크리스트는 아래 공통 기준을 기본으로 삼고, 각 Phase 표에는 그 Phase에만 해당하는 항목만 추가로 적는다(공통 항목을 매번 반복 기재하지 않음).

### 5-1. 코드 검사(Code Review) 체크리스트 — 공통

- [ ] 강제 언래핑(`!`)·강제 캐스팅(`as!`) 남용 없는지 — 실패 가능한 지점은 `guard let`/`try?`/`if let`로 처리했는지
- [ ] 네트워크·API 실패 시 UI가 무한 로딩이 아니라 명시적 실패 상태를 보여주는지(기존 `failedEstimateBlockView` 패턴 참고)
- [ ] 새 모델의 영속화가 `events.json`과 같은 `Codable` + 파일저장 패턴을 그대로 따르는지, `Store`에 `@Published`로 선언됐는지
- [ ] async 클로저에서 `Store`/`AIAssistant` 참조 순환 방지를 위해 `[weak self]`가 필요한 곳에 붙어있는지
- [ ] UI를 갱신하는 코드가 메인 스레드(`@MainActor` 등)에서 실행되는지
- [ ] 새 기능이 이전 Phase가 의존하는 기존 함수 시그니처(`Store.addEvent`, `AIAssistant`의 기존 툴 스키마 등)를 깨지 않았는지
- [ ] 카카오/ODsay/AI 호출이 불필요하게 반복되지 않는지(캐시 가능한 값은 캐시 — `Store.daysWithSchedule`처럼)
- [ ] 새로 추가한 AI 툴이 Gemini 형식 스키마 계약(§3)을 그대로 따르는지(대문자 타입명, 프록시의 `lowercaseSchemaTypes` 의존)
- [ ] 한 Day당 3~4개 파일 제한(§4)을 넘겨 손댄 파일이 있으면 이유가 타당한지

### 5-2. 실기기 테스트 체크리스트 — 공통 절차 (Phase 전용 시나리오는 각 Phase 표에 명시)

- [ ] iOS 시뮬레이터 + macOS 둘 다 빌드 성공
- [ ] 아이폰(UDID `8D9B807B-F874-5AD8-A62C-BC1731A31A1F`)에 설치 및 실행
- [ ] 이번 Phase 신규 기능의 happy path 1회 성공
- [ ] 이번 Phase 신규 기능의 엣지 케이스(네트워크 없음/빈 검색 결과/잘못된 입력 등) 최소 1개 확인
- [ ] **회귀 확인(항상 실행)**: be on-time sir 핵심 흐름 — 일정 수동 등록→출발 알람→구글 캘린더 동기화, 그리고 카카오톡 공유→AI 파싱→일정 자동 등록 — 각 최소 1회씩 재확인해 이전 Phase가 망가지지 않았는지 확인
- [ ] 이 Day에서 발견한 문제는 그 자리에서 고치지 않고 다음 "안정화" Day로 넘긴다(테스트와 수정을 같은 세션에 섞지 않아 각 세션이 명확히 끝나게 함)

### 5-3. 안정화(Stabilization) 기준 — 공통

- [ ] 코드 검사·실기기 테스트에서 발견된 문제를 전부 수정하거나, 수정하지 않기로 했으면 §7(리스크)에 "알려진 이슈"로 명시적으로 남긴다
- [ ] 회귀로 발견된 기존 기능 문제는 최우선으로 수정(새 기능보다 우선순위 높음)
- [ ] `STATUS.md`에 이번 Phase 완료 사실 반영
- [ ] 커밋

## 6. 일자별 실행 리스트

### Phase 0 — AI 카카오톡 공유 파이프라인 완성 — ✅ 완료 (당초 계획과 다른 아키텍처로 구현됨)

**당초 계획**: Anthropic Claude API 키를 프록시에 배포 + URL scheme 기반 Share Extension 핸드오프.
**실제 구현(더 나은 방향으로 확정됨)**: Gemini를 시도했다가 Cloudflare 엣지 IP가 Gemini 무료 티어에 지역 무관 차단당하는 문제(성공률 10~50%)를 겪고 Cloudflare Workers AI(`@cf/mistralai/mistral-small-3.1-24b-instruct`)로 전환했다가, 함수 호출 신뢰도 때문에 **2026-09-12 OpenAI `gpt-5.6-luna`로 최종 확정**(폴백이던 Workers AI 경로는 2026-09-13 삭제). 백엔드를 세 번 갈아끼우는 동안 앱 코드는 한 줄도 안 바뀌었다 — 와이어 포맷을 Gemini `generateContent` 형식으로 고정한 계약 덕분이다. Share Extension은 URL scheme이 아니라 **App Group 파일 큐**(`SharedInbox.swift`)로 구현됨. 상세는 §1 참고.

| 항목 | 상태 | 비고 |
|---|---|---|
| AI 백엔드 확보 | ✅ 완료 | 당시 Cloudflare Workers AI(무료). **2026-09-12 OpenAI `gpt-5.6-luna`로 교체** — 함수 호출 신뢰도 때문. `/ai/chat` 라우트는 그대로 |
| Share Extension(텍스트) | ✅ 완료, 실기기 성공 확인 | App Group 큐 + 앱 포그라운드 drain 방식 |
| Share Extension(이미지) | ✅ 완료 | `inlineData` → OpenAI Responses `input_image`로 프록시가 번역(`toResponsesRequest`), luna가 비전 지원. 2026-09-12 이전엔 Workers AI `image_url`이었다 |
| 파싱 실패/2차 API 실패 시 오표시 버그 | ✅ 수정 완료 | 등록 자체는 성공했는데 확인 메시지 호출만 실패해 에러로 잘못 뜨던 문제 |
| **다음 세션에서 재확인 필요** | ⏳ 미확인 | 월간 캘린더 스와이프 렉 수정, 탭→상세정보 시트 전환 수정 — 둘 다 아이폰에 설치까지는 됐고 실제 라이브 재테스트만 남음(§6 Day 5) |

### Phase 0.5 — be on-time sir 고도화 (Phase 0과 병행 진행, ✅ 완료)

원래 계획엔 없었지만 AI 파이프라인 작업 중 사용자 요청으로 함께 진행되어 완료된 항목들 — be on-time sir 자체의 완성도를 높이는 작업이라 순서상 문제 없음.

| 항목 | 내용 | 대상 파일 |
|---|---|---|
| 즐겨찾기 장소 | "집" 등 자주 쓰는 장소 저장 → 일정 추가 화면에서 칩으로 빠른 선택, AI가 목적지/출발지명을 즐겨찾기와 우선 매칭 | `Shared/FavoritesView.swift` |
| 복합 반복 출퇴근 일정 | "매주 평일 9시~18시 교육, 점심 1~2시" 같은 표현 → 출근+퇴근 왕복 이동을 자동 생성, 점심도 "근처 식당" 등 다른 장소로 명시하면 왕복 이동 생성(같은 건물이면 생성 안 함), 출발지·복귀 여부·이동수단이 애매하면 AI가 등록 전에 먼저 되물음 | `Shared/AIAssistant.swift`, `Shared/Store.swift`(`addRecurringActivities`), `Shared/Models.swift`(`ActivityBlock`, `ScheduleAnchor`) |
| AI 대화 기록 영구 저장 | 재설치해도 대화 이력이 사라지지 않도록 `ai_history.json`으로 저장/로드 | `Shared/AIAssistant.swift` |
| 캘린더 UI 전면 개편 | 일간/주간/월간 탭 제거 → 월간 그리드 기본, 날짜 탭하면 그 날 시간표+상단 주간 스트립, 좌우 스와이프로 날짜/월 이동(실시간 손가락 추적 애니메이션), 블록 꾹 눌러 드래그로 5분 단위 재조정(반복 일정이면 전체/이 일정만 이동 확인 다이얼로그), 활동 블록 이동 시 연계된 이동 블록도 같이 이동, 이동 블록만 옮기면 활동은 고정하고 버퍼만 조정 | `Shared/ContentView.swift`(대규모 재작성), `Shared/Store.swift` |
| 월간 스와이프 렉 수정 | `Store.daysWithSchedule`(`Set<DateComponents>` 캐시)로 O(n)→O(1) | `Shared/Store.swift`, `Shared/ContentView.swift` |
| 탭→상세정보 안 뜨던 버그 수정 | `NavigationSplitView` detail 컬럼 전환 대신 `.sheet` 사용 | `Shared/ContentView.swift` |

**남은 리스크**: Day 5 라이브 재확인은 완료(2026-09-10). 다만 그 뒤 진행한 **전체 코드 점검 2차의 수정분은 빌드·설치만 하고 라이브 재확인 전**(§1 참고) — 특히 ① 알림 예약 갱신(`rescheduleNearestNotifications`)이 기존 예약을 다 지웠다 새로 까는 방식이라 알림이 정상적으로 오는지, ② 블록 렌더/히트테스트 통합(`span(for:)`) 후 탭·드래그에 회귀가 없는지 두 가지는 다음에 폰을 만질 때 확인 필요.

| Day | 작업 | 대상 파일 | 완료 기준 |
|---|---|---|---|
| 5 | ✅ 완료(2026-09-10) — 최근 설치된 빌드로 실기기 라이브 재테스트: ① 블록 위에서 빠른 스크롤이 되는지, ② 이동/활동 블록 탭 시 상세정보 시트가 뜨는지, ③ 롱프레스-드래그 재조정과 좌우 스와이프 내비게이션에 회귀가 없는지. 문제 있으면 그 자리에서 수정, 없으면 바로 Phase 1(Day 6)으로 진행 | `Shared/ContentView.swift`, `Shared/Store.swift`, `Shared/AIAssistant.swift`, `Shared/ActivityDetailView.swift`(신규), `Shared/AddActivityView.swift`(신규), `Shared/EventDetailView.swift`, `Shared/AddEventView.swift`, `Shared/SettingsView.swift`, `Shared/AIChatView.swift` | 3가지 상호작용 모두 실기기에서 정상 동작 확인 — 완료. 추가로 발견된 문제(겹친 블록 히트 테스트, AI 히스토리 role 순서 버그 등)도 전부 수정·재확인 |

### Phase 1 — be full sir MVP (식사 추천) — Day 6~11

**왜 다음인가**: 사업계획서가 명시한 2번째 MVP 축이며, `PlaceSearch`(카카오 로컬 검색)가 이미 있어 신규 외부 연동 없이 "맛집 추천"을 구현 가능 — 가장 리스크 낮은 신규 서비스.

| Day | 작업 | 대상 파일 | 완료 기준 |
|---|---|---|---|
| 6 | ✅ **완료(2026-09-10)** — `Models.swift`에 `MealCategory`(외식/배달/요리, `title`·`systemImage`는 `TransportMode`와 같은 형태) + `MealLog` 추가. `Store`에 `@Published var meals` + `meals.json` 로드/저장(`activities` 패턴 그대로) + `addMeal`/`updateMeal`/`deleteMeal`/`recentMeals(limit:)` 추가. `meals`는 시간표 블록이 아니라 이력이므로 `daysWithSchedule`에 넣지 않음(식당까지 가는 이동은 별도 `ScheduledEvent` 담당) | `Shared/Models.swift`, `Shared/Store.swift` | iOS·macOS 빌드 무경고 통과. JSON 왕복은 `Models.swift`를 직접 컴파일한 검증 스크립트로 12항목 확인(빈 배열, 세 카테고리, place/estimatedCost/scheduledEventId의 nil·비nil, loggedAt, 최신 우선 정렬, 모르는 카테고리는 디코드 실패 → 기존 값 유지) |
| 7 | ✅ **완료(2026-09-11)** — 프록시 `/kakao/local/keyword`에 `category_group_code`·`x`·`y`·`radius`·`sort`·`page` 전달 추가(배포 완료). `PlaceSearch.nearbyPlaces(category:near:radius:limit:)` — FD6(음식점)/CE7(카페) 거리순. `EventDetailView`에 "목적지 주변" 섹션(펼쳤을 때만 조회 — 상세 열 때마다 장소 API를 쓰지 않으려고). 강남역 좌표로 프록시 직접 호출해 결과 확인. **신규 파일 없이** `PlaceSearch.swift`/`Models.swift`에 넣어 xcodegen 재생성(서명 리셋)을 피함. *(원래 계획은 `DirectionsService`와 같은 레벨의 신규 `MealSuggestionService`를 만드는 것이었다 — 위 서명 리셋 문제 때문에 기존 파일에 넣는 쪽으로 바꿨고, Day 10도 같은 이유로 이 결정을 따라갔다.)* | `Shared/PlaceSearch.swift`, `Shared/Models.swift`, `Shared/EventDetailView.swift`, `proxy/src/index.js` | 일정 상세에서 목적지 주변 맛집 리스트 3~5개 표시 확인 |
| 8 | ✅ **완료(2026-09-24, 조사만 하고 구현 없음)** — 결론: **양사 모두 개인 개발자용 공식 API 없음 → "앱/웹 열어주기(유니버설 링크)" 방식으로 확정**. 배달의민족은 공개 개발자 포털 자체가 없고(배달대행 표준 API·POS 연동은 B2B 파트너 전용), 요기요도 공개 API가 없다(모회사 Delivery Hero의 Restaurant Integration API는 파트너 제한). 커스텀 스킴 `baemin://`·`yogiyo://`은 공식 문서화된 적이 없어 앱 버전이 바뀌면 조용히 끊길 수 있어 채택하지 않는다. 대신 유니버설 링크를 **실측** 확인했다(각 도메인의 `.well-known/apple-app-site-association`): 배민 — 앱 `com.jawebs.baedal`, `/shopDetail` 경로가 앱 오픈 등록; 요기요 — 앱 `com.yogiyo.yogiyoapp`, `/mobile/*` 전 경로가 앱 오픈 등록. 상세 결론은 바로 아래 "Day 8 조사 메모" | `plan.md`(조사 결과 기록) | 배달 카테고리 구현 방식이 확정되어 다음 세션 프롬프트에 바로 쓸 수 있음 |
| 9 | ✅ **완료(2026-09-12)** — `AIAssistant`에 `recommend_meal` 툴 추가(선언 `AIAssistant.swift:604`, 실행 `executeRecommendMeal`). Day 7의 `PlaceSearch.nearbyPlaces`를 그대로 재사용하고 **Gemini 형식 툴 선언 계약 유지**(§3). **인자가 계획과 다르다**: 계획의 `budget`은 넣지 않았다 — `expenses`는 Phase 3라 주입할 데이터가 아직 없다. 최근 `meals` 이력 주입도 하지 않았다(요청당 고정 토큰을 10,701→5,804로 줄인 직후라 되늘리지 않으려고). 대신 `keyword`/`category`(restaurant·cafe)/`at_iso`/`place_query`/`radius_meters`로 갔고, 기준 위치는 `place_query` → `at_iso`(그 시각에 있을 장소) → 현재 위치 순으로 떨어진다 — 실사용에서 "이따 강남 갔을 때 근처" 형태가 예산보다 훨씬 자주 나왔다 | `Shared/AIAssistant.swift` | AI 채팅에 "저녁 뭐 먹을까"로 물으면 추천 응답 1회 성공 |
| 10 | ✅ **완료(2026-09-12)** — 계획의 `MealSuggestionService`+`Store.addEvent` 대신 **신규 화면 `FullSirView.swift`** + 기존 `Store.addActivityWithTravel`로 구현. Day 7 직후 들어온 수정 요청(UI 분리·이동수단 분리)을 같이 받느라 경로가 바뀌었다: 식당을 고르면 "식사 활동 블록 + 왕복 이동"이 한 번에 생기고 출발·복귀 이동수단을 각각 고른다. 연결 필드도 계획의 `MealLog.scheduledEventId`가 아니라 **`activityId`** — 묶이는 대상이 이동 일정이 아니라 활동 블록이라서다. 일정을 지우면 아직 안 먹은 기록도 같이 사라진다(`Store.removeUpcomingMeals` → `ScheduleLogic.mealsToRemove`, 이미 지난 식사는 실제 먹은 기록이라 남긴다) | `Shared/FullSirView.swift`(신규), `Shared/Store.swift`, `Shared/RootView.swift` | 추천 선택 → 활동+왕복 이동 등록 + `meals.json` 기록 확인 |
| 11 | ✅ **완료(2026-09-12)** — 아래 전용 항목 확인. `FullSirView.save()`의 `activityId` 항목은 실제 코드에선 이미 `made.activityId`를 직접 받는 방식이라(제목·시각 재검색 아님) 해당 없음(계획 당시 우려였고 구현은 처음부터 안전하게 됨) | `Shared/Models.swift`, `Shared/Store.swift`, `Shared/PlaceSearch.swift`, `Shared/FullSirView.swift`, `Shared/AIAssistant.swift` | 체크리스트 전 항목 확인 완료 |
| 12 | ✅ **완료(2026-09-12, 실기기 테스트 결과 아래 기록)** | - | 결과 기록 완료 |
| 13 | 🟡 **진행 중(2026-09-12)** — Day 12에서 나온 진짜 버그 2건은 그 자리에서 수정·빌드 확인 완료(아래). 남은 건 UX 설계 결정 2건(사용자 확인 대기). Day 8은 2026-09-24 종결(§6 Day 8 행) | `Shared/FullSirView.swift`, `Shared/AIAssistant.swift` | 버그 수정 완료 + 사용자 확인 후 STATUS.md 갱신 |

**Day 8 조사 메모 (2026-09-24) — 배달/요리 카테고리 구현 방식 결론. 다음 세션 프롬프트에 이 블록을 그대로 쓴다.**

- **공식 오픈 API: 배달의민족·요기요 둘 다 개인 개발자 대상 제공 없음.** 배민은 공개 개발자 포털이 없고 존재하는 API(배달대행 주문 표준 API 2023.11, POS·ERP 연동)는 전부 B2B 파트너용. 요기요는 공개 API가 없고 모회사 Delivery Hero의 Restaurant Integration API도 파트너 제한. 스크래핑 서드파티(유료)는 비공식이라 약관 위험 — 쓰지 않는다.
- **커스텀 URL 스킴(`baemin://`, `yogiyo://`): 공식 문서화된 적 없음 → 의존하지 않는다.** 무문서 스킴은 앱 업데이트로 조용히 끊길 수 있어 계약 없이 쓸 대상이 아니다.
- **확정 구현 방식 — 유니버설 링크(웹 URL) 열기.** 실측 근거(각 사이트의 `.well-known/apple-app-site-association`를 2026-09-24에 직접 받아 확인):
  - 배달의민족: 앱 ID `L2VVJTXV3R.com.jawebs.baedal`, 앱 오픈 등록 경로 `/shopDetail`, `/shopDetail/menuDetail` (도메인 `baemin.com`, 응답 200)
  - 요기요: 앱 ID `URTQLGEF74.com.yogiyo.yogiyoapp`, 앱 오픈 등록 경로 `/mobile/*` 전체(카카오 OAuth 페이지 제외) (도메인 `yogiyo.co.kr`, 응답 302→/mobile)
  - 동작: iOS `UIApplication.open` / macOS `NSWorkspace.open`으로 해당 https URL을 열면 앱이 설치돼 있으면 앱이, 없으면 모바일 웹이 뜬다. besir는 메뉴·주문 데이터를 전혀 다루지 않는다(외부 앱으로 보내기만).
- **`MealCategory.delivery`·`.cooking` 판정**: 죽은 코드가 아니라 **예약 값으로 유지**. `.delivery`는 위 방식(외부 열기)을 붙일 때, `.cooking`은 요리 식사 기록을 붙일 때 쓴다. 지우지 않는다. 배달 카테고리 UI를 언제 붙일지는 별도 기획(Phase 1 완료 기준에는 포함돼 있지 않았다).

**Phase 1 전용 코드 검사 항목(Day 11)** — *구현이 계획과 달라져 항목도 실제 코드 기준으로 교체함(2026-09-12)*:
- [ ] `PlaceSearch.nearbyPlaces`가 `DirectionsService`와 같은 프록시 호출 관례(`config.proxyRequest`)를 따르는지 — 계획의 `MealSuggestionService`는 만들지 않았다(xcodegen 재생성=서명 리셋을 피하려고 기존 파일에 넣음)
- [ ] `category_group_code`·`x`·`y`·`radius`·`sort`·`page`가 기존 키워드 검색 쿼리 파라미터와 충돌 없이 추가됐는지(프록시·앱 양쪽)
- [ ] `executeRecommendMeal`의 인자 방어 — `radius_meters` 누락 시 1000, `keyword` 빈 문자열, `place_query`/`at_iso` 둘 다 없고 **위치 권한도 거부**된 경로에서 안내 문구로 끝나는지(빈 결과로 크래시하지 않는지)
- [ ] **`FullSirView.save()`가 `await addActivityWithTravel` 직후 `store.activities.last { 제목·시작시각 일치 }`로 방금 만든 활동을 되찾는다** — 같은 제목·같은 시각 활동이 이미 있으면 엉뚱한 것에 붙고, 못 찾으면 `activityId`가 nil이라 일정을 지워도 식사 기록이 안 지워진다. §5-1의 "`await` 앞뒤로 인덱스/식별자를 재사용" 항목에 정확히 해당 — `addActivityWithTravel`이 만든 활동을 반환하도록 고치는 쪽이 맞다
- [x] **요청당 고정 토큰 재측정 완료(2026-09-15) — 기준선 교체.** AI 요청당 고정 토큰비 = **4,425**
  (시스템 프롬프트 1,526 + 툴 선언 2,899). 측정법: 중립 설정(`AppConfig` 기본값·즐겨찾기 0건·기억 0건)에서
  `systemPrompt()` 원문 텍스트와 `toolsJSON()`의 JSON 직렬화(sortedKeys, 공백 없음)를 각각 tiktoken
  `o200k_base`로 인코딩해 합산. 시스템 프롬프트나 툴 선언을 고치면 같은 방법으로 다시 잰다.
  옛 5,804는 **측정 방법이 기록돼 있지 않아 이 숫자와 비교할 수 없다** — 더하거나 빼지 말고 이 기준선을 쓴다.
  (같은 트리를 두 번 쟀을 때 툴 선언이 2,895/2,899로 ±4 갈렸다. 직렬화 방식 차이이며, 위 측정법을 명시한 이유다.)
- [x] `MealCategory.delivery`·`.cooking` 판정 — Day 8 결론(2026-09-24, 위 메모): 죽은 코드 아님, 예약 값으로 유지. 지우지 않는다

**Phase 1 전용 실기기 테스트 시나리오(Day 12)** — *실제 UI 기준으로 교체함(2026-09-12)*, **사용자가 실기기에서 직접 확인한 결과(2026-09-12)를 반영**:
- [x] 일정 상세의 "목적지 주변" 섹션 — 정상 동작. **다만 사용자 피드백**: 이동 일정보다 활동 일정 쪽에 있는 게 더 자연스러워 보인다는 의견 → UX 결정 필요(아래 "남은 결정" 참고)
- [x] 기준 위치를 현재 위치 ↔ 일정 목적지로 바꿔가며 검색 — 정상 동작
- [x] AI 채팅 추천이 실제 검색 결과에 있는 가게만 말함(할루시네이션 없음) — 확인됨
- [x] **버그 발견 → 수정 완료**: `FullSirView`에서 식당을 고르면 식사 활동 블록만 생기고 왕복 이동은 안 생겼다. 원인: `applyDestinationSuggestion`이 "다음 일정"이 있을 때만 복귀지를 채우고, 없으면(가장 흔한 경우) `destination`을 그냥 nil로 비웠다 — "돌아가는 이동 만들기" 토글이 켜져 있어도 도착지가 없어 조용히 안 만들어짐. **수정**: 다음 일정이 없으면 출발지(`origin`)로 되돌아가는 것으로 기본값 설정. 같은 증상이 AI `create_activity`에도 있었다(갈 때 이동만 생기고 올 때가 안 생김) — 이쪽은 모델이 `return_to_query`를 종종 빠뜨리는 문제라 툴 설명에 "왕복이면 반드시 채워라"를 강조하는 프롬프트 보강으로 완화(모델 준수 여부는 재확인 필요)
- [x] **버그 발견 → 수정 완료**: AI가 만들어준 식사 일정이 "최근 먹은 것" 목록에 안 남았다. 원인: `executeCreateActivity`가 활동+이동만 만들고 `store.addMeal`을 호출하지 않았다(`meals.json` 연결은 `FullSirView` 경로에만 있었음). **수정**: `create_activity`에 `log_as_meal` 인자 추가 — true면 `FullSirView.save()`와 동일하게 `addMeal(activityId:)`까지 호출. 시스템 프롬프트에도 추천→예약 흐름에서 반드시 넣으라고 명시
- [x] 카카오 로컬 검색 결과 0건 — 빈 상태 UI 정상
- [x] 위치 권한 거부 — 정상 동작(안내 문구로 종료)
- [ ] **새로 발견된 요구사항(버그 아님, 기능 없음)**: be full sir 화면에서 "현재 위치/오늘 일정 목적지" 외에 기준 위치를 직접 검색하는 기능이 없어 외곽 지역을 기준으로 찾을 방법이 없음 → UX 결정 필요(아래 참고)
- [ ] 참고 의견(액션 없음): 랭체인 같은 구조를 붙이면 AI가 미묘하게 잘못 이해하는 부분이 줄어들지 않겠냐는 제안 — 지금 당장 필요한 변경은 아니라 메모만 남김. 재발하는 인자 누락이 계속되면 검토

**남은 결정(사용자 확인 필요)** — 위 두 항목은 버그가 아니라 설계 선택이라 코드를 더 건드리기 전에 확인받는다:
1. "목적지 주변" 맛집 섹션을 이동 일정 상세에서 활동 일정 상세로 옮길지, 양쪽 다 둘지, 지금 그대로 둘지
2. be full sir에 기준 위치 직접 검색(자유 위치) 기능을 지금 추가할지, 다음으로 미룰지

### Phase 2 — be healthy sir MVP — Day 14~20

**왜 다음인가**: HealthKit은 애플 표준 프레임워크라 외부 파트너십 없이 바로 시작 가능하고, be full sir가 만든 식사 데이터를 곧바로 영양소 계산에 재사용할 수 있어 의존성 순서상 자연스럽다.

| Day | 작업 | 대상 파일 | 완료 기준 |
|---|---|---|---|
| 14 | HealthKit 연동 기초: `Info.plist`에 `NSHealthShareUsageDescription` 추가, 프로젝트에 HealthKit capability(project.yml entitlements), `HealthKitService.requestAuthorization()` + `fetchTodaySteps()`/`fetchTodayActiveEnergy()`(HKStatisticsQuery) 구현 | `Shared/HealthKitService.swift`(신규), `project.yml` | 시뮬레이터/실기기에서 오늘 걸음수 콘솔 출력 확인(시뮬레이터는 Health 앱에 더미 데이터 필요) |
| 15 | 건강 목표 UI: `Models.swift`에 `struct HealthGoal: Codable { targetCalories: Int; targetActiveMinutes: Int }`, `HealthDashboardView`(목표 입력 + Day 14 데이터로 달성률 프로그레스바) | `Shared/Models.swift`, `Shared/HealthDashboardView.swift`(신규) | 목표 입력 후 달성률(%) 표시 동작 |
| 16 | be full sir 연동: `MealLog`에 `estimatedCalories: Int?` 필드 추가(1차는 AI 툴 `recommend_meal` 응답에 칼로리 추정치를 포함시켜 채움 — 별도 영양 DB 연동은 이번 스코프 제외), `HealthDashboardView`에 오늘 식사 칼로리 합산 표시 | `Shared/Models.swift`, `Shared/AIAssistant.swift`, `Shared/HealthDashboardView.swift` | 식사 기록 후 대시보드에 칼로리 합산 반영 |
| 17 | be on-time sir 연동: 활동량 목표 미달 시(Day 14 데이터 기준) `Store`에 "운동 일정 제안" 배너 → 수락 시 기존 `addEvent`로 캘린더 등록 | `Shared/Store.swift`, `Shared/ContentView.swift` | 목표 미달 조건에서 제안 배너 → 수락 시 일정 등록 확인 |
| 18 | **코드 검사**(§5-1 공통 + 아래 전용 항목) | `Shared/HealthKitService.swift`, `Shared/Models.swift`, `Shared/HealthDashboardView.swift` | 체크리스트 전 항목 확인, 발견 사항은 Day 20으로 넘김 |
| 19 | **실기기 테스트**(§5-2 공통 + 아래 전용 시나리오, HealthKit은 반드시 실기기 또는 Health 앱에 더미 데이터 넣은 시뮬레이터에서) | - | 체크리스트 전 항목 실행, 결과 기록 |
| 20 | **안정화**(§5-3 공통) | `STATUS.md` | be healthy sir MVP 완료 |

**Phase 2 전용 코드 검사 항목(Day 18)**:
- [ ] HealthKit 권한 거부 시 앱이 크래시 없이 "권한 없음" 상태를 보여주는지
- [ ] `HKStatisticsQuery` 콜백이 메인 스레드로 안전하게 튀는지(`DispatchQueue.main`/`@MainActor`)
- [ ] 운동 일정 제안 배너가 매 앱 실행마다 중복으로 뜨지 않는지(하루 1회 등 제한 로직)

**Phase 2 전용 실기기 테스트 시나리오(Day 19)**:
- [ ] Health 앱에 걸음수/활동 칼로리 더미 데이터를 넣은 뒤 대시보드에 반영되는지
- [ ] 목표 미달성 상태에서 "운동 일정 제안" 배너 → 수락 시 캘린더에 실제 등록되는지
- [ ] 식사 기록 후 칼로리 합산이 대시보드에 즉시 반영되는지
- [ ] HealthKit 권한을 거부한 상태로 앱을 켰을 때 나머지 기능(be on-time/full sir)이 영향받지 않는지

### Phase 3 — be rich sir MVP (수동 입력 기반, 축소 스코프) — Day 21~26

**왜 스코프를 줄였나**: 토스 등 금융 데이터는 마이데이터 사업자 등록 없이 공식 API 연동이 사실상 불가능하다(조사 없이도 일반적으로 알려진 제약) → 처음부터 "수동 입력 + 분석/제안"으로 범위를 좁혀 실현 가능하게 한다.

| Day | 작업 | 대상 파일 | 완료 기준 |
|---|---|---|---|
| 21 | 데이터 모델: `struct Expense: Codable, Identifiable { id: UUID; amount: Int; category: ExpenseCategory; date: Date; linkedEventId: UUID?; linkedMealId: UUID? }`, `Store`에 `expenses` 배열 + `expenses.json` 영속화(기존 패턴 그대로) | `Shared/Models.swift`, `Shared/Store.swift` | 빌드 성공, 저장/로드 왕복 확인 |
| 22 | 소비 입력 UI + 리포트: `ExpenseListView`(입력 폼) + `ExpenseReportView`(카테고리별 합계 파이/바 차트 또는 단순 리스트, 이번 주 목표 대비 초과 여부) | `Shared/ExpenseListView.swift`, `Shared/ExpenseReportView.swift`(신규) | 지출 입력 → 카테고리별 합계 확인 |
| 23 | be full/be on-time 연동: 식사(`MealLog.estimatedCost`)·이동 관련 지출을 `Expense`로 자동 제안(사용자 확인 후 등록, 자동 확정은 하지 않음 — 금액 데이터는 틀리면 신뢰를 잃는 영역이므로 확인 단계 필수) | `Shared/Store.swift` | 식사 등록 후 지출 자동 태깅 제안 → 확인 시 등록 |
| 24 | **코드 검사**(§5-1 공통 + 아래 전용 항목) | `Shared/Models.swift`, `Shared/ExpenseListView.swift`, `Shared/ExpenseReportView.swift` | 체크리스트 전 항목 확인, 발견 사항은 Day 26으로 넘김 |
| 25 | **실기기 테스트**(§5-2 공통 + 아래 전용 시나리오) | - | 체크리스트 전 항목 실행, 결과 기록 |
| 26 | **안정화**(§5-3 공통) | `STATUS.md` | be rich sir MVP 완료 |

**Phase 3 전용 코드 검사 항목(Day 24)**:
- [ ] 금액(`amount: Int`) 입력 검증 — 음수/빈 값이 그대로 저장되지 않는지
- [ ] 자동 태깅 제안이 "제안"에 그치고 사용자 확인 없이 `Expense`가 바로 생성되지 않는지(§3 안전 원칙)
- [ ] `linkedEventId`/`linkedMealId`가 삭제된 일정/식사를 참조하는 경우(dangling) 리포트 화면이 크래시하지 않는지

**Phase 3 전용 실기기 테스트 시나리오(Day 25)**:
- [ ] 지출을 수동으로 입력 → 카테고리별 합계 리포트에 즉시 반영되는지
- [ ] 식사/이동 일정 등록 후 지출 자동 태깅 제안이 뜨고, 확인 시에만 등록되는지(취소 시 등록 안 되는지도 확인)
- [ ] 이번 주 목표 금액을 초과했을 때 리포트에 초과 표시가 뜨는지
- [ ] 연결된 일정/식사를 삭제한 뒤 지출 리포트를 열어도 정상 동작하는지(dangling 참조 케이스)

### Phase 4 — be fun sir MVP — Day 27~31

**왜 마지막 신규 서비스인가**: 사업계획서상 우선순위가 가장 낮고, 실제 유의미한 추천(인터파크/야놀자 연동)은 외부 제휴가 필요해 리스크가 높다 — 우선 규칙 기반 최소 버전만 구현.

| Day | 작업 | 대상 파일 | 완료 기준 |
|---|---|---|---|
| 27 | 여가활동 추천 로직(규칙 기반, 외부 API 없이): 오늘 일정의 빈 시간대 + 현재 위치 기준 `category_group_code=CT1`(문화시설)/`AT4`(관광명소) 카카오 로컬 검색으로 후보 제시 | `Shared/FunSuggestionService.swift`(신규) | 빈 시간대에 근처 여가 후보 리스트 표시 |
| 28 | be on-time sir 연동: 추천 항목 선택 시 기존 `addEvent`로 일정 등록 | `Shared/Store.swift` | 여가 일정 등록 확인 |
| 29 | **코드 검사**(§5-1 공통 + 아래 전용 항목) | `Shared/FunSuggestionService.swift`, `Shared/Store.swift` | 체크리스트 전 항목 확인, 발견 사항은 Day 31로 넘김 |
| 30 | **실기기 테스트**(§5-2 공통 + 아래 전용 시나리오) | - | 체크리스트 전 항목 실행, 결과 기록 |
| 31 | **안정화**(§5-3 공통) | `STATUS.md` | be fun sir MVP 완료 |

**Phase 4 전용 코드 검사 항목(Day 29)**:
- [ ] "빈 시간대" 계산이 자정을 넘기는 일정이나 겹치는 일정에서도 올바른지
- [ ] 카카오 로컬 검색 결과가 0건일 때 빈 상태 UI 처리

**Phase 4 전용 실기기 테스트 시나리오(Day 30)**:
- [ ] 오늘 일정 사이 빈 시간대가 있을 때 여가 후보가 실제로 뜨는지
- [ ] 후보 선택 → 캘린더에 등록되는지
- [ ] 일정이 하루 종일 꽉 찬 날에는 추천이 뜨지 않거나 "추천 없음"으로 명확히 표시되는지

### Phase 5 — 통합 대시보드 & 베타 준비 — Day 32~38

| Day | 작업 | 대상 파일 | 완료 기준 |
|---|---|---|---|
| 32 | 메인 화면 재설계: `ContentView`를 "오늘의 시간표 + 5개 서비스 핵심 지표 카드"(사업계획서 3장 표 그대로 — 목표 칼로리/운동량, 오늘 사용 금액/목표 금액 등) 레이아웃으로 개편(이미 완료된 월/주/일 스와이프 캘린더 UI 위에 지표 카드만 추가하는 형태) | `Shared/ContentView.swift` | 홈 화면에서 5개 지표 카드 확인 |
| 33 | 서비스간 연계 누락 점검: 사업계획서 4장 표(5개 표 전체)를 체크리스트로 놓고 이번 로드맵에서 구현 안 된 연결(예: be fun sir 소비 자동 기록, be rich sir → be healthy sir 제안) 확인 및 우선순위 높은 것만 보완 | 해당 파일들 | 체크리스트 대비 구현률 문서화 |
| 34 | 프록시 보안 강화: Cloudflare WAF 레이트리밋 규칙 추가, `APP_TOKEN` 로테이션 절차 문서화. **OpenAI 실사용 비용도 이 시점에 실측**하고 대시보드에 월 한도를 건다(프록시가 토큰만 있으면 누구나 부를 수 있으므로 레이트리밋이 곧 비용 방어다) | `proxy/wrangler.toml`, Cloudflare·OpenAI 대시보드 | 레이트리밋 1건 적용 확인 |
| 35 | 베타 준비: 테스트 시나리오 문서 정리, 파트너십 후보 1곳(예: 카카오/구글 외 구글Fit 또는 삼성헬스) 컨택 초안 작성 | `STATUS.md` 또는 별도 문서 | 베타 착수 가능 상태 |
| 36 | **전체 코드 감사**: §5-1 체크리스트를 프로젝트 전체(Phase 0~4에서 만든 모든 신규 파일)에 다시 적용 — 개별 Phase에서는 놓쳤을 수 있는 서비스 간 상호작용(예: `Store`에 배열이 5개나 쌓이면서 생긴 로딩 순서 문제) 위주로 확인 | 프로젝트 전체 | 감사 결과 문서화(발견 시 Day 38로) |
| 37 | **전체 실기기 회귀 테스트**: 5개 서비스 각각의 핵심 시나리오(§5-2의 Phase별 시나리오 전부)를 한 기기에서 순서대로 실행 — 개별 Phase 테스트 때는 없던 "여러 서비스 동시 사용" 상태(예: 일정 많고 지출 많고 건강 목표도 설정된 상태)에서 성능/충돌 확인 | - | 전체 시나리오 통과, 성능 저하(캘린더 스와이프 렉 재발 등) 없음 |
| 38 | **최종 안정화**: Day 36~37에서 발견된 문제 수정, `STATUS.md`를 베타 배포 가능 상태로 최종 갱신, 커밋 | `STATUS.md` | 베타 착수 가능 상태 확정 |

### Phase 1.5 — 메모리 제거 + 앱 주도 선택형 되묻기 (로드맵 외 삽입, 2026-09-15 사용자 요청) — ✅ 완료(2026-09-15, SPEC-ASK-001 M1~M6)

**완료 기록(2026-09-15)**: 설계 그대로 실현 — `SPEC-ASK-001`(`.moai/specs/SPEC-ASK-001/`)로
공식화해 M1~M6 완료. 아래 "열린 결정"은 **묶음 카드(선택지 C)**로 확정: 부재 인자마다 행을 모은
한 장 카드 + 확인 버튼, 확인 시 툴 정확히 1회 호출. as-built 차이 2건 — ① "한 번에 하나씩 순차로
묻는다"는 D-1 확정으로 **한 장 카드 + 스크롤 오버플로**로 바뀌었다(순차 질문의 중단 비용), ② `weeks`도
선언에서 빼 카드의 기간 줄(칩 4/8/12/26주, 직접입력 1~26)로 이사했다. 검증: GuardDriver **88/88**
(카드 단언 (a)~(e)·무기억 회귀 포함)·proxy 7/7·iOS·macOS 무경고 빌드 — 2026-09-15 최종 트리에서
실측. code-safety 검토에서 "현재 위치" 실패 문구의 내부 토큰 노출 1건을 배포 전에 수정(카드 확인
경로의 실패 묻힘은 무죄 — 확인의 툴 실패는 대화에 남고, 미응답 카드는 안내 말풍선으로 전환된다).
`CHECKLIST.md` 전면 갱신(95행), 실기기 확인 목록은 그 문서에.

**왜 지금 하나.** 저장된 선호가 조용히 적용되다 사용자가 모르는 채 틀린 값이 쓰이는 사고가 반복됐다
(`b303f41` — 여유 0분짜리 35건이 등록되고도 아무도 몰랐다). 5개 서비스 전체의 활동 로그를 쌓아
AI가 사용자를 학습하는 **제대로 된 메모리는 별도 plan으로 전 기능 구현 후 한 번에** 만든다. 그때까지
지금의 얕은 메모리(`ai_memory.json` + 선호 필드)는 이득보다 사고가 큰 부채이므로 걷어낸다.

**핵심 결정 — 되묻는 주체는 앱이다(사용자 승인 2026-09-15).** 모델이 아니다.
근거는 이 프로젝트가 직접 측정한 모델 행동이다: 이 모델은 **선언된 선택 인자를 비워두지 못하고 전부
채운다**(`b303f41`의 근본 원인). "비워둬라"·"물어봐라"는 이 프로젝트에서 가장 안 지켜지는 지시이고,
2026-09-15 실기기 전사에서도 `mode_this_time`이 여전히 채워져 왔다. `weeks` 되묻기가 거의 안 뜨는
것도 같은 이유다(모델이 채워서 `weeksArgument(input) == nil`이 성립하지 않는다). 되묻기를 모델에
맡기면 메모리 폴백까지 사라진 자리에 **임의 값이 조용히 들어간다**.

**따라서 따라오는 결정 — 되물을 인자는 툴 선언에서 아예 뺀다.** 앱이 "인자가 비었다"를 보려면
모델이 그것을 채울 수 없어야 한다. 선언에 남겨두고 "채우지 마라"라고 적는 방식은 이미 두 번 실패했다.
사용자가 직접 말한 경우("자동차로 가자", "여유 20분")는 **앱의 문장 파서가 잡는다** — 모델을 거치지
않으므로 모델 행동과 무관하게 결정적이다. 부수 효과로 툴 선언이 줄어 고정 토큰비(현재 4,425)가 내려간다.

**지우는 것**: `remember_fact`·`forget_fact` 툴, `ai_memory.json`, 시스템 프롬프트의
`factsBlock`·`prefsBlock`·`modeBlock`, `Config`의 선호 필드, `resolvedMode`/`resolveOrigin`의
저장값 폴백, `applyStatedPreferences`.
→ **이 삭제는 "모델이 바뀌었으니 방어를 걷어낸다"가 아니다**(CLAUDE.md가 금지하는 것). 폴백을
**더 강한 것으로 교체**하는 것이다 — 값이 없으면 추측하지 않고 묻는다.

**만드는 것**: 비어 있는 인자를 앱이 감지해 채팅창에 선택 칩을 그리고, 탭한 값으로 툴을 재호출하는
경로. 질문·선택지·재개할 호출을 담는 보류 상태, `Bubble`의 선택지 case, `AIChatView`의 칩 렌더링.
여러 인자가 비면 한 번에 하나씩 순차로 묻는다.

**검증**: `Tools/GuardDriver.swift`에 "인자가 없으면 칩 요청이 나온다 / 탭한 값으로 재호출된다"를
단언으로 넣는다 — 앱 주도이므로 모델 없이 결정적으로 검증된다(모델 주도였다면 불가능했다).

**열린 결정**: 매번 전부 물으면 일정 하나에 이동수단·여유·알림을 세 번 묻게 된다. 진짜 매번 물을지,
앱이 켜져 있는 동안만 기억할지(영속 안 함), 한 화면에 묶어 물을지 — 착수 전 확정한다.

### Phase 1.6 — 실기기 회귀 수정 + 카드 확장 (로드맵 외 삽입, 2026-09-16 사용자 실기기/시뮬레이터 확인) — 진행 중

**왜 생겼나.** 2026-09-15에 SPEC-ASK-001을 "완료"로 닫았으나, 다음 날 실기기·시뮬레이터
확인에서 **카드가 뜨지 않는 경로가 다수 발견**됐다. 가드 드라이버는 88/88 초록이었다 —
드라이버가 보지 않는 자리(툴 선언 문구, 발화 사이 상태, 모델이 보내는 미선언 인자)에
결함이 있었다. **로직 검증이 초록이어도 기기에서 안 돌 수 있다**는 것이 이번 회차의 교훈이고,
Day 마무리에 실기기 확인을 넣어둔 이유가 그대로 증명됐다.

**전제가 틀렸던 지점(가장 중요).** Phase 1.5는 "되물을 인자는 툴 선언에서 아예 뺀다 —
모델이 채울 수 없어야 앱이 '비었다'를 관측한다"를 근거로 삼았다. **이 전제는 거짓이다.**
선언에서 빼는 것은 "알려주지 않는다"일 뿐 "보내지 못한다"가 아니며, 백엔드는 미선언 인자를
걸러주지 않는다. 2026-09-16 시뮬레이터 실측에서 `create_recurring_schedule`이 선언에 없는
`mode_this_time`·`buffer_minutes`·`notify_lead_minutes`·`weeks`를 전부 실어 왔고, 앱이 그것을
"차 있다"로 읽어 카드를 띄우지 않았다 — **사용자가 고른 적 없는 기간 8주로 118건이 등록됐다.**
SPEC-ASK-001이 없애려던 조용한 적용이 그대로 재현된 것이다.
→ 따라서 선언 축소는 **힌트**이고, 실제 방어는 **앱의 입력 정화(결함 D)**다. 이 둘을 같이 둔다.

**이번에 고치는 것** (전부 `Shared/AIAssistant.swift` + `Tools/GuardDriver.swift`, 화면은 아래 ①만):

| 결함 | 증상 | 고침 |
|---|---|---|
| A | 왕복인데 `travel_from_query`가 비어 편도로 퇴화 — 가는 편 줄·가는 이동·여유 줄이 통째로 사라짐 | 선언 대칭화 + 앱이 "가는 편 출발지"를 카드로 물음("가는 편 없음" 탈출 칩 포함) |
| B | 모델이 되묻는 턴이 끼면 앞서 말한 "자동차로·여유 20분"이 증발해 카드가 다시 물음 | `statedArgs`를 덮어쓰지 않고 병합, **툴 실행 시점에** 소거(등록이 곧 요청의 끝) |
| C | 모델이 첫 호출부터 `on_conflict:"ignore"`를 실어 와 **겹침 검사가 통째로 건너뛰어짐** | `confirm_recurrence`·`confirm_zero`와 같은 패턴 — 앱이 실제로 물었을 때만 유효 |
| D | **선언에 없는 되묻기 인자를 모델이 보내면 앱이 그대로 믿음** (위 "전제가 틀렸던 지점") | 들어온 인자를 읽히기 전에 단일 관문에서 정화. 생성 도구 3개에만, `update_*`는 제외 |
| E | 말하지 않은 출발지를 모델이 지어냄(`origin_query=집`) | **프롬프트 강화만** — 장소명은 무한해서 문장 파서로 옮기면 틀린 출발지가 조용히 들어가는 쪽이 더 나쁘다(2026-09-16 사용자 결정) |
| F | 기억이 없는데 "앞으로 자동차로 할게요"라고 **지키지 못할 약속**을 함 | 프롬프트 — 미래를 약속하지 말고 이번 요청에만 적용, 매번 묻는다는 사실과 이유를 정직하게 |
| G | 자정을 넘는 블록이 **반쪽만 보임**(이동은 도착일만, 활동은 시작일만) | `events(on:)`/`activities(on:)`을 "그 날과 겹치는" 기준으로, `span(for:)`이 그리는 날을 받아 0~1440으로 자름 |
| ① | "일정 생성" 한마디로는 못 만듦. 목적지를 안 말하면 모델이 지어냄 | 카드에 **제목·목적지·시각** 줄 추가 — 탭만으로 완결. 목적지 결함도 여기서 닫힌다 |
| K | `회사`라고 말했는데 즐겨찾기에 없자 장소 검색 **첫 결과**를 확인 없이 채택 — **'농업회사법인 화조원'으로 118건 등록**(2026-09-16 시뮬레이터 관찰). 일반명사는 장소 이름이 아닌데 앱이 구분하지 않았다 | 생성 경로에서 즐겨찾기 없는 일반명사류를 검색 결과로 조용히 때우지 않는다. "해석된 이름이 질의를 포함하는가" 판정은 이 사례에서 실패한다('화조원'이 '회사'를 포함) |
| L | `일정 생성` 한마디에 모델이 **툴을 부르지 않고 말로 되물었다** — ①의 전제(빈 인자 호출 → 앱이 카드로 묻기)가 성립하지 않았다. `required`를 비운 것만으로는 부족 | 프롬프트에 "정보가 부족해도 말로 묻지 말고 빈 인자로 호출하라 — 묻는 일은 앱이 한다". E와 같은 계열이라 **수용된 갭**으로 남는다 |
| M | 카드에서 가는 편 자동차·오는 편 대중교통을 골랐는데 **이동이 0건** 만들어지고 요약이 아무 말도 안 했다(`events.json` 직접 확인). `집`이 즐겨찾기에 없어 해석 실패 → `madeLegs > 0`일 때만 언급하므로 실패가 묻힘 | 이동 질의가 **비어 있지 않은데 해석 실패**하면 사용자가 보게 한다. "명시적으로 안 만듦"과 "만들려다 실패"가 같은 결과로 보이면 안 된다(L7과 같은 태도) |
| N | 반복 일정 등록이 너무 느리다 — `hasGoogleCalendar`가 **"클라이언트 ID가 있나"**일 뿐이라 구글 계정을 **연결하지 않아도 참**이고, 58건 등록이 회차마다 `accessToken(allowInteractive:)` + 네트워크를 순차로 시도하다 전부 실패하며 `catch`가 조용히 삼킨다(2026-09-16 사용자 보고 → 코드 추적). 제대로 된 `googleConnected`(:506)는 설정 화면에서만 쓰인다 | 모든 캘린더 쓰기 경로를 **연결 여부**로 막고, 등록은 로컬에서 먼저 끝내 응답한 뒤 캘린더는 뒤에서 올린다. **실패를 조용히 묻지 않는다** — 회차별 동기화 상태(대기/완료/실패)를 영속화하고 사용자가 볼 수 있는 자리에 드러낸다(뒤로 보내면서 `try?`로 삼키면 오늘 결함이 더 나빠질 뿐이다) |
| O | K 게이트가 **대화를 끊는다** — 즐겨찾기 없는 `회사`를 말하면 "즐겨찾기에 추가해 주세요"로 끝나고 일정이 안 만들어져, 사용자가 설정 화면에 다녀와 처음부터 다시 해야 한다(2026-09-16 사용자 관찰·요청) | 실행부에서 거절하는 대신 **카드에 그 장소 줄을 띄운다**(즐겨찾기 칩 + 직접입력). 판정이 동기(즐겨찾기는 메모리, `genericPlaceWords`는 정적 집합)라 `askFields`에서 바로 가능하다. 실행부 가드는 그대로 둔다 — 카드 먼저, 가드는 뒤(`missingAskedArguments`의 선례) |
| P | 장소 줄의 `[직접입력]`이 **그냥 빈 칸**이라 무엇이든 통과한다 — 카드를 다 채우고 **확인을 누른 뒤에야** 실행부가 "위치를 찾지 못했어요"로 되돌린다. 사용자가 `ㅁㄴㅇㄹ`를 넣어 시험하며 그대로 드러났다(2026-09-16 관찰·요청: "위치 입력칸에 주소 검색 기능이 없음") | 직접입력을 **검색해서 고르는 자리**로. `placeSearch.search`(실행부와 같은 경로)로 후보를 띄우고 탭해서 확정 — 확인 뒤에 실패할 여지를 없앤다. 호출은 묶어서(카카오 할당량), `await` 뒤 카드 자리 재확인, 빈 결과·오프라인은 정직하게 |
| H | 이 모델은 "비움"을 **빈 문자열**로 실어 보낸다 — `arrival_iso:""`가 nil 판정을 통과해 시각 줄이 영영 안 뜨고, 확인 뒤에야 실행부가 `parseDate`에서 걸러 모델에게 되물게 했다 (2026-09-16 코드 검사 발견) | `askFields`의 시각·여유 유무 판정을 nil 검사에서 `filled()`로 — 빈 문자열도 "비었다". 드라이버 W1 |
| I | `end_iso`에 상한이 없다(9999년도 통과) — `dayKeys`가 `activities`의 didSet 안에서 하루씩 걷는데 비한정이면 **화면이 얼고, 그 레코드를 지우려 해도 켤 때마다 다시 얼어** 지울 수도 없다 (2026-09-16 코드 검사 발견) | `dayKeys` 걷기를 366일에서 끊는다(그 너머의 긴 반복은 반복 활동의 영역). 드라이버 W2. 생성 시점 범위 검사는 미적용 — 데이터를 버리는 행동이라 구현 전문가 판단에 맡김 |

G는 `Shared/ContentView.swift`, ①은 `Shared/AIChatView.swift`가 함께 바뀐다.
**CHECKLIST.md 정정 필요**: F1(충돌 검사)·G10(출발지)·K9(자정 넘김)의 ✅는 이번 관찰로 반증됐다.

### Phase 1.7 — 일정·활동 화면 UI 통일 (2026-09-16 사용자 요청, 범위 확정: **활동까지 전부**) — 진행 중

`AddEventView`(550) · `EventDetailView`(377) · `AddActivityView`(267) · `ActivityDetailView`(222)
네 화면을 AI 카드와 **같은 UI**로 통일한다 — 약 1,800줄. 같은 일(일정 만들기)을 하는 화면이
세 벌이라 한 곳을 고치면 나머지가 어긋나는 구조를 없앤다(계약 5의 단일 출처 원칙을 화면에도 적용).

**네 장으로 쪼갰다** (2026-09-18, 칸반 대기열). 네 화면 + 컴포넌트 + AI 카드는 6파일이라 한 Day
3~4파일 제한을 넘는다. 그래서 컴포넌트 추출을 먼저 떼어내고, 화면 전환을 일정·활동으로 나눴다.
t2는 plan 단계에서 한 번 더 쪼개졌다 — 장소 검색 디바운스를 계약 5대로 단일화하려면
`AIAssistant.swift`가 열려야 해 5파일이 되므로, 운영자가 2a(추가 화면+디바운서)/2b(상세 화면)
분할을 확정했다(2026-09-18).

| 카드 | 범위 | SPEC | 상태 |
|---|---|---|---|
| t1 | 편집 카드 컴포넌트를 `Shared/`로 추출 + **AI 카드만** 그것을 쓰도록 전환 | `SPEC-UIKIT-001` | done — 2026-09-18 plan·run·sync 완료 |
| t2 | UI 통일 2a — `AddEventView` 전환 + 장소 검색 디바운서 단일화(4파일) (t1 done 이후) | `SPEC-UIKIT-002` | done — 2026-09-20 run·sync 완료 |
| t4 | UI 통일 2b — `EventDetailView` 크롬 통일 + 시각 포매터·기준 매핑 단일화(본체 2파일 + N2 치환 8줄) (t2 done 이후) | `SPEC-UIKIT-004` | done — 2026-09-20(run·sync 종결, 3-phase close. Phase 1 감사는 INCONCLUSIVE→운영자 승인 진행 — 채널 전멸 경위·재감사 조건은 plan-audit 일일 기록) |
| t3 | `AddActivityView` · `ActivityDetailView` 전환 (t4 done 이후) — 이동 다리(leg)를 컴포넌트 옵션으로 흡수 | `SPEC-UIKIT-003` | done — 2026-09-22(run·sync 종결, 3-phase close. 카드 본문에 없던 차이 1건이 plan 단계에서 새로 판단됐다 — **기준 없는 시각 줄**: 활동의 시작·종료는 도착/출발 기준이 성립하지 않아 기준 칩 줄을 통째로 없앴다(REQ-001~003). Phase 1 감사 iteration 1 FAIL→델타 수정→iteration 2 PASS) |
| t6 | 장소 좌표 사전의 이름-키 충돌 수리 — `AddEventView`(줄 신원 키) · `AIAssistant`(단사 열쇠, B안) (t3 done 이후 · t5 앞) | `SPEC-UIKIT-005` | **sync 종결 — 2026-09-23(3-phase close). 기계 게이트 넷은 sync 레인이 직접 재실행해 통과**: 드라이버 205/205(exit 0)·프록시 7/7·iOS·macOS `BUILD SUCCEEDED` swift 경고 0/0. **카드가 닫히지 않은 이유는 AC-006·AC-009가 ⬜이기 때문이다** — 시뮬레이터 14단계와 실기기 4건은 운영자 실행 대기이고, 이 프로젝트에서 기계 초록은 완료가 아니다(2026-09-15 드라이버 88/88 다음 날 실기기 결함 7건). 후속 3건 등록: 14번 격상·15번·16번 |
| t5 | 데드 코드 정리 — 호출부 없는 함수 넷 중 셋 제거(`Store.addActivity`·`Store.deleteExpired`·`LocationManager.openLocationSettings`와 그것만 쓰던 `AppKit`/`UIKit` import), `Store.updateMeal`은 SPEC-FULL-001 REQ-003 때문에 이유 주석과 함께 유지, 쓰이지 않는 `import CoreLocation` 셋 제거 (t6 done 이후) | `SPEC-UIKIT-006` | **sync 종결 — 2026-09-23(3-phase close).** 동작이 바뀌는 자리 0곳(−50/+2 — 더한 두 줄은 제자리로 옮긴 문서 한 줄과 이유 주석 한 줄)이라 실기기 전용 항목이 없다. 게이트: iOS·macOS **새 DerivedData로 전체 빌드** `BUILD SUCCEEDED` swift 경고 0/0 · 프록시 7/7(sync 레인 재실행) · 드라이버 205/205는 run 레인 측정을 인용(컴파일 집합 12파일이 `b8bbe1c`와 바이트 동일 — 실데이터를 건드리는 실행을 다시 하지 않았다). 독립 `--deep` 렌즈 결함 0. `CHECKLIST.md` 인용 재정렬(끝점 89개 바이트 대조) 중 **이전부터의 오인용 4건**(L3·I2·A3·L14)을 함께 고쳤다. 이 파일 `:105`의 "알고도 안 고친 것" 중 `deleteExpired`를 닫았다 |
| t7 | 일정 편집의 출발지 덮어쓰기 수리 — 출발지 줄에 편집 씨앗 한 줄(`chosen: editing?.origin?.name`) + `confirmedPlace` 주석 재서술(후속 17의 수리, 결함은 t2 `1b98e14`에서 유입) | `SPEC-UIKIT-007` | **sync 종결 — 2026-09-24(3-phase close).** 코드 커밋은 `b73013b` 하나다(한 줄 +주석 3줄, 645줄 그대로). run: AC-001~004 기계 신호·빌드 통과. 시뮬레이터 한 자리(dd-a·dd)에서 파트 A **(가) 재현**(AC-005), 파트 B 1~8 통과(AC-006·007). 같은 자리에서 SPEC-UIKIT-005 AC-009의 보류 판정·6번 통과, SPEC-UIKIT-003 AC-010은 15/16(16번 VoiceOver는 실기기 이월). **AC-005·006의 값 기록 절은 미충족이다** — 수치(N₀·X·D 등)가 없어 판정만 남았고, 수용 여부는 리드 몫이다. sync: 새 DerivedData로 iOS·macOS `BUILD SUCCEEDED` swift 경고 0/0 · 프록시 7/7(이 레인 재실행). 드라이버는 금지이고 이 경로에 닿지 않는다. 후속 17 닫음. 인용 드리프트 0(바이트 대조), 대조 중 이전 오인용 1건(후속 5) 수리. 독립 `--deep` 렌즈 결함 0 · 관찰 7 → 후속 19(이 수리가 깨운 표시 둘과 주석 범위)·20(원래 있던 넷). 남은 것은 실기기 셋(spec §3.3)과 O-1이고 Day 닫기로 넘긴다. 카드 밖 사안(AC-009 7·9번·U-3·U-4)은 Day 닫기 이월 목록에서 리드가 관리 |
| t8 | 가드 드라이버 구조적 경화 — 실행마다 임시 홈 샌드박스(`CFFIXED_USER_HOME`, 실패하면 exit 2) · 실제 지원 디렉터리 바이트 대조(다르면 exit 3) · 머리말의 `googleClientID` 비움(키체인 게이트) · 불변식 세 자리 · 내부 기한(기본 900초, exit 124) + `CLAUDE.md` 격리·종료 코드 문장 + 하네스 스킬의 `updateMeal` 후보 정리(2026-09-23 드라이버 2차 사고의 구조적 수리) | `SPEC-TEST-001` | **sync 종결 — 2026-09-24(3-phase close).** 코드 커밋은 `de8fd77` 하나다(`Tools/GuardDriver.swift` +162/−1, `Shared/`·`proxy/` 무변경). run: 짧은 기한 실행 exit 124·4초, 전체 실행 exit 0·**212/212**(205 + 새 단언 실행 7), 실제 폴더 해시 무변경, 키체인 창 없음. sync: 이 레인이 신선 컴파일로 다시 돌려 **exit 0·212/212·불변식 9/9 ✓**, 바깥 기록(실행 전후 `ls`·`shasum`·`pgrep`) diff 0, 샌드박스 삭제 확인, 운영자 관측 "키체인 창 없음" — **212가 이 병합부터의 드라이버 기준선이다.** iOS·macOS 빌드와 프록시는 입력이 t7 sync 측정 트리 이후 바이트 동일해 그 값(swift 경고 0/0 · 7/7)에 귀속했다. 독립 `--deep` 렌즈 결함 0 · note 4. 그중 `CLAUDE.md`의 "마지막 줄 `P/T 통과`"가 실제 출력(그 뒤에 대조 줄이 한 줄 더 찍힘)과 달라 운영자 승인으로 한 구절 고쳤고, `CHECKLIST.md` 드라이버 인용 끝점 7개도 운영자 승인으로 옮겼다(둘 다 SPEC REQ-008 sync 범위 밖 예외, 바이트 대조 검증). Day 닫기로 넘기는 것: `CHECKLIST.md`의 옛 트리부터 틀린 인용 11개와 사실이 달라진 문장 둘("세 겹의 안전장치", "드라이버는 실제 앱 데이터에 쓴다"), O-1(드라이버의 네트워크 호출 가설 · `CLAUDE.md`의 "(API 할당량 안 씀)"), O-2(절마다 백업 7곳), note n2(시한·크래시 샌드박스 잔존 — run의 짧은 실행이 남긴 1개가 있다). 공용 메모리의 "t8 전까지" 절차 갱신은 병합 뒤 리드 몫이다 |
| t9 | Day 닫기 전수 검사 — CLAUDE.md Day 종료 절차(체크리스트 전면 재생성·버그 4부류+간결성 검사·이월 목록 전 항목 배치) | 없음(검사 카드 — 명세는 CLAUDE.md Day 종료 절차) | **done — 2026-09-24** 기준선 게이트 이 레인 재실측 통과(드라이버 212/212 두 실행·exit 0·불변식 9✓·실데이터 해시 무변경 · iOS·macOS swift 경고 0/0 수리 전후 · proxy 7/7). 구멍 1건 그 자리 수리: 후속 20② 저장 버튼 `saving` 게이트(AddEventView:119 1줄, 본보기 AddActivityView:509). 신규 결함 2건 발견(EventDetailView.loadTransitPath 무취소 경합 · Store.updateActivity 조용한 실패) + O-1 정정(네트워크 관측 0건/136샘플이나 코드상 최대 ~5회/실행 가능 — "모델 API 할당량 안 씀"은 참) + n2 잔여 샌드박스 정리. 이월 배치·카드 추천 전체 목록은 `.moai/reports/day-close-20260924.md` |
| t10 | 드라이버 위생(C1) — O-1 시작 블록에서 `proxyBaseURL`·`appToken` 비움(프록시 경유 카카오·ODsay 조회 구조적 차단) + O-2 절마다 파일 백업 9쌍 제거(Q절 쌍은 구현 중 발견한 `loadHistory` 재독쓰를 레인이 등가 판정으로 승인해 포함 — 인사말 리터럴 동치, code-safety 대항 검증) + 전역 불변식이 프록시 비어 있음을 함께 검사(`drvAssertNoCalendarPush`→`drvAssertGlobalInvariants` 개명, 단언 수 불변) + CLAUDE.md 수동 청소 절차(스위퍼 미도입 — 운영자 결정) | 없음(원인 전부 확정 — plan 생략; 근거: day-close-20260924 §6·§7·같은 날 code-safety §3·§4) | **sync FAIL(D1·D2) 수리 완료 — 병합 대기(2026-09-24)** 재게이트: 드라이버 **212/212·exit 0**(기준선 무변동 — 수리 전 1회 + N1·N2 반영 뒤 2회 + sync 독립 재실측 1회)·불변식 9/9 ✓(프록시 검사 포함 새 라벨)·실데이터 해시 무변경(events·activities `4f53cda1…`·config `e2698db8…`)·소켓 표집 0건(양성 대조로 "볼 수 있음"을 먼저 증명한 표집 — 1차 이름 grep은 lsof COMMAND 9글자 절단으로 원리상 무효였음을 sync D1이 지목, 재실측으로 대체) · iOS·macOS swift 경고 0/0 · proxy 7/7(빌드·proxy는 앱 입력 무변경 — Shared·proxy·project.yml 대비 diff 0줄). code-safety 대항 리뷰 "재게이트 진행 허가"(결함 1건 CHECKLIST 안전장치 문단 좌표 드리프트 — 그 자리 수리, t10 소행 맞음). 운영자 결정 2건 반영: 차단 코드 시행·CLAUDE.md:58 문구 현행 유지 / 스위퍼 미도입·수동 청소만 문서화. 차단 뒤 드라이버 완주가 433초→9초로 줄었다(죽은 DNS를 향한 프록시 타임아웃 대기 소멸). 잔여: ipwho.is 직접 폴백(유효 표집 관측 0·이론 가능, 프록시 밖)·Z절 선재 낡은 주석(GuardDriver :1499)·Q쌍 무백업의 세 전제(① resetConversation이 contents=[]·lastRecurrenceId 없음·보류 카드 없음으로 저장 ② 드라이버가 submit·confirmAsk에 닿지 않음 ③ 샌드박스가 히스토리 파일 없이 시작 — 인사말 리터럴 :119/:223은 버블 텍스트를 읽는 단언이 없어 판정에 무관, sync N4 정정) |
| t11 | `AddEventView` 경합·표시 묶음(C2) — 후속 20①(`recomputeEstimates` await 경합 — `estimateFlights` 카운터·`await` 뒤 신원 재확인)·20④(`gatedRows(seeding:)` 과부하로 접힘)·N1(`save()`가 `travelSecondsHint`를 안 넘기던 것 — 폼↔저장 값 어긋남 창)·후속 19 셋 + code-safety F1(옛 좌표 힌트 저장 회귀 — `estimatesFor` 쌍 대조)·F2(값 찬 줄 안내 잔존) | 없음(원인 전부 확정 — plan 생략; 근거: day-close-20260924 §6·§7) | **done — 2026-09-24.** 코드 커밋 `f0c18da`. sync 1차 FAIL D1·D2·D3(문서 인용 드리프트 — CHECKLIST 12좌표 줄밀림·이월 2번 미표기·plan 후속 14) → 수리 `6285f19` + SHA 백필 `368b30e`, 리드 ff push `f13ca3c..368b30e`·done t11. sync 신규 N5(장소 변경마다 조회 재실행 무취소 + prefill 5초/측위 8초 불일치)는 t12 디스패치 때 부류 노트로 태웠다. 시뮬레이터 4항목(경합 표시·권한 안내·편집 냉시작 무스피너·저장 시 조회 0회)은 운영자 몫 |
| t12 | 무취소 Task 부류(C3) — 후속 12 nearby `onChange` + 신규 `EventDetailView.loadTransitPath` 무취소를 **취소-교체 패턴 하나로**(4파일: `transitTask`·`nearbyTask`·`estimateTask`/`prefillTask` 태깅 + `await` 뒤 `!Task.isCancelled` 가드 + `LocationManager.locateTimeoutSeconds` 단일 출처) + t11 sync N5 동반(prefill 대기 파생 — iOS 9초·macOS 현행 5초 바이트 동일) | 없음(원인 전부 확정 — plan 생략; 근거: day-close-20260924 §6 rows 6·14·§7·t11 sync N5) | **sync FAIL(문서 D1~D4) 수리 완료 — 병합 대기(2026-09-25).** 코드 `7532f10`은 sync 판정 **PASS**(독립 렌즈 DEFECT 0건 — 발화 지점 전수·카운터 균형·onDisappear KEEP; 게이트도 sync가 격리 사본으로 독립 재현 — 드라이버 212/212·iOS·macOS 무경고·proxy 7/7). 수리: 문서 D1~D4(CHECKLIST 좌표 9건·이월 3번 처리됨 표기·plan 후속 12 닫힘·11·14 재사상·progress 기전 2건 정정) + 리드 판정으로 권고 코드 N1(`startTimeout` 취소 가드 — 이중 호출 경로에서 IP 폴백 사망·스피너 조기 소등이던 사전 존재 결함, 기전은 sync D4 실험 정정)·N2(주변 스피너 순서)·N3(`choose()` 장소 변경 조회 취소)·N4(주석)·N7(오타) — 커밋 `01bb149`, 재게이트 드라이버 212/212·무경고 0/0·proxy 7/7(레인 직접). N5는 GPS 경로만 닫혔다(AI 경로 3초 대기·이중 호출 잔여는 N6·N1 기록 — 후속 카드 후보) |
| t13 | 수정 경로 조용한 실패(C4) — `Store.updateActivity`의 인라인 `try? createEvent` 재등록을 **업로드 큐 경유로**(pending/failed 신호·성공 gid는 큐가 단일 출처 — updateEvent·updateRecurringSeries와 같은 문턱) + code-safety 권고(sync 2-5 성공 시 pending 미해제 "올리는 중" 영구 좌초 — `Store.swift:1468-1470`) + **1차 sync 판정 D2·D3 수리**: 재등록 autoAdd 무관(운영자 결정 a — 형제 정책을 활동에 그대로 옮긴 게 회귀였다)·gid 비교-후-소거·sync 2-2·이벤트 가져오기 게이트가 실시간 묘비까지(활동 `:1433`·이벤트 `:1396`) | 없음(원인 확정 — plan 생략; 근거: day-close-20260924 §6 row 7·§7·t13 sync-verdict §2①) | **sync FAIL(D1·D2·D3) 수리 완료 — 병합 대기(2026-09-25).** 코드 `3b42e45` + 수리 `258b49b`. 게이트는 수리 트리 기준 이 레인 3차 재실측: 드라이버 **212/212·exit 0·불변식 9/9·실데이터 바이트 대조 통과** · iOS·macOS 신선 DerivedData 빌드 swift 경고 0/0(42/38 위상) · proxy 7/7(1·2차는 판정문이 격리 사본에서 독립 재실측 통과). code-safety 재판정 **PASS-able** — 처방 충실·차단 0("모든 인터리빙에서 사전보다 나쁜 경우 없음"); 1차 보고의 "신규 결함 0"은 **정정**(D2=이번 커밋이 들인 활동 경로 회귀, D3=옛 경로 확대 — 수용 근거 '한 틱 폭'은 스냅샷 전제 오류). 잔여 비차단 4건·후속 카드 후보(2-1 경합 축소분·형제 정책 분기·주석 뉘앙스·X1·X2는 판정 §4) progress §5·§6. 문서: CHECKLIST 맨몸 꼬리 12건(판정 §2③) 포함 좌표 36건 `258b49b` 기준 재사상·결함 4번 처리됨 표기·후속 20② 출처 정정(t7 `83bf259` — 당시 옳은 좌표)·progress §5 정정 3건+로그아웃 갭 추가+§6 수리 절·커밋 구분(코드→문서) |
| t23 | 캘린더 sync 데이터 보호(C14 — X1·X2 긴급) — X1: `fetchBesirItems`가 토큰 실패·HTTP 비200·본문 해석 실패를 빈 결과로 삼켜 sync 1단계가 gid 있는 이동 일정 전부 삭제·알림 취소·묘비 정리(오프라인 콜드스타트·401·403·5xx 동일 경로 — t13 판정 §4 X1)를, 실패 전부 **throw** + 정상 빈(200+items 부재) 유지로 막음(GoogleCalendarService.swift:106-128; Store.swift:1365-1367 주석만 — 가드 `:1368`는 원래 throw에 조기 복귀하던 모양이라 무변경, 조기 복귀 시 이벤트·활동·알림·묘비 무손상을 code-safety가 sync 전체 판독으로 확인). X2: `nextPageToken` 순회 `collectPages`(GoogleCalendarService.swift:135-144 — 클로저 주입 구조라 드라이버가 통신 없이 검증; 26주 평일+왕복 260 → 2페이지) | 없음(원인 코드 읽기로 확정 — plan 생략; 근거: 카드 본문·t13 sync-verdict §4) | **완료 — 병합 대기(2026-09-25).** 게이트 이 레인 재실측: 드라이버 **217/217·exit 0·실데이터 바이트 대조 통과**(212+X2절 5단언) · proxy 7/7 · iOS 42위상·macOS 38위상 무경고. code-safety 4렌즈 **차단 0·비차단 4**(사전 존재 2·현실성 낮음 2 — 후속 후보: items 캐스트 구분 한 줄·페이지 상한) — 병합 가능 판정. 코드 `64eabc3`. 시뮬레이터 확인 절차는 progress §5(운영자 몫 — X1 오프라인 보존·빈 캘린더 반대 계약·X2는 드라이버가 대리 검증). |

**t1이 AI 카드까지 전환하는 이유**: 추출한 컴포넌트를 아무도 쓰지 않으면 옳게 추출됐는지 알
방법이 없다. 추출 원본인 AI 카드가 그것을 쓰고도 동작이 그대로인 것이 정확성의 유일한 증거다.
네 화면을 함께 옮기면 "추출이 틀렸다"와 "전환이 틀렸다"가 한 덩어리로 도착해 가를 수 없다.

**Phase 1.6에 넣지 않은 이유**(2026-09-16 판단, 그대로 유효): 카드의 바탕(D)이 아직 기기에서
검증되지 않았고, 깨진 바탕 위에 얹으면 바탕을 고칠 때 얹은 것까지 전부 다시 테스트해야 한다.

SPEC를 쓰고 ui-design + swift-impl을 붙여 진행한다.

**t1에서 실측된 제약 2건**(`291db49`, `SPEC-UIKIT-001` plan.md §2에 상세):
- `AskField`가 `AIAssistant`의 `private static` 셋(`parseDatetime`·`when`·`isoFormatter`)에 기대고
  있어, 중첩을 벗어나면 그 참조가 끊긴다. 해석이 두 곳에 생기지 않게 옮기는 것이 판정 기준이다.
- 가드 드라이버가 `AskField`/`PendingAsk`를 20곳에서 쓰고, 드라이버 컴파일 집합에는 `import
  SwiftUI`가 한 건도 없다. 그래서 꺼낸 **모델 파일은 SwiftUI를 몰라야** 하고, 모델과 뷰는 반드시
  다른 파일이다. CLAUDE.md의 드라이버 `swiftc` 인자 목록도 함께 갱신해야 한다.

**t3가 남긴 후속 항목 13건** (2026-09-22 sync). 둘로 나뉜다 — run이 인계한 11건
(`SPEC-UIKIT-003` progress.md §E.2 M5 말미)과 sync의 `--deep` 렌즈가 새로 올린 3건(11~13)이다.
REQ-041이 "전환 중 눈에 띈 개선은 코드가 아니라 루트 `plan.md`의 후속 항목으로"라고 정했기
때문에 여기로 온다 — 카드 안에서 고쳤다면 4파일 경계와 한 Day 3~4파일 제한이 함께 무너진다.

run 인계 11건 중 하나(§Phase 1.7 t3 행 갱신)는 이 sync에서 처리했고, 2번과 8번은 렌즈 실측으로
**범위가 넓어졌다**(2번은 26줄 → 81줄, 8번은 즐겨찾기 경계 → 이름-키 부류 전체). 카드 안에서
닫은 것은 여기 없다 — MAJOR-A(이름-키 좌표 충돌)와 MINOR-C(틀린 주석)는 t3가 직접 고쳤다.

*공유 컴포넌트를 열어야 하는 것* — 고치면 AI 카드·`AddEventView`·활동 두 화면이 함께 바뀐다:

1. `PlaceSearchDebouncer`에 최소 글자수 게이트가 없다(F-6(ii)) — 한 글자에도 카카오를 부른다.
   외부 한도로 이미 데인 프로젝트라 상수 하나가 곧 비용 방어다.
2. `AddActivityView` ↔ `ActivityDetailView`에 **바이트 동일한 코드가 123줄** 있다.
   run 단계는 이것을 `chooseTimePlain` 26줄 하나로 기록했으나(MINOR-3), sync에서 두 번 반증됐다.
   `--deep` 렌즈가 이름 붙은 함수 블록을 세어 **8블록 87줄**을 냈고, sync 종결 트리에서 리드가
   **바이트 동일한 최대 연속 구간**으로 다시 재어 **7구간 123줄**을 얻었다(4줄 이상, 괄호·빈 줄만인
   구간 제외). 두 값이 다른 것은 세는 단위가 달라서다 — 리드 쪽은 인접 함수가 한 구간으로 합쳐지고
   (`searchPlaces`+`finishPlaceSearch` 31줄, `setLookup`+`field`/`chosenIn`/`confirmedPlace`+
   `choosePlace` 27줄), 렌즈가 세지 않은 `.task { bootstrap() }` 10줄과 `actions` 10줄도 들어온다.
   **세는 방법을 적지 않은 수치는 다시 재도 같은 값이 안 나온다** — 위 두 값은 방법과 함께 적었다.
   재현 명령: `difflib.SequenceMatcher`로 두 파일의 `get_matching_blocks()` 중 4줄 이상.
   MAJOR-A·MINOR-C 수정이 중복을 늘렸다(주석 정정 +4, `confirmedPlace` fail-closed 주석 +5 —
   양쪽 동일). **로직 중복은 안 늘었다** — 새 기계장치(`forgetPlaces`·`reseed`·기억 헬퍼 둘)는
   `AddActivityView`에만 산다. 통합은 5번째 파일이 필요해 카드 밖이고 D-2 A안과 함께 본다.
   본보기에 없던 새 계산이라 계약 5가 새로 노출된 자리다. 단일 출처화는 5번째 파일을 열어야
   해 이 카드 밖이고 D-2 A안과 함께 검토하는데, **규모가 3배라 우선순위 판단이 달라진다.**
   깨지는 시점은 지금이 아니라 다음 수정 때다 — 한쪽만 고치면 두 화면의 해석이 갈라지고
   그 갈라짐을 알려줄 빌드도 드라이버도 없다(렌더링과 히트테스트가 갈라졌던 그 모양).

*`PlaceField`·`ConflictBanner` 잔여* — REQ-042가 "거처는 그대로 두고 색만"으로 경계를 그어 남은 것:

3. `PlaceField` cornerRadius 8 → `Theme.radius`(:501 계열).
4. `PlaceField` 돋보기 버튼에 접근성 라벨이 없다(:518) — VoiceOver에 이름 없는 버튼으로 읽힌다.
5. `ConflictBanner` 잔여 계약 6 위반과 radius(`AddEventView`:627·:630 — 처음 적은 `:601·:604`는 t3 트리 `d5203cb`의 좌표였는데, t6 `02481c6`이 파일을 26줄 민 뒤 옮기지 않아 `store.addEvent(…)` 호출을 가리키고 있었다. 2026-09-24 t7 sync가 두 줄을 `cmp`로 대조해 옮겼다).

*"그대로" 계약 때문에 이번에 일부러 안 고친 것*:

6. `ActivityDetailView` 삭제 단추 정렬이 `EventDetailView` 문법과 어긋난다. AC-007의 36절
   "그대로" 계약을 지키려 현행 유지했다 — 보존 대조 중에 형태를 바꾸면 무엇을 보존했는지
   말할 수 없게 된다.
7. 고른 장소의 주소 상시 표시(후시 선언 (g), 2026-09-22 운영자 승인). 확정 칩은 공유 문법이라
   화면 하나만 주소를 붙이면 문법이 둘이 된다 — 되살린다면 화면이 아니라 컴포넌트에서다.
8. **장소 좌표를 이름으로 키잉하는 부류가 두 화면에 남아 있다.** 원래 MINOR-2("bootstrap이
   저장 좌표로 즐겨찾기를 덮는다")로 좁게 적혀 있던 항목인데, sync의 `--deep` 렌즈가 더 위험한
   갈래를 찾아 범위를 넓힌다 — 한 화면의 **장소 줄 여럿이 같은 이름-키 사전을 공유**해, 같은
   상호의 다른 지점을 두 줄에 고르면 나중 쓰기가 앞 좌표를 덮고 두 줄이 같은 좌표를 되읽는다.
   t3가 `AddActivityView`(줄 3)·`ActivityDetailView`(줄 1)를 줄 신원 키로 바꿔 닫았고,
   **`AddEventView`(줄 2, 카드 t2가 독립 바인딩을 버린 자리)와 `AIAssistant`(줄 5, 원래 형태)는
   아직 이름-키다.** 통일이 화면마다 좌표 안전성을 하나씩 버려온 계통적 회귀이므로 남은 둘을
   한 카드로 묶는다 — **운영자 승인으로 카드 t6에 등록됐다**(2026-09-22, t3 병합 후 · t5 앞).
   t3의 줄 신원 키 수정이 본보기다. 다만 t6는 화면마다 같은 4줄이 아니다 — t3에서 실측된 대로
   줄이 배열에서 들고 나는 화면은 재생성된 줄에 좌표를 다시 걸어야 한다(아래 주의).
   **닫혔다 — t6 (`SPEC-UIKIT-005`, 2026-09-23 sync 종결).** `AddEventView`는 t3 본보기 그대로 줄 신원 키로 갔고, `AIAssistant`는 카드가 사라져도 살아남는 사전이라 줄 신원이 없어 B안(이름 → 이름·주소 → 이름·좌표 순의 결정적 단사 열쇠)으로 갔다. 이름-키가 좌표를 덮어쓰던 계통 회귀 넷은 이로써 닫혔다 — 다만 `AIAssistant` 쪽에는 **잔여가 하나 남는다**(sync 렌즈 F3): `resolveOrigin`은 즐겨찾기(`:2350`)를 확정 장소(`:2359`)보다 **먼저** 보므로(의도된 우선순위 — 주석 `:2356-2358`), 즐겨찾기 라벨과 같은 이름을 카드에서 고르면 열쇠 ①(이름 그대로)인 첫 줄은 여전히 즐겨찾기 좌표로 풀린다. 변경 전에는 두 줄이 **모두** 그렇게 무너져 이동 0분이 됐으니 엄밀히 개선이고 0분 결함은 진짜로 닫혔지만, "전부"는 한 칸 과한 말이다. 다만 재키잉이 직접입력 경로의 실패 방향을 바꿔 **후속 14번이 격상됐다**(기본 흐름에서 오저장까지 간다 — Day 닫기·실기기 확인 전에 처리).

*접근성·문구*:

9. "주변" 섹션 헤더에 `.isHeader` 특성 — `Form`을 버리며 잃은 랜드마크 낭독을 부분 회복한다
   (AC-008 상실 선언의 후속).
10. 토글 문구 "맞춰 도착"과 여유 분(分)의 긴장 — 문구를 정리할 때 함께 본다.

*sync `--deep` 렌즈가 새로 올린 것* (2026-09-22):

11. `EditCard.chooseTimePlain`의 기본값이 **소리 없는 `false`**다(`:263` `{ _, _ in false }`).
    지금은 무해하다 — `anchored: false` 생성은 정확히 넷(`ActivityDetailView:158`·`:160` ·
    `AddActivityView:139`·`:141`)이고 두 화면 다 배선한다(`:128`·`:113`). 잔여 위험은 앞날에
    있다: 누가 `anchored: false` 줄을 더하며 배선을 빼면 **컴파일이 통과하고 확인 버튼이 무신호로
    죽는다.** 드라이버는 뷰를 보지 않는다. `EditCardView:234-236` 주석이 정확히 그 실패를
    경고해 두고 기본값이 그 문을 열어 둔 형국이라, D-2와 묶어 기본값 제거를 판단한다.
12. `ActivityDetailView:339`의 `.onChange(of: nearbyCategory) { Task { await loadNearby() } }`가
    **취소도 태깅도 하지 않는다** — 종류를 빠르게 두 번 바꾸면 먼저 쏜 요청이 나중에 도착해
    화면의 종류와 다른 목록이 남는다(`loadNearby:386-392`가 `nearby`를 무조건 덮는다).
    **t3의 것이 아니다** — 이 diff는 그 기계장치를 한 줄도 건드리지 않았고 `nearbySection`
    호출부가 `Form Section` → `VStack`으로 옮겨간 두 줄이 전부다(확인: diff에 `nearbyCategory`·
    `loadNearby` 등장 0건). 카카오 할당량도 함께 태우므로 후속 값은 된다.
    **닫혔다 — t12(card C3, 커밋 `7532f10`, 2026-09-24).** 취소-교체 패턴 하나로 닫았다 —
    `nearbyTask` 태깅에 발화 두 곳(버튼·종류 전환)을 `startNearby()` 한길로 통과시키고 `await`
    뒤 `!Task.isCancelled` 가드가 늦은 옛 결과의 `nearby` 쓰기를 막는다. sync 수리(커밋
    `01bb149`)에서 가드를 스피너 해제보다 앞으로 옮기고(N2) 장소 변경 시 `choose()`가 조회를
    취소한다(N3) — 장소를 바꾼 뒤 옛 장소 조회가 착지해 막 비운 목록을 다시 채우던 경로도
    같은 커밋에서 닫혔다. 위 좌표는 그날 기록이라 그대로 둔다.
13. `ActivityDetailView`의 저장 게이트가 `.disabled(title.trimmed.isEmpty)`에서
    `.disabled(!(card?.isReady ?? false))`로 바뀌며 **약해졌다** — `isReady`는 `chosen != nil`만
    보므로(`EditCard.swift:240`) 저장된 제목이 빈 문자열이면 통과한다. 옛 게이트는 막았다.
    렌즈는 도달 불가로 봤다(`accepts()`가 빈 입력을 거절하고 `AddActivityView`도 제목 `chosen`을
    요구한다). **게이트 약화는 확정, 도달 불가는 추정** — AI 활동 생성 경로(`executeCreateActivity`
    계열)는 읽지 않았으므로 그쪽을 확인할 때 함께 판정한다. **닫힘(2026-09-24, t9 Day 닫기)** —
    code-safety가 그 AI 경로를 읽어 도달 불가를 확인했다(`executeCreateActivity`가 빈 제목을
    거부, 세 생성 경로 전부). 게이트 약화는 사실이지만 현재 어떤 경로로도 빈 제목이 저장에
    닿지 못한다 — 코드 변경 없이 노트로 종결한다.

14. **직접입력(submitCustom)이 장소 줄의 옛 좌표를 지우지 않는다 — 현재 UI에서는 도달 불가한 잠재 결함(강등).** 장소 줄은 `allowsCustom: true`라 `submitCustom`이 `chosen`만 바꾸는데, 좌표 사전 재키잉(t3·t6)이 이 경로의 실패 방향을 바꿨다. t6 M2(swift-impl)가 발견, M4 code-safety가 회귀 방향을 정밀화(2026-09-22): (i) 위치 권한을 켠 새 일정은 `prefillOrigin`이 출발지 줄에 현재 위치 좌표를 심는다 — 여기에 "회사"를 직접입력하면 현재 위치가 "회사"란 이름으로 조용히 저장된다(**기본 흐름 도달**, 예외 경로가 아니다). (ii) 즐겨찾기 라벨을 타이핑하면 재키잉 이전엔 이름-키 읽기가 즐겨찾기 좌표로 정확히 풀렸는데 이제 옛 줄 좌표가 이긴다(정확→부정확). (iii) 모르는 이름은 이전엔 조용한 무동작(안전), 이제 조용한 오저장(오염). 쌍둥이가 `AddActivityView:423-429`에 있다(t6 REQ-021이 그 파일을 금지해 카드 밖 판정 확정 — 한 화면만 고치면 계약 5 위반 모양, AC-003 (1) 계수 신호 재작성도 선행돼야 한다). **2026-09-23 sync 게이트 `--deep` 렌즈가 (i)(ii)(iii)의 전제를 반증했다 — 강등.** 장소 줄에는 자유 텍스트 확정 경로가 **없다**: `EditCardView:310`이 `if field.kind == .place { placeSearchEditor(field) } else { textCustomEditor(field) }`로 갈라 두고, `submitCustom`을 부르는 자리는 `textCustomEditor` 안의 둘(`:383` `.onSubmit` · `:384` 확인 버튼)뿐이다(`grep -n "onSubmit\|actions.submitCustom\|submitCustom(" Shared/EditCardView.swift` → `383·384·435·436`이 전부). `placeSearchEditor`(`:318-346`)에는 확인 버튼도 `.onSubmit`도 없고, 그 자리 주석(`:313-316`)이 "자유 텍스트를 그대로 확정하는 버튼을 두지 않는다 — 결함 P의 증상 그 자체"라고 이유를 적어 뒀다. 따라서 (i)의 시나리오는 UI에서 실행할 수 없고 (ii)(iii)도 같은 전제 위에서 함께 무너진다. **덧붙여 (i)의 결과 서술도 틀렸다** — `AddEventView.save()`(`:573-574`·`:601`)는 `chosen`이 아니라 `Place` 구조체를 넘기고 `Models.swift:158-159`의 `origin`/`destination`이 `Place`이므로, 설령 도달하더라도 "현재 위치가 '회사'란 이름으로 저장"되지 않는다(역지오코딩된 원래 지명이 저장된다). **처리 시점: `EditCardView`가 장소 줄에 확정 버튼을 되살릴 때 함께** — Day 닫기 전 처리 항목이 아니다. run 레인의 격상은 호출 사슬을 끝까지 재지 않은 채 내려진 판정이었다. 수리 모양(되살아날 때를 위해 남긴다): `submitCustom`에서 `choose`의 쓰기 줄을 미러링 — `if c.fields[i].kind == .place { confirmedPlaces[field] = favoritePlaces[value] }`(직접입력엔 검색 후보가 없어 place 항 없음). 수리할 때 `AddEventView:300`↔`AddActivityView:179` 쓰기 줄 lockstep과 `%.4f`↔50m 짝 판정 주석도 함께 못박는다.
15. **장소 확정 칩이 감기지 않는다 — B안 구분 문자열이 길이 문제를 다시 연다.** t6 M4 ui-design 렌즈의 정적 실측(2026-09-22): 시각 줄 확정 칩은 `.lineLimit(nil).fixedSize(horizontal: false, vertical: true)`로 감기게 돼 있는데(`EditCardView:206-208`) 장소 줄 확정 칩에는 같은 처리가 없고 ChipFlow가 칩을 이상적 폭으로 재니 긴 문자열이 오른쪽으로 넘친다 — 기본 크기에서도, 최대 텍스트에서는 확정적으로. t6 B안의 구분 문자열("이름 · 주소")이 정확히 이 길이대다. 수정은 `EditCardView.swift`라 t6 카드 밖(REQ-021) — 시각 줄과 같은 modifier를 장소 확정 칩에. 시뮬레이터 AC-009 (14)에서 실측 확인 뒤 우선순위 확정.
16. **기존 Theme 위반 2자리(t6가 만든 것 아님 — M4 ui-design 부기).** `AIChatView:114`의 `.foregroundStyle(.white)`/`.primary`(계약 6 — Theme.bg·Theme.ink가 정답), `AddActivityView:575`의 `cornerRadius: 8`(Theme.radius). t6 diff는 문자열 로직만이라 무관(추가 줄 색·폰트 grep 0건 확인). 후속 3~5의 PlaceField·ConflictBanner 정리와 한묶음으로 본다.
17. **일정을 편집으로 열면 저장돼 있던 출발지가 현재 위치로 조용히 바뀐다(t6가 만든 것 아님 — 2026-09-23 sync 게이트 `--deep` 렌즈 F2, sync 레인이 경로를 전수 재확인).** `buildCard`가 `origin_query` 줄을 만들 때 **`chosen:`을 주지 않는다**(`AddEventView:165-166` — 목적지 줄 `:167-169`에는 `chosen: editing?.destination.name`이 있다). 그래서 편집 씨앗이 심은 좌표(`:178`)를 `confirmedPlace(_:)`가 되읽지 못하고(`:538`이 `chosen == nil`이면 nil을 돌려주는 fail-closed), 연쇄가 이렇게 흐른다: `bootstrap:149` `recomputeEstimates`가 가드(`:465`)에 걸려 **이동시간을 아예 계산하지 않고** → `bootstrap:151` `prefillOrigin`의 가드(`:424` `confirmedPlace == nil`)가 통과해 위치를 요청하고 → `confirmCurrentLocationAsOrigin`의 가드(`:441` `chosen == nil`)도 통과해 `:447`이 **현재 위치로 덮어쓰고** `:449`가 `chosen`을 `hereMarker`로 세운다. 위치 권한이 없으면 대신 출발지 줄이 빈 채 남고 `isReady`(`EditCard:240`)가 저장을 잠가 사용자가 출발지를 다시 고르게 만든다 — 어느 쪽이든 원래 출발지는 복원되지 않는다. **t6 이전에도 같았다**(`c5396b3`의 `:158-159`에도 `chosen:`이 없고 옛 `confirmedPlace`(`:511-513`)도 `chosen`이 nil이면 nil을 돌려줬다) — 그래서 t6가 카드 안에서 고치지 않고 여기로 넘긴다. 수리 모양: `:165-166`에 `chosen: editing?.origin?.name`을 더한다(목적지 줄이 이미 그 모양이다). **그 한 줄이 셋을 함께 갚는다** — 편집 결함, t6가 새로 쓴 `:178`의 **읽힐 수 없는 죽은 쓰기**, 그리고 `:531-536` 주석의 "지금은 쓰기 자리들이 이름과 좌표를 늘 함께 적어 도달 불가"라는 단언(그 반례가 바로 같은 커밋의 `:178`이다). **동작이 바뀌는 수리라 시뮬레이터 증거가 붙어야 한다** — 그래서 sync 종결 시점에 눈감고 고치지 않았다. `AddActivityView`·`ActivityDetailView`에 같은 모양이 있는지는 **확인하지 않았다**(카드 밖). **닫혔다 — t7 (`SPEC-UIKIT-007`, 2026-09-24 sync 종결).** 수리 커밋은 `b73013b`다. `:166`에 위 수리 모양 그대로 `chosen: editing?.origin?.name` 한 줄을 더했고, `:534-536`의 주석을 다시 썼다. 파일이 645줄 그대로라 이 항목의 좌표는 옮기지 않았다. 서로 다른 인용 끝점 15개를 `73ceb43`과 바이트 대조하니 13개가 같았고, 다른 둘(`:166`·`:536`)은 수리 자체다. `c5396b3`의 좌표(`:158-159`·`:511-513`)는 그날의 기록이라 대조하지 않았다. 그러니 위 본문은 **수정 전 트리의 내용**이다. 같은 줄번호에 지금은 수리가 있다(`:166`에 `chosen:`, `:531-536`에 "출발지 줄의 nil 읽기는 프리필을 여는 신호" 주석). **결함은 t6 이전이 아니라 t2 `1b98e14`(2026-09-20, `SPEC-UIKIT-002` M4)에서 들어왔다**. 카드 전환 전 `d3c9327`은 출발지를 지켰으므로 "t6가 만든 것 아님"은 참이지만 Phase 1.7 안의 회귀다. 동작 증거는 2026-09-23 운영자의 시뮬레이터 한 자리에서 나왔다. 수정 전 빌드에서 **(가) 재현**(저장된 출발지가 현재 위치 칩으로 바뀜), 수정 빌드에서 1~8단계 통과(권한 "안 함"에서도 출발지 유지·저장 켜짐, 새 일정 프리필과 "현재 위치" 칩 직접 탭은 그대로). 수치(이동시간·출발 시각)는 기록되지 않아 판정만 남았다(`SPEC-UIKIT-007` progress.md §E.2 M3c). 위의 "확인하지 않았다"도 plan에서 닫혔다. `AddActivityView`에는 편집 모드가 없고(`grep -c 'editing' Shared/AddActivityView.swift` = 0), `ActivityDetailView`는 `chosen:`과 좌표를 함께 심는다(`SPEC-UIKIT-007` spec §1.4). 남은 것은 실기기 확인 셋(편집 뒤 출발 알림 실제 수신 · 구글 캘린더 항목 · macOS 편집 시트 — Day 닫기 이월)과 카드 밖 O-1(`Store.modifyEvent`의 nil 출발지 → 목적지 대체, 코드 읽기 가설 — Day 닫기 이월)이다. **t9 판정(2026-09-24): 카드화 추천.** 대체식 `newOrigin ?? current.origin ?? current.destination`(`Store.swift:358`)과 도달 사슬(출발지 없는 일정의 존재·`update_schedule`의 시각만 고치는 호출이 정상 기능 D4)을 코드로 확인했고, 이 경로엔 `isSamePlace` 가드가 없다(`AIAssistant.swift:1650` 주석 — create_schedule 전용). 시각만 고치는 편집이 사용자가 고른 적 없는 출발지를 조용히 심는 구조라, 수리 방향(origin 폴백 제거·가드 확장 여부)은 카드에서 정한다.
18. **t6가 남긴 주석 2건이 범위를 과하게 적는다(문구만, 동작 무관 — sync 렌즈 F4·F5).** ① `AIAssistant:756`의 "칩 글자가 구분 문자열로 길어지는 것이 이 변경의 유일한 보임새 변화다" — 표면은 둘이다. `EditCard:171-174`의 `chosenLabel`이 `.place`에 원값을 그대로 돌려주고(`:181`) `AIAssistant:905-907`의 `resolvePendingAsk`가 그 값으로 **확인 직후 사용자 말풍선**을 만들어, 구분 문자열이 채팅 기록에도 찍힌다. spec HISTORY 0.1.3이 이미 세 표면(칩·거품 줄·재탭 씨앗)으로 정정했으므로 **코드 주석만 스펙과 어긋나 있다**. 반대로 클래스 주석(`:45-46`)의 "저장 데이터로는 새지 않는다"는 참이다 — 사전 값은 언제나 원래 `Place`이고 실행부 요약은 해석된 `Place.name`을 쓴다(`:1399`·`:1700`·`:2245`). ② `confirmedPlaces`의 증가 차원이 "서로 다른 이름 수"에서 "대화 중 탭한 서로 다른 지점 수"로 바뀌었는데 천장을 명시하지 않았다(`:52` 선언·`:761-763` 쓰기·`:220` `resetConversation`이 비움). 한도 위반은 아니다 — 순회·직렬화 경로가 없고 같은 지점 재선택은 `isSamePlace`(`:783`)로 열쇠를 늘리지 않는다. 한 줄 주석이면 갚아진다.
19. **t7의 편집 씨앗이 새로 깨운 것 셋(결함 아님 — 2026-09-24 t7 sync 게이트 `--deep` 렌즈 O1~O3, 코드 읽기·미관측).** ① **값이 정해진 줄의 스피너.** 저장된 출발지가 있는 편집 시트에서도 앱 시작 측위가 진행 중이면 출발지 줄에 "진행 중" 스피너가 돈다. 스피너를 모는 것은 프리필이 아니라 `location.isLocating`이다(`AddEventView:93` → `EditCardView:91-95`). 수리 전에는 프리필이 실제로 그 위치를 기다렸으니 참인 표시였고, 이제는 아무도 그 줄에서 일하지 않는다. 캐시된 위치 없는 냉시작 직후에만 보이고 값은 덮이지 않는다. 고친다면 편집 씨앗이 있을 때는 `setBusy`를 걸지 않는 쪽이다. ② **권한 거부 + "현재 위치" 칩 탭.** `:276`이 씨앗 좌표를 지우고 `:297`이 `chosen`을 비운 뒤, `:416-417`의 프리필이 빈손으로 끝난다. 저장돼 있던 출발지가 줄에서 사라지고 저장이 잠기며, 이 시트에는 안내가 없다(`grep -c lastError Shared/AddEventView.swift` = 0). 사용자의 탭이라 REQ-002 위반은 아니고, 취소하고 다시 열면 돌아온다. ③ **주석 범위.** `:535-536`의 "출발지 줄의 nil 읽기는 … 프리필을 여는 신호다"는 전칭으로 읽으면 한 칸 과하다. nil 읽기는 넷(`:424`·`:465`·`:542`·`:573`)이고 프리필을 여는 것은 `:424` 하나다. "`prefillOrigin`의 가드(`:424`)에서는"으로 좁히면 갚아진다. 후속 18과 같은 부류(주석이 범위를 과하게 적음)라 한묶음으로 본다. ①②는 Day 닫기 `ux-check`의 편집 시트 항목과 함께 본다. **닫혔다 — t11(card C2, 커밋 `f0c18da`, 2026-09-24).** ① `syncOriginBusy()` 단일 규칙(스피너는 줄이 비어 있고 위치를 기다릴 때만 — 빌드 시드도 `editing?.origin == nil` 게이트), ② 권한 거부 안내 note를 syncFieldExtras 한 곳에서 조립 + prefillOrigin 조기 반환(5초 죽은 대기도 제거), ③ 가드 한 곳으로 좁힘 — 전부 같은 커밋. 표시 변화라 시뮬레이터 확인 목록으로 넘긴다.
20. **`AddEventView`에 원래 있던 것 넷(t7이 만든 것 아님 — 같은 렌즈 O4~O7, 코드 읽기).** ① **`recomputeEstimates`의 `await` 경합**(`:464-474`). 좌표를 `await` 앞에서 잡고 뒤에서 `estimates`·`estimating`을 무조건 쓴다. 계산 도중 칩을 바꾸면 늦게 끝난 쪽이 이겨 옛 출발지의 소요시간·충돌 배너가 남는다. 저장은 `Store.updateEvent`가 다시 계산하므로 표시만 틀린다. 수리 모양: `await` 뒤 `confirmedPlace(…)`를 다시 읽어 같을 때만 쓴다(`setLookup`의 재확인과 같은 규율). ② **저장 버튼이 `saving`을 보지 않는다**(`:119` `.disabled(!(card?.isReady ?? false))` ↔ 카드 안 `EditCardView:37` `canConfirm = card.isReady && !busy`). 제출 판정이 두 곳에 따로 있다. 두 번 탭하면 `updateEvent`가 둘 돌고, `Store.swift:945-992`이 `await` 앞 사본을 되써 `googleEventId`를 옛 값으로 덮을 수 있다(**중복 캘린더 항목 가설 — 재현 안 함**). 넷 가운데 가장 먼저 확인할 것이다. ③ 저장된 출발지 이름이 `""`이면 빈 글자 선택 칩이 된다 — 확인된 생성 경로는 없고, 코드는 nil만 막는다(`GoogleCalendarService.swift:211` 등. 가설·사소). ④ 편집 씨앗의 `gatedRows(…)` 인자 여섯이 `:179-182`와 `:201-204`에 글자 그대로 두 벌 있다(계약 5 모양). **넷의 배치 — ②는 t9에서 1줄 수리, ③은 t9에서 기각, ①·④는 t11(card C2, 커밋 `f0c18da`, 2026-09-24)에서 닫혔다.** ① `estimateFlights` 카운터가 `estimating` 소유권을 정리하고 `await` 뒤 `confirmedPlace` 재확인(setLookup 규율)이 옛 계산의 늦은 쓰기를 막는다. ④ `gatedRows(seeding:)` 과부하 한 개로 접힘. ②의 편집 모드 stale-gid 좁은 창은 t9 문서화 잔여 그대로(이 카드 밖).

## 7. 리스크 / 열린 질문

- **배달앱(요기요/배민) 공식 API — 종결(2026-09-24, Day 8)**: 양사 모두 개인 개발자 개방 없음 확인. 유니버설 링크로 앱/웹을 여는 방식으로 확정(§6 Day 8 조사 메모). 예상대로 스코프가 낮아졌다.
- **금융 API(토스 등)**: 마이데이터 사업자 등록 없이는 공식 연동 불가 가능성 높음 — be rich sir는 애초에 "수동 입력 + 분석"으로 스코프를 낮춤(Phase 3 설계에 반영됨).
- **OpenAI 사용 비용**: 작업당 약 6원(luna, 고정 5,804토큰 기준)까지만 실측됐고 **월 총액은 미실측**. be full/healthy/fun sir의 AI 추천 툴이 추가되면 호출량이 늘어나므로 Phase 5(Day 34)에서 실사용 기준으로 재점검하고 OpenAI 대시보드에 월 한도를 건다. 프록시는 `APP_TOKEN`만 있으면 누구나 부를 수 있어 **레이트리밋이 곧 비용 방어**다.
- **백엔드가 하나뿐이라 폴백이 없다(2026-09-13~)**: `OPENAI_KEY`가 빠지거나 `OPENAI_MODEL`("gpt-5.6-luna")이 폐지되면 `/ai/chat`이 그대로 끊긴다(키 없음은 503 `openai_key_missing`, 모델 폐지는 `openai_error`). AI 채팅이 안 될 때 **가장 먼저 확인할 지점**이고, 조치는 `proxy/src/index.js`의 `OPENAI_MODEL` 한 줄 교체다.
- **luna의 한국어 tool-calling 안정성**: 인자 누락이 재발하면 `gpt-5.6-terra`($2/$12)로 올린다 — 같은 상수 한 줄. 실행부 방어(`resolvedMode`/`resolveOrigin`/`isSamePlace` 50m 가드/`list_schedules` 자기교정)는 테스트로 불필요함을 확인하기 전까지 걷어내지 않는다.
- **1인 개발 기준**이므로 Day 38까지는 "매일 온전히 이 작업만 했을 때" 가정. 실제 캘린더 일수는 더 길어질 수 있음(실제로 Phase 0는 예상보다 훨씬 오래 걸렸고 계획에 없던 Phase 0.5까지 발생함) — **순서를 지키는 것이 날짜를 지키는 것보다 중요**하다. Phase당 코드 검사/실기기 테스트/안정화 3일이 추가되면서 전체 일수가 늘었지만, 이 3일은 건너뛰지 않는다 — 회귀를 놓치면 다음 Phase가 이전 Phase 위에 쌓이는 구조상 문제가 누적된다.
- ~~Claude 비전 지원 모델 확인~~, ~~ShareExtension URL scheme 핸드오프 불확실성~~ — 둘 다 해소됨(Workers AI 비전 지원 확인, App Group 파일 큐 방식으로 확정).
