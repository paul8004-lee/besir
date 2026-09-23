# SPEC-TEST-001 — progress.md

칸반 카드 t8 · 가드 드라이버 구조적 경화. 2026-09-24 리드 디스패치를 받아 plan 레인이 시작했다.
워크트리는 `.claude/worktrees/t8`(branch `WT-driver-hardening`, base `2a37673` = `origin/master`)다.

## §E.1 Plan-phase Audit-Ready Signal

- kickoff_gate: **pending** — 결정 넷(D-1~D-4)과 Tier 확인이 남아 있다(`spec.md` §4, `plan.md` §2). 이 신호가 여는 다음 단계는
  run 착수가 아니라 착수 승인 게이트다.
- 산출물: `spec.md` · `plan.md` · `progress.md`(이 파일). Tier S라 `acceptance.md`를 두지 않고 AC는 `spec.md` §3.1에 인라인했다.
- 작성 주체: 세 파일 모두 plan 레인 오케스트레이터가 직접 썼다(서브에이전트 위임 없음). 이유: 이 카드의 출발점이 "위임받은 서브에이전트가
  드라이버를 돌려 실제 데이터를 덮어썼다"(2026-09-23 14:17)이고, 실측 수치 수십 개를 그대로 옮겨야 했다.
- **가드 드라이버는 돌리지 않았다**(디스패치 금지). **`Shared/`·`Tools/` 아래 변경은 0건이다**(`git status --short`로 커밋 전 확인 — §F.1 뒤 신호 앞에 기록).
- 신호 줄(`plan_complete_at`·`plan_status`)은 파일 끝, §F.1 감사 자리 뒤에 둔다.

### 관측된 증거 — 이 레인이 `2a37673`에서 직접 돌린 명령

| 명령 | 관측된 출력 | 쓰인 곳 |
|---|---|---|
| `git rev-parse --short HEAD` · `git branch --show-current` | `2a37673` · `WT-driver-hardening` | 기준 트리 |
| `git diff --quiet b8bbe1c 2a37673 -- <CLAUDE.md:59-63의 12파일>` · `git log --oneline -1 -- Tools/GuardDriver.swift` | exit 0 · `f9cd9bb` | spec §0 기준선 귀속 |
| `grep -n 'appendingPathComponent("' Shared/Store.swift Shared/AIAssistant.swift Shared/Config.swift` | 데이터 파일 7개 + 디렉터리 `:67` | spec §1.2 |
| `awk` 머리말 `:168-188` · `awk 'NR>=274 && NR<=301'` · `sed -n '8,30p' Shared/Store.swift` · 첫 `drvCreate` `:428` · 절 머리 `grep -c` = 29 · 백업 `grep -n` = 10줄 | G `:278`은 없는 번호라 쓰기 전 반환(`:281` 단언) → 첫 쓰기는 H `:293`(`save()` `Store.swift:759`), 배열 `didSet`은 저장 안 함(`:10`·`:14`), 백업 7곳(`drvPersistedPayload`는 Q절 `:651`에서 불림) | spec §1.2 (감사 1회차 D1로 정정) |
| `grep -o '"title":"[^"]*"' /tmp/besir-incident-20260923/*.fixture` · `grep -n 'V-출발\|W-하룻밤' Tools/GuardDriver.swift` | `V-출발`·`W-하룻밤` · V절 `:972`·W절 `:1038` | spec §1.1 (J `:1127`보다 앞) |
| `grep -n 'Keychain\|isConnected\|…' Shared/GoogleCalendarService.swift` · `grep -n 'googleConnected\|hasGoogleCalendar\|removeFromCalendar(' Shared/Store.swift` · 함수 시작 줄 목록 | 게이트 갈래 7자리 · 게이트 밖 갈래 둘(`removeFromCalendar` 호출부 5, `updateActivity` `:273`) | spec §1.3 |
| `grep -n 'store\.delete\|store\.updateActivity\|delete_schedule\|delete_recurring' Tools/GuardDriver.swift` · `grep -o 'drvExecuteTool("[a-z_]*"' … \| sort \| uniq -c` · `grep -o 'drvAsk("[a-z_]*"' …` · `grep -n 'updateActivity(\|modifyActivity' Shared/Store.swift Shared/AIAssistant.swift` · `grep -n 'reconcileActivities(' Shared/*.swift` | 0줄 · `create_activity` 4 · `create_schedule` 3 · `drvAsk`는 생성 계열뿐 · `modifyActivity` `:288` → `:310` ← `AIAssistant.swift:2220` · `:1378` 한 곳 | spec §1.3 (드라이버는 게이트 밖 갈래를 부르지 않음, `:1425`는 게이트 안) |
| `grep -n 'removeFromCalendar(' Shared/Store.swift` | 정의 `:97` + 호출 9곳, 게이트 밖 6(`:272`·`:370`·`:706`·`:1258`·`:1276`·`:1289`) | spec §1.3 (감사 1회차 D2로 정정 — 처음엔 다섯) |
| `grep -n 'app-sandbox' project.yml` | `:107` `com.apple.security.app-sandbox: false` | AC-002 전제 (감사 1회차 D8) |
| `awk 'NR>=76 && NR<=89' Shared/Config.swift` | `bundledDefaults`의 `googleClientID` 비어 있지 않음 `:80`, 프록시 `:78`, 파일 없으면 기본값 `:86` | spec §1.3·O-1 |
| 탐침 `probe_home` (none · setenv-cffixed · setenv-home) | 기준 경로 · `/tmp/besir-probe-cf/Library/Application Support` · 기준 경로 | spec §1.4 |
| 탐침 `probe_pin` (home-first · fm-first · tmp) · `test -e /tmp/besir-probe-pin` | 먼저 읽어도 고정 안 됨 ×2 · `NSTemporaryDirectory` 불변 · 디렉터리 없음 | spec §1.4 |
| `HOME=/tmp/… <탐침>` | 워크트리 가드가 거부("sets HOME, injecting git configuration…") | spec §1.4 |
| `which timeout gtimeout` · `sw_vers -productVersion` | 둘 다 not found · `26.6.2` | spec §1.4·§1.5 |
| `awk 'NR>=210 && NR<=250' <주 체크아웃 hazards SKILL.md>` · `wc -l` · `awk 'NR>=405 && NR<=415' Shared/Store.swift` | 후보 목록 `:229-234`, `updateMeal` `:233`, 유지 문단 선례 `:244-246`, 249줄 · 이유 주석 `:408` | spec §1.6 |
| `git ls-files .claude \| wc -l` | 0 | spec §1.6, REQ-007 |
| `git grep -n '/tmp/gd' -- ':!.moai/specs'` | `CLAUDE.md:59`·`:60`·`:64` · `GuardDriver.swift:4`·`:5`·`:9` | REQ-006 (레시피 사본 둘) |
| `grep -rln 'GuardDriver\|/tmp/gd'` 주 체크아웃 `.claude/`(워크트리 제외) | 0건 — 하네스 스킬·에이전트에 레시피 사본 없음 | REQ-006 범위 |
| `awk 'NR>=576 && NR<=600'`·`'NR>=972 && NR<=984' Shared/Store.swift` · `grep -n 'hasProxy' Shared/DirectionsService.swift` | `addEvent` → `applyEstimate` → `directions.estimate` → 프록시 | O-1 (가설) |

탐침 소스와 바이너리는 `.moai/state/verify/t8/`에 있다(git 무시, `.gitignore:28`). 탐침은 경로 문자열만 찍고 파일·디렉터리를 만들지 않는다.

### 카드 원문 (`moai todo`, 2026-09-24 이 레인이 읽음)

> t8	picked	드라이버 구조적 경화 — 2026-09-23 사고(2차 발생): GuardDriver 앞쪽 절들이 백업 없이 Store.save()를 불러 실제 앱 데이터(~/Library/Application Support/besir/events.json·activities.json)를 픽스처로 덮어씀. 첫 백업이 J절(:1127)에만 존재. 1차(9a5b3d6)는 구글 캘린더 직접 접근을 막았지만 저장 경로는 안 막았음. 할 일: (1) 드라이버 시작·종료에 백업·복원·cmp 대조 강제 — SPEC-UIKIT-006 REQ-030 절차의 코드화 (2) 키체인 접근 격리 — 새로 컴파일한 드라이버가 SecItemCopyMatching에서 멈출 수 있음(plan 보고) (3) R4(sync 인계) — 종료 시각 모호성의 진짜 수리: sleep 감시자는 wait 뒤 회수(900초 연장이 아님 — run §E.2의 '600초 동시 종료'는 감시자가 호출을 붙잡은 착시, 로그 마지막 쓰기 16:40:19) (4) R5 — 하네스 스킬 hns-besir-app-hazards의 updateMeal 데드코드 후보 항목 정리(D-2 유지 확정으로 낡음). t7 완료 후·Day 닫기 전 실행. 운영자 승인 2026-09-23.

디스패치(리드, 2026-09-24): 범위 4항목은 카드 본문 그대로, 공용 메모리 `feedback_besir_driver_touches_real_data`를 반드시 읽고 반영, 드라이버 실행이 필요한 실측은 plan 단계에서 금지.

### 카드 본문과 실측이 어긋난 자리

- **"첫 백업이 J절(:1127)에만 존재"** — `events.json` 기준으로는 맞다. 파일 전체로는 Q절 `:633`(`ai_history.json`)과 그 도우미 `:152`가 먼저다.
  요지 — 앞쪽 절(첫 쓰기 H `:293`부터 V·W까지)의 쓰기에는 백업이 없다 — 는 그대로다.
- **카드 (1)의 방식** — 카드는 "시작·종료 백업·복원·cmp 코드화"를 적었다. 이 레인은 실제 디렉터리를 아예 쓰지 않는 격리가 오늘 실측으로 가능함을 보였고,
  그것을 권고안(D-1 (a))으로 올렸다. 카드 문구 그대로의 안은 D-1 (b)로 남겼다. 결정은 게이트 몫이다.
- **카드 (3)의 방식** — "sleep 감시자는 wait 뒤 회수"를 적었다. 권고안(D-2 (a))은 감시자를 없애 회수할 것 자체를 없앤다. 카드 문구 그대로는 D-2 (b).

### Gaps — plan이 돌리지 않은 것 (증거 없음 ≠ 통과)

- 가드 드라이버(금지). 따라서 이 트리의 205/205, 샌드박스에서의 통과 수, 실행 시간은 전부 미관측이다.
- `CFFIXED_USER_HOME`이 드라이버 컴파일 집합 전체(`Store`·`AIAssistant`·`LocationManager`·MapKit 캐시 등)에 같은 효과를 내는지 — 탐침은
  `FileManager`·`NSHomeDirectory`·`NSTemporaryDirectory`만 쟀다.
- `CFFIXED_USER_HOME`과 키체인의 관계(O-3) — 재지 않았다.
- 타이머 스레드에서 `exit`할 때 주 스레드가 `SecItemCopyMatching`에 묶여 있으면 어떻게 되는지.
- 실제 지원 디렉터리의 현재 목록·해시 — 운영자 데이터 파일을 열지 않았다(M1에서 run이 잰다).
- 운영자 `config.json`과 `bundledDefaults`의 값 비교 — 하지 않았다.
- 드라이버가 실제로 네트워크를 부르는지(O-1) — 코드 읽기뿐이다.
- `xcodebuild`·`npm test` — `Shared/`·`proxy/`를 바꾸지 않는 카드라 plan에서 돌리지 않았다.

### 카드 밖 발견 — 리드가 카드로 올릴지 정할 것

- **O-1 드라이버의 네트워크 호출**(코드 읽기 가설, 미관측) — `spec.md` §3 Out of Scope. 사실이면 `CLAUDE.md:58`의 "(API 할당량 안 씀)"이 틀리다.
- **O-2 절마다의 파일 백업 7곳** — D-1 (a) 뒤 샌드박스 안에서만 돈다. Day 닫기 간결성 검사의 입력.
- **O-4 공용 메모리 갱신** — `feedback_besir_driver_touches_real_data`의 "t8 전까지" 절차.

### 잔여 위험

- `CFFIXED_USER_HOME`은 문서화가 얕은 동작이다. REQ-001의 경로 확인이 무시되는 날을 잡지만, 그날 드라이버는 돌지 않는다(exit 2) — 게이트가 멈춘다.
- REQ-004는 게이트 밖 키체인 갈래의 **전제**를 잴 뿐 호출 자체를 재지 않는다. 두 측정 자리 사이에서 깼다가 되세우는 절은 통과한다.
- 샌드박스 시작 상태가 실제 설정과 달라 기준선 205가 흔들릴 수 있다(AC-008 (4)).

## §E.2 Run-phase Evidence

(run 단계가 채운다 — `plan.md` §1의 M1~M5, 드라이버 실행마다 명령 원문·종료 코드·출력 꼬리·바깥 대조·운영자 키체인 답)

## §E.3 Run-phase Audit-Ready Signal

(run 단계가 채운다)

## §F Phase 4 Mode Selection

- 선택: **serial**(서브에이전트 없이 오케스트레이터 직접 작성 + 독립 감사 한 채널). 근거: Tier S, 문서 셋, 수치 대조가 작성과 한 손에 있어야 한다.

## §F.1 Phase 11 — 독립 감사

### 1회차 — PASS 0.76 (Tier S 통과선 0.75), 2026-09-24

- 보고서: `.moai/reports/plan-audit/SPEC-TEST-001-review-1.md`. 감사자: `plan-auditor` 서브에이전트(맥락 격리), 교차 모델 `audit_multi`는
  claude 필수 · codex 끔 · glm 참고 — GLM이 `inconclusive`(fail-open)라 판정은 claude 단독이다. **독립 채널은 하나다.**
- 감사자에게 드라이버·탐침 바이너리 실행, 실제 지원 디렉터리·키체인 접근, SPEC 수정을 금지했고, 감사자는 지켰다고 보고했다
  (쓴 파일은 보고서 하나 — `git status --short`로 이 레인도 확인).
- 점수: 명확성 0.75 · 완결성 0.90 · 시험 가능성 0.65 · 추적성 0.80(조화평균). must-pass MP-1~MP-7 전부 통과(MP-4 해당 없음).
  D-1~D-4·Tier는 의도된 게이트 표식으로 결함에서 뺐다.
- **blocking should-fix 9건(D1~D9) — 커밋 전 전부 반영.** 인용 오류는 D1(첫 쓰기 G→H)·D2(게이트 밖 호출부 5→6) 둘뿐이었고, 이 레인이
  같은 명령으로 다시 확인했다(D2는 감사 결과가 오기 전에 이 레인도 따로 찾았다). 나머지 일곱은 요구사항·AC의 구멍이다 — REQ-008의 git 밖
  범위(D3), REQ-001 "every exit path"의 과장(D4), 종료 루틴 이원화와 코드 2의 자리(D5), AC-004가 메인 액터 밖 성질을 못 가림(D6),
  AC-003의 세는 명령(D7), 맥 앱 비샌드박스 전제(D8), 삭제 대상 확인의 AC(D9). 반영 내용은 `spec.md` HISTORY 0.1.0 행.
- optional D10~D19 10건 중 9건 반영 — 잔여 위험의 범위(씨앗 전체), plan §0 매핑(002→008), §1.3의 `update_schedule` → `modifyActivity` 경로(툴 이름 전수를
  명령째 넣음), AC-002 (3)의 grep(쓰기·삭제·디렉터리 생성 호출 전수로 바꿈), AC-005 (1)의 절 범위, AC-006 (2)의 `:408`, `plan.md` §2의
  `[NEEDS CLARIFICATION]` 표식, 종료 코드 1의 중의성, 카드 원문 인용(이 파일 §E.1). 보류 1건: REQ 문장 안의 줄번호(프로젝트 관례).
- **재감사 없음.** 2회차는 착수 게이트 결정(D-1~D-4·Tier)을 반영한 뒤 그 델타와 이 반영분을 함께 본다. 3회가 상한이므로 게이트 뒤 2회, 여유 1회가 남는다.

- plan_complete_at: 2026-09-24
- plan_status: audit-ready
