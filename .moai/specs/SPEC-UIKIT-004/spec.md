---
id: SPEC-UIKIT-004
title: "EventDetailView 크롬 통일 + 시각 포매터·기준 매핑의 BesirTime 단일화 (UI 통일 2b)"
version: "0.1.0"
status: draft
created: "2026-09-20"
updated: "2026-09-20"
author: "plan-lane t4 (manager-spec 대행)"
priority: P1
phase: "Phase 1.7 — 화면 UI 통일"
module: "shared-ui"
lifecycle: spec-anchored
tags: "ui-unification, chrome, contract-5, contract-6, besir-time, formatter-single-source, anchor-mapping, theme-tokens"
tier: M
related_specs: [SPEC-UIKIT-001, SPEC-UIKIT-002]
kanban_card: t4
---

# SPEC-UIKIT-004 — EventDetailView 크롬 통일 + 시각 표기 단일화 (UI 통일 2b)

## HISTORY

| 버전 | 날짜 | 변경 |
|---|---|---|
| 0.1.0 | 2026-09-20 | 최초 작성. 루트 `plan.md` §Phase 1.7의 t4 행을 GEARS로 정식화 — t2a(SPEC-UIKIT-002)가 2026-09-18 분할 때 예약해 둔 카드다. 인용 줄번호는 `9e4a374`(= `origin/master`, t2a 머지 직후) 실측. 작성 경위 특이: plan 세션의 Agent 스폰이 불가해(세션 팀 파일 오류, `progress.md` §F.1) manager-spec 위임 대신 orchestrator-direct로 작성했고, 설계 교차협의·독립 감사를 GLM(z.ai) 백엔드로 대체 수행했다. 리드 디스패치의 "접두↔기준 매핑 5곳"은 t2a 종료 시점 AddEventView 내 5곳 셈이고 본 SPEC은 현 트리 전수 **10곳**(§1.3)을 기준으로 삼는다 — 숫자 차이를 숨기지 않고 세는 명령과 함께 기록 |

## 0. 이 SPEC의 성격

**as-built 베이스라인이 아니라 구현을 앞둔 변경의 계약이다.** 설계 원본은 루트 `plan.md` §Phase 1.7의
t4 행이고, 범위는 t2a 분할 때 운영자가 확정한 그대로다 — ① `EventDetailView` 크롬 통일(D-1: 편집
필드 0개, 읽기 전용 렌더 모드 금지), ② 시각 포매터 4벌의 `BesirTime` 단일화(D-2: `shortTimeFmt`
"a h:mm" 흡수 금지), ③ t2a §E.3 후속 표의 **N2**(접두↔기준 매핑 → `BesirTime.anchor`)와
**"9/17 (목) 오후 3시 05분" 표기 검증 승계**(t2a AC-009 S8 이월).

인용 줄번호는 변경 전 상태(`9e4a374`) 기준이라 구현 중 밀릴 수 있다 — 그때마다 실측 재정렬한다
(SPEC-UIKIT-002 HISTORY 0.1.0이 물려준 관례).

**크롬 통일의 정의(D-4)**: 이 화면의 카드 컨테이너·보조색·상징색이 t1/t2a가 확립한 `Theme` 토큰
문법으로 바뀌는 것. 정보 구조(섹션 순서)·상호작용·문구는 그대로다. 레이아웃 재디자인이 아니다.

**REQ 예산 — 14건으로 상한(16) 아래다.** 세는 명령은 `grep -c '^- \*\*REQ-' spec.md`이고 값은
**14**여야 한다: §2.1 3건(001~003) · §2.2 3건(010~012) · §2.3 4건(020~023) · §2.4 2건(030~031) ·
§2.5 2건(040~041). 여유 2건은 구현 중 측정 정정(HISTORY 추가)용으로 남겨둔다. 그 이상 늘면 분할 신호다.

**드라이버 초록은 뷰 증거가 되지 못한다.** `Tools/GuardDriver.swift`는 SwiftUI 뷰를 컴파일 대상으로
삼지 않는다 — 크롬·표기·낭독은 전부 가드 밖이고 AC-009(시뮬레이터)가 대체 불가능한 증거다
(88/88 초록 다음 날 실기기 결함 7건 이력, t2a §0에서 재확인).

## 1. 배경

### 1.1 EventDetailView 실태 (`9e4a374` 실측)

| 항목 | 값 | 확인 |
|---|---|---|
| `Shared/EventDetailView.swift` | **377줄** | `wc -l` |
| 카드 컨테이너 | `.padding(18).background(.thinMaterial, in: RoundedRectangle(cornerRadius: 14))` **2곳** — 출발 카드 `:213-214`, 대중교통 여정 `:249-250` | 읽음 |
| 지도 클립 | `RoundedRectangle(cornerRadius: 12)` `:59`(280pt 프레임 `:58`) | 읽음 |
| 시스템 보조색 | `.secondary` **9건**(`:177`·`:180`·`:199`·`:210`·`:234`·`:273`·`:282`·`:309`·`:352`), `.tertiary` 1건(`:246`), `.quaternary` 1건(`:264`) | `grep -c '\.secondary\|\.tertiary'` = 10 |
| 원색 사용 | 출발 시각 큰 숫자 `isPast ? .red : .green` `:203`, 구글 등록됨 체크 `.green` `:116` | 읽음 |
| 시각 포매터 | `fullFmt` `:17-20` · `timeFmt` `:21-24` · `shortTimeFmt` `:26-29` — 셋 다 `static let`(재렌더마다 할당 문제는 없다) | 읽음 |
| 접근성 호출·`@ScaledMetric` | **각 0건** | `grep -c 'accessibility\|@ScaledMetric'` = 0 |
| 편집 경로 | 툴바 "편집" `:76-79` → `.sheet { AddEventView(editing:) }` `:80-82` — **화면 안 편집 필드 0개** | 읽음 |
| 캘린더 블록 | 네 갈래 `:110-146` (등록됨 `:115-116` / pending `:117-120` / 실패+재시도 `:122-136` / 계정 미연결 `:138-144`) | 읽음 |

### 1.2 시각 포매터 — 사람이 읽는 표기가 두 파일에 다섯 종 (D-2)

| 포매터 | 패턴 | 소재 | 분(0패딩) | 운명 |
|---|---|---|---|---|
| `BesirTime.whenFormatter`(`when`) | "M월 d일 (E) a h시 m분" | `EditCard.swift:14-20` | m — "3시 5분" | 유지 |
| `BesirTime.compact` | "M/d (E) a h시 mm분" | `EditCard.swift:27-32` | mm — "3시 05분" | 유지 |
| `BesirTime.isoFormatter` | "yyyy-MM-dd'T'HH:mm:ss" | `EditCard.swift:37-43` | (기계 형식) | 유지 |
| `fullFmt` | "M월 d일 (E) a h시 mm분" | `EventDetailView.swift:17-20` | mm — "3시 05분" | **BesirTime으로 이사**(REQ-001) |
| `timeFmt` | "a h시 mm분" | `EventDetailView.swift:21-24` | mm — "3시 05분" | **BesirTime으로 이사**(REQ-001) |
| `shortTimeFmt` | "a h:mm" | `EventDetailView.swift:26-29` | mm — "3:05" | **로컬 유지 — 흡수 금지**(REQ-002) |

`EditCard.swift:10-12`가 BesirTime의 존재 이유를 못박았다("포매터·파서가 파일마다 제각각 생기는
것이 이 프로젝트가 이미 한 번 당한 어긋남이라 정의는 이곳 하나"). 사람이 읽는 표기 5종 중
`shortTimeFmt`를 뺀 **4종이 BesirTime 소유로 모이는 것**이 D-2의 "4벌 단일화"다. 핵심 함정:
`fullFmt`와 `when`은 **패딩만 다른 거의 쌍둥이**("M월 d일 (E) a h시 mm분" vs "…m분")이라 서로
흡수하고 싶어진다 — t2a REQ-023이 `compact`를 `when`으로 흡수하지 않았던 이유(폭)에 패딩
회귀("오후 3:5")가 겹친다. 흡수가 아니라 **이사**다(REQ-003).

### 1.3 접두↔기준 매핑 10곳 (N2, t2a §E.3 이월)

`ScheduleAnchor`는 `Models.swift:204`(`String, Codable`, `.arrival`/`.departure`)이고,
`Models.swift`는 드라이버 컴파일 집합(CLAUDE.md `swiftc` 인자)에 있으므로 `BesirTime`
(`EditCard.swift`)이 참조해도 드라이버가 깨지지 않는다. 현재 매핑 전수 — 세는 명령:
`grep -rn 'prefix == "arr:"\|prefix == "dep:"\|hasPrefix("arr:")' Shared/*.swift` **7건** +
`grep -rn '? "arr:" : "dep:"' Shared/*.swift` **3건** = 10곳:

| 곳 | 방향 | 내용 | 운명 |
|---|---|---|---|
| `AddEventView.swift:325` | 기준→접두 | 직렬화 `(basis == .arrival ? "arr:" : "dep:")` | 전환(REQ-011) |
| `AddEventView.swift:335` | 기준→접두 | 같은 형태(시각 에디터 확인) | 전환 |
| `AddEventView.swift:476` | 접두→기준 | `parsed?.prefix == "dep:"`(출발기준 판정) | 전환 |
| `AddEventView.swift:531` | 접두→기준 | `parsed.prefix == "arr:"`(겹침 검사 분기) | 전환 |
| `AddEventView.swift:554` | 접두→기준 | 저장 `anchor = … ? .arrival : .departure` | 전환 |
| `EditCardView.swift:168` | 접두→기준 | `chosen.hasPrefix("arr:") ? .arrival : .departure` | 전환 |
| `AIAssistant.swift:826` | 기준→접두 | 직렬화(보류 턴) | 전환 |
| `AIAssistant.swift:885` | 접두→기준 | `parseDatetime(time)?.prefix == "dep:"` — 출발 기준일 때 여유 실림 방지(`:880-882` 주석이 "여기가 그 약속의 실행 장소"라 부른 곳) | 전환 |
| `EditCard.swift:139` | 접두→라벨 | `$0.prefix == "arr:" ? "도착 " : "출발 "`(customLabel) | **유지** — 카드 문법 소유 |
| `AIAssistant.swift:893` | 접두→인자 키 | `args[… ? "arrival_iso" : "departure_iso"]` | **유지** — AI 소유 의미 |

유지 2곳의 규칙은 t2a가 세운 것과 같다 — `setLookup`·`maxPlaceSuggestions`는 AI 쪽 의미라
`EditCard.swift`로 따라가지 않았다(SPEC-UIKIT-002 REQ-010 절). 라벨 문구와 툴 인자 이름은
중립 타입이 알 일이 아니다.

### 1.4 이월과 문서 인용

- **N2·"05분" 검증은 t2a §E.3 후속 표의 t4 소관**(리드 디스패치 2026-09-20). 같은 표의
  B7(불가 수단 침묵)·S-lens4(buffer 초산 3곳)·CB(ConflictBanner 계약 6 우회 3건)는
  후보로만 남고 **본 카드 밖**이다(§3).
- **CHECKLIST 코드 근거**(세는 명령 `grep -c '<파일>.swift:[0-9]' CHECKLIST.md`):
  EventDetailView **1** · EditCard **2** · AIAssistant **6** · EditCardView **6** · AddEventView
  **0**. N2 전환은 제자리 줄 치환이라 줄번호가 안 흔들리지만, EditCard의 신규 멤버 삽입과
  EventDetailView 본체 수정은 인용을 민다 — **드리프트를 만든 카드가 sync에서 바이트 대조로
  수리한다**(t2a가 101조각을 수리한 전례, 루트 plan.md 갱신과 함께 sync 소관).
- 루트 `plan.md:427` t4 행("별도 SPEC — t4 plan에서 확정")은 본 plan 단계에서
  `SPEC-UIKIT-004`로 확정 기록한다.

## 2. 요구사항 (GEARS)

### 2.1 시각 포매터 단일화 (001번대)

- **REQ-001 (Ubiquitous)**: The screen's date formatters shall belong to BesirTime, except the one this SPEC forbids to move. `fullFmt`(`:17-20`)과 `timeFmt`(`:21-24`)를 `BesirTime`의 `static let` 멤버(이름 `full`·`clock`, D-2)로 옮기고 **패턴 문자열은 한 글자도 바꾸지 않는다**. 호출부는 `:179`(헤더 도착 시각)·`:201`(출발 시각 큰 숫자) 두 곳. 근거: §1.2 — t2a REQ-023이 `depFmt`→`compact`로 같은 이동을 했고, 이사를 마치면 사람이 읽는 시각 표기의 소유자는 `EditCard.swift` 하나가 된다. 기계적 신호: `grep -c "DateFormatter()" Shared/EventDetailView.swift` = **1**(shortTimeFmt뿐), `grep -c "DateFormatter()" Shared/EditCard.swift` = **5**(when·compact·iso·full·clock).

- **REQ-002 (Unwanted)**: The step-time formatter shall not be absorbed into BesirTime. `shortTimeFmt`("a h:mm", `:26-29`)는 EventDetailView 로컬에 남는다. 근거: 환승 단계 옆 좁은 표기("오후 3:05", `:280`)는 이 화면의 고유 요구이고, BesirTime 멤버로 올리는 순간 분 표기를 다른 멤버와 맞추려는 유혹 — mm이 아닌 재표현, 즉 "오후 3:5" 회귀(swift 실측 재현 이력, 리드 디스패치 명시) — 이 생긴다. t2a가 `compact`를 `when`으로 흡수하지 않은 것(SPEC-UIKIT-002 REQ-023)과 같은 판단의 연장이다. 이 줄의 주석(`:25` "경로 안내 단계 옆에 붙는 짧은 시각")이 그대로 이유를 말하고 있다.

- **REQ-003 (Ubiquitous)**: Minute zero-padding shall survive exactly as it is today. 분의 0은 포매터별 현재값 그대로다 — `full`·`compact`·`clock`은 mm("3시 05분"), `when`은 m("3시 5분"), `shortTimeFmt`는 mm("3:05"). **어느 쪽도 다른 쪽으로 흡수하지 않는다.** 승계: t2a AC-009 S8("9/17 (목) 오후 3시 05분" 세부 확인은 t4 포매터 검증으로 이월). 검증은 swift 실측 한 줄로 기계적으로 한다(AC-002) — 패딩은 눈으로 봐야 하는 성질이 아니다.

### 2.2 기준 매핑 단일화 (010번대)

- **REQ-010 (Ubiquitous)**: The prefix↔anchor mapping shall live in BesirTime alone. `BesirTime`에 접두→기준 `anchor(ofPrefix: String) -> ScheduleAnchor?`("arr:"→`.arrival`, "dep:"→`.departure`, 그 외 `nil`)과 기준→접두 `prefix(for: ScheduleAnchor) -> String`을 신설한다. 근거: 매핑이 9곳에 흩어져 각자 늙는 것(§1.3)이 계약 5 위반의 모양이고, `parseDatetime`(`EditCard.swift:47-54`)이 돌려주는 접두 String은 이미 단일 출처라 이 신설은 그 값을 의미로 바꾸는 마지막 한 걸음이다. `ScheduleAnchor` 의존은 드라이버 집합 안(`Models.swift` 포함)이라 컴파일 경계를 깨지 않는다(§1.3).

- **REQ-011 (Ubiquitous)**: Every pure mapping site shall route through the new accessors. 전환 8곳은 §1.3 표의 전환 행 — `AddEventView:325`·`:335`(→`prefix(for:)`), `:476`·`:531`·`:554`와 `EditCardView:168`(→`anchor(ofPrefix:)`), `AIAssistant:826`(→`prefix(for:)`)·`:885`(→`anchor(ofPrefix:)`). 전부 **제자리 한 줄 치환**이다. 유지 2곳(`EditCard:139` 라벨 조립, `AIAssistant:893` 인자 키)은 §1.3의 사유대로다. 기계적 신호: `grep -rn 'prefix == "arr:"\|prefix == "dep:"\|hasPrefix("arr:")' Shared/*.swift` = **2**(`:139`·`:893`뿐), `grep -rn '? "arr:" : "dep:"' Shared/*.swift` = **0**.

- **REQ-012 (Unwanted)**: Neither the form nor the AI card shall observably change. 직렬화 결과("arr:"/“dep:” + ISO — `:325`·`:335`·`:826`), 칩 라벨(`:139`), 저장 anchor(`:554`), 툴 인자 키(`:893`)의 관측 가능한 값이 전부 동일하다. 드라이버 **단언을 추가하지 않고** 기존 단언(P 계열 — 시각 줄 왕복이 `parseDatetime`을 지난다)이 초록인 것이 증거다. 이 매핑 전환이 AI 카드의 어떤 화면 표면을 바꾸면 잘못된 것이다.

### 2.3 크롬 통일 (020번대)

- **REQ-020 (Ubiquitous)**: The screen's card containers shall speak the component language. 출발 카드(`:213-214`)와 대중교통 여정(`:249-250`)의 `.thinMaterial` + `cornerRadius: 14`가 `.background(Theme.raised, in: RoundedRectangle(cornerRadius: Theme.radius))` + `.overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.line))`(`EditCardView:63-64` 문법)로 바뀐다. 상세행 블록(`:302-348`, 현재 컨테이너 없음)도 같은 컨테이너로 감싼다(D-4). `.thinMaterial`은 이 화면에서 퇴장한다. 기계적 신호: `grep -c 'thinMaterial' Shared/EventDetailView.swift` = **0**.

- **REQ-021 (Ubiquitous)**: Every color on this screen shall go through a Theme token. `.secondary` 9건(§1.1 열거) → `Theme.muted`, `.tertiary`(`:246`) → `Theme.faint`, `.quaternary`(`:264`) → `Theme.line`, 출발 시각 큰 숫자 `isPast ? .red : .green`(`:203`) → `isPast ? Theme.nowLine : Theme.travel`, 등록됨 체크 `.green`(`:116`) → `Theme.travel`. 예외(D-4 변경 금지 목록): `.white` 노선 원 위 글리프(`:259`), `Color(hex:)` 노선색(`:261`), `Theme.bg` 배경(`:71`, 이미 토큰). 근거(실측): `EditCardView`는 `.secondary`/`.tertiary` **0건** — 본문 `Theme.ink`·캡션 `Theme.muted`·최흐림 `Theme.faint` 문법(`:46`·`:53`·`:96`·`:104`·`:311`·`:337`)이며, `nowLine`은 시간축의 '지난/현재' 적색(`ContentView:449`), `travel`은 '갈 일정' 녹색(`ContentView:303`·`:361`)이다. 기계적 신호: `grep -c '\.secondary\|\.tertiary\|\.quaternary\|\.red\|\.green' Shared/EventDetailView.swift` = **0**.

- **REQ-022 (Ubiquitous)**: The calendar block's four states shall survive the chrome pass untouched. 등록됨(`:115-116`)·pending(`:117-120`)·실패+재시도(`:122-136`)·계정 미연결(`:138-144`) 네 갈래의 분기·문구·재시도 버튼이 그대로다 — 바뀌는 것은 색 토큰화뿐(REQ-021). 승계: t2a D-1의 판단 — "그 단순화가 바로 이 블록이 태어난 원인이었다"(`:108-109`·`:139-140` 주석), 네 갈래를 둘로 젽는 재발은 금지다(SPEC-UIKIT-002 §4 D-1).

- **REQ-023 (Ubiquitous)**: The chrome pass shall carry the component's accessibility contract as pure additions. 현재 accessibility 호출·`@ScaledMetric` 각 **0건**(§1.1)이므로 추가는 전부 순증이다: 출발 카드의 시각 큰 숫자+상태 캡션 결합 낭독, `stepRow`의 헤드라인+예상 시각 결합 낭독, 지도 프레임의 이름 — 그리고 38pt 고정 출발 숫자(`:202`)의 `@ScaledMetric` 상대화(D-4 확정안). 잃을 것은 없다(0에서 시작) — t2a REQ-031의 표기 원칙("잃는 것을 숨기지 않는다")을 그대로 계승하되 본 카드에는 잃는 항목이 없다.

### 2.4 보존해야 할 것 (030번대)

- **REQ-030 (Ubiquitous)**: The pass shall lose no user-visible affordance. 대조 단위는 acceptance.md AC-006의 **절 표**(일괄 통과 금지 — t2a AC-006과 같은 규율). 형태가 바뀌는 것은 크롬(REQ-020·021)과 순증(REQ-023)뿐이고, 정보·상호작용·문구는 하나도 안 바뀐다. 특히: 편집 툴바(`:76-79`), 삭제 분기(단일 `:341-347` / 반복·같은 제목 `:325-340`), 지도 전환(`:92-106`), "이동시간을 계산하지 못했습니다" 폴백(`:215-220`), 상대시각 문구(`relativeText` `:359-364`).

- **REQ-031 (Unwanted)**: The screen shall not gain editing surface. 편집 가능한 필드는 계속 **0개**다 — 편집은 `.sheet { AddEventView(editing:) }`(`:80-82`) 위임 그대로고, `EditCardView`에 읽기 전용 렌더 모드를 만들지 않는다. 승계: D-1(2026-09-18 운영자 확정). t2a가 기각한 해석("컴포넌트에 읽기 전용 모드 추가 — 465줄 전체가 편집 문법이라 거의 모든 가지가 둘로 갈라진다")이 그대로 유효하다.

### 2.5 검증과 범위 경계 (040번대)

- **REQ-040 (Ubiquitous)**: The pass shall pass the project gate on both platforms. 네 절 — t2a REQ-040과 동일한 형태:
  - (a) AI 인자 가드 드라이버 전체 초록, **단언 추가 없음** — 특히 P 계열(시각 줄·장소 검색 경로)과 `BesirTime` 경로.
  - (b) iOS·macOS 양쪽 **무경고** 빌드(툴체인 경고 제외).
  - (c) `cd proxy && npm test` 전체 통과(본 SPEC은 프록시를 건드리지 않지만 게이트는 돈다).
  - (d) **새 소스 파일을 만들지 않는다** — `xcodegen generate` 불필요, 서명 Team 재선택 요청도 없다. 기계적 신호: `git diff --name-only --diff-filter=A origin/master...HEAD -- 'Shared/*.swift'`가 0건.

- **REQ-041 (Unwanted)**: This SPEC shall not modify anything beyond its counted lines. 소스 변경은 다섯 파일 안에서 일어난다 — 본체 2(`EventDetailView.swift`·`EditCard.swift`)와 N2 전환 8줄의 3(`AddEventView.swift` 5줄·`EditCardView.swift` 1줄·`AIAssistant.swift` 2줄, REQ-011 열거). 세 치환 파일의 diff는 **열거된 줄만** 담는다 — 그 밖의 줄이 diff에 있으면 REQ-041 위반이다. 문서 예외: 루트 `plan.md`(t4 행)·본 SPEC 4종·`progress.md`·`CHECKLIST.md`(sync의 인용 수리, §1.4). CB·B7·S-lens4는 본 카드 밖(§3).

## 3. Out of Scope

- CB — `ConflictBanner`의 계약 6 우회 3건(`.secondary`·`.tertiary`·`cornerRadius: 8`, `AddEventView.swift:609` 계열) — t2a §E.3이 "다음 카드 후보"로 남긴 것. 본 카드는 건드리지 않는다(N2의 `AddEventView` 5줄과 무관한 줄이다).
- B7(계산 후 불가 수단의 침묵)·S-lens4(buffer 초산 변환 3곳, `AddEventView.swift:483-484`·`:529`·`:556`) — t2a §E.3의 t3/t4 후보. 리드 디스패치가 t4 소관으로 정한 것은 N2·05분 검증뿐이므로 밖으로 뺀다.
- 활동 화면 둘(`AddActivityView`·`ActivityDetailView`) — **카드 t3**(`SPEC-UIKIT-003`, 루트 `plan.md:428`).
- 출시 전 제거할 테스트용 코드(`deleteEverythingForTesting`·`transcriptForDebugging`) — 별건.
- 지도 클립 반경의 토큰화(D-4에서 유지 판정 및 사유 기록).

## 4. 결정 기록

### D-1 — 편집 표면 만들지 않기 — **해소됨(승계)**

- **결정**: 편집 필드 0개 유지, 시트 위임 유지, 읽기 전용 렌더 모드 금지(2026-09-18 운영자 확정 — t2a 카드 분할 때 확정, SPEC-UIKIT-002 §4 D-1).
- **반영**: REQ-031, §0
- t2a의 측정이 그대로 유효하다: 이 화면의 `detailRows` 본문은 읽기 전용 `row(k,v)` 세 쌍뿐이고 편집은 전부 시트로 위임된다. 본 SPEC은 그 판단을 승계만 한다.

### D-2 — 포매터 4벌의 운명 — **해소됨(리드 디스패치 확정 + 본 세션 실측)**

- **결정**: 사람이 읽는 시각 표기 5종(§1.2 표) 중 `shortTimeFmt`를 뺀 4종(`when`·`compact`·`fullFmt`·`timeFmt`)이 `BesirTime` 소유로 모인다. `fullFmt`·`timeFmt`는 신규 멤버 **`full`·`clock`** 로 이사(패턴 불변), `shortTimeFmt`는 로컬 유지(REQ-002), 패딩은 포매터별 현행 유지(REQ-003).
- **멤버 이름에 관하여**: t2a가 "시각 포매터 `clock`·`stepTime` 신설"을 예고했으나(SPEC-UIKIT-002 §3), `shortTimeFmt` 흡수 금지가 확정되면서 `stepTime`의 자리가 사라졌다 — 예고의 절반(`clock`)만 채운다. 예고는 계약이 아니므로 이력으로 남긴다.
- **기각한 형태**:

| 기각한 형태 | 이유 |
|---|---|
| `fullFmt`를 `when`으로 흡수(mm→m 통일) | "05분"의 0이 사라진다 — t2a AC-009 S8이 승계 지정한 바로 그 회귀. 패딩 차이는 우연이 아니라 표기 요구다 |
| `shortTimeFmt`까지 BesirTime에 올린다 | 소유 통일이 목적지가 아니라 계약 5가 목적이다. 이 화면 고유 표기를 중립 타입에 두면 다음 화면이 그것을 "표준"으로 재사용하려 든다 — "오후 3:5" 회귀의 문을 연다 |
| ISO 포매터까지 손댄다 | 기계 형식은 이미 단일 소유이고 왕복 계약(`EditCard.swift:34-36` 주석)이 붙어 있다 — 고칠 것이 없다 |

- **반영**: REQ-001~003

### D-3 — anchor 접근자의 형태 — **해소됨(본 세션, 리드 디스패치 이름 존중)**

- **결정**: 접두→기준 `BesirTime.anchor(ofPrefix:)`, 기준→접두 `BesirTime.prefix(for:)` 한 쌍.
- 디스패치가 부른 이름은 `BesirTime.anchor(of:)`였다 — 본 세션이 실측한 결과 매핑은 **양방향**으로 쓰이고(§1.3: 기준→접두 3곳, 접두→기준 5곳, 나머지 1곳은 인자 키) 단방향 API만으로는 절반의 호출부가 여전히 삼항으로 남는다. 방향 인자 이름을 붙여 한 쌍으로 신설한다.
- **기각한 형태**: `ScheduleAnchor`에 접두를 돌려주는 프로퍼티를 넣는다(`anchor.prefix`) — `Models.swift`는 데이터 모델 파일이고 시각 값의 문자열 문법은 `BesirTime`이 홀로 안다는 `EditCard.swift:10-12`의 선언을 깬다. `EditField` 쪽에 무엇을 더하는 것도 기각 — 매핑은 카드가 아니라 시각 값의 성질이다.
- **반영**: REQ-010~011

### D-4 — 크롬 매핑 — **해소됨(본 세션 실측 + GLM 교차협의 2026-09-20)**

- **결정 표**(REQ-020·021·023의 근거):

| # | 현재 | → 목표 | 근거(실측) |
|---|---|---|---|
| 1 | 카드 컨테이너 `.thinMaterial`/14 ×2 | `Theme.raised` + `Theme.radius` + `Theme.line` 스트로크 | `EditCardView:63-64` 문법 그대로 — 계약 6 |
| 2 | 지도 클립 `cornerRadius: 12`(`:59`) | **유지** | 280pt 이미지 프레임은 크롬이 아니라 콘텐츠 경계다. `Theme.radius`(3)는 칩·에디터용 미세 반경이라 지도에 얹으면 사각형과 구분이 안 된다. 유지 사유를 주석으로 남긴다 |
| 3 | `.secondary` 9건 | `Theme.muted` | t1 캡션 문법(`EditCardView:53`·`:104`·`:311`·`:337`) |
| 4 | `.tertiary` 1건(ODsay 주의문) | `Theme.faint` | t1의 최흐림 계열(`:96`·`:145` — 점선 칩·흐림) |
| 5 | 출발 숫자 `isPast ? .red : .green` | `isPast ? Theme.nowLine : Theme.travel` | `nowLine`=시간축 '지난/현재' 적색(`ContentView:449`), `travel`='갈 일정'(`:303`·`:361`). "지났습니다" 캡션의 `Theme.warn`(`:207`)은 유지 — 이미 토큰이고 경고 문법 |
| 6 | `.quaternary` 연결선(`:264`) | `Theme.line` | 같은 역할(흐린 구분선) |
| 7 | `.white` 글리프(`:259`)·`Color(hex:)` 노선색 | **유지** | 노선색 위 대비는 의도된 것이고 노선색은 외부 데이터 — 토큰이 알 수 없다(`:367-377` 주석) |
| 8 | 상세행 블록(`:302-348`) 컨테이너 없음 | 같은 카드 컨테이너로 감쌈 | 언어 통일(섹션이 카드인 화면에서 벌거벗은 블록은 예외적 모습). 정보·순서 불변 — 재디자인 아니다 |
| 9 | 38pt 고정(`:202`) | `@ScaledMetric` 상대화 | Dynamic Type 무시가 현재 결함(0건 실측). 크롬 패스의 순증 범주 |

- **변경 금지**: 지도 클립 반경(2), `.white` 글리프·노선색(7), `Theme.bg` 배경, 섹션 순서(헤더→지도→출발→여정→캘린더→상세행), 캘린더 네 갈래 분기(REQ-022), 모든 문구.
- **협의 경위**: Agent 스폰 불가로 besir `ui-design` 전문가 대신 GLM(z.ai) 백그라운드 백엔드에 본 표의 독립 교차검증을 요청했다(결과는 `progress.md` §F.1에 기록). 표의 각 행은 실측 근거를 스스로 가지므로 협의는 이견 탐지용이다.
- **반영**: REQ-020·021·023

## 5. 관련 문서

- 루트 [plan.md](../../../plan.md) §Phase 1.7 — 설계 원본·카드 분할표(t2·t3·t4 행). 본 plan 단계에서 t4 행을 `SPEC-UIKIT-004`로 확정 기록한다
- [SPEC-UIKIT-002](../SPEC-UIKIT-002/spec.md) — t2a. §4 D-1(편집 위임 판단)·REQ-023(compact 이사의 전례)·§E.3 후속 표(N2·05분 이월)·AC-009 S8
- [SPEC-UIKIT-001](../SPEC-UIKIT-001/spec.md) — t1. 컴포넌트 언어·`BesirTime` 탄생
- [CLAUDE.md](../../../CLAUDE.md) — 여섯 계약(특히 5·6), 한 Day 파일 상한, 드라이버 실행 명령
- `hns-besir-app-verify` 스킬 — 빌드·테스트·설치 명령의 단일 출처. 명령을 새로 만들지 않는다

🗿 MoAI
