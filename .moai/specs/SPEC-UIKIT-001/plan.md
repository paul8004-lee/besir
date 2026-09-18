# SPEC-UIKIT-001 — plan.md

> 이 문서는 **구현을 앞둔 계획**이다(as-built 아님). 설계 원본은 루트 `plan.md:411-417`. 루트 `plan.md`는 사용자가 "계획이 실제와 달라지면 그 자리에서 갱신"하는 1차 참조 문서다 — 구현 중 어긋남이 생기면 그 파일과 본 문서를 함께 갱신한다.

## 0. Tier 판단

**Tier: M**

- 근거: 건드리는 파일 **4개** — `Shared/EditCard.swift`(신규, 모델·동작 표면·날짜 단일 출처) + `Shared/EditCardView.swift`(신규, 뷰·`ChipFlow`·`chip`) + `Shared/AIAssistant.swift`(중첩 타입 반출·어댑터·별칭) + `Shared/AIChatView.swift`(카드 제거·컴포넌트 사용). 여기에 문서 갱신 2종(`CLAUDE.md` 드라이버 명령, 루트 `plan.md`).
- **REQ 16건 · AC 8건** — `spec-workflow.md:149`의 Tier M 상한(REQ 16 / AC 16)에 REQ가 **정확히 걸려 있다**. 산출 내역은 spec.md §0 "REQ 예산" 항에 있다(§2.1 5 · §2.2 4 · §2.3 3 · §2.4 2 · §2.5 2). 파일 수도 CLAUDE.md의 한 Day 상한(3~4)에 정확히 걸린다 — **어느 쪽이든 하나라도 늘면 분열 신호**다.
  - 0.1.x가 이 자리에 적었던 "REQ 16건"은 실제 20건이었고 근거가 없는 숫자였다(HISTORY 0.2.0). 지금의 16은 `grep -c '^- \*\*REQ-'` 실측값이다 — 이 줄을 고칠 때는 다시 세고 고친다.
- Tier L이 아닌 이유: Tier L은 >1000 LOC 또는 >15파일(`spec-workflow.md:142`)이고 t1은 4파일이다. REQ가 상한을 넘었을 때 tier up으로 푸는 것은 `:152`가 금지한 "예산 느슨하게 하기"에 해당한다.
- `design.md`/`research.md`는 Tier L 전용 산출물 — 설계 검토는 `ui-design` 전문가 협의(2026-09-18, spec.md §4 D-1·D-2)와 `291db49` 실측으로 갈음했다.

## 1. 마일스톤

의사결정 가변성 순서로 배치했다 — 사람 검토가 집중해야 할 것(중립 표면의 형태)을 맨 앞에 두고, 기계적 이동과 게이트를 뒤로 미뤘다. 실행 순서도 의존성상 동일하다: M1 → M2 → M3 → M4 → M5.

| M | REQ | AC | 요약 | 상태 |
|---|---|---|---|---|
| M1 | — (D-1·D-2) | — | 설계 확정 — 중립 표면의 형태와 새 파일 이름. **2026-09-18 `ui-design` 협의로 해소**: D-1 = 클로저 묶음, D-2 = `Shared/EditCard.swift` + `Shared/EditCardView.swift`. 근거·기각 사유는 spec.md §4 | 🟢 |
| M2 | REQ-001~005 | AC-001 | 필드 모델 중립화 — `AskField`(`:38-113`)·`PendingAsk`(`:117-127`)를 `Shared/EditCard.swift`로. 날짜 3멤버는 **정의 이동 + 위탁**(REQ-002), 별칭 2줄로 `AIAssistant` 본문·드라이버 무변경(REQ-005). **드라이버 `swiftc` 인자 목록과 CLAUDE.md 갱신을 같은 마일스톤에서 한다** — 미루면 M3 내내 드라이버가 빨갛다 | ⬜ |
| M3 | REQ-010~013 | AC-002 | 카드 뷰 추출 — `AskCardView`(`:158-557`)·`ChipFlow`(`:564-612`)·`chip` 빌더를 `Shared/EditCardView.swift`로, `private` 해제. 9개 결합 지점(`:181`·`:238`·`:299`·`:344`·`:444`·`:495`·`:523`·`:534`·`:537`)을 `EditCardActions`로 대체. `AIChatView`는 `EditCardView(card:busy:actions:)`를 호출만 한다(612줄 → 약 200줄) | ⬜ |
| M4 | REQ-020~022, REQ-040~041 | AC-003, AC-004, AC-006 | 불변식 **절 단위** 대조 — 디자인 4절, 접근성 9절, 동작 4절. 여기에 범위 경계 확인(네 화면 무변경, 날짜 형식 복제 0, `parts` 사후 대입 0). **일괄 통과 금지** — 절마다 하나씩 원본과 맞춰 본다 | ⬜ |
| M5 | REQ-030~031 | AC-005, AC-007, AC-008 | 품질 게이트 — 가드 드라이버 전체 초록(단언 추가 없음), iOS·macOS 무경고 빌드, `cd proxy && npm test`, 실기기에서 AI 카드 무변화 확인 | ⬜ |

**M1은 닫혔고 M2 착수 가능하다.** D-3(`AIChatView`에 남는 계약 6 우회·전송 버튼 접근성 라벨을 t1에 포함할지)은 **운영자 결정 대기**이지만 M2~M5를 막지 않는다 — 기본값이 "t1 밖"이므로, 결정이 늦으면 그대로 후속 항목이 된다.


## 2. 알려진 이슈 / 리스크

- **`private static` 3개가 이 카드의 가장 단단한 제약**(REQ-002, 형태 확정됨). `AskField.customLabel`·`accepts`가 `AIAssistant.parseDatetime`·`when`·`isoFormatter`를 부르는데 셋 다 `private static`이라, 중첩을 벗어나는 순간 컴파일이 깨진다. **해석을 복제해 "양쪽 다 되게" 만드는 것이 이 카드에서 가장 하기 쉬운 실수**이고 계약 5 위반이다 — 그래서 REQ-002가 형태를 "정의 이동 + 위탁"으로 지정했다. `when`은 카드 밖 **13곳**에서 쓰이므로(실측) 그냥 옮기면 호출부 13곳이 함께 바뀌어 REQ-041과 부딪힌다. 기계적 신호: `grep -rc "yyyy-MM-dd'T'HH:mm:ss" Shared/` 합이 1을 넘으면 복제다(AC-001 조건 5).
- **재렌더 경로가 끊기는 위험**(D-1의 보류된 판단). 뷰에서 `@ObservedObject var assistant`를 없애도 부모(`AIChatView.chat`이 `assistant.bubbles`를 읽는다)가 재렌더를 담당한다는 것은 **코드 구조 독해에 근거한 추론**이며 실행으로 확인한 사실이 아니다. 반증 신호 셋 중 하나라도 나오면 즉시 되돌린다: 칩을 탭해도 체크가 안 뜬다 / 검색 결과가 줄에 안 얹힌다 / `isThinking` 중 확인 버튼이 안 잠긴다.
- **카드 지역 `@State`가 뷰 정체성에 묶여 있다**(REQ-013). 교체 중 카드를 `Group`이나 조건문으로 한 겹 싸면 정체성이 바뀌어 `customOpen`·`draft`·`rejected`·`draftBasis`·`draftDate`가 날아간다. 증상: 장소 줄 타이핑 중 `idle→searching→results` 재렌더 사이에 **에디터가 닫히거나 글자가 지워진다**. `.id(bubble.id)`와 `ForEach` 안 위치가 지금과 같은지 확인한다.
- **`parts` 불변성이 느슨해진다**(D-2). 화면 카드가 `parts` 없이 카드를 만들려면 기본값이 필요하고, Swift는 `let` + 기본값을 멤버와이즈 이니셜라이저에서 제외하므로 `var`로 바뀐다. `grep -rn '\.parts = ' Shared/`가 0건이어야 한다 — 0이 아니면 카드가 붙잡은 보류 호출이 사후 변조되고 있다(AC-006).
- **드라이버가 모델을 20곳에서 쓴다**(REQ-004). `drvAsk`가 `PendingAsk?`를 돌려주는 등 `Tools/GuardDriver.swift`가 `AskField`/`PendingAsk`를 20회 참조한다. CLAUDE.md의 `swiftc` 인자 목록에 새 모델 파일을 넣지 않으면 드라이버가 컴파일되지 않는다 — **M2에서 같이 한다.**
- **모델 파일에 SwiftUI가 새어 들어가면 드라이버 경계가 무너진다**(REQ-003). 컴파일 집합 11개 파일에 `import SwiftUI`가 한 건도 없다(실측). 모델에 `Color`·`View`·`@State` 같은 것이 하나라도 들어가면 드라이버를 못 돌린다 — 그래서 모델과 뷰는 **반드시 다른 파일**이고, 이 제약이 D-2에서 파일이 2개인 이유다.
- **`xcodegen generate`가 필수이고 서명을 리셋한다**(REQ-031). 새 소스 파일 2개가 생기므로 CLAUDE.md의 조건("새 소스 파일이나 Info.plist 키를 추가했을 때만")에 걸린다. 돌린 뒤 **`besir-iOS`·`besirShare` 두 타깃 모두** Team 재선택을 사용자에게 요청해야 한다 — 요청하지 않으면 다음 빌드가 `No Account for Team`으로 끊긴다. `Tools/`는 빌드 대상이 아니라 무관하다.
- **카드 렌더링은 가드 밖이다**(REQ-031 (d)). 드라이버가 검증하는 것은 보류 상태의 결정적 부분(필드 목록·확인 시 1회 호출·값 수용 판정)이고, 렌더링·제스처·접근성 낭독은 **빌드 + 실기기**만 잡는다. "드라이버 초록"을 "동작 무변화"로 읽지 않는다 — 88/88 초록 다음 날 실기기 결함 7건이 나온 이력이 있다.
- **순수 추출인데 개선하고 싶어지는 자리들**(REQ-041). §1.1이 `PlaceField`의 계약 6 위반과 디바운스 부재를 측정해 적어뒀지만 본 SPEC은 고치지 않는다(t3 소관). 추출 중 눈에 띈 개선은 코드가 아니라 루트 `plan.md`의 후속 항목으로 적는다.
- ~~**루트 `plan.md:412`의 줄 수가 낡았다**~~ — **해소됨**(2026-09-18, 커밋 `3511672`). `EventDetailView` 366 → **377** 정정(`origin/master..HEAD`에서 `+29`), Phase 1.7 절 신설, 세 장 분할표 추가.
- **`.toggle` 종류가 아직 없다**(t2·t3 대비). 현재 `Kind`는 `.place`·`.mode`·`.buffer`·`.notify`·`.weeks`·`.title`·`.datetime` 일곱이고, 네 화면의 토글(알림 받기 / 구글 캘린더 등록 / 가는·오는 이동 함께 만들기)에 대응하는 종류가 없다. **t1에서는 만들지 않는다**(REQ-041). t2에서 추가할 때의 함정을 미리 적어둔다: `isReady`가 `chosen != nil`로 판정하므로 토글 줄은 반드시 `chosen: "true"`/`"false"`로 생성해야 한다 — 안 그러면 Bool은 영원히 "안 고른 값"이고 확인 버튼이 풀리지 않는다.
- **하네스 배정**(CLAUDE.md "작업을 시작할 때", 매번 적용):
  - M1 — `ui-design`(중립 표면의 형태·새 컴포넌트 API 설계)
  - M2·M3 — `swift-impl`(타입 이동·뷰 추출), `ai-tooling`(`AIAssistant`의 어댑터 쪽 변경과 드라이버 컴파일 명령)
  - M4·M5 — `code-safety`(구현 변경 후), `ux-check`(실기기 배포 전)
- **동시 진행 세션과의 접점**: 본 카드는 worktree `.claude/worktrees/t1`(브랜치 `WT-ui-unify-1`)에서만 작업한다. 이 브랜치는 `origin/master`에서 갈라진 뒤 로컬 `master`(24커밋, `291db49`)를 머지해 만들어졌다 — 기본 분기점인 `origin/master`(`1d2c460`)에서는 `AIChatView.swift`가 **146줄**이고 카드 UI가 아예 없어, 그대로 작업하면 존재하지 않는 코드를 추출하게 된다.

## 3. 검증 계획

| 대상 | 명령 | 통과 기준 |
|---|---|---|
| AI 인자 가드 | CLAUDE.md의 드라이버 블록(모델 파일 추가 후) | 전체 초록, **단언 추가 없음** — 기존 단언이 그대로 통과 |
| iOS 빌드 | `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build` | `BUILD SUCCEEDED`, 툴체인 경고 제외 무경고 |
| macOS 빌드 | `xcodebuild -scheme besir-macOS -derivedDataPath build build` | 동일 |
| 프록시 | `cd proxy && npm test` | 전체 통과 (본 SPEC은 프록시를 건드리지 않지만 게이트는 돈다) |
| 실기기 | `-allowProvisioningUpdates` → `devicectl device install app` → `process launch` | acceptance.md **AC-007** 항목 전부 |

`hns-besir-app-verify` 스킬이 이 명령들의 단일 출처다 — 명령을 새로 만들지 않고 그 스킬을 돈다.

## 4. 후속 (본 SPEC 밖)

- `SPEC-UIKIT-002` (카드 t2) — `AddEventView`(550) · `EventDetailView`(377) 전환. 본 SPEC이 done이 된 뒤 착수(같은 컴포넌트를 쓰므로 순서 의존). 기존 기능 손실 0 기준 — 캘린더 업로드 상태 표시(`EventDetailView.swift:110-146`) 포함.
- `SPEC-UIKIT-003` (카드 t3) — `AddActivityView`(267) · `ActivityDetailView`(222) 전환. 활동의 이동 다리(leg)를 컴포넌트 옵션으로 흡수하고 화면마다 따로 계산하지 않는다. `PlaceField`의 계약 6 위반·디바운스 부재가 여기서 사라진다.

🗿 MoAI
