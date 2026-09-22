# SPEC-UIKIT-005 — progress.md

칸반 카드 t6 · 장소 사전 이름-키 충돌 수리(잔여 두 화면). plan 레인 세션이 2026-09-22 리드 디스패치로 개시.
워크트리 `.claude/worktrees/t6` (branch `WT-place-dict`, base `c5396b3`).

## §E.1 Plan-phase Audit-Ready Signal

- **plan_status: audit-ready-for-kickoff-gate** — "구현 준비 완료"가 **아니다.** D-1(`AIAssistant`의 단사성 기법)이 미해소인 채로 나가므로, 이 신호가 여는 다음 문은 run 착수가 아니라 **착수 승인 게이트**다(아래 § 미해소 결정).
- plan_complete_at: 2026-09-22T15:07+09:00
- plan 산출물: `spec.md` · `plan.md` · `acceptance.md` · `progress.md`(이 파일) — **미커밋.** 지시대로 커밋하지 않았고, `git status --short`가 `?? .moai/specs/SPEC-UIKIT-005/` 한 줄이다. `Shared/` 아래 변경 0건.
- 등록 근거: 루트 `plan.md` §Phase 1.7 후속 **8번**(t3 sync의 `--deep` 렌즈가 올린 계통 회귀) + 2026-09-22 운영자 승인(t3 병합 후 · t5 앞).

### 관측된 증거 — 명령과 그 출력

인용 줄번호는 전부 아래 명령을 이 트리(`c5396b3`)에서 돌려 얻었다. **기억하거나 어림한 값은 없다** — SPEC-UIKIT-001 HISTORY 0.1.1이 어림 인용 27건으로 run을 없는 코드로 보낸 것이 이 관례의 이유다.

| 명령 | 관측된 출력 | 쓰인 곳 |
|---|---|---|
| `git rev-parse --short HEAD` / `git branch --show-current` | `c5396b3` / `WT-place-dict` | 전 인용의 기준 트리 |
| `grep -n "\[String: Place\]" Shared/AddEventView.swift Shared/AIAssistant.swift` | `AddEventView:19` · `AIAssistant:49` | §1.1 남은 둘 |
| `grep -n "\[UUID: Place\]" Shared/AddActivityView.swift Shared/ActivityDetailView.swift` | `ActivityDetailView:20` · `AddActivityView:24` | §1.1 t3가 닫은 둘 |
| `grep -c "kind: .place" Shared/AddEventView.swift` / `… Shared/AIAssistant.swift` | **2** / **5** | §1.1 장소 줄 수 |
| `grep -c "confirmedPlaces\[" Shared/AddEventView.swift` | **6** | §1.4 (나) 접점 |
| `grep -c "confirmedPlaces" Shared/AIAssistant.swift` | **7** | §1.5 접점 |
| `grep -n "fields.remove" Shared/AddEventView.swift` | `:266` **단건**(`.notify` 줄) | REQ-020 근거 |
| `wc -l Shared/AddEventView.swift Shared/AIAssistant.swift` | **619** / **2443** | Tier 판단 |
| `grep -c "resolveOrigin(" Shared/AIAssistant.swift` | **5**(선언 1 포함 → 호출 4) | D-1 A안 비용 |
| `grep -c "resolveDestination(" Shared/AIAssistant.swift` | **9**(선언 1 포함 → 호출 8) | D-1 A안 비용 |
| `grep -c "unresolvedGenericPlace(" Shared/AIAssistant.swift` | **5**(선언 1 포함 → 호출 4) | D-1 A안 비용 |
| `grep -rn "isSamePlace" Shared/` | `AIAssistant:1297`(유일 호출) · `:1613`(범위를 적은 주석) · `:2279`(선언) | §1.3 경로별 증상 |
| `grep -n "isSamePlace\|origin == \|sameCoord" Shared/Store.swift` | **0건** | §1.3 · §3 Out of Scope |
| `grep -n "이름이 겹칠 수 있어" Shared/Models.swift` | `:108` | §1.2 |
| `grep -n "item.name ?? p.name ?? query" Shared/PlaceSearch.swift` | `:126` | §1.2 |
| `grep -n "모호한 이름" Shared/AIAssistant.swift` | `:2317` | §1.2 |
| `grep -n "bubbles\[b\].ask?.fields.firstIndex" Shared/AIAssistant.swift` | `:739`(따라서 조회 절은 `:738-739`) | §4 D-1 A안 선례 |
| `[[ "SPEC-UIKIT-005" =~ ^SPEC(-[A-Z][A-Z0-9]*)+-[0-9]{3}$ ]]` | **PASS** | SPEC ID 자기점검 |
| `grep -rn "SPEC-UIKIT-005" .moai/ *.md` | **0건**(작성 전) | ID 중복 없음 |
| `grep -c '^- \*\*REQ-' spec.md` / `grep -c '^## AC-' acceptance.md` | **11** / **9** | Tier M 상한(16/16) 아래 |
| `grep -c '^### Out of Scope — ' spec.md` | **7** | 범위 배제 절 |

### 게이트 — plan이 실제로 돌린 것 **하나**

```
$ cat Shared/EditCard.swift Shared/AIAssistant.swift Tools/GuardDriver.swift > /tmp/gd_t6.swift \
  && swiftc -o /tmp/gd_t6 /tmp/gd_t6.swift Shared/Store.swift Shared/Models.swift \
       Shared/Config.swift Shared/PlaceSearch.swift Shared/DirectionsService.swift \
       Shared/LocationManager.swift Shared/NotificationManager.swift \
       Shared/GoogleCalendarService.swift Shared/SharedInbox.swift -parse-as-library \
  && /tmp/gd_t6
205/205 통과
```

**이 205/205는 이 plan 세션이 `c5396b3`에서 직접 실행해 관측한 값이다 — t3 기록의 인용이 아니다.** 두 값이 우연히 같지만 귀속이 다르므로 그렇게 적는다(t3의 205/205는 t3의 최종 트리에 대한 t3 sync의 측정이고, 이것은 t6 착수 시점 이 트리에 대한 측정이다). 임시 산출물 `/tmp/gd_t6*`는 실행 후 삭제했다.

이 트리에서 드라이버가 초록이라는 사실이 **착수 전 베이스라인**이며, run이 `AIAssistant.swift`를 고친 뒤 이 값과 비교할 기준점이다. 컴파일 집합이 `cat Shared/EditCard.swift Shared/AIAssistant.swift Tools/GuardDriver.swift …`로 시작하므로 **이 카드의 모든 `AIAssistant` 변경이 이 게이트를 통과해야 한다** — t3와 다른 점이다.

### Gaps — plan이 **돌리지 않은** 것 (증거 없음 ≠ 통과)

아래 넷은 이 plan 세션에서 **한 번도 실행되지 않았다.** 어느 것도 "통과"로 읽어서는 안 되고, run이 자기 트리에서 직접 재어 §E.2에 적는다.

- **iOS 빌드 — 미실행.** `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build` 를 돌리지 않았다. t3 sync가 t3 최종 트리에서 "Swift 소스 경고 0"을 기록했으나 **그것은 t3의 트리에 대한 t3의 측정**이므로 이 카드의 베이스라인이 아니다.
- **macOS 빌드 — 미실행.** `xcodebuild -scheme besir-macOS -derivedDataPath build build` 를 돌리지 않았다. 위와 같은 귀속.
- **프록시 — 미실행.** `cd proxy && npm test` 를 돌리지 않았다. 이 카드는 `proxy/`를 건드리지 않지만 게이트는 run이 돈다.
- **시뮬레이터 · 실기기 — 미실행, 그리고 plan이 할 수 있는 일이 아니다.** 이 카드가 고치는 값은 **좌표**이고 좌표는 화면에 찍히지 않는다. "두 줄에 같은 상호의 다른 지점을 고른다"는 조작은 사람만 할 수 있고, `acceptance.md` AC-009가 그 목록이다. 드라이버가 `AIAssistant.swift`를 컴파일한다는 사실은 **인자 경로**를 덮을 뿐 이 조작을 덮지 않는다.

### 미해소 결정 — 착수 승인 게이트에 올린다

**D-1: `AIAssistant`의 단사성 기법 — A안(인자 슬롯 열쇠) vs B안(확정 시점 이름 구분).**

- 미해소 표식은 **`plan.md` §2에만** 있다 — `spec.md`·`acceptance.md`·이 파일에는 두지 않는 관례다(표식 자체를 세는 명령은 `grep -rc` 한 줄이며, SPEC 디렉터리 전체에서 값이 `plan.md` **1**, 나머지 셋 **0**이어야 한다. 이 줄이 표식 문자열을 그대로 싣지 않는 이유가 그것이다 — 실으면 자기가 말하는 계수를 자기가 깨뜨린다).
- 두 안의 비용·새 위험·보임새·렌즈 명단 대조는 `spec.md` §4 D-1과 `plan.md` §2. **권고는 B안**이며, 근거 셋은 ① 읽는 자리 12곳을 건드리지 않아 회귀 면적이 작다, ② 대화 범위 오염이 추가 가드 없이 닫힌다, ③ 결함의 **관측 불가능성**을 함께 고친다.
- **이 결정이 두 가지를 함께 정한다**: M3의 내용, 그리고 M4 렌즈 명단에 `ui-design`이 드는지(B안일 때만 든다 — 확정 칩 글자가 바뀐다). 따라서 **게이트 전에는 `plan.md` §4의 해당 칸이 정해지지 않는 것이 맞다.**
- **M2(`AddEventView`)는 이 결정과 무관하다** — 게이트 대기 중에도 착수 가능하고, 그 사실을 `plan.md` §2 끝줄이 적고 있다.

해소된 결정 둘은 기록만 남긴다: **D-2**(`AddEventView`에 `reseed`/`forgetPlaces`를 옮기지 않는다 — 실측 근거 REQ-020), **D-3**(현재 위치 확정 시 `card == nil`이면 쓰지 않는다 — REQ-004).

### plan 레인 교차 검증 — 인용 정정 1건

plan 레인이 SPEC의 인용을 트리에 대고 독립 재측정했고, **한 건이 두 줄 어긋나 있었다**: §4 D-1 A안의 "같은 조회를 이미 하는 자리"를 `:740-741`로 적었으나 실제는 **`:738-739`**다(`:740`은 `chosen` 대입, `:741`은 닫는 괄호). 레인이 `spec.md:244`를 정정하고 세는 명령(`grep -n "bubbles\[b\].ask?.fields.firstIndex" Shared/AIAssistant.swift`)을 붙였으며, 이 세션이 같은 명령으로 **`:739`**를 재확인했다. HISTORY 0.1.0 행에 정정 사실을 적었다(t3 관례 — 틀린 인용은 덮지 않고 정정으로 남긴다).

나머지 인용은 레인의 독립 재측정과 **전부 일치**했고, 여기에는 이 세션이 브리프를 정정한 세 건도 포함된다 — `:2317`(브리프는 `:2318`), 해석부 호출부 **12곳**(브리프는 ~9곳), `isSamePlace` 증상 분기(`:1297` 유일 호출 · `:1613` 주석이 `create_schedule` 전용임을 명시).

### 잔여 위험 (plan이 적는다)

- **줄번호 드리프트.** 이 SPEC의 인용은 `c5396b3` 기준이고 run이 두 파일을 고치면 밀린다. 밀릴 때마다 실측 재정렬한다. 같은 드리프트가 t5와 `CHECKLIST.md`로 흘러가며, **`CHECKLIST` 인용은 이 카드가 sync에서 본문 바이트 대조로 수리한다**(드리프트를 만든 카드가 수리한다는 t1 이후의 관례).
- **AC-005의 기계 절이 비어 있다.** A안과 B안은 바뀌는 자리가 겹치지 않아 세는 명령이 다르다. 고르기 전에 채우면 고르지 않은 안의 신호를 세게 되므로 비워 둔 것이 맞고, **M1 직후 run이 채운다.**
- **가장 조용한 실패 모양**은 `AddEventView`의 즐겨찾기 경로다(REQ-003). 지금 그 칩이 동작하는 유일한 이유가 "`chosen`의 라벨이 곧 사전 열쇠"이므로, 열쇠만 바꾸고 쓰기 자리를 안 만들면 **즐겨찾기로 고른 일정이 좌표 없이 저장되고 빌드도 드라이버도 잡지 못한다.** AC-003 (4)가 그 반증 신호다.
- **plan 세션은 코드를 한 줄도 건드리지 않았다.** `git status --short`가 새 SPEC 디렉터리 한 줄뿐이므로, run이 받는 트리는 `c5396b3` 그대로다.

### 인계 — plan 레인이 워크트리를 놓는다 (2026-09-22)

리드 요청으로 plan 레인 세션([79cd2f], pid 29072)이 `ExitWorktree(keep)`로 `.claude/worktrees/t6`의 세션 잠금을 놓았다 — run이 `EnterWorktree`를 거부당하고 있었기 때문이다. **`keep`이다**: 브랜치 `WT-place-dict`가 아직 미푸시라 이 나무가 작업의 **유일한 사본**이고, 리드가 병합할 때까지 없애지 않는다.

놓기 직전에 레인이 자기 트리에서 직접 확인한 것 — `git status --short` **빈 출력**(미커밋 잔여 0건), HEAD `8e68316`, 브랜치 `WT-place-dict`. 리드가 같은 사실을 주장했으나 레인이 다시 쟀다(읽고 옮기는 것과 재는 것은 다르다).

**run이 받는 상태**: 소스는 `c5396b3` 그대로이고, 이 브랜치가 더한 것은 `.moai/specs/SPEC-UIKIT-005/` 네 파일뿐이다. **먼저 할 일은 M2가 아니라 M1** — D-1(`plan.md` §2)이 운영자 판정을 기다린다. M3은 그 게이트 전에 착수하지 않는다. M2(`AddEventView`)는 게이트와 무관해 먼저 착수할 수 있다.

### 게이트 통과 — D-1 해소, run 레인 착수 (2026-09-22)

- **D-1 = B안(확정 시점 이름 구분)** — 운영자 확정 2026-09-22, 리드 디스패치로 이 레인에 전달됐다. 바로 위 인계 기록의 "운영자 판정을 기다린다" 서술보다 디스패치가 새 사실이다.
- 결정이 함께 정한 것: **M3의 내용**(B안 — 되읽는 자리 셋 `:2322`·`:2371`·`:2393`과 호출부 12곳은 무변경, 쓰기 자리 `:748`에서 구분 열쇠)과 **M4 렌즈 명단에 `ui-design` 포함**(REQ-022의 유일한 예외 — 겹치는 이름의 확정 칩 글자).
- 미해소 표식(대괄호 영문 표식)을 `plan.md` §2에서 해소 문구로 바꿨다. 계수는 위 '미해소 결정' 절이 적은 세는 명령 그대로 — 이 세션이 편집 직전에 재니 **plan.md만 1·나머지 셋 0**(기록과 일치), 편집 뒤 **전 파일 0**.
- 같은 회차 편집: `plan.md` §1 M1 상태 ⬜→✅(B안, 2026-09-22)·§4 `ui-design` 칸 확정(부른다), `spec.md` §4 D-1 머리말 해소 문구·frontmatter `status: draft → in-progress`·HISTORY 0.1.1행, `acceptance.md` AC-005 A안 절 표시.
- **AC-005 기계 절 정리.** plan 문서는 AC 매트릭스 서두에서 "고르기 전에는 그 절이 비어 있는 것이 맞다"고 적었으나 실제로는 두 갈래(A안·B안)가 **모두** 기록된 채 넘어왔다 — 잔여 위험 절의 "비어 있다" 서술과도 어긋난다. run은 절을 새로 채우는 대신 **A안 절에 채택 안 됨 표시**만 붙였다. B안 절이 이미 그대로 판정에 쓸 수 있어, 새로 쓰면 같은 내용의 소유자가 둘이 된다(계약 5).
- run 레인이 받아서 다시 잰 상태: HEAD `c198719`, `git status --short` 빈 출력, 브랜치 `WT-place-dict`. 소스는 `c5396b3` 그대로다.

## §F Phase 4 Mode Selection

**Mode: serial (sub-agent 순차)** — 근거 셋:

- **M3이 운영자 결정에 막혀 있다.** D-1이 해소되기 전에는 `AIAssistant` 쪽에 착수할 내용 자체가 정해지지 않는다. 병렬로 띄울 두 번째 일감이 게이트 뒤에 있으므로 병렬화할 span이 애초에 없다.
- **두 파일이 파일로는 독립이지만 커밋 대상 브랜치가 하나다.** `Shared/AddEventView.swift`와 `Shared/AIAssistant.swift`는 서로를 읽지 않아 기술적 의존이 없지만(`plan.md` §1), 쓰기 가능한 에이전트 둘을 한 워크트리에 동시에 두는 것은 얻는 것 없이 쓰기 경합만 만든다. 마일스톤별 커밋이 순서의 기계적 보증이 된다.
- **M2가 M3의 학습이다.** `AddEventView`는 t3 본보기가 거의 그대로 통하는 쪽이라 불변식의 모양이 빨리 확인된다. 본보기가 통하지 않는 M3에는 그 모양을 손에 쥔 채 들어가는 편이 낫다(`plan.md` §1 각주).

구현 주체는 `plan.md` §4 배정표 그대로 — M2 `swift-impl` · M3 `ai-tooling`(+B안이면 `ui-design`) · M4 `code-safety` 후 `ux-check`. M1은 결정뿐이라 **0명**이고, plan 단계(이 문서)도 읽기 전용 실측과 문서 작성뿐이라 **0명**이다.

## §E.2 Run-phase Evidence

## §E.3 Run-phase Audit-Ready Signal

## §E.4 Sync-phase Audit-Ready Signal

🗿 MoAI
