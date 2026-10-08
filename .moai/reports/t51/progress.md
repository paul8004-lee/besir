# t51 진행 기록 — 가장자리 자동 스크롤 대체안 상수 수리

카드: t51(B급 — run→sync, plan 생략, SPEC 없음) · 브랜치 `WT-scroll-lock-fallback`(베이스 afd36c3 = t43 병합) · 리드 디스패치 2026-10-08, 레인 실행 2026-10-08~09.
워크트리: `.claude/worktrees/t51` · 운영자 승인: 2026-10-08 "상수 수리 먼저, S-9·S-10은 그 뒤 재확인".

## 0. 가드

- `echo $MOAI_KANBAN_LABEL` → `run` — 디스패치 조건 충족.
- 진입 시 주 체크아웃(master) 소속 → ExitWorktree 불필요. `EnterWorktree(t51)`로 트리 생성 후 `git branch -m WT-scroll-lock-fallback`.
- 베이스 확인: `git rev-list --count --left-right origin/master...HEAD` = `0 0`(양쪽 다 afd36c3) — t43 병합 포함, 분기 없음.

## 1. 폴백 경로 읽기 결과(변경 전 — 카드 본문이 요구한 순서)

좌표는 전부 `Shared/ContentView.swift`(워크트리 베이스 afd36c3 기준). 이 경로는 이 변경 전까지
**한 번도 실행된 적 없다**(`usesPanLockFallbackForOwnedLegDrag`가 항상 false였으므로).

### 1-1. 팬 인식기를 끄는 곳 — 한 곳

`startAutoScrollIfNeeded` `:1188-1206`, 그중 `:1193-1199`:

```swift
if panLockFallback, let scroll = dragScrollView {
    scroll.panGestureRecognizer.isEnabled = false
    panWasDisabled = true
}
```

- 진입 가드 `:1189`: `guard displayLink == nil, didBegin, autoScrollEligible() else { return }`.
  `autoScrollEligible`는 ContentView가 준 클로저 `:506` — `activeDrag?.owner != nil`, 즉 **소유 있는
  구간 드래그에서만** 팬이 꺼진다(Q-9).
- `dragScrollView = nearestScrollView(from: gr.view)` `:1192` — 드래그 시작 때 조상 UIScrollView를
  한 번 찾아 둔다.
- 호출 지점: 롱프레스 `.began` `:1159`과 `.changed` `:1166`. `displayLink == nil` 가드로 멱등이라
  두 번 불려도 팬은 한 번만 꺼진다.

### 1-2. 되돌리는 곳 — 한 곳

`stopAutoScroll` `:1255-1274`, 그중 `:1256-1259`:

```swift
if panWasDisabled, let scroll = dragScrollView {
    scroll.panGestureRecognizer.isEnabled = true
    panWasDisabled = false
}
```

주석 `:1196`이 선언하듯 "되돌리는 곳은 멈춤 함수뿐이다". 복구 판정은 `panWasDisabled`/
`dragScrollView` 상태만 읽고 `panLockFallback` 플래그를 다시 보지 않는다 — 드래그 중 플래그가
바뀌어도(실제로는 `let` 상수라 불가능) 복구는 이루어진다. `panWasDisabled`는 `dragScrollView`가
nil이 아닌 같은 블록에서만 세워지므로 "팬은 꺼졌는데 스크롤 뷰를 잃어 복구 못 함" 모양은 성립하지
않는다. `stopAutoScroll`은 멱등이다(두 번째 호출: `panWasDisabled` 이미 false, `dragScrollView` 이미 nil).

### 1-3. 멈춤 함수에 도달하는 끝 경로 — 6개 전부 확인

| # | 경로 | 좌표 | 타이머·팬 복구 | onEnd(activeDrag 정리) |
|---|---|---|---|---|
| 1 | 드래그 정상 종료 `.ended` | `:1167-1170` | ✅ | ✅ onEnd(true) → ContentView `:493-497` activeDrag=nil |
| 2 | 제스처 중단·시스템 취소 `.cancelled`/`.failed` | `:1171-1174` | ✅ | ✅ onEnd(false) |
| 3 | onBegin 거절(블록 밖 시작 — 아직 켠 것 없음) | `:1152-1157` | ✅(무해) | — (activeDrag 미설정) |
| 4 | SwiftUI가 오버레이를 치움 `dismantleUIView` | `:1085-1089` | ✅ | ❌ **호출 안 함** |
| 5 | 창 이탈(앱 전환 등) `didMoveToWindow` window==nil → `onLeaveWindow` | `:1003-1007` → `:1069` | ✅ | ❌ **호출 안 함** |
| 6 | 틱 안 인식기 상태 검사(.began/.changed 밖 = 이벤트 없는 취소) | `:1218-1220` | ✅ | ❌ **호출 안 함** |

## 2. focus ①②③ 답변(디스패치 지시 — 읽은 결과만)

**① true일 때 팬 인식기를 끄는 곳과 되돌리는 곳(드래그 종료·취소·앱 전환·제스처 중단 복구)**
끄는 곳·되돌리는 곳이 각각 정확히 하나씩이고(§1-1·§1-2), 식별 가능한 끝 경로 6개가 전부 멈춤
함수를 지난다(§1-3). **팬 인식기 복구의 코드상 누락 경로는 찾지 못했다.** 4·5·6은 onEnd를 부르지
않지만 팬 복구에는 영향이 없다(onEnd는 activeDrag 정리 몫).

**② 활동·소유 없는 구간 드래그는 계속 스크롤 잠금인지**
그렇다. `scrollLockedDuringDrag` `:530-534`는 스위치가 true여도 `drag.owner != nil`(소유 구간)일
때만 false(잠금 면제)를 돌려주고, 활동 드래그·소유 없는 구간 드래그는 `.scrollDisabled(true)`
`:525`가 그대로 걸린다. 팬 끄기 진입 조건(`autoScrollEligible` `:506`·`:1189`)도 소유 드래그만
허용한다 — 뷰 계산(`:532`)과 오버레이 가드(`:1189`)가 같은 선을 긋는다. 이는 SPEC-UIKIT-012
spec.md §3 불변(`:202` — grep 실측 "소유 구간 드래그가 D-11 대체안으로 바뀌어도 활동 블록 드래그와
소유 없는 구간 드래그의 .scrollDisabled 잠금은 그대로다")과 일치한다.

**③ 복구 누락이 S-9·S-10 첫 실패(스크롤 잠금 잔류 가설)와 이어지는지**
이 경로에서 찾은 유일한 복구 누락은 팬이 아니라 **activeDrag 잔류**다 — 경로 4·5·6은 타이머와
팬은 복구하지만 onEnd를 부르지 않아 ContentView.activeDrag가 nil로 안 지워질 수 있다. 본안(false)에서는
이 잔류가 `scrollLockedDuringDrag` 계속 참 = `.scrollDisabled(true)` 지속으로 나타나며, 증상은
"손가락 스와이프로 시간표가 안 굴러감"이다(다음 드래그의 onBegin이 activeDrag를 덮어쓰고 그
드래그의 onEnd가 지우기까지 지속).
그러나 **S-9·S-10의 증상과는 모양이 다르다**: S-9(이동·활동 블록이 아예 안 움직임, 재확인
"들려서 끌렸는데 놓으니 제자리")·S-10(첫 시도 안 움직임, 재시도엔 움직임)은 "드래그·커밋 불능"이지
"시간표 스크롤 죽음"이 아니다. 읽은 코드로는 스크롤 잠금(본안 scrollDisabled 잔류든 대체안 팬
잔류든)이 드래그 자체를 막는 메커니즘이 없다 — 드래그는 오버레이 고유의 롱프레스 인식기에서
돌고(`:1146-1178`), 미리보기 이동은 onChange → deltaMinutes 순수 SwiftUI 상태(`:482-492`)다.
S-9의 "끌렸는데 놓으니 제자리"는 커밋 경로(onEnd(true) && deltaMinutes != 0 → finalizeDrag
`:496`)에서 유효 Δ가 0으로 잘렸거나(`:488-490` effectiveDragMinutes) finalize 내부 문제여야 하는데,
그 판정에는 재현이 필요하다 — **이 카드는 기록만 하고 수리는 카드 밖**(디스패치 limits 그대로).

덧붙여: 대체안이 켜지면 소유 구간 드래그는 아예 `.scrollDisabled`를 안 쓰므로, 소유 구간에 한해서는
위 activeDrag 잔류 계열의 "스크롤 죽음" 증상 자체가 사라진다(팬은 멈춤 함수가 되돌린다).

## 3. 변경

```diff
-    /// D-11 대체안 스위치. 기본(false)은 `.scrollDisabled`를 그대로 쓰는 본안 — scrollDisabled가
-    /// 프로그램 오프셋 setContentOffset까지 막는지는 확인되지 않았다(가설). 시뮬레이터 S-16이
-    /// 본안이 안 움직인다고 보이면 이 값을 true로 바꿔 소유 구간 드래그만 팬 인식기 끄기로 돌린다.
-    private static let usesPanLockFallbackForOwnedLegDrag = false
+    /// D-11 대체안 스위치. true는 2026-10-08 t51의 선택 — 운영자가 S-6·S-16·S-17에서 본안
+    /// (.scrollDisabled)일 때 자동 스크롤이 시간표를 움직이지 않는 것을 관측했다. 팬 끄기가
+    /// 프로그램 오프셋을 살리는지는 운영자 재확인(S-6·S-16·S-17)이 판정한다.
+    private static let usesPanLockFallbackForOwnedLegDrag = true
```

- 파일: `Shared/ContentView.swift` 한 곳, 4줄(주석 3 + 상수 1). **줄 수 변화 없음** → CHECKLIST·SPEC
  문서 인용(file:line)에 밀림 없음.
- 참조 조사: `usesPanLockFallbackForOwnedLegDrag`는 이 파일 안 3곳(`:507`·`:523` 주석·`:532`)과
  선언뿐이고, 문서 참조는 t43 run-progress.md(시점 기록 — 수정하지 않음)뿐이다.
- 하네스 명단(카드 착수 규칙): **code-safety**(구현을 바꿈 — 디스패치가 명시적으로 요구) 1명.
  swift-impl은 걸릴 조건이지만 단일 상수 뒤집기라 카드가 요구한 "경로 끝까지 읽기"를 마친 뒤
  레인이 직접 수행했다 — 스폰하면 검토 대상이 늘어날 뿐이라고 판단(기록으로 남긴다).
  ui-design·ux-check·ai-tooling은 이 diff가 건드리는 영역이 아니다.

## 4. 검증

### 4-1. iOS 빌드(무경고 게이트) — 관측됨

명령(레시피 hns-besir-app-verify 그대로):

```
xcodebuild -scheme besir-iOS \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath build build > .moai/state/verify/t51/build-ios.log 2>&1
```

결과: `exit=0` · `BUILD SUCCEEDED` · 경고 필터(`grep "warning:" | grep -v appintentsmetadataprocessor
| sort -u`) 출력 **빈 줄 0건**. 로그: `.moai/state/verify/t51/build-ios.log`.

### 4-2. 드라이버 — 대상 아님(근거와 함께 미실행)

- D-11이 명시한다(plan.md:145): "드라이버가 못 하는 것: 이 전부(UIKit 제스처·스크롤·타이머·SwiftUI
  배치). 구조 대조(AC-013·016)와 시뮬레이터(S-6·S-16·S-17)가 맡는다."
- ContentView.swift는 드라이버 컴파일 단위(`EditCard`+`AIAssistant`+`GuardDriver`+Store 계열,
  CLAUDE.md 레시피)에 없다 — 이 상수는 드라이버에 보이지 않으므로 단얱할 것도 영향받을 것도 없다.
  GuardDriver.swift를 고칠 내용도 없다(디스패치 limits: "드라이버로 단언 가능한 부분만").

### 4-3. 프록시 — 대상 아님

diff가 `proxy/`를 건드리지 않는다. `cd proxy && npm test`는 프록시 변경·배포 전 게이트다.

## 5. code-safety 검토

검토자: `hns-besir-app-code-safety-specialist`(contracts·hazards 스킬 로드 후 검토, 2026-10-09).
**판정: 차단 0건 · 권고 0건 · 정보 4건** — 전문 보존: `.moai/reports/t51/code-safety.md`.

- **정보 1** — 코디네이터가 `stopAutoScroll` 없이 해제되면 팬이 영구 꺼진다(`:1025` nil-target 분기가
  링만 끊음). 단 그럴 수 있는 경로가 발견되지 않았다(조상 해제의 문서상 전부인 `dismantleUIView`·창
  이탈 둘 다 멈춤 함수를 부름) — 재현 경로 없는 의심 단계. 방어 보강(프록시에 약한 복구 대상 넘기기)은
  이 카드 범위 밖 — **후속 카드 후보로만 기록**.
- **정보 2** — 대체안은 본안과 달리 `.began` 안에서 **동기로** 팬을 꺼서 잠금이 한 프레임 더 빠르다.
  두 잠금이 함께 풀려 있는 창은 없다(유리한 차이).
- **정보 3** — 드래그 중 뷰 계층이 UIScrollView 인스턴스를 갈아끼우면 자동 스크롤이 조용히 죈다
  (`:1192` 시작 시 1회 포획). t43 설계부터 있는 이론적 경로이고 이 diff가 만든 것이 아니며, 그 그림에서도
  새 뷰의 팬은 꺼진 적이 없어 팬 걸림은 생기지 않는다.
- **정보 4** — 재작성된 주석의 사실 관계가 sim-result-20261008.md 9-14행 관측 기록과 일치(독립성
  주장 없음 — 35행 단서와 모순 없음).

렌즈별: 팬 복구 완전성(끝 경로 6개 전수·멱등·강한 참조·이중 방어) 통과 · 잠금 공백(두 번째 손가락·
러버밴딩·관성·좌우 넘김 — 유해한 신규 경로 없음) 통과 · 조용한 실패·상태 증가(링 순환 참조 구조적 차단) 통과 ·
복제 계산·죽은 코드(롤백 스위치로서의 의도된 사망만) 통과 · H1/H5-H8 해당 없음 · 스코프·문서(SPEC에
"기본값 false" 서술 없음 — 전환 후에도 낡지 않음) 통과.

검토자가 명시한 미검증: 런타임 동작 전반(운영자 S-6·S-16·S-17 재확인 몫 — "막힌 팬과
setContentOffset의 상호작용"은 문서 부재 영역) · GuardDriver(D-11대로 커버 불가) · macOS 빌드
(iOS 전용 정책) · proxy·Store·공유 확장(diff 미접촉 영역).

## 6. 관측 못 한 것(운영자 몫 — 못 했다고 적는다)

- **화면 동작 전부**: S-6·S-16 ①~④·S-17(자동 스크롤이 시간표를 내리는지), S-9·S-10 재시도(스크롤
  잠금 잔류 가설 재확인). 팬 끄기가 프로그램 오프셋 setContentOffset을 살리는지는 여전히 관측되지
  않았다 — 이 카드의 변경은 그 가설의 판정 재료를 만드는 것뿐이다.
- 실기기·시뮬레이터 설치: 디스패치 지시대로 하지 않았다(리드가 검증 뒤 설치).
- 런타임에서 팬이 실제로 꺼지는지(UIKit 계층의 실 스크롤 뷰 도달 여부) — 코드 읽기로만 확인.

## 7. 상태

- 커밋: 이 문서와 함께 `Shared/ContentView.swift` + 본 파일 (card t51) — 병합·push **안 함**(디스패치 limits).
- 남은 관문: 리드가 evidence를 읽고 시뮬레이터 설치 → 운영자 S-6·S-16·S-17 재확인 + S-9·S-10 재시도.
  그래도 안 움직이면 카드 본문의 대안(12시 밑으로 내리면 다음 날 표 자동 표시)을 검토.
