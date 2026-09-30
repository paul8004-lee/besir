# t19 진행 기록 — C10 proxy 정리: `/claude/messages` 제거

- card: t19 (Class B — plan 스킵, 원인·범위는 Day-close 2026-09-24에서 확정됨)
- worktree: `.claude/worktrees/t19`, 브랜치 `WT-proxy-cleanup` (기준 291c3cf = origin/master, 분기 차이 `0 0`)
- 완료 신호: 브랜치명 + 본 파일 경로. 병합은 sync 검토 PASS 뒤 리드 지시로.

## 1. 원인·범위 근거 (Class B 요건 — 확정된 인과 증거)

- **day-close-20260924.md §6 19행(L104)**: "proxy `/claude/messages` 데드 라우트 → 카드 C10 — **앱 호출 0건(AIAssistant:961은 /ai/chat만)**"
- **§7 C10**: "proxy 정리: `/claude/messages` 제거."
- **CHECKLIST.md:543-544**(카드의 정식 범위 문구): "앱 호출 0건(앱의 프록시 호출은 `/ai/chat` 한 곳). **ANTHROPIC 시크릿·redactSecrets 항목도 제거와 함께.**"
- 변경 전 참조 전수(워크트리에서 관측, `grep -rn 'claude/messages'` 코드·문서 전체):
  `proxy/src/index.js:26`(:26 주석·:91 라우트), `Shared/Config.swift:48`(문서 주석 예시),
  `STATUS.md:33·41`(낡은 사업문서 — 범위 밖, 이월), `CHECKLIST.md:543`(추적 항목), `plan.md:105`(역사 나열).

## 2. 구현 내역 (ai-tooling 전문가 실행, diff 원문 레인이 직접 검수)

| 파일 | 변경 |
|---|---|
| `proxy/src/index.js` | 라우트 블록(주석 포함)·라우트 목록 주석 줄·`ANTHROPIC_MESSAGES` 상수·`proxyClaude()` 함수 전체·`redactSecrets()` 목록의 `"ANTHROPIC_KEY"`·시크릿 문서 주석 줄 제거. GEMINI_KEY 문단 뒤에 2행 제거 기록(2026-09-30, 앱 호출 0건, 부모 커밋 참고) 추가 — 기존 문단 어조·밀도에 맞춤 |
| `proxy/wrangler.toml` | `wrangler secret put ANTHROPIC_KEY` 주석 줄 제거 |
| `Shared/Config.swift` | :48 문서 주석 예시만 `/claude/messages` → `/ai/chat`. **코드 무변경** |
| `plan.md` | :105의 죽은 라우트 언급을 같은 줄 t5 취소선 관례로 처리: `~~…~~ → **2026-09-30 제거(t19)**` |
| `plan.md` | :27 "`ANTHROPIC_KEY`·`GEMINI_KEY` 시크릿은 여전히 남아 있으나" — §4 판정 발견 1이 낡은 서술로 지목 → **같은 커밋에서 수리**(코드 참조 완전 제거·배포 시 `wrangler secret delete` 안내로 갱신) |

## 3. 검증 (레인 직접 관측 — 전부 이 워크트리에서 재실행한 축자 출력)

**`cd proxy && npm test`** (node_modules 없어 `npm ci` 선행 — 전체 출력은 `.moai/reports/t19/npm-test-output.txt`):

```
  ✓ system은 instructions로 빠지고 input에는 안 들어간다
  ✓ call_id가 대화 전체에서 유일하고 호출↔결과가 순서대로 짝지어진다
  ✓ 텍스트+도구호출이 섞인 model 턴은 아이템 두 개로 쪼개지되 순서는 유지된다
  ✓ 첨부 이미지는 input_image, 본문은 input_text
  ✓ 도구 스키마는 평평하게 펴지고 type이 소문자가 된다
  ✓ 응답 역변환: reasoning 아이템은 버리고 나머지 순서는 유지
  ✓ 인자 JSON이 깨져도 던지지 않고 빈 인자로 넘긴다

7/7 통과
```
exit 0.

**제거 증명 grep** — `grep -rn 'claude/messages\|ANTHROPIC\|proxyClaude' proxy/ Shared/ Tools/ | grep -v node_modules` → **0건** (exit 1).

**Config.swift 구문 파싱** — `xcrun swiftc -parse Shared/Config.swift` → exit 0 (주석 전용 변경의 무결성 확인).

**`git diff --stat`**:

```
 Shared/Config.swift |  2 +-
 plan.md             |  2 +-
 proxy/src/index.js  | 33 +++------------------------------
 proxy/wrangler.toml |  1 -
 4 files changed, 5 insertions(+), 33 deletions(-)
```

> 정정(sync 판정): 위 stat은 plan.md:27 수리 전 값이다. 최종 커밋은 4파일 6/34(plan.md:27 수리 포함).

## 4. 판정 (code-safety)

**PASS** — `hns-besir-app-code-safety-specialist` 렌즈(2026-09-30). 렌즈 5개 전부 가동, 각각 관측 근거 확보.

- **H1 await 인덱스 무효화**: diff에 Swift 비동기 표면 없음(유일 Swift 변경 = `Config.swift:48` 주석 1줄) — `git diff` 전문으로 대상 없음 확인.
- **H2 조용히 묻히는 실패**: 제거된 `proxyClaude()`는 `missing_anthropic_key` 500을 명시적으로 반환하던 경로였고 호출자 0건·`try?` 추가 없음. `proxy/test/`에 해당 라우트 미러 테스트 부재(grep 0건) → 7/7 유지는 정합.
- **H3 외부 한도**: 무한 증가 상태·한도 대상 미접촉. 제거 자체가 공격·비용 표면 축소.
- **H4 복제 계산**: 이중화 없음. `passthrough()` 잔여 호출자 3곳(`index.js:285·308·326`) — 고아 아님.
- **간결성**: 제거 기록이 기존 GEMINI 양식(index.js 헤더 2행, plan.md t5 취소선)을 따름. `redactSecrets()`에서 `ANTHROPIC_KEY` 제거는 계약 #2의 역방향 정합 — 키를 읽는 경로가 0건이므로 목록 항목도 함께 죽는다.

**핵심 관측(전문가)**: 사멸 grep `claude/messages|ANTHROPIC|proxyClaude` on `proxy/·Shared/·Tools/·ShareExtension/` → **0건(exit 1)**. 잔여 `env.` 읽기는 `APP_TOKEN`·`OPENAI_KEY`·`KAKAO_REST_KEY`·`ODSAY_KEY`뿐 → `ANTHROPIC_KEY`를 에러 본문에 흘릴 경로 없음. 앱 POST 호출자는 `AIAssistant.swift:1376`의 `/ai/chat` 유일 → 런타임 동작 변화 없음. `swiftc -parse` exit 0.

**발견 1건 [낮음·문서] — 이 카드에서 즉시 수리**: `plan.md:27` "시크릿은 여전히 남아 있으나"가 이 제거 뒤 낡은 서술 → §2 마지막 행대로 같은 커밋에서 갱신(이월하지 않음). STATUS.md:33/41은 카드가 범위 밖으로 선언 — 미집계.

**잔여 위험**: ① 라이브 Worker에 `ANTHROPIC_KEY` 값이 운영자의 `wrangler secret delete` 전까지 상주(읽는 코드 경로 0개 — §6 이월 그대로). ② Worker 실제 반영은 `npx wrangler deploy` 전까지 없음.

**오케스트레이터 재관측(판정 전)**: `npm test` 7/7(exit 0)·사멸 grep 0건(exit 1)을 레인 기록과 별개로 직접 재실행해 이중 확인.

## 5. 미검증 (Gaps)

- **iOS·macOS 전체 빌드 미실행** — Swift 변경이 `Config.swift` 문서 주석 1행뿐이라 구문 파싱으로 충분하다고 판단. 빌드 무경고 주장은 하지 않는다.
- **가드 드라이버 미실행** — 같은 이유(주석 전용). 드라이버가 `Config.swift`를 컴파일에 포함하나 동작은 주석의 영향을 받지 않는다.
- **프록시 배포 미실행** — 카드 검증은 `npm test`까지만 선언. 라이브 Worker는 배포 전까지 옛 라우트를 계속 서빙한다(앱 호출 0건이므로 위험은 없음).

## 6. 이월 (카드 밖 — 리드/sync/운영자 몫)

- **배포 시**: `wrangler secret delete ANTHROPIC_KEY` 실행 후 `npx wrangler deploy` (운영자). 시크릿 삭제를 먼저 해도 이 코드에선 누구도 그 키를 읽지 않으므로 순서는 자유롭다.
- **STATUS.md:33·41** — 제거된 라우트를 살아있는 것처럼 서술. CLAUDE.md가 이미 "낡은 사업문서"로 선언한 파일이라 카드 범위에서 뺐다. 문서 갱신 시 참조.
- **CHECKLIST.md:543 항목 10** — 이 카드가 완료하려는 작업 자체. 항목 정리(완료 표시)는 sync/Day 닫기 몫.
