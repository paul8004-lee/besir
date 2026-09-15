---
id: SPEC-ASK-001
title: "be on-time sir — 앱 주도 선택형 되묻기 + 얕은 메모리 제거"
version: "0.2.1"
status: draft
created: "2026-09-15"
updated: "2026-09-15"
author: "manager-spec"
priority: P1
phase: "v0.1.2 target"
module: "be-on-time-sir"
lifecycle: spec-anchored
tags: "be-on-time-sir, ai-assistant, argument-guards, guard-driver"
tier: M
related_specs: [SPEC-ONTIME-001]
---

# SPEC-ASK-001 — 앱 주도 선택형 되묻기 + 얕은 메모리 제거

## HISTORY

| 버전 | 날짜 | 변경 |
|---|---|---|
| 0.1.0 | 2026-09-15 | 최초 작성 — 루트 `plan.md` §6 Phase 1.5(2026-09-15 사용자 요청, 같은 날 승인)을 SPEC으로 정식화. 사용자가 2026-09-15에 확정한 설계 3결정(되묻는 주체는 앱 / 되물을 인자는 툴 선언에서 제거 / 이 삭제는 CLAUDE.md가 금지하는 방어 제거가 아님)을 REQ로 명문화하고, 되묻기 빈도는 열린 결정(D-1)으로 유보. 제거 대상 심볼의 인용 줄번호는 2026-09-15 작업 트리에서 grep 실측 |
| 0.2.0 | 2026-09-15 | D-1 확정 반영(사용자, 2026-09-15 — 선택지 C: 한 장의 묶음 카드 + 확인 버튼, 확인 시 툴 1회 호출). REQ-011을 개별 칩에서 단일 카드로, REQ-012를 탭 즉시 재호출에서 확인 시 1회 호출로, REQ-013을 순차 질문에서 "전부 모은 한 장 카드 + 스크롤 오버플로"로 갱신. REQ-014는 모든 행의 `[직접입력]`과 `도착 여유`의 진짜 `0분` 칩을 명시(발화로는 `v > 0`만 전달되는 트레이드오프, `Shared/AIAssistant.swift:1336-1341` 실측). REQ-015에 "명시 값은 카드 행을 만들지 않는다" 조항 추가. REQ-040을 D-1 조건부에서 무조건 무영속으로 확정하고 REQ-041(매번 물음, 세션 메모리 기각)을 신설 — REQ 16건. §4를 결정 대기에서 결정 기록(근거 2건 포함)으로 전환, Out of Scope의 D-1 항목을 세션 메모리 재도입 금지로 교체, REQ-020 단언을 (a)~(e)로 갱신 |
| 0.2.1 | 2026-09-15 | 후속 정정 2건. ① §4에 규약 슬롯 형식의 결정 기록 추가(D-1 = C — 기록일: 2026-09-15, 반영 REQ: REQ-041) 및 근거 2에 "C가 B보다 안전한 두 번째 이유" 보강 — REQ-040은 B의 디스크 절반만 막고 노출 문제를 구현으로 미룬다, C는 질문 자체를 제거한다. ② 드라이버 총 단언 수 인용 철회 — 작성 이후 두 생성 경로의 음수 `buffer_minutes` 미클램프가 발견돼 클램프가 `Store.clampBuffer`/`Store.clampNotifyLead`로 통일되는 중이고 드라이버 단언이 추가되고 있다. 게이트는 이름으로, 총수는 run-phase 실측으로(plan.md §2·§3, acceptance.md AC-005·AC-007, progress.md §E.1 동일 적용) |

## 0. 이 SPEC의 성격

**이 문서는 as-built 베이스라인이 아니라 구현을 앞둔 변경의 계약이다.** 설계 원본은 루트 `plan.md` §6 Phase 1.5이며, 이 SPEC은 그것을 재발명하지 않고 GEARS로 정식화한다. 인용 줄번호는 변경 전 현재 상태(2026-09-15) 기준이므로 구현 진행 중 밀릴 수 있다 — 그때마다 실측 재정렬한다(SPEC-ONTIME-001 HISTORY 0.2.3이 세운 관례).

**왜 신규 SPEC인가(수정이 아닌 분열).** `SPEC-ONTIME-001`은 REQ 25건으로 Tier L 상한에 정확히 걸려 있고, 그 SPEC 스스로 REQ 예산을 "Tier L 상한 25건"으로 못박는다 — 위반은 분열 신호다. 본 변경은 새 REQ 여러 건을 필요로 하므로 별도 SPEC으로 분열하며, `SPEC-ONTIME-001`의 REQ 번호는 재번호하지 않는다(acceptance.md·plan.md가 대역 체계에 의존). 대신 그 SPEC 쪽에 파장을 주는 두 REQ(REQ-061·REQ-063)의 개정을 본 SPEC의 완료 조건에 넣는다(§2.4).

## 1. 배경

저장된 선호가 조용히 적용되다 사용자가 모르는 채 틀린 값이 쓰이는 사고가 반복됐다 — 커밋 `b303f41`에서 명시적인 `0`이 저장된 여유·알림을 덮어써 여유 0분짜리 35건이 등록됐고 아무도 알아채지 못했다. 근본 원인은 이 프로젝트가 직접 측정한 이 모델의 행동이다: **선언된 선택 인자를 비워두지 못하고 전부 채운다.** "비워둬라"와 "물어봐라"는 이 프로젝트에서 가장 안 지켜지는 지시다 — 2026-09-15 실기기 전사에서도 `mode_this_time`이 여전히 채워져 도착했고, `weeks` 되묻기가 거의 뜨지 않는 것도 같은 이유다(모델이 채워서 `weeksArgument(input) == nil`이 성립하지 않는다, 정의 `Shared/AIAssistant.swift:1119`).

그래서 되묻는 주체를 모델에서 **앱**으로 옮긴다. 앱이 "인자가 비었다"를 관측하려면 모델이 그 값을 제공할 수 없어야 하므로, 되물을 인자는 툴 선언에서 아예 뺀다. 사용자가 직접 말한 값("자동차로 가자", "여유 20분")은 앱의 문장 파서가 잡는다 — 모델을 거치지 않으므로 결정적이다. 부수 효과로 툴 선언과 시스템 프롬프트가 줄어 요청당 고정 토큰비가 내려간다 — 현재 실측 **4,425 토큰**(systemPrompt 1,526 + toolsJSON 2,899; tiktoken `o200k_base`, 중립 설정).

### 1.1 이 제거가 "방어를 걷어낸다"가 아닌 이유 (명명 단락)

CLAUDE.md(AI 백엔드 절)는 "**모델을 바꿨다고 이 방어들을 먼저 걷어내지 않는다** — 테스트로 불필요해진 것을 확인한 뒤에 지운다"고 못박는다. 이 문단은 본 SPEC의 제거가 이 금지 사례가 **아님**을 명시한다:

1. **근거가 측정돼 있다** — 저장값 폴백이 사고를 낸 실적이 있고(`b303f41`), "비워둬라" 지시는 두 번 실패했다(§1).
2. **제거는 교체다** — 값이 없으면 추측하는 대신 **묻는다**(REQ-011). 폴백이 사라진 자리에 임의 값이 조용히 들어가는 것이 본 변경이 막으려는 바로 그 사고다.
3. **걷지 않는 것도 명시한다** — `isSamePlace` 50m 가드, `list_schedules` 빈 결과 자기교정, 갱신 경로의 0 되묻기(`zeroUpdateIssue`, SPEC-ONTIME-001 REQ-062) 등 나머지 실행부 방어는 본 SPEC이 건드리지 않는다(§ Out of Scope).

훗날 이 제거를 "모델이 좋아져서 방어를 걷어냈다"로 오독하는 일이 없도록, 이 구분을 여기 둔다.

## 2. 요구사항 (GEARS)

> REQ 번호는 **§2.N 대역식**이다 — §2.1→001번대, §2.2→010번대, §2.3→020번대, §2.4→030번대, §2.5→040번대로 각 하위 절에 하나의 대역을 배정했고, 연속 번호가 아니다. 대역 사이의 빈 번호는 REQ 누락이 아니라 그 절에 추가 REQ가 붙을 자리다. acceptance.md와 plan.md의 REQ 범위 표기가 이 대역에 의존하므로 재번호하지 않는다.

### 2.1 얕은 메모리 제거 (001번대)

- **REQ-001 (Unwanted)**: The `AIAssistant` tool loop shall not expose `remember_fact` or `forget_fact` — 툴 수는 11 → 9. 근거(변경 전 실측): 선언 `Shared/AIAssistant.swift:712`(`remember_fact`)·`:725`(`forget_fact`), 디스패치 `:773`·`:777`, 시스템 프롬프트 안내 `:521`. 이 변경은 `SPEC-ONTIME-001` REQ-061("정확히 11개 툴")의 개정을 수반한다(REQ-030).
- **REQ-002 (Unwanted)**: The app shall neither read nor write `ai_memory.json`. 근거: 경로 조립 `Shared/AIAssistant.swift:97`. 기기에 남은 옛 `ai_memory.json`은 앱이 더 이상 읽지 않으므로 동작에 영향을 주지 않는다 — 삭제 마이그레이션은 요구하지 않는다.
- **REQ-003 (Ubiquitous)**: The system prompt shall carry no `factsBlock`, `prefsBlock`, or `modeBlock`, and no instruction to fill saved defaults or leave `mode_this_time` empty. 근거: `prefsBlock` `:485`, `modeBlock` `:487-488`, `factsBlock` `:489`, 주입 지점 `:494`, 지시문 `:498`·`:501` — "저장된 기본값을 그대로 채워라" / "`mode_this_time`은 비워둬라" / "물어서 들으면 `remember_fact`로 저장하라"가 전부 사라진다. 이 지시들이 바로 이 프로젝트에서 가장 안 지켜지는 지시였다(§1).
- **REQ-004 (Unwanted)**: `AppConfig` shall not carry `preferredMode`, `preferredBuffer`, or `preferredNotify`. 근거: `Shared/Config.swift:29`·`:31`·`:33`(필드), `:22-26`(설계 의도 주석 — 이 주석이 말하는 위협 모델이 본 SPEC으로 폐기된다), CodingKeys `:112`, 디코드 `:124-126`. 옛 `config.json`에 남은 해당 키는 더 이상 디코드되지 않는다.
- **REQ-005 (Unwanted)**: `resolvedMode`/`resolveOrigin` shall not substitute stored preference values for absent arguments, and `applyStatedPreferences(from:)` shall not exist — 부재는 부재로 관측되어 REQ-011의 칩 요청으로 흐른다. 근거: `resolvedMode` `:757`, `resolveOrigin` `:1810`, `applyStatedPreferences` 정의 `:321`·호출 `:279`. **빈 문자열을 부재로 읽는 처리(`:1095-1096` 주석의 모양)는 유지한다** — 제거하는 것은 저장값 대체뿐이다.

### 2.2 앱 주도 선택형 되묻기 (010번대)

- **REQ-010 (Ubiquitous)**: The tool declarations (`toolsJSON()`) shall not declare the arguments the app will ask about — 최소한 생성 도구(`create_schedule`, `create_recurring_schedule`)의 `mode_this_time`(왕복 변형 `travel_mode_this_time`/`return_mode_this_time` 포함), `buffer_minutes`, `notify_lead_minutes`, `weeks`. 앱이 "부재"를 관측하려면 모델이 그 값을 제공할 수 없어야 한다 — 선언에 남겨두고 "채우지 마라"라고 적는 방식은 이미 두 번 실패했다(§1). 근거: `toolsJSON()` `:539`, 인자 선언 `:577-579`·`:599-601`(왕복 변형)·`:626`(`weeks`)·`:631-633`. 부수 효과로 요청당 고정 토큰비(4,425, §1)가 내려간다. **갱신 도구(`update_recurring_schedule`)의 인자 선언과 0 되묻기 흐름은 SPEC-ONTIME-001 REQ-062 그대로 유지한다** — 갱신 쪽까지 제거를 확장할지는 plan.md M1에서 판단하되, 확장하면 REQ-030의 개정 범위도 함께 넓어난다(조용한 확장 금지).
- **REQ-011 (Event-driven)**: **When** a tool call arrives with one or more required arguments absent, the app — not the model — shall render a **single card** in the chat view, one chip row per missing argument plus a confirm button, and hold the call until the user confirms; **when** nothing is missing, no card appears and the tool executes directly. 보류 상태는 인자별 선택지와 재개할 호출을 담는다. 승인된 카드 형태는 §4의 예시다. 모델에게 "물어봐라"라고 지시하는 경로는 더 이상 존재하지 않는다(REQ-003).
- **REQ-012 (Event-driven)**: **When** the user confirms the card, the app shall invoke the tool exactly once, carrying every collected value in its argument — 탭은 그 행의 선택값을 정하고(마지막 탭이 유효), 확인이 호출을 발동한다. 호출은 앱이 수행한다 — 선택과 값 사이에 모델이 임의 값을 넣을 틈이 없다.
- **REQ-013 (Event-driven)**: **When** more than one required argument is absent, the app shall collect all of them into the one card — 인자마다 행이 하나고, 카드는 요청당 정확히 한 장이며, 여러 번 끼어들지 않는다(D-1 근거 1, §4). 반복 일정처럼 빈 인자가 5개 이상이 되어 카드가 길어지면 **스크롤로 전체를 담는다** — 캡이나 접기로 행을 숨기면 그 인자를 아예 정할 수 없거나 기본값이 조용히 적용되는 경로가 되살아나므로, 숨김 없이 전부 도달 가능하게 둔다.
- **REQ-014 (Where capability gate)**: **Where** an argument is asked on the card, its row shall offer a `[직접입력]` escape — 칩은 모든 값을 열거할 수 없으므로 모든 행에 붙는다(§4 승인 형태의 `[직접]`). `도착 여유` 행은 **진짜 `0분` 칩**을 제공한다: 0은 "여유 없이"라는 정당한 요청이지만, 문장 파서의 `Self.minutes`는 `v > 0`만 돌려주고 생성 경로 수용부도 `$0 > 0`만 통과시켜(`Shared/AIAssistant.swift:1336-1337`·`:1341`) **발화로는 진짜 0을 말할 수 없다** — 이 프로젝트가 받아들인 트레이드오프였고, 이 SPEC의 카드가 그 받아들여진 격차를 닫는다: 0이 다시 설정 가능해진다. 빈 직접입력으로는 제출되지 않는다.
- **REQ-015 (Event-driven)**: **When** the user's utterance explicitly states a value ("자동차로 가자", "여유 20분"), the app's own sentence parser shall fill the argument from it, bypassing both the model and the card — 명시된 인자는 카드에 행을 만들지 않는다. 카드는 진짜 모르는 것만 보여준다(D-1 확정 사항, §4). 현재 `applyStatedPreferences(from:)`(`:321`, 호출 `:279`)가 문장에서 선호를 뽑아내는 파싱 능력이 이 역할의 씨앗이다 — 저장 대상이 사라지므로(REQ-005) 이 파싱은 "이번 요청의 인자 채우기"로 재목적된다.

### 2.3 결정적 검증 — GuardDriver (020번대)

- **REQ-020 (Where capability gate)**: **Where** a requirement of this SPEC is verifiable without a model call, it shall be expressed as a `Tools/GuardDriver.swift` assertion — 최소 다섯 가지: **(a)** 부재 인자 집합 → 카드 요청이 정확히 그 인자들만 나열(행 수 = 부재 인자 수), **(b)** 발화 명시 값 → 해당 행이 카드에서 빠짐, **(c)** 빈 부재 집합 → 카드 없이 툴 직접 실행, **(d)** 확인 → 수집된 모든 값이 실린 호출이 정확히 1회 발생, **(e)** 제거된 툴·인자가 `toolsJSON()`에 부재. 근거: 드라이버는 로직을 복사하지 않고 원본 `Shared/AIAssistant.swift`를 이어붙여 컴파일하므로 원본과 어긋날 수 없으며, 모델 호출·API 할당량 없이 결정적으로 돈다(`Tools/GuardDriver.swift` 머리말; CLAUDE.md "AI 인자 가드를 고쳤으면 `Tools/GuardDriver.swift`의 단언도 같이 갱신한다"). **대비 — 모델 주도였다면 이 검증은 불가능했다**: 되묻기를 모델에 맡긴 기존 흐름(`on_conflict` 재질의, `confirm_many`, 반복 0 되묻기)은 "되묻기가 사용자에게 닿았다"를 가드가 증명할 수 없다 — 가드는 모델이 실제로 어떤 인자를 보내는지 알 수 없고 그 증거는 실기기 대화 기록뿐이라는 제약을 이 프로젝트는 이미 드라이버 머리말에 문서화했다. 앱 주도 카드는 요청 생성 자체가 앱의 보류 상태(REQ-011)이므로 비로소 결정적 검증이 된다 — 이것이 이 설계의 핵심 이득이다. (현행의 `recurrenceConfirmAsk` — `Shared/AIAssistant.swift:66`·`:1143`, 앱이 실제로 되물은 조합만 확인을 인정하는 패턴 — 이 같은 원리의 축소판이다.)

### 2.4 문서 정합성 — `SPEC-ONTIME-001` 개정이 완료 조건이다 (030번대)

이 프로젝트는 as-built 문서가 코드를 따라가지 못하는 드리프트를 이미 두 번 겪었다. (1) `SPEC-ONTIME-001` REQ-060은 커밋 `860e121`이 지운 Workers AI 경로를 인용한 채 남아 있었다(같은 SPEC HISTORY 0.2.1에서 교체). (2) `CHECKLIST.md` L11행(`CHECKLIST.md:150`)은 도달 불가능한 분기를 2026-09-15까지 ✅로 표시하고 있었다. 본 SPEC이 툴을 지우고 REQ-061("정확히 11개 툴")·REQ-063(`ai_memory.json` 지속)을 그대로 두면 같은 드리프트의 세 번째 사례가 된다. 그래서 개정은 후속 작업이 아니라 **본 SPEC의 완료 조건**이다.

- **REQ-030 (Ubiquitous)**: Completion of this SPEC shall include amending `SPEC-ONTIME-001` REQ-061 to enumerate 9 tools (`remember_fact`·`forget_fact` 제거) — 함께 그 SPEC acceptance.md AC-007의 "11개 툴" 서술과 plan.md M5의 대응 서술을 갱신하고 HISTORY에 버전 bump를 기록한다.
- **REQ-031 (Ubiquitous)**: Completion shall likewise amend `SPEC-ONTIME-001` REQ-063 to drop the `ai_memory.json` persistence and the `remember_fact`/`forget_fact` path — `ai_history.json` 지속과 툴 호출 실패 시 사전 상태 롤백 단언은 그대로 둔다.

소유권 주의: `SPEC-ONTIME-001`의 spec.md·acceptance.md·plan.md 본문 수정은 manager-develop에게 금지된 영역이다 — run-phase에서 이 REQ들이 걸리면 오케스트레이터가 manager-spec에게 재위임한다(D-NEW-1 인라인 수정 패턴).

### 2.5 되묻기 빈도 — 모든 선택지에 공통인 불변식 (040번대)

- **REQ-040 (Unwanted)**: The asking state shall not persist to disk in any form — `ai_memory.json`, `Config` 선호 필드, 또는 그 대체물이 부활하지 않는다(D-1, §4). 진짜 메모리 시스템은 별도 plan이다(§ Out of Scope).
- **REQ-041 (Ubiquitous)**: The app shall ask on every request — 어떤 값도 요청 사이에 기억되어 넘어가지 않는다. 매번 물음을 그대로 유지하되 중단 비용을 카드 1장·요청당 1회로 낮춘다(D-1 근거 1, §4). 선택지 B(세션 한정 기억)는 기각됐다 — 세션으로 범위를 좁혀도 "저장된 값이 조용히 적용된다"는 이 SPEC이 제거하려는 바로 그 성질이 되살아나기 때문이다(근거 2, §4).

## 3. Out of Scope

### Out of Scope — 진짜 메모리 시스템

- 5개 서비스 전체의 활동 로그를 쌓아 AI가 사용자를 학습하는 메모리 — 사용자가 2026-09-15에 결정: 전 기능 구현 후 별도 plan으로 한 번에 만든다. 본 SPEC은 현재 부채인 얕은 메모리(`ai_memory.json` + 선호 필드)를 걷어내고 결정적 되묻기로 대체하는 것까지다.

### Out of Scope — 세션 메모리의 재도입

- 선택지 B(앱이 켜져 있는 동안만 기억)는 2026-09-15에 기각됐고(§4 근거 2), 그 재도입 제안도 이 SPEC 범위 밖이다. "저장된 값이 조용히 적용되는" 성질이 필요한 설계는 진짜 메모리 시스템의 별도 plan에서 다룬다.

### Out of Scope — 유지되는 실행부 방어 (CLAUDE.md 계약 준수)

- `isSamePlace` 50m 가드, `list_schedules` 빈 결과 자기교정, 갱신 경로의 0 되묻기·`confirm_zero`·`series_number` 흐름(SPEC-ONTIME-001 REQ-062), `weeks` 상한 26주(`maxRecurrenceWeeks`) 등 본 SPEC이 명시적으로 제거하지 않는 방어는 그대로 둔다. SSOT는 CLAUDE.md "AI 백엔드" 절 — "테스트로 불필요해진 것을 확인한 뒤에 지운다."

### Out of Scope — 프록시·AI 백엔드

- `proxy/src/index.js`, 모델(`gpt-5.6-luna`), `reasoning.effort` 설정은 건드리지 않는다. 칩은 앱 안에서만 일어나며 Gemini 와이어 포맷 계약(SPEC-ONTIME-001 REQ-060)도 그대로다. 백엔드 현황의 SSOT는 `CLAUDE.md` "AI 백엔드" 절이다.

### Out of Scope — 실기기 전용 검증

- 칩 탭 감각, 질문이 대화에 끼어드는 느낌, 실제 알림 수신 등 빌드로 검증 불가능한 항목은 acceptance.md에서 ⬜로만 표시하고 본 SPEC의 완료 조건에 넣지 않는다(SPEC-ONTIME-001 AC-010/011 관례).

## 4. 결정 기록 — D-1 되묻기 빈도 (2026-09-15 사용자 확정)

**결정: 선택지 C — 한 장의 묶음 카드.** 필수 인자가 비어 있으면 앱이 그 전부를 모아 인자별 칩 행을 가진 카드 1장을 채팅창에 띄우고, 사용자가 확인 버튼을 누르면 그때 툴을 **1회** 호출한다. 승인된 형태:

```
┌──────────────────────────┐
│ 몇 가지만 알려주세요        │
│                          │
│ 이동수단                  │
│ [자동차][대중교통][도보]    │
│                          │
│ 도착 여유                 │
│ [0분][10분][20분][직접]    │
│                          │
│ 알림                     │
│ [없음][10분][30분][직접]   │
│                          │
│        [ 등록하기 ]       │
└──────────────────────────┘
```

**근거 1 — "매번 물음"을 문자 그대로 유지하면서 중단은 요청당 1회.** 순차 변형(선택지 A)도 같은 질문을 하지만 일정 하나에 3~5번 끼어든다 — 하루에 몇 번씩 쓰는 앱에서 이 중단은 쌓인다. 카드는 매번 다 물으면서도(REQ-041) 중단 비용을 1회로 묶는다.

**근거 2 — 기억을 전혀 되살리지 않는다.** 기각된 선택지 B(앱이 켜져 있는 동안만 기억)는 이 SPEC이 제거하려는 성질 — **저장된 값이 조용히 적용됨** — 을 세션으로 범위를 좁혀서 되살린다. 그것이 `b303f41`의 사고 형태다(조용히 적용된 값이 35건에 닿고 아무도 몰랐다). **범위 축소는 이 부류에 대한 해법이 아니므로 기각했다. 이 근거를 명시하는 이유**: 훗날 누군가 세션 메모리를 "자명한 최적화"로 다시 열지 못하게 하려는 것이다. C가 B보다 안전한 두 번째 이유도 같은 맥락이다 — REQ-040(디스크 영속 금지)은 B의 디스크 절반만 막고 "기억값이 쓰이는 순간이 사용자에게 보이는가"는 구현으로 미뤘을 것이다. C는 그 질문 자체를 제거한다 — 미루지 않고 없앤다.

**기각된 대안**: A(매번 순차 질문) — 근거 1의 중단 비용. B(세션 한정 기억) — 근거 2. 두 기각 모두 카드 형태(REQ-011~014·REQ-041)에 설계 제약으로 남는다.

**결정 기록(규약 슬롯 형식)**: D-1 = C — 기록일: 2026-09-15, 반영 REQ: REQ-041
