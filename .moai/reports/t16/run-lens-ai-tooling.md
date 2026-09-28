# SPEC-UIKIT-008 run 렌즈 — ai-tooling 계약 감사 (card t16)

- 대상 트리: worktree `t16`, branch `WT-place-resolution`, HEAD `dbdb5b9` (M6 직후 최종 트리)
- diff 기준: `aa7b792` (SPEC base) · `e1a40a6` (후보, run 출발점) · `c405ff5`~`dbdb5b9` (M1~M6)
- 관측자: ai-tooling 렌즈. **모든 수치는 이 세션이 직접 돌린 명령의 출력이다** — §E.2 전사 아님.
- 읽기 전용. 이 보고서가 유일한 쓰기다.

## 커버리지 표 — 헌장 항목 → 명령 → 관측

| # | 헌장 항목 | 돌린 명령 | 관측된 출력 | 판정 |
|---|---|---|---|---|
| 1a | 와이어 포맷 — 소문자 타입 금지 | `grep -c '"type": "[a-z]' Shared/AIAssistant.swift` | `0` | ✅ |
| 1b | 새 AI 클래스·ObservableObject 금지 | `git diff aa7b792 HEAD -- Shared/ \| grep '^+' \| grep -c 'class .*ObservableObject\|final class '` | `0` | ✅ |
| 1c | Shared/ 추가 파일 없음(xcodegen 불필요) | `git diff --name-only --diff-filter=A aa7b792 HEAD -- Shared/ \| wc -l` | `0` | ✅ |
| 2a | 선언 블록 무변경(후보 차분 분리) | `sed -n '/private func toolsJSON/,/^    }$/p'` 3판 대조 — aa7b792·e1a40a6·HEAD | aa7b792→HEAD **1줄**(`origin_query` description 값. 164줄 중). aa7b792→e1a40a6 = 그 1줄, **e1a40a6→HEAD = 빈 출력** | ✅ |
| 2b | 시스템 프롬프트 — M4·M6 무변경 | `sed -n '/private func systemPrompt/,/^    }$/p'` 3판 대조 | aa7b792→e1a40a6 **+1줄**(머무는 반복 규칙), e1a40a6→HEAD **빈 출력** | ✅ |
| 2c | '이동 없음' = 카드 전용 토큰 | `grep -n '이동 없음\|noTravelToken' Shared/AIAssistant.swift` | 16+10건 전부 선언 블록(:1360–1523) 밖 실행부·주석. `noTravelToken = "__no_travel__"`(`:2829`). 선언 키 집합은 2a의 바이트 동일성이 보장 | ✅ |
| 2d | 고정 토큰 비용 — +122이 후보 몇인지 | `cat .moai/state/verify/t16/token-pair.json` + 2a·2b 구조 검증 | base 3,824(1,704+2,120) → final 3,946(1,771+2,175), 증분 +122. system +67·tools +55 = 후보의 프롬프트 1줄·설명 1줄과 정확히 대응. M1~M6의 선언·프롬프트 잔차는 0이므로 +122 전체가 후보 귀속 | ✅ |
| 3a | `isSamePlace` 본문 동일성 | `sed -n '/private static func isSamePlace/,/^    }$/p'` 양판 `cmp` | 5줄, **IDENTICAL** | ✅ |
| 3b | `sanitizeModelArgs` 본문 동일성 | 같은 방법 | 15줄, **IDENTICAL** | ✅ |
| 3c | `executeListSchedules` 본문 동일성(총 건수 동작 포함) | 같은 방법 + 본문 내 `total` 검색 | 126줄, **IDENTICAL** — "다만 전체로은 N건 등록돼 있어요" 로직이 그대로 안에 있음 | ✅ |
| 3d | `resolveOrigin` 사다리 생존(M6 이후) | 본문 추출·호출처 grep | 선언 `(_ query: String?, orDefault: Bool)` — 기본값 제거(죽은 갈래). 유일 호출처 `:2601` `orDefault: true`. 사다리는 `resolveOriginAdoption`(`:2803`, `guard orDefault else …` → 즐겨찾기 '집' → 현재 위치)에 온존. 기본값(false) 호출처 `:1603`·`:1803`·`:2001` 생존. `adoptPlace` 순서(즐겨찾기 → 확정 장소 → 일반명사 가드 → 검색) base와 동일 | ✅ |
| 3e | M6 diff가 방어를 건드리지 않았는지 | `git diff a73b6c2 dbdb5b9 -- Shared/AIAssistant.swift Tools/GuardDriver.swift` | 변경 4종만 — `typealias UnclearPlaceList`·`statedLabels() +` 빈 앞항 제거(이유 주석)·`resolveOrigin` 기본값 제거(이유 주석)·드라이버 시그니처 별칭화. 방어 본문 무변경 | ✅ |
| 4a | 머무는 요청 이원 판정 = SPEC 수용안 | `stayingRecurrenceSignal`(`:792`)·`stayingOneShotActivity`(`:805`) vs `isSamePlace` 50m(`:1821`, `stayingOneShotActivity` 게이트) | 카드=문자열 같음·실행부=50m의 분리가 spec 0.1.1 D3 수용안 그대로. 기저 `stayingRecurrence`(토큰 못 봄)의 직접 호출처는 Signal 1곳뿐 — 분기 없음 | ✅ |
| 4b | 맥락 줄 단일 출처 | `filledValueLabels`(`:873`) 호출처 | 실행 전 카드(`:856`)와 후보 카드(`:931`)가 같은 함수(주석이 계약 5를 명시). `statedLabels` 잔여 호출처 1곳 | ✅ |
| 4c | 후보 키 기록 단일 메커니즘 | `parkForUnclearPlaces`(`:917` parked 빈 값) ↔ `resolvePendingAsk`(`:1186` 빈 값 판정) | 빈 문자열 자체가 기록이며 읽는 쪽도 같은 인자를 본다(D-3 (a)) — 별도 목록 없음 | ✅ |
| 4d | 튜플 반복 권고(AC-011 (6), 통과 조건 아님) | `grep -c '(key: String, query: String, candidates: \[Place\])'` 두 파일 | 후보 5자리 → **1**(별칭 정의 자체) + GuardDriver 0 | ✅(권고 충족) |
| 5a | 원장 산술 — 최종 관측 | CLAUDE.md 레시피로 HEAD 드라이버 직접 실행(`gate 아닌 이 렌즈 실행`) | exit 0 · **`296/296 통과`** · `[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다` · 샌드박스 자체 정리(`ls -d $TMPDIR/besir-gd-*` 없음) · 컴파일 경고 24줄 | ✅ |
| 5b | 원장 산술 — 앵커 관측 | 같은 레시피로 `aa7b792`·`e1a40a6` 드라이버 각각 실행 | aa7b792 **`217/217`** exit 0 · e1a40a6 **`241/241`** exit 0 — spec 0.1.0의 "base 217/217·head 241/241" 기록과 정확히 일치. T 앵커 241은 후보 트리(=run 출발점)임이 문서화돼 있음 | ✅ |
| 5c | 마일스톤 차분 — 이름 대조 | M1~M4 커밋쌍 diff에서 `drvCheck("` 줄 추출 | M1 **+38/−0**(AB-H01 9·H02 3·H03 2·H04 2·H05 1·H06 2·H07 3·H08 3·H09 1·H10 1·H11 11) · M2 **−2/+1**(AB-H03 두 줄 → `[경로 제거]` 한 줄, 이름 원문 일치) · M3 **−2/+3**(AA-1 강남·테헤란로 재작성, 이름 원문 일치) · M4 raw −3/+20줄을 장부 −2/+19로 계상(AC-012 (1)의 O-6 재작성 0/0 규약; 순변화 +17은 양쪽 같음) · M5 GuardDriver 무변경 · M6 단언 무변경. **241 + 61 − 6 = 296** 관측과 일치 | ✅ |
| 5d | 스팟체크 5종 | grep·diff | AA-4 첫 단언 소거(M4 diff `−`) ✅ · O-6 첫 단언 **재작성**(같은 자리 −1/+1, 이름·기대 교체 — 소거 아님) ✅ · `AB-H09 [수용]` 존재(`:2403`) ✅ · `AB-H03 [경로 제거]` 존재(`:2214`) ✅ · 강남 픽스처 주소 실림(AB-H04 `:2222`·`:2225` — 선릉로100길 1·삼성동 131 / AA-1 `:1840`~) ✅ | ✅ |
| 6a | D-5 전제 — `repairDanglingToolTurn()` 무조건 호출 | `submit()` 본문(`:288-320`) | `:297`에서 무조건 호출, 사용자 턴 `contents.append`(`:307`)보다 **선행**. 본문 base와 바이트 동일. 로드 시 `:169` 호출도 존속 | ✅ |
| 6b | runLoop park-return | `runLoop` 본문(`:436-448`) | 모델 턴 `:438` 무조건 append(루프 불변식 1) → `:446` `if bubbles.contains(where: { $0.ask != nil }) { return }` — 카드가 서면 턴 종료(D-5 (a)). `trimHistory()` 본문도 base와 바이트 동일(사용자 턴 경계 절단 불변) | ✅ |
| 6c | 프록시 무변경 | `git diff --quiet aa7b792 HEAD -- proxy/ project.yml` | exit 0 | ✅ |

## 발견 — 차단 0건 · 선택 4건

1. **[선택] AC-012 (1)의 `grep -c '✗'` = 0 문구가 관측과 어긋난 채 남아 있다.**
   `acceptance.md:233`(AC-012 (1))·REQ-014는 "✗ 줄 0"을 요구하지만, M1 이후 모든 실행에서 `grep -c '✗'` = **1**이다 — `Tools/GuardDriver.swift:1992`의 AB절 배너 문장("후보에서 ✗ = 재현이다")이 ✗ 문자를 안내 텍스트로 포함해서다. 이 렌즈의 실행도 같은 1줄(배너)이고 실패 단언은 0이다. 실행 레인은 매번 설명을 붙였지만 AC 문구 자체는 고치지 않았다. sync 판정 레인이 문자 그대로 읽으면 오탐 가능 — **배너 문구에서 ✗ 문자를 빼거나 AC에 배너 제외를 명시**하는 쪽을 권한다.
2. **[선택] AC-012 (1)의 "AA-4 첫 단언을 `AB-H11`로 바꾼 것(뺀 1 · 더한 1)"에서 +1의 착지 이름이 부정확하다.**
   M4 diff에서 AA-4 첫 단언 소거 옆에 실제로 더해진 줄은 **AB-H01** 이름이다("AB-H01 머무는 반복 목적지 모호('이동 없음' 뒤)"). AA-4 첫 단언의 의미론적 대체는 M1부터 있던 AB-H11 블록(11줄)이 맞고(`Tools/GuardDriver.swift:1890` 주석도 그렇게 쓴다) 계상 −1/+1 자체는 성립하지만, 문장을 그대로 읽으면 "+1이 AB-H11 이름으로 들어왔다"로 읽힌다. 원장 정확성에 흠은 아니고 표현 정밀도 문제다.
3. **[선택] progress.md §E.2 M6의 `resolveOriginAdoption` 호출처 줄번호가 트리 앵커를 섞어 인용했다.**
   "선언 `:2803`, 호출 `:1459`·`:1648`·`:1786`"에서 선언 번호는 HEAD 값, 호출 셋은 **후보(e1a40a6) 값**이다. HEAD의 실제 호출처는 `:1603`·`:1803`·`:2001`(M6 커밋 전에도 :1459가 아니다). 주장 자체(기본값 호출처 셋 생존)는 HEAD에서 참으로 확인됐다 — 인용 좌표만 다른 트리 것.
4. **[선택] 카드 열림 판정이 인라인 관용구로 9곳에 흩어져 있다(계약 위반 아님, 관찰).**
   `bubbles.contains(where: { $0.ask != nil })` 3곳(`:446`·`:908`·`:1143`) + `lastIndex(where:)` 변형 6곳. base에도 7곳 있던 **기존 관용구**이며 이번 작업이 같은 모양으로 2곳 더했다 — 두 계산이 따로 놀아 어긋나는 계약 5의 실패 모양(렌더링/히트테스트형)과는 다르다. 한 줄 술어라 의미가 흩어질 여지는 작지만, 다음 정리 때 헬퍼(`hasOpenAsk`류)로 모으는 후보로 기록해 둔다.

## 검증하지 못한 것 (Gaps)

- 모델 왕복(`callAI`)·화면 동작 — 드라이버가 구조적으로 지나가지 못하는 경로다(AC-014·AC-015 사람 증거). 이 렌즈 범위 밖.
- iOS·macOS 빌드·`npm test` 재실행 — AC-012 (3)·(4)는 이 렌즈 헌장 6항목 밖이고 M6 게이트 로그(`ios.log`·`macos.log`·`gate-*.log`)가 이미 `.moai/state/verify/t16/`에 있다. 전사하지 않았고 재검증도하지 않았다(sync 판정 레인 몫).
- 시뮬레이터 U-2 네 화면·AI 카드 1~16번 — 사람 전용 AC.

## 판정

**PASS** — 차단 0건. 헌장 6개 항목 전부 이 렌즈가 직접 실행한 명령 출력으로 통과했고, 토큰 증분 +122의 후보 귀속과 원장 산술(217→241→296)의 양끝을 관측으로 닫았다. 선택 4건은 문구·인용 정밀도와 차기 정리 후보 기록이다.

- 조언(advisory): 발견 1은 sync 판정 레인이 AC-012 (1)을 문자 그대로 대조하기 전에 배너 제외 명시(또는 배너 문구 수정)로 닫아 두는 쪽이 안전하다. 발견 2·3은 다음 progress.md 개정 때 한 줄씩이면 된다.
