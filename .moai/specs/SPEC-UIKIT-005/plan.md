# SPEC-UIKIT-005 — plan.md

> 이 문서는 **구현을 앞둔 계획**이다(as-built 아님). 설계 원본은 루트 `plan.md` §Phase 1.7 후속 8번.
> 루트 `plan.md`는 "계획이 실제와 달라지면 그 자리에서 갱신"하는 1차 참조 문서다 — 본 카드가
> 카드 본문의 셈("화면마다 같은 4줄")을 실측으로 정정했으므로 sync에서 후속 8번 항목에 반영한다.

## 0. Tier 판단

**Tier: M**

- **파일은 둘**이다 — `Shared/AddEventView.swift`(619줄) · `Shared/AIAssistant.swift`(2443줄).
  인자 거동이 실제로 바뀔 때에 한해 `Tools/GuardDriver.swift`가 셋째로 붙는다. 세는 명령:
  `wc -l Shared/AddEventView.swift Shared/AIAssistant.swift` → **619 / 2443**.
- **파일 수만 보면 S로 보이지만 S가 아니다.** Tier S는 `acceptance.md` 없이 `spec.md §3`에 AC를
  인라인하는 등급이다. 이 카드는 세 가지 실측된 이유로 그 등급에 들지 않는다:
  1. **표면이 크다** — `AIAssistant`의 장소 줄 **5개**(`grep -c "kind: .place"` = 5), 좌표를 되읽는
     자리 **3곳**(`:2322`·`:2371`·`:2393`), 그 셋을 부르는 호출부 **12곳**(§2 D-1 비용표).
  2. **설계가 미해소다** — A안/B안이 회귀 면적과 새 위험이 다르고, 되돌리기 비싼 결정이다.
     Tier S에는 결정 게이트를 걸 자리가 없다.
  3. **증거 설계 자체가 작업이다** — 좌표는 화면에 보이지 않는다. 무엇을 어떻게 눌러야 결함이
     드러나는지를 적는 것이 `acceptance.md`의 몫이고, 인라인 AC로는 안 된다.
- **REQ 11건 · AC 9건** — 실측 명령과 함께: `grep -c '^- \*\*REQ-' spec.md` = **11**,
  `grep -c '^## AC-' acceptance.md` = **9**. Tier M 상한(REQ 16 / AC 16) 아래로 여유 **5건**.
  **REQ 16 도달 또는 소스 파일 4개는 분할 신호.**
- Tier L이 아닌 이유: 두 파일이고, 어느 안을 고르든 변경이 **한 파일 안의 상태 소유 형태**에
  머문다. 새 타입도, 새 화면도, 새 저장 경로도 생기지 않는다.
- `design.md`/`research.md`는 Tier L 전용 — 설계 판단은 본 세션의 실측(`spec.md` §1.1~1.5)과
  SPEC-UIKIT-003의 본보기로 갈음했다.

## 1. 마일스톤

**의사결정 가변성 순서다.** 되돌리기 가장 비싼 결정(`AIAssistant` 기법 선택)이 맨 위에 있고,
기계적인 것이 아래로 내려간다. 실행 순서도 의존성상 같다: M1 → M2 → M3 → M4.

| M | REQ | AC | 요약 | 상태 |
|---|---|---|---|---|
| M1 | — (D-1) | — | **설계 확정 — `AIAssistant` 기법 A/B 선택.** 착수 승인 게이트에서 운영자가 고른다. 고른 안이 M3의 내용과 M4의 렌즈 명단(`ui-design` 포함 여부)을 함께 정한다. **미해소 결정 1건** | ⬜ |
| M2 | REQ-001~004 | AC-001~004 | `AddEventView` — 열쇠를 줄 신원으로, 즐겨찾기 씨앗 분리, **쓰기 자리 신설**(지금 없다), 현재 위치 확정 순서 뒤집기. `reseed`/`forgetPlaces`는 **만들지 않는다**(REQ-020) | ⬜ |
| M3 | REQ-010~012 | AC-005·AC-006 | `AIAssistant` — M1이 고른 안으로 단사성 세우기. **읽는 자리 셋(`:2322`·`:2371`·`:2393`)이 줄을 볼 수 없다는 것이 이 마일스톤의 전제**다 | ⬜ |
| M4 | REQ-020~022, REQ-030 | AC-007~009 | 범위 대조와 게이트 — 두 파일 밖 무변경, 보이는 변화 대조, 드라이버·양쪽 빌드·프록시, 시뮬레이터·실기기 | ⬜ |

**M2를 M3보다 먼저 두는 이유는 위험이 아니라 학습이다.** `AddEventView`는 t3의 본보기가 거의
그대로 통하는 쪽이라 요소 하나하나가 옳게 놓였는지 빨리 확인된다. M3은 본보기가 통하지 않는
쪽이므로, M2에서 확인된 불변식의 모양을 손에 쥔 채 들어가는 편이 낫다. 두 파일은 서로를 읽지
않으므로 기술적 의존은 없다.

## 2. 미해소 결정 — 착수 승인 게이트

**[NEEDS CLARIFICATION: `AIAssistant`의 단사성 기법 — A안(인자 슬롯 열쇠) vs B안(확정 시점 이름 구분)]**

두 안의 내용·비용·새 위험은 `spec.md` §4 D-1에 실측과 함께 적혀 있다. 요지만 옮기면:

| | A안 — 슬롯 열쇠 | B안 — 확정 시점 이름 구분 **(권고)** |
|---|---|---|
| 읽는 자리 | 시그니처 3 + 호출부 **12곳**을 고친다 | **0곳** — String 조회 그대로 |
| 대화 범위 오염 | **새로 생긴다.** 사전은 `resetConversation()`(`:217`)에서만 비므로, 이번 카드에서 확정한 적 없는 이름이 앞 카드의 좌표를 같은 슬롯으로 받는다. 질의 동일성 가드 필수(REQ-011) | 구조적으로 닫힌다 — 열쇠가 좌표를 구분한다 |
| 사용자에게 보임 | 변화 **0건** | 겹치는 순간에만 칩 글자가 구분 문자열로 바뀐다 — **결함의 관측 불가능성을 함께 고친다** |
| 모델 경유 위험 | 없음 | 구분 문자열이 `chosen`으로 모델에 간다. 모델이 말을 바꾸면 조회가 빗나가 **새 검색**으로 떨어진다 — 이 카드 이전의 모호한 검색 동작이지 **잘못된 확정 좌표는 아니다**(열화 방향이 안전한 쪽) |
| run 렌즈 | `ai-tooling` | `ai-tooling` + **`ui-design`**(칩 글자) |

**이 게이트를 통과하기 전에는 M3에 착수하지 않는다.** 두 안은 바꾸는 자리가 겹치지 않으므로,
잘못 고르면 되돌리는 것이 아니라 다시 짜는 일이 된다.

**M2(`AddEventView`)는 이 결정과 무관하다** — 게이트 대기 중에도 착수할 수 있다.

## 3. 알려진 이슈 / 리스크

- **`AddEventView`의 즐겨찾기 경로가 열쇠 교체만으로 죽는다** (REQ-003). 지금 즐겨찾기 칩이
  동작하는 유일한 이유는 `chosen`에 라벨이 들어가고 그 라벨이 사전 열쇠이기 때문이다
  (`:512` `field(key)?.chosen.flatMap { confirmedPlaces[$0] }`). 칩 탭 경로인
  `choose(field:value:)`(`:256`)에는 **쓰기가 한 줄도 없다**(`grep -n "confirmedPlaces"`의 여덟
  자리 중 그 함수 범위에 드는 것이 0건). 열쇠만 바꾸고 쓰기 자리를 안 만들면 **즐겨찾기로 고른
  일정이 좌표 없이 저장된다** — 빌드도 드라이버도 잡지 못하는 종류다.
  반증 신호: 출발지를 즐겨찾기 칩으로 고르면 이동시간이 계산되지 않고 저장 버튼이 열리지 않는다.
- **fail-closed 읽기를 빠뜨리면 결함이 형태만 바꿔 산다** (REQ-001). 이름이 열쇠이던 동안에는
  `chosen`이 nil인 줄이 사전에 자연히 안 걸렸다(열쇠가 없으니까). 신원이 열쇠가 되면 줄은 언제나
  열쇠를 갖고 있어 **지운 줄이 옛 좌표를 계속 들고 있는다.** t3가 렌즈 권고로 복원한 자리다
  (`AddActivityView:493-494`가 본보기).
- **현재 위치 쓰기와 줄 인덱스 찾기의 순서**(REQ-004). `:425`가 무조건 쓰고 `:427`이 조건부로
  인덱스를 잡는다. 합치면 "`card`가 nil이면?"이 드러나므로 **코드가 아니라 SPEC이 답을 정했다**
  (쓰지 않는다 — D-3). 실측상 두 호출 경로(`:396`·`:410`) 모두 `card` 비-nil이라 관측 차이는 없다.
- **A안을 고를 경우, 질의 동일성 가드를 빠뜨리면 결함을 다른 결함으로 바꾼다**(REQ-011). 새 위험이
  **조용한 종류**라 테스트로 우연히 잡히지 않는다 — 앞 카드에서 '스타벅스' 홍대점을 확정한 뒤,
  뒤 카드에서 같은 슬롯에 '스타벅스'가 실려 오면 사용자가 이번에 고르지 않은 좌표가 붙는다.
- **B안을 고를 경우, 구분 문자열이 저장 데이터에 새면 안 된다**(REQ-012). 내부 토큰이 모델·요약
  문구로 새어 나간 전례가 **두 번** 있다(`AIAssistant.swift:44-48` 주석 — 현재 위치·가는 편 없음).
  `resolveDestination`(`:2388`)·`resolveOrigin`(`:2309`)이 돌려주는 것은 **사전에 든 `Place` 자체**
  이므로 `.name`은 원래 값이어야 한다. 반증 신호: 확정 요약이나 캘린더 일정 제목에 구분 문자열이
  찍힌다.
- **`AIAssistant.swift`는 가드 드라이버의 컴파일 집합 안에 있다**(REQ-030). 이 워크트리 `CLAUDE.md`
  § 빌드 · 배포의 블록이 `cat Shared/EditCard.swift Shared/AIAssistant.swift Tools/GuardDriver.swift …`
  로 시작한다 — **t3와 다른 점이다.** 모든 `AIAssistant` 변경이 드라이버를 통과해야 하고, 인자
  거동이 바뀌면 `Tools/GuardDriver.swift`의 단언도 **같이** 갱신한다(같은 `CLAUDE.md` 문장).
- **`reseed`/`forgetPlaces`를 반사적으로 옮기는 것**(REQ-020). t3의 다섯 요소 중 그 하나는 다리
  토글이 장소 줄을 빼고 다시 넣는 화면에만 필요하다. `AddEventView`에는 그 경로가 없다 —
  `grep -n "fields.remove" Shared/AddEventView.swift`가 `:266` 한 건이고 `.notify` 줄이다.
  넘겨받은 본보기를 확인 없이 착수하면 아무것도 막지 않는 장치가 하나 더 생긴다(계약 5 역방향).
- **줄번호 드리프트가 t5와 `CHECKLIST.md`로 흘러간다.** 본 카드가 두 파일을 수정하므로 t5가 적어
  둔 좌표와 `CHECKLIST`의 인용이 밀린다. t5는 plan에서 grep 재실측하기로 이미 정해져 있고,
  `CHECKLIST` 인용은 **본 카드가 sync에서 본문 바이트 대조로 수리한다**(t1이 179건을 어긋낸 뒤
  생긴 관례 — 드리프트를 만든 카드가 수리한다).
- **하네스 배정**(이 워크트리 `CLAUDE.md` § 작업을 시작할 때, 사용자 지시·매번 적용) — §4.

## 4. 하네스 전문가 배정 (사용자 지시, 매번 적용)

`CLAUDE.md` § 작업을 시작할 때의 표를 **이 카드가 실제로 건드리는 것**으로 채운 명단이다.
걸리는 조건이 없으면 부르지 않는다 — 0명도 정상적인 답이다.

| 마일스톤 | 부르는 전문가 | 조건 |
|---|---|---|
| M1 (설계 확정) | **0명** | 읽기 전용 실측과 결정뿐이다 |
| M2 (`AddEventView`) | `swift-impl` | `Shared/`의 Swift 기능 수정 |
| M3 (`AIAssistant`) | `ai-tooling` | AI 툴·인자 경로 변경 |
| M3 (B안일 때만) | **+ `ui-design`** | 확정 칩의 글자가 바뀐다(REQ-022의 유일한 예외) |
| M4 (대조·게이트) | `code-safety` | 구현을 바꿨음 / 실기기 배포 전 |
| M4 (Day 마무리) | `ux-check` | 실기기 배포 전 / Day 마무리 |
| plan 단계(이 문서) | **0명** | 읽기 전용 실측과 문서 작성뿐 |

- **`ui-design`은 M1의 결과에 달렸다.** A안이면 보이는 변화가 0건이라 부를 조건이 없다.
  B안이면 칩 글자가 바뀌므로 부른다. **M1 전에는 이 칸이 정해지지 않는다.**
- `code-safety`는 M2·M3 어느 쪽이든 **구현이 끝난 뒤** 한 번 돌린다. 매니페스트 Sprint Contract의
  `hazard_coverage`는 "검사하지 않은 것 = 실패"다 — 0건을 찾는 건 통과지만 렌즈를 안 돌린 채
  끝내는 건 통과가 아니다.

## 5. 검증 계획

명령의 단일 출처는 이 워크트리의 `CLAUDE.md` § 빌드 · 배포와 `hns-besir-app-verify` 스킬이다 —
**명령을 새로 만들지 않고 그것을 돈다.**

| 대상 | 명령 | 통과 기준 |
|---|---|---|
| AI 인자 가드 | `CLAUDE.md` § 빌드 · 배포의 드라이버 블록 (컴파일 집합이 `cat Shared/EditCard.swift Shared/AIAssistant.swift Tools/GuardDriver.swift …`로 시작) | 전체 초록. 인자 거동이 바뀌었으면 `Tools/GuardDriver.swift` 단언도 **같이** 갱신 |
| iOS 빌드 | `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build` | `BUILD SUCCEEDED` + `grep 'warning:' <log> \| grep -c '\.swift'`가 **0** |
| macOS 빌드 | `xcodebuild -scheme besir-macOS -derivedDataPath build build` | 동일 |
| 프록시 | `cd proxy && npm test` | 전체 통과 (이 SPEC은 프록시를 건드리지 않지만 게이트는 돈다) |
| 범위 경계 | `git diff --name-only <base>...HEAD -- 'Shared/*.swift'` | **정확히 두 파일** |
| 새 파일 | `git diff --name-only --diff-filter=A <base>...HEAD -- 'Shared/*.swift'` | **0건** → `xcodegen generate` 불필요 |
| 시뮬레이터 | 입력 문구 + 기대 결과를 정확히 준 스크립트 방식(초기화 시점 포함) | `acceptance.md` AC-009 시뮬레이터 목록 전부 |
| 실기기 | `-allowProvisioningUpdates` → `xcrun devicectl device install app` → `process launch` | AC-009 실기기 전용 항목 |

**측정된 베이스라인 (`c5396b3`, 이 세션이 직접 실행).**

```
$ cat Shared/EditCard.swift Shared/AIAssistant.swift Tools/GuardDriver.swift > /tmp/gd_t6.swift \
  && swiftc -o /tmp/gd_t6 /tmp/gd_t6.swift Shared/Store.swift Shared/Models.swift \
       Shared/Config.swift Shared/PlaceSearch.swift Shared/DirectionsService.swift \
       Shared/LocationManager.swift Shared/NotificationManager.swift \
       Shared/GoogleCalendarService.swift Shared/SharedInbox.swift -parse-as-library \
  && /tmp/gd_t6
205/205 통과
```

빌드·프록시는 **이 plan 세션에서 돌리지 않았다** — run 단계의 몫이다. t3 sync가 최종 트리에서
기록한 값(iOS·macOS Swift 소스 경고 0, 프록시 7/7)은 **t3의 기록이지 이 세션의 실측이 아니므로**
run 단계가 자기 트리에서 다시 잰다.

**경고 게이트는 총계가 아니라 `.swift` 계수로 잰다.** `appintentsmetadataprocessor`의
"No AppIntents.framework" 경고는 전체 빌드에서만 나타나고 어떤 `.swift` 파일도 가리키지 않는다
(`hns-besir-app-verify` SKILL.md가 iOS 2건·macOS 1건으로 실측해 두었다). 총계를 기준으로 삼으면
소스가 깨끗해도 게이트가 붉게 보인다.

**`xcodegen generate`는 돌리지 않는다** — 새 소스 파일 0개(REQ-021)이므로 서명 계정 리셋도,
`besir-iOS`·`besirShare` 두 타깃의 Team 재선택 요청도 없다. `Tools/`는 빌드 대상이 아니라
`GuardDriver.swift`가 바뀌어도 마찬가지다. **이 문장이 지워져 있으면 새 파일을 만든 것이다.**

**드라이버 초록은 이 카드의 증거로 반만 센다.** `AIAssistant`의 인자 경로는 가드 안이지만, 좌표
사전은 뷰 상호작용으로 채워지고 드라이버는 SwiftUI 뷰를 컴파일하지 않는다. **"두 줄에 같은
이름의 다른 지점을 고른다"는 조작 자체가 가드 밖**이므로, AC-009가 대체 불가능한 증거다.
205/205 초록 다음 날 실기기 결함 7건이 나온 이력이 이 프로젝트에 있다(2026-09-15).

## 6. 후속 (본 SPEC 밖)

- **카드 t5** — 데드 코드 정리. 본 카드 done 이후. 본 카드가 두 파일의 줄번호를 밀므로 t5가
  plan에서 grep 재실측한다(이미 t5 카드 본문에 적혀 있다).
- **`Store` 수준의 출발지==도착지 검사** — `grep`이 0건인 사실은 확인됐으나 이 카드가 만든 결함이
  아니다(`spec.md` §3). 이 카드가 원인을 없애므로 남은 것은 별개 원인에 대한 판단이다.
- **`isSamePlace` 가드의 `create_recurring_schedule`·`create_activity` 확대** — 원인이 다른 결함이다
  (`spec.md` §3). 같은 수정으로 닫으면 어느 쪽이 닫혔는지 말할 수 없게 된다.
- **`EditCard.chooseTimePlain`의 소리 없는 `false` 기본값** — 루트 `plan.md` 후속 11번, D-2와 묶어
  판단. 이 카드는 `EditCard.swift`를 건드리지 않는다(REQ-021).
- **`ActivityDetailView:339`의 `.onChange(of: nearbyCategory)` 취소 부재** — 루트 `plan.md` 후속
  12번. 이 카드는 그 파일을 건드리지 않는다.
- **고른 장소의 주소 상시 표시** — 루트 `plan.md` 후속 7번. 되살린다면 화면이 아니라 컴포넌트에서다.

🗿 MoAI
