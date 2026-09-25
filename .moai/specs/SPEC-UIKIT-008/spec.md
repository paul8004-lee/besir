---
id: SPEC-UIKIT-008
title: "AI 카드의 장소 해석 UX — 첫 검색 결과 무확인 채택(U-4)·되묻기 장소 줄(AC-009 7·9)·왕복 가는 편 줄·머무는 반복·검색 재오픈 강조(U-2)"
version: "0.1.1"
status: draft
created: "2026-09-26"
updated: "2026-09-26"
author: "manager-spec"
priority: P1
phase: "Phase 1.7 — 일정·활동 화면 UI 통일"
module: "shared-ui"
lifecycle: spec-anchored
tags: "place-resolution, candidate-card, u-4, ac-009, round-trip, staying-recurrence, u-2, ai-tooling, candidate-diff"
tier: M
related_specs: [SPEC-UIKIT-005, SPEC-UIKIT-007, SPEC-UIKIT-003, SPEC-ASK-001]
kanban_card: t16
---

# SPEC-UIKIT-008 — AI 카드의 장소 해석 UX

## HISTORY

| 버전 | 날짜 | 변경 |
|---|---|---|
| 0.1.0 | 2026-09-26 | 최초 작성. 칸반 카드 t16 본문(`moai todo`)을 GEARS로 정식화했다. **출발점은 이전 세션이 남긴 미커밋 후보 구현을 보존한 `e1a40a6`이고, 이 SPEC은 그 diff를 채택된 답이 아니라 후보로 다룬다.** 연구 입력은 읽기 전용 렌즈 보고서 둘(`.moai/reports/t16/plan-lens-ai-tooling.md`·`plan-lens-ui-design.md`)이며 본문을 옮기지 않고 절 번호로 인용한다. 게이트 수치는 오케스트레이터가 이 세션에서 다시 돌려 `.moai/state/verify/t16-plan/`에 남긴 로그를 읽어 인용했다(드라이버 base `217/217`·head `241/241`, iOS·macOS 전체 빌드 swift 경고 0/0). **줄번호는 전부 이 트리(`e1a40a6`)에서 명령으로 쟀고 세는 명령을 옆에 적었다.** 이전 기록 `.moai/reports/t16/progress.md`의 부류 "Class B"는 운영자가 Class C(plan → run → sync)로 바꿨다 — 그 파일은 고치지 않고 이 SPEC의 `progress.md` §E.1에 적었다. 미해소 결정 10건은 `plan.md` §2에만 게이트 표식으로 둔다(`spec.md`·`acceptance.md`에는 두지 않는 관례, SPEC-UIKIT-005 HISTORY 0.1.0) |
| 0.1.1 | 2026-09-26 | **plan 감사 1회차(FAIL 0.77, `.moai/reports/plan-audit/SPEC-UIKIT-008-review-1.md`) 반영 — 게이트 전 작성 수리.** 코드는 무변경이고 REQ 15 · AC 15 그대로다. **D2** REQ-008의 적용을 `create_schedule`·`create_activity`로 좁히고, `create_recurring_schedule`의 같은 값은 REQ-010의 머무는 반복 신호라 이 규칙에서 뺐다(AC-006 (5) 신설). **D3** REQ-010의 발동 조건을 카드(문자열 같음)와 실행부(50 m)로 갈랐고, 이름은 다르고 좌표만 같은 경우를 잔여 위험으로 적었다. **D4** REQ-001에 단언 극성 규칙을 넣었다 — 고칠 가설은 바라는 동작, 게이트가 수용한 가설은 M1 재현 뒤 관측 동작을 적는 특성화 단언(`[수용]` 표지)으로 바꾼다. 그래서 REQ-014의 ✗ 0과 모든 선택지가 함께 선다(AC-001 (5)·AC-008 (5)). **D5** `plan.md` D-7 (b)를 거뒀다 — 발화 파서(`:338-344`)는 출발지를 읽지 않는다. **D6** 재현 단언 이름을 두 자리(`AB-H01`~`AB-H10`)로 바꿔 `AB-H1`이 `AB-H10`을 세던 충돌을 없앴다. **D7** REQ-015에 원장 범주 "대상 제거·재작성"과 "수리 전 상태 문장은 그 SPEC의 base 커밋에 고정" 규칙을 넣고, SPEC-UIKIT-005 인용 지목을 그 규칙으로 다시 썼다. 후보가 `isSamePlace`의 둘째 사용처(`:1812`)를 만들어 `:1869` 주석이 거짓이 된 사실을 §1.4·§3에 적고, 그 주석 교정을 REQ-010(run 범위)에 넣었다. **D8**(오케스트레이터 결정) 렌즈 보고서 둘은 plan 커밋에 SPEC 디렉터리·plan 감사 보고서와 함께 들어간다 — REQ-013 예외 목록에 넣고 AC-011 (1)을 `e1a40a6` 기준 예외 목록 방식으로 바꿨다. **D9** REQ-015·AC-013 (1)에 GuardDriver 파일명 토큰 계수(`CHECKLIST.md` 1건)를 더했다. **D12** D-10 권장 문안을 `plan.md` §2에 원문으로 적고 AC-005·006·007·008·010에 문자열 신호를 넣었으며, 조사·줄표 규칙을 REQ-008 본문으로 올렸다. **D11** D-1 (c)·D-3 (c)·D-5 (c)의 "바뀌는 것"을 AC 절과 스크립트 번호까지 적고, D-5 (a)의 전제가 깨질 때의 경로를 넣었다(D10 겸). **D13** 통과 수를 T = 241 − 뺀 수 + 더한 수로 정했다. **D14** AC-003 제목("열 조합")·AC-014 대응 REQ·`plan.md` 대응표(011→014)를 고쳤다. 한 줄 수리로 함께 반영한 선택 결함: **D15**(REQ-012에 `chip()` 무변경을 올리고 튜플 반복 감소는 권고로 낮춤) · **D16**(REQ-011 트리거·사실 문장) · **D17**(REQ-006 Where 절, REQ-014 When 절) · **D19**(AC-010 색 검사 정규식·양성 대조) · **D20**(REQ-013 죽은 경로 서술) · **D21**(잔여 위험 한 줄) · **D22**(경고 "24줄, 진단 12"). **D18**은 프로젝트 관례(SPEC-UIKIT-005·007)라 두었다. 게이트 표식 10건(MP-7, D1)은 리드 몫이라 그대로다 |

## 0. 이 SPEC의 성격과 예산

**후보 구현을 고쳐서 받는 변경의 계약이다.** run은 `e1a40a6`에서 시작한다. 후보는 카드 항목 다섯 중 넷을 AI 쪽에서 이미 건드렸고(§1.2), 오케스트레이터가 다시 돌린 게이트도 통과한다. 그러나 두 렌즈는 서로를 보지 않고 **같은 결함 셋**에 도달했고(§1.4), 그 결함은 전부 드라이버가 지나지 않는 경로에 있다. 그래서 이 SPEC은 후보를 출발점으로만 쓰고, 렌즈가 코드 추적으로만 찾은 결함은 run이 **먼저 재현한 뒤에** 고치게 한다(REQ-001).

**Tier: M.**

| 측정 | 값 | 세는 명령 |
|---|---|---|
| 후보 diff | `Shared/AIAssistant.swift` +333/−64 · `Tools/GuardDriver.swift` +179/−1 (소스 합 577줄) | `git diff --numstat aa7b792 e1a40a6` |
| 파일 길이 | AIAssistant 2484 → **2753** · GuardDriver 1813 → **1991** · EditCardView 528 · EditCard 350 | `git show aa7b792:<파일> \| wc -l` · `wc -l <파일>` |
| AIAssistant diff 헝크 | **35개**, 첫 헝크가 `:495`에서 시작 | `git diff -U0 aa7b792 e1a40a6 -- Shared/AIAssistant.swift \| grep -c '^@@'` |
| run이 여는 소스 파일 | 최대 **4** — 크게 고침 2(AIAssistant·GuardDriver), 작게 고침 2(EditCardView — D-1, EditCard 주석 한 줄 — D-6) | §2 REQ-013 |

후보 diff만으로 Tier S 기준(< 300 LOC)을 넘는다. 재현 절과 수리가 더해져도 1000줄 아래로 본다 — Tier L이 아닌 이유다. 파일 수는 5 미만이지만 변경량, 미해소 결정 10건, **사람만 볼 수 있는 증거의 설계**가 `acceptance.md`를 요구한다(SPEC-UIKIT-005 §0과 같은 판단).

**REQ·AC 예산.** `grep -c '^- \*\*REQ-' spec.md` = **15**, `grep -c '^## AC-' acceptance.md` = **15**. Tier M 상한 16 아래이고 여유는 각 1건이다. 16에 닿으면 분할 신호다.

**한 Day 파일 한도(3~4).** 크게 고치는 파일 2 + 작게 고치는 파일 2로 한도 안이다. 한도를 넘기는 선택지(D-8 (b)(c), D-9 (c))는 `plan.md` §2에 그 사실을 적었다. U-2는 셋째 파일(`Shared/EditCardView.swift`)로 이 카드에 넣기를 권고한다(D-1) — 새 후보 카드가 장소 검색 편집기를 주 경로로 만들기 때문이다(ui 렌즈 §1.4).

**드라이버 초록은 이 SPEC의 증거로 반만 센다.** 241/241이 통과한 바로 그 트리에 렌즈 결함이 있다. 이 프로젝트에는 드라이버 88/88 다음 날 실기기 결함 7건이 나온 이력이 있다(2026-09-15). 드라이버는 도구 실행부와 카드 판정을 모델 없이 직접 부르지만 `runLoop`의 모델 왕복(`callAI`)은 지나지 못한다(드라이버가 프록시 설정을 비우므로 — `CLAUDE.md` § 빌드 · 배포). 모델 루프의 행동과 화면은 사람 증거(AC-014·015)로만 닫힌다.

## 1. 배경

### 1.1 카드 항목 다섯 — 관측된 원형

| 항목 | 관측 | 출처 |
|---|---|---|
| U-4 지점 불일치 | "스타벅스 홍대점" 요청이 **대학로점**으로(2026-09-23), "강남"이 **서울선릉과정릉**으로(2026-09-24, 최종 빌드 `5a357cc`) 등록 — 첫 검색 결과를 확인 없이 채택 | 공용 메모리 이월 목록(t7 세션·14항목 세션) · `day-close-20260924.md` §6 #23 |
| AC-009 7·9 | 되묻기·`create_activity` 카드에 장소 줄이 서지 않고 모델이 텍스트로 재질문(2026-09-23, `dd-a` 빌드) | `day-close-20260924.md` §6 #24 · SPEC-UIKIT-005 `acceptance.md` AC-009 |
| 왕복 가는 편 줄 | 왕복 `create_activity` 카드는 뜨지만 가는 편 출발지 줄과 '가는 편 없음' 칩이 없다(2026-09-24) | 카드 t16 본문 |
| 머무는 반복 | "집에서 점심식사" 반복이 통근형(회사↔집, 76건)으로 등록됐고 모델이 스스로 잘못을 고지했다(2026-09-24) | 공용 메모리 이월 목록 |
| U-2 강조 잔존 | 장소를 고른 뒤 장소 검색을 다시 열면 옛 선택 강조가 남는다(2026-09-23, SPEC-UIKIT-003 AC-010) | 공용 메모리 이월 목록 · `day-close-20260924.md` §6 #21 |

### 1.2 후보 구현이 한 일 (`e1a40a6`, 코드 열람)

세는 명령: `grep -n 'func parkForUnclearPlaces\|func adoptPlace\|enum PlaceAdoption\|func searchTopClearlyMatches\|func stayingRecurrence\|func filledValueLabels\|func repeatedSearchQuery\|func searchBoundPlace\|func resolvePendingAsk\|func askFields' Shared/AIAssistant.swift`와 해당 범위의 `awk 'NR>=a && NR<=b'`.

| 무엇 | 자리 |
|---|---|
| 해석 사다리의 단일 출처 — 즐겨찾기 → 확정 장소 → 일반명사 가드 → 검색 채택, 삼태 `resolved/notFound/unclear` | `adoptPlace` `:2653` · `PlaceAdoption` `:2645` · 후보 5건 자르기 `:2675`(`maxPlaceSuggestions` `:927`) |
| 채택 판정 — 결과 **이름 + 주소**를 공백 없이 이어 붙여 질의 낱말을 찾는다 | `searchTopClearlyMatches` `:2685` · 이어 붙이기 `:2686` |
| 등록 실행부 갈래 — `unclear`가 하나라도 있으면 등록을 멈추고 후보 카드 | `create_schedule` `:1457-1485` · `create_activity` `:1630-1661` · `create_recurring_schedule` `:1784-1805` |
| 후보 카드 — 모호한 키를 보류 인자에서 비우고 후보를 줄에 얹는다 | `parkForUnclearPlaces` `:786` · 중복 가드 `:790-792` · 비우기 `:796` · 후보 얹기 `:801` · 맥락 줄 `:805` |
| 같은 이름 줄(AC-009 7·9) | `create_schedule` `:495-505` · `create_activity` `:537-548` · 판정 `repeatedSearchQuery` `:708` · `searchBoundPlace` `:700` |
| 왕복 가는 편 줄 | `:549-562`(재확인 캡션 `:560`) · 탈출 칩 `:644` |
| 머무는 반복 | 카드 억제 `stayingRecurrence` `:720`(적용 `:525-529`) · 실행부 `:1812-1830` · 프롬프트 `:1193` · 선언 설명 `:1273` |
| 드라이버 새 절 | `Tools/GuardDriver.swift` AA절 `:1826-1977` · 판정 도우미 `drvTopMatches` `:137`(주소 기본값 `""`) · `drvPark` `:143` |

### 1.3 후보 카드의 확인 주입 — 도구×키 여덟 조합 (코드 추적, 미실행)

`parkForUnclearPlaces`는 모호한 키를 `""`로 비운다(`:796`). 확인 때 `resolvePendingAsk`는 `askFields(tool:args:)`를 다시 구해 **그 함수가 돌려준 키에만** 고른 값을 싣는다(`:1050-1051`). 그런데 `askFields`는 여러 키에서 빈 값을 "물을 값"으로 보지 않는다. ai-tooling 렌즈 A-1 (c)의 표를 이 트리에서 다시 읽었다(`awk 'NR>=467 && NR<=579' Shared/AIAssistant.swift`).

| 도구 | 모호한 키 | 빈 값에 줄이 서는가 | 후보 트리에서의 예측 |
|---|---|---|---|
| `create_schedule` | `origin_query` | 선다 `:493` | 주입된다 |
| `create_schedule` | `destination_query` | 선다 `:491` | 주입된다(AA-6·AA-7이 덮는 유일한 조합) |
| `create_recurring_schedule` | `origin_query` | 선다 `:521` | 주입된다 |
| `create_recurring_schedule` | `destination_query` | **안 선다** — `:520`은 `unknownPlace`만 본다 | 선택이 버려지고 `:1760` "반복 일정 정보가 부족합니다"로 끝난다 |
| `create_activity` | `place_query` | **안 선다** — `:534`는 `unknownPlace`만 본다 | 이동이 없으면 장소 없는 활동이 성공 문구로 등록된다(빈 값은 `:1667-1668`에서 실패로 세지 않는다) |
| `create_activity` | `travel_from_query`(왕복) | 선다 `:556` | 주입된다 |
| `create_activity` | `travel_from_query`(편도) | **안 선다** — `:550`의 guard가 빠져나간다 | 가는 편 없이 성공 등록, 경고 문구 없음 |
| `create_activity` | `return_to_query` | **안 선다** — 왕복이 편도로 바뀌며 `:567`이 수단 줄을 새로 요구 | `missingAskedArguments`(`:1403`)가 "이동수단이 비어 있어요"로 막는다 |

화면은 체크 칩으로 "골랐다"를 보여주므로(ui 렌즈 §2.6 X2) 사용자 쪽에서는 조용한 실패다. 2026-09-23 홍대점 관측이 어느 도구에서 났는지는 기록에 없다 — `create_activity`였다면 **관측 사례 자체가 후보로 닫히지 않는다**(ai 렌즈 A-1 (c) 끝, 추론).

### 1.4 두 렌즈의 판정 — 독립으로 수렴한 셋

두 렌즈는 서로의 보고서를 보지 않고 썼다. ui-design 렌즈는 아래 셋을 "뷰 밖이지만 화면 결과를 바꾸는 교차 가설"로 넘겼고(§2.6 X1·X2, §2.2 B1), ai-tooling 렌즈는 같은 셋을 코드 경로 끝까지 따라가 결함으로 판정했다(A-1 (b)(c)(f)).

1. **'강남' 판정 누락.** 술어가 주소까지 보므로 선릉·정릉 주소의 '강남구'에서 '강남'이 맞는다. 드라이버 AA-1은 이 사례를 **빈 주소**로 단언해 그 경로를 뺀 채 통과한다(`Tools/GuardDriver.swift:1834-1835`, `grep -n 'drvTopMatches("강남"' Tools/GuardDriver.swift` → `:1835`에 주소 인자 없음).
2. **확인 주입 구멍.** §1.3의 네 조합.
3. **보이지 않는 후보.** 후보는 편집기 안에서만 그려지고(`Shared/EditCardView.swift:316` `placeSearchEditor`, 열림 조건 `:132`), 편집기의 씨앗은 `startsOpen` 줄뿐인데(`:68-70`) 기본값이 false이고(`Shared/EditCard.swift:164`) 후보 카드는 이를 켜지 않는다(`grep -c 'startsOpen' Shared/AIAssistant.swift` = **0**). 캡션은 "아래 후보에서 골라 주세요"다(`:735`).

그 밖의 판정(각 렌즈 절 번호로만 적는다):

- **한 턴 다중 호출 소실** — 중복 가드 `:790`은 "카드가 하나라도 열려 있는가"만 보고, 두 번째 모호 호출은 카드에 실리지 않은 채 "자동으로 진행돼요"(`:791`)라는 거짓 안내를 받는다. 한 턴 다중 호출은 설계된 경로다(`:738-740` 주석). (ai A-1 (d))
- **보류 뒤 루프 지속** — `runLoop` 카드는 세워지는 즉시 턴을 끝내지만(`:428-431`) 후보 카드는 도구 실행 안에서 세워져 루프가 이어진다(`:433-434`, 상한 `:380`). 모델이 인자를 바꿔 재호출하면 그것이 등록되고, 카드를 확인하면 한 건이 더 생길 수 있다. (ai A-1 (e), ui B4)
- **맥락 줄이 빈다** — 후보 카드의 "말씀하신 대로"는 `statedLabels() + filledValueLabels(...)`(`:805`)인데, `executeTool`이 실행 직전 `statedArgs`를 비우므로(`:1414`) 앞 항은 늘 비고, `filledValueLabels`는 `create_schedule`만 다룬다(`:765`). 활동·반복 후보 카드에는 제목조차 없다. (ai A-1 (g), ui B5)
- **왕복 가는 편 캡션이 가리키는 값이 카드에 없다** — `:560` "미리 정해진 출발지가 맞는지…". (ai A-4, ui S3)
- **지어낸 출발지가 보이지 않는다** — 76건 사고는 모델이 출발지를 '회사'로 지어낸 것이고, 이를 막는 것은 프롬프트(`:1193`)와 선언 설명(`:1273`)뿐이며 반복 카드는 모델이 채운 출발지를 보여주지 않는다(`:765`). (ai A-5)
- **깨어난 잠복 결함** — 머무는 반복은 `lastRecurrenceId`를 활동만 있는 그룹으로 둔다(`:1825`). `Store.updateRecurringSeries`는 events만 센다(`Shared/Store.swift:698-700` `recurringSeries`, `:728` 선언). 번호 없는 `update_recurring_schedule`은 0건이 되어 "이미 삭제됐을 수 있어요"(`:2058`)라는 거짓 문구로 끝난다. (ai A-5)
- **머무는 반복의 조용한 버림·이중 질문** — `lunch_*` 인자는 요약(`:1829`)에 나오지 않고 버려진다(ai A-5). 끝 시각이 없으면 모델에게 재호출을 요구하는데(`:1814`) `weeks`는 선언에 없어(`grep -n '"weeks"' Shared/AIAssistant.swift` → `:530`·`:677`·`:1954`뿐) 재호출 때 정화로 빠지고 '반복 기간' 줄이 다시 뜰 수 있다(ui X3).
- **U-2** — 강조 생산자가 둘이다: 값 칩 `EditCardView.swift:116`과 검색으로 고른 값의 칩 `:122-123`(상수 `selected: true`). 관측 경로의 생산자는 `:123`이다. 강조만 끄면 파일 머리말의 약속(`:3-5` "정해진 값도 전부 화면에 보인다")과 긴장한다. 공유 카드를 쓰는 화면은 넷이다(`grep -rn 'EditCardView(' Shared/` → `AIChatView.swift:106`·`AddEventView.swift:68`·`AddActivityView.swift:72`·`ActivityDetailView.swift:64`). (ui §1)
- **문안** — 같은 이름 캡션의 조사('강남역'**가**)·UI 문구에 처음 쓰는 줄표, 후보 캡션의 구현 용어("첫 검색 결과"), 왕복 캡션의 보이지 않는 값. (ui §2.1 S1~S3·S6)
- **`isSamePlace`의 둘째 사용처** — 후보는 머무는 반복 분기에 `isSamePlace(origin, dest)`를 새로 불렀다(`:1812`, 기존 `create_schedule` `:1492`). 그래서 점심 구간 주석 `:1869`의 "(`isSamePlace` 가드는 create_schedule 경로 전용)"은 글자 그대로는 거짓이 됐다(`grep -n 'isSamePlace(origin, dest)\|가드는 create_schedule 경로 전용' Shared/AIAssistant.swift` → `:1492`·`:1812`·`:1869`). 이 주석은 루트 `plan.md:562`·`CHECKLIST.md:535`(base 좌표 `:1654`)가 인용한다. SPEC-UIKIT-005 `spec.md` §3의 "넓히지 않는다"는 그 카드의 범위 판단이었고(0분 통근 가드가 아니라 "고른 좌표가 덮인다"를 닫는 카드), 이 카드는 머무는 반복을 가르는 데에만 가드를 쓴다(spec §3). (감사 1회차 D7)

**통과한 계약 점검**(ai 렌즈 §B): Gemini 와이어 포맷·대문자 스키마(`grep -n '"type": "[a-z]' Shared/AIAssistant.swift` 0건), 새 AI 클래스 없음, `isSamePlace` 본문(`:2538`)과 `create_schedule` 거절(`:1492`) 무변경(호출처는 `:1812`가 늘었다 — 위), `sanitizeModelArgs`(`:819`) 무변경, 프록시 무변경.

### 1.5 가설 H-1~H-10 — run이 먼저 재현한다

아래는 전부 **코드 추적**이고 실행으로 재현되지 않았다. 드라이버가 닿을 수 있는 경로인지도 함께 적었다 — 열 개 모두 도구 실행부·카드 판정 도우미(`drvPark`·`drvExecuteTool`·`drvResolvePendingAsk`·`drvAsk`)로 닿는다.

| H | 가설 | 근거 | 후보에서의 예측 |
|---|---|---|---|
| H-1 | 후보 카드에서 고른 값이 확인 때 버려진다 | §1.3 | 여덟 조합 중 넷 실패, 두 키 동시 모호(머무는 반복 포함)도 실패 |
| H-2 | 두 번째 모호 호출이 카드에 실리지 않고 거짓 안내를 받는다 | `:790-792` | 두 번째 호출의 결과 문구가 "자동으로 진행"을 말하고 카드는 한 장 |
| H-3 | 카드가 열린 동안 인자를 바꾼 재호출이 등록되고, 확인하면 한 건이 더 생긴다 | `:433-434` · `:790` | 같은 요청의 레코드 2건 |
| H-4 | '강남'이 실제 주소 모양에서 채택된다 | `:2686` | `drvTopMatches("강남", name: "서울선릉과정릉", address: "서울 강남구 선릉로100길 1")` = true |
| H-5 | 후보가 첫 렌더에 보이지 않는다 | `:801` · `EditCard.swift:164` | 후보 카드 줄의 `startsOpen` = false |
| H-6 | 활동·반복 후보 카드의 맥락 줄이 비어 제목이 없다 | `:765` · `:805` · `:1414` | `stated`가 빈 배열 |
| H-7 | 왕복 가는 편 줄의 캡션이 가리키는 값이 카드에 없다 | `:557-560` · `:765` | 줄의 `chosen` nil, 캡션·맥락 줄 어디에도 그 값 없음 |
| H-8 | 머무는 반복 뒤 번호 없는 반복 수정이 거짓 문구로 끝난다 | `:1825` · `Store.swift:698-700` · `:2058` | "이미 삭제됐을 수 있어요" |
| H-9 | 머무는 반복의 끝 시각 재호출에서 '반복 기간' 줄이 다시 뜬다 | `:1814` · `:530` · 정화 `:819` | `weeks` 없는 재호출 인자에 기간 줄이 선다 |
| H-10 | 머무는 반복에서 점심 인자가 조용히 버려진다 | `:1812-1830` | 결과 문구에 점심 언급 없음 |

### 1.6 무엇을 보고 판정하나

- 좌표는 화면에 찍히지 않는다. 대리 신호는 **등록된 목적지·활동 장소의 이름과 주소**(상세 화면), **이동시간이 0분인가**, 그리고 **편집 시트의 출발지 칩**이다. 일정 상세는 출발지를 그리지 않으므로(SPEC-UIKIT-007 `plan.md` §6) 출발지는 편집 시트를 열어 보고 "취소"한다.
- 카카오의 실제 응답(선릉·정릉의 주소 문자열, '스타벅스 홍대점'의 첫 결과)은 어느 렌즈도 관측하지 않았다. 드라이버 픽스처의 주소는 가정이고, 시뮬레이터 단계가 실제 값을 본다(AC-014).

## 2. 요구사항 (GEARS)

### 2.1 출발점과 재현

- **REQ-001 (Ubiquitous · Event-driven)**: The run phase shall start from commit `e1a40a6` and shall treat each hypothesis H-1 through H-10 (§1.5) as unverified; when run takes up a hypothesis, it shall first add a guard-driver assertion that exercises that hypothesis's path, run it against the unmodified candidate, and record the observed output — the assertion's ✓/✗ line and the `P/T 통과` line — in `progress.md` §E.2 before changing any code for it; when the assertion passes on the candidate, run shall record the hypothesis as not reproduced and shall make no code change for it. The M1 assertion shall state the desired behavior, so that ✗ on the candidate means reproduced. Where the kickoff gate accepts a reproduced hypothesis instead of fixing it (D-2 (c) for H-4, D-5 (c) for H-3, D-8 (a) for H-9), run shall afterwards rewrite that assertion as a characterization assertion stating the observed behavior, tag its name with `[수용]`, and record "재현됨 — 수용(D-n)" in §E.2 next to the M1 ✗ line; no other assertion shall be rewritten to match observed behavior. 근거 (극성): 이 규칙이 있어야 수용 선택지와 REQ-014의 "✗ 0"이 함께 선다 — 바라는 동작으로 남기면 ✗가 끝까지 남고, 처음부터 관측 동작으로 적으면 후보에서 ✓가 나와 "재현 안 됨"이라는 거짓 기록이 된다(감사 1회차 D4). 근거: 결함 주장은 도구가 확인하기 전까지 가설이다. 두 렌즈 모두 이 결함들을 "코드 추적, 실행하지 않음"으로 적었다. 재현 없이 고치면 고친 것이 결함이었는지 알 길이 없고, 재현 절은 수리 뒤 회귀 방지선으로 남는다. 후보 트리에서 드라이버가 exit 1로 끝나는 것은 이 단계의 기대값이다 — 단 `P/T 통과` 줄이 찍혀야 컴파일 실패와 구별된다(`CLAUDE.md` § 빌드 · 배포의 종료 코드).

### 2.2 U-4 — 후보 카드

- **REQ-002 (Event-driven · Where — D-2)**: When a creation-path place query — `create_schedule` origin or destination, `create_activity` place, outbound origin, or return destination, `create_recurring_schedule` origin or destination — is resolved by search and the top result does not clearly match the query, the executor shall not register and shall open a candidate card carrying up to five candidates; the clear-match predicate shall classify `'스타벅스 홍대점'` against `'스타벅스 대학로점'` at an address of the form `서울 종로구 대학로 116` as not matching, and, where D-2 (a) or (b) is chosen, `'강남'` against `'서울선릉과정릉'` at an address of the form `서울 강남구 선릉로100길 1` as not matching. 근거: 후보 카드 자체는 후보가 이미 구현했다(§1.2). '강남' 사례는 §1.4 수렴 1이다. 빈 주소 픽스처만으로는 이 사례를 닫은 것으로 보지 않는다.

- **REQ-003 (Event-driven)**: When the user picks a candidate on a candidate card and confirms, the record that the confirmation creates shall carry the picked candidate's place for every tool-and-key combination in §1.3, including one call with two ambiguous keys and a staying recurrence whose both keys are ambiguous, and a candidate shown as chosen on the card shall never be discarded at confirmation. 근거: §1.3의 네 조합이 H-1의 예측이다. 수리 방식은 D-3이 정한다.

- **REQ-004 (Unwanted)**: While a candidate card is open, a further creation call that also needs a candidate card shall not receive a tool result claiming it will proceed automatically unless the open card will in fact register it; every call in a turn shall end registered, carried by an open card, or answered with a tool result that states truthfully that it was not registered. 근거: H-2(`:790-792`). 모양은 D-4가 정한다.

- **REQ-005 (Unwanted)**: The candidate-card path shall not produce two records for one user request; in particular, a creation call that runs while a candidate card is open shall not leave a record that the card's later confirmation registers again. 근거: H-3(`:433-434`). 루프를 끝낼지, 열린 카드 동안 등록 호출을 막을지는 D-5가 정한다.

- **REQ-006 (Where — D-6)**: Where D-6 (a) is chosen, the candidate card shall make its preloaded candidates visible on first render without an extra tap; where D-6 (b) is chosen, the candidate card's caption shall name the single action that reveals them; in either case no caption shall describe a screen state that is not true at that moment, and no caption shall use implementation terms such as "첫 검색 결과". 근거: §1.4 수렴 3(H-5).

- **REQ-007 (Ubiquitous)**: Every card the assistant raises for `create_schedule`, `create_activity`, or `create_recurring_schedule` — the card raised before execution and the candidate card alike — shall show in text the title and each place value the model filled that the card does not ask about, and one function shall produce that text for both card paths. 근거: `EditCardView.swift:3-5`의 약속("정해진 값도 전부 화면에 보인다")이 AI 카드의 최소 방어다. 지금은 `create_schedule`만 적고(`:765`) 후보 카드의 앞 항은 늘 빈다(`:805`·`:1414`, H-6). 76건 사고의 지어낸 출발지 '회사'도 이 줄이 있었다면 카드에서 보였다(ai A-5). 한 함수로 두는 것은 계약 5다.

### 2.3 같은 이름 줄 · 왕복 · 머무는 반복

- **REQ-008 (Event-driven)**: When one `create_schedule` or `create_activity` call carries the same search-bound place name in two or more of its place keys, the card shall show a row for each such key with a caption stating why it is asked, and that caption shall attach no particle directly to the quoted name and shall contain no dash; when the shared name is a favorite label or a place already confirmed in this conversation, the card shall not show such rows. The same value in `origin_query` and `destination_query` of `create_recurring_schedule` is the staying-recurrence signal of REQ-010 and is excluded from this rule. 근거: AC-009 7·9번의 수리이며 후보가 구현했다(`:495-505`·`:537-548`). 반복 분기(`:517-530`)에는 같은 이름 줄이 없다 — 그 도구에서 같은 값은 프롬프트(`:1193`)·선언(`:1273`)·`stayingRecurrence`(`:720-725`)가 정한 머무는 반복이라, 같은 이름 줄을 띄우면 REQ-010과 맞선다(감사 1회차 D2). 조사·줄표 규칙은 '강남역'**가** 같은 받침 오류와 UI 문구에 없던 줄표를 막는다(ui §2.1 S1). 드라이버 AA-2의 즐겨찾기 제외 단언(`Tools/GuardDriver.swift:1856-1863`)은 서로 다른 이름 '회사'/'집'을 쓰므로 제외 규칙이 애초에 발동하지 않는다 — 양성 대조가 아니다(ai A-2).

- **REQ-009 (Event-driven · Where — D-7)**: When `create_activity` arrives with a non-empty `return_to_query`, the card shall show the outbound-origin row with the '가는 편 없음' chip, except where that row is raised because the outbound origin is an unknown place; where `travel_from_query` was filled, the row's caption shall name the filled value and the row shall not start selected (D-7 (a)). 근거: 2026-09-24 관측과 후보 `:549-562`. 지금 캡션(`:560`)은 카드 어디에도 없는 값을 확인하라고 한다(H-7).

- **REQ-010 (Event-driven · Where — D-8)**: When `origin_query` and `destination_query` of a `create_recurring_schedule` call carry the same value, the card shall not ask for mode, buffer, or notification lead and shall show in text that the recurrence has no travel; when the origin and destination of that call resolve to places within 50 m of each other, the executor shall create activity blocks only and no travel legs, the tool result shall name any lunch arguments it did not apply, and, when the end time is missing, the tool result shall direct the model to obtain the end time from the user and shall not invite the model to supply one; and no source comment shall state that the `isSamePlace` guard is exclusive to `create_schedule`. 근거: 카드는 실행 전에 문자열로 판정하고(`:525` `stayingRecurrence`), 좌표는 실행 때에야 풀린다(`:1812`) — 한 조건으로 적으면 후보도 권장안도 만족할 수 없다(감사 1회차 D3). 이름은 다르고 좌표만 같은 경우('집'/'우리집')에는 카드가 수단을 묻고 실행부는 구간을 만들지 않는다 — 코드 주석(`:716-719`)이 받아들인 차이이고 잔여 위험으로 둔다. 주석 절은 `:1869`가 후보의 둘째 사용처(`:1812`) 때문에 거짓이 됐기 때문이다(§1.4, 감사 1회차 D7). 실행부(`:1812-1830`)와 카드 억제(`:525-529`)는 후보가 구현했다. 점심 인자 버림은 H-10, `:1814`의 "끝나는 시각을 return_time에 넣어 … 다시 호출해"는 모델이 끝 시각을 스스로 채우게 만드는 문구다(가드 재질문 문구 원칙 — 공용 메모리 `feedback_besir_guard_messages`). 이중 질문(H-9)은 재현 결과를 기록하고 D-8이 처리 방식을 정한다.

- **REQ-011 (State-driven · Event-driven)**: While the most recent recurrence of this conversation (`lastRecurrenceId`) is a staying group, when `update_recurring_schedule` arrives without a series number asking to change mode, buffer, or notification lead, the tool result shall state that the group has no travel legs to change and shall not claim the group may have been deleted. 근거: H-8. `lastRecurrenceId`는 마지막으로 만든 그룹을 가리키므로(`:1825`·`:1841`) 트리거를 "마지막 그룹이 머무는 반복일 때"로 좁혔다(감사 1회차 D16). 이 변경이 도달 가능하게 만든 잠복 경로다(공용 메모리 `feedback_besir_dormant_hazard`). `Shared/Store.swift`는 고치지 않는다(REQ-013).

### 2.4 U-2 — 장소 검색 재오픈

- **REQ-012 (State-driven · Where — D-1)**: Where U-2 is in this card's scope, while the place-search editor is open on a place row that already has a value, no chip on that row shall render as selected and the current value shall remain visible as text on that row; the "searching" predicate shall be computed in one place, the chip rendering function `chip()` shall stay unchanged, and the change shall reach all four screens that use the shared card without per-screen code. 근거: §1.4 U-2. 생산자 둘(`:116`·`:122-123`)이 같은 술어를 읽어야 한다(계약 5). 네 화면은 `fieldRow` → `chip()`을 함께 거치므로 수리 자리는 공유 컴포넌트 하나다. 칩 렌더링의 단일 출처 `chip()`(`EditCardView.swift:265`)은 바꾸지 않는다.

### 2.5 범위 · 게이트 · 문서

- **REQ-013 (Unwanted)**: The change shall not modify repository paths outside its declared set — in run, `Shared/AIAssistant.swift`, `Tools/GuardDriver.swift`, `Shared/EditCardView.swift` (only where D-1 puts U-2 in scope), comment lines of `Shared/EditCard.swift` (only where D-6 (a) is chosen), this SPEC directory (`progress.md` §E.2·§E.3, `spec.md` frontmatter `status`·`updated`), and root `plan.md` limited to plan-versus-reality updates for t16; in sync, `CHECKLIST.md`, root `plan.md`, this SPEC directory, coordinate comments in `Tools/GuardDriver.swift`, and the `progress.md` files of SPEC-UIKIT-005 and SPEC-UIKIT-007 — with the plan-phase paths committed in the plan commit excepted (this SPEC directory, `.moai/reports/t16/plan-lens-ai-tooling.md`, `.moai/reports/t16/plan-lens-ui-design.md`, and `.moai/reports/plan-audit/SPEC-UIKIT-008-*`); and it shall not add a source file, change `proxy/` or `project.yml`, add a tool declaration, parameter key, or schema type, add an AI class, or weaken `isSamePlace`, the `resolveOrigin` fallback ladder, `sanitizeModelArgs`, or the `list_schedules` total count; code paths the candidate introduced that no caller reaches shall be removed. 근거: 계약 1·4·5와 `CLAUDE.md`의 "모델을 바꿨다고 이 방어들을 먼저 걷어내지 않는다". 새 소스 파일이 없으므로 `xcodegen generate`도 서명 계정 리셋도 없다. 렌즈 보고서 둘을 예외에 넣은 것은 오케스트레이터 결정이다 — 이 SPEC이 절 번호로 인용하는 연구 입력이 워크트리 폐기와 함께 사라지지 않게 plan 커밋에 넣는다(감사 1회차 D8). 후보 때문에 생긴 죽은 경로는 둘이다 — ① `resolveOrigin`의 `orDefault` 기본값 `false` 갈래: base에서는 `:1323`·`:1486`·`:1612`가 그 갈래를 불렀으나 후보가 셋을 `resolveOriginAdoption`으로 옮겨(`git show aa7b792:Shared/AIAssistant.swift | grep -n 'resolveOrigin('`) 남은 호출처가 `:2380`(`true`) 하나다. 없앨 것은 이 기본값 갈래뿐이고 `orDefault: true` 사다리(빈 값이면 집 → 현재 위치, `:2589-2593`)와 `resolveOriginAdoption`의 기본값 경로(`:1459`·`:1648`·`:1786`이 부른다)는 남긴다(감사 1회차 D20). ② 후보 카드 맥락 줄의 늘 빈 앞 항(`:805`). 같은 튜플 타입이 다섯 자리에 반복되는 것(`grep -c '(key: String, query: String, candidates: \[Place\])'` → AIAssistant 4 · GuardDriver 1)은 정리 **권고**다(감사 1회차 D15). SPEC-UIKIT-005/007의 `spec.md`·`plan.md`·`acceptance.md` 본문은 sync 레인이 직접 고치지 않는다(REQ-015).

- **REQ-014 (Event-driven)**: When the card is about to leave run, and again when it is about to leave sync, the lane that judges the phase shall itself run, on the final tree, the guard driver by the `CLAUDE.md` recipe (exit 0, a pass count T equal to 241 minus the assertions it removed plus the assertions it added, with the removed and added assertion names recorded in §E.2, no ✗ line, the real-data comparison passed), iOS and macOS builds with fresh DerivedData (`BUILD SUCCEEDED`, zero warnings that name a `.swift` file), the driver compile with a warning set identical to the base's after normalizing line and column numbers (the base's `grep -c 'warning:'` is 24 lines — 12 diagnostics plus 12 caret-context lines, all MapKit·CoreLocation deprecations in `DirectionsService.swift`·`LocationManager.swift`), and `cd proxy && npm test` with every test passing; and it shall measure the per-request fixed token cost by the root `plan.md:230-233` method on `aa7b792` and on the final tree as one pair, keep both outputs under `.moai/state/verify/`, replace the root `plan.md:230` baseline only with that pair's base value, and report the increment. 근거: 이 세션의 게이트는 `e1a40a6`에서만 관측됐다. 프록시 테스트는 `git diff --name-only aa7b792 e1a40a6`에 `proxy/`가 없어 돌리지 않았다 — 갭이다. 토큰은 증분(+122~123)만 같은 방법으로 두 번 쟀고, 절대값은 `plan.md:230`의 4,425와 이전 기록의 base 3,824가 어긋난 채다. 이전 측정 산출물은 `/tmp`에 있어 보존 위치를 벗어났다(ai 렌즈 §B).

- **REQ-015 (Event-driven)**: When sync runs, it shall re-map every live line citation of `Shared/AIAssistant.swift` and `Tools/GuardDriver.swift` in `CHECKLIST.md`, root `plan.md`, and the SPEC-UIKIT-005 and SPEC-UIKIT-007 documents to the final tree by atomic token replacement — a ledger row per citation token (document, old token, the source text it pointed to, new token), each target located in the final tree by content fingerprint rather than by line offset, whole tokens replaced including range ends and bare `:N` tokens resolved through the row's default file — and shall prove zero residue by comparing the ledger's strings against the final tree together with a positive control that shows the comparison catches a planted miss; a citation whose target text this card removed or rewrote shall stay in the ledger as a "대상 제거·재작성" row that records the new text and the REQ or commit that changed it, and is excluded from the byte comparison; citations explicitly anchored to a named historical commit shall stay unchanged, and a citation in a completed SPEC that describes the state before that SPEC's own fix shall not be re-mapped but shall carry an explicit anchor to that SPEC's base commit — for SPEC-UIKIT-005 that is `c5396b3`, covering its AC-005 Given (`:748`·`:1297`·`:1613`·`:2322`·`:2371`·`:2393`) and its AC-009 steps 7·9 (`:1297`·`:1613`). 근거: 오프셋이 구간마다 다르다 — `:494`까지는 그대로이고 그 뒤는 35개 헝크를 따라 제각각 밀린다(§0 표). 파일명이 붙은 인용 토큰 수는 `grep -o 'AIAssistant\(\.swift\)\{0,1\}:[0-9]\{1,4\}' <문서> \| wc -l`로 `CHECKLIST.md` 14 · 루트 `plan.md` 4 · SPEC-UIKIT-005 `spec.md` 6·`plan.md` 1·`progress.md` 3 · SPEC-UIKIT-007 `spec.md` 1이고, `GuardDriver` 파일명 토큰은 같은 명령으로 `CHECKLIST.md` **1**(`:619`의 `GuardDriver.swift:264`), 나머지 0이다 — 그 1건도 후보가 이미 밀었다(base `:264` = `setenv("CFFIXED_USER_HOME", …)`, head에서는 `:275`, 감사 1회차 D9). SPEC-UIKIT-005의 여섯 좌표는 `c5396b3`에서는 서술과 맞고 `aa7b792`에서는 모두 다른 줄이며, 그중 `:748`의 원문(`confirmedPlaces[place.name] = place`)은 005의 수리로 사라졌다 — 지문으로 찾을 대상이 없는 행이라 재사상하지 않고 고정한다(감사 1회차 D7). 이 SPEC의 `acceptance.md`가 AC-009 7·8번 단계를 현재 좌표로 다시 적으므로 운영자는 005의 옛 좌표에 기대지 않는다. `:1869` 주석은 REQ-010이 고쳐 쓰므로 그 주석을 가리키는 루트 `plan.md:562`·`CHECKLIST.md:535`의 인용은 "대상 제거·재작성" 행이 된다. 파일명 없는 맨몸 `:N` 인용은 이 계수에 잡히지 않는다 — t15에서 파일명 계수 18이 실제 87이었다(공용 메모리 `feedback_besir_refactor_breaks_citations`). 완료된 SPEC-UIKIT-005/007의 `spec.md`·`plan.md`·`acceptance.md` 본문 인용은 sync가 원장을 만들고, 편집은 오케스트레이터가 `manager-spec`에 재위임한다(본문 소유권).

## 3. 범위 밖

### Out of Scope — `update_schedule`의 `new_place_query` (D-9)

- 수정 경로도 첫 결과를 그대로 채택한다(`Shared/AIAssistant.swift:2430-2431`). 저장된 데이터를 바꾸는 쓰기 경로라 U-4와 같은 부류다(ai 렌즈 §D 2).
- 관측된 실패가 없고, 넣으면 보류 카드·확인 주입 조합이 수정 경로에 하나 더 생긴다. 권고는 이 카드 밖이다 — D-9가 정한다.

### Out of Scope — O-1 `Store.modifyEvent`의 출발지 대체 (카드 C11)

- `CHECKLIST.md` C7 항목(`:530-535`)이 t7발 O-1 가설을 함께 적었으나 카드 t16 본문에는 없다. `day-close-20260924.md` §6 8b가 이미 카드 C11로 배치했다.
- 넣으면 `Shared/Store.swift`가 다섯째 파일이 되어 한 Day 한도를 넘는다.

### Out of Scope — 점심 장소의 되묻기

- `lunch_place_query`는 후보 카드를 열지 않고 첫 결과를 쓴다(`:1876-1878` 주석 — 실패·틀린 지점이 결과 문구에 이름으로 드러나고 통근 전체를 멈춰 물을 자리가 아니다). 이 경계를 유지한다(D-9 (a)).

### Out of Scope — `isSamePlace`를 통근 반복의 0분 가드로 넓히기

- 이 카드가 `create_recurring_schedule`에서 `isSamePlace`를 쓰는 것은 **머무는 반복을 가르는 데**뿐이다(REQ-010, `:1812`). 출발지≈목적지인 통근 반복을 거절하는 가드로 넓히지 않고, `create_activity`에도 넣지 않는다.
- SPEC-UIKIT-005 `spec.md` §3("`isSamePlace` 가드의 적용 범위 확대 — 넓히지 않는다", `:237-240`)은 그 카드의 범위 판단이었다. 이 카드의 사용은 그 판단과 다른 목적이라 충돌하지 않으며, 거짓이 된 `:1869` 주석은 REQ-010이 고친다.

### Out of Scope — 브랜드 단일어의 채택 한계

- '스타벅스' 한 낱말은 어느 지점이 와도 "확실히 맞다"로 채택된다(ai A-1 (b) 표). 판정 술어의 설계 한계이며 같은 이름 줄(REQ-008)이 일부만 덮는다. 잔여 위험으로 기록한다.

### Out of Scope — 끝 시각 카드 줄 · 머무는 반복 전용 도구

- 끝 시각을 카드 줄로 묻는 일은 `EditField` 종류·`EditCard`·`EditCardView`·실행부가 함께 바뀌어 파일 한도를 넘는다. 전용 도구는 선언을 늘려 요청당 고정 토큰비를 올린다. 둘 다 D-8의 채택하지 않은 안으로 남는다.

### Out of Scope — Theme 대비 · VoiceOver 중복 낭독 · AI 호출 실패 폴백

- 줄 이름(`Theme.faint`)이 캡션(`Theme.muted`)보다 흐린 대비(ui B2 — 밝은 모드 1.79:1)는 기존 후보 A5(Theme 고대비)의 몫이다. 이 카드가 근거를 더할 뿐 토큰을 바꾸지 않는다.
- 줄 컨테이너 라벨과 자식 Text가 긴 캡션을 두 번 읽을 가능성(ui §2.4)은 실기기 확인 항목이다.
- 뒤이은 AI 호출이 실패하면 모델용 도구 결과 문구가 말풍선에 그대로 보이는 폴백(`:385`)은 기존 패턴 전반의 문제다.

### Out of Scope — U-1 편집 카드 통일 · U-3 대화 메모리

- 각각 카드 C8(대형)·C9(장기)로 배치됐다(`day-close-20260924.md` §7).

## 4. 결정 — 미해소

착수 승인 게이트에서 운영자가 정할 결정은 10건이다(D-1 U-2 범위와 모양 · D-2 채택 판정 · D-3 확인 주입 수리 · D-4 다중 호출 · D-5 보류 뒤 루프 · D-6 후보 노출 · D-7 왕복 재확인 · D-8 머무는 반복의 표현 · D-9 되묻기 적용 범위 · D-10 문안). 선택지·권고·바뀌는 REQ/AC는 `plan.md` §2에만 적는다. Tier M 확인도 같은 게이트에서 한다.

## 5. 관련 문서

- 칸반 카드 **t16** 본문(`moai todo`) · `.moai/reports/day-close-20260924.md` §6 #21·#23·#24, §7 C7
- 연구 입력: `.moai/reports/t16/plan-lens-ai-tooling.md` · `.moai/reports/t16/plan-lens-ui-design.md` · 후보의 자기 기록 `.moai/reports/t16/progress.md`(무변경)
- [SPEC-UIKIT-005](../SPEC-UIKIT-005/spec.md) — 확정 장소의 이름-키 충돌 수리(B안). `acceptance.md` AC-009가 이 카드 7·9번 관측의 출처다
- [SPEC-UIKIT-007](../SPEC-UIKIT-007/spec.md) — 편집 시트가 저장된 출발지를 보여주게 된 수리. 출발지 판정을 편집 시트로 하는 근거다
- [SPEC-UIKIT-003](../SPEC-UIKIT-003/spec.md) — AC-010 2단계가 U-2가 관측된 자리다
- [SPEC-ASK-001](../SPEC-ASK-001/spec.md) — 앱 주도 되묻기 카드의 원 설계

🗿 MoAI
