---
id: SPEC-UIKIT-011
title: "장소 채택 항상-선택 — 검색에서 온 장소는 사용자가 고를 때만 확정 · 재시도 병합 삭제 · 쓰기 경로(수정 새 장소·반복 점심)와 조회 경로(식사 추천 기준·이동시간 조회) 선택 카드 · 드라이버 AI절 재설계와 R-5"
version: "0.2.0"
status: completed
created: "2026-10-06"
updated: "2026-10-07"
author: "manager-spec"
priority: P1
phase: "Phase 1.7 — 일정·활동 화면 UI 통일"
module: "shared-ai"
lifecycle: spec-anchored
tags: "place-adoption, always-select, candidate-card, dedup-coordinate, retry-removal, update-schedule, recurring-lunch, lookup-card, guard-driver, r-5"
tier: M
related_specs: [SPEC-UIKIT-008, SPEC-UIKIT-009]
kanban_card: t47
---

# SPEC-UIKIT-011 — 장소 채택 항상-선택

## HISTORY

| 버전 | 날짜 | 변경 |
|---|---|---|
| 0.1.0 | 2026-10-06 | 최초 작성. 칸반 카드 **t47**(`moai todo` 본문 — 운영자 지시 2026-10-06, 루트 `plan.md` 후속 31·32·33 통합)을 GEARS로 정식화했다. **SPEC 번호 010은 쓰지 않는다** — 반려된 t45(SPEC-UIKIT-010, `status: rejected`)의 기록은 `.moai/reports/t45/`에 보존돼 있다. 기준 트리는 `d900a78`(브랜치 `WT-always-select`)이고, 코드는 t42 병합 `4987e2d`와 바이트가 같다(`git diff --quiet 4987e2d HEAD -- Shared Tools proxy project.yml` → exit 0). 줄번호는 이 트리에서 명령으로 쟀다고 적었으나 **다섯 자리가 틀렸다**(`:1087`·`:1092` — 0.1.1에서 정정). 명령과 출력은 `progress.md` §E.1 표에 있다. 미해소 결정은 `plan.md` §2에만 게이트 표식으로 둔다(이 프로젝트 관례 — SPEC-UIKIT-005 HISTORY 0.1.0). |
| 0.1.1 | 2026-10-06 | **plan 감사 1회차(FAIL 0.75, `.moai/reports/plan-audit/SPEC-UIKIT-011-review-1.md`) 반영.** 코드는 무변경이고 REQ 15 · AC 13 · 게이트 표식 6건 그대로다(MF-1 — 결정 D-1~D-6은 운영자 몫이라 표식을 지우지 않았다). **MF-2** `adoptPlace` 사다리 인용 `:1087`·`:1092`를 `:3087`·`:3092`로(이 파일 §1.2·§2 A·REQ-005·REQ-010, `plan.md` §7). 그 뒤 세 문서(spec·plan·acceptance)의 맨몸 `:N` 인용(0.1.1 기준 167종 — 정정 기록 속 `:1087`·`:1092` 포함)을 가리키는 파일의 해당 줄을 출력해 대조했고, 어긋남을 둘 더 찾아 고쳤다 — `PlaceSearch.swift`의 MapKit `try?`는 `:121`이 아니라 `:122`(plan §7·acceptance 경계표·research·progress), `executeCreateRecurringSchedule` 선언은 `:2116`이 아니라 `:2115`(research §4). research의 나머지 인용은 표본만 대조했다(`progress.md` 0.1.1 표). **MF-3** AC-009 문구 행을 고정 부분 문자열 계수로 바꾸고 기준값을 실측했다. **MF-4** 시뮬레이터 입력문을 발화 파서가 잡는 꼴(`지하철로`·`여유 10분`·`알림 10분 전`)로 바꾸고 실행 전 카드 단계를 기대에 넣었다 — 코드 읽기 가설임을 스크립트 머리에 적었다. **MF-5** 앱 변경량을 `plan.md` §3 표의 합 하나(삭제 약 100 · 추가 약 60 · 고쳐 쓰기 약 40줄, 어림)로 통일했다. 권고 A-1(REQ-009 맥락 줄에 〔제안〕) · A-2(카드 장수) · A-3(AC-008 대조 대상) · A-4(`resolveDestination`의 `creation` 매개변수) · A-5(주석 `:34`·`:912-917`) · A-6(REQ-003 문구) · A-7(AI-19 픽스처) · A-8(MX ANCHOR) · A-9(research 열쇠 서술) · A-10(빈 바인딩)을 모두 반영했다. |
| 0.1.2 | 2026-10-06 | **plan 감사 2회차(FAIL 0.86, `.moai/reports/plan-audit/SPEC-UIKIT-011-review-2.md`) 반영.** 이 파일의 요구사항 본문은 무변경이고 REQ 15 · AC 13 · 게이트 표식 6건 그대로다(D-1~D-6은 운영자 결정 대기). **N-1** `create_schedule`은 제목이 비면 [제목] 줄을 세우고(`Shared/AIAssistant.swift:505`) 프롬프트가 모델에게 말하지 않은 제목을 비우라고 지시하므로(`:1463`), 시뮬레이터의 모든 등록 입력에 `제목은 …`을 넣고 스크립트 머리·`plan.md` §7·§9에 제목 줄 사유를 더했다(코드 읽기 가설, 실행 확인 전 표기 유지). **N-2** 결정 D-3 (c)(맥락 줄 없음)면 AI-18 (b)가 빠진다는 분기를 `acceptance.md` AC-005·AC-011 2와 `plan.md` §5에 넣었다 — 총수는 D-5 × D-3 조합으로 488 · 487 · 496 · 495. 권고 **B-1**(AC-011 4에 `resolveDestination`의 `creation` 선언·본문 계수) · **B-2**(AC-008의 이름 대조 한계와 보강 세 겹) · **B-3**(D-6에 (a) Tier M 확인 / (b) 다른 Tier 표) · **B-4**(`askFields` 인용 `:553-557` → `:555-557`)를 반영했다. |
| 0.2.0 | 2026-10-06 | **착수 승인에서 운영자가 결정 D-1~D-6을 확정해 결정에 기대는 절만 고쳐 썼다**(plan 감사 3회차 조건 — 재감사 없음, 고친 절의 차이만 대조). 결정: D-1 **(b) 조회도 카드**(작성자 권장안 (a)가 아니라 **운영자 선택**) · D-2 (a) 카카오 순서 · D-3 (a) 제안 원문(수정 카드 맥락 줄 포함) · D-4 (a) 첫 저장 직전 · D-5 (a) 죽은 코드 삭제 · D-6 (a) Tier M·파일 2. 같은 자리에서 운영자는 §3 마지막 줄(같은 대화에서 원래 질의를 다시 말하면 다시 묻는다)을 **의도된 동작**으로 두었다. **D-1 (b)의 파급**: 이 파일의 §1.1에 조회 행을 더했고 §1.2·§1.3 (가)(바)를 고쳤으며, **REQ-012를 "조회도 카드" 요구사항으로 다시 썼다**(식사 추천 기준 장소 `place_query`·이동시간 `origin_query`/`destination_query`). REQ-009는 줄 재료에 `place_query`(식사 추천, 줄 이름 `기준 장소`)를 더했고, REQ-013·REQ-014·REQ-015·§3·§4·§5가 따라 바뀌었다 — **`resolveDestination`·`resolveOrigin`은 호출처가 전부 삼태로 옮겨가 통째로 지운다**(REQ-014). REQ 15 · AC 13은 그대로다. 결정 분기("D-n (a)면 …")는 확정안만 남기고 접었다 — 따라서 감사 3회차 권고 **C-1**("추가 11"의 D-3 (c) 단서)은 D-3이 (a)로 닫혀 단서 자체가 사라졌다(추가 단언은 D-1 (b)의 4건을 더해 15). 권고 **C-2**는 `acceptance.md` AC-008에 반영했다. 게이트 표식은 `plan.md` §2의 6건이 0건이 됐다. |

## 0. 이 SPEC의 성격과 예산

**운영자가 방향을 정한 변경의 계약이다.** 무엇을 바꿀지는 카드 본문의 운영자 지시 다섯 항(①~⑤)과 자동 유지 경계가 정했고, 착수 승인에서 운영자가 정한 결정 D-1~D-6(`plan.md` §2)이 지시만으로는 정해지지 않던 자리를 닫았다. 이 SPEC은 그 지시와 결정이 코드에서 닿는 자리를 적는다. 지시와 결정은 다시 묻지 않는다.

**Tier: M.**

| 측정 | 값 | 세는 명령 |
|---|---|---|
| 바꾸는 소스 파일 | **2** — `Shared/AIAssistant.swift`(3258줄) · `Tools/GuardDriver.swift`(5068줄). 새 파일 없음 | `wc -l` |
| 앱 쪽 변경 어림 | 삭제 약 130 · 추가 약 90 · 고쳐 쓰기 약 30줄(측정 아님 — `plan.md` §3 표의 합) | `plan.md` §3 |
| 드라이버 쪽 변경 어림 | 단언 삭제 15 · 추가 15 · 반전 3 · 정리(R-5) 4 | `plan.md` §5 |
| REQ · AC | **15 · 13** — Tier M 상한 16 아래 | `grep -c '^- \*\*REQ-' spec.md` · `grep -c '^## AC-' acceptance.md` |

Tier S(300줄 미만·결정 없음)를 넘는 이유는 셋이다. 쓰기 경로 다섯(등록 세 도구 + 수정 + 반복 점심)과 조회 경로 둘(식사 추천 기준 장소 + 이동시간 조회, 결정 D-1 (b))의 동작이 바뀌고, 그중 반복 점심은 해석 위치를 첫 저장 **앞으로** 옮기는 구조 변경이며(§1.3 (나)), 사람만 볼 수 있는 증거(실제 카카오 목록·카드 화면)가 `acceptance.md`의 시뮬레이터 절을 요구한다. 크게 고치는 파일은 2개라 한 Day 한도(3~4) 안이다.

**드라이버 초록은 이 SPEC의 증거로 반만 센다.** 드라이버는 판정 함수와 카드 조립·확인 경로를 모델·카카오 없이 직접 부른다. 실제 카카오 목록의 모양과 순서, 카드 화면, 모델이 카드 뒤에 무엇을 말하는지는 시뮬레이터에서만 보인다(AC-012·AC-013). 이 프로젝트에는 드라이버 88/88 다음 날 실기기 결함 7건이 나온 이력이 있다(2026-09-15).

## 1. 배경

### 1.1 운영자 지시 (카드 t47 본문, 2026-10-06)

원문은 `moai todo`의 t47 행이다. 아래는 항목 번호와 요지이고, 출처는 전부 **운영자 지시**다 — 다만 "조회" 행은 카드 본문이 아니라 착수 승인에서 운영자가 정한 결정(D-1 (b))이다.

| 항 | 지시 | 코드에서 닿는 자리 |
|---|---|---|
| 원칙 | 카카오 검색에서 온 장소는 항상 그 결과를 그대로 보여주고 사용자가 하나를 골라야 확정한다 — 조용한 확정 전면 폐지 | `adoptPlace` `:3081` → `placeAdoptionDecision` `:3172` |
| ① | 유일 일치 갈래(이름 포함 판정) 제거 — 판정 갈래 재설계 | `:3177-3184` |
| ② | 후보 중복 제거 키를 이름 → 이름+좌표로(같은 이름 다른 좌표 지점도 각각 칩) | `:3185-3187` |
| ③ | 쓰기 경로(수정의 새 장소·반복 점심)도 같은 선택 카드 — unclear를 첫 후보로 평탄화하던 것 제거 | `:2813` · `:2250` |
| 조회 (착수 승인 D-1 (b)) | 조회 경로(식사 추천의 기준 장소·이동시간 조회의 출발지·목적지)에도 같은 선택 카드 — 조회는 저장하지 않지만 "검색에서 온 장소는 사용자가 고를 때만 쓴다"를 글자 그대로 적용한다. 식사 추천의 기준 장소 줄 재료도 새로 만든다 | `:2703` · `:2762` · `:2765` |
| ④ | 정확 일치 단일 결과조차 묻는다("글자 그대로 항상") | `:3176` |
| ⑤ | 재시도 병합(t42 ②) 삭제 — 접미 뗀 재검색·병합 없이 카카오 원결과를 그대로. 사용자가 질의를 고치는 몫은 카카오맵과 같다. 빈 결과는 지금처럼 notFound | `:3094-3104` · `suffixStrippedRetryQuery` `:3148` · `mergedPlaceResults` `:3195` |
| 경계 | 자동 유지: 즐겨찾기 · 같은 대화에서 이미 확정한 장소 재사용(SPEC-UIKIT-008 REQ-008) · 현재 위치 | `locallyResolvedPlace` `:1358` · `currentLocationToken` `:2966` |
| 일관성 | 환승역 노선 갈림 질문은 그대로 둔다 — 좌표 근접 "같은 장소" 갈래를 만들지 않는다(t45 반려) | — |
| 동반 부채 | R-5: 드라이버 AI-2·4·5·8의 `drvAdoption` 이중 호출을 `let`으로 묶는다(살아남는 블록 기준). AI-3 픽스처 간격 조정은 근접 확정 폐기로 불필요 — plan이 확인 뒤 정리 | `Tools/GuardDriver.swift:4966-5018` |

### 1.2 지금의 사다리 (기준 트리 `d900a78`, 코드 열람)

`adoptPlace`(`:3081-3110`)는 ① 즐겨찾기·확정 사전(`locallyResolvedPlace` 호출, `:3087`) → ② 등록 경로의 일반명사 가드(`:3092`) → ③ 카카오 검색(`:3093`) → ④ 첫 결과가 비었거나 이름 낱말을 만족하지 않으면 접미를 뗀 질의로 한 번 더 검색해 병합(`:3098-3104`) → ⑤ `placeAdoptionDecision`(`:3172`)의 삼태로 끝난다. 판정은 **정확 일치**(`:3176` — 정규화한 질의 = 정규화한 첫 결과 이름이면 확정)·**유일 일치**(`:3181-3184` — 첫 결과가 낱말을 만족하고 나머지 만족 결과가 전부 첫 이름을 품으면 확정)·**그 외 unclear**(`:3185-3188` — 만족 결과 먼저, 정규화 이름으로 중복 제거, 5건까지)다.

삼태를 받는 곳은 두 갈래다.

- **등록 세 도구는 이미 묻는다.** `create_schedule`(`:1749-1775`)·`create_activity`(`:1928-1962`, 장소 줄 셋)·`create_recurring_schedule`(`:2154-2181`)은 `unclear`를 모아 `parkForUnclearPlaces`(`:918`)로 후보 카드를 연다. 그래서 판정이 검색 결과에 대해 `resolved`를 내지 않게 되면 이 세 경로는 새 카드 코드 없이 묻는다.
- **평탄화하는 곳은 넷이다.** `resolveDestination`(`:3206-3212`)과 `resolveOrigin`(`:2953-2960`)은 `unclear → candidates.first`다. 그 호출처 가운데 **쓰기** 둘은 반복 점심(`:2250`, `creation: true`)과 수정의 새 장소(`:2813`)이고, **조회** 둘은 식사 추천의 기준 장소(`:2703`)와 이동시간 조회(`:2762`·`:2765`)다. 카드는 쓰기 둘만 적었고, 조회 둘도 카드로 묻기로 착수 승인에서 정했다(D-1 (b)). 그래서 이 SPEC 뒤에는 **호출처 다섯이 전부 삼태를 직접 받고** 두 래퍼는 호출처가 없어진다(REQ-014).

### 1.3 이 SPEC이 조사로 찾은 것 (카드 본문에 없던 것)

(가) **수정·점심·식사 추천 줄은 지금의 카드 재료로 서지 않는다.** `placeRow(key:)`(`:746-754`)는 모르는 키를 `destinationField()`(`:752`)로 떨어뜨려, 키가 `"destination_query"`인 줄을 만든다. `parkForUnclearPlaces`는 줄을 `item.key`로 찾아 바꾸거나 덧붙이고(`:942-943`) 비운 키를 `clearedKeys`로 남기는데(`:950`), 확인 주입은 **줄 키가 `clearedKeys`에 든 장소 줄에만** 고른 값을 싣는다(`:1238`). 그러니 `new_place_query`·`lunch_place_query`를 그대로 넘기면 "목적지" 줄이 뜨고, 고른 값은 비운 키에 실리지 않는다 — 반복 도구에서는 진짜 목적지 줄과 키가 겹친다. 두 키 각각의 줄 재료가 필요하다(REQ-009). **조회 도구(D-1 (b))도 같다.** 이동시간 조회의 `origin_query`·`destination_query`는 기존 출발지 줄(`originField` `:644`)·목적지 줄(`destinationField` `:659`)이 그대로 맞지만, 식사 추천의 `place_query`는 키가 활동 등록과 겹쳐 `activityPlaceField()`(`:669-673`, 줄 이름 "활동 장소")로 떨어진다 — 식사 추천 카드가 "활동 장소"라고 뜨면 거짓이다. `placeRow(key:)`가 키만 보므로 도구를 알아야 갈린다(REQ-009). 반면 확인 주입 자체는 도구 이름을 보지 않으므로(`:1238-1247`) 수정 도구에도 그대로 쓴다. 맥락 줄 함수 `filledValueLabels`(`:886-910`)는 수정 도구에서 아무것도 내지 않는다(`title` 키가 없고 `switch`의 `default`) — 수정 카드는 무엇을 고치는지 적지 않은 채 뜬다(SPEC-UIKIT-008 H-6과 같은 모양).

(나) **반복 점심은 첫 저장 뒤에 해석된다.** 점심 장소 해석(`:2250`)은 통근 구간(`:2202`)·복귀 구간(`:2220`)·체류 활동(`:2228`)을 **이미 저장한 뒤**다. 그 자리에서 카드를 세우면 확인이 도구 전체를 다시 실행하므로(`resolvePendingAsk` → `runToolCalls`, `:1318-1319`) 통근 묶음이 한 벌 더 생긴다. 점심 해석은 첫 저장 앞으로 옮겨야 하고(REQ-008), 머무는 반복(`makeStayingRecurrence`, `:2084`)은 점심을 쓰지 않으므로(`:2104-2106` 안내) 그 갈래에서는 점심을 검색하지 않아야 한다.

(다) **같은 이름 다른 좌표의 확정은 이미 갈린다.** 후보를 고르면 `choose(field:place:)`(`:1063-1067`)가 `confirmedPlaceKey`(`:1083-1092`)로 사전 열쇠를 정한다 — 이름이 다른 좌표에 점유돼 있으면 "이름 · 주소", 그다음 "이름 · 좌표" 열쇠로 넘어간다(50 m `isSamePlace`로 같은 지점이면 같은 열쇠). 그래서 한 카드의 두 줄이 같은 이름 다른 좌표 지점을 각각 골라도 사전에서 서로를 덮지 않는다. 중복 제거 키에 좌표를 넣어 같은 이름 칩이 둘 이상 뜨는 것은 이 열쇠 사다리가 받는다 — 새 결함이 아니라 지켜야 할 회귀선이다(REQ-010). 칩 화면은 `ForEach(places, id: \.self)`(`Shared/EditCardView.swift:349`)이고 `Place`는 이름·주소·위도·경도 전체가 `Hashable`이라(`Shared/Models.swift:111-116`) 이름+좌표가 같은 두 항목이 남지 않는 한 같은 id가 생기지 않는다. 주소는 칩 아래 줄에 보인다(`EditCardView.swift:365-367`).

(라) **사라지는 갈래에 기대던 다른 소비처는 없다.** `PlaceAdoption.resolved`의 소비처를 따라갔다 — 등록 세 도구의 `isSamePlace` 판정(`:1782`·`:1970-1976`·`:2195`)은 해석이 끝난 두 좌표를 보므로 카드 뒤 확정 좌표에서 그대로 성립하고, 확인 경로의 50 m 판정(`stayingTokenForColocatedPick`, `:1333-1353`)은 처음부터 로컬 두 단(`locallyResolvedPlace`)만 본다. 검색 결과를 조용히 확정해야만 성립하던 판정은 찾지 못했다(`research.md` §3).

(마) **문구 둘이 거짓이 된다.** 후보 줄 캡션(`unclearPlaceNote`, `:852-854` — "검색 결과가 말씀하신 지점인지 확실하지 않아요")과 모델에게 돌려주는 문구(`:957` — "이름이 다른 곳이나 같은 이름의 여러 지점으로 보여요")는 정확 일치 단일 결과를 물을 때 사실이 아니다. 중복 가드 문구(`:924`)와 `:957`은 "등록"을 말해 수정 도구에는 맞지 않는다. 주석도 옛 갈래를 설명한다(`:3065-3069`·`:2247-2249`·`:3094-3108`, 보류 카드 설명 `:912-917`의 "검색 첫 결과가 이름과 맞지 않아", 목록 타입 설명 `:34`의 "실행부 셋" — 수정·식사 추천·이동시간 조회가 보류 실행부로 늘어난다). 지워지는 두 래퍼의 주석(`:2943-2952`·`:2957`·`:3202-3205`)은 함수와 함께 사라지고, 래퍼 이름을 가리키는 남은 주석 넷(`:640`·`:2301`·`:2962`·`:3046`)은 이름이 없어지므로 고쳐 쓴다(REQ-011).

(바) **D-1·D-2의 상호작용은 D-1 (b)가 닫았다.** 후보 순서를 제공자 순서로 두면(결정 D-2 (a)) 조회 경로의 평탄화가 고르던 첫 후보는 제공자 첫 결과가 된다 — 지금은 정확·유일 일치면 첫 결과, unclear면 **낱말을 만족하는 결과 먼저** 재정렬한 목록의 첫 항목이라, 루트 `plan.md:585`가 적은 '강남' 사례(서울선릉과정릉 → 강남역 2호선)는 그 재정렬 덕에 맞았다. 운영자가 조회도 카드로 정했으므로(D-1 (b)) 조회에는 평탄화가 없고, 제공자 순서는 카드의 칩 순서로만 보인다 — 조회 답의 장소를 제공자 첫 결과가 조용히 정하는 길이 없어진다.

### 1.4 이웃 카드

| 카드 | 관계 |
|---|---|
| t32 (C22) | 한 턴의 여러 호출 중 하나가 후보 카드를 세우면 나머지 호출의 요약이 말풍선 없이 버려진다(`runLoop` `:452`, 중복 가드 `:923-925`). 이 SPEC 뒤에는 검색으로 푸는 장소가 **항상** 카드를 세우므로 그 경로를 지나는 빈도가 오른다. 고치지 않는다 — 겹침만 적는다(§4). |
| t30 (C21) | AI 카드 문법 통일. ⑥(가는 편 재확인 줄을 확정 장소·즐겨찾기면 다시 띄우지 않기)은 이 SPEC의 자동 유지 경계와 같은 기준이지만 줄 판정(`askFields`) 쪽이라 이 SPEC이 건드리지 않는다. |
| t35 (C25) | 확인 경로 후보 카드가 카드#1에서 답한 왕복 가는 편 출발지를 되묻는다. 이 SPEC 뒤 후보 카드가 늘면 같이 자주 보인다 — 고치지 않는다. |
| t44 | `AIAssistant.swift` 인용 재사상. 이 SPEC이 같은 파일의 줄을 지우고 옮기므로 t44의 원장이 다시 밀린다 — 순서는 리드 몫(`plan.md` §6). |
| t45 (반려) | 좌표 근접 확정. 운영자가 전제를 거부했다("애초에 굳이 같은 장소로 보지 않음") — REQ-006이 그 결정을 이 SPEC의 금지로 옮긴다. |

## 2. 요구사항 (GEARS)

### [DELTA] A 채택 판정

- [EXISTING] 사다리 앞 두 단(즐겨찾기·확정 사전 `:3087`)과 일반명사 가드(`:3092`), 빈 결과의 notFound(`:3173`) — 그대로 둔다.
- [MODIFY] `placeAdoptionDecision`(`:3172-3189`) — 검색 결과가 있으면 언제나 unclear.
- [REMOVE] 접미 재시도·병합 블록(`:3094-3104`) · `suffixStrippedRetryQuery`(`:3143-3155`) · `mergedPlaceResults`(`:3191-3200`).

- **REQ-001 (Ubiquitous · Unwanted)**: The place adoption shall not adopt any provider search result without the user's pick: when the provider search for a query returns one or more results, the adoption shall be the ask state carrying candidates, including when the only result's name equals the query exactly. 근거: 운영자 원칙·①·④("글자 그대로 항상"). 지금은 정확 일치(`:3176`)와 유일 일치(`:3181-3184`) 두 갈래가 검색 결과를 조용히 확정한다. 등록 세 도구는 ask 상태를 이미 카드로 보내므로(§1.2) 이 판정만 바꾸면 그 경로들이 묻는다.

- **REQ-002 (Ubiquitous)**: The candidate list shall be the provider's results with duplicates removed by a key of name plus exact coordinate, so that results with the same name and different coordinates each remain as a candidate, in the provider's own order, and capped at the existing suggestion limit of five. 근거: ②와 결정 D-2 (a). 지금 키는 정규화 이름(`:3187`)이라 같은 이름 다른 좌표 지점과 접미만 다른 이름이 하나로 접힌다(루트 `plan.md:584` 후속 32 — t42 sync 실행 재현). 상한 `maxPlaceSuggestions = 5`(`:1097`)는 카드 안 검색(`:1121-1122`)과 같은 값이라 바꾸지 않는다. 순서는 제공자 순서 그대로다 — 운영자가 D-2 (a)로 확정했다(문구 "그 결과를 그대로"). 앱이 낱말 만족 결과를 앞당기던 재정렬(`:3186-3187`)은 없어진다.

- **REQ-003 (Unwanted)**: The place adoption shall make at most one call to the place-search service per query and shall not search again with a suffix-stripped query or merge any second result list; the place-search service's own fallback from Kakao to MapKit inside that one call stays as it is. 근거: ⑤. 한 번의 호출 안에서 카카오가 비거나 실패하면 MapKit으로 넘어가는 폴백(`Shared/PlaceSearch.swift:13-18`)은 운영자가 "현행 그대로"라 한 빈 결과 처리의 일부이고 이 SPEC 밖이다(§4). 운영자 취지 원문(카드): "차후 카카오맵 검색 기능이 개선될 경우 우리 재시도 보강이 그 개선과 충돌해 엉뚱한 결과를 낼 수 있으므로 제공자 원결과 통과가 원칙". 지금은 질의 하나에 검색이 최대 2회다(`:3093`·`:3102`).

- **REQ-004 (Event-driven)**: When the provider search for a query returns no result, the place adoption shall report not-found as it does today, and shall not fall back to any default place. 근거: ⑤ 끝 문장 "빈결과는 현행 notFound 그대로". `:3170-3173`.

- **REQ-005 (State-driven)**: While a query resolves from a favorite, from a place already confirmed in the current conversation, or from the current-location token, the app shall use that place without a provider search and without a candidate card. 근거: 운영자 자동 유지 경계. 즐겨찾기·확정 사전은 `locallyResolvedPlace`(`:1358-1363`)가 검색 앞에서 풀고(`:3087`), 현재 위치는 `resolveOriginAdoption`(`:2966-2968`)과 활동의 `resolve`(`:1948-1951`)가 검색 없이 푼다. 카드에서 후보를 고르면 그 장소가 확정 사전에 들어가므로(`:1063-1067`) 확인 뒤 재실행이 이 경계로 풀린다(REQ-010).

- **REQ-006 (Unwanted)**: The place adoption shall not treat two different provider results as one place by coordinate proximity or by name containment, so that results the provider returns separately — such as the separate route entries of a transfer station — remain separate candidates. 근거: t45 반려(운영자 2026-10-06 — "애초에 굳이 같은 장소로 보지 않음", `.moai/reports/t45/plan-progress.md` 반려 결정 절). 이름 포함 판정(유일 일치)은 ①이 지우고, 좌표 근접 갈래는 만들지 않는다. 같은 이름+같은 좌표의 완전 중복만 REQ-002의 키로 접힌다.

### [DELTA] B 쓰기 경로 — 수정의 새 장소 · 반복 점심 (줄 재료는 조회 경로 D와 공유)

- [EXISTING] 후보 카드 조립(`parkForUnclearPlaces` `:918`)과 확인 주입(`resolvePendingAsk` `:1207`, 비운 키 주입 `:1238-1247`) — 도구 이름을 보지 않는 부분은 그대로 쓴다.
- [MODIFY] `executeUpdateSchedule`의 새 장소 해석(`:2811-2815`) · `executeCreateRecurringSchedule`의 점심 해석 위치(`:2242-2267`) · `placeRow`(`:746-754` — 키에 더해 도구를 받는다) · `filledValueLabels`(`:886-910`).
- [NEW] `new_place_query`·`lunch_place_query`와 식사 추천 `place_query`의 줄 재료.
- [REMOVE] 두 쓰기 경로의 unclear → 첫 후보 평탄화.

- **REQ-007 (Event-driven · Unwanted)**: When `update_schedule` names a new place that resolves only through a provider search with one or more results, the app shall not modify the target schedule and shall open a candidate card whose place row is that new-place argument; when the user confirms the card, the target shall be modified exactly once with the picked place. 근거: ③. 지금은 `resolveDestination(q)`(`:2813`)가 unclear를 첫 후보로 평탄화해 사용자가 고르지 않은 지점으로 일정·활동의 장소가 바뀐다. 대상 찾기(`:2792-2809`)는 검색 앞에서 끝나고 저장(`modifyActivity` `:2824`·`modifyEvent` `:2842`)은 검색 뒤라, 검색과 저장 사이에서 멈추면 아무것도 바뀌지 않은 채 카드가 선다. 확인은 같은 인자로 도구를 다시 실행하고 대상 찾기도 다시 한다.

- **REQ-008 (Event-driven · Unwanted)**: When `create_recurring_schedule` carries a lunch place that resolves only through a provider search with one or more results, the app shall open a candidate card before writing any record of that request, and when the user confirms the card, the series shall be created exactly once with the picked lunch place; while the request is a staying recurrence, the app shall not search the lunch place. 근거: ③과 §1.3 (나). 점심 해석이 지금 자리(`:2250`)에 남으면 확인 재실행이 통근·복귀·체류 묶음(`:2202`·`:2220`·`:2228`)을 한 벌 더 만든다. 머무는 반복은 점심 인자를 적용하지 않는다고 이미 안내하므로(`:2104-2106`) 그 갈래에서 점심을 검색하면 쓰이지 않을 카드가 뜬다. 빈 결과(REQ-004)의 점심은 오늘과 같다 — 통근은 만들고 점심 이동은 빼며 결과 문구에 이름을 적는다(`:2265`).

- **REQ-009 (Ubiquitous)**: The candidate card for the new-place argument of `update_schedule`, the lunch-place argument of `create_recurring_schedule`, and the base-place argument of `recommend_meal` shall show a place row whose key is that argument, labelled for that argument, and shall carry a context line naming the schedule being changed for an update; the confirmation shall put the pick into that argument and no other. 근거: §1.3 (가) — 지금 재료로는 새 장소·점심 두 키가 "목적지" 줄(`destinationField`, `:752`)이 되어 고른 값이 비운 키에 실리지 않고(`:1238`), 식사 추천의 `place_query`는 "활동 장소" 줄이 되며(`activityPlaceField` `:669-673`), 수정 카드는 맥락 줄이 빈다(`:886-910`). 줄 이름은 `plan.md` §4(결정 D-3 (a), 운영자 확정): `바꿀 장소`(선언 설명 `:1609`과 같은 말) · `점심 장소` · `기준 장소`(선언 설명 `:1635`의 "기준 장소 직접 지정"과 같은 말). 이동시간 조회의 `origin_query`·`destination_query`는 기존 줄(`출발지`·`목적지`)이 그대로 맞다. **출처 구분**: 새 장소·점심에 선택 카드를 여는 것은 〔운영자 ③〕이고, 식사 추천·이동시간에 여는 것은 〔운영자 결정 D-1 (b)〕이며, 줄 키·주입은 그것을 성립시키는 〔조사〕다. 수정 카드에 고칠 일정을 적는 맥락 줄(`고칠 일정 '…'`)은 〔제안〕이었으나 결정 D-3 (a)로 운영자가 확정했다. 조회 카드에는 맥락 줄을 두지 않는다 — 카드 바로 위에 방금 한 질문이 있고 줄 캡션이 질의를 적는다〔조사〕. 운영자가 본 문안에 없는 줄이라 더하지 않았다. 식사 추천의 기준 장소 줄에는 "현재 위치" 칩을 두지 않는다 — 현재 위치 기준은 `place_query`를 비우는 기존 갈래(`:2712-2719`)가 맡고, 토큰이 `place_query`에 실리면 그 글자가 검색 질의가 된다.

- **REQ-010 (Event-driven)**: When the user confirms a candidate card, each place row shall resolve to the coordinates of the place the user picked for it without another provider search or card for that row, including when two rows of one card picked places with the same name and different coordinates. 근거: §1.3 (다). 지금도 성립하는 동작이고(확정 열쇠 `:1063-1092` · 확정 사전 조회 `:3087`/`:1362`), 이 SPEC 뒤 같은 이름 칩이 늘어나므로 회귀선으로 못 박는다. 다시 묻지 않는 범위는 **고른 장소의 이름**이다 — 같은 대화에서 원래 질의('스타벅스 강남점')를 다시 말하면 그 질의는 확정 사전에 없어 다시 묻는다(§3 마지막 줄).

### [DELTA] C 문구와 주석

- [MODIFY] `unclearPlaceNote`(`:852-854`) · `parkForUnclearPlaces`의 반환 문구(`:957`)와 중복 가드 문구(`:924`) · 옛 갈래를 설명하는 주석.

- **REQ-011 (Ubiquitous · Unwanted)**: The candidate row caption, the result text returned to the model when a candidate card is opened, and the text returned when a card is already open shall not state a reason that is false when every search result is asked — such as the result being uncertain, mismatched, or of a different name — shall use the verb that matches the tool (register, change, or look up), and shall keep naming every asked query; and comments that describe the removed exact-match, unique-match, retry, merge, or flatten behavior shall be corrected. 근거: §1.3 (마). 문안은 `plan.md` §4의 제안 원문 그대로다 — 결정 D-3 (a), 운영자가 착수 승인에서 확정했다(사용자가 보는 캡션이고, 모델에게 가는 문구는 확인 뒤 모델의 말투를 정한다). 조회 도구의 동사(`조회하지`)는 같은 원문에서 동사 자리만 바꾼 꼴이고 D-1 (b)에서 파생됐다〔조사 — `plan.md` §4 끝〕. 드라이버 AI-13(`Tools/GuardDriver.swift:5053`)이 반환 문구에 두 질의 이름이 다 들어 있는지 본다.

### [DELTA] D 조회 경로 (결정 D-1 (b) — 운영자 선택)

- [EXISTING] 후보 카드 조립과 확인 주입 — 도구 이름을 보지 않는 부분은 쓰기 경로와 같다. 확인 경로가 조회 도구를 실행하는 것은 이 SPEC이 처음이다(확인은 보류한 호출을 `runToolCalls`로 다시 돌리고 `:1319`, 이어서 모델이 그 결과로 답한다 `:1193`).
- [MODIFY] `executeRecommendMeal`의 기준 장소 해석(`:2700-2705`) · `executeCheckTravelTime`의 출발지·목적지 해석(`:2762`·`:2765`).
- [REMOVE] `resolveDestination`(`:3206-3212`)·`resolveOrigin`(`:2953-2960`) — 호출처가 없어진다(REQ-014).

- **REQ-012 (Event-driven · Unwanted)**: When `recommend_meal` names a base place, or `check_travel_time` names an origin or a destination, that resolves only through a provider search with one or more results, the app shall not search for nearby places or estimate any route and shall open one candidate card with a place row for each such argument; when the user confirms the card, the lookup shall run exactly once with the picked places, its result text shall name the places used, and it shall write no record. 근거: 운영자가 착수 승인에서 고른 결정 D-1 (b)다 — 작성자의 권장안 (a)(조회는 카드 없이 첫 후보)가 아니라 **운영자 선택**이다. 카드 ③은 쓰기 경로만 적었으나 운영자가 "검색에서 온 장소는 사용자가 고를 때만 쓴다"를 조회에도 글자 그대로 적용하기로 했다. 지금은 `resolveDestination(q)`(`:2703`·`:2765`)와 `resolveOrigin`(`:2762`)이 unclear를 첫 후보로 평탄화해 조회의 기준 장소·출발지·도착지가 사용자가 고르지 않은 지점이 된다. 보류는 검색(`nearbyPlaces` `:2722`)과 경로 계산(`travelEstimates` `:2766`)보다 앞이고, 이동시간 조회는 출발지·목적지를 둘 다 해석한 뒤 카드를 한 장으로 연다. 두 조회 도구에는 실행 전 카드가 없어 카드는 이 한 장뿐이다(`askFields`의 `default: break` — research §3 (가)). 조회가 두 단계(카드 → 답)가 되고, 확인 뒤 답은 지금처럼 모델이 말한다. 이름이 비었거나(식사 추천의 `place_query`·이동시간의 `origin_query`) 즐겨찾기·같은 대화의 확정 장소·현재 위치로 풀리는 인자는 REQ-005가 그대로 지킨다. 빈 결과(REQ-004)는 오늘의 문구를 그대로 쓴다 — 이동시간은 `placeNotFound`(`:2765`), 식사 추천의 기준 장소는 시각·현재 위치 기준으로 넘어가는 기존 갈래(`:2706-2719`).

### [DELTA] E 드라이버와 검증

- [MODIFY] `Tools/GuardDriver.swift` AI절(`:4947-5055`) · 도우미(`:141-166`).
- [REMOVE] 재시도·병합 단언과 도우미, 이름 술어 단언과 도우미(결정 D-5 (a)).
- [NEW] 항상-선택·중복 키·쓰기 경로 카드·조회 경로 카드의 단언.

- **REQ-013 (Ubiquitous)**: The guard driver shall assert the behavior of REQ-001 through REQ-012 that a command can observe, by the redesign table of `plan.md` §5 — the "resolved" expectations of AI-2, AI-4, and AI-5 turned to "ask", the merge assertions of AI-6 and the retry assertions of AI-9 through AI-12 removed, each surviving `drvAdoption` call of AI-2, AI-4, AI-5, and AI-8 evaluated once and bound with `let` (R-5) — and its run shall end with no ✗ and exit 0, with the total recorded against a base total measured on the unchanged tree in the same run phase. 근거: 카드 동반 부채와 드라이버 하한 규칙. 하한 492는 t42 sync 레인이 `1375587` 트리에서 잰 값이다(`.moai/reports/t42/gate-sync-driver.log:577` "492/492 통과" — 코드는 `d900a78`과 같다). 새 하한의 산술은 `plan.md` §5에 있다 — 삭제 15와 추가 15(D-1 (b)의 조회 단언 4건 포함)가 상쇄해 총수는 기준과 같은 492로 산출된다. 값은 run이 실행에서 찍힌 줄로 확정한다.

- **REQ-014 (Ubiquitous · Unwanted)**: No function whose only callers were the removed branches or the flattening wrappers shall remain — `searchTopClearlyMatches`, `normalizedPlaceWord`, `resolveDestination`, `resolveOrigin`, and the driver helpers that exposed the removed functions — no parameter that no remaining caller sets shall remain, and the assertions that tested only those functions shall be removed with them. 근거: `CLAUDE.md` Day 끝 절차 3(간결성 — 죽은 코드)과 결정 D-5 (a), 운영자 확정. 이 트리의 앱 호출처는 전부 지우는 갈래 안이거나 삼태로 옮겨가는 자리다 — `searchTopClearlyMatches` 호출 `:3100`·`:3177`·`:3181`, `normalizedPlaceWord` 호출 `:3138`·`:3151`·`:3174`·`:3175`·`:3182`·`:3187`은 지우는 갈래 안이고, `resolveDestination` 호출 `:2250`(점심)·`:2703`(식사 추천)·`:2765`(이동시간 목적지)·`:2813`(수정)과 `resolveOrigin` 호출 `:2762`(이동시간 출발지)는 전부 REQ-007·008·012가 삼태 직접 호출로 바꾼다. 그러면 두 래퍼의 호출처가 0이 되어 함수와 `creation` 기본값 매개변수가 함께 사라진다(감사 1회차 A-4가 짚은 `creation: true` 호출처 하나(점심 `:2250`)도 같은 이유로 자리를 잃는다). `adoptPlace`의 `creation` 매개변수와 `resolveOriginAdoption`의 `orDefault`는 호출처가 값을 명시해 남는다(`:1768`·`:1931`·`:1952`·`:2174` `creation: true`, 점심 직접 호출 `creation: true`, `:2972`의 `!orDefault`). 이 SPEC 뒤 `resolveDestination`·`resolveOrigin`의 이름은 소스에 한 번도 나타나지 않는다(주석 포함 — REQ-011). 계획자의 제안이 운영자 확정(D-5 (a))으로 굳었다.

### [DELTA] F 계약과 범위

- **REQ-015 (Ubiquitous · Unwanted)**: The change shall touch only `Shared/AIAssistant.swift` and `Tools/GuardDriver.swift` among source files; shall not add, remove, or rename any tool declaration key or change the Gemini wire format and its uppercase schema types; shall add no AI class, no source file, no color outside `Theme`, and no secret; shall leave `proxy/` unchanged; shall keep the iOS build free of source warnings; and, under the iOS-only policy, shall neither build nor verify the macOS app. 근거: `CLAUDE.md` 계약 1·2·4·6과 iOS 전용 방침(2026-09-30). 새 줄 재료는 선언 키를 늘리지 않는다 — `new_place_query`·`lunch_place_query`·식사 추천의 `place_query`는 이미 선언돼 있고(`:1609` · `:1567` · `:1635`) 이동시간 조회의 `origin_query`·`destination_query`도 그렇다(`:1646`·`:1647`). 새 소스 파일이 없으므로 `xcodegen generate`와 서명 팀 재선택이 없다.

## 3. 바뀌지 않는 것

- 즐겨찾기·같은 대화의 확정 장소·현재 위치는 묻지 않는다(REQ-005).
- 일반명사 가드(`unresolvedGenericPlace` `:3049`, 목록 `:3043`)와 못 푸는 장소 줄(`unknownPlaceNote` `:3061`) — 즐겨찾기에 없는 '회사'는 지금처럼 검색 전에 카드가 묻는다.
- 빈 결과의 notFound 안내(`placeNotFound` `:2931`)와 그 문구.
- 카드 한 장 원칙과 카드가 서면 턴을 끝내는 규칙(`runLoop` `:446-452`, 확인 경로 `:1191`).
- 확인 주입의 세대 가드(`:1221`·`:1272`)와 J-1 두 번째 카드(`:1298-1316`).
- 머무는 요청의 출발지 줄·50 m 판정(`stayingTokenForColocatedPick` `:1333`, 활동 `:1969-1976`, 반복 `:2195`).
- 카드 안 장소 검색(`searchPlaces` `:1104-1125`) — 디바운스·5건 상한·0건 문구.
- 후보 칩의 모양(이름 + 주소 줄, `EditCardView.swift:357-378`) — `Shared/EditCardView.swift`를 고치지 않는다.
- 같은 이름 줄(SPEC-UIKIT-008 REQ-008 — `repeatedSearchQuery` `:771`)과 머무는 요청 판정.
- 환승역 노선 갈림의 질문 — 지금처럼 노선마다 칩이 뜬다(REQ-006).
- iOS 알림 64건 한도에 닿는 경로 — 이 SPEC은 저장 건수를 바꾸지 않는다.
- 확정 사전의 열쇠는 **고른 장소의 이름**이다 — 같은 대화에서 원래 질의를 다시 말하면 다시 묻는다(REQ-010 근거, 기존 동작). **운영자가 의도된 동작으로 확정했다**(착수 승인, 2026-10-06) — 원래 질의 열쇠를 사전에 함께 두는 별도 결정은 만들지 않는다.
- 조회 도구가 이름 없이 기준을 정하는 갈래 — 식사 추천의 `at_iso`·현재 위치 기준(`:2706-2719`)과 이동시간 조회의 `origin_query` 비움(집 → 현재 위치, `orDefault` `:2974-2978`)은 검색이 아니라 저장된 값으로 풀리므로 카드가 없다(REQ-005).

## 4. 범위 밖

### Out of Scope — 한 턴 여러 호출의 요약 소실(t32)

- 한 턴에 호출이 여럿일 때 하나가 후보 카드를 세우면 나머지 호출의 결과가 말풍선 없이 끝나는 것(`runLoop` `:452`)과, 둘째 호출이 "등록하지 않았어요" 안내만 받는 것(`:923-925`)은 고치지 않는다. 이 SPEC 뒤 검색으로 푸는 장소가 늘 카드를 세우므로 그 경로가 더 자주 쓰인다 — 조회 도구(D-1 (b))도 이 경로에 들어온다(한 턴에 이동시간 조회와 등록을 함께 하면 한쪽 결과가 말풍선 없이 끝난다). 잔여 위험으로 적고(`plan.md` §7), 수리는 카드 t32 몫이다.

### Out of Scope — 카드 문법(t30·t35)

- 가는 편 재확인 줄의 생략(t30 ⑥), 출발지 줄 순서(t30 ④), 확인 경로 후보 카드가 왕복 가는 편을 되묻는 것(t35)은 줄 판정(`askFields`) 영역이라 이 SPEC 밖이다.

### Out of Scope — 장소 검색 제공자와 편집 화면

- `Shared/PlaceSearch.swift`(카카오 → MapKit 폴백, `:9-19`)와 오프라인·0건을 구분하지 못하는 동작은 바꾸지 않는다.
- `Shared/EditCardView.swift`의 후보 칩·편집기는 바꾸지 않는다.
- 식사 추천에서 `place_query`가 notFound일 때 시각·현재 위치 기준으로 넘어가는 기존 갈래(`:2706-2719`)와 그 문구는 바꾸지 않는다 — REQ-004의 "기본 장소로 떨어지지 않는다"는 채택 판정 안의 규칙이고, 이 도구의 기준 정하기 순서(place_query → at_iso → 현재 위치)는 도구의 설계다.
- 수정 도구의 새 장소에 일반명사 가드를 거는 일(지금 `resolveDestination(q)`가 `creation: false`로 부른다 — `:2813`, 이 SPEC 뒤에는 `adoptPlace(q, creation: false)`)은 하지 않는다. 즐겨찾기에 없는 '회사'를 새 장소로 말하면 지금은 검색 첫 결과로 조용히 바뀌고, 이 SPEC 뒤에는 검색 결과 카드가 뜬다 — 조용한 확정은 사라지지만 '회사'를 장소로 물어 주는 못 푸는 장소 줄은 생기지 않는다.

### Out of Scope — 문서 인용 재사상

- 이 SPEC이 `AIAssistant.swift`·`GuardDriver.swift`의 줄을 옮겨 깨는 CHECKLIST·루트 `plan.md`·SPEC 문서 인용은 이 카드의 sync가 원장 방식으로 다시 잇거나 t44에 넘긴다 — 어느 쪽인지는 리드가 정한다(`plan.md` §6).

### Out of Scope — 맥 앱

- 맥 앱(`besir-macOS`)은 빌드하지도 검증하지도 않는다(iOS 전용 방침). `Shared/AIAssistant.swift`는 두 타깃이 함께 컴파일하므로 맥 타깃이 깨져도 이 카드의 게이트는 잡지 않는다 — 운영자가 받아들인 갭이다.

## 5. 결정

착수 승인(2026-10-06)에서 운영자가 D-1~D-6을 확정했다. 결정 분기는 확정안만 남겨 이 SPEC 본문에 반영했고, 선택지와 버려진 안은 `plan.md` §2에 기록으로 남았다.

| 결정 | 확정 | 이 SPEC에서 닿는 곳 |
|---|---|---|
| D-1 조회 경로 범위 | **(b) 조회도 카드** — 운영자 선택(권장안 (a)와 다름) | REQ-012 · REQ-009 · REQ-014 · §1.1·§1.2·§1.3 |
| D-2 후보 순서 | (a) 제공자 순서 그대로 | REQ-002 · REQ-014 |
| D-3 문안 | (a) 제안 원문 그대로(수정 카드 맥락 줄 포함) | REQ-009 · REQ-011 |
| D-4 반복 점심 해석 위치 | (a) 첫 저장 직전에 따로 | REQ-008 |
| D-5 죽은 코드 | (a) 삭제 | REQ-014 |
| D-6 Tier·파일 | (a) Tier M · 파일 2 | §0 |
| (결정표 밖) 원래 질의 재언급 | 의도된 동작으로 둔다 | §3 마지막 줄 |

## 6. 관련 문서

- 칸반 카드 **t47** 본문(`moai todo`) — 운영자 지시 원문
- 루트 `plan.md:583-585` — 후속 31·32·33(t42 sync 렌즈 실행 재현)
- `.moai/reports/t42/code-safety-sync.md` — t42 판정문(R-5 정의 `:115`)
- `.moai/reports/t45/plan-progress.md` — t45 반려 결정
- [SPEC-UIKIT-008](../SPEC-UIKIT-008/spec.md) — 후보 카드(U-4)와 확정 사전 재사용(REQ-008)의 원 계약
- [SPEC-UIKIT-009](../SPEC-UIKIT-009/spec.md) — 형식 기준
- 이 SPEC의 조사 기록 — `research.md`

🗿 MoAI
