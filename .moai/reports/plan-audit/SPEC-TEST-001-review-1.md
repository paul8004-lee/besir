# SPEC 검토 보고서: SPEC-TEST-001
Iteration: 1/3
Verdict: PASS
Overall Score: 0.76

> 작성자 추론 맥락은 무시했다(M1 Context Isolation). 호출자가 준 환경 사실(워크트리 경로, 베이스 `2a37673`, 규칙·스킬 파일 위치, 금지 사항)은 경로 해석과 금지 범위를 정하는 데만 썼다.
> 입력: Tier S — `spec.md`(219줄) · `plan.md`(127줄) · `progress.md`(87줄, 증거 기록). `acceptance.md`·`design.md`·`research.md` 없음(Tier S라 정상).
> 트리: `git rev-parse --short HEAD` → `2a37673`, `git branch --show-current` → `WT-driver-hardening`, `git status --short` → `?? .moai/specs/SPEC-TEST-001/`뿐. `git rev-parse --short origin/master` → `2a37673`.
> 교차 모델: 주 체크아웃 `workflow.yaml:77-82`의 `audit.model: multi`(claude required · codex off · glm advisory). `mcp__moai__audit_multi` → overall `needs-attention`, GLM `inconclusive`(z.ai 응답 본문 없음, fail-open). 판정은 claude 단독이다.
> 금지 준수: 가드 드라이버·CLAUDE.md 레시피·`.moai/state/verify/t8/`의 탐침 바이너리는 컴파일도 실행도 하지 않았다(탐침은 `.swift` 소스만 읽었다). `~/Library/Application Support/besir/`와 키체인은 건드리지 않았다. 사고 백업 `/tmp/besir-incident-20260923/`도 운영자 데이터 사본이라 열지 않았다. 쓴 파일은 이 보고서 하나다.

**PASS의 근거와 조건.** must-pass 일곱이 모두 PASS다(MP-4는 N/A). 점수 0.76은 Tier S 통과선 0.75를 **겨우** 넘는다. 판정은 M6에 따라 must-pass와 점수에 묶인다. 그러나 blocking 부류의 should-fix가 아홉 건(D1~D9)이다. 넷은 인용·문언 정정이고, 다섯은 설계와 AC의 빈틈이다(시간 제한 경로와 정상 종료의 배타성, 오프-메인 타이머를 가리지 못하는 AC, 샌드박스 삭제 대상 확인의 AC 부재, 비샌드박스 맥 앱과의 공유 디렉터리). **이 PASS는 착수 승인 게이트를 통과했다는 뜻이 아니다.** 결정 넷(D-1~D-4)과 Tier가 열려 있고, 게이트 뒤 manager-spec 개정 때 D1~D9를 같이 반영해야 한다. 개정 뒤에는 그 델타에 한정한 2회차 감사를 권한다. (b)안이 하나라도 채택되면 REQ가 다시 쓰이므로 2회차는 필수다.

## Must-Pass Results

| # | 결과 | 근거 |
|---|---|---|
| MP-1 REQ 번호 | PASS | `grep -n '^- \*\*REQ-' spec.md` → REQ-001(:95)·002(:97)·003(:101)·004(:103)·005(:107)·006(:111)·007(:113)·008(:117). 빈 번호·중복 없음, 세 자리 zero-padding 일관 |
| MP-2 GEARS | PASS | *판정 층위: 요구사항 층(`spec.md` §2, :95-117)만.* §3.1의 Given-When-Then AC는 검증 층의 올바른 형식이라 여기서 채점하지 않았다. Event-driven 3건(REQ-001 "When the driver starts, it shall…", REQ-002 "When the driver starts and again when it ends…", REQ-005 "When the driver has run longer than its deadline…"), State-driven 1건(REQ-003 "While the driver runs, … shall be empty"), Ubiquitous 3건(REQ-004·006·007), Unwanted 1건(REQ-008 "The change shall not modify…"). 요구사항 안에 구현 모양과 줄 번호가 섞인 점은 optional로 적었다(D17) |
| MP-3 frontmatter | PASS | `spec.md:2-13`에 12개 필드가 다 있다. id `SPEC-TEST-001`(정규식 통과), title 따옴표 문자열, version `"0.1.0"`, status `draft`, created·updated `"2026-09-24"`, author, priority `P1`, phase `"Phase 1.7 — Day 닫기 전 드라이버 경화"`(금지값 `plan`/`run`/`sync`/`mx` 아님), module `"Tools/GuardDriver.swift"`, lifecycle `spec-anchored`, tags 쉼표 문자열. 거부 별칭 0건. `moai spec lint .moai/specs/SPEC-TEST-001/spec.md` → `✓ No findings — all SPEC documents are valid`. `related_specs`·`kanban_card`는 형제 SPEC-UIKIT-006·007과 같은 관례다 |
| MP-4 언어 중립성 | N/A | 단일 언어(Swift) 호스트 도구 하나를 고치는 SPEC이다 |
| MP-5 D7 | PASS | 본문 참조 SPEC-UIKIT-006(`completed`)·SPEC-ONTIME-001(`draft`)·SPEC-FULL-001(`in-progress`). retired/superseded/archived 0건, 미발견 0건. BLOCKING 없음 |
| MP-6 D8 | PASS | `grep -c 'syscall'` → spec.md 0 · plan.md 0. D8-4에 따라 자동 통과 |
| MP-7 명확화 게이트 | PASS | `grep -rn '\[NEEDS CLARIFICATION' plan.md spec.md` → 0건(exit 1). `research.md` 없음. 열린 결정은 산문으로만 적혀 있다 — 아래 "게이트 표식"과 D16 |

## Category Scores (0.0-1.0, rubric-anchored)

| Dimension | Score | Rubric Band | Evidence |
|---|---|---|---|
| Clarity | 0.75 | 0.75 | 요구사항 대부분이 단일 해석이다(REQ-003 :101은 필드·자리·효과를 특정, REQ-006 :111은 적을 내용을 열거). 감점: REQ-001 :95의 "on every exit path"가 달성 불가(D4), REQ-002·005 :97·:107이 두 종료 경로의 배타성을 정하지 않음(D5), REQ-008 :117의 git 밖 조항이 AC-006·008과 충돌(D3) |
| Completeness | 0.90 | 1.0 대역 하단 | HISTORY :21-25, 배경(WHY) :37-87, 범위·예산(WHAT) :27-35, 요구사항 :89-117, 인라인 AC :123-155, `### Out of Scope —` H3 넷과 `-` 항목(:157-172), 잔여 위험 :174-176, 결정 :178-210, HOW는 `plan.md` §1·§5. frontmatter 12/12. 감점: 실행 전제에 맥 앱 미실행 조건이 없음(D8), 잔여 위험이 설정 파일만 다룸(D10) |
| Testability | 0.65 | 0.50~0.75 사이 | AC-001·006·007은 명령과 기대값이 기계적이다. 감점: AC-003 (3)의 세는 명령이 정해지지 않았고 어떤 자연스러운 grep도 "3"을 내지 않음(D7), AC-004가 REQ-005의 핵심 성질(오프-메인 타이머)을 가리지 못하고 (4)가 경합에 따라 흔들릴 수 있음(D5·D6), AC-002 (3)의 grep이 실제 경로 변수를 못 찾음(D13), AC-005 (1)의 "근처·안팎"(D14), AC-008 (4)의 "회귀로 판정되면" |
| Traceability | 0.80 | 0.75~1.0 사이 | REQ 8건 전부 AC ≥1, AC 8건 전부 실재 REQ를 가리킴(헤더 :125-153). 감점: REQ-001의 "지우기 전 대상 확인"(D9)·REQ-005의 "메인 액터 밖"(D6)·REQ-008의 git 밖 조항(D3)에 AC가 없다. `plan.md:18` 매핑이 REQ-002→AC-008을 빠뜨림(D11) |

집계: 조화평균 4 / (1/0.75 + 1/0.90 + 1/0.65 + 1/0.80) = 4 / 5.2329 = **0.76**. Tier S 통과선(`spec-workflow.md:140`) 0.75 이상.

## 설계 주장 판정 (요청 항목 4)

- **(a) 프로세스 안 `CFFIXED_USER_HOME` 재지정.** 탐침 두 개의 소스를 읽었다(`.moai/state/verify/t8/probe_home.swift`·`probe_pin.swift`, 실행 안 함). 둘 다 `-parse-as-library`가 아닌 최상위 스크립트이고, `FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)`·`NSHomeDirectory()`·`NSTemporaryDirectory()`만 찍는다. 드라이버는 `@main` + `@MainActor static func main() async`(`GuardDriver.swift:165-168`)라 실행 맥락이 다르다. 그래도 **SPEC은 요구사항 층에서 과장하지 않는다.** REQ-001이 `Store` 생성 전에 `AppConfig.supportDirectory`가 샌드박스 안인지 확인하고 아니면 exit 2로 멈추므로(fail-closed), 탐침이 일반화되지 않아도 실제 디렉터리에 쓰기 전에 멈춘다. "고정되는 것은 `static let` 하나"(:76)는 언어 사실이고 `Config.swift:65-68`과 맞는다. 앱 데이터 파일 일곱이 모두 `AppConfig.supportDirectory`에서 나온다는 것도 확인했다. 컴파일 집합의 다른 파일 쓰기는 `SharedInbox`(앱 그룹 컨테이너)뿐인데 호출부가 `App.swift:125`(컴파일 집합 밖) 하나다. `UserDefaults` 사용 0건, `NotificationManager`는 번들 식별자가 없으면 센터를 건드리지 않는다(`NotificationManager.swift:12`). progress.md Gaps(:51-52)도 탐침의 한계를 적었다. **과장은 두 자리다** — REQ-001의 "every exit path"(D4)와 D-1 (a)의 "끊겨도 실제 데이터는 무사하다"(:184). 후자는 지원 디렉터리에 한해서만 참이다(네트워크 O-1·키체인 O-3은 격리 대상이 아니다).
- **(b) 클라이언트 ID 비우기와 키체인.** 코드 읽기로 확인했다. 게이트 갈래 7자리(`Store.swift:764`·`:805`·`:867`·`:902`·`:963`·`:1308`·`:1315`)가 모두 `hasGoogleCalendar`(`Config.swift:28`)를 거친다. `googleConnected`(`:481`)는 단락 평가다. `gcal.fetchBesirItems`·`deleteEvent`·`clearReminders`·`createEvent`(`:1343`·`:1352`·`:1430`·`:1438`)는 `syncWithGoogle`과 그 하위 `reconcileActivities`(호출부 `:1378` 하나) 안이다. 키체인 쓰기(`Keychain.set`/`delete`/`upgradeAccessibility`)는 토큰 교환(`GoogleCalendarService.swift:302`)·`SettingsView.swift:33`·`App.swift:67`에서만 불리므로 드라이버 컴파일 집합에서 닿지 않는다. 게이트 밖 갈래가 `googleEventId` 레코드를 전제한다는 결론은 맞다. 다만 호출부 수가 다섯이 아니라 여섯이다(D2). AIAssistant 안의 `update_schedule` → `modifyActivity` → `updateActivity`(게이트 밖) 경로는 SPEC의 grep이 덮지 않는다. 드라이버가 부르는 툴 이름을 전수로 세어 보니 결론은 유지된다(D12).
- **(c) 종료 코드 우선순위.** REQ-002(:97) "3 > 124 > 1 > 0"과 REQ-005(:107) "124 (or 3)"는 서로 모순되지 않는다. 그러나 종료 경로가 둘(메인 액터의 정상 종료, 오프-메인 타이머)인데 한쪽만 돌게 하는 장치가 없고, 2가 우선순위에 없다(D5).
- **(d) 타이머 스레드와 `@MainActor` main.** `AppConfig`는 격리 없는 struct(`Config.swift:10`)라 타이머에서 경로를 읽어도 되고, `Store`는 `@MainActor`(`Store.swift:8`)라 타이머가 만지면 안 된다 — plan.md:66이 이를 적었다. 문제는 검증이다. AC-004의 3초 실행은 메인 액터가 네트워크 대기로 비어 있을 때 메인 액터 타이머(`Task.sleep`)도 제시간에 끝나므로 잘못된 구현을 통과시킨다(D6). 주 스레드가 동기 호출에 묶인 채 다른 스레드가 `exit`하는 가지는 관측되지 않는다고 plan.md:64-65가 정직하게 적었다.

## 범위 규율 (요청 항목 5)

`moai todo`로 카드 t8 원문을 직접 읽었다. 할 일 넷은 (1) "드라이버 시작·종료에 백업·복원·cmp 대조 강제 — SPEC-UIKIT-006 REQ-030 절차의 코드화" (2) "키체인 접근 격리" (3) "R4 … sleep 감시자는 wait 뒤 회수(900초 연장이 아님 …)" (4) "R5 — 하네스 스킬 … updateMeal 데드코드 후보 항목 정리"다. SPEC은 이 넷 안에 머문다. 카드 문구와 다른 두 권고 — D-1 (a)가 "백업·복원"을 격리 + 대조로 바꾸고, D-2 (a)가 감시자 회수를 내부 시간 제한으로 바꾸는 것 — 는 조용히 채택되지 않았다. 둘 다 착수 승인 게이트의 결정(spec §4 D-1·D-2, plan §2 항목 1·2)으로 올라가 있고, 카드 문구 그대로의 안이 (b)로 남아 있다. progress.md §E.1 "카드 본문과 실측이 어긋난 자리"(:42-46)에도 명시돼 있다. D-2 (a)여도 REQ-006이 "그래도 감시자를 두면 `wait` 직후 거둔다"를 문서에 남겨 카드 (3)의 문자를 지킨다. 네트워크(O-1)·백업 7곳 정리(O-2)·끝난 SPEC 절차(O-4)를 카드 밖으로 뺀 것도 맞다. 카드의 "첫 백업이 J절(:1127)에만"을 `events.json` 기준으로 맞고 파일 전체로는 Q `:633`이 먼저라고 바로잡은 것도 트리와 맞는다. 흠은 하나다. 카드 원문이 SPEC 어디에도 인용돼 있지 않다(HISTORY :25는 "할 일 넷"이라고만 적는다). 카드가 닫힌 뒤에는 범위 대조의 근거가 사라진다(D19).

## 게이트 표식 (요청 항목 7 — 결함과 구분)

다음은 **의도된 열린 결정**이고 결함으로 세지 않았다: D-1 실제 데이터 보호 방식(spec :182-187), D-2 시간 제한과 R4(:189-193), D-3 키체인 격리 방식(:195-200), D-4 `CLAUDE.md` 편집 승인(:202-206), Tier S 확정(:208-210). plan.md §2(:41-53)와 progress.md `kickoff_gate: pending`(:8)이 같은 목록을 가리킨다. 권고 근거는 안 설명과 분리돼 있고, (b)를 골랐을 때 다시 써야 할 REQ도 적혀 있다(:187·:200). 이 표식은 `[NEEDS CLARIFICATION]` 토큰이 아니라 MP-7의 기계 검사에 잡히지 않는다(D16).

## Defects Found (structured defect-list)

D1. first-write-citation — spec.md:L51(§1.2), progress.md:L23·L43 — "첫 쓰기는 G절 `:278`의 `drvUpdate`다"와 "첫 쓰기(G `:278`)를 포함해"가 틀렸다. `:278`은 `series_number: 99`로 부르는데, 그 번호가 없으면 `updateRecurringSeries`(`AIAssistant.swift:1834`) 전에 돌아간다. 드라이버 자신도 바로 뒤 `:281`에서 "아무것도 쓰지 않는다"를 단언한다. `:282`(`-1`)도 같은 가지다. 디스크에 닿는 첫 `drvUpdate`는 H절 `:293`이다(`:292` `drvSetLast(ridY)` → 번호 0 → `lastRecurrenceId` → `updateRecurringSeries` → `save()` `Store.swift:759`). §1.2가 "(실측)"이라고 표기했지만 이 문장은 경로 추적이다. — 증거: `sed -n '274,284p' Tools/GuardDriver.swift` → `:278 let g1 = await aiG.drvUpdate(["series_number": 99, "mode": "car"])` · `:281 aiG.drvCheck("아무것도 쓰지 않는다", …)`. `sed -n '1803,1811p' Shared/AIAssistant.swift` → `guard let rid = seriesNumbers.first(where: { $0.value == seriesNumber })?.key else { return "그 번호의 반복 그룹을 찾지 못했어요…" }`. (감사자 쪽도 코드 읽기다 — 드라이버 실행은 금지됐다.) — Severity: should-fix — Class: blocking — Required fix: 세 자리를 "첫 쓰기는 H절 `:293`의 `drvUpdate`다(G `:278`은 첫 호출이지만 번호가 없어 쓰지 않는다 — `:281`의 단언)"로 고치고, "(실측)" 절 안의 경로 추적 문장에는 "(코드 읽기)"를 붙인다.

D2. ungated-caller-count — spec.md:L58(§1.3) — "게이트 밖 호출부는 다섯이다"는 여섯이어야 한다. `updateActivity`의 `:272` `removeFromCalendar([gid])`가 빠졌다. 같은 문단이 `:272-273`을 gid 조건 목록에 인용하면서 수에서는 뺐다. 결론(모두 gid 레코드 전제 — `:270` `if let gid = old.googleEventId`)은 그대로다. — 증거: `grep -n 'removeFromCalendar(' Shared/Store.swift` → `97`(정의)·`272`·`370`·`706`·`773`·`965`·`1258`·`1276`·`1289`·`1425`. 게이트 안 `773`·`965`·`1425`를 빼면 여섯. — Severity: should-fix — Class: blocking — Required fix: "게이트 밖 호출부는 여섯이다 — `updateActivity` `:272` · `deleteActivity` `:370` · …"로 고치고 (ii)는 `:273` `createEvent`만 남긴다.

D3. req008-outside-git-contradiction — spec.md:L117(REQ-008) 대 L147(AC-006)·L155(AC-008) — REQ-008은 git 밖에서 "only the hazards skill file (REQ-007) and the driver's own sandbox"만 건드린다고 한다. 그런데 AC-008은 `CLAUDE.md` 레시피로 `/tmp`에 소스를 합치고 고유 이름의 바이너리를 컴파일하게 하고(`CLAUDE.md:59-60`의 `> /tmp/gd.swift`·`-o /tmp/gd`), AC-006은 스킬 파일 사본을 세션 scratch나 워크트리의 git 무시 경로에 두게 한다. 문언대로면 REQ-008이 자기 AC를 금지한다. git 밖 조항에는 AC도 없다(AC-007은 git 경로만 본다). 선행 SPEC-UIKIT-006 REQ-021은 같은 자리에 "선언된 예외 셋"(scratch 포함, 그 spec.md:162)을 두었다. — 증거: `sed -n '59,60p' CLAUDE.md` → `cat … > /tmp/gd.swift \` · `&& swiftc -o /tmp/gd …`. — Severity: should-fix — Class: blocking — Required fix: REQ-008의 git 밖 목록에 예외를 적는다. (1) 드라이버 컴파일 산출물(`/tmp` 또는 세션 scratch, 실행마다 고유 이름) (2) 스킬 파일의 편집 전 사본(AC-006) (3) git 무시 증거 경로(`.moai/state/verify/t8/`). 실제 지원 디렉터리 무변경은 AC-002가 잰다는 한 줄을 곁들인다.

D4. req001-every-exit-path — spec.md:L95(REQ-001), L184(D-1 (a)) — "shall remove that directory on every exit path"는 달성할 수 없다. `SIGKILL`, 트랩(범위 밖 첨자 등), 핸들러가 요구되지 않은 `SIGINT`·`SIGTERM`, 그리고 D5의 시간 제한 경합에서는 지울 수 없다. D-1 (a)의 "시간 제한·`SIGKILL`·크래시로 끊겨도 실제 데이터는 무사하다"는 지원 디렉터리에 한해 참이지만, 삭제 보장과 같은 문단에 있어 읽는 사람이 둘을 섞는다. — 증거: `grep -n 'exit(' Tools/GuardDriver.swift` → `1620: exit(drvFail == 0 ? 0 : 1)` 하나. 신호 처리 요구는 REQ 어디에도 없다(`grep -n 'SIGTERM\|SIGINT' spec.md` → D-1 (b) 설명 :185 한 줄뿐). — Severity: should-fix — Class: blocking — Required fix: REQ-001을 "on every exit path the driver itself takes (normal completion, assertion failure, exit 2, deadline)"로 좁히고, 통제 밖 종료는 `NSTemporaryDirectory()` 아래 샌드박스를 남길 수 있다고 적는다. 필요하면 다음 시작 때 고유 접두어 + 죽은 PID인 샌드박스를 같은 대상 확인을 거쳐 지운다는 절을 더한다. D-1 (a) 문장은 "실제 지원 디렉터리는"으로 주어를 좁힌다.

D5. single-exit-guard-and-removal-race — spec.md:L97(REQ-002)·L107(REQ-005), AC-004 (4) L139 — 종료 경로 둘(메인 액터의 정상 종료와 오프-메인 타이머)이 각자 대조 → 샌드박스 삭제 → `exit`를 하는데 한쪽만 돌게 하는 장치가 없다. 기한이 정상 종료와 겹치면 두 스레드가 동시에 `exit`를 부른다(C 표준상 정의되지 않은 동작). 우선순위 문장도 종료가 한 번뿐이라고 전제한다. 타이머가 샌드박스를 지우는 동안 주 스레드는 계속 돈다. 그 사이 `Store.save()` 계열이 `createDirectory(…, withIntermediateDirectories: true)`로 트리를 다시 만들거나 `removeItem` 도중 새 파일을 써서 실패시킬 수 있다(`try?`로 묻힌다). 그러면 AC-004 (4) "샌드박스가 남지 않았다"가 실행마다 달라질 수 있다. exit 2는 우선순위 목록에 없다(첫 읽기 전에 나므로 대조가 없다는 것도 적혀 있지 않다). plan.md:31 M2는 타이머를 머리말 맨 끝에 세워, `Store.init`과 머리말 구간은 기한 밖에 둔다. — 증거: `grep -n 'createDirectory' Shared/Store.swift Shared/AIAssistant.swift | wc -l` → 6. `grep -n 'createDirectory' Shared/Store.swift` 중 `1456: try? FileManager.default.createDirectory(at: AppConfig.supportDirectory, withIntermediateDirectories: true)`(`save()`). — Severity: should-fix — Class: blocking — Required fix: REQ-005에 "대조·샌드박스 삭제·종료는 한 경로만 수행한다 — 먼저 선점한 쪽(잠금이나 원자 플래그)"을 넣는다. 우선순위 문장에 "2는 첫 읽기 전에 난다(대조 없음)"를 더한다. 시간 제한 경로의 삭제는 최선 노력으로 두고 남은 샌드박스를 D4의 방식으로 회수하거나, AC-004 (4)를 "남지 않았다, 또는 남은 경로를 출력했다"로 고친다. 타이머는 실제 디렉터리 첫 읽기 직후, `Store(...)` 앞에 세우도록 M2 순서를 고친다(optional).

D6. ac004-offmain-not-discriminated — spec.md:L139(AC-004), L107(REQ-005), plan.md:L64-66 — REQ-005의 핵심은 "a timer that does not run on the main actor"인데 어느 AC도 이를 재지 않는다. AC-004의 3초 실행에서는 드라이버가 대부분 `await`(이동시간 조회 등)로 메인 액터를 비우므로, 메인 액터에 붙은 `Task { try await Task.sleep(…) }` 타이머도 제시간에 124로 끝난다. 잘못된 구현이 모든 AC를 통과하고, REQ-005가 막으려던 형태(주 스레드가 동기 호출에 묶임)는 plan.md:64-65 스스로 관측하지 않는다고 적었다. — 증거: `sed -n '165,168p' Tools/GuardDriver.swift` → `@main` / `struct Drv {` / `@MainActor` / `static func main() async {`(`@MainActor` 안에서 만든 `Task {}`는 그 격리를 물려받는다). — Severity: should-fix — Class: blocking — Required fix: AC-004에 (6)을 더한다 — "코드 읽기: 타이머가 메인이 아닌 큐나 스레드에서 만들어지고(예: `DispatchSource.makeTimerSource(queue: .global())` 또는 `Thread`), 처리기가 `@MainActor` 격리가 아니며 `store`·`drvPass`를 만지지 않는다. 해당 줄을 §E.2에 코드 읽기로 적는다."

D7. ac003-count-command — spec.md:L135(AC-003 (1)·(3)), plan.md:L111 — (3) "불변식 함수의 호출부를 `grep -c`로 세고 … 호출부가 3곳"은 패턴이 없다. 자연스러운 두 패턴 모두 3을 내지 않는다. `awk 'NR==1262 || NR==1337'`는 M2가 머리말에 수십 줄을 더하는 순간 확실히 어긋나므로 처음부터 대체 명령만 의미가 있다. — 증거: `grep -c 'drvAssertNoCalendarPush' Tools/GuardDriver.swift` → 4(정의 `:184`·`:1342`·주석 `:1616`·`:1617`). `grep -c 'drvAssertNoCalendarPush(' Tools/GuardDriver.swift` → 3(정의 + 호출 둘, 변경 뒤에는 4). `grep -n 'drvAssertNoCalendarPush(' Tools/GuardDriver.swift | grep -v 'func '` → `1342`·`1617`(변경 뒤 기대 3줄). — Severity: should-fix — Class: blocking — Required fix: (3)의 명령을 `grep -n 'drvAssertNoCalendarPush(' Tools/GuardDriver.swift | grep -v 'func '` → **정확히 3줄**로 적는다. (2)의 `awk`는 `grep -n 'calSavedClientID' Tools/GuardDriver.swift` → 2줄, 문장이 `let calSavedClientID = store.config.googleClientID`·`store.config.googleClientID = calSavedClientID`와 바이트가 같음으로 바꾼다.

D8. unsandboxed-mac-app-shares-real-dir — spec.md:L97(REQ-002)·L131(AC-002), plan.md:L30·L32(M1·M3) — besir 맥 앱은 앱 샌드박스가 꺼져 있고 같은 `AppConfig.supportDirectory`를 쓴다. 즉 대조가 지키는 실제 디렉터리가 맥 앱의 데이터 디렉터리 그 자체다. 드라이버가 도는 동안 맥 앱이 떠 있으면(동기화 등으로 `events.json`을 쓴다) 드라이버 잘못 없이 exit 3이 나고 AC-002 (1)이 FAIL한다. SPEC 스스로 이 쓰기 주체를 언급하면서(:97 "그 사이 맥 앱이 정당하게 쓴 내용") 실행 전제를 두지 않았다. 안전 방향(멈춤)의 오탐이지만 "실제 디렉터리가 바뀌었다"는 판정이 사고로 오독된다. — 증거: `sed -n '104,108p' project.yml` → `path: Generated/besir-macOS.entitlements` · `com.apple.security.app-sandbox: false`. `sed -n '65,68p' Shared/Config.swift` → `static let supportDirectory` = `applicationSupportDirectory` + `besir`. — Severity: should-fix — Class: blocking — Required fix: M1·M3에 전제 "두 실행 동안 besir 맥 앱이 떠 있지 않다(프로세스 확인 명령과 출력을 §E.2에 적는다 — 프로세스 이름은 run이 확인)"를 넣는다. REQ-002의 출력 문구를 "실제 디렉터리가 바뀌었다 — 드라이버나 다른 쓰기 주체"로 하고, AC-002에 "3이 나면 다른 쓰기 주체부터 확인한 뒤 판정한다"를 더한다.

D9. req001-removal-guard-no-ac — spec.md:L95(REQ-001) 대 L127(AC-001), plan.md:L62-63 — REQ-001의 "after checking that the path is the one it created"는 파괴적 조작의 안전 조건인데 AC가 없다. AC-001 (3)은 샌드박스가 없어졌는지만 보므로 확인 없이 지우는 구현도 통과한다. plan.md는 이것을 렌즈 몫으로만 넘긴다. — 증거: `sed -n '127p' spec.md`의 (1)~(3)에 삭제 대상 확인 항목 없음. — Severity: should-fix — Class: blocking — Required fix: AC-001에 (4)를 더한다 — "코드 읽기: 삭제 직전에 이번 실행이 만든 경로(`NSTemporaryDirectory()` 아래 고유 이름)와 같은지 비교하는 분기가 있고, 실제 홈이나 실제 지원 디렉터리를 대상으로 하는 삭제 가지가 없다. 해당 줄을 §E.2에 적는다."

D10. residual-risk-seed-scope — spec.md:L174-176, L155(AC-008 (4)), plan.md:L67-68 — 잔여 위험이 `config.json` 대 `bundledDefaults`만 다룬다. 샌드박스는 `events`·`favorites`·`activities`·`meals`가 빈 채로, `ai_history.json`도 없이 시작한다. `AIAssistant.init`은 `loadHistory()`(`AIAssistant.swift:116`)로 `lastRecurrenceId`까지 되살리는데, 기준선 205는 그날의 실제 파일을 씨앗으로 잰 값이다. AC-008 (4)가 차이를 잡으므로 위험은 덮이지만 설명이 좁다. — 증거: `sed -n '113,123p' Shared/AIAssistant.swift` → `loadHistory()`. — Severity: optional — Class: optional — Required fix: 잔여 위험과 AC-008 (4)의 문구를 "설정과 씨앗 데이터(일정·즐겨찾기·활동·식사·대화 기록)"로 넓힌다.

D11. plan-mapping-omission — plan.md:L18 — 매핑 "002→002·004"가 AC-008을 빠뜨렸다. AC-008 헤더(spec :153)는 "REQ-001~005"이고, exit 0이 곧 REQ-002 대조 통과다. — Severity: optional — Class: optional — Required fix: "002→002·004·008".

D12. keychain-grep-scope — spec.md:L59, progress.md:L26 — "드라이버는 그 삭제·수정 경로를 부르지 않는다"의 근거 grep(`store\.delete\|store\.updateActivity\|delete_schedule\|delete_recurring`)이 `update_schedule`을 덮지 않는다. AIAssistant는 `update_schedule` → `store.modifyActivity`(`AIAssistant.swift:2220`) → `updateActivity`(`Store.swift:310`, 게이트 밖)로 간다. 감사자가 드라이버의 툴 이름을 전수로 세니 결론은 유지된다. — 증거: `grep -o 'drvExecuteTool("[a-z_]*"\|drvAsk("[a-z_]*"' Tools/GuardDriver.swift | sort | uniq -c` → `create_activity` 6+4 · `create_recurring_schedule` 3 · `create_schedule` 32+3, `grep -c 'update_schedule\|delete_schedule' Tools/GuardDriver.swift` → 0. — Severity: optional — Class: optional — Required fix: grep에 `update_schedule\|modifyActivity\|modifyEvent`를 더하고 결과를 다시 적는다.

D13. ac002-grep-misses-real-path — spec.md:L131(AC-002 (3)) — `grep -n 'supportDirectory'`로는 실제 디렉터리 쓰기를 찾을 수 없다. REQ-002의 참고 모양은 실제 경로를 `NSHomeDirectory()` + 상대 경로로 만든 변수에 담으므로, 그 변수로 쓰는 줄은 이 grep에 걸리지 않는다. — Severity: optional — Class: optional — Required fix: "실제 경로를 담은 변수 이름을 grep해 읽기 API(`contentsOfDirectory`·`Data(contentsOf:)`)에만 쓰인다"를 더한다.

D14. ac005-vague-locus — spec.md:L143(AC-005 (1)) — "드라이버 블록 근처(`:58-66` 안팎)"는 판정자가 해석해야 한다. — Severity: optional — Class: optional — Required fix: "모든 헝크의 새 줄 번호가 `## 빌드 · 배포`(`:45`)와 다음 `## ` 머리 사이"로 바꾼다.

D15. ac006-partial-coverage — spec.md:L147(AC-006 (2)) 대 L113(REQ-007) — REQ-007은 이유(SPEC-FULL-001 REQ-003)·결정(SPEC-UIKIT-006 D-2 (a))·`Shared/Store.swift:408`의 주석 셋을 요구한다. AC-006 (2)는 `SPEC-FULL-001`·`REQ-003`·`SPEC-UIKIT-006`만 본다. 새 문단을 `:229`와 `:236` 사이에 두면 (1)의 "사이의 목록에 없다"가 목록과 문단을 가르는 판단을 요구한다. — 증거: `grep -n 'Dead code candidates\|was removed from this list' /Users/iseongmin/Projects/besir/.claude/skills/hns-besir-app-hazards/SKILL.md` → `229:`·`236:`(패턴은 macOS grep에서 그대로 돈다). — Severity: optional — Class: optional — Required fix: (2)에 `Store.swift:408`과 `D-2`를 더하고, 새 문단 위치를 "`:244-246` 유지 문단 곁"으로 정한다.

D16. gate-markers-in-prose — plan.md:L41-53, spec.md:L178-210 — 열린 결정 다섯이 `[NEEDS CLARIFICATION: …]` 토큰이 아니라 산문으로만 적혀 있다. `moai-workflow-spec` SKILL.md:173은 착수 전에 풀어야 할 질문을 이 토큰으로 표시하라고 한다. 그래서 MP-7이 기계적으로 통과하고, 이 PASS를 착수 가능 신호로 오독할 여지가 생긴다. 사람 게이트(`kickoff_gate: pending`)가 따로 있으므로 안전 문제는 아니다. — Severity: optional — Class: optional — Required fix: 리드의 선택이다. 토큰을 넣으면 다음 회차 MP-7이 의도된 게이트 신호로 FAIL한다(SPEC-UIKIT-007의 선례).

D17. line-anchors-in-requirements — spec.md:L101(REQ-003 `:173`)·L103(REQ-004 `:1342`·`:1617`)·L95(REQ-001 "수리 모양") — 요구사항 문장에 줄 번호와 구현 모양이 들어 있다. M2가 머리말에 줄을 더하는 순간 `:1342`·`:1617`은 어긋난다. — Severity: optional — Class: optional — Required fix: "N절 끝의 기존 불변식 호출 자리", "마지막 집계 출력 직전"처럼 이름으로 고정하고, 줄 번호는 `<base>` 기준 괄호로 돌린다.

D18. exit1-collision — spec.md:L111(REQ-006) — `cat … && swiftc … && <바이너리>` 사슬에서는 컴파일이 실패해도 0이 아닌 코드(보통 1)가 나와 "단언 실패 1"과 겹친다. — Severity: optional — Class: optional — Required fix: REQ-006이 적을 종료 코드 설명에 "1은 마지막 `P/T 통과` 줄이 있을 때만 단언 실패다"를 더한다.

D19. card-text-not-quoted — spec.md:L25(HISTORY), progress.md:L3·L42-46 — 카드 t8 원문이 인용돼 있지 않다("할 일 넷"이라고만 적음). 카드가 닫히면 범위 대조의 근거가 큐에서 사라진다. — 증거: `moai todo` → `t8 picked 드라이버 구조적 경화 — … 할 일: (1) … (2) … (3) … (4) …`. — Severity: optional — Class: optional — Required fix: progress.md §E.1에 할 일 넷을 원문 그대로 인용한다.

## Regression Check

1회차라 해당 없음.

## Recommendation

1. **리드**: 착수 승인 게이트에서 D-1~D-4와 Tier를 정한다. 이 PASS는 그 게이트를 대신하지 않는다.
2. **manager-spec(게이트 뒤 개정 때 함께)**: blocking D1~D9를 반영한다. 문언 정정은 D1(첫 쓰기 H `:293`)·D2(여섯)·D3(REQ-008 예외)·D4(통제된 종료 경로로 좁힘)이다. 설계와 AC 보강은 D5(단일 종료 경로·2의 자리·삭제 경합)·D6(AC-004 코드 읽기 항목)·D7(세는 명령 확정)·D8(맥 앱 미실행 전제)·D9(삭제 대상 확인 AC)이다. D5·D6·D9는 AC에 코드 읽기 항목을 더하는 일이라 AC 수(8)는 늘지 않는다.
3. optional D10~D19는 개정 범위 안에서 싸게 고칠 수 있는 것만 고른다.
4. 개정 뒤 이 결함 목록에 한정한 2회차 감사를 받는다. D-1 (b)나 D-3 (b)가 채택되면 REQ-001·002 또는 003·004·008이 다시 쓰이므로 2회차는 필수다.

## 감사자가 직접 확인한 것과 SPEC에서 가져온 것

**직접 확인(이 트리 `2a37673`, 명령과 출력 관측)**
- 규칙·예산: `spec-workflow.md:140`(Tier S 행)·`:148`(8/8) · `grep -c '^- \*\*REQ-'` = 8 · `grep -c '^#### AC-'` = 8 · `moai spec lint` 무결함 · D7/D8/MP-7 동사.
- 드라이버: `wc -l` = 1622 · `:167-169`·`:173`·`:184`·`:1342`·`:1617` · 절 머리 `grep -c` = 29와 J·N·P 중복 줄 · 백업 10줄 7곳과 범위 전부(`:150-161`·`:651`·`:632-636`·`:1126-1157`·`:1165-1239`·`:1249-1341`·`:1355-1482`·`:1490-1611`) · `drvCheck(` 201 · 생성 호출 14 − 정의 2 = 12(`grep -o`로도 14) · `CFFIXED_USER_HOME` 0 · `googleClientID = ""` 1(`:1263`) · `:1262`·`:1264`·`:1337` · V `:972`·W `:1038`·첫 생성 O `:428` · gid `:1282`·`:1312`·`:1318`·`:1332` · 머리말 레시피 `:4-9`.
- 앱 소스: 데이터 파일 일곱과 `Config.swift:65-68`·`:70`·`:28`·`:78`·`:80`·`:83-89` · `Store.swift:117`·`:119`·`:481`, 게이트 7자리, `:97`·`:101`·`:264`·`:273`·`:1257`·`:408`·`:559`·`:587`·`:980` · `GoogleCalendarService.swift:37`·`:49`·`:131`·`:253`·`:400`·`:406`, 키체인 쓰기 호출부 · `AIAssistant.swift:122`·`:128` · `DirectionsService.swift:27`·`:30` · `project.yml:107`.
- 문서·git: `CLAUDE.md:23`·`:45`·`:58`·`:59-64`(12파일) · `git grep -n '/tmp/gd' -- ':!.moai/specs'` 6줄 · `git diff --quiet b8bbe1c 2a37673 -- <12파일>` exit 0 · `git log --oneline -1 -- Tools/GuardDriver.swift` → `f9cd9bb` · `git ls-files .claude | wc -l` = 0 · `.gitignore:28` · 스킬 파일 249줄·`:229`·`:233`·`:236`·`:244-246` · SPEC-UIKIT-006 §E.2(`progress.md:242`)의 205/205와 spec §0(`:39`)의 멈춤 추적 문구 · SPEC-FULL-001 REQ-003(`spec.md:60`) · `which timeout gtimeout` → 둘 다 not found · `sw_vers` → 26.6.2 · `test -e /tmp/besir-probe-pin`·`/tmp/besir-probe-cf` → 없음 · 433초 산술(16:33:06→16:40:19).
- 결과: SPEC이 든 인용 가운데 어긋난 것은 D1(첫 쓰기)·D2(호출부 수) 둘이다. 나머지는 전부 맞았다.

**SPEC에서 가져온 것(감사자가 재지 않음)**
- 탐침 실행 결과(§1.4 표) — 탐침 바이너리 실행이 금지돼 소스만 읽었다.
- 사고 백업의 제목(`V-출발`·`W-하룻밤`) — 운영자 데이터 사본이라 열지 않았다.
- 기준선 205/205 자체, 2026-09-23 멈춤의 `sample` 관측, t5 sync 레인의 시각(16:33:06·16:40:19·16:43:06), 워크트리 가드의 `HOME=`·`perl` 거부 — 모두 다른 레인의 관측이며 드라이버 실행이 금지돼 재현하지 않았다.
- D1·D5·D6·D12의 판단은 감사자 쪽도 **코드 읽기**다. 드라이버를 돌려 확인하지 않았다.
