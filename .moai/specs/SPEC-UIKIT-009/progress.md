# SPEC-UIKIT-009 — progress.md

칸반 카드 t17 · C8 U-1 편집 카드 통일. 2026-09-30 plan 레인(`manager-spec`)이 작성했고, 같은 날 plan-audit 1회차 뒤 0.1.1로, 2회차 뒤 0.1.2로 고쳤고, 운영자의 iOS 전용 방침(P-1)을 받아 0.1.3으로 고쳤다. 2026-10-05 3회차 감사의 blocking 결함 D20~D24만 고쳐 0.1.4로 올렸다(아래 0.1.4 수정 기록). 워크트리 `.claude/worktrees/t17`(브랜치 `WT-edit-card-unify`), 기준 트리 `b2c3987`.

## §E.1 Plan-phase Audit-Ready Signal

- **kickoff_gate: resolved (2026-09-30)** — `plan.md` §2의 결정 13건(D-1~D-13)이 모두 해소됐다. 출처: 운영자의 답이 **칸반 리드 → 이 plan 세션** 경로로 전달됐다(이 세션은 운영자의 답을 직접 보지 않았다 — SPEC-UIKIT-008 HISTORY 0.1.3과 같은 표기). 권장안 12건 채택, D-8은 (b). review-1 D3에 대한 운영자 선택 (b)는 D-14로 기록했다. 이것은 결정 게이트의 해소이지 run 착수 승인(Implementation Kickoff Approval)이 아니다 — 착수 승인은 리드가 운영자에게 받는다. 확인 필요 표식 문자열의 잔여 건수는 SPEC 디렉터리 일곱 파일 모두 0이다(아래 표).
- **방침 P-1 반영 (0.1.3, 2026-09-30)** — iOS 전용 개발·검증. 운영자 방침을 칸반 리드가 전했다(이 세션은 운영자의 말을 직접 보지 않았다). 원문은 `master`의 `CLAUDE.md:10-12`(커밋 `00cd149`)이고 이 워크트리의 `CLAUDE.md`에는 없다 — 이 세션이 `git log`·`git show`로 읽었다(아래 0.1.3 개정 기록). 결정 게이트가 아니므로 해소할 표식을 만들지 않았다(`plan.md` §2 P-1).
- **Tier: L** — 요구사항 23 > Tier M 상한 16이 강제한다(Tier L 상한 25 — 여유 2). 수락 기준 24(여유 1). 파일 수(예측 10)만 보면 M이다. 측정과 어긋나지는 않는다(`spec.md` §0, `plan.md` §0). 배달은 카드 셋(D-11 (a)), 순서 MA → MB → MC(MC는 MA에 기댄다).
- 산출물: `spec.md` · `plan.md` · `acceptance.md` · `design.md` · `research.md`(Tier L 다섯) · `spec-compact.md` · `progress.md`(이 파일).
- 작성 주체: 일곱 파일 모두 `manager-spec`(서브에이전트)이 썼다. 이 SPEC 디렉터리 밖에는 쓰지 않았고, 코드·빌드·드라이버 실행·커밋·푸시를 하지 않았다(오케스트레이터 지시).
- **신호 줄(`plan_complete_at`·`plan_status`)은 이 레인이 적지 않는다.** 독립 plan-auditor 통과 뒤 오케스트레이터가 붙인다.
- 하네스 배정(plan 단계): **0명** — 렌즈 셋은 오케스트레이터가 이미 돌렸고 이 레인은 읽기 전용 재측정과 문서 작성만 했다(`plan.md` §4).

### plan-audit 기록

| 회차 | 판정 | 보고서 | 이 레인의 대응 |
|---|---|---|---|
| 1 | FAIL · 0.73(MP-7 실패 · 결함 D1~D13, blocking 9 · optional 4) | `.moai/reports/plan-audit/SPEC-UIKIT-009-review-1.md` | 0.1.1: D1~D10·D12·D13 수리, D11 불채택(오케스트레이터 지시). 결함별 위치는 `spec.md` HISTORY 0.1.1과 `research.md` §4.1 |
| 2 | FAIL · 0.84(must-pass 전부 PASS · 통과선 0.85 · 결함 D14~D17 blocking, D18·D19·D11 optional) | `.moai/reports/plan-audit/SPEC-UIKIT-009-review-2.md` | 0.1.2: D14~D19 수리(D18·D19 채택), D11 불채택. REQ 23 · AC 24 그대로. 결함별 위치는 `spec.md` HISTORY 0.1.2와 `research.md` §4.2. 3회차가 마지막 감사다(FAIL이면 운영자에게 올라간다) |
| 3 | FAIL · 0.84(must-pass 전부 PASS · 통과선 0.85 · 결함 D20~D24 blocking, D25~D29·D11 optional · 3회차 상한) | `.moai/reports/plan-audit/SPEC-UIKIT-009-review-3.md` | 0.1.4: D20~D24만 수리(오케스트레이터 지시 — 결함 목록으로 한정한 재감사용). D25·D27~D29·D11 불채택. 결함별 위치는 아래 0.1.4 수정 기록 |

0.1.3은 감사 결함의 수리가 아니라 방침 P-1의 반영이었고 3회차 감사가 그 판을 봤다. 0.1.4(이 판)는 3회차 결함 D20~D24의 수리다.

### 0.1.2 적대적 자기 점검 — 새로 쓰거나 고친 문장이 덮는 것과 못 덮는 것

두 감사 모두 앞 판이 새로 쓴 문장에서 막히는 결함을 찾았고 부류가 같았다(한 모양·한 날·한 환경에 쓴 규칙이 다른 것을 놓침). 그래서 고친 문장마다 네 축을 대조했다. 모양은 `design.md` §4의 (가) 도착 기준 · (나) 출발 기준 새로 만듦/고침 · (다) 출발 기준 재추정 실패 · (라) 출발 기준 반복 뒤 회차다. "새로 만든 가는 편/오는 편 실패"는 (가)/(나), "재추정 실패"는 가는 편이면 (가)·오는 편이면 (다)다.

| 문장(자리) | 덮는 모양 | 덮는 날 | 덮는 환경 | 덮는 역할 | 못 덮는 것 → 처리 |
|---|---|---|---|---|---|
| REQ-023 문장·근거 (`spec.md` §2 F) | (가)(나)(다)(라) + `anchor` nil 옛 모양 | 한 날 · 자정을 넘는 구간의 시작일(앵커가 든 날에 나열) · 끝날(나열하지 않음을 명시) | 규칙이라 환경과 무관 | 가는 편 · 오는 편 · 단독 이동(레코드 모양만 봄) | 이동시간 계산된 구간은 "지금 그대로"로만 덮음(바꾸지 않음) · `d3c9327` 이전 데이터의 "도착 기준인데 출발은 있고 이동시간 없음" 모양은 새로 경고가 됨 → `plan.md` §3 갭 · 실패 구간의 끝날·가는 편의 원래 출발일에는 아무것도 없음 → `design.md` §4 명시한 갭 |
| REQ-010 근거 추가 | (가)(나) — 카드 저장 순간 | 한 날(날짜 무관) | 온라인·오프라인(플래그 = 레코드) | 활동 카드의 가는 편·오는 편 | 재추정 실패의 결과 보고 없음 → `spec.md` §3 마지막 절 · 단독 이동 폼(`AddEventView`)의 결과 보고는 이 카드 밖(변경 없음) |
| REQ-020 문장·근거 | (다)(가) 재추정 — 결정적 · (가)(나) 새로 만듦 — 도달 기록 · 판정·배치 — 메모리 구성(네 모양) | 판정·배치 쪽은 한 날·자정(AC-010 (12)(13)·AC-017 (9)) | 게이트(온라인) · 이름 붙인 오프라인 실행 · 결정적(환경 무관) | 레코드 모양 기준 | (라)는 기준 트리에서 재현하지 않음(메모리 구성으로만 — 반복 생성의 첫 회차를 실패시킬 결정적 수단이 없다: `addRecurringEvents`의 출발지는 비-Optional `Store.swift:629`) → 갭 · 추정 실패 guard(`:1006`·`:1031`) 쪽 도달은 오프라인 실행에만 → 도달 기록 · 오프라인 ✗ 집합은 전제 두 줄 밖은 미측정 |
| `design.md` §4 표·규칙·실례 | 넷 모두(표) · 실례는 (다) 한 날·자정, (나) 자정, (가) 자정 | 한 날 · 자정 시작일 · 끝날 | — | 오는 편 실례·가는 편 실례 | (라)의 자정 실례 없음 — 앵커가 `arrivalDate`라 (가)와 같은 규칙(표에 적음) · 23:50 경고 블록의 아래 넘침 11.4분은 기존 동작과 같음(실례에 적음) |
| `design.md` §6.2 문장 · §6.3 E9 | (다) — 묶음 안 겹침이 생기지 않음 | 자정 시작일(E9) · 끝날(목록에 없음) | 순수 함수라 환경 무관 | 명시 연결 오는 편 | (나)·한 날 (다)의 배치는 따로 실례가 없음 — 같은 앵커·같은 맞닿음이라 E9와 같은 모양(AC-010 (11)이 앵커를 본다) · 추정 묶음(반복)의 (다)는 추정이 `arrivalDate`로 같은 날을 대조하므로 옛 도착이 다음 날이면 묶음에서 빠짐 → 기존 약점과 같은 부류(갭) |
| AC-010 (4)(10)–(13) · Given | (4) (가)(나) · (10) (다)(가) · (11) 넷 + 옛 모양 + 대조군 · (12) (다)(나)(가) 자정, (라) 한 날, 대조군 · (13) (12)의 레코드 전부 | 한 날 · D · D+1 · (13)은 D−1…D+2 | (4)만 오프라인 의존(도달 기록) · 나머지 결정적 | 링크 없는 레코드 — 단독 이동으로 만들고 역할 무관임을 Given에 적음 | 도착 기준 (가)의 **재추정** 모양을 자정 판으로는 보지 않음 — (가)는 만든 경로와 무관하게 같은 모양이라 (12)의 자정 (가)가 덮음 · ContentView가 날짜 판정 함수를 부르는지는 드라이버가 못 봄 → (9) grep 대리 지표 |
| AC-015 Given·(9)·(11) | — (반복 추정) | 내일 · 모레 · 글피 | 결정적(메모리 구성) | 반복 회차의 가는 편·오는 편 | 같은 날·같은 반복·같은 장소 이름의 두 회차 → 명세하지 않음(`design.md` §5, `plan.md` §3 갭) |
| AC-017 (9) · Given | (다) 자정 | D(시작일) · D+1은 AC-010 (12)에 맡김 | 결정적 | 명시 연결 오는 편 | 한 날 (다)·(나)·(라)의 배치 실례 없음(위 §6.3 줄과 같은 이유) |
| AC-020 (5) · 결정성 문단 · `plan.md` §5 | 실패 모양 세 갈래 | — | 온라인 게이트 · 오프라인 도달 실행(선택) · 결정적 | — | 판정 레인이 네트워크를 끌 수 없으면 도달 기록은 "아니오 — 전제 없음"으로 남음(갭, 실패 아님) |
| 스크립트 20 · 20b (사람) | 20: (나) · 20b: (다) | 한 날 | 시뮬레이터(오프라인 전환) | 활동에 연결된 오는 편 | 자정 판은 시뮬레이터 스크립트 없음(시계 조작 필요) · 단독 이동의 실패 표시·반복 뒤 회차 (라)는 사람 스크립트 없음 → 기계 쪽 AC-010이 덮음 · 경고 블록으로 바뀐 오는 편의 끌기 강조 없음 → `design.md` §9·`plan.md` §6 |

### 0.1.3 개정 기록 — 방침 P-1(iOS 전용 개발·검증)

방침을 따르느라 바뀐 자리만 고쳤다. 감사가 옳다고 본 문장 가운데 방침과 무관한 것은 건드리지 않았다(아래 "그대로 둔 것"). 요구사항 23 · 수락 기준 24는 그대로다.

**고친 자리와 그대로 둔 것**

| 파일 | 고친 자리 | 그대로 둔 것(이유) |
|---|---|---|
| `spec.md` | `version` 0.1.3 · HISTORY 0.1.3 행 · §0 "빌드 기준선" 행(iOS만) · [DELTA] E의 [EXISTING] "iOS 빌드 무경고" · REQ-019의 끝 절과 근거(플랫폼 절 = 방침, 코드 사실은 측정으로) · §3 새 절 "맥 앱의 빌드와 검증"(받아들인 갭) · §4 한 문장(P-1은 방침) | HISTORY 0.1.0 행의 "iOS·macOS 전체 빌드"(그때의 기록) · REQ-018 근거의 "iOS의 탭·길게 누르기"(iOS 사실) · 나머지 REQ 22건 |
| `acceptance.md` | 머리말 ② 누적 기준에 (6) · 매트릭스 AC-019 카드 열 (6) · AC-024 행 14~22 · AC-019 머리(여섯·명령 4)와 새 (6) · AC-020 (3)(iOS만) · AC-024 제목·관측자·Given·When·Then · 스크립트 23 → 뺀 기록 한 줄 · § 통과 수에 0.1.3 문단 · "SPEC 하나의 완료"의 1~22 | 드라이버 항목·grep 항목 전부 · 스크립트 1~22의 문구(18·19의 "(iOS)"는 제스처가 iOS 코드라서, 13a·20의 "Mac 네트워크 차단"은 시뮬레이터를 돌리는 호스트의 네트워크라서 그대로다) |
| `plan.md` | 머리 한 줄 · §0 여유 문단 · §1 sync 행 (6) · A5 · C3 · C4 · §2 머리와 **방침 P-1** · §3 위험 한 줄 · §4 `code-safety`의 (6) 갭 몫 · §5 머리(맥 명령 제외)·두 기준 커밋 (6)·맥 행 삭제·불변식 행 (6)·기준선 문단·돌리지 않은 것 · §6 후속 한 줄 | D-1~D-14 본문 · §3의 "iOS 탭·길게 누르기" 줄 · 드라이버·iOS·재현·오프라인·범위·인용 행 |
| `progress.md` | 머리 줄 · §E.1 P-1 줄 · 감사 표 2행의 "(이 판)" · 오케스트레이터 로그 표 빌드 세 줄(iOS만)과 역사 관측 한 문장 · 표 크기 52행 · Gaps 두 줄과 스크립트 범위 · 잔여 위험 한 줄 · 이 기록 | §E.2~§E.4(다른 레인 몫) · 0.1.0~0.1.2 행 |
| `research.md` | §1 포인터("표 마지막 묶음" → "표 34·35" — 0.1.1부터 이미 낡은 포인터였다) · 표 35(iOS만, 이 세션이 다시 셈) · 표 50~52(방침 출처·플랫폼 분기·양성 대조) · §6 "두 플랫폼의 같음" 삭제와 맥 타깃 갭 한 줄 · §7 한 문장 | §4 전부 · 표 1~34·36~49 |
| `spec-compact.md` | 머리의 버전·방침 문장 · REQ-019(원문과 한 벌) · AC-019·AC-020·AC-024 행 · 범위 밖 새 절 | 나머지 REQ 22건 · 다른 AC 행 |
| `design.md` | 고치지 않았다 — 플랫폼·맥 빌드 문장이 0건이다(`grep -n -i "macos\|맥\|플랫폼\|iOS" design.md` → 무출력). 탭·히트테스트 문장(§6·§9)은 플랫폼을 말하지 않는다 | 전부 |

**통과 수 — AC마다 다시 셌다(iOS 기준)**

`T = 357 − 뺀 수 + 더한 수`, 기준 357은 그대로다. "드라이버"는 AC 머리의 드라이버 하한(그 AC가 더하는 ✓ 줄의 바닥)이고, "명령"은 grep·`git diff`·빌드처럼 드라이버가 찍지 않는 판정, "사람"은 시뮬레이터 단계, "갭"은 머리에 갭으로 센 항목이다(항목 안에 적힌 한계 — AC-001 (3) · AC-007 (8) · AC-019 (6) — 는 그 항목의 분류로 센다).

| AC | 드라이버(접두) | 명령 | 사람 | 갭 | 0.1.3의 변화 |
|---|---|---|---|---|---|
| 001 | 3 (AF) | 2 | 1 | 1 | — |
| 002 | 7 (AF) | 0 | 0 | 0 | — |
| 003 | 5 (AF) | 0 | 0 | 0 | — |
| 004 | 6 (AF) | 0 | 0 | 0 | — |
| 005 | 2 (AF) | 1 | 0 | 1 | — |
| 006 | 6 (AG) | 4 | 0 | 0 | — |
| 007 | 8 (AF) | 0 | 0 | 0 | — |
| 008 | 5 (AF) | 0 | 0 | 1 | — |
| 009 | 5 (AF) | 0 | 0 | 0 | — |
| 010 | 12 (AF 5 · AH 7) | 1 | 3 | 0 | — |
| 011 | 3 (AG) | 1 | 0 | 1 | — |
| 012 | 5 (AF) | 0 | 0 | 1 | — |
| 013 | 3 (AF) | 1 | 1 | 0 | — |
| 014 | 3 (AF) | 1 | 1 | 0 | — |
| 015 | 12 (AF 4 · AH 8) | 1 | 0 | 0 | — |
| 016 | 2 (AH) | 3 | 0 | 0 | — |
| 017 | 9 (AH) | 0 | 0 | 0 | — |
| 018 | 5 (AF 3 · AH 2) | 0 | 1 | 0 | — |
| 019 | 2 (AF) | **4** | 0 | 1 | 명령 3 → 4 (새 (6)) |
| 020 | 0 | 5 | 0 | 0 | (3)에서 맥 절을 뺐다 — 항목 수는 그대로 |
| 021 | 0 | 4 | 0 | 0 | — |
| 022 | 0 | 3 | 0 | 0 | — |
| 023 | 0 | 0 | 14단계(1~13 · 13a) | 0 | — |
| 024 | 0 | 0 | **11단계**(14~22 · 20a · 20b) | 1 | 12 → 11 (스크립트 23을 뺐다) |

드라이버 열: AF = 3 + 7 + 5 + 6 + 2 + 8 + 5 + 5 + 5 + 5 + 3 + 3 + 4 + 3 + 2 = **66** · AG = 6 + 3 = **9** · AH = 7 + 8 + 2 + 9 + 2 = **28** · 합 **103**. 누적 바닥(직렬): MA 뒤 357 + 66 = **423** · MB 뒤 423 + 9 = **432** · MC 뒤 432 + 28 = **460**. 0.1.2와 같다 — 바뀐 세 자리(AC-019 명령 +1, AC-020 (3)의 명령 축소, AC-024 사람 −1)가 모두 드라이버 열 밖이기 때문이다. 기계 대조: AC 머리의 드라이버 하한 19개의 합과 `acceptance.md` § 통과 수 표의 접두별 합을 스크립트로 맞춰 봤다(아래 명령 표).

**적대적 자기 점검 — 지우거나 고친 문장마다 그것에 기대던 문장**

| 지우거나 고친 문장 | 기대던 문장·수 | 고쳤나 |
|---|---|---|
| `spec.md` §0 빌드 기준선의 맥 절반(38 · 경고 0 · "둘 다") | `plan.md` §5 기준선 문단 · `progress.md` 로그 표 세 줄 · `research.md` 표 35 · HISTORY 0.1.0 | 셋 고침. HISTORY 0.1.0은 그때의 기록이라 둠 |
| [DELTA] E "두 빌드 무경고" | AC-020 (3) · `spec-compact.md` AC-020 행 · `plan.md` A5 · C3 "두 플랫폼 빌드" | 넷 고침 |
| REQ-019 "iOS와 macOS에서 같게 동작(재배치 오버레이 제외)" | `spec-compact.md` REQ-019(문장 대조 `mismatch []`) · 검증 AC-019 · AC-024 Then "두 플랫폼의 같음" · 스크립트 23 · `research.md` §6 "두 플랫폼의 같음" | 전부 고침. 새 절의 검증은 AC-019 (6)(명령)이고 매트릭스·`plan.md` §1 sync 행·머리말 ②·`plan.md` §5 두 곳에 (6)을 더했다 |
| REQ-019 근거 "`RescheduleOverlay`만 iOS 전용(`#if os` → 4)" | 다른 문서의 인용 없음(`grep -rn '#if os'` → REQ-019·AC-019 (6)·P-1·표 51뿐) | 측정한 줄 목록으로 바꿈(`:2`·`:195` 맥·`:454`·`:857`) |
| AC-020 (3) "iOS·macOS BUILD SUCCEEDED" | `plan.md` §5 맥 행 · "run 게이트" 목록(`plan.md` §1 A5·C3·C4) · `acceptance.md` "카드 하나의 완료"(AC-020을 이름으로만 부른다) | 맥 행 삭제 · A5·C3 고침 · 완료 정의는 AC-020을 가리키기만 해 고칠 문구 없음 |
| 스크립트 23 | AC-024 제목·When·Then · 매트릭스 AC-024 · `spec-compact.md` AC-024 · `plan.md` C4 · "SPEC 하나의 완료" · `progress.md` Gaps · 스크립트 순서(22가 마지막, 23을 앞뒤로 가리키는 단계 없음) · 초기화 지점(1·11·13·14 — 무관) | 전부 고침. 포인터 스크립트: 정의된 단계 25개, 1~22 연속, 가리키는 번호 120개 중 없는 번호는 뺀 기록 세 줄의 "23"뿐(아래) |
| `spec.md` §3에 새 절 | "§3 마지막 절"을 가리키는 네 자리(REQ-010·REQ-023 근거 · `progress.md` REQ-010 행 · `plan.md` §6 `conflicts` 줄)와 "§3 첫 절"(`plan.md` §3) | 새 절을 "저장 경로의 기존 결함" **앞**에 넣어 두 포인터가 그대로 맞는다 · Out of Scope 절 6 → 7(린트 다시 돌림) |
| `progress.md` 로그 표의 맥 값 | 역사 관측 한 문장(기준 아님으로 표시) | 표에서 뺐고 문장으로만 남김 |
| `research.md` 표에 50~52행 | `progress.md` "전체 표(49행)" | 52행으로 고침 |
| Day 닫기 검증 목록(`acceptance.md` "실기기 전용" · `plan.md` §4 Day 닫기) | 맥 항목 없음 — `master` `CLAUDE.md:126`의 Day 닫기 규칙(iOS 무경고)과 AC-020 (3)이 같다 | 고칠 것 없음 |
| 통과 수 | 인용하는 자리 — `acceptance.md` AC-020 (1)·§ 통과 수 · `plan.md` §5 · `spec-compact.md` 두 줄 · HISTORY 0.1.2·0.1.3 | 값이 그대로라 고칠 것 없음(`grep`으로 인용을 모두 찾아 대조) |

**맥 동작을 검증했다거나 시험으로 지킨다고 말하는 REQ·AC가 남았나** — 없다. REQ-019는 "지우지 않음"과 "어느 게이트도 맥을 빌드·검증하지 않음"을 함께 말하고, AC-019 (6)은 분기 줄이 사라지지 않았다는 대리 지표라고 스스로 적으며 "맥 쪽 동작을 판정하지 않는다"고 못박는다. AC-024에서 "두 플랫폼의 같음"을 뺐다. REQ-015~018·023은 공유 코드의 동작을 플랫폼 없이 말하지만, 그 AC는 드라이버(플랫폼과 무관한 순수 함수·Store)와 iPhone 시뮬레이터에서만 판정한다 — 맥에서의 성립은 주장하지 않고, 그 공백이 `spec.md` §3의 받아들인 갭이다.

**0.1.3에서 이 레인이 돌린 명령**

| 명령 | 관측된 출력 | 쓰인 곳 |
|---|---|---|
| `git branch --show-current` · `git rev-parse --short HEAD` | `WT-edit-card-unify` · `b2c3987` | 기준 트리 그대로 |
| `git log --oneline -3 master` · `git show --stat --format='%h %s' 00cd149` · `git show 00cd149:CLAUDE.md \| sed -n 10,12p` · `git show 00cd149:CLAUDE.md \| grep -n 'iOS 전용\|macOS는 2026-09-30\|맥 앱은'` | 맨 위 `00cd149 docs: iOS 전용 전환 — 맥 빌드·검증 중단, 코드는 보존 (운영자 지시 2026-09-30, card t38)` · `CLAUDE.md \| 9 +++++++--` · 방침 원문 세 줄 · `:10`·`:11`·`:57`·`:126` | 방침 P-1 출처 |
| `grep -n "macOS\|양쪽" CLAUDE.md`(이 워크트리) | `:8` · `:41` · `:53`(맥 빌드 명령) · `:121`("iOS·macOS 양쪽 **무경고** 빌드") | P-1 — 이 워크트리 판은 방침 이전 |
| `grep -n 'platform:\|- Shared$\|^  besir' project.yml` | `besir-iOS:` `:19` · `platform: iOS` `:21` · `- Shared` `:23` · `besirShare:` `:58` · `besir-macOS:` `:89` · `platform: macOS` `:91` · `- Shared` `:93` | 받아들인 갭(맥 타깃도 `Shared`를 컴파일) |
| `grep -rn '#if os\|#elseif os\|canImport(AppKit)\|canImport(UIKit)' Shared ShareExtension` · `grep -n '#if os\|#else\|#endif' Shared/ContentView.swift` · `sed -n 193,200p`·`452,460p`·`855,860p Shared/ContentView.swift` | 37줄(`canImport` 0) · `ContentView` `:2`/`:4` · `:195`/`:207`(맥 — 툴바 동기화 단추) · `:454`/`:486`(탭·드래그 오버레이) · `:857`/`:980` | REQ-019 근거 |
| `git grep -h -e '#if os' -e '#elseif os' b2c3987 -- Shared \| sed 's/^ *//' \| sort \| uniq -c` · `grep -c '#if os'` 선언 파일 일곱 | `25 #if os(iOS)` · `12 #if os(macOS)` · Store 2 · AddActivityView 1 · ActivityDetailView 1 · ContentView 4 · 나머지 0 | AC-019 (6) 기준값 |
| AC-019 (6)의 명령 — 기준 목록과 `HEAD` 목록을 스크래치 파일로 받아 `diff … \| grep -c '^<\|^>.*\(macOS\|AppKit\)'`, 그리고 한 줄 지운 사본 · `#if os(macOS)`를 더한 사본 · `#if os(iOS)`를 더한 사본 | `0` · `1` · `1` · `0` | AC-019 (6) 양성·음성 대조 |
| 오케스트레이터 로그 다시 셈: `grep -c '^SwiftCompile' ios-build.log` · `grep -n "BUILD SUCCEEDED" ios-build.log` · `grep 'warning:' ios-build.log \| grep -v 'Metadata extraction skipped' \| wc -l` · `grep -c 'warning:' ios-build.log` · `grep -c 'warning:' driver-compile.log` · `grep -c '^  ✓ '`·`'^  ✗ '` · `tail -3 driver-run.log` | `42` · `:944` · `0` · `2` · `24` · `357` · `0` · `357/357 통과` / `[실제 데이터] 대조 통과 …` / `run_exit=0` | 기준선(iOS) |
| `python3 <스크래치>/reqsync.py .moai/specs/SPEC-UIKIT-009`(REQ 문장 대조 + AC 머리 드라이버 하한 합 + § 통과 수 표 접두별 합) | `spec REQs 23 \| compact REQs 23` · `mismatch []` · `sum 103` · `AF … sum 66 \| table says 66` · `AG … 9 \| 9` · `AH … 28 \| 28` · `per-AC prefix sums == header: all equal` · `floors 423 432 460` | 요약본 동기 · 통과 수 |
| `python3 <스크래치>/trace.py .moai/specs/SPEC-UIKIT-009` | `REQ→AC plan §0 vs matrix-derived: identical` · `uncovered REQs: none` · `pointer problems: 0` | 추적성 · AC 항목 포인터 |
| `python3 <스크래치>/scripts.py .moai/specs/SPEC-UIKIT-009`(스크립트 번호 포인터 — "스크립트 N", "A~B" 범위, 나열) | `defined scripts: 1 … 13 13a 14 … 20 20a 20b 21 22 \| count 25` · `contiguous 1..max: True` · 없는 번호를 가리키는 자리는 **"스크립트 23"을 뺐다고 적은 기록뿐**(`spec.md` HISTORY 0.1.3 · `plan.md` P-1 · `acceptance.md` § 통과 수 · 이 기록의 표들)이고, 그 밖에 `plan.md` §1 MC 행 한 줄은 파서가 "20b · 015(…)"의 AC 번호 015를 스크립트로 읽은 오탐이다. 실제로 끊긴 포인터 0 | 스크립트 포인터 |
| (작성 뒤) `grep -c '^- \*\*REQ-' spec.md` · `grep -c '^## AC-' acceptance.md` · `grep -c '^### Out of Scope' spec.md` · `moai spec lint --strict .moai/specs/SPEC-UIKIT-009/spec.md` · `grep -rc` 확인 필요 표식 | `23` · `24` · `7`(0.1.2의 6 + "맥 앱의 빌드와 검증") · `✓ No findings — all SPEC documents are valid` · 일곱 파일 모두 `0` | 예산 · frontmatter · Out of Scope · MP-7 |
| (작성 뒤) `grep -rn -i "macos\|mac-build\|besir-macOS\|both builds\|두 빌드" .moai/specs/SPEC-UIKIT-009/` · `grep -rn "SwiftCompile" … \| grep 38` | 남은 자리는 모두 방침 기록·HISTORY·코드 사실(`#if os`·`project.yml` 타깃)·이 개정 기록 가운데 하나다(분류는 반환 보고) · `38`이 붙은 `SwiftCompile` 줄은 HISTORY 0.1.3의 "뺀 것" 하나뿐 — 기준으로 쓰는 자리 0 | 맥 기준 제거 확인 |

### 0.1.4 수정 기록 — review-3 결함 D20~D24 (2026-10-05)

범위는 오케스트레이터가 정한 다섯 결함뿐이다. 요구사항 23 · 수락 기준 24 · 드라이버 하한은 그대로이고, `Shared/`·`Tools/`는 바뀌지 않았다(`git diff --stat b2c3987 -- Shared Tools` → 무출력). 줄번호는 0.1.4 판 기준이다.

**먼저 발견한 것 — 기록 없는 선행 편집.** `acceptance.md`의 파일 시각은 `2026-09-30 19:59:19`로 3회차 보고서(`16:08:54`)보다 늦었고 다른 여섯 파일은 15시대였다(`stat -f '%Sm %N'`). 보고서가 인용한 원문과 대조하니 이 판 이전에 이미 들어가 있던 편집이 넷이었다 — D21의 AC-010 갭 줄과 머리의 "갭 1" · D22의 "세 구간"(L263·L274) · D23의 AC-010 (9) 일부(`Store.swift`를 grep 대상에 넣음, 다만 점의 규칙은 "후보 날 열거" 방식) · **D26**의 AC-002 When·(7) 문구. 어느 레인이 썼는지 이 세션은 모른다. D21·D22·D23 몫은 대조해 이 판의 수리로 맞췄고(아래 표), **D26 몫은 이 판의 범위 밖이라 손대지 않았다** — 되돌릴 원문을 확정할 수 없어(보고서는 일부만 인용) 그대로 두고 리드에게 알린다.

| 결함 | 바뀐 자리(파일:줄) | 전 → 후 | 확인 명령 → 관측된 출력 |
|---|---|---|---|
| D20 | `acceptance.md:367`(AC-022 Given) · `:370`(1) · `:371`(2) · `:372`(양성 대조) · `plan.md:52`(MB) · `:60`(MC) · `:284`(§5 범위 행) · `spec.md:175`(REQ-022 근거) · `spec-compact.md:76` | (1) `git diff --name-only <BASE> HEAD` → `… -- . ':!.moai/specs/SPEC-UIKIT-009' ':!.moai/reports'` · (2) `git diff --numstat <BASE> HEAD` → `… -- Shared Tools` · MB·MC 선언에 "문서: CHECKLIST·루트 `plan.md`는 sync" 없음 → 있음(MA `plan.md:40`과 같은 문구, `spec-compact.md:86-88`과 맞음) · REQ-022 근거에 경로 규칙 한 문장 | 양성 대조(병합된 t16 범위, 자기 SPEC 이름만 008로): `git diff --name-only 291c3cf^1 291c3cf \| wc -l` → `33` · 제외를 건 같은 명령 → `8`줄(SPEC-UIKIT-005 acceptance · CHECKLIST · plan · Shared 넷 · Tools) · `git diff --numstat 291c3cf^1 291c3cf \| awk '$1+$2>=100'` → `19`줄 · `-- Shared Tools`로 → `2`줄(AIAssistant 764/84 · GuardDriver 1661/6). 이 워크트리에서 `git diff --name-only b2c3987 HEAD -- . ':!…009' ':!.moai/reports' \| wc -l` → `0`(카드 커밋 없음). 전례 `SPEC-UIKIT-008/acceptance.md:271` 원문을 읽어 같은 pathspec 꼴임을 확인 |
| D21 | `spec.md:171`(REQ-020 문장과 근거 ②) · `spec-compact.md:41`(같은 문장) · `:64`·`:74`(AC-010·AC-020 행) · `acceptance.md:203`(AC-010 갭 줄) · `:349`(AC-020 (5) ⓑ) · `:48`(결정성 문단 ④) · `:403`(경계표 (라) 행) · `plan.md:45`(A1) · `:243`(§3) · 이 파일 Gaps 한 줄 | "a newly created leg" → "a leg newly created through `addEvent` (shapes (가)·(나))" · (라)를 갭으로 — "결정적 경로가 없고 그 레코드를 보는 단언도 없다, 메모리 구성 AC-010 (7)(11)(12)(13)으로만" · 경계표 (라) 행 `(7)(11)(12)` → `(7)(11)(12)(13)` | `sed -n 626,632p`·`654,680p Shared/Store.swift` → 출발지 비-Optional `:629` · 첫 회차 추정 `:673` · 캐시 `:674` · `else if let` `:676` · 캐시 적용 `:677`. AC-010 (7)(11)(12)(13)이 (라)를 메모리 레코드로 다루는지 본문 대조 → (7) "(나)·(다)·(라)에서 참" · (11) "(라) → `arrivalDate` D 15:00" · (12) "(라)(D 15:00) → D 참" · (13) "(12)의 레코드를 하나씩" — 넷 다 덮는다. **감사 문구와 다르게 쓴 곳**: 감사는 "도달 경로도 없다"고 했으나 `grep -n 'addRecurringEvents(' Shared/*.swift` → `AIAssistant.swift:2217`(오는 편, `:2218` `anchor: .departure`)이고 드라이버의 `return_time` 있는 반복(`Tools/GuardDriver.swift:2567` 등)이 그 길을 탄다 — 오프라인 실행에서 (라)가 부수적으로 생길 수 있다(코드 읽기, 실행하지 않음). 그래서 "도달 경로가 없다"가 아니라 "그 레코드를 보는 단언이 없고 요구하지 않는다"로 적었다. REQ 문장 대조 스크립트 → `spec 23 compact 23 mismatch []` |
| D22 | `acceptance.md:263`(AC-015 Given) · `:274`((9)) | "네 구간" → "세 구간"(선행 편집으로 이미 들어가 있었고 이 판은 대조만 했다) | `grep -n '네 구간' *.md`(SPEC 디렉터리 일곱 파일) → `spec.md:29`(HISTORY 0.1.4의 "전 → 후" 인용)와 이 기록의 이 행뿐 · `grep -n '세 구간' acceptance.md` → `:59`·`:240`(다른 AC, 실제로 셋) · `:263`·`:274`. 다른 문서에 같은 계수 없음 |
| D23 | `design.md:120`(§4 점 문단) · `:235`·`:236`(§9) · `acceptance.md:198`(AC-010 (9)) · `:9`(제안 이름 목록) · `spec.md:181`([NEW]) · `:184`(REQ-023 근거) · `plan.md:60`(MC 작게 고침) · `:64`(C3) · `spec-compact.md:64` | 점: "없으면 지금의 `:136-140`" → "나열 구간(제안 `listedSpan`)이 있으면 그 `[start, end]`를 `dayKeys`에, 없으면 `failedBlockAnchor ?? arrivalDate`의 날 키 하나" · (9): Store 쪽 `isListed(on:` ≥ 1 → `failedBlockAnchor` ≥ 1 그리고 `listedSpan` ≥ 1, `git grep` 명령 추가 · §9의 열린 항목 → 결정됨(이름·반환 모양만 열림) | `git grep -c 'e.arrivalDate > dep' -- Shared/Store.swift` → `Shared/Store.swift:1` · exit 0(기준). 0건일 때의 출력 형태: `git grep -c 'listedSpan' -- Shared/Store.swift` → 무출력 · exit 1 — 그래서 AC-010 (9)의 기대값을 "0"이 아니라 **무출력 · exit 1**로 적었다(지시는 "0"이었다). `grep -c 'e.arrivalDate > dep' Shared/Store.swift Shared/ContentView.swift` → `1` · `1` · `grep -c 'listedSpan\|failedBlockAnchor\|isListed(on:' Shared/Store.swift Shared/ContentView.swift Shared/Models.swift` → `0` · `0` · `0` · `awk '/func recomputeDaysWithSchedule/,/^    }$/' Shared/Store.swift \| grep -c departureDate` → `1`. `sed -n 28,40p`·`128,152p Shared/Store.swift`·`80,96p Shared/ContentView.swift`로 지금 두 사본(`:136` · `:89`)과 `overlapsDay`·`dayKeys`(`:157`)의 반열린 구간 규칙을 읽어 새 규칙이 계산된 구간에서 같은 날을 낸다고 확인(코드 읽기). `spec.md` [REMOVE](`:182`)는 이미 `Store.swift:136`을 적고 있어 그대로다 |
| D24 | `acceptance.md:336`(AC-019 (6) 갭) · `plan.md:267`(§4 `code-safety` 몫) · `:78`(P-1 "run이 하지 않는 것") · `:64`(C3) · `spec.md:169`(REQ-019 근거) · `spec-compact.md:73` | 갭이 "`#if os(macOS)` 구간에 닿은 헝크"만 → ⓐ 그것 + ⓑ 지시문 밖에서 주석이 맥 전용으로 밝힌 코드(`.onTapGesture` `:618`·`:641`·`:674`)를 지우거나 바꾼 헝크. 대리 지표는 더하지 않았다(지시) | `grep -n 'onTapGesture' Shared/ContentView.swift` → 코드 줄 `:618` · `:641` · `:674`(나머지 `:456`·`:459`·`:616`·`:625`·`:673`·`:883`은 주석) · `grep -n 'macOS' Shared/ContentView.swift` → `:195`(`#if os(macOS)`) · `:617` · `:625` · `:673` · `sed -n 612,628p`·`638,642p`·`670,675p`로 주석 원문 확인 |
| (덧) | `acceptance.md:330`(AC-019 머리) | "다섯 … 명령 항목 3 — (1)(3)(4) · 갭 2 — (5)와 목록 뒤 플랫폼 절 갭 줄" → "여섯 … 명령 항목 4 — (1)(3)(4)(6) · 갭 1 — (5)" | D24를 고치며 같은 AC를 훑다 찾았다 — 항목은 여섯이고 "목록 뒤 플랫폼 절 갭 줄"은 없다. 0.1.3 표(위, AC-019 명령 4 · 갭 1)와 3회차 감사의 계수(명령 (1)(3)(4)(6) = 4 · 갭 (5))가 이 분류다. 다섯 결함 밖의 정정이라 따로 적는다 |

**통과 수 — 바뀌지 않았다.** AC 머리의 드라이버 하한을 스크립트로 다시 합산 → `{'AF': 66, 'AG': 9, 'AH': 28} 103 423 432 460`. 바뀐 항목은 AC-010 (9)(명령) · AC-010 갭 줄 · AC-019 (6) 갭 · AC-020 (5) · AC-022 (1)(2)(명령)뿐이고 드라이버 줄이 아니다. AC별 분류의 변화는 AC-010 갭 0 → 1(D21의 갭 줄, 선행 편집이 머리에 이미 반영) 하나다 — 위 0.1.3 표는 그때의 기록이라 고치지 않았다.

**이 판에서 돌린 명령(요약)**: `moai spec lint --strict .moai/specs/SPEC-UIKIT-009/spec.md` → `✓ No findings — all SPEC documents are valid` · `grep -c '^- \*\*REQ-' spec.md` → `23` · `grep -c '^## AC-' acceptance.md` → `24` · `grep -c '^### Out of Scope' spec.md` → `7` · 확인 필요 표식 `grep -rc` → 일곱 파일 모두 `0` · `ID="SPEC-UIKIT-009"; [[ … ]]` → `PASS` · 형제 문장 훑기(아래 갭의 범위 안).

**0.1.4의 갭(관측하지 않은 것)**
- 드라이버·빌드·시뮬레이터를 돌리지 않았다. D23의 "새 규칙이 계산된 구간에서 같은 날을 낸다"와 D21의 "오프라인 실행에서 (라)가 부수적으로 생길 수 있다"는 코드 읽기다.
- AC-022의 새 경로 규칙은 이 SPEC의 카드 커밋이 아직 없어 이 SPEC 위에서는 돌려 보지 못했다 — 양성 대조는 이미 병합된 t16 범위에서 SPEC 이름만 바꿔 돌린 것이다.
- `research.md`는 고치지 않았다 — `e.arrivalDate > dep`·"새로 만든 구간"이 나오는 자리(§3 표 45·46, §4 16, §6의 0.1.1 줄)는 0.1.1·0.1.2 때의 측정·발견 기록이고 지금도 참이다.
- 선행 편집의 작성자와 D26 문구의 원래 판은 확인하지 못했다.
- optional D25(주석 줄 거짓 FAIL)·D27(시뮬레이터 비행기 모드)·D28·D29·D11은 열어 둔 채다.

### 관측된 증거 — 오케스트레이터 로그(이 레인은 읽기만 했다)

로그 위치 `.moai/state/verify/t17-plan/`(gitignored — 워크트리 안에만 있다). 오케스트레이터가 `b2c3987`에서 돌린 것이다. review-1도 같은 로그를 다시 세어 같은 값을 얻었다(review-1 § 재측정 표본).

| 명령 | 관측된 출력 | 쓰인 곳 |
|---|---|---|
| `grep -c '^  ✓ ' driver-run.log` · `grep -c '^  ✗ ' driver-run.log` · `tail -3 driver-run.log` | `357` · `0` · `357/357 통과` / `[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다` / `run_exit=0` | 드라이버 기준선(T = 357 − 뺀 수 + 더한 수) |
| `grep -c '^SwiftCompile' ios-build.log` | `42` | 빌드 기준선(iOS) |
| `grep -n "BUILD SUCCEEDED" ios-build.log` | `:944` | 빌드 기준선(iOS) |
| `grep 'warning:' ios-build.log \| grep -v 'Metadata extraction skipped' \| wc -l` · `grep -c 'warning:' ios-build.log` | `0` · `2`(툴체인 안내뿐) | 무경고 기준선(iOS) |
| `grep -c 'warning:' driver-compile.log` | `24` | 드라이버 컴파일 경고 집합(진단 12 + 캐럿 문맥 12로 보이나 이 레인은 건수만 확인) |

0.1.3에서 이 레인이 위 네 줄과 드라이버 줄을 같은 로그에서 다시 셌고 값이 같았다(`42` · `:944` · `0` · `2` · `24` · `357` · `0` · `run_exit=0`). **역사 관측 — 기준이 아니다**: 같은 로그 묶음의 맥 빌드 로그도 방침 전(2026-09-30)에 `** BUILD SUCCEEDED **`였다(`grep -n "BUILD SUCCEEDED"` → `:587`). 방침 P-1로 0.1.3부터 맥 빌드는 어느 게이트에도 없고, 이 값은 비교 대상도 기준선도 아니다.

### 관측된 증거 — 이 레인이 직접 돌린 명령

전체 표(52행 — 0.1.3에서 50~52를 더했다)는 `research.md` §3에 있다. 핵심만 적는다. 0.1.0 작성 때의 행과 0.1.1·0.1.2·0.1.3 수정 때의 행을 가른다.

| 명령 | 관측된 출력 | 쓰인 곳 |
|---|---|---|
| `git rev-parse --short HEAD` · `git branch --show-current` · `git status --short` | `b2c3987` · `WT-edit-card-unify` · `?? .moai/reports/t17/`(0.1.0 시점) | 기준 트리 |
| `ID="SPEC-UIKIT-009"; [[ "$ID" =~ ^SPEC(-[A-Z][A-Z0-9]*)+-[0-9]{3}$ ]] && echo PASS \|\| echo FAIL` · `ls .moai/specs \| grep -c SPEC-UIKIT-009` | `PASS` · `0` | frontmatter `id` (작성 전 실행) |
| `grep -rn linkedActivityId Shared ShareExtension Tools proxy \| wc -l` | `18` | spec §0 |
| `grep -c "activities\|ActivityBlock\|activityId\|linkedActivityId" Shared/AddEventView.swift Shared/EventDetailView.swift` | `0` · `0` | REQ-001 |
| `grep -rn "EditCardView(" Shared` | 4줄 | 렌즈 정정 확인 |
| `grep -n "isSamePlace(" Shared/AIAssistant.swift` | 6줄(정의 `:2917` + 사용 5) | 렌즈와 어긋남(`research.md` §4 1) |
| `awk 'NR>=1065 && NR<=1171' Shared/Store.swift \| grep -c "enqueueCalendarUpload\|removeFromCalendar"` | `0` | D-10 |
| `grep -cF 'store.events.filter { $0.title == event.title }' Shared/EventDetailView.swift` | `1` | AC-013 기준값 |
| `grep -c 'private func legToggleRow\|…' Shared/AddActivityView.swift` | `5` | AC-006 기준값 |
| `grep -c 'linkedActivityId == nil' Shared/ContentView.swift` | `1`(`:651`) | AC-005 기준값 |
| (0.1.1) `grep -n departureDate Shared/*.swift` · `grep -n travelSeconds Shared/*.swift` · `sed -n 994,1036p Shared/Store.swift` · `sed -n 505,583p Shared/ContentView.swift` | 출발 기준 실패는 `:1025` 대입 → guard `:1031`로 `departureDate`가 남는다 · 블록 선택 `ContentView.swift:511` · 실패 분기 `:558` · 출발 고정 최소 높이 `:580` | REQ-010 근거 · REQ-023 (review-1 D3 확인) |
| (0.1.1) `sed -n 1118,1131p Shared/Store.swift` · `grep -n linkedLegs Shared/*.swift Tools/GuardDriver.swift` | 추정 `:1126-1130` · 호출 `:1075` 하나 | D-8 (b) |
| (0.1.1) `grep -n linkedActivityId Shared/Store.swift \| awk -F: '$1>=628 && $1<=695' \| wc -l` | `0` | REQ-011 · 표 17 (review-1 D13) |
| (0.1.1) `sed -n 189,230p Shared/Store.swift \| grep -c travelSecondsHint` | `0` | AC-018 Given (review-1 D5) |
| (0.1.1) `grep -c 'e.departureDate != nil' Shared/ContentView.swift` · `grep -c 'columnEnds' Shared/ContentView.swift Shared/Models.swift` · `grep -c '반복 일정의 한 회차입니다' Shared/ActivityDetailView.swift` · `awk '/^enum ScheduleAnchor/,/^}/' Shared/Models.swift \| grep -c 'case '` | `1` · `8` / `0` · `1` · `1` | 새 대리 지표의 기준값(AC-010 (9) · AC-016 (2) · AC-011 (4) · AC-019 (4)) |
| (0.1.1) `git log --oneline -S 'var travelSeconds: TimeInterval?' -- Shared/Models.swift` | `d3c9327 최초 커밋 …` 한 줄 | `plan.md` §3 |
| (0.1.1 작성 뒤) `grep -c '^- \*\*REQ-' .moai/specs/SPEC-UIKIT-009/spec.md` · `grep -c '^## AC-' .moai/specs/SPEC-UIKIT-009/acceptance.md` | `23` · `24` | 예산 |
| (0.1.1 작성 뒤) `moai spec lint --strict .moai/specs/SPEC-UIKIT-009/spec.md` | `✓ No findings — all SPEC documents are valid` | frontmatter·Out of Scope |
| (0.1.1 작성 뒤) `grep -c '^### Out of Scope' .moai/specs/SPEC-UIKIT-009/spec.md` | `6` | Exclusions |
| (0.1.1 작성 뒤) `grep -rc` 로 확인 필요 표식 문자열을 SPEC 디렉터리 전체에서 셈 | 일곱 파일 모두 `0` | 결정 게이트 해소(MP-7) |
| (0.1.2) `git rev-parse --short HEAD` · `git branch --show-current` | `b2c3987` · `WT-edit-card-unify` | 기준 트리 그대로 |
| (0.1.2) `awk 'NR>=80&&NR<=100'`·`'NR>=500&&NR<=660'`·`'NR>=699&&NR<=775' Shared/ContentView.swift` | 나열 `:87-95`(guard `:89`) · 블록 선택 `:511` · 실패 분기 `:558-561` · `failedEstimateBlockView` `:627-642` · 배치 `:699-742` | REQ-023 · E9 옛 결과 손 추적 |
| (0.1.2) `awk 'NR>=990&&NR<=1040'`·`'NR>=1240&&NR<=1282'`·`'NR>=640&&NR<=690'`·`'NR>=740&&NR<=772'`·`'NR>=120&&NR<=175' Shared/Store.swift` · `grep -n 'applyEstimate(\|applyDepartureAnchoredEstimate(\|applyCached' Shared/Store.swift` | 모양 넷의 생산자(`research.md` §3 표 43·44) · 달력 점의 사본 `:136` | REQ-023 (가)~(라) · 점 절 |
| (0.1.2) `grep -c 'e.arrivalDate > dep' Shared/ContentView.swift Shared/Store.swift` · `grep -c 'failedBlockAnchor\|isListed(on:' Shared/*.swift` | `1` / `1` · 전 파일 `0` | AC-010 (9) 기준값 |
| (0.1.2) `grep -n '전제' Tools/GuardDriver.swift` · `grep -n '전제' .moai/state/verify/t17-plan/driver-run.log` | `:667`·`:981`·`:991`·`:1356`·`:1369` / 로그 `:95`·`:150`·`:211` | REQ-020 · 결정성 문단(D15) |
| (0.1.2) 고친 문장의 좌표 재측정 — `awk`로 줄을 찍어 대조(Store 41줄 · ContentView 22줄 · App·Models·AIAssistant·Google·GuardDriver·로그) | 어긋남 0 | 이 판의 모든 새 좌표 |
| (0.1.2) `python3 <스크래치>/trace.py .moai/specs/SPEC-UIKIT-009` (매트릭스 → REQ→AC 역방향 · `plan.md` §0 대조 · 모든 "AC-XXX (n)" 포인터 · `plan.md` §1·`spec-compact.md` 카드 열 · 여러 카드 AC의 항목 집합) | `REQ→AC plan §0 vs matrix-derived: identical` · `uncovered REQs: none` · `pointer problems: 0`(처음 실행에서 1건 — `plan.md` D-4의 채택하지 않은 선택지가 AC-009의 없는 여섯째 항목을 번호로 가리켜 "여섯째 항목 신설"이라는 말로 고쳤다) | D17 · D19 · 추적성 |
| (0.1.2) REQ 문장 대조(`spec.md` ↔ `spec-compact.md`, 23건) · 통과 수 합산 | `mismatch []` · `AF 66 AG 9 AH 28 sum 103 floors 423 432 460` | 요약본 동기 · 통과 수 |
| (0.1.2 작성 뒤) `grep -c '^- \*\*REQ-' spec.md` · `grep -c '^## AC-' acceptance.md` · `grep -c '^### Out of Scope' spec.md` · `moai spec lint --strict .moai/specs/SPEC-UIKIT-009/spec.md` · `grep -rc` 확인 필요 표식 | `23` · `24` · `6` · `✓ No findings — all SPEC documents are valid` · 일곱 파일 모두 `0` | 예산 · frontmatter · MP-7 |

### 렌즈·기록과 어긋난 자리 (요약 — 전문은 `research.md` §4)

1. `isSamePlace` 사용처 렌즈 4곳 → 측정 5곳(`:1085` 추가).
2. `NotificationManager.swift:21`은 `bootstrap()` 안이다 — 알림 생략은 `:34`, 그리고 드라이버는 비번들이라 알림이 늘 nil이다(AC-007 (8) 한계).
3. `addActivityWithTravel`의 범위 렌즈 둘이 다르다 — 측정 `:189-230`.
4. 묶음 안 겹침의 원천 셋 중 하나(계산 실패 블록이 도착 시각 아래로 자람, `ContentView.swift:557-563`)는 렌즈에 없다.
5. D-9는 권장이 (b)다(호출자 없는 입력은 죽은 API). D-13을 새로 세웠다.
6. (0.1.1) 0.1.0 자신의 REQ-010 근거가 틀렸다 — "계산 실패는 `departureDate`를 nil로 남긴다"는 가는 편에만 맞고 오는 편은 `departureDate`가 남는다(review-1 D3). REQ-023으로 이어졌다.
7. (0.1.2) 0.1.1 자신의 REQ-023이 실패 모양을 하나로 봤다 — 재추정 실패는 옛 도착을 남기고 반복 뒤 회차는 출발 기준인데 `departureDate`가 nil이다(review-2 D14). 소비자만 훑고 생산자를 훑지 않은 탓이다(`research.md` §4 15).
8. (0.1.2) review-2 D15의 "다섯째 재현은 오프라인에서만 닿는다"는 새로 만든 구간에만 맞다 — 재추정 실패 모양은 출발지 nil 레코드로 결정적으로 닿는다(`research.md` §4 16, 코드 읽기).

### Gaps — plan이 돌리지 않은 것 (증거 없음 ≠ 통과)

- **드라이버·빌드를 이 레인은 실행하지 않았다.** 수치는 오케스트레이터 로그를 읽은 것이다. 드라이버 컴파일 경고 집합의 동일성은 건수(24)만 확인했다.
- **프록시 `npm test` — 미실행.** 이 SPEC은 프록시를 바꾸지 않는다. 기준선 자체가 관측되지 않았다.
- **결함 가설 전부 — 재현되지 않았다.** 장소를 못 지움 · 끝 ≤ 시작 재정렬 · 일괄 삭제 무연쇄 · 매달린 링크 · 오는 편 실패가 일반 블록으로 그려짐은 코드 읽기다(REQ-020이 재현을 수리보다 먼저 둔다). `addEvent`로 새로 만든 구간의 실패 모양((가)·(나))은 추정이 실패하는 실행에서만 닿고(AC-010 (4) — 도달 기록), 반복 뒤 회차 (라)는 결정적 경로도 그것을 보는 단언도 없어 메모리 구성으로만 보이며(0.1.4 — AC-010 갭 줄), 재추정 실패 모양은 출발지 nil 레코드로 결정적으로 닿는다고 읽었다(AC-010 (10) — 실행 전).
- **§6 실례의 기대값 — 손으로 계산했다.** 드라이버가 확정하기 전까지 가설이다(옛 알고리즘 값은 C1이 실제 출력으로 기록한다). review-1도 손 추적으로 같은 값을 얻었다 — 손 추적은 실행이 아니다.
- **(0.1.1) 배치 묶음 조회·미계산 판정 — 코드가 없다.** 이름·시그니처는 제안이고, 추정이 `linkedLegs`와 한 벌인지는 AC-015 (12)가 run에서 처음 잰다.
- **(0.1.1) 미계산 판정이 옛 경고를 모두 포함한다는 것 — 코드 읽기다**(`plan.md` §3). AC-010 (8)이 run에서 잰다. 이 저장소 이전(`d3c9327` 전) 데이터의 모양은 확인할 수 없다.
- **(0.1.2) 실패 모양 넷과 앵커 규칙 — 코드 읽기다.** 생산자 전수(표 43·44)는 `grep`·`awk`로 훑었지만 어떤 모양도 실행으로 만들어 보지 않았다. `design.md` §4·§6.3 E9의 값은 손 계산이다.
- **(0.1.2) 출발지 nil 레코드의 재추정이 추정 실패와 같은 상태를 남긴다는 것 — 코드 읽기다**(두 guard 사이에 레코드를 바꾸는 줄이 없음, `sed -n 1020,1036p`로 읽음). AC-010 (10)이 run에서 처음 잰다.
- **(0.1.2) 오프라인 드라이버 실행 — 돌리지 않았다.** 기대 ✗ 집합은 전제 두 줄만 적었고 그 밖은 미측정이다. 판정 레인이 네트워크를 끌 수 있는지도 모른다.
- **(0.1.2) 기존 드라이버 절이 이동시간 미계산 레코드의 나열·점을 단언하는지 — 훑지 않았다.** MC의 "뺀 수 0"이 잡는다.
- **(0.1.2) 앵커·나열 규칙에 대한 운영자 확인 — 없다.** D-14 (b)의 적용 범위를 넓힌 설계 규칙이라 새로 묻지 않았다. 리드가 확인할 몫이다.
- **(0.1.1) 배치 묶음 조회의 렌더 비용 — 측정하지 않았다(가설: 무시할 만함).**
- **(0.1.1) 운영자의 답 — 이 세션은 직접 보지 않았다.** 칸반 리드가 전한 내용(D-1~D-7·D-9~D-13 권장 채택, D-8 (b), review-1 D3 (b), D10·D12·D13 채택, D11 불채택)을 그대로 적었다. 전달 내용과 운영자의 실제 답이 다르면 `plan.md` §2만 고친다.
- **활동 카드가 `origin_query`·`return_query` 줄을 처리할 때 복사된 장소 검색 도우미가 줄 키에 무관하게 동작하는지** — 완전히 읽지 않았다(MB B3가 처음 확인).
- **시뮬레이터·실기기 동작 전부 — 미관측.** 스크립트 1~22(13a·20a·20b 포함 — 25단계)가 그 자리다. 이동시간의 실제 분·문구의 실제 모양은 미관측이다. 반복 회차의 묶음 배치 화면은 스크립트에 없다(AC-024 갭).
- **알림 생략·알림 취소·캘린더 호출은 드라이버로 관측할 수 없다** — `NotificationManager`의 `center`가 비번들에서 늘 nil이다(`:10-14`), 캘린더 푸시는 꺼진다(AC-008·AC-012 갭 줄).
- **"크게 고침"의 조작적 정의(`numstat` 100줄)와 카드별 예측 파일 수 — 예측이다.** run이 그 카드의 기준 커밋과 실측해 기록한다.
- **`updateActivity`의 삭제 영향 — 확인하지 않았다**(호출자 수만 셌다).
- **MCP `spec_audit`는 이 SPEC을 보지 못했다.** `mcp__moai__spec_audit(filter_spec: "SPEC-UIKIT-009")` → `total_specs: 0`(2026-09-30 0.1.0 작성 때 호출). SPEC-UIKIT-008 기록과 같은 모양이라 MCP 서버가 주 체크아웃을 읽는 것으로 보인다(추정). 0.1.1에서는 다시 부르지 않았다. 린트는 워크트리 CLI로 대신 확인했다(위 표).
- **맨몸 `:N` 인용 수 — 미측정.** 파일명 붙은 토큰만 셌다(하한). sync가 행의 기본 파일로 풀어 센다.
- **(0.1.3) 맥 타깃 — 이 SPEC의 어느 단계도 빌드·검증하지 않는다(방침 P-1, 받아들인 갭).** `Shared/` 변경이 맥 타깃을 깨는지는 아무도 보지 않는다(`spec.md` §3 "맥 앱의 빌드와 검증" 절). AC-019 (6)은 플랫폼 지시문 줄이 사라지지 않았다는 대리 지표일 뿐이다.
- **(0.1.3) 방침 원문 — 운영자의 말 자체는 보지 않았다.** 칸반 리드가 전한 내용과 `master`의 `CLAUDE.md:10-12`(커밋 `00cd149`)를 읽었다. 방침과 전달 내용이 다르면 `plan.md` §2 P-1과 REQ-019 플랫폼 절만 고친다.

### 잔여 위험

- 드라이버 초록이 사람 증거를 대신하지 못한다 — `357/357` 트리에 코드 읽기 결함이 있고 배치·블록 선택은 옮기기 전에는 기계로 못 잰다.
- AI 경로가 구간의 시간을 직접 고치면 결합이 여전히 끊길 수 있다(범위 밖 — 운영자 증상은 UI 경로에서만 닫힌다). AI 목록의 실패 표지도 실패한 오는 편을 놓친다.
- 안 A(묶음 한 칸)는 틈 있는 묶음과 안쪽 겹침이 있는 묶음에서 폭을 더 쓴다(E3b·E4) — 운영자가 "왜 좁아졌지"로 볼 수 있다.
- 추정 묶음은 도착이 다음 날인 오는 편을 놓치고 이름이 같은 장소를 섞을 수 있다 — 폭만 틀린다(데이터는 그대로).
- `Store.swift` 중간 삽입이 CHECKLIST 인용 39건(하한)을 민다. 원장이 지문 기반이어야 한다.
- 활동 카드 저장이 비동기가 되어 저장 도중 닫기·두 레코드 저장 순서 위험이 새로 생긴다(잠금·직렬로 완화).
- `GuardDriver.swift`가 세 카드의 공통 파일이라 병합 충돌이 난다(직렬이 기본).
- t30과 `EditCard.swift`에서 접촉할 수 있다.
- (0.1.3) 맥 타깃도 `Shared/`를 컴파일하는데 맥 빌드가 없다 — 세 카드의 `Shared/` 변경이 맥 타깃을 깨도 맥 앱을 만들 때까지 드러나지 않는다. 운영자가 받아들인 갭이다(방침 P-1).

## §E.2 Run-phase Evidence

_<pending run-phase>_

카드별 기준 커밋 칸 — plan이 만든 빈 칸이다. 값은 각 카드의 run 레인이 카드를 시작할 때 `git rev-parse --short HEAD`로 재어 적는다(AC-022 · `plan.md` §5). 비어 있으면 AC-022는 판정할 수 없다.

| 카드 | card_base_sha | 무엇의 커밋인가 |
|---|---|---|
| MA (t17-a) | _<pending run-phase>_ | _<pending run-phase>_ |
| MB (t17-b) | _<pending run-phase>_ | _<pending run-phase>_ |
| MC (t17-c) | _<pending run-phase>_ | _<pending run-phase>_ |

## §E.3 Run-phase Audit-Ready Signal

_<pending run-phase>_

## §E.4 Sync-phase Audit-Ready Signal

_<pending sync-phase>_
