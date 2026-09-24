# SPEC-TEST-001 — progress.md

칸반 카드 t8 · 가드 드라이버 구조적 경화. 2026-09-24 리드 디스패치를 받아 plan 레인이 시작했다.
워크트리는 `.claude/worktrees/t8`(branch `WT-driver-hardening`, base `2a37673` = `origin/master`)다.

## §E.1 Plan-phase Audit-Ready Signal

- kickoff_gate: **resolved 2026-09-24** — 운영자가 결정했고 리드가 전했다(기록은 `plan.md` §2): D-1 (a) 격리 + 대조 · D-2 (a) 내부 시간 제한 ·
  D-3 (a) 머리말 불변식 · D-4 `CLAUDE.md` 편집 승인 · Tier S. (b) 없음 → REQ·AC 재작성 없음. 이 plan 세션은 운영자의 답을 직접 보지 않았다.
  결정을 반영한 판은 `spec.md` 0.1.1이다.
- (게이트 전 기록) kickoff_gate: pending — 결정 넷(D-1~D-4)과 Tier 확인이 남아 있었고, 이 신호가 여는 다음 단계는 run 착수가 아니라
  착수 승인 게이트였다(커밋 `08c1a1b`).
- 산출물: `spec.md` · `plan.md` · `progress.md`(이 파일). Tier S라 `acceptance.md`를 두지 않고 AC는 `spec.md` §3.1에 인라인했다.
- 작성 주체: 세 파일 모두 plan 레인 오케스트레이터가 직접 썼다(서브에이전트 위임 없음). 이유: 이 카드의 출발점이 "위임받은 서브에이전트가
  드라이버를 돌려 실제 데이터를 덮어썼다"(2026-09-23 14:17)이고, 실측 수치 수십 개를 그대로 옮겨야 했다.
- **가드 드라이버는 돌리지 않았다**(디스패치 금지). **`Shared/`·`Tools/` 아래 변경은 0건이다** — 커밋마다 직전에 `git status --short`로
  확인했다(바뀐 것은 이 SPEC 디렉터리와 감사 보고서뿐). 감사 2회차도 기준 트리·작업 트리 양쪽에서 `git diff --quiet … Shared/ Tools/` exit 0을 쟀다.
- 신호 줄(`plan_complete_at`·`plan_status`)은 파일 끝, §F.1 감사 자리 뒤에 둔다.

### 관측된 증거 — 이 레인이 `2a37673`에서 직접 돌린 명령

| 명령 | 관측된 출력 | 쓰인 곳 |
|---|---|---|
| `git rev-parse --short HEAD` · `git branch --show-current` | `2a37673` · `WT-driver-hardening` | 기준 트리 |
| `git diff --quiet b8bbe1c 2a37673 -- <CLAUDE.md:59-63의 12파일>` · `git log --oneline -1 -- Tools/GuardDriver.swift` | exit 0 · `f9cd9bb` | spec §0 기준선 귀속 |
| `grep -n 'appendingPathComponent("' Shared/Store.swift Shared/AIAssistant.swift Shared/Config.swift` | 데이터 파일 7개 + 디렉터리 `:67` | spec §1.2 |
| `awk` 머리말 `:168-188` · `awk 'NR>=274 && NR<=301'` · `sed -n '8,30p' Shared/Store.swift` · 첫 `drvCreate` `:428` · 절 머리 `grep -c` = 29 · 백업 `grep -n` = 10줄 | G `:278`은 없는 번호라 쓰기 전 반환(`:281` 단언) → 첫 쓰기는 H `:293`(`save()` `Store.swift:759`), 배열 `didSet`은 저장 안 함(`:10`·`:14`), 백업 7곳(`drvPersistedPayload`는 Q절 `:651`에서 불림) | spec §1.2 (감사 1회차 D1로 정정) |
| `grep -o '"title":"[^"]*"' /tmp/besir-incident-20260923/*.fixture` · `grep -n 'V-출발\|W-하룻밤' Tools/GuardDriver.swift` | `V-출발`·`W-하룻밤` · V절 `:972`·W절 `:1038` | spec §1.1 (J `:1127`보다 앞) |
| `grep -n 'Keychain\|isConnected\|…' Shared/GoogleCalendarService.swift` · `grep -n 'googleConnected\|hasGoogleCalendar\|removeFromCalendar(' Shared/Store.swift` · 함수 시작 줄 목록 | 게이트 갈래 7자리 · 게이트 밖 갈래 둘(`removeFromCalendar` 게이트 밖 호출부 6 — 아래 줄, `updateActivity` `:273`) | spec §1.3 |
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
  그것을 권고안(D-1 (a))으로 올렸다. 카드 문구 그대로의 안은 D-1 (b)로 남겼다. **게이트가 (a)로 확정했다(2026-09-24).**
- **카드 (3)의 방식** — "sleep 감시자는 wait 뒤 회수"를 적었다. 권고안(D-2 (a))은 감시자를 없애 회수할 것 자체를 없앤다. 카드 문구 그대로는 D-2 (b).
  **게이트가 (a)로 확정했다(2026-09-24).**

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

### 카드 밖 발견 — 리드 판정 (2026-09-24)

- **O-1 드라이버의 네트워크 호출**(코드 읽기 가설, 미관측) — `spec.md` §3 Out of Scope. 사실이면 `CLAUDE.md:58`의 "(API 할당량 안 씀)"이 틀리다.
  → **Day 닫기 이월**, 이 카드로 끌어들이지 않는다.
- **O-2 절마다의 파일 백업 7곳** — D-1 (a) 뒤 샌드박스 안에서만 돈다. Day 닫기 간결성 검사의 입력. → **Day 닫기 이월**.
- **O-4 공용 메모리 갱신** — `feedback_besir_driver_touches_real_data`의 "t8 전까지" 절차. → **병합 뒤 리드가 갱신**.
- R5 스킬 편집이 워크트리에서 막히면 → **리드가 run에게 `ExitWorktree(keep)` 후 편집을 지시**.

### 잔여 위험

- `CFFIXED_USER_HOME`은 문서화가 얕은 동작이다. REQ-001의 경로 확인이 무시되는 날을 잡지만, 그날 드라이버는 돌지 않는다(exit 2) — 게이트가 멈춘다.
- REQ-004는 게이트 밖 키체인 갈래의 **전제**를 잴 뿐 호출 자체를 재지 않는다. 두 측정 자리 사이에서 깼다가 되세우는 절은 통과한다.
- 샌드박스 시작 상태가 실제 설정과 달라 기준선 205가 흔들릴 수 있다(AC-008 (4)).

## §E.2 Run-phase Evidence

### M1 — 실행 전 바깥 기록 (2026-09-24, run 레인 오케스트레이터 직접)

| 항목 | 명령 | 관측 |
|---|---|---|
| 맥 앱 미실행 | `pgrep -x besir` | 빈 출력(exit 1) — M3 각 실행 앞뒤로 다시 잰다 |
| 실제 지원 디렉터리 목록 | `ls -la "$HOME/Library/Application Support/besir/"` | 파일 셋 — `activities.json`(2B)·`config.json`(288B)·`events.json`(2B), 하위 디렉터리·그 외 항목 없음(`find -mindepth 1 -maxdepth 1 ! -type f` 빈 출력) |
| 파일별 해시 | `find … -type f -exec shasum -a 256 {} +` | `events.json` `4f53cda18c2baa0c0354bb5f9a3ecbe5ed12ab4d8e11ba873c2f11161202b945` · `config.json` `e2698db8979f91dc787e310ce2f62575eb102ddca98c01f5ccc653917cbc7c05` · `activities.json` `4f53cda18c2baa0c0354bb5f9a3ecbe5ed12ab4d8e11ba873c2f11161202b945` |
| 컴파일 집합 12파일 ≡ `2a37673` | `git diff --quiet 2a37673 -- Shared/EditCard.swift Shared/AIAssistant.swift Tools/GuardDriver.swift Shared/Store.swift Shared/Models.swift Shared/Config.swift Shared/PlaceSearch.swift Shared/DirectionsService.swift Shared/LocationManager.swift Shared/NotificationManager.swift Shared/GoogleCalendarService.swift Shared/SharedInbox.swift` | exit 0 |

- 2B 두 파일은 9/23 정리된 `[]` 그대로다(공용 메모리 기록과 일치). 바깥 대조의 기준 삼값은 이 표다.
- 감사 보고서 3부(`.moai/reports/plan-audit/SPEC-TEST-001-review-1·2·3.md`) 존재 확인. Phase 1 게이트 소비 방식: plan 3회차 PASS 0.89(회차 상한 도달, 감사자 "R3 반영은 판정 불변" 서술)를 최종 판정으로 삼고 재실행하지 않았다 — 리드가 3회차 뒤 run을 디스패치했다(`plan.md` §2 끝).
- 키체인 고지·맥 앱 금지 안내(AC-002·AC-003 전제)는 M3 직전 운영자에게 별도로 한다.

### M2 — 드라이버 머리말 경화 (2026-09-24, swift-impl 전문가 위임 + run 레인 검증)

- 위임: `hns-besir-app-swift-impl-specialist`(contracts·hazards 스킬 주입). 금지 — 드라이버 실행, `Tools/GuardDriver.swift` 밖 변경, 기존 단언 수정. 준수 보고.
- 결과: `Tools/GuardDriver.swift` **+162/−1**. 삭제 1줄은 꼬리의 `exit(drvFail == 0 ? 0 : 1)` — 종료 코드 결정이 단일 종료 루틴으로 접혔다.
- 핵심 줄(편집 후): 시한 상수 `:172`(900초) · 종료 루틴 `drvFinishOnce` `:218-241`(잠금 `:223`) · 가드 삭제 `:203-214`(조건 `:205-210`, `removeItem` `:212`) · `realHome` `:253` · `setenv` `:262` < `Store(` `:305`(AC-001 (1)) · 경로 확인 fail-closed `:267-272` · 시작 스냅숏 `:281` · 기한 인자 `:287-295` · 타이머 `DispatchQueue.global().asyncAfter` `:299`(메인 액터 밖, AC-004 (6)) · `googleClientID = ""` `:315`(N-1 기존 `:1421` — AC-003 (1)·(2)) · 불변식 호출 3자리 `:346`·`:1500`·`:1775`(AC-003 (3)).
- 설계 선택(이유 한 줄씩): `exit` 채택(버퍼를 비운다 — 124·3의 이유가 로그에 남아야 AC가 출력으로 판정한다) · 종료 루틴 잠금을 풀지 않는다(먼저 온 쪽이 exit할 때까지 잠금을 쥐면 늦은 쪽은 잠금에서 프로세스와 함께 끝난다 — 풀면 루틴 밖으로 새어 나가 잘못된 exit를 할 수 있다) · 기한 인자 해석 실패 → 한 줄 고지 후 기본값(시험 편의를 위해 기본 보증을 깨는 방향이면 안 된다) · 900초 = 기록된 완주 433초의 약 2.1배 · 셈법 **205 + 7 = 212**(k=7 — 머리말 자리 3 + 기존 두 자리에 2씩; REQ-002 대조는 drvCheck를 거치지 않는다).
- 전문가 검증: 연결 타입체크(`swiftc -typecheck`, 바이너리 없음) **exit 0** — 드라이버 파일 경고 0·동시성 진단 0(`-strict-concurrency=complete`에서도 신규 코드 진단 0, 기존 `drvPass/drvFail` 선언 2건만). 탐침 `probe_home_m2`로 `/var`→`/private/var` 심볼링크 정규화가 `hasPrefix` 가드를 우회하지 않음을 실측.
- run 레인 재검증(직접): `git status --short` = ` M Tools/GuardDriver.swift` 유일 · `git diff --quiet 2a37673 -- Shared/ project.yml proxy/` exit 0 · `CFFIXED_USER_HOME` grep 1줄 · 불변식 호출부 grep 정확히 3줄 · `googleClientID = ""` 2줄 · 지워진 `drvCheck(` 0줄 · 새 코드 영역(`:165-324`)과 꼬리(`:1760-1783`) 직독.
- IDE 진단 주석: SourceKit이 이 파일을 단독 분석해 `Cannot find type 'AIAssistant'` 등을 띄우는데, 이 파일은 원래 Shared 소스와 이어붙여야 컴파일되는 설계다(머리말 `:11-16`) — 기대된 노이즈. 실제 판정은 연결 타입체크와 M3 신선 컴파일이 한다.
- 렌즈 행감 예고(M5): `drvDiffSupportDir`은 "있으나 읽기 실패(nil 바이트)"와 "없음"을 같은 상태로 센다 — 읽을 수 있는 파일의 생성·삭제·변경은 전부 잡히고, 실제 디렉터리에는 하위 디렉터리·읽기 불가 항목이 없다(M1 관측). 이 미세한 간극을 `code-safety` 렌즈가 판정한다.
- git 밖 산출물(REQ-008 목록): `/tmp/gd-t8-m2-typecheck.swift`(바이너리 미생성) · `.moai/state/verify/t8/probe_home_m2.swift`·동명 바이너리 · `.moai/state/verify/t8/hazards-SKILL-pre-edit.md`(M4 편집 전 사본).

### M3 — 드라이버 실행 두 번 (2026-09-24, run 레인 오케스트레이터 직접)

운영자 고지(실행 전, run 세션 AskUserQuestion — "시작" 응답): 키체인 대화상자는 뜨면 거부(Deny)하고 알림 · 두 실행 동안 맥 앱 금지 · ①→② 순서와 ① 이상 시 ② 중단 조건 · 전체 실행은 네트워크 조회 가능성(O-1 가설) 고지.

**① 짧은 기한 실행 (AC-004)** — 컴파일 exit 0(드라이버 파일 경고 0), 실행 명령 원문 `/tmp/gd-t8-m3a 3 > .moai/state/verify/t8/m3-short-run.log 2>&1`(sleep·kill·perl 없음):

- **exit 124 · 소요 4초**(기한 3초 + 10초 안 — 도구 호출이 기한보다 오래 붙잡히지 않았다)
- 출력 첫머리: `[샌드박스] 이번 실행의 홈: /var/folders/…/T/besir-gd-B5B669A3-…` + 지원 디렉터리가 그 안(`…/T/besir-gd-…/Library/Application Support/besir`) — AC-001 (2) 신호
- `[시한] 3초를 넘겼다 — 샌드박스: …` 한 줄 · `[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다` · 머리말 불변식 3줄 ✓
- 샌드박스 **남아 있음**(`test -e` yes — REQ-001 시한 가지는 지우지 않는다) · 바깥 대조 pre==post==M1 해시 3파일 · `pgrep -x besir` 전후 빈 출력(4회 전부 exit 1)
- AC-004 (6)·AC-001 (1)·(2)·(3) 관측 성립. **AC-001 (4)·AC-004 (6)의 코드 읽기 판정은 M5 렌즈가** 아래 §E.2 렌즈 절에 근거와 함께 적는다(타이머 `:299` · 종료 루틴 잠금 `:223` · 가드 삭제 `:205-212`).
- **exit 2 거부 가지는 관측하지 않았다** — 재지정이 실패하는 상황을 만들 방법이 없어(드라이버가 항상 자기 setenv로 덮는다) 코드 읽기로만 판정한다(AC-001 규정 문구).

**② 전체 실행 (AC-008·AC-003·AC-002)** — 신선 컴파일 `/tmp/gd-t8-m3b`(exit 0), 실행 명령 원문 `/tmp/gd-t8-m3b > .moai/state/verify/t8/m3-full-run.log 2>&1`(인자 없음 → 기본 900초):

- **exit 0 · 소요 16초**(기한 미도달 — 124 아님)
- 마지막 줄 **`212/212 통과`** — P = T = **205 + 7**(셈법: 머리말 자리 3 + 기존 두 자리에 새 단언 2씩; REQ-002 대조는 drvCheck 밖). 절별 차이 **0** — 샌드박스 씨앗(bundledDefaults·빈 배열)이 단언 수를 흔들지 않았다(AC-008 (4) 잔여 위험 현실화 없음)
- 불변식 줄 **9개**(3자리 × 3단언) 전부 ✓(AC-003 (4)) · `[실제 데이터] 대조 통과` · **샌드박스 삭제 확인**(`test -e` no — AC-001 (3)) · 바깥 해시 3파일 무변경 · pgrep 전후 빈
- **운영자 키체인 답: "안 떴다"** — 2026-09-24 run 세션 AskUserQuestion 응답(AC-003 (5))
- 부가 관측: 완주 16초는 기록된 433초(실제 데이터 씨앗)보다 짧다 — 빈 샌드박스 씨앗에서 네트워크 조회가 준 것일 수 있으나(O-1 가설) 이 카드가 재지 않았다.

**git 밖 산출물 추가**(REQ-008 목록 이어서): `/tmp/gd-t8-m3a.swift`·`/tmp/gd-t8-m3a`·`/tmp/gd-t8-m3a-compile.log` 및 `m3b` 동일 세트(컴파일마다 고유 이름 — 낡은 바이너리 재사용 없음) · `.moai/state/verify/t8/m3-short-run.log`·`m3-full-run.log`.

### M4 — CLAUDE.md + 스킬 파일 (2026-09-24)

**CLAUDE.md (REQ-006, D-4 승인 항목의 실행)**

- **편집 직전 운영자 확인 — 수단: run 세션 직접 응답.** 2026-09-24 run 세션 AskUserQuestion("CLAUDE.md 드라이버 블록 곁 편집을 승인하시나요? … 이 질문에 답하시는 것 자체가 그 확인입니다")에 운영자가 **"승인 (권장)"**으로 응답. REQ-006이 인정하는 두 수단(운영자 직접 입력 · 편집 권한 프롬프트 승인) 중 첫째. 권한 프롬프트는 따로 뜨지 않았다(세션 추가 디렉터리 경로라 무프롬프트 편집) — 확인은 직접 응답 하나로 성립했다.
- 편집: 드라이버 코드 블록 뒤 7줄 — 자기 격리(임시 홈 · 빈 클라이언트 ID · 내부 기한 기본 900초/인자 덮음), 실제 지원 디렉터리는 시작·종료 바이트 대조만, 종료 코드 **0·1·2·3·124**(1은 마지막 줄 `P/T 통과`가 있을 때만 단언 실패 — 그 앞의 1은 `&&` 연쇄상 컴파일 실패), 외부 감시자 불필요 — 굳이 두면 `wait` 직후 거둔다.
- AC-005 (1): `git diff -U0 2a37673 -- CLAUDE.md \| grep '^@@'` → 헝크 하나 `@@ -66,0 +67,7 @@`. § 빌드 · 배포는 `:45`부터 다음 `## `(`:88`) 앞까지(`grep -n '^## '`로 실측) — 삽입 줄 67-73이 전부 그 안이다.
- AC-005 (2): 종료 코드 다섯 개와 감시자 문장이 `:71-72`에 있다(`grep -n '124'` → `:72`).
- AC-005 (3): 드라이버 머리말 레시피(`Tools/GuardDriver.swift:3-9`)는 무변경 — 컴파일·실행 명령이 바뀌지 않았으므로 `CLAUDE.md` 블록과 명령 단위로 그대로 같다.
- `(API 할당량 안 씀)` 문구는 손대지 않았다(O-1 — 리드 판정 Day 닫기 이월, REQ-006 편집 범위 밖).

**스킬 파일 (REQ-007 — git 밖, 편집 전 사본이 유일한 변경 기록)**

- 편집 전 사본: `.moai/state/verify/t8/hazards-SKILL-pre-edit.md`(249줄) — M3 착수 전에 확보.
- 편집: 주 체크아웃 `.claude/skills/hns-besir-app-hazards/SKILL.md` — 후보 목록에서 `Store.updateMeal(_:)` 한 줄 제거, `RouteMode.car` 문단 뒤 유지 문단 추가(영어 4줄+빈 줄, `:244-246` 선례 모양). **워크트리에서 주 체크아웃 편집이 막히지 않았다** — `ExitWorktree(keep)` 절차는 불필요했다(리드가 예비해 둔 지시).
- AC-006 (1): `grep -n 'updateMeal'` → `:243`(유지 문단)만. 목록 마커 `:229`(Dead code candidates)·`:235`(RouteMode.car removed) 사이가 아니다.
- AC-006 (2): 문단이 `SPEC-FULL-001`·`REQ-003`·`SPEC-UIKIT-006`·`D-2 (a) (2026-09-23)`·`Shared/Store.swift:408`을 모두 담는다.
- AC-006 (3): `diff .moai/state/verify/t8/hazards-SKILL-pre-edit.md <스킬 파일>` = `233d232`(목록 한 줄 제거) + `243a243,247`(유지 문단 추가)만.

### M5 — code-safety 렌즈 (2026-09-24, 읽기 전용 — 드라이버 실행·컴파일 0회)

- 위임: `hns-besir-app-code-safety-specialist`(contracts·hazards 스킬 주입, 수정 금지·보고만 — 준수). 대상 HEAD `4da237e`, 기준 `2a37673`.
- **위험 클래스 다섯 전부 통과 — blocker 0 · should-fix 0 · note 3.** 상시 4클래스(H1 await 인덱스·H2 조용한 실패·H3 외부 한도·H4 복제 계산)도 같은 diff에서 함께 돌렸다(H1 해당 없음 — 추가 코드에 await 없음).
- **AC-001 (4) 판정: 통과.** `removeItem` 전수 11줄 — 기준 10줄(도우미 `:159` 포함; "7곳"은 백업 위치 기준)은 무변경·줄이동만, **이 카드가 더한 것은 `:212` 샌드박스 삭제 하나뿐**. 그 호출 바로 위(같은 함수 `drvRemoveSandboxIfOurs` `:203`)의 확인 조건 `:205-207`: `sandbox.path.hasPrefix(NSTemporaryDirectory())` ∧ `name.hasPrefix("besir-gd-")` ∧ `UUID(uuidString: 접미사) != nil`.
- **AC-002 (3) 판정: 통과.** 쓰기·삭제·디렉터리생성 22줄 전수의 대상이 전부 `AppConfig.supportDirectory` 파생(`:158-159`·`:793-794`·`:1314-1315`·`:1394-1397`·`:1496-1499`·`:1637-1640`·`:1768-1769`) 또는 이번 실행 샌드박스(`:212`·`:256`). 순서 보증: `AppConfig.supportDirectory`의 첫 접근이 `:267` fail-closed 가드(setenv `:262` 뒤, 그 앞 구간엔 접근 없음). **`realSupport`는 쓰기 대상 0줄** — 전용처 7곳이 전부 읽기 인자·전달이다.
- **AC-004 (6) 판정: 통과.** 타이머 생성 `:299`(`DispatchQueue.global().asyncAfter` — 전역 큐 = 메인 액터 밖, 클로저 포획은 전부 let 값 타입), 종료 루틴 잠금 `:223`(`drvFinishGate.lock()`, 해제 없음 — 이긴 쪽이 `:241` `exit`까지 보유). exit 호출부 전수가 `:241`·`:260`·`:271`이고 뒤의 둘(거부 exit 2)은 타이머 장착보다 앞 — 장착 뒤의 유일한 출구는 잠긴 단일 루틴이라 정상 종료와 시한이 같은 루틴을 한 번만 지난다. `drvFail`은 타이머 경로에서 읽히지 않고(`:236-238` 분기 구조) 주 스레드 유일 기록자와 같은 스레드에서만 읽힌다.
- **AC-007 (4) 판정: 통과(공허 충족).** 지워진 `drvCheck(` 0줄 — diff의 삭제 줄은 옛 exit 한 줄뿐.
- **잔여 (a)·(b) 판정 — 둘 다 잔여로 수용.** (a) `drvDiffSupportDir`의 nil==부재 간극(`:196` 평평화 비교): 드라이버의 쓰기 표면은 평면 파일뿐이고 하위디렉터리를 만드는 경로가 없으며, 실제 디렉터리 접근 자체가 `:267` 가드 뒤에 있고 하위디렉터리를 만들 수 있는 행위자는 실행 배제된 맥 앱뿐(M1 관측: 파일 3개·하위디렉터리 없음) — 드라이버가 낼 수 없는 상태를 위해 복잡도를 더하지 않는다. (b) 시한 순간 주 스레드 print와의 한 줄 인터리브: 로그 가독성만 영향, 종료 코드는 잠금 보호 — `_exit` 전환·stdout 잠금이 결함보다 비싸다.
- **note 3건(기록만, 무수정)**: (n1) `"besir-gd-"` 리터럴 3곳(`:206`·`:207`·`:255`) — 한쪽만 어긋나도 실패 방향이 안전(가드 탈락 → 삭제 거부·경로 print)이라 세 줄 그대로 둔다 (n2) 시한·크래시 실행이 남긴 샌드박스의 쓸개(sweeper) 없음 — REQ-001이 의도적으로 수용한 설계(지우는 경로는 정상·거부 둘뿐), Day 닫기 간결성 검사에서 O-2와 함께 한 줄로 남길 것 (n3) 기한 인자 0/음수 기각 문구 "`:292` 초로 읽지 못한다"가 부정확(파싱됐으나 기각) — 거동은 안전 방향, 문구 수준.
- **렌즈 Gaps**: exit 2 실동작(재현 불가), 미래 macOS의 재지정 변수 거동, 툴체인 동시성 검사 수준 전환 시점, `NSTemporaryDirectory()` 이중 호출 변이 — 미관측. **잔여 위험 한 줄**: `drvCheck`의 무경합 성질은 현재 호출 그래프(호출 전부 main 안)에서만 성립 — 첫 비동기 호출부가 생기는 커밋에서 이 단락을 다시 읽는다.

## §E.3 Run-phase Audit-Ready Signal

- run 단계 M1~M5 완료(2026-09-24). 커밋 사슬: M1 `cf76902` → M2 `de8fd77` → M3 `8265ea9` → M4 `4da237e` → M5(이 커밋).
- **AC 판정: AC-001 ~ AC-008 전부 PASS.** 관측·코드 읽기·문서·운영자 답의 증거는 §E.2 M1~M5. 관측 한계는 각 AC가 규정한 대로 기록됐다(AC-001 exit 2 가지 = 코드 읽기만, AC-003 (5) = 운영자 관측 "안 떴다", AC-008 (4) = 절별 차이 0).
- AC-008의 선택 빌드(iOS·macOS `xcodebuild`·`npm test`): **돌리지 않았다** — AC-007 (2)가 `Shared/`·`project.yml`·`proxy/` 무변경(`git diff --quiet` exit 0)을 증명해 이 카드와 무관함이 성립.
- git 밖 산출물 전체 목록(AC-007 (5), §E.2 M2·M3에 산개 기록): 스킬 파일(편집) · 편집 전 사본 · `/tmp/gd-t8-m2-typecheck.swift` · 탐침 `probe_home_m2`(소스·바이너리) · `/tmp/gd-t8-m3a·m3b`(연결 소스·바이너리·컴파일 로그 각 3) · `.moai/state/verify/t8/`의 실행 로그 2·스킬 사본 · 샌드박스(① `besir-gd-B5B669A3-…` 잔존 — 시한 가지 규정, ② `besir-gd-7954ED75-…` 삭제 확인). **이 외의 경로에 쓴 것 없다(run 레인 진술).**
- 후속(본 카드 밖): sync — 루트 `plan.md` Phase 1.7 표 t8 행·게이트 재실측(`plan.md` §1 sync 행). Day 닫기 이월: O-1(네트워크 가설·`CLAUDE.md` "(API 할당량 안 씀)" 문구), O-2(백업 7곳), note (n2).
- run_complete_at: 2026-09-24
- run_status: audit-ready

## §F Phase 4 Mode Selection

- 선택: **serial**(서브에이전트 없이 오케스트레이터 직접 작성 + 독립 감사 한 채널). 근거: Tier S, 문서 셋, 수치 대조가 작성과 한 손에 있어야 한다.
- run 단계(2026-09-24): **serial** — 구현 위임(`swift-impl`) 1회와 렌즈(`code-safety`) 1회를 순차로. 근거: Tier S·코딩 중심 작업이라 순차가 기본(`orchestration-mode-selection.md` §B), 드라이버 실행은 어느 에이전트도 맡지 않고 run 레인 오케스트레이터가 직접(`plan.md` §4).

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
- optional D10~D19 10건 가운데 7건 완전 반영, 2건 부분 반영, 1건 보류(2회차 감사가 D10·D15를 부분으로 판정 — 처음 이 자리에 "9건 반영"으로
  적은 것을 정정한다). 완전: plan §0 매핑(002→008), §1.3의 `update_schedule` → `modifyActivity` 경로(툴 이름 전수를 명령째 넣음), AC-002 (3)의
  grep(쓰기·삭제·디렉터리 생성 호출 전수), AC-005 (1)의 절 범위, `plan.md` §2의 게이트 표식(D16 — 넣었다가 게이트 해소로 걷음), 종료 코드 1의
  중의성, 카드 원문 인용(이 파일 §E.1). 부분: 잔여 위험의 범위(D10 — spec §3 잔여 위험은 씨앗 전체로 넓혔지만 AC-008 (4)의 문구는 설정 한정으로
  남음, 감사자 판정 "무해"), AC-006 (2)(D15 — `Store.swift:408`은 더했으나 `D-2`·새 문단 위치는 반영하지 않음). 보류: REQ 문장 안의 줄번호(프로젝트 관례).
- **1회차 뒤 재감사 없이 커밋**(`08c1a1b`). 2회차는 착수 게이트 결정을 반영한 뒤 그 델타와 이 반영분을 함께 봤다(아래).

### 2회차 — PASS 0.87, 2026-09-24

- 보고서: `.moai/reports/plan-audit/SPEC-TEST-001-review-2.md`. 같은 채널(`plan-auditor` 서브에이전트 + `audit_multi`, GLM `inconclusive` → claude 단독).
  금지 사항 동일, 준수 보고. 대상: 1회차 D1~D9 반영분 + 게이트 델타(`spec.md` 0.1.1).
- must-pass MP-1~MP-7 전부 통과(MP-4 해당 없음). `moai spec lint` 결함 없음. REQ·AC 8/8, 결정에 기대는 REQ·AC 0, 명확화 표식 0, 교차 참조 끊김 0.
- **D1~D9 아홉 모두 "해소"** — 감사자가 명령으로 재확인(D1·D5·D6의 판단은 감사자 쪽도 코드 읽기).
- 새 결함 넷, 전부 반영:
  - **R2-1 (major, blocking)** — REQ-006·AC-005 (4)·`plan.md` M4·§2 항목 4가 `CLAUDE.md` 편집 확인 수단을 권한 프롬프트 승인 하나로 좁혔다.
    선례 SPEC-UIKIT-006(`spec.md:157`)은 run 세션 직접 입력과 권한 프롬프트 승인 둘을 인정했고, 그 run은 직접 입력으로만 확인됐다
    (`progress.md:258-259` — 이 레인이 원문을 읽어 확인). 이대로면 구현이 옳아도 AC-005가 떨어질 수 있었다. → 네 곳 모두 두 수단으로, 다른 세션을
    거친 메시지는 치지 않음, 수단과 결과를 §E.2에, 둘 다 없으면 편집 보류 + 리드에게 블로커 보고.
  - R2-2 (minor) — `spec.md` HISTORY 0.1.1의 "다시 쓴 REQ·AC는 없다"가 AC-005 (4) 신설과 표식 제거를 빠뜨림 → 서술 정정.
  - R2-3 (minor) — 이 파일의 낡은 문장 넷(호출부 5, "결정은 게이트 몫", 존재하지 않는 기록 위치, "9건 반영") → 정정.
  - R2-4 (minor, 관측하지 않은 가설) — iOS 타깃도 제품 이름이 `besir`라 `pgrep -x besir`가 시뮬레이터 앱을 잡을 수 있다 → AC-002 전제와 `plan.md` M1에
    `pgrep -lf besir` 경로 확인을 더함.
- 감사자 권고: R2-1 반영분을 3회차(마지막)로 확인한다 — 3회차 뒤 재감사 없이 반영하는 일을 피하려는 것.

### 3회차(마지막) — PASS 0.89, 2026-09-24

- 보고서: `.moai/reports/plan-audit/SPEC-TEST-001-review-3.md`. 같은 채널, 금지 사항 동일·준수 보고. 범위: R2 델타만.
- 점수 0.76 → 0.87 → 0.89(명확성 0.88 · 완결성 0.95 · 시험 가능성 0.85 · 추적성 0.90). REQ·AC 8/8, 명확화 표식 0(세 파일), `moai spec lint` 결함 없음.
- R2-1·R2-2·R2-4 수정, R2-3 부분(D15 라벨 뒤바뀜 → R3-2).
- 새 결함 셋(전부 minor·optional, blocking 없음) — 감사자 지정 문구대로 반영:
  - R3-1 — R2-1이 붙인 블로커 경로가 선례 `spec.md:157` 끝 문장("리드에게 블로커 보고로 되묻지 않는다 — 되물으면 또 다른 세션을 거친 승인이
    되어…")과 어긋남. 2회차 감사자가 제안한 경로였고 선례의 끝 문장을 놓쳤다. 이 레인이 원문을 읽어 확인했다. → "리드의 처리는 확인을 대신하지
    않는다 — 이 블로커는 확인 요청이 아니라 편집 보류의 통지다"를 네 곳에.
  - R3-2 — D15(AC-006, 부분)·D16(게이트 표식, 완전) 라벨 정정.
  - R3-3 — `plan.md` §2 끝 "2회차 뒤 디스패치" → "3회차 뒤".
- **R3 반영은 재감사를 받지 않았다** — 회차 상한 3에 닿았다. 감사자 판정: 넣든 안 넣든 판정 불변.
- 감사자가 확인하지 못한 것: `pgrep -lf besir`의 판별(감사 시점에 besir 프로세스가 없었다), 드라이버 동작과 M4 확인 절차의 실제 작동(run M3·M4에서 처음 관측).

- plan_complete_at: 2026-09-24
- plan_status: audit-ready
