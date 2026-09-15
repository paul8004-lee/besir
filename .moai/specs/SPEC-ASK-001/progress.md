# SPEC-ASK-001 — progress.md

## §E.1 Plan-phase Audit-Ready Signal

plan_status: audit-ready
plan_complete_at: 2026-09-15

- 산출물: spec.md(REQ 16건, 대역 001/010/020/030/040, v0.2.0) + plan.md(M1~M6) + acceptance.md(AC-001~008) + progress.md — Tier M.
- 작성 시 실행 검증(2026-09-15, Bash 실측): SPEC ID 정규식 `SPEC-ASK-001` → 출력 `PASS`; `.moai/specs/` 스캔 → 기존 SPEC-ASK 0건(유일성 확인); frontmatter canonical 12 필드 + `tier: M`(스키마 SSOT 준수); Out of Scope — `### Out of Scope —` H3 5개, 각 `-` 불릿 포함.
- D-1(되묻기 빈도) 해소: 2026-09-15 사용자 확정 — 선택지 C(한 장의 묶음 카드 + 확인 버튼, 확인 시 툴 1회 호출). spec.md §4에 결정 기록과 근거 2건(중단 1회 / 세션 메모리 기각 — b303f41 부류)으로 반영, REQ-041 신설(REQ 16건), REQ-011~015·REQ-020·REQ-040 갱신, plan.md 해소 대기 마커 제거 — run-phase 착수 장애 없음.
- 검증 기준선(HEAD `707b9af`, 오케스트레이터 관측 보고 — 본 세션에서 재실행하지 않음): GuardDriver 전체 초록·proxy `npm test` 7/7·iOS·macOS BUILD SUCCEEDED 0 Swift 경고 — 게이트 이름으로만 인용. **드라이버 총 단언 수는 인용하지 않는다**(작성 후 클램프 통일 `Store.clampBuffer`/`Store.clampNotifyLead` 작업으로 단언 추가 진행 — 총수의 SSOT는 run-phase 실측).

## §E.2 Run-phase Evidence

run_status: in-progress (M1~M5 완료, M6만 남음)
commit: 7683700(M1~M3) · b9ef208(M4) · M5는 이번 커밋

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

M5 완료(2026-09-15, manager-spec 재위임 → 오케스트레이터 diff 전문 검증):
- `SPEC-ONTIME-001` v0.2.3 → **0.2.4**(as-built, status draft 그대로): REQ-061 "정확히 11개 툴" →
  **9개**(remember_fact·forget_fact 제거, GuardDriver "(e) 툴은 9개다" 단언 근거), REQ-063에서
  `ai_memory.json`·remember/forget 경로 삭제(`ai_history.json` 지속·실패 턴 롤백은 유지),
  acceptance.md AC-007 동조(✅ 마커 무변경 — 개정 후에도 코드가 만족) + 밀린 근거 줄번호 재실측,
  plan.md M5 행 갱신. 제목의 "장기 기억" 표현도 정리(§2.7·AC-007) — 디렉터리 전체 잔여 grep 0건 확인.
- `SPEC-ASK-001` spec.md 0.2.1 → **0.2.2**(지시가 인용한 0.2.0은 낡은 기준선이었음 — 전문가가 밝히고
  한 단계 위로 bump): 착수 확정 읽기 3건 본문 반영 — REQ-005(출발지 부재도 카드, `orDefault:`로
  폴백 격리·`check_travel_time`만 활성), REQ-011(create_activity는 오가는 이동이 있을 때만 카드 행,
  왕복은 가는 편·오는 편 따로), REQ-014(이동수단 행 `[직접입력]` 미부침 예외 — 세 칩 = 전체 집합).
- 검증: diff 4개 파일 +16/−14(문서만), REQ-061/063 개정 원문 대조, "장기 기억" 잔여 0건.

미해결(다음 세션):
- (없음 — M1~M6 전부 완료. 남은 것은 사용자 실기기 확인(AC-008)뿐)

M6 완료(2026-09-15, 오케스트레이터 직접 게이트 + 하네스 2인):
- 게이트(최종 트리 `b1771ae` = F1 수정 포함, 실측): GuardDriver **88/88** · proxy **7/7** ·
  iOS·macOS **BUILD SUCCEEDED·Swift 경고 0건**(appintentsmetadataprocessor 공지 제외 필터).
  같은 게이트를 abd1832에서도 관측(한 번은 ux-check 하네스가 독립 실행) — 2회 관측.
- code-safety 하네스: **카드 확인 경로의 실패 묻힘은 무죄**(확인의 툴 실패는 contents에 남고 폴백
  seed로 작동, 미응답 카드는 `cancelPendingAsk` 안내 말풍선 전환, 이중 탭 `guard !isThinking` 차단
  — 드라이버 Q절이 단언). 신규 결함 1건 **F1**(중-하): 카드 "현재 위치" 칩 실패 문구에 내부 토큰
  `__current_location__` 노출 → ai-tooling이 배포 전 수정(보간 제거·고정 안내, `:1043`.
  `resolveOrigin` 나머지 호출 2곳 `:1245`·`:1791`은 유출 없음 확인). 사전 존재 부채 3건은 회귀
  아님으로 기록만: F2 캘린더 제거 fire-and-forget 6곳, F3 bubbles 무상한(기존과 동일),
  F4 드라이버 백업-복원 창 — **드라이버 동시 실행 금지** 운영 규칙으로 대응.
- ux-check 하네스: `CHECKLIST.md` 전면 재생성(95행 = ✅86·⚠️6·❌2·의도적 미제공 1). 이전 ⚠️ 중
  D7(생성 경로 클램프 없음)은 e10b292로 해소, G절(기억)은 제거 설계대로 재작성, 카드 G4~G14·
  보류 중 강제 종료 L12 신규. 근거 줄번호는 이번 트리에서 전수 재실측.
- 실기기: iPhone 15(UDID 8D9B…31A1F) 서명 빌드 → **설치·실행 완료**(`devicectl` 관측:
  "Launched application with com.iseongmin.besir bundle identifier", 2026-09-15 16:47).
  AC-008의 사용자 확인 목록 12항목 전달

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

run_status: audit-ready
run_complete_at: 2026-09-15

- M1~M6 전부 완료. 커밋: 7683700(M1~M3) · b9ef208(M4) · abd1832(M5) · b1771ae(M6 — F1 수정·체크리스트).
- 게이트(최종 트리 b1771ae 실측): GuardDriver 88/88 · proxy 7/7 · iOS·macOS 무경고 빌드.
- AC-001~006 관측 근거 확보(드라이버 단언·코드·개정 문서), AC-007 게이트 통과.
  **AC-008(실기기)만 사용자 확인 대기** — 확인 목록 12항목 전달.
- 잔여 관찰(코드 수정 대상 아님 — 실기기 대화에서 관찰): 모델이 재호출 시 미선언 인자 복사에
  실패해 카드가 한 번 더 뜨는지(안전하지만 재질문), stated 값은 카드에서 수정 불가이므로 재발화
  안내가 충분한지.

## §E.4 Sync-phase Audit-Ready Signal

_<pending sync-phase>_
