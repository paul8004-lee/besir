---
id: SPEC-TEST-001
title: "가드 드라이버 구조적 경화 — 실제 앱 데이터·키체인 격리, 내부 시간 제한, 하네스 스킬 항목 정리"
version: "0.1.3"
status: completed
created: "2026-09-24"
updated: "2026-09-24"
author: "plan-lane (orchestrator-direct)"
priority: P1
phase: "Phase 1.7 — Day 닫기 전 드라이버 경화"
module: "Tools/GuardDriver.swift"
lifecycle: spec-anchored
tags: "guard-driver, isolation, real-data, keychain, deadline, harness-skill, incident-20260923"
tier: S
related_specs: [SPEC-UIKIT-006, SPEC-ONTIME-001]
kanban_card: t8
---

# SPEC-TEST-001 — 가드 드라이버 구조적 경화

## HISTORY

| 버전 | 날짜 | 변경 |
|---|---|---|
| 0.1.0 | 2026-09-24 | 최초 작성. 칸반 카드 t8 본문(`moai todo`로 확인한 할 일 넷)과 리드 디스패치(범위 4항목은 카드 본문 그대로)를 GEARS로 정식화했다. **인용 줄번호와 건수는 전부 이 워크트리의 베이스 `2a37673`(= `origin/master`)에서 명령을 돌려 얻었고, 세는 명령을 각 수치 옆에 적었다.** 가드 드라이버는 돌리지 않았다(디스패치 금지 — §0). 대신 드라이버·`Shared/`·키체인을 쓰지 않는 탐침 두 개로 **홈 디렉터리 재지정의 기전을 실측**했고(§1.4), 그 결과 카드 (1)의 "시작·종료 백업·복원·cmp"를 **실제 디렉터리를 아예 쓰지 않는 격리 + 대조**로 바꾸는 안을 권고안으로 올렸다(§4 D-1). 카드 (3)의 감시자 회수는 같은 이유로 드라이버 내부 시간 제한으로 대체하는 안을 권고한다(D-2). 결정 넷(D-1~D-4)과 Tier는 착수 승인 게이트 몫이다. **커밋 전에 plan 감사 1회차(PASS 0.76 — must-pass 전부 통과, blocking should-fix D1~D9)를 반영했다**: 첫 쓰기를 G `:278`에서 H `:293`(→ `Store.swift:759`)으로 정정(G는 없는 번호라 쓰기 전에 돌아간다 — 코드 읽기, 감사자도 같은 판정), 게이트 밖 `removeFromCalendar` 호출부를 다섯에서 여섯으로(`updateActivity` `:272`) 정정하고 `modifyActivity` 경로와 드라이버가 실행하는 툴 이름 전수를 더했다, REQ-001의 샌드박스 삭제를 드라이버가 스스로 끝내는 두 경로(정상·거부)로 좁히고 시한 가지는 남기게 했다(주 스레드의 `createDirectory` 경합), REQ-002에 종료 루틴 단일화와 코드 2의 자리를 적었다, REQ-008에 git 밖 scratch 산출물을 넣었다, AC-001에 삭제 대상 확인·AC-002에 맥 앱 미실행 전제(`project.yml:107` 비샌드박스)·AC-003에 정확한 세는 명령·AC-004에 메인 액터 밖 타이머의 코드 읽기 판정을 더했다. 선택 지적 가운데 잔여 위험의 범위(씨앗 전체), plan §0 매핑(002→008), AC-002 (3)의 grep(쓰기·삭제·디렉터리 생성 호출 전수), AC-005의 절 범위, AC-006의 `:408` 확인, REQ-006의 종료 코드 1 중의성, 카드 원문 인용(`progress.md`), `plan.md` §2의 게이트 미해결 표식(명확화 필요 토큰 다섯)을 반영했다. REQ 문장 안의 줄번호는 프로젝트 관례라 그대로 두었다. **이 반영은 재감사를 받지 않았다** — 2회차는 게이트 결정을 반영한 뒤의 델타 감사로 남긴다 |
| 0.1.1 | 2026-09-24 | **착수 승인 게이트 해소.** 운영자가 다섯 항목을 모두 첫 안(권고)으로 확정했고 리드가 전했다: D-1 (a) 격리 + 대조 · D-2 (a) 드라이버 내부 시간 제한 · D-3 (a) 머리말 불변식(`Shared/` 무변경) · D-4 `CLAUDE.md` 편집 승인 · Tier S. 이 plan 세션은 운영자의 답을 직접 보지 않았다. (b)가 없으므로 REQ·AC의 **규범 문장은 다시 쓰지 않았다** — 결정에 기대던 조건 문구를 걷었고, 새 절은 D-4 확인 기록 하나다: §0의 Tier와 `Shared/` 문장, §2·§3 머리말, REQ-006의 D-4 거절 가지(확인 수단 절로 바꿈), REQ-008의 D-4 조건, AC-005의 거절 가지(→ 새 (4) 확인 기록), AC-007의 D-4 조건. `plan.md` §2의 명확화 토큰 다섯을 걷고 결정 기록으로 바꿨다. §4는 해소 기록으로 줄이고 채택하지 않은 안은 `plan.md` §2로 옮겼다. 카드 밖 발견의 리드 판정을 적었다 — O-1·O-2는 Day 닫기 이월(이 카드로 끌어들이지 않는다), O-4는 병합 뒤 리드가 공용 메모리를 갱신한다. **plan 감사 2회차 PASS 0.87** — D1~D9 아홉 모두 해소 판정, 새 결함 R2-1(major — D-4 확인 수단을 권한 프롬프트 하나로 좁혀 선례의 직접 입력 확인이 AC-005를 떨어뜨림)을 감사자 문구대로 반영했다: REQ-006·AC-005 (4)·`plan.md` M4·§2 항목 4가 선례의 두 수단(run 세션 직접 입력 · 권한 프롬프트 승인)을 인정하고, 둘 다 없으면 편집 보류 + 리드에게 블로커 보고. R2-2(이 행의 서술)·R2-3(`progress.md` 낡은 문장 넷)·R2-4(`pgrep -x besir`가 시뮬레이터의 iOS 앱을 잡을 가능성 — `pgrep -lf besir`로 경로 확인)도 반영했다. REQ 8 · AC 8, 인용 줄번호는 그대로다(코드는 한 줄도 안 바뀌었다). 다음은 plan 감사 3회차(R2 델타만) |
| 0.1.2 | 2026-09-24 | **plan 감사 3회차(마지막, R2 델타만) PASS 0.89** — R2-1·R2-2·R2-4 수정, R2-3 부분(D15 라벨 뒤바뀜). 새 결함 셋은 전부 minor·optional이고 감사자가 지정한 문구대로 넣었다: R3-1 — R2-1 반영이 붙인 블로커 경로가 선례 `SPEC-UIKIT-006` `spec.md:157`의 끝 문장("run 레인은 이 확인을 위해 리드에게 블로커 보고로 되묻지 않는다")과 어긋나, REQ-006·AC-005 (4)·`plan.md` M4·§2 항목 4에 "리드의 처리는 확인을 대신하지 않는다 — 이 블로커는 확인 요청이 아니라 편집 보류의 통지다"를 더했다(이 레인이 선례 원문을 읽어 확인). R3-2 — `progress.md` §F.1의 D15·D16 라벨 정정. R3-3 — `plan.md` §2 끝의 "2회차 뒤 디스패치"를 "3회차 뒤"로. **이 반영은 재감사를 받지 않았다** — 회차 상한(3)에 닿았고, 감사자는 셋을 넣든 안 넣든 판정이 바뀌지 않는다고 적었다. REQ 8 · AC 8, 코드 무변경 |
| 0.1.3 | 2026-09-24 | **sync 단계 종료 — 3-phase close(`in-progress → implemented → completed`, 한 커밋). 본문은 고치지 않았다**(frontmatter와 이 행만). ① sync 레인이 드라이버를 신선 컴파일로 다시 돌렸다 — exit 0 · `212/212` · 불변식 9/9 ✓ · 실제 지원 디렉터리의 바깥 기록 전후 diff 0 · 샌드박스 삭제 · 운영자 관측 "키체인 대화상자 없음". AC-001~003·008을 다른 손으로 재관측했고, AC-004(짧은 기한)는 run M3 ①을 인용한다. ② iOS·macOS 빌드와 프록시는 입력이 t7 sync 측정 트리 `c9a4abd` 이후 바이트 동일해 그 측정에 귀속했다. ③ **REQ-008 밖 예외 둘 — 운영자가 이 sync 세션에서 직접 승인했다.** `CHECKLIST.md`의 드라이버 인용 끝점 7개(이 카드가 민 것)를 새 좌표로 옮겼다(헝크 사상 뒤 옛·새 줄 본문 바이트 대조). 그리고 독립 `--deep` 렌즈가 찾은 `CLAUDE.md:70`의 "마지막 줄 `P/T 통과`가 있을 때만"을 "`P/T 통과` 줄이 찍혔을 때만"으로 고쳤다 — 드라이버는 그 줄 뒤에 대조 줄(시한 가지는 시한 줄)을 한 줄 더 찍는다(로그 셋에서 관측). REQ-006의 확인 수단은 이 세션에서 받은 운영자 직접 응답이다. **REQ-006 근거와 AC-008 (2)에 남은 "마지막 줄" 표현은 plan 단계의 계약 문장이라 고치지 않았다** — "`P/T 통과` 줄"로 읽는다. ④ 렌즈 판정은 결함 0 · note 4다(샌드박스 스윕 없음 · `"besir-gd-"` 리터럴 셋 · 기한 인자 거부 문구 · 위 문구). 앞의 셋은 run M5와 같다. ⑤ `CHECKLIST.md`의 옛 트리부터 틀린 인용 11개와 사실이 달라진 문장 둘, O-1·O-2·note n2는 Day 닫기로 넘긴다 |

## 0. 이 SPEC의 성격과 예산

**구현을 앞둔 변경의 계약이다.** `<base>`는 전부 `2a37673`이다. 바꾸는 코드는 `Tools/GuardDriver.swift`(빌드 대상이 아닌 호스트 `swiftc` 도구) 하나이고, 앱 소스 `Shared/`는 한 줄도 바꾸지 않는다(D-3 (a) 확정 — REQ-008).

**Tier: S (운영자 확정, 2026-09-24 — 리드 전달).** run이 바꾸는 저장소 파일은 `Tools/GuardDriver.swift`와 `CLAUDE.md`(D-4 승인) 둘, 저장소 밖에서는 하네스 스킬 파일 하나다. 줄 수는 드라이버 머리말에 더하는 수십 줄 규모다. `spec-workflow.md`(주 체크아웃 `.claude/rules/moai/workflow/`) `:140`의 Tier S 기준(< 300 LOC, < 5 files) 안이다.

**REQ·AC 예산 — 둘 다 Tier S 상한(8, `spec-workflow.md:148`)과 같다.** `grep -c '^- \*\*REQ-' spec.md` = **8**, `grep -c '^#### AC-' spec.md` = **8**. §2.1 2건(001·002) · §2.2 2건(003·004) · §2.3 1건(005) · §2.4 2건(006·007) · §2.5 1건(008).

**가드 드라이버는 이 plan 단계에서 돌리지 않았다.** 디스패치가 금지했고, 이 SPEC이 고치려는 결함이 바로 "돌리면 실제 데이터에 쓴다"이기 때문이다. 기준선 **205/205**는 t5 run 레인의 관측이다(SPEC-UIKIT-006 `progress.md` §E.2, 2026-09-23 `b8bbe1c`). 이 트리에 그 기준선을 귀속할 수 있는 근거는 컴파일 집합 12파일이 `b8bbe1c`와 `2a37673`에서 바이트가 같다는 것이다(`git diff --quiet b8bbe1c 2a37673 -- <CLAUDE.md:59-63의 12파일>` → exit 0). `Tools/GuardDriver.swift`의 마지막 변경은 `f9cd9bb`(t1)이다(`git log --oneline -1 -- Tools/GuardDriver.swift`).

## 1. 배경

### 1.1 사고 두 번 — 막은 경로와 안 막은 경로

- **1차(2026-09-16).** N절이 `store.config = AppConfig.load()`로 설정을 통째로 되돌리면서 머리말의 `autoAddToCalendar = false`가 풀렸고, 시험 일정 두 건(`Z-단발`·`P-확정`)이 운영자의 실제 구글 캘린더에 올라갔다. `9a5b3d6`이 한 필드만 되돌리게 고치고 불변식 단언(`drvAssertNoCalendarPush`, 정의 `Tools/GuardDriver.swift:184`, 호출 `:1342`·`:1617`)을 세웠다. **막은 것은 원격 푸시 하나다.**
- **2차(2026-09-23).** 저장 경로는 막혀 있지 않았다. 앞쪽 절들이 백업 없이 `Store.save()` 계열을 불러 실제 `~/Library/Application Support/besir/events.json`·`activities.json`을 픽스처로 덮어썼다. 사고 백업(`/tmp/besir-incident-20260923/`, 읽기 전용으로 확인)에 남은 제목은 `V-출발`(events)과 `W-하룻밤`(activities)이고(`grep -o '"title":"[^"]*"'`), 각각 V절 `:972`·W절 `:1038`이 만든다(`grep -n 'V-출발\|W-하룻밤' Tools/GuardDriver.swift`). 둘 다 첫 `events.json` 백업인 J절(`:1126-1127`)보다 앞이다. 그래서 뒤쪽 절들의 백업·복원은 **이미 덮어쓴 바이트를 백업하고 그것으로 되돌렸다.** 운영자 확인으로 이 맥의 두 파일에는 애초에 픽스처만 있었고(맥 앱 직접 사용 없음), 두 파일은 `[]`로 정리됐다(공용 메모리 `feedback_besir_driver_touches_real_data`, 2026-09-23 16:31).
- **같은 날 plan 레인의 실행은 키체인에서 멈췄다.** 새로 컴파일한 바이너리가 600초 동안 CPU 0%로 잠들었고, `sample`의 메인 스레드는 `executeUpdateRecurringSchedule` → `Store.updateRecurringSeries` → `Store.googleConnected.getter` → `Keychain.get` → `SecItemCopyMatching`에 있었다(SPEC-UIKIT-006 `spec.md` §0 — 그 레인의 관측). **멈추기 전에 이미 실제 `events.json`을 썼다.**

교훈은 이미 적혀 있다 — **같은 파일을 건드리는 위험은 경로별로 따로 막는다**(읽기·쓰기·원격이 각각 다른 구멍이었다). 이 SPEC은 남은 두 경로(로컬 쓰기·키체인)를 절차가 아니라 코드로 막는다.

### 1.2 쓰기 — 드라이버는 어디에 쓰나 (실측)

- 앱 데이터 경로는 `AppConfig.supportDirectory` 하나에서 나온다 — `static let`이고(`Shared/Config.swift:65-68`), `FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)`에 `besir`를 붙인다. 파일 일곱이 그 아래다(`grep -n 'appendingPathComponent("' Shared/Store.swift Shared/AIAssistant.swift Shared/Config.swift` → `Config.swift:70` config.json · `Store.swift:71`·`:74`·`:77`·`:80`·`:83` events·favorites·activities·meals·deleted_gcal_ids · `AIAssistant.swift:128` ai_history — `:67`의 `"besir"`는 디렉터리라 뺀다).
- `Store.init`(`Store.swift:117`)은 읽기만 한다(`:119` `AppConfig.load()` → `load()`·`loadFavorites()`…). 드라이버는 `main()`(`GuardDriver.swift:168`)의 첫 줄 `:169`에서 `Store`를 만들고 `:173`에서 `autoAddToCalendar = false`를 세운다.
- **첫 쓰기는 H절 `:293`의 `drvUpdate`다**(→ `executeUpdateRecurringSchedule` → `updateRecurringSeries` → `save()` `Store.swift:759`, 코드 읽기). 그 앞의 G절 `:278`은 없는 번호(99)를 줘 쓰기 전에 돌아가고, 드라이버 스스로 `:281`에서 "아무것도 쓰지 않는다"를 단언한다. 배열 대입(`store.events = …`)은 저장하지 않는다 — `didSet`이 `recomputeDaysWithSchedule()`만 부른다(`Store.swift:10`·`:14`). 같은 H절 호출이 `:764`에서 키체인 게이트에 처음 닿는다(§1.3). 첫 생성은 O절 `:428`이다. 드라이버의 절 머리는 **29개**다(`grep -c '^        print("\\n[A-Z]\. ' Tools/GuardDriver.swift`). J·N·P는 머리 글자가 두 번씩 나온다(`:326`·`:1125` · `:377`·`:1248` · `:489`·`:1489`). 파일 백업은 **10줄 · 7곳**이다(`grep -n 'Backup = try? Data(contentsOf\|let backup = try? Data' Tools/GuardDriver.swift` → 10줄) — 도우미 `drvPersistedPayload`(`:150-161`, Q절 `:651`에서 불린다) · Q(`:632-636`) · 둘째 J(`:1126-1157`) · Y(`:1165-1239`) · 둘째 N(`:1249-1341`) · Z(`:1355-1482`) · 둘째 P(`:1490-1611`). 나머지 절에는 백업이 없다 — 첫 쓰기(H `:293`)를 포함해 V(`:972`)·W(`:1038`)도 그렇다.

### 1.3 키체인 — 어떤 경로가 키체인에 닿나 (실측)

키체인 읽기는 `Keychain.get`(`Shared/GoogleCalendarService.swift:400`, `SecItemCopyMatching` `:406`) 하나이고, 두 갈래로 닿는다.

- **클라이언트 ID 게이트를 지나는 갈래.** `googleConnected` = `config.hasGoogleCalendar && gcal.isConnected`(`Store.swift:481`)이고 `hasGoogleCalendar`는 클라이언트 ID가 비어 있지 않은지다(`Config.swift:28`). 단락 평가라 ID가 비면 `isConnected`(`GoogleCalendarService.swift:37` → `Keychain.get`)를 부르지 않는다. 이 갈래를 쓰는 자리: `updateRecurringSeries` `:764` · `enqueueCalendarUpload` `:805` · `pushToCalendar` `:867` · `pushActivitiesToCalendar` `:902` · `updateEvent` `:963` · `connectGoogle` `:1308` · `syncWithGoogle` `:1315`. 2026-09-23의 멈춤은 이 갈래였다(`:764`).
- **게이트를 지나지 않는 갈래 둘.** `isConnected`와 `accessToken`은 클라이언트 ID를 보지 않는다. (i) `removeFromCalendar`(`:97`) → `gcal.deleteEvent`(`:101` → `GoogleCalendarService.swift:131` `guard isConnected`). 호출부 9곳(`grep -n 'removeFromCalendar(' Shared/Store.swift` → 정의 `:97` 제외) 가운데 게이트 밖은 **여섯**이다 — `updateActivity` `:272` · `deleteActivity` `:370` · `deleteRecurringSeries` `:706` · `deleteEvent` `:1258` · `deleteEvents` `:1276` · `deleteActivities` `:1289`. 게이트 안은 셋이다 — `:773`(`:764` 안) · `:965`(`:963` 안) · `:1425`(`reconcileActivities`, 호출은 `syncWithGoogle`의 `:1378` 한 곳뿐이라 `:1315` 안). (ii) `updateActivity`(`:264`)의 `gcal.createEvent`(`:273` → `GoogleCalendarService.swift:49` `accessToken(allowInteractive: true)` → `:253` `Keychain.get`). `updateActivity`는 `modifyActivity`(`:288`)의 `:310`에서 불리고, 그것은 AI 편집 경로(`AIAssistant.swift:2220`)다. **두 갈래 모두 `googleEventId`를 가진 레코드에서만 불린다**(`:1258`은 `:1257`의 `if let gid = event.googleEventId`, `:370`·`:706`·`:1276`·`:1289`는 `!gids.isEmpty`, `:272-273`은 `old.googleEventId`).
- 드라이버는 그 삭제·수정 경로를 부르지 않는다. 직접 호출은 없고(`grep -n 'store\.delete\|store\.updateActivity\|delete_schedule\|delete_recurring' Tools/GuardDriver.swift` → 0줄), 드라이버가 실행하는 툴은 생성 계열뿐이다 — `grep -o 'drvExecuteTool("[a-z_]*"' Tools/GuardDriver.swift | sort | uniq -c` → `create_activity` 4 · `create_schedule` 3, `drvAsk`는 `create_schedule` 32 · `create_activity` 6 · `create_recurring_schedule` 3, `drvUpdate`는 `updateRecurringSeries`로 가고 그 본문(`:715-800`)에 `updateActivity`는 없다(`grep -c` = 0). store 배열에 들어가는 gid 픽스처는 N-2의 `gid-already` 하나이고(`:1282`), `:1332`에서 비운다. N-4의 두 gid(`:1312`·`:1318`)는 디코딩만 한다.
- **클라이언트 ID는 설정 파일이 없어도 비지 않는다.** `AppConfig.load()`는 파일이 없으면 `bundledDefaults`를 돌려주고(`Config.swift:83-89`), 그 `googleClientID`는 비어 있지 않다(`:80`). 그래서 §1.4의 격리만으로는 키체인 게이트가 닫히지 않는다 — REQ-003이 따로 필요하다.
- 드라이버는 N-1에서만 ID를 비운다(`:1262` 저장 · `:1263` 비움 · `:1337` 되돌림). N절 밖의 모든 절은 실제 ID로 돈다.

### 1.4 홈 재지정 — 탐침으로 잰 기전 (이 레인 관측, 2026-09-24, macOS 26.6.2)

드라이버·`Shared/`·키체인을 쓰지 않는 탐침 두 개(`.moai/state/verify/t8/probe_home.swift`·`probe_pin.swift` — git 무시 경로, `git check-ignore -v` → `.gitignore:28`)를 컴파일해 경로 문자열만 찍었다. 디렉터리는 하나도 만들지 않았다(`test -e /tmp/besir-probe-pin` → 없음).

| 방식 | `FileManager…applicationSupportDirectory` | 판정 |
|---|---|---|
| 아무것도 안 함 | `/Users/iseongmin/Library/Application Support` | 기준 |
| 프로세스 안 `setenv("CFFIXED_USER_HOME", X, 1)` 뒤 첫 호출 | `X/Library/Application Support` | **따른다** |
| 프로세스 안 `setenv("HOME", X, 1)` | 원래 경로 그대로 | 따르지 않는다 |
| `NSHomeDirectory()`를 먼저 읽고 `setenv(CFFIXED…)` | 뒤의 호출이 `X/…` | 먼저 읽어도 고정되지 않는다 |
| `FileManager` 호출을 먼저 하고 `setenv(CFFIXED…)` | 뒤의 호출이 `X/…` | 먼저 불러도 고정되지 않는다 |
| `NSTemporaryDirectory()` 앞뒤 | `/var/folders/…/T/` 그대로 | 영향 없음 |

**고정되는 것은 `AppConfig.supportDirectory` 자신이다** — Swift의 `static let`은 처음 접근할 때 한 번 계산된다. 그래서 `setenv`는 그 첫 접근(= `Store.init`의 `AppConfig.load()`, `GuardDriver.swift:169`)보다 앞서야 한다. 셸 앞머리 `HOME=…` 방식은 워크트리 가드가 거부했다(이 레인 관측) — 프로세스 안 `setenv`가 유일하게 잰 경로다. `CFFIXED_USER_HOME`이 키체인 검색까지 바꾸는지는 **재지 않았다**(키체인을 건드리는 탐침은 이 SPEC이 막으려는 위험 그 자체다). 이 SPEC은 그 효과에 기대지 않는다.

### 1.5 시간 제한 — 감시자가 호출을 붙잡은 일

- 이 맥에는 `timeout`·`gtimeout`이 없다(`which timeout gtimeout` → 둘 다 not found, 이 레인 관측). SPEC-UIKIT-006 REQ-030 (a)의 `perl -e 'alarm shift; exec @ARGV'` 형태는 워크트리 가드가 거부했고, t5 run 레인은 `sleep <초> && kill -TERM $PID &` 감시자 + `wait $PID`로 205/205를 완주했다(공용 메모리, t5 run 레인 기록).
- t5 sync 레인이 잰 것: 드라이버 로그의 마지막 쓰기는 16:40:19, 시작은 16:33:06(약 433초 완주)인데, 도구 호출은 시작+600초인 16:43:06에 돌아왔다 — **같은 호출 안의 감시자가 살아 있는 동안 호출이 돌아오지 않았다**(시각은 관측, 기전은 가설 — 공용 메모리의 정정 단락). 감시자를 900초로 넓히면 모든 실행이 900초가 될 뿐이다. 카드 (3)이 가리키는 것이 이것이다.

### 1.6 R5 — 하네스 스킬의 낡은 항목 (실측)

- 주 체크아웃의 `.claude/skills/hns-besir-app-hazards/SKILL.md`(249줄, `wc -l`) `:229-234`의 "Dead code candidates" 목록 `:233`이 `Store.updateMeal(_:)`을 "zero callers" 후보로 싣는다.
- t5 착수 게이트가 D-2 (a) — **유지 + 이유 주석** — 로 정했고(SPEC-UIKIT-006 `spec.md` §4 D-2, 2026-09-23), 코드에는 그 주석이 있다(`Store.swift:408` "호출부가 0개여도 남긴다 — 진행 중인 SPEC-FULL-001 REQ-003이 이 연산을 Store 요구사항으로 명시한다."). 스킬 항목만 여전히 후보라고 말한다. 같은 파일 `:244-246`에 "Do not delete `MealCategory.delivery`…"라는 유지 문단의 선례가 있다.
- `.claude/`는 git이 추적하지 않는다(`git ls-files .claude | wc -l` = **0**). 이 워크트리에는 그 파일이 없고, 주 체크아웃의 사본이 유일하다.

## 2. 요구사항 (GEARS)

착수 승인 게이트가 D-1 (a) · D-2 (a) · D-3 (a) · D-4 승인을 확정했다(2026-09-24, 운영자 결정·리드 전달, §4). 아래 REQ는 그 안이다.

### 2.1 실제 앱 데이터 격리 (카드 (1) — D-1 (a))

- **REQ-001 (Event-driven)**: When the driver starts, it shall — before the first read of `AppConfig.supportDirectory` — point its own process's user home at a fresh per-run directory it creates under `NSTemporaryDirectory()` by setting `CFFIXED_USER_HOME`, and shall exit with code 2 before constructing `Store` unless `AppConfig.supportDirectory` then resolves inside that directory; when the run ends normally or is refused this way, it shall remove that directory, and only after checking that the path is the one it created. 근거: §1.4의 실측 — 프로세스 안 `setenv`는 따르고 `HOME`은 따르지 않으며, 고정되는 것은 `static let` 하나라 첫 접근(`:169`) 앞이어야 한다. 경로 확인은 fail-closed다 — 앞으로의 macOS가 이 변수를 무시하면 드라이버는 아무것도 건드리기 전에 멈춘다. 이 격리 뒤에는 기존 파일 백업 7곳(§1.2)이 샌드박스 안에서 돈다 — 그대로 둔다(§3 Out of Scope). **지우는 경로는 둘뿐이다**(정상 종료 · 거부) — 둘 다 주 스레드가 끝낸다. 시간 제한 가지(REQ-005)는 주 스레드가 아직 샌드박스에 쓰는 중일 수 있어(`Store.save()`가 `createDirectory(withIntermediateDirectories: true)`로 다시 만든다, `Store.swift:1456`) 지우지 않고 경로만 찍는다. 신호(`SIGKILL`·처리기 없는 `SIGINT`/`SIGTERM`)·크래시로 끝나도 샌드박스는 남는다 — 어느 쪽이든 남는 것은 `NSTemporaryDirectory()` 아래의 시험 파일뿐이고 실제 데이터와 무관하다. 지우는 대상 확인은 필수다 — 드라이버가 만든 경로(`NSTemporaryDirectory()` 아래, 이번 실행의 고유 이름)가 아니면 지우지 않는다. 수리 모양(참고): `main()` 첫머리에 `setenv` → `AppConfig.supportDirectory.path.hasPrefix(<샌드박스>)` 확인 → 그다음 `:169`의 `Store(...)`.

- **REQ-002 (Event-driven)**: When the driver starts and again when it ends — by normal completion or by the deadline of REQ-005 — it shall read the real support directory as a set of file names with their bytes (a missing directory is itself a state), and when the two readings differ it shall print every differing name and exit with code 3; it shall never write, restore, or delete anything under the real support directory. 근거: 격리가 막고, 대조가 잰다 — "불변식이 살아 있는지 재는 단언을 둔다"는 교훈의 코드판이다(공용 메모리 1차 사고 How to apply (3)). 카드 (1)의 "복원"이 없어지는 이유: 드라이버가 실제 디렉터리에 쓰지 않으니 되돌릴 것이 없고, 그 사이 맥 앱이 정당하게 쓴 내용을 복원이 덮어쓸 수 있다. 이름 집합으로 읽는 이유: `Store`의 파일 목록을 드라이버에 한 벌 더 적으면 새 파일이 생길 때 어긋난다(계약 5). 실제 경로도 다시 철자하지 않는다 — 참고 모양: 재지정 **전** `NSHomeDirectory()`(먼저 읽어도 고정되지 않음, §1.4)에 `AppConfig.supportDirectory`의 샌드박스 기준 상대 경로를 붙인다. 종료 코드: 2는 어떤 절도 돌기 전의 거부라 다른 코드와 겹치지 않는다. 절이 돈 뒤에는 실제 디렉터리가 바뀌었으면 3, 아니면 시간 제한 124(REQ-005), 아니면 단언 실패 1, 아니면 0이다. **끝내는 일은 한 루틴이 한 번만 한다** — 정상 종료와 시간 제한 가운데 먼저 들어온 쪽이 대조·종료 코드 결정·종료를 하고, 늦게 온 쪽은 그 루틴 안으로 들어가지 못한다(잠금 등). 두 스레드가 각자 `exit`를 부르면 동시 종료가 되고, 이는 정의되지 않은 동작이다.

### 2.2 키체인 격리 (카드 (2) — D-3 (a))

- **REQ-003 (State-driven)**: While the driver runs, `store.config.googleClientID` shall be empty — set in the header next to `autoAddToCalendar = false` (`GuardDriver.swift:173`) — so that `config.hasGoogleCalendar` is false and every gated path in §1.3 returns before `Keychain.get`. 근거: 2026-09-23의 멈춤 경로(`:764`)가 이 게이트를 지난다(§1.1). 격리만으로는 부족하다 — 샌드박스의 설정은 `bundledDefaults`이고 그 ID는 비어 있지 않다(`Config.swift:80`, §1.3). N절은 `:1262`에서 그 순간의 값을 저장하고 `:1337`에서 되돌리므로 머리말 뒤에는 **빈 값을 되돌린다** — N절 편집은 필요 없다(AC-003이 확인한다). N-1의 단언("clientID가 비면 googleConnected는 거짓", `:1264`)은 뜻이 그대로다.

- **REQ-004 (Ubiquitous)**: The driver's invariant check shall measure — besides `autoAddToCalendar` being false — that `config.hasGoogleCalendar` is false and that no record in `store.events` or `store.activities` carries a `googleEventId`, at three sites: right after the header, at the end of the N clause (`:1342`), and at the end of the run (`:1617`). 근거: 게이트 밖 두 갈래(§1.3)는 gid를 가진 레코드에서만 불린다. 드라이버는 지금 그 경로를 부르지 않지만(코드 읽기, §1.3), 뒤에 추가될 절이 gid 레코드와 삭제 경로를 함께 들여오면 키체인 대화상자로 드러나기 전에 빨갛게 드러나야 한다. 이 단언이 재는 것은 **그 경로의 전제**이지 키체인 호출 자체가 아니다 — 호출을 직접 재려면 `Shared/`에 손을 대야 한다(D-3 (b), 채택하지 않음 — `plan.md` §2). 한계는 기존 `:1614-1616` 주석과 같다: 두 측정 자리 사이에서 깼다가 되세우면 통과한다.

### 2.3 시간 제한 (카드 (3) R4 — D-2 (a))

- **REQ-005 (Event-driven)**: When the driver has run longer than its deadline, it shall print one line naming the deadline and the sandbox path, run the comparison of REQ-002, and exit with code 124 (or 3 when the comparison differs) through the single finishing routine of REQ-002 — from a timer that does not run on the main actor, so that a main thread blocked in a synchronous call (as in `SecItemCopyMatching` on 2026-09-23) cannot hold it back — leaving the sandbox in place (REQ-001). The deadline shall be a constant chosen by run, with its value and reasoning recorded, and overridable by a single command-line argument used by AC-004's short-deadline test. 근거: 외부 감시자가 사라지면 R4(감시자가 호출을 붙잡음, §1.5)도 그 자리에서 사라진다. 가드가 거부한 `perl` 형태와 서브셸 문제도 없다. 격리(REQ-001) 뒤라 시간 제한으로 끊겨도 실제 데이터는 무사하고, 대조는 끊긴 실행에서도 돈다. 참고 수치: 기록된 완주는 t5 run의 약 433초 한 번뿐이다(§1.5). `exit`와 `_exit` 중 무엇을 쓰는지(출력 버퍼 비우기 포함)는 run이 정하고 이유를 적는다.

### 2.4 문서 (카드 (3)의 기록 · 카드 (4))

- **REQ-006 (Ubiquitous)**: `CLAUDE.md` § 빌드 · 배포 shall state, next to the driver block (`CLAUDE.md:58-64`), that the driver isolates itself (temporary home, empty client ID, internal deadline), its exit codes (0 · 1 · 2 · 3 · 124), and that no external watcher is needed — and that any external watcher that is added anyway must be reaped immediately after `wait`; the recipe in the driver's header comment (`GuardDriver.swift:4-9`) shall not disagree with that block. 근거: `CLAUDE.md`는 게이트 레시피의 단일 출처다(`CLAUDE.md:45` § 빌드 · 배포, 워크트리 레시피 교훈). 종료 코드가 문서에 없으면 게이트를 도는 레인이 3과 124를 "그냥 실패"로 읽는다. 1은 `swiftc` 컴파일 실패와도 겹친다(블록이 `&&`로 잇는다) — 그래서 문서는 "마지막 줄 `P/T 통과`가 있을 때의 1만 단언 실패"라고 적는다. 레시피 사본은 둘이다(`git grep -n '/tmp/gd' -- ':!.moai/specs'` → `CLAUDE.md:59`·`:60`·`:64`와 `GuardDriver.swift:4`·`:5`·`:9`) — 명령을 바꾸면 두 곳을 함께 바꾸거나 머리말을 `CLAUDE.md` 가리킴으로 줄인다(계약 5). **`CLAUDE.md` 편집은 착수 승인 게이트가 승인했다(D-4, 2026-09-24).** 승인이 리드를 거쳐 왔으므로 run 레인은 편집 직전에 자기 세션에서 운영자의 확인을 한 번 더 얻는다. **확인으로 치는 수단은 둘뿐이다** — 운영자가 run 세션에 직접 입력한 확인, 또는 그 편집에 뜨는 권한 프롬프트를 운영자가 승인하는 것(SPEC-UIKIT-006 `spec.md:157`의 선례 — 그 run은 직접 입력으로만 확인됐고 권한 프롬프트는 뜨지 않았다, 그 `progress.md:258-259`). 리드나 다른 세션을 거쳐 온 메시지는 확인으로 치지 않는다. 쓴 수단과 결과를 `progress.md` §E.2에 적는다. 둘 중 어느 것도 얻지 못하면 `CLAUDE.md` 편집을 보류하고 리드에게 블로커로 보고한다 — 처리는 리드가 정한다. 리드의 처리는 확인을 대신하지 않는다 — 운영자가 run 세션에서 직접 확인하게 하거나, `CLAUDE.md` 편집을 이 카드에서 빼고 REQ-006·AC-005를 어떻게 닫을지 정하는 것 중 하나다. 이 블로커는 확인 요청이 아니라 편집 보류의 통지다(선례 `spec.md:157`은 확인을 블로커로 되묻지 않았다).

- **REQ-007 (Ubiquitous)**: The hazards skill (`/Users/iseongmin/Projects/besir/.claude/skills/hns-besir-app-hazards/SKILL.md`) shall no longer list `Store.updateMeal(_:)` among the dead-code candidates, and shall carry instead a do-not-delete note — in the file's language (English), shaped like `:244-246` — that names SPEC-FULL-001 REQ-003 as the reason, SPEC-UIKIT-006 D-2 (a) (2026-09-23) as the decision, and the reason comment at `Shared/Store.swift:408`. 근거: §1.6. 스킬이 후보라고 말하는 한 다음 전수 분석이 이것을 또 올린다. 목록 머리(`:229` "re-verified 2026-09-16")와 나머지 두 항목(`KoreanHolidays.dates(year:)`·`MealLog.estimatedCost`)은 이 카드가 다시 재지 않았으므로 건드리지 않는다. 파일이 git 밖이므로 증거는 편집 전 사본과 `diff`다(AC-006).

### 2.5 범위와 게이트

- **REQ-008 (Unwanted)**: The change shall not modify any repository path outside its declared files — in run, `Tools/GuardDriver.swift`, `CLAUDE.md` (driver section only — D-4 approved at the kickoff gate), this SPEC directory, and root `plan.md` limited to plan-versus-reality updates for this card; in sync, root `plan.md` and this SPEC directory — with plan-audit reports under `.moai/reports/plan-audit/` excepted as the auditor's output; outside git it shall write only the hazards skill file (REQ-007), the driver's own sandbox, and run-lane scratch artifacts (the freshly compiled driver binaries and concatenated sources under `/tmp` as `CLAUDE.md:59-60` compiles them, the skill file's pre-edit copy, and run logs), listing every such path in `progress.md` §E.2; and it shall keep the argument-guard driver fully green. 근거: `Shared/`·`project.yml`·`proxy/` 무변경이면 앱 빌드와 프록시가 이 카드와 무관함이 `git diff --quiet`로 증명된다 — 새 소스 파일이 없으니 `xcodegen generate`도, 서명 계정 리셋도, `besir-iOS`·`besirShare` Team 재선택 요청도 없다. 기존 단언은 바꾸지 않는다(불변식 함수 안은 예외) — 드라이버가 재는 인자 가드 거동은 이 카드가 건드리지 않는다. 루트 `plan.md`를 run에 여는 이유는 `CLAUDE.md:23`("계획이 실제와 달라지면 그 자리에서 이 파일을 갱신한다")이다.

## 3. 인수 기준과 범위 밖

§3.1은 Tier S의 인라인 인수 기준이다. 착수 승인 게이트가 확정한 안(§4) 기준이다. **이 카드의 AC는 명령, 코드 읽기 셋(AC-001 (4)·AC-002 (3)·AC-004 (6) — `code-safety` 렌즈가 판정하고 근거를 적는다), 운영자 관측 하나(키체인 대화상자 여부)로 판정한다** — 앱 동작이 바뀌지 않으므로 시뮬레이터·실기기 항목은 없다.

### 3.1 인수 기준 (Tier S 인라인)

#### AC-001 — 샌드박스가 `Store`보다 먼저 선다 (REQ-001)

**Given** run이 끝난 트리에서 **When** `grep -n 'CFFIXED_USER_HOME' Tools/GuardDriver.swift`·`grep -n 'let store = Store(' Tools/GuardDriver.swift`·`grep -n 'removeItem' Tools/GuardDriver.swift`를 돌리고 AC-008의 전체 실행 출력을 읽으면 **Then** (1) 첫째의 `setenv` 줄이 `main()` 안에 있고 그 줄번호가 둘째보다 작다 (2) 출력의 앞머리가 샌드박스 경로와, 그 경로로 시작하는 `AppConfig.supportDirectory`를 찍는다 (3) 정상 종료 뒤 찍힌 샌드박스 경로가 없다(`test -e <경로>` 실패) (4) 셋째가 찍는 줄 가운데 이 카드가 더한 것은 샌드박스 삭제뿐이고, 그 호출 바로 앞에 경로가 `NSTemporaryDirectory()` 아래이며 이번 실행의 고유 이름을 담는지 확인하는 조건이 있다 — 줄번호와 그 조건 문장을 `progress.md` §E.2에 적는다(코드 읽기, `code-safety` 렌즈가 판정). 기존 7곳의 `removeItem`(절마다의 백업 복원)은 무변경이다. **종료 코드 2의 거부 가지는 관측하지 않는다** — 재지정이 실패하는 상황을 만들 방법이 없어 코드 읽기로만 판정하고, 그 사실을 `progress.md` §E.2에 적는다.

#### AC-002 — 실제 디렉터리가 바이트 단위로 그대로다 (REQ-002)

**Given** 두 실행 동안 macOS 앱(besir)이 떠 있지 않고(`pgrep -x besir` 빈 출력을 실행 전후에 기록 — 맥 앱은 샌드박스가 없어 같은 디렉터리를 쓴다, `project.yml:107` `com.apple.security.app-sandbox: false`. 출력이 비지 않으면 `pgrep -lf besir`로 경로를 보고, 시뮬레이터의 iOS 앱(`CoreSimulator` 경로 아래 — iOS 타깃도 제품 이름이 `besir`다)뿐이면 전제를 충족한 것으로 적는다 — 이 구분은 관측하지 않은 가설이다), run 레인이 드라이버를 돌리기 직전에 `ls -la "$HOME/Library/Application Support/besir/"`와 그 안의 파일마다 `shasum -a 256`을 기록해 두고 **When** AC-004의 시간 제한 실행과 AC-008의 전체 실행을 각각 마친 뒤 같은 명령들을 다시 돌리면 **Then** (1) 두 번 모두 이름 목록과 해시가 실행 전과 같다 — 드라이버의 자기 보고만 믿지 않고 바깥에서 따로 잰다 (2) 드라이버 출력에 실제 디렉터리 대조의 통과 줄이 있고 종료 코드가 3이 아니다 (3) `grep -n 'write(to\|removeItem\|createDirectory' Tools/GuardDriver.swift`가 찍는 줄마다 대상 경로가 샌드박스에서 나온다(`AppConfig.supportDirectory` 파생이거나 이 카드가 만든 샌드박스 경로) — 실제 디렉터리 경로 변수를 대상으로 쓰는 줄이 0이다(코드 읽기, 판정 근거를 §E.2에 적는다). 실행 중 맥 앱이 떠 있었다면 (1)·(2)는 판정하지 않고 다시 돈다.

#### AC-003 — 키체인 게이트가 실행 내내 닫혀 있다 (REQ-003·004)

**Given** run이 끝난 트리에서 **When** `grep -n 'googleClientID = ""' Tools/GuardDriver.swift`·`grep -n 'calSavedClientID' Tools/GuardDriver.swift`와 `git show 2a37673:Tools/GuardDriver.swift | grep -n 'calSavedClientID'`·`grep -n '<불변식 함수 이름>(' Tools/GuardDriver.swift | grep -v 'func '`(이름을 바꾸지 않았으면 `drvAssertNoCalendarPush`)를 돌리고, AC-008의 전체 실행을 운영자에게 **"키체인 대화상자는 뜨지 않아야 한다. 뜨면 거부(Deny)로 답하고 알려 달라"**고 먼저 알린 뒤 돌리면 **Then** (1) 첫째에 머리말 줄(`let store = Store(` 뒤, 첫 절 머리 `A.` 앞)이 있다 (2) 둘째와 셋째가 줄번호를 빼고 같은 두 문장이다(N절의 저장·되돌림 무변경) (3) 넷째가 **정확히 3줄**이고(`2a37673`에서는 2줄 — `:1342`·`:1617`), 그 함수 본문이 `hasGoogleCalendar`와 `googleEventId`를 잰다 (4) 출력의 불변식 줄이 전부 ✓다 (5) 운영자의 답이 **"대화상자 없음"**이다. 대화상자가 떴으면 게이트가 샌 것이다 — AC-003은 FAIL이고 카드를 멈추고 리드에게 보고한다. 운영자가 "모르겠다"고 답하면 그대로 적고 PASS로 세지 않는다.

#### AC-004 — 시간 제한 가지가 짧은 기한에서 제대로 끝난다 (REQ-005·REQ-002)

**Given** AC-002의 실행 전 기록이 있고 **When** 새로 컴파일한 드라이버를 기한 인자를 작은 값(예: 3초)으로 주어 돌리며 앞뒤에 `date +%s`를 찍으면 **Then** (1) 종료 코드가 124다 (2) 출력에 기한과 샌드박스 경로를 적은 한 줄과 실제 디렉터리 대조 줄이 있다 (3) 앞뒤 `date +%s`의 차이가 기한 + 10초 이내다 — 도구 호출이 기한보다 오래 붙잡히지 않았다 (4) 찍힌 샌드박스 경로가 `NSTemporaryDirectory()` 아래다(REQ-001대로 이 가지는 지우지 않는다) (5) AC-002 (1)의 바깥 대조가 같다 (6) **코드 읽기**: 시한 타이머가 메인 액터 밖(전역·전용 디스패치 큐나 스레드)에서 돌고, 정상 종료와 시한이 같은 종료 루틴을 한 번만 지난다 — 짧은 기한 실행은 메인 액터의 `Task.sleep` 타이머로도 124가 나와 이 성질을 가리지 못하므로, 타이머 생성 줄과 종료 루틴의 잠금 줄을 `progress.md` §E.2에 적고 `code-safety` 렌즈가 판정한다. 그리고 두 실행(이 AC·AC-008)의 명령 원문을 `progress.md` §E.2에 그대로 적는다 — **`sleep`·`kill`·`perl`이 없어야 한다**(외부 감시자 없음). AC-008의 전체 실행은 기한에 걸리지 않아야 한다(종료 코드 124가 아님). 기한 값과 이유를 함께 적는다.

#### AC-005 — 레시피 문서가 드라이버와 맞는다 (REQ-006)

**Given** run이 끝난 트리에서 **When** `git diff -U0 2a37673 HEAD -- CLAUDE.md | grep '^@@'`·`grep -n '124' CLAUDE.md`·`sed -n '1,24p' Tools/GuardDriver.swift`를 읽으면 **Then** (1) 헝크가 전부 § 빌드 · 배포 절 안에 있다 — `2a37673`에서 그 절은 `## 빌드 · 배포`(`:45`)부터 다음 `## ` 머리 앞까지다(`grep -n '^## ' CLAUDE.md`로 끝 줄을 잰다) (2) 종료 코드 다섯(0·1·2·3·124)과 "외부 감시자 불필요 — 두면 `wait` 직후 거둔다"가 적혀 있다 (3) 드라이버 머리말의 레시피가 `CLAUDE.md` 블록과 명령 단위로 같거나, 머리말이 `CLAUDE.md`를 가리키는 한 줄로 줄었다 (4) `progress.md` §E.2에 REQ-006의 두 수단 가운데 하나(run 세션 직접 입력 · 편집 권한 프롬프트 승인)로 운영자가 확인했다는 기록이 수단과 함께 있다. 둘 다 없어 편집을 보류했다면 AC-005는 판정하지 않고, 블로커 보고와 리드의 처리를 적는다(리드의 처리는 확인을 대신하지 않는다 — REQ-006).

#### AC-006 — 하네스 스킬이 `updateMeal`을 후보로 싣지 않는다 (REQ-007)

**Given** run 레인이 편집 전에 스킬 파일을 세션 scratch(또는 워크트리의 git 무시 경로)로 복사해 두고 **When** 편집 뒤 `grep -n 'updateMeal' <스킬 파일>`·`grep -n 'Dead code candidates\|was removed from this list' <스킬 파일>`·`diff <사본> <스킬 파일>`을 돌리면 **Then** (1) `updateMeal`이 나오는 줄이 두 번째 명령이 찍는 두 줄("Dead code candidates" `:229` · "`RouteMode.car` was removed from this list" `:236` — `2a37673` 시점 주 체크아웃 사본 기준) 사이의 목록에 없다 (2) `updateMeal`이 나오는 문단이 `SPEC-FULL-001`·`REQ-003`·`SPEC-UIKIT-006`·`Store.swift:408`을 모두 담는다 (3) `diff`가 그 목록 한 줄 제거와 유지 문단 추가만 보인다 (4) 사본 경로와 `diff` 출력이 `progress.md` §E.2에 있다. git이 이 파일을 보지 못하므로 (4)가 유일한 변경 기록이다.

#### AC-007 — 범위 밖 경로가 없다 (REQ-008 앞 절)

**Given** run이 끝난 브랜치에서 **When** `git diff --name-only 2a37673 HEAD -- . ':!.moai/reports/plan-audit'`·`git diff --quiet 2a37673 HEAD -- Shared/ project.yml proxy/`·`git diff --name-only --diff-filter=A 2a37673 HEAD -- . ':!.moai/specs/SPEC-TEST-001' ':!.moai/reports/plan-audit'`·`git diff -U0 2a37673 HEAD -- Tools/GuardDriver.swift | grep '^-' | grep 'drvCheck('`를 돌리면 **Then** (1) 첫째가 `Tools/GuardDriver.swift`, `CLAUDE.md`, `.moai/specs/SPEC-TEST-001/` 아래 경로, (갱신했다면) 루트 `plan.md`뿐이다 — 그 밖의 경로가 하나라도 있으면 FAIL. 루트 `plan.md`가 나오면 헝크마다 이 카드 항목인지 §E.2에 적는다 (2) 둘째가 exit 0 (3) 셋째가 0줄 (4) 넷째에 나오는 줄이 있으면 전부 불변식 함수 본문 안의 줄이다 — 그 밖의 기존 단언이 지워지거나 바뀌었으면 FAIL (5) `progress.md` §E.2에 git 밖에서 쓴 경로가 전부 적혀 있다 — 스킬 파일, 그 편집 전 사본, `/tmp`의 연결 소스·바이너리(실행마다), 샌드박스(정상 종료는 삭제 확인, 시한 실행은 남긴 경로), 실행 로그 — 그리고 그 밖의 경로가 없다는 run 레인의 진술. 카드 브랜치에 병합이 들어오면 기준을 `git merge-base origin/master HEAD`로 바꾸고 SHA를 적는다.

#### AC-008 — 가드 드라이버가 전부 초록이다 (REQ-008 뒤 절 · REQ-001~005)

**Given** run이 끝난 트리에서 **When** 이 워크트리 `CLAUDE.md` § 빌드 · 배포의 드라이버 블록을 **바이너리 이름만 고유하게 바꿔**(낡은 `/tmp` 바이너리 재사용 금지 — 워크트리 레시피 교훈) 신선 컴파일해 한 번 돌리면 **Then** (1) 종료 코드가 0이다 (2) 마지막 줄 `P/T 통과`에서 P = T다 (3) T = 205 + k이고, k(이 카드가 더한 단언이 실행되는 횟수)를 **어떻게 셌는지와 함께** 적는다 — 확정안의 모양이면 머리말 자리에서 새로 불리는 기존 불변식 1 + 새 단언 2 × 3자리 = 7로 212가 예상이다(REQ-002의 대조까지 `drvCheck`로 세면 213) (4) T가 예상과 다르면 어느 절에서 몇이 달라졌는지 적는다 — 샌드박스의 시작 상태는 실제 `config.json`이 아니라 `bundledDefaults`이므로(§1.3) 설정에 기대는 단언이 달라질 수 있다(§3 Out of Scope 잔여 위험). 그 차이가 인자 가드 거동의 회귀로 판정되면 FAIL이다. iOS·macOS `xcodebuild`와 `npm test`는 AC-007 (2)가 무변경을 증명하므로 선택이고, 돌렸는지 적는다.

### Out of Scope — 드라이버의 네트워크 호출 (O-1, 코드 읽기 가설 — 미관측)

- 드라이버의 생성 경로는 이동시간 조회에 닿는다 — `addEvent`(`Store.swift:559`)의 `:587` `applyEstimate` → `:980` `directions.estimate` → `DirectionsService.swift:27`·`:30`(`config.hasProxy`면 프록시 경유 카카오·ODsay). 샌드박스의 설정(`bundledDefaults`)에도 프록시 주소가 있다(`Config.swift:78`). 생성 호출은 `drvCreate`·`drvCreateRecurring` 합쳐 12곳이다(`grep -c 'drvCreate(\|drvCreateRecurring(' Tools/GuardDriver.swift` = 14에서 정의 두 줄 `:81`·`:82`를 뺀 값). `fresh()`마다 `AIAssistant` 초기화가 `location.useCurrentLocation()`(`AIAssistant.swift:122`)을 부른다. 기록된 완주 433초(§1.5)는 네트워크 대기와 맞아떨어지지만 증거는 아니다.
- 사실이라면 `CLAUDE.md:58`의 "(API 할당량 안 씀)"은 틀리다. 이 카드는 네트워크를 격리하지 않는다 — 카드 범위 넷 밖이고, 조회 결과에 기대는 단언이 있는지 먼저 재야 한다. **리드 판정(2026-09-24): Day 닫기 이월 — 이 카드로 끌어들이지 않는다.** `CLAUDE.md:58`의 문구는 이 카드에서 고치지 않는다(REQ-006의 편집은 드라이버 블록 곁의 격리·종료 코드·감시자 문장에 한한다).

### Out of Scope — 절마다의 파일 백업 7곳 (O-2)

- REQ-001 뒤에는 7곳(§1.2)이 샌드박스 안의 파일을 백업·복원한다. 해롭지 않지만 실제 데이터 보호로서는 할 일이 없어진다. 지우는 것은 계획에 없는 리팩터링이라 이 카드에서 하지 않는다(`CLAUDE.md` "계획에 없는 리팩터링은 하지 않는다"). Day 닫기 간결성 검사의 입력으로 넘긴다 — 리드 판정(2026-09-24): Day 닫기 이월.

### Out of Scope — 샌드박스와 키체인 (O-3, 미측정)

- `CFFIXED_USER_HOME`이 키체인 검색 목록까지 바꾸는지는 재지 않았다(§1.4). 이 SPEC의 키체인 격리는 REQ-003·004가 전부다.

### Out of Scope — 끝난 SPEC의 절차와 공용 메모리 (O-4)

- SPEC-UIKIT-006 REQ-030 (a)의 실행 절차(키체인 거부 고지·백업·시간 제한·`kill -0`·`cmp`)는 완료된 SPEC이라 고치지 않는다 — 기록으로 남는다. 이 카드가 병합되면 그 절차가 필요 없어진다는 사실은 공용 메모리 `feedback_besir_driver_touches_real_data`("t8 전까지 SPEC-UIKIT-006 REQ-030 (a)")에 반영돼야 한다 — 리드 판정(2026-09-24): 병합 뒤 리드가 갱신한다.

### 잔여 위험 — 샌드박스의 시작 상태

- 기준선 205/205는 실제 지원 디렉터리를 씨앗으로 잰 값이다 — 설정(`config.json`)과 `Store.init`이 읽는 일정·즐겨찾기·활동·식사·삭제 묘비, `AIAssistant`가 읽는 대화 기록(`ai_history.json`) 전부. 샌드박스는 이 모두가 없는 상태, 곧 `bundledDefaults`와 빈 배열·빈 기록으로 시작한다. 2026-09-23 기준 실제 디렉터리에는 `activities.json`·`config.json`·`events.json` 셋만 있었고(SPEC-UIKIT-006 REQ-030 (a) (ii), 그 레인의 `ls`), 두 데이터 파일은 같은 날 `[]`로 정리됐다(공용 메모리). 그래서 차이가 날 수 있는 씨앗은 사실상 설정 하나다. 운영자 설정과 `bundledDefaults`의 값이 같은지는 재지 않았다(운영자 설정 파일을 읽지 않았다). 다르면 AC-008 (4)가 잡는다.

## 4. 결정 — 해소 (착수 승인 게이트, 2026-09-24)

운영자가 결정했고 리드가 전했다 — **다섯 항목 모두 첫 안(권고)**. 이 plan 세션은 운영자의 답을 직접 보지 않았다. 채택하지 않은 안과 그 근거는 결정 기록으로 `plan.md` §2에 남긴다.

- **D-1 (a) 격리 + 대조** — REQ-001·002. 드라이버는 실제 지원 디렉터리를 읽기만 하고 쓰지 않는다. 시간 제한·`SIGKILL`·크래시로 끊겨도 **실제 지원 디렉터리의 파일은** 무사하다(키체인·네트워크는 이 안이 막는 경로가 아니다 — D-3·O-1). 씨앗도 비어서 실제 레코드의 gid가 메모리에 올라오지 않는다. 카드 (1)의 "복원"은 없어지고 "cmp 대조"는 REQ-002로 남는다.
- **D-2 (a) 드라이버 안의 시간 제한** — REQ-005. 외부 감시자가 없으니 R4는 감시자와 함께 사라진다. `CLAUDE.md`에는 "감시자 불필요, 두면 `wait` 직후 거둔다"(REQ-006).
- **D-3 (a) 드라이버만** — REQ-003·004. `Shared/` 무변경. 게이트 갈래는 구조적으로 닫히고, 게이트 밖 두 갈래는 전제(gid 레코드)를 재는 단언으로 덮는다 — 코드 읽기 수준의 보장이다.
- **D-4 승인** — REQ-006. § 빌드 · 배포의 드라이버 블록 곁에 격리·종료 코드·감시자 문장. 컴파일·실행 명령은 바뀌지 않는다.
- **Tier S 확정** — 저장소 파일 둘(`Tools/GuardDriver.swift`·`CLAUDE.md`)과 저장소 밖 하나(스킬 파일), 드라이버에 더하는 수십 줄.

(b)가 하나도 채택되지 않아 REQ·AC 재작성과 Tier 재판단은 없다.

## 5. 관련 문서

- 칸반 카드 **t8** 본문(`moai todo`) — 이 SPEC의 출처
- 공용 메모리 `feedback_besir_driver_touches_real_data` — 1·2차 사고 전말, 실행 주체들의 기록(sleep 감시자·`kill -0`·`pgrep -fx`·감시자 정정)
- [SPEC-UIKIT-006](../SPEC-UIKIT-006/spec.md) — REQ-030 (a) 실행 절차(이 카드가 코드로 대체), §4 D-2(`updateMeal` 유지)
- [SPEC-FULL-001](../SPEC-FULL-001/spec.md) — REQ-003(`updateMeal`을 요구)

🗿 MoAI
