# t19 sync 판정 — `/claude/messages` 데드 라우트 제거

- card: t19 (Class B) · 커밋 9e74181 (WT-proxy-cleanup, 부모 291c3cf — 분기 차이 `0 1`)
- 렌즈: --ai-tooling --security · 판정자: sync 세션(리드가 지정한 범위 = 커밋 diff 전수)
- **판정: PASS** (코드·계약 범위). 낮음·문서 발견 1건은 리드 결정 사항으로 넘김(아래 F1).

## Claim → Evidence

| # | 주장 | 이 세션에서 직접 관측한 것 |
|---|---|---|
| 1 | 변경 범위가 4파일 +6/−34 | `git diff --numstat 291c3cf 9e74181` → Config.swift 1/1 · plan.md 2/2 · index.js 3/30 · wrangler.toml 0/1 (합 6/34) |
| 2 | index.js 추가 3줄은 기록 주석 2줄 + redact 목록 1줄뿐 | `git diff … -- proxy/src/index.js` 의 `+` 행 전수 열람: 주석 2줄, `for (const key of ["KAKAO_REST_KEY","ODSAY_KEY","OPENAI_KEY","APP_TOKEN"])` |
| 3 | proxy 테스트 회귀 없음 | `cd proxy && npm test` → `7/7 통과` (재실행, exit 0) |
| 4 | 코드 범위 잔여 참조 0건 | 워크트리 루트에서 `grep -rn 'claude/messages\|ANTHROPIC\|proxyClaude' Shared ShareExtension Tools proxy/src proxy/test proxy/wrangler.toml proxy/package.json project.yml` → 출력 없음 |
| 5 | 앱의 프록시 POST 호출자는 `/ai/chat` 하나 | `proxyPOSTRequest` 호출자 = `Shared/AIAssistant.swift:1376` (`"/ai/chat"`) 단 1곳. GET 호출은 `/kakao/*`·`/odsay/*`만 |
| 6 | redactSecrets 목록 = 실제 읽는 시크릿 (계약 #2) | `env.*` 읽기 전수: `APP_TOKEN`·`KAKAO_REST_KEY`·`ODSAY_KEY`·`OPENAI_KEY` (`env.AI`는 index.js:16 주석 1건). 목록 4개와 일치 — 빠진 키 없음 |
| 7 | `passthrough()` 고아 아님 | 호출자 3곳 (index.js:285·308·326) |
| 8 | 라우트 흐름 무결 | index.js:88-120 열람 — APP_TOKEN 검사가 라우트보다 앞, `/ai/chat` 분기 무변경. 제거된 경로에 POST가 오면 인증 통과 후 405(전엔 Anthropic으로 중계) |
| 9 | Config.swift는 주석 전용 | `xcrun swiftc -parse Shared/Config.swift` exit 0, 변경 1줄이 `///` 문서 주석 |

### ai-tooling 렌즈
`/ai/chat`·`toResponsesRequest`·`lowercaseSchemaTypes`·OPENAI 상수 미접촉(diff에 해당 행 없음). Gemini 와이어 포맷 계약(#1) 영향 0.

### security 렌즈
공격·과금 표면이 줄었다(인증 뒤의 임의 본문 중계 라우트 제거). 새 에러 경로·새 시크릿 없음. 남은 시크릿 4종은 모두 redact 대상.

## F1 [낮음·문서] 카드 증거의 "참조 전수"가 코드맵 3곳을 놓쳤다

추적 파일 `.moai/project/codemaps/`가 제거된 함수·라우트를 아직 싣는다:

- `entry-points.md:28` — `| POST /claude/messages | 레거시, 현재 미사용 |`
- `modules.md:51` — `| proxyClaude | 레거시, 현재 미사용 |`
- `dependencies.md:46` — `Legacy["/claude/messages → proxyClaude (미사용)"]` (다이어그램 노드)

진행 기록 §1은 "코드·문서 전체 grep"이라 적었지만 목록에 codemaps가 없고, §3 사멸 grep의 범위도 `proxy/ Shared/ Tools/`(+ShareExtension)라 이 3곳은 원리상 걸리지 않는다. "미사용"이라고 적혀 있어 동작을 거짓으로 말하진 않지만, 이제 없는 심볼을 가리킨다. 코드맵은 재생성 산출물이라 `/moai codemaps`로 갱신하거나 3줄 수동 수리가 가능하다.
→ **리드 결정**: t19 커밋에 3줄을 얹어 병합할지, 병합 후 codemaps 재생성 카드로 이월할지. 코드 판정에는 영향 없음.

## 알려진 문서 잔여(카드가 범위 밖 선언 — 재확인만)
`STATUS.md:33·41·42`(낡은 사업문서), `CHECKLIST.md:543-544`(이 카드의 추적 항목 — 완료 표시는 sync/Day 닫기 몫).

## Gaps (미검증)
- iOS·macOS 빌드·가드 드라이버 미실행(카드와 동일 사유 — Swift 변경은 주석 1줄; `swiftc -parse`만 관측). 빌드 무경고 주장 없음.
- 라이브 Worker 동작(배포·`wrangler secret delete`) 미관측 — 이 카드는 배포하지 않음.
- 진행 기록 §3 `git diff --stat`(plan.md 2 +−, 5/33)는 :27 수리 전 값으로 낡음. 실제 커밋은 4/6/34(위 #1). 기록 오차일 뿐 커밋 내용과 무관.

## Residual risk
① 배포 전까지 라이브 Worker가 옛 라우트를 계속 서빙하고 `ANTHROPIC_KEY` 값이 상주(읽는 코드는 0개) — 운영자: `wrangler secret delete ANTHROPIC_KEY` → `npx wrangler deploy`.
② 증거 디렉터리 `.moai/reports/t19/`는 워크트리에서 **미추적** 상태 — 워크트리를 병합 전에 치우면 증거가 사라진다(처분은 병합 후, 규칙대로).
