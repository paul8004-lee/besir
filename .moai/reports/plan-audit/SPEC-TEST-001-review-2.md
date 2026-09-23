# SPEC 검토 보고서: SPEC-TEST-001
Iteration: 2/3
Verdict: PASS
Overall Score: 0.87

> Reasoning context ignored per M1 Context Isolation. 호출자가 전한 편집 요약(게이트 결정·걷어낸 문구 목록)은 판단 근거로 쓰지 않고, 파일 본문과 대조할 **주장**으로만 다뤘다.
> 입력: Tier S — `spec.md`(0.1.1, 198줄) · `plan.md`(149줄) · `progress.md`(118줄). `acceptance.md`·`research.md`는 없다(`ls` → No such file, Tier S라 정상).
> 트리: `git rev-parse --short HEAD` → `08c1a1b` · `git branch --show-current` → `WT-driver-hardening` · `git status --short` → SPEC 파일 셋만 `M`. 델타는 `git diff -- .moai/specs/SPEC-TEST-001/`(3 files, +73 −78)로 읽었다.
> 교차 모델: 주 체크아웃 `workflow.yaml:77-82` `audit.model: multi`(claude required · codex off · glm advisory). `mcp__moai__audit_multi` → overall `pass`, GLM `inconclusive`(z.ai 응답 본문 없음, fail-open). 판정은 claude 단독이다.
> 금지 준수: 가드 드라이버·CLAUDE.md 레시피·`.moai/state/verify/t8/`의 탐침 바이너리는 컴파일도 실행도 하지 않았다. `~/Library/Application Support/besir/`·키체인·`/tmp/besir-incident-20260923/`은 건드리지 않았다. SPEC 디렉터리와 저장소 파일은 수정하지 않았다. 쓴 파일은 이 보고서 하나다.

**판정 요지.** must-pass 일곱이 모두 PASS다(MP-4 N/A). 1회차 blocking 결함 D1~D9는 **아홉 모두 본문에서 해소됐다**(아래 표 — 요약이 아니라 해당 줄과 코드로 대조했다). 게이트 델타는 조건 문구를 깨끗이 걷었고, 결정에 기대는 REQ·AC는 남지 않았다. REQ 8 · AC 8이다. 점수는 0.76에서 0.87로 올랐다(STOP 신호 없음). **새 blocking 결함이 하나 있다(R2-1).** 게이트 델타가 REQ-006·AC-005 (4)에 넣은 "`CLAUDE.md` 편집 확인" 수단이 권한 프롬프트 승인 하나뿐이다. 그런데 인용한 선례(SPEC-UIKIT-006 REQ-020 (a))는 두 수단을 인정했고, 선례의 run 기록에는 **권한 프롬프트가 뜨지 않았다**고 남아 있다. 이대로면 AC-005 (4)는 결함이 없어도 FAIL할 수 있다. 문구 네 곳을 고치는 일이고, run이 M4에 닿기 전에 고쳐야 한다.

## Must-Pass Results

| # | 결과 | 근거 |
|---|---|---|
| MP-1 REQ 번호 | PASS | `grep -n '^- \*\*REQ-' spec.md` → REQ-001(:96)·002(:98)·003(:102)·004(:104)·005(:108)·006(:112)·007(:114)·008(:118). 빈 번호·중복 없음, 세 자리 zero-padding 일관 |
| MP-2 GEARS | PASS | *판정 층위: 요구사항 층(`spec.md` §2, :96-118)만.* §3.1의 Given-When-Then AC는 검증 층의 올바른 형식이라 여기서 채점하지 않았다. Event-driven 3건(REQ-001 "When the driver starts, it shall…", REQ-002 "When the driver starts and again when it ends…", REQ-005 "When the driver has run longer than its deadline, it shall…"), State-driven 1건(REQ-003 "While the driver runs, … shall be empty"), Ubiquitous 3건(REQ-004·006·007), Unwanted 1건(REQ-008 "The change shall not modify…"). 델타는 REQ의 규범 문장(영문)을 바꾸지 않았다 — 바뀐 곳은 REQ-004·006·008의 괄호·근거 절뿐이다(diff 202/203·211/212·218/219행) |
| MP-3 frontmatter | PASS | `spec.md:2-13`에 12개 필드. `version: "0.1.1"`(따옴표 semver, 0.1.0에서 올림), status `draft`, created·updated `"2026-09-24"`, priority `P1`, lifecycle `spec-anchored`, tags 쉼표 문자열. 거부 별칭 0건. `moai spec lint .moai/specs/SPEC-TEST-001/spec.md` → `✓ No findings — all SPEC documents are valid` |
| MP-4 언어 중립성 | N/A | 단일 언어(Swift) 호스트 도구 하나를 고치는 SPEC이다 |
| MP-5 D7 | PASS | D7 동사 실행 → SPEC-FULL-001 `in-progress` · SPEC-ONTIME-001 `draft` · SPEC-UIKIT-006 `completed` · SPEC-TEST-001(자기) `draft`. retired/superseded/archived 0건, 미발견 0건. plan.md 참조는 SPEC-TEST-001·SPEC-UIKIT-006뿐. BLOCKING 없음 |
| MP-6 D8 | PASS | `grep -c 'syscall'` → spec.md 0 · plan.md 0. D8-4 자동 통과 |
| MP-7 명확화 게이트 | PASS | `grep -rn '\[NEEDS CLARIFICATION' plan.md spec.md progress.md` → `progress.md:113` 한 줄뿐인데, 이것은 1회차 반영 내역을 서술하며 백틱으로 인용한 토큰 이름이다(`: <topic>`이 없다 — 표식 아님). MP-7의 검사 대상인 `plan.md`는 0건, `research.md`는 없다. 08c1a1b의 `plan.md` §2에 있던 표식 다섯(diff 51-55행)은 게이트 해소로 걷혔다 |

## Category Scores (0.0-1.0, rubric-anchored)

| Dimension | Score | Rubric Band | Evidence |
|---|---|---|---|
| Clarity | 0.85 | 0.75~1.0 사이 | 1회차 감점 셋이 풀렸다 — REQ-001 :96 "when the run ends normally or is refused this way"(D4), REQ-002 :98 "끝내는 일은 한 루틴이 한 번만 한다"(D5), REQ-008 :118 git 밖 목록(D3). 감점: REQ-006 :112의 확인 수단이 선례와 다르게 좁혀졌다(R2-1). "정상 종료"가 단언 실패(1)·대조 차이(3)로 끝나는 완주를 포함하는지는 REQ-002의 "normal completion"으로 읽혀 일관되게 해석된다(감점 없음) |
| Completeness | 0.95 | 1.0 대역 | HISTORY :21-26(0.1.1 행 추가), 배경 :38-88, 요구사항 :90-118, 인라인 AC :124-156, `### Out of Scope —` H3 넷과 `-` 항목(:158-173), 잔여 위험 :175-177(씨앗 전체로 넓힘), 결정 해소 기록 :179-189, 기각안 `plan.md` §2 :42-69. frontmatter 12/12. 감점: `progress.md`에 정정·해소 뒤 낡은 문장 넷(R2-3) |
| Testability | 0.80 | 0.75~1.0 사이 | AC-003 (3)이 정확한 명령과 "정확히 3줄"을 갖췄고(D7), AC-004 (4)가 경합에 흔들리지 않게 바뀌었으며(D5), AC-001 (4)·AC-004 (6)이 코드 읽기 판정을 더했다(D9·D6). 감점: AC-005 (4)가 환경에 따라 충족 불가(R2-1), AC-008 (4)의 "회귀로 판정되면"은 여전히 판단이다, AC-006 (1)은 새 문단 위치에 따라 판단이 끼어든다(D15 잔여) |
| Traceability | 0.90 | 0.75~1.0 사이 | REQ 8건 전부 AC ≥1, AC 8건 전부 실재 REQ를 가리킨다(헤더 :126-154). 1회차에서 AC가 없던 세 성질이 모두 AC를 얻었다 — 삭제 대상 확인(AC-001 (4)), 메인 액터 밖 타이머(AC-004 (6)), git 밖 쓰기(AC-007 (5)). `plan.md:18` 매핑이 002→002·004·008로 고쳐졌다. 감점: AC-005 (4)가 REQ-006의 규범 문장이 아니라 근거 절의 절차를 잰다(R2-1에 포함) |

집계: 조화평균 4 / (1/0.85 + 1/0.95 + 1/0.80 + 1/0.90) = 4 / 4.5902 = **0.87**. Tier S 통과선 0.75(주 체크아웃 `spec-workflow.md:140` — 직접 읽음) 이상. 1회차 0.76보다 높아 점수 하락 STOP 조건은 해당 없다.

## 1회차 결함 D1~D9 — 본문 대조

HISTORY 0.1.0 행(`spec.md:25`)의 요약이 아니라 해당 줄과 코드를 직접 대조했다.

| # | 판정 | 확인한 본문 | 증거 명령 → 관측 출력 |
|---|---|---|---|
| D1 첫 쓰기 인용 | **수정** | `spec.md:52` "첫 쓰기는 H절 `:293`의 `drvUpdate`다(→ … `save()` `Store.swift:759`, 코드 읽기). 그 앞의 G절 `:278`은 없는 번호(99)를 줘 쓰기 전에 돌아가고, … `:281`에서 '아무것도 쓰지 않는다'를 단언한다". `progress.md:26`(G→H 정정 표기), `:54`("첫 쓰기 H `:293`부터 V·W까지"). `grep -n '첫 쓰기'` 세 파일 → 남은 G 서술 0 | `sed -n '274,295p' Tools/GuardDriver.swift` → `:278 let g1 = await aiG.drvUpdate(["series_number": 99, "mode": "car"])` · `:281 aiG.drvCheck("아무것도 쓰지 않는다", …)` · `:292 aiH.drvSetLast(ridY)` · `:293 _ = await aiH.drvUpdate(["series_number": 0, "mode": "car"])`. `sed -n '755,766p' Shared/Store.swift` → `:759 save()` 다음 `:764 if googleConnected {`. 더 앞선 쓰기가 없는지도 봤다: A~F절(`:190-273`)의 호출은 `drvCheck`·`drvZero`·`drvList`뿐(`grep -o 'ai[A-Z]*\.[a-zA-Z]*('` 집계), `AIAssistant.init`(`AIAssistant.swift:113-123`)은 `loadHistory()`만 부르고 `saveHistory()`는 부르지 않는다. **(코드 읽기다 — 드라이버 실행 금지)** |
| D2 게이트 밖 호출부 수 | **수정** | `spec.md:59` "게이트 밖은 **여섯**이다 — `updateActivity` `:272` · `deleteActivity` `:370` · … `deleteActivities` `:1289`. 게이트 안은 셋 — `:773` · `:965` · `:1425`", (ii)는 `:273` `createEvent`만 | `grep -n 'removeFromCalendar(' Shared/Store.swift` → `97`(정의)·`272`·`370`·`706`·`773`·`965`·`1258`·`1276`·`1289`·`1425`. 9 − 3 = 6. 잔여: `progress.md:28`의 옛 증거 행이 아직 "호출부 5"다 — R2-3 |
| D3 REQ-008 git 밖 조항 | **수정** | `spec.md:118` "outside git it shall write only the hazards skill file (REQ-007), the driver's own sandbox, and run-lane scratch artifacts (the freshly compiled driver binaries and concatenated sources under `/tmp` as `CLAUDE.md:59-60` compiles them, the skill file's pre-edit copy, and run logs), listing every such path in `progress.md` §E.2". AC-007 (5) `:152`가 같은 목록을 잰다. AC-006 사본·AC-008 컴파일 산출물과의 모순이 없어졌다 | `sed -n '56,66p' CLAUDE.md`(워크트리) → `:59 cat Shared/EditCard.swift Shared/AIAssistant.swift Tools/GuardDriver.swift > /tmp/gd.swift \` · `:60 && swiftc -o /tmp/gd …`. 미채택 부분: git 무시 증거 경로(`.moai/state/verify/t8/`)를 이름으로 적지 않았다 — 목록의 "pre-edit copy"·"run logs"가 위치를 묶지 않아 모순은 남지 않는다 |
| D4 "every exit path" | **수정** | `spec.md:96` "when the run ends normally or is refused this way, it shall remove that directory"와 "**지우는 경로는 둘뿐이다**(정상 종료 · 거부) … 신호(`SIGKILL`·처리기 없는 `SIGINT`/`SIGTERM`)·크래시로 끝나도 샌드박스는 남는다". `spec.md:183` D-1 (a) "**실제 지원 디렉터리의 파일은** 무사하다(키체인·네트워크는 이 안이 막는 경로가 아니다 — D-3·O-1)" | `grep -n 'every exit path' spec.md plan.md progress.md` → `progress.md:109`(1회차 반영 내역의 인용) 하나뿐, 요구사항에는 0. 참고: REQ-005 근거(`:108`)의 "시간 제한으로 끊겨도 실제 데이터는 무사하고"는 시한 맥락이라 오독 여지가 작다(1회차 지적 위치가 아니었다 — 결함으로 세지 않음) |
| D5 단일 종료·코드 2·삭제 경합 | **수정** | `spec.md:98` "**끝내는 일은 한 루틴이 한 번만 한다** — … 먼저 들어온 쪽이 대조·종료 코드 결정·종료를 하고, 늦게 온 쪽은 그 루틴 안으로 들어가지 못한다(잠금 등)", "2는 어떤 절도 돌기 전의 거부라 다른 코드와 겹치지 않는다". REQ-001 `:96` 시한 가지는 지우지 않고 경로만 찍는다. REQ-005 `:108` "through the single finishing routine of REQ-002 … leaving the sandbox in place". AC-004 (4) `:140` "REQ-001대로 이 가지는 지우지 않는다" | `sed -n '1454,1457p' Shared/Store.swift` → `:1456 try? FileManager.default.createDirectory(at: AppConfig.supportDirectory, withIntermediateDirectories: true)`(REQ-001이 드는 경합 근거와 일치). optional이던 타이머 위치 변경은 미채택(`plan.md:32` 여전히 머리말 끝) — `Store.init`(`Store.swift:117-126`)은 읽기만 하고 키체인에 닿지 않으므로 알려진 위험은 없다 |
| D6 AC-004 메인 액터 밖 판별 | **수정** | AC-004 (6) `spec.md:140` "**코드 읽기**: 시한 타이머가 메인 액터 밖(전역·전용 디스패치 큐나 스레드)에서 돌고, 정상 종료와 시한이 같은 종료 루틴을 한 번만 지난다 — 짧은 기한 실행은 메인 액터의 `Task.sleep` 타이머로도 124가 나와 이 성질을 가리지 못하므로, 타이머 생성 줄과 종료 루틴의 잠금 줄을 `progress.md` §E.2에 적고 `code-safety` 렌즈가 판정한다" | `sed -n '163,169p' Tools/GuardDriver.swift` → `:165 @main` · `:167 @MainActor` · `:168 static func main() async {` · `:169 let store = Store(…)` (`plan.md:86`의 `:167` 인용과 일치) |
| D7 AC-003 세는 명령 | **수정** | AC-003 `spec.md:136` — `grep -n 'calSavedClientID'`를 현재 트리와 `git show 2a37673:…` 양쪽에 돌려 "줄번호를 빼고 같은 두 문장", `grep -n '<불변식 함수 이름>(' … \| grep -v 'func '` → "**정확히 3줄**이고(`2a37673`에서는 2줄 — `:1342`·`:1617`)" | `git show 2a37673:Tools/GuardDriver.swift \| grep -n 'calSavedClientID'` → `1262: let calSavedClientID = store.config.googleClientID` · `1337: store.config.googleClientID = calSavedClientID`. `git show 2a37673:Tools/GuardDriver.swift \| grep -n 'drvAssertNoCalendarPush(' \| grep -v 'func '` → `1342`·`1617` 두 줄. SPEC의 기준값과 일치 |
| D8 비샌드박스 맥 앱 | **수정** | AC-002 Given `spec.md:132` "두 실행 동안 macOS 앱(besir)이 떠 있지 않고(`pgrep -x besir` 빈 출력을 실행 전후에 기록 — … `project.yml:107`)"와 "실행 중 맥 앱이 떠 있었다면 (1)·(2)는 판정하지 않고 다시 돈다". `plan.md:31` M1 · `:33` M3 · `:80-81` §3 | `grep -n 'app-sandbox' project.yml` → `107: com.apple.security.app-sandbox: false`. 프로세스 이름: 최상위 `PRODUCT_NAME: besir`(`project.yml:14`)를 `besir-macOS`(`:89-116`)가 재정의하지 않는다 → `pgrep -x besir`가 맥 앱에 맞는다. 미채택 부분: REQ-002 출력 문구("드라이버나 다른 쓰기 주체")는 바꾸지 않았다 — 전제와 재실행 규칙이 오독을 막으므로 결함은 남지 않는다. 부작용 하나는 R2-4 |
| D9 삭제 대상 확인 AC | **수정** | AC-001 (4) `spec.md:128` "셋째가 찍는 줄 가운데 이 카드가 더한 것은 샌드박스 삭제뿐이고, 그 호출 바로 앞에 경로가 `NSTemporaryDirectory()` 아래이며 이번 실행의 고유 이름을 담는지 확인하는 조건이 있다 — … 코드 읽기, `code-safety` 렌즈가 판정". "기존 7곳의 `removeItem`은 무변경" | `git show 2a37673:Tools/GuardDriver.swift \| grep -n 'removeItem'` → 10줄(`159`·`636`·`1157`·`1237`·`1239`·`1339`·`1341`·`1480`·`1482`·`1611`), 7곳 — "7곳"과 일치 |

**결과: D1~D9 아홉 모두 해소.** 1회차의 미해결 결함으로 자동 FAIL이 되는 항목은 없다.

### 선택 지적 D10~D19 — `progress.md` §F.1 주장 대조

| # | 판정 | 근거 |
|---|---|---|
| D10 잔여 위험 범위 | 반영 | `spec.md:177`이 씨앗 전체(설정·일정·즐겨찾기·활동·식사·묘비·대화 기록)로 넓혔다. AC-008 (4)는 여전히 "설정에 기대는 단언"이지만 같은 단락이 "사실상 설정 하나"인 이유를 적어 무해하다 |
| D11 매핑 | 반영 | `plan.md:18` "002→002·004·008" |
| D12 `update_schedule` 경로 | 반영 | `spec.md:59-60`. 재확인: `sed -n '308,311p' Shared/Store.swift` → `:310 if changed { updateActivity(updated) }`, `AIAssistant.swift:2220` `store.modifyActivity(…)`. 툴 이름 전수 `grep -o 'drvExecuteTool("[a-z_]*"' \| sort \| uniq -c` → `create_activity` 4 · `create_schedule` 3, `drvAsk` → `create_activity` 6 · `create_recurring_schedule` 3 · `create_schedule` 32, `grep -c 'update_schedule\|delete_schedule\|modifyActivity\|modifyEvent'` → 0. 드라이버의 직접 store 호출 `grep -o 'store\.[a-zA-Z]*('` → `enqueueCalendarUpload` 2 · `pushActivitiesToCalendar` · `pushToCalendar` · `travelSeconds` — 앞의 셋은 게이트 갈래(`:805`·`:902`·`:867`)다. SPEC 결론 유지 |
| D13 AC-002 (3) grep | 반영 | `write(to\|removeItem\|createDirectory` 전수로 바뀌었다. `2a37673`의 20줄 대상 URL은 모두 `AppConfig.supportDirectory.appendingPathComponent(…)`에서 나온다(`:151`·`:632`·`:1126`·`:1165`·`:1166`·`:1249`·`:1250`·`:1355`·`:1356`·`:1490`) — 기존 줄이 (3)을 깨지 않는다 |
| D14 AC-005 절 범위 | 반영 | `grep -n '^## ' CLAUDE.md`(워크트리) → `:45 ## 빌드 · 배포` 다음 `:81` |
| D15 AC-006 | **부분** | `Store.swift:408`은 더했고, `D-2`와 새 문단 위치는 반영하지 않았다. `progress.md:112`의 주장도 ":408"만 말하므로 주장 자체는 정확하다 |
| D16 게이트 표식 | 반영 후 해소 | 08c1a1b에서 토큰 다섯을 넣었고(diff 51-55행) 0.1.1에서 걷었다 |
| D17 줄번호 | 보류(명시) | 프로젝트 관례로 남긴다고 적었다 |
| D18 종료 코드 1 | 반영 | `spec.md:112` "마지막 줄 `P/T 통과`가 있을 때의 1만 단언 실패" |
| D19 카드 원문 | 반영 | `progress.md:45-47`에 원문 인용 |

`progress.md:111`의 "10건 중 9건 반영"은 D10·D15가 부분이라 조금 부풀려졌다(R2-3에 포함).

## 게이트 델타(0.1.1) 감사

1. **결정에 기대는 REQ·AC가 남았나 — 없다.** `grep -n '승인 시\|거절되면\|거절됐을\|권고안\|게이트가 다른 안\|확정 대기\|고르면\|채택되면\|when D-4\|only when' spec.md plan.md progress.md` → `spec.md`는 HISTORY 0.1.0 행(:25, 이력)과 :160("네트워크 대기" — 게이트 무관)뿐, `progress.md:56-57`은 plan 시점 서술(R2-3). REQ·AC 본문 0건. REQ-004가 D-3 (b)를 언급하는 것은 "채택하지 않음 — `plan.md` §2"라는 설명이지 조건이 아니다. AC-005의 거절 가지와 AC-007의 "(D-4 승인 시)"가 없어진 것을 diff 232/233·241/242행에서 확인했다.
2. **명확화 표식 — 없다.** MP-7 참조.
3. **§4를 줄이며 잃은 것 — 요구사항에 영향을 주는 것은 없다.** 채택안 다섯, REQ 대응, 기각안 (b) 넷의 내용과 주된 기각 사유는 `spec.md` §4(:183-187)와 `plan.md` §2(:47-64)에 남았다. 빠진 것은 기각안의 부가 근거뿐이다: D-1 (b)의 "기록된 PID가 살아 있으면 거부, 죽었으면 복원", D-1의 "카드의 목적은 (a)가 더 강하게 채운다", D-2의 "바깥 프로세스를 하나도 띄우지 않는다(백그라운드 부하 규율)", D-3의 "'출시 전에 제거할 테스트용 코드'와 같은 관리 대상이 하나 는다", D-4의 "운영자 지시 문서라 편집 자체를 게이트에서 묻는다", 그리고 "(b)를 고르면" 절(이제 무의미). 모두 `git show 08c1a1b:.moai/specs/SPEC-TEST-001/spec.md`로 되찾을 수 있어 결함으로 세지 않았다.
4. **REQ·AC 수 — 8/8.** `grep -c '^- \*\*REQ-' spec.md` → 8, `grep -c '^#### AC-' spec.md` → 8. Tier S 상한 8(`spec-workflow.md:148`)과 같다.
5. **카드 밖 발견의 리드 판정 — 세 파일이 일치한다.** O-1·O-2 "Day 닫기 이월": `spec.md:161`·`:165`, `plan.md:65-66`·`:143-144`, `progress.md:73-75`. O-4 "병합 뒤 리드가 갱신": `spec.md:173`, `plan.md:66`·`:145`, `progress.md:76`. 스킬 편집이 막힐 때의 `ExitWorktree(keep)` 지시: `plan.md:66-67`·`:92-93`, `progress.md:77`.
6. **교차 참조 — 끊어진 것 없음.** REQ-004 → `plan.md` §2 항목 3(D-3 (b) 있음), `spec.md` §4 → `plan.md` §2, `plan.md` §0 → "§2 항목 5"(Tier S 있음), `progress.md:10` → "`spec.md` 0.1.1"(frontmatter `version: "0.1.1"`과 일치).
7. **결정 자체의 귀속.** 운영자의 답은 이 감사자도, plan 세션도 보지 않았다 — SPEC 스스로 세 곳에 그렇게 적었다(`spec.md:26`·`:181`, `plan.md:45`). 결정의 사실성은 리드 전달을 믿은 것이다.

## Defects Found (structured defect-list)

R2-1. confirmation-means-narrowed — spec.md:L112(REQ-006 근거 절), spec.md:L144(AC-005 (4)), plan.md:L34(M4), plan.md:L60-62(§2 항목 4) — 게이트 델타가 "`CLAUDE.md` 편집을 run 세션에서 확인한다"를 넣으면서 인정 수단을 **권한 프롬프트 승인 하나**로 정했고, AC-005 (4)는 그 기록이 없으면 통과하지 못한다. 근거로 든 선례는 두 수단을 인정했고, 실제 run에서 쓰인 것은 이 SPEC이 뺀 쪽이다. 권한 모드가 편집을 자동 허용하는 세션이면 프롬프트가 아예 뜨지 않아, 구현이 옳아도 AC-005가 FAIL하거나 run 레인이 즉석에서 해석하게 된다. 또한 AC-005 (4)는 REQ-006의 규범 문장(영문)이 아니라 근거 절의 절차를 잰다. — 증거: `grep -n 'REQ-020' .moai/specs/SPEC-UIKIT-006/spec.md`의 `:157` → "**확인으로 치는 수단은 둘뿐이다**: 운영자가 run 세션에 직접 입력한 확인, 또는 그 편집에 뜨는 권한 프롬프트를 운영자가 승인하는 것. 리드나 다른 세션을 거친 메시지는 확인으로 치지 않는다." `sed -n '256,262p' .moai/specs/SPEC-UIKIT-006/progress.md` → "운영자 응답 … 이 세션 AskUserQuestion 직접 입력, 편집 직전 (REQ-020 (a)의 인정 수단 1번). **권한 프롬프트는 뜨지 않았다**(직접 입력으로만 확인됨)." — Severity: major — Class: blocking — Required fix: 네 곳을 선례와 같은 두 수단으로 고친다. REQ-006 근거 절: "승인이 리드를 거쳐 왔으므로 run 레인은 편집 직전에 자기 세션에서 확인받는다. 확인으로 치는 수단은 둘이다 — 운영자가 run 세션에 직접 입력한 확인, 또는 그 편집의 권한 프롬프트 승인. 리드나 다른 세션을 거친 메시지는 확인으로 치지 않는다. 수단과 결과를 `progress.md` §E.2에 적는다." AC-005 (4): "`progress.md` §E.2에 확인 수단(직접 입력 · 권한 프롬프트 승인 중 하나)과 결과가 있다 — 없으면 FAIL." `plan.md` M4와 §2 항목 4도 같은 두 수단으로 맞춘다. 칸반 구성상 run 레인이 운영자에게 직접 물을 수 없다면, 그 경우의 처리(편집 보류 + 리드에게 블로커 보고)를 같은 자리에 한 줄 적는다 — 어느 쪽인지는 리드가 정한다.

R2-2. history-011-inaccurate — spec.md:L26(HISTORY 0.1.1) — "(b)가 없으므로 **다시 쓴 REQ·AC는 없다** — 결정에 기대던 조건 문구만 걷었다"라고 했지만 AC-005에는 새 판정 항목 (4)가 생겼다(diff 233행). REQ-006의 절 추가는 괄호로 밝혔지만 AC-005 (4)는 밝히지 않았다. `plan.md` §2에서 `[NEEDS CLARIFICATION]` 토큰 다섯을 걷은 사실도 적혀 있지 않다. 변경 기록을 믿는 독자는 AC-005가 그대로라고 여긴다. — 증거: diff 232행(옛 AC-005, 판정 항목 (1)~(3)+거절 가지) 대 233행(새 AC-005, (1)~(4)). — Severity: minor — Class: optional — Required fix: R2-1을 고칠 때 0.1.1 행을 "다시 쓴 REQ는 없다. AC-005에 확인 기록 항목 (4)를 더했다(REQ-006 근거 절의 확인 절차를 잰다). `plan.md` §2의 명확화 토큰 다섯을 걷었다"로 고친다.

R2-3. progress-stale-lines — progress.md:L16·L28·L55-57·L111 — 정정·해소 뒤에 남은 낡은 문장 넷. (a) `:28` 증거 행이 여전히 "게이트 밖 갈래 둘(`removeFromCalendar` 호출부 5, …)"이다. 바로 아래 `:30` 행이 6으로 정정하지만 `:28`에는 표시가 없다. (b) `:55-57` "그것을 권고안(D-1 (a))으로 올렸다 … 결정은 게이트 몫이다"는 게이트 해소 뒤 낡았다. (c) `:16` "`Shared/`·`Tools/` 아래 변경은 0건이다(`git status --short`로 커밋 전 확인 — §F.1 뒤 신호 앞에 기록)"가 가리키는 기록이 없다. §F.1 끝(:114)과 신호 줄(:116-117) 사이는 빈 줄뿐이고, 08c1a1b에도 없었다(`git show 08c1a1b:…/progress.md`의 `:13`에 같은 문장, 끝 다섯 줄에 기록 없음). 주장 자체는 참이다(아래 "직접 확인"). (d) `:111` "10건 중 9건 반영" — D10·D15는 부분이다. — Severity: minor — Class: optional — Required fix: (a) `:28` 출력 칸을 "호출부 5 → 6으로 정정(아래 행)"으로 고친다. (b) `:56-57` 끝에 "→ 게이트가 (a)로 정했다(2026-09-24)"를 붙인다. (c) `:16`의 괄호를 실제 명령과 출력(`git diff --quiet 2a37673 HEAD -- Shared/ Tools/` → exit 0)으로 바꾸거나 "기록" 문구를 뺀다. (d) "9건(그중 D10·D15는 부분)"으로 고친다.

R2-4. pgrep-simulator-false-positive — spec.md:L132(AC-002 Given), plan.md:L31·L33 — `pgrep -x besir`는 프로세스 이름만 본다. iOS 타깃도 최상위 `PRODUCT_NAME: besir`(`project.yml:14`)를 물려받으므로(재정의는 `besirShare`의 `:84`뿐), iOS 시뮬레이터에서 besir가 떠 있으면 같은 이름의 호스트 프로세스가 잡힐 가능성이 크다. 이 경우 M1 전제가 막혀 run 레인이 멈춘다. 멈추는 방향의 오탐이라 안전하다. **가설이다** — 시뮬레이터 프로세스 이름을 이 감사에서 관측하지 않았다. — Severity: minor — Class: optional — Required fix: M1·M3에 "비어 있지 않으면 `pgrep -lf besir`로 경로를 보고 `CoreSimulator` 아래가 아닌 `besir.app/Contents/MacOS/besir`만 맥 앱으로 친다"를 한 줄 더한다.

## Regression Check (Iteration 2)

1회차 결함:
- D1: RESOLVED — `spec.md:52`, `progress.md:26`·`:54`, 코드 `GuardDriver.swift:278`·`:281`·`:293` · `Store.swift:759`
- D2: RESOLVED — `spec.md:59` "여섯", `grep -n 'removeFromCalendar('` 10줄(정의 포함)
- D3: RESOLVED — `spec.md:118` git 밖 목록, AC-007 (5) `:152`
- D4: RESOLVED — `spec.md:96`(두 경로로 좁힘), `:183`(주어를 좁힘)
- D5: RESOLVED — `spec.md:98`(단일 루틴·코드 2), `:96`·`:108`·`:140`(시한 가지는 지우지 않음)
- D6: RESOLVED — AC-004 (6) `spec.md:140`
- D7: RESOLVED — AC-003 `spec.md:136`, 기준값 `:1262`·`:1337`·`:1342`·`:1617` 실측 일치
- D8: RESOLVED — AC-002 Given `spec.md:132`, `plan.md:31`·`:33`·`:80-81`
- D9: RESOLVED — AC-001 (4) `spec.md:128`
- 세 회차 연속으로 남은 결함 없음(정체 신호 없음). 점수 0.76 → 0.87, STOP 신호 없음.

## Recommendation

1. **manager-spec(또는 plan 레인)** — R2-1을 run 디스패치 전에 고친다. 늦어도 run이 M4(`CLAUDE.md` 편집)에 닿기 전이다. 고칠 문구는 R2-1에 그대로 적었다(`spec.md:112`·`:144`, `plan.md:34`·`:60-62`). 같은 커밋에서 HISTORY 0.1.1 문구(R2-2)도 맞춘다.
2. R2-3·R2-4는 선택이다. 한 줄씩이라 같은 편집에 넣으면 싸다.
3. **재감사.** 회차 상한 3에서 1회가 남는다. R2-1을 적힌 문구대로 고쳤다면 3회차는 R2-1·R2-2만 보는 델타 확인으로 충분하다. 문구를 달리 쓰거나 다른 곳을 건드렸다면 3회차를 받는다. 선례(SPEC-UIKIT-006)처럼 3회차 뒤 재감사 없이 반영하는 일이 없도록, 고친 뒤에 확인받기를 권한다.
4. **이 PASS가 보장하지 않는 것.** 드라이버 동작(격리·대조·시한·키체인)은 전부 run의 M3에서 처음 관측된다. 이 감사의 설계 판단은 코드 읽기다.

## 감사자가 직접 확인한 것과 SPEC에서 가져온 것

**직접 확인 (이 트리 `08c1a1b` + 작업 트리 델타, 명령과 출력을 관측)**
- 트리·델타: `git rev-parse --short HEAD` = `08c1a1b`, 브랜치 `WT-driver-hardening`, `git status --short` = SPEC 파일 셋 `M`, `git diff --stat` 3 files +73 −78, 델타 전문 316줄.
- 규칙: 주 체크아웃 `spec-workflow.md:140`(Tier S 통과선 0.75)·`:148`(8/8), `workflow.yaml:77-82`(audit multi).
- 수: REQ 8 · AC 8, `moai spec lint` 무결함, D7 동사(참조 SPEC 셋의 status), `syscall` 0, `[NEEDS CLARIFICATION]` plan.md 0.
- 코드(D1): `GuardDriver.swift:274-295`, `:190-273`의 호출 집계, `:43-45`(`drvZero`)·`:71-73`(`drvList`·`drvUpdate`·`drvSetLast`), `Store.swift:755-766`, `AIAssistant.swift:113-123`·`:218-224`·`:1799`·`:1810`·`:1834`.
- 코드(D2·D12·키체인): `Store.swift` `removeFromCalendar(` 10줄, `:8-20`(`config`는 `@Published`, 저장 `didSet` 없음), `:117-126`(`Store.init` 읽기만), `:264`·`:288`·`:308-311`·`:480`·`:715`·`:804`, `updateRecurringSeries` 본문(`:715-800`)의 `updateActivity` 0건, `AIAssistant.swift:2218-2221`, `GoogleCalendarService.swift:16`·`:37`·`:253`, 드라이버의 툴 이름·`execute*`·`store.` 호출 전수, `:1282`·`:1312`·`:1318`·`:1332`.
- 코드(D5·D7·D9·D13): `Store.swift:1454-1457`, `git show 2a37673:Tools/GuardDriver.swift`의 `calSavedClientID` 2줄 · 불변식 호출 2줄 · `removeItem` 10줄 · `write(to|removeItem|createDirectory` 20줄과 그 대상 URL 정의 10줄, `GuardDriver.swift:163-169`.
- 설정·문서: `project.yml:14`·`:84`·`:86-116`(맥 타깃 이름 재정의 없음, `:107` 비샌드박스), 워크트리 `CLAUDE.md:23`·`:45`·`:56-66`(`EditCard.swift` 포함 12파일 블록)·`## ` 머리 목록, 스킬 파일 249줄·`:229`·`:233`·`:236`·`:244`.
- 무변경: `git diff --quiet 2a37673 HEAD -- Shared/ Tools/ project.yml proxy/ CLAUDE.md` → exit 0, `git diff --quiet -- Shared/ Tools/`(작업 트리) → exit 0, `git diff --name-only 2a37673 HEAD` → 보고서 1 + SPEC 파일 3.
- 선례: SPEC-UIKIT-006 `spec.md:26`·`:156-157`·`:211`, `progress.md:256-262`(R2-1의 근거).

**SPEC·호출자에서 가져온 것(감사자가 재지 않음)**
- 운영자의 게이트 결정(D-1 (a)·D-2 (a)·D-3 (a)·D-4 승인·Tier S)과 O-1·O-2·O-4·`ExitWorktree(keep)`에 대한 리드 판정 — 리드 전달이다. plan 세션도 직접 보지 않았다고 적었다.
- 탐침 결과(§1.4), 기준선 205/205, 2026-09-23 멈춤의 `sample`, t5 레인의 시각, 워크트리 가드의 `HOME=`·`perl` 거부 — 다른 레인의 관측이며 드라이버·탐침 실행이 금지돼 재현하지 않았다.
- 사고 백업의 제목(`V-출발`·`W-하룻밤`) — 운영자 데이터 사본이라 열지 않았다.
- R2-4의 시뮬레이터 프로세스 이름 — 관측하지 않은 가설이다.
- D1·D5·D6의 판단과 1회차 설계 판단은 감사자 쪽도 **코드 읽기**다.

**교차 모델**: `audit_multi` → claude `pass`, GLM `inconclusive`(fail-open). 독립 채널은 이 감사 하나다.
