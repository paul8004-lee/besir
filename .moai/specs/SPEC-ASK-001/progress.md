# SPEC-ASK-001 — progress.md

## §E.1 Plan-phase Audit-Ready Signal

plan_status: audit-ready
plan_complete_at: 2026-09-15

- 산출물: spec.md(REQ 16건, 대역 001/010/020/030/040, v0.2.0) + plan.md(M1~M6) + acceptance.md(AC-001~008) + progress.md — Tier M.
- 작성 시 실행 검증(2026-09-15, Bash 실측): SPEC ID 정규식 `SPEC-ASK-001` → 출력 `PASS`; `.moai/specs/` 스캔 → 기존 SPEC-ASK 0건(유일성 확인); frontmatter canonical 12 필드 + `tier: M`(스키마 SSOT 준수); Out of Scope — `### Out of Scope —` H3 5개, 각 `-` 불릿 포함.
- D-1(되묻기 빈도) 해소: 2026-09-15 사용자 확정 — 선택지 C(한 장의 묶음 카드 + 확인 버튼, 확인 시 툴 1회 호출). spec.md §4에 결정 기록과 근거 2건(중단 1회 / 세션 메모리 기각 — b303f41 부류)으로 반영, REQ-041 신설(REQ 16건), REQ-011~015·REQ-020·REQ-040 갱신, plan.md 해소 대기 마커 제거 — run-phase 착수 장애 없음.
- 검증 기준선(HEAD `707b9af`, 오케스트레이터 관측 보고 — 본 세션에서 재실행하지 않음): GuardDriver 전체 초록·proxy `npm test` 7/7·iOS·macOS BUILD SUCCEEDED 0 Swift 경고 — 게이트 이름으로만 인용. **드라이버 총 단언 수는 인용하지 않는다**(작성 후 클램프 통일 `Store.clampBuffer`/`Store.clampNotifyLead` 작업으로 단언 추가 진행 — 총수의 SSOT는 run-phase 실측).

## §E.2 Run-phase Evidence

run_status: in-progress (M1~M4 완료, M5~M6 미착수)
commit: 7683700 `feat(SPEC-ASK-001): 얕은 메모리 제거 + 앱 주도 되묻기 카드 (M1~M3, 중간 저장)` / M4는 이번 커밋

착수 전 기준선(2026-09-15, HEAD 7b623c3에서 오케스트레이터가 직접 실행해 관측):
GuardDriver **67/67**, proxy `npm test` **7/7**, iOS·macOS **BUILD SUCCEEDED, Swift 소스 경고 0건**.

구현 후 관측(같은 날, HEAD 7683700):
- iOS `xcodebuild -scheme besir-iOS …` → **BUILD SUCCEEDED**, Swift 소스 경고 0건
- macOS `xcodebuild -scheme besir-macOS …` → **BUILD SUCCEEDED**, Swift 소스 경고 0건
- GuardDriver → **56/67**. 실패 11건은 전부 **낡은 단언**이고 신규 결함이 아니다:
  M절 3건(`기간(weeks) 비었으면 되묻는다` / `weeks 0은 '없음'` / `weeks 상한 초과`)은 `weeks`를
  툴 선언에서 뺐으므로 그 되묻기 갈래 자체가 사라져 도달 불가; O절 8건은 호출 인자에
  `mode_this_time`(및 일부 `origin_query`)이 없어 `missingAskedArguments` 가드에 먼저 걸린다.
- proxy `npm test` → **미실행**(본 SPEC은 `proxy/`를 건드리지 않음 — PRESERVE)

M4 완료(2026-09-15, HEAD 82c9df9 위 작업 트리):
- GuardDriver → **88/88 통과**(67 − 삭제 3 + 신규 24, 산술 일치). 낡은 단언 정리 — M절 weeks 3건 삭제
  (weeks가 툴 선언에서 빠져 갈래 소멸; 자리에 이유 주석. 빈 값·상한 검사는 카드 입력 `AskField.accepts`로 이주),
  O절 8건은 픽스처에 `mode_this_time`(O4엔 `notify_lead_minutes`까지) 추가해 `missingAskedArguments`를
  통과시킴 — **단언 문구·기대값 무변경**(클램프는 M1~M3에서 불변). 신규 — P절 REQ-020 카드 단언 19건
  ((a)~(e); `fillStated`→`pendingAsk`→`choose`→`resolvePendingAsk` 실제 경로를 탐. 두 번째 확인 무동작으로
  "정확히 1회"까지 검증), Q절 REQ-040/041 무기억 회귀 5건(같은 인스턴스 둘째 요청 재질문, Config에
  preferred* 부재, 보류 카드 미저장 — 진짜 기기 데이터 디렉터리 백업·복원 후 저장 본문 검사).
- 오케스트레이터 재검증(같은 날): 같은 명령 재실행 → **88/88, exit 0, 컴파일 에러 0건**.
  diff는 `Tools/GuardDriver.swift` 하나(+182/−13), `Shared/` 소스 무변경 확인.
- 구현 위임: ai-tooling 하네스 전문가. 드라이버가 잡은 신규 결함 없음(실패 11건 전부 낡은 단언).

미해결(다음 세션):
- M5: `SPEC-ONTIME-001` REQ-061·REQ-063 개정(본문 수정은 manager-spec 소관 — 재위임 필요).
  더불어 SPEC-ASK-001 spec.md에 확정 설계 결정 2건(출발지도 카드에서 묻기, create_activity 카드 대상)
  과 이동수단 줄 `[직접입력]` 미부침(세 칩 = 전체 집합) 읽기를 반영
- M6: 전체 게이트 재확인, 루트 `plan.md` §6 Phase 1.5 완료 표시, 실기기 배포(AC-008)

착수 시 확정한 설계 결정 2건(사용자, 2026-09-15 — spec.md 반영은 M5로 미룸):
1. **출발지도 카드에서 묻는다.** REQ-005의 "부재는 부재로 관측되어 칩 요청으로 흐른다"를 문자 그대로
   적용했다. `resolveOrigin`의 조용한 즐겨찾기 '집' → 현재 위치 폴백은 `orDefault:`로 가뒀고, 켜는
   곳은 `check_travel_time`(조회, 되물을 이유 없음) 하나뿐이다.
2. **create_activity도 카드 대상.** 단, 오가는 이동을 실제로 만들 때만 — 머무는 시간만 있는 활동은
   그 값들을 쓰지 않으므로 묻지 않는다. 왕복이면 가는 편·오는 편 수단을 따로 묻는다(Day 7 요청 보존).

승인 형태(spec.md §4)와 달라진 점 1건 — 이동수단 줄에 `[직접입력]`을 붙이지 않았다.
REQ-014의 근거가 "칩은 모든 값을 열거할 수 없으므로"인데 `TransportMode`는 세 칩이 곧 전체 집합이라
그 근거가 성립하지 않고, §4의 승인된 그림도 그 줄에는 `[직접]`이 없다. 직접입력이 없어도 고를 수
없는 값이 생기지 않음을 확인했다. M5에서 spec.md에 이 읽기를 명시한다.

## §E.3 Run-phase Audit-Ready Signal

_<pending run-phase>_

## §E.4 Sync-phase Audit-Ready Signal

_<pending sync-phase>_
