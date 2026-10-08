# t51 sync 판정 — 2026-10-09

카드: t51(B급, SPEC 없음) · 브랜치 `WT-scroll-lock-fallback` 커밋 `d1fb4ff`(베이스 afd36c3) · 판정자: sync 레인(리드 재디스패치).
수리·병합·push 없음 — 판정만 한다.

## 판정: **PASS (차단 0건)**

단, 이 PASS는 **코드 구조와 빌드**에 대한 것이다. 이 변경이 실제로 자동 스크롤을 살리는지는 화면에서
봐야 아는 것이고, 나는 못 봤다(§5).

## 1. 점검 ① — diff는 주석 3 + 상수 1, 줄 수 불변 — 확인

```
$ git diff afd36c3..HEAD --numstat -- Shared/
4	4	Shared/ContentView.swift
$ git diff afd36c3..HEAD --stat
 .moai/reports/t51/code-safety.md |  55 +++
 .moai/reports/t51/progress.md    | 184 +++
 Shared/ContentView.swift         |   8 +-
```

`Shared/`는 `ContentView.swift` 하나, +4/−4(바뀐 줄이 주석 3개와 `:539` 상수 1개). 나머지 둘은 `.moai/` 보고서다.
줄 수가 같으므로 CHECKLIST·SPEC의 `file:line` 인용에 밀림이 없다.

## 2. 점검 ② — run의 독해를 코드에서 다시 읽음 — 일치

run 보고서를 옮겨 적지 않고 `Shared/ContentView.swift`를 직접 다시 읽었다(`:1146-1274`).

- 팬 끄기 **1곳**: `:1197` `scroll.panGestureRecognizer.isEnabled = false`(`startAutoScrollIfNeeded` 안, `panLockFallback` 가드 아래).
- 되돌리기 **1곳**: `:1257` `= true`(`stopAutoScroll` 안, `panWasDisabled` 가드 아래).
- 전수 grep:
  ```
  $ grep -rn "panGestureRecognizer" Shared/
  Shared/ContentView.swift:1197:   scroll.panGestureRecognizer.isEnabled = false
  Shared/ContentView.swift:1257:   scroll.panGestureRecognizer.isEnabled = true
  ```
  양성 대조: 이미 알던 두 줄이 정확히 그 둘로 잡혔고, 그 밖의 다른 곳에서 팬을 건드리는 코드는 없다.
- 끝 경로 6개 — `stopAutoScroll()` 호출처 전수(`grep -n "stopAutoScroll()"`): `:1069`(창 이탈 클로저)·`:1088`(`dismantleUIView`)·`:1156`(onBegin 거절)·`:1168`(`.ended`)·`:1172`(`.cancelled/.failed`)·`:1219`(틱의 인식기 상태 검사), 그리고 `:1214`(틱의 대상 소실 가드)는 같은 함수로 가는 일곱 번째 호출이다. 정의는 `:1255` 하나.
  run이 센 6개와 같고, `:1214`는 run이 세지 않은 보조 경로(스스로 멈춤)로 무해하다.
- `stopAutoScroll`은 멱등: 두 번째 호출에서는 `panWasDisabled` false, `dragScrollView` nil이라 아무 일도 안 한다.
  `panWasDisabled`는 `dragScrollView`가 nil이 아닌 같은 블록(`:1193-1199`)에서만 true가 되므로
  "팬은 꺼졌는데 스크롤 뷰를 잃어 복구 못 함" 모양이 성립하지 않는다.
- `CADisplayLink` 생성처는 `:1202` 하나, 프록시가 코디네이터를 약한 참조로 잡아 순환 참조가 없다(`:1020-1028`).

## 3. 점검 ③ — 소유 없는 구간·활동 드래그는 계속 잠긴다 — 확인

`:530-534`:

```swift
guard let drag = activeDrag else { return false }
if Self.usesPanLockFallbackForOwnedLegDrag && drag.owner != nil { return false }
return true
```

스위치가 true여도 잠금이 풀리는 것은 `drag.owner != nil`(소유 있는 구간)뿐이다. 활동 드래그
(`owner = nil`, `:477-479`)와 소유 없는 구간 드래그는 `return true` → `:525` `.scrollDisabled(true)`가 그대로 걸린다.
팬 끄기 쪽 입장도 같은 선이다 — `autoScrollEligible: { activeDrag?.owner != nil }`(`:506`)이 `:1189` 가드로 들어간다.
즉 두 곳이 같은 조건(소유 유무)을 읽어서, 소유 없는 드래그에서는 팬도 안 꺼지고 `scrollDisabled`도 그대로다.
`scrollDisabled` 사용처 전수(`grep -rn scrollDisabled Shared/`): 코드는 `:525` 한 곳, 나머지는 주석.
스위치 사용처 전수: `:507`·`:523`(주석)·`:532`·`:539`(선언) — 숨은 독자 없음.

## 4. 점검 ④ — code-safety 정보 1~4 중 카드 안에서 고칠 것 — 없음

| 정보 | 내용 | 이 카드에서 고칠까 | 이유 |
|---|---|---|---|
| 1 | 코디네이터가 `stopAutoScroll` 없이 해제되면 팬이 영구 꺼짐 | **아니오** | 재현 경로가 없다(`dismantleUIView`·창 이탈이 조상 해제의 전부이고 둘 다 멈춤 함수 호출). 보강하려면 프록시에 복구 대상 약한 참조를 넘기는 코드가 필요해 상수 1개 + 주석 3줄 범위를 넘는다. 후속 카드 후보로만 남긴다. |
| 2 | 대체안이 한 프레임 먼저 잠김 | 해당 없음 | 유리한 차이. |
| 3 | 드래그 중 `UIScrollView` 인스턴스 교체 시 자동 스크롤만 조용히 죔 | **아니오** | t43부터 있던 구조, 이 diff가 만든 것이 아님. |
| 4 | 주석 사실관계가 관측 기록과 일치 | 해당 없음 | 통과. |

**내가 더한 정보 5(수리 안 함)**: 본안에서는 소유 구간 드래그의 잠금이 `.scrollDisabled`라 스크롤 뷰를 찾는 데
의존하지 않았다. 대체안에서는 잠금이 `nearestScrollView`(`:1140`) 성공에 달려 있다 — 못 찾으면(`dragScrollView == nil`)
팬이 안 꺼지고 `scrollLockedDuringDrag`도 false라 **소유 구간 드래그가 잠금 없이** 돌고 자동 스크롤도 안 돈다(틱이 `:1213`에서 스스로 멈춤).
충돌·유실은 아니고 "끌면서 시간표가 같이 스크롤되는" 열화다. 같은 올라가기(`ScrollTouchFixView` `:1009-1013`)가 이미 탭 수리에
쓰이고 있어 도달성은 있다고 보지만, **런타임에서 실제로 찾는지는 내가 못 봤다.** 운영자 재확인에서 "소유 구간을 끌 때 시간표가
손가락과 함께 밀려나가는" 모양이 보이면 이것이다.

주석 낡음 점검(상수 외 문구): `:1194-1196`의 "S-16이 어느 쪽인지 정한다"는 아직 사실이다(판정 대기 중). 낡은 서술 없음 — 고칠 것 없음.

## 5. 못 본 것 (못 봤다고 적는다)

- **화면 동작 전부.** 팬 끄기가 `setContentOffset`을 살려 시간표가 실제로 내려가는지, 놓은 뒤 팬이 돌아와 손가락 스크롤이
  다시 되는지 — 나는 시뮬레이터를 돌리지 않았다. 이 diff는 "본안의 `.scrollDisabled`가 프로그램 오프셋을 막는다"는 **가설**에
  거는 내기이고, 가설이 맞는지는 코드 읽기로 알 수 없다(`UIScrollView` 문서에도 이 상호작용의 명시가 없다).
- **디스패치가 인용한 "S-6 움직임, S-16 잘 멈춤, S-17 잘 작동"을 디스크에서 찾지 못했다.** `.moai/reports/t43/sim-result-20261008.md`는
  52줄이고 §4는 "S-9·S-10 재확인과 큐 정리"까지다. `grep "잘 멈춤\|잘 작동\|움직임"`이 잡는 것은 S-18 "잘 작동"과
  S-10 "안움직임"뿐이다. 이 판정은 그 관측에 **기대지 않았다.** 관측이 맞다면 가설이 선 것이니 리드가 운영자 원문을 디스크
  (예: 같은 파일 §5 또는 t51 보고서)에 남기길 권한다 — 병합 근거가 채팅에만 있으면 낡는다.
- 드라이버(`Tools/GuardDriver.swift`)는 UIKit 제스처·스크롤을 못 다룬다(plan.md D-11) — 해당 없음, 돌리지 않았다.
- macOS 빌드: iOS 전용 정책으로 돌리지 않았다. `proxy/`: diff가 건드리지 않아 돌리지 않았다.

## 6. 재현 명령과 출력

**iOS 빈 캐시 빌드**(빈 폴더 확인 후 빌드, 로그 `.moai/state/verify/t51-sync/build-ios.log`):

```
$ mkdir dd-t51-empty && ls -A dd-t51-empty | wc -l
0
$ xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath dd-t51-empty build
exit=0 · ** BUILD SUCCEEDED **
```

- 캐시가 비었던 것의 관측: 로그 947줄, `CompileSwift`/`SwiftCompile` 줄 42개 — 컴파일 0줄이 아니다.
- 경고: `grep "warning:" | grep -v appintentsmetadataprocessor | sort -u | wc -l` → **0**.
  남은 `warning:` 2줄은 `appintentsmetadataprocessor` "Metadata extraction skipped"(앱에 AppIntents 의존이 없다는 도구 안내).
- `grep -c "error:"` → 0.

**master 충돌**(master는 t49 병합으로 `d53d980`):

```
$ git merge-tree --write-tree master HEAD
3ee9539f743d331c51d8d616ba4cbe0e832e7a22   (exit=0, 충돌 표시 없음)
```

리드가 먼저 확인한 "충돌 없음"과 같다.

## 7. 정리

| 항목 | 결과 |
|---|---|
| ① diff 주석 3 + 상수 1, 줄 수 불변 | ✅ 확인 |
| ② 팬 끄기·되돌리기 각 1곳, 끝 경로 | ✅ 직접 재독해, run과 일치 |
| ③ 소유 없는 구간·활동 드래그 잠금 유지 | ✅ `:530-534` + `:506` |
| ④ 정보 1~4 중 카드 안에서 고칠 것 | 없음 (정보 5 추가, 수리 안 함) |
| iOS 빈 캐시 빌드 | ✅ 무경고·오류 0 |
| master 병합 충돌 | ✅ 없음 |
| 화면 동작 | ❌ 못 봄 — 운영자 몫 |

병합 판단은 리드 몫이다. 이 판정서는 코드 구조·빌드·충돌만 보증하고, 자동 스크롤이 실제로 도는지는
운영자 재확인(S-6·S-16·S-17, 그리고 놓은 뒤 손가락 스크롤 복귀)이 판정한다.
