# t51 code-safety 검토 — 2026-10-09

검토자: hns-besir-app-code-safety-specialist(opus) · 대상: `WT-scroll-lock-fallback` diff
(`Shared/ContentView.swift` 상수 1개 + 주석 3행) · hns-besir-app-contracts·hns-besir-app-hazards
스킬 로드 후 검토. 이하는 검토 보고 전문(레인이 받은 그대로 보존).

---

# t51 코드 안전성 검토 — `usesPanLockFallbackForOwnedLegDrag` false→true (Shared/ContentView.swift:539)

판정 요약: **차단 0건**. 휴면 경로를 깨우는 스위치 전환이지만, 전환으로 새로 살아나는 경로(팬 인식기 끄기·되돌리기)의 시작·끝이 기존 드래그 수명 주기에 정확히 묶여 있고, 끝 경로 6곳이 모두 `stopAutoScroll`을 지난다는 AC-016 구조가 이번 전환에도 성립한다. 아래는 권고 0건·정보 4건.

## 발견 (심각도순)

### 1. 정보 — 코디네이터가 `stopAutoScroll` 없이 사라지면 팬이 영구 꺼진다 (재현 경로 없음, 의심 단계)
- **어디**: Shared/ContentView.swift:1025 (`AutoScrollProxy.tick`의 nil-target 분기), 대비 1197-1198(끄기)·1256-1259(되돌리기).
- **무엇**: 팬을 되돌리는 유일한 상태(`panWasDisabled`·`dragScrollView`)는 코디네이터만 가진다. 코디네이터가 링이 살아 있는 채 해제되면 프록시가 링만 끊고(1025) 팬 복구는 아무도 못 한다 — 시간표 스크롤이 앱 재시작까지 죽는다.
- **깨지는 조건**: SwiftUI가 `dismantleUIView`(1085)도, 창 이탈 `onLeaveWindow`(1003)도 부르지 않고 코디네이터를 해제하는 경우. 두 경로가 문서상 조상 해제의 전부이고 둘 다 `stopAutoScroll`을 호출하므로 **구체적 재현 경로를 나는 대지 못했다** — 정의상 "의심"이지 결함이 아니다. 방어 보강은 값싸다: 끌 때 프록시에 `weak var panRestoreTarget`을 넘기고 nil-target 분기에서 되돌리게 하면 된다. 단 이번 카드 범위(상수 1개)를 넘는다 — 후속 카드 후보로만 기록 권장.
- **확신**: 의심(구체적 interleaving 없음).

### 2. 정보 — 팬 끄기가 기존 대비 *먼저* 잠긴다 (유리한 차이, 결함 아님)
- **어두**: Shared/ContentView.swift:1151→1159(동기) 대비 479(상태 설정)→525(다음 렌더에 적용).
- 본안은 `activeDrag` 설정 뒤 SwiftUI 다음 렌더에서 `.scrollDisabled`가 붙는다(한 프레임 늦음). 대체안은 `.began` 안에서 동기로 팬을 끈다. 두 잠금이 함께 풀려 있는 창은 없다 — `onBegin`(activeDrag 설정)과 `startAutoScrollIfNeeded`(팬 끄기)가 같은 동기 블록(1149-1159)에서 실행돼 유저 이벤트가 끼어들 수 없고, `.ended`에서도 `stopAutoScroll`(1168)이 `onEnd`(1169)보다 먼저 같은 동기 블록에서 돈다. 결함 없음.

### 3. 정보 — 잡힌 `dragScrollView`가 드래그 중 교체되면 자동 스크롤이 조용히 죽는다 (t43 이전 구조, 이번 전환으로 새로 생긴 것 아님)
- **어두**: Shared/ContentView.swift:1192(시작 시 1회 포획)·1213(틱이 포획 뷰에 쓴다)·1256(같은 참조에 되돌림).
- 드래그 중 뷰 계층 재구성이 UIScrollView 인스턴스를 갈아끼우면 틱의 `setContentOffset`이 떨어져 나온 옛 뷰에 쓰여 자동 스크롤만 소리 없이 멈춘다. 다만 이 그림에서 **새 뷰의 팬은 꺼진 적이 없으므로 팬 걸림은 생기지 않는다**. 이 경로는 t43의 틱 설계부터 있던 것이고 이번 diff가 만든 것이 아니며, 연장(hourCount 증가)은 같은 인스턴스에서 contentSize만 키우므로 실제로 닿기 어렵다.
- **확신**: 코드 읽음(결함 경로는 이론적·사전 존재).

### 4. 정보(통과) — 재작성된 주석의 사실 관계는 관측 기록과 일치한다
- Shared/ContentView.swift:536-538의 "운영자가 S-6·S-16·S-17에서 본안일 때 자동 스크롤이 시간표를 움직이지 않는 것을 관측" — /Users/iseongmin/Projects/besir/.moai/reports/t43/sim-result-20261008.md 9-14행(S-6 "내려가는 것이 보이지 않음", S-16①~④·S-17 "시간표가 움직이지 않음")과 일치. 같은 문서 35행은 S-16②③④·S-17이 독립 관측이 아니라고 단서를 달지만, 주석은 독립성을 주장하지 않으므로 모순 없다. "재확인이 판정한다"는 미결 상태를 정확히 못박은 표현이다.

## 렌즈별 결과

**1) 팬 복구 완전성 — 통과.** 끝 경로 6개 전수 확인: `.ended`/`.cancelled`/`.failed`(1167-1174), onBegin 거절(1152-1157 — 이 경로는 시작 전이므로 `panWasDisabled`가 거짓, no-op), `dismantleUIView`(1085-1089), 창 이탈(1003-1007→1069), 틱 인식기 상태 검사(1218-1220). 시스템 제스처 중단(컨트롤 센터 등)·앱 전환은 인식기 `.cancelled`로 수렴하고, 놓친 경우라도 틱의 상태 검사가 같은 틱에 잡는 이중 방어. `stopAutoScroll`은 멱등(재호출 시 `panWasDisabled` 거짓·링 nil). `dragScrollView`는 강한 참조라 드래그 중 해제될 수 없고 `stopAutoScroll`에서 nil 처리(1265). `updateUIView`(1091-1098)는 상수를 다시 밀 뿐 잠금을 다시 걸지 않는다(시작은 `displayLink == nil` 가드가 있는 `startAutoScrollIfNeeded`에서만). 첫 드래그가 다 풀리기 전 두 번째 드래그: `.ended`에서 판이 이미 복구된 뒤 `.began`이 다시 끄는 순서만 있고, 이전 `stopAutoScroll`의 0.1초 지연 클램프(1268)는 실행 시점의 contentSize를 다시 읽으므로(1269) 새 드래그와 충돌하지 않는다. 유일한 구멍이 1번(정보).

**2) 잠금이 더는 안 덮는 것 — 유해한 신규 경로 없음.** 두 번째 손가락 팬: 스크롤 뷰의 팬 인식기는 뷰에 하나뿐이고 `isEnabled=false`는 모든 터치에 적용되므로 본안과 같거나 더 강하다. 좌우 하루 넘김: `SwipePager`는 `isLocked: activeDrag != nil`(415·339)로 두 모드 같다. 러버밴딩·관성: 유저 구동 팬 자체가 막혀 없고, 드래그 직전 플릭의 감속은 팬이 꺼지는 순간 멈춘다(본안의 `.scrollDisabled` 적용과 같은 결과, 시점만 한 프레임 빠름). 드래그 중 두 번째 손가락 탭으로 블록 선택되는 것은 오버레이의 탭 인식기(1180) 때문이며 `.scrollDisabled`와 무관 — 본안에서도 똑같다(기존 동작). 틱의 오프셋 계산(1229-1247)에 영향을 주는 신규 입력 경로 없음.

**3) 조용한 실패·상태 증가 — 통과.** CADisplayLink 순환 참조는 구조적으로 차단(링→프록시 강한, 프록시→코디네이터 약한, 코디네이터→링 강한 — 순환 없음, 1017-1028 확인). 상태는 링·인식기·스크롤 참조·플래그 넷뿐이고 `stopAutoScroll`에서 전부 nil/초기화(1262-1266). 무한 증가 상태 없음. H2에 해당하는 것은 3번의 조용한 no-op뿐(사전 존재).

**4) 복제 계산·죽은 코드 — 통과.** `scrollLockedDuringDrag`(530-534)는 SwiftUI 쪽 잠금의 단일 출처로 유지되고, 본안의 소유 드래그 분기가 죽은 것은 주석이 명시하는 롤백 스위치라 의도된 사망(되돌림 경로 보존). 이 전환으로 *그 외에* 새로 죽은 것 없음 — `.scrollDisabled`(525)는 활동·소유 없는 구간 드래그에서 여전히 산다. spec §3 불변(spec.md:202)과 코드(532) 대조 일치.

**H1/H5-H8 — 해당 없음.** diff에 await·Task·try? 없음(H1·H2·H5), 통지·할당량 없음(H3), 기하·날짜 중복 계산 없음(H4·H7), AI 인자 불변(H6·H8). `usesPanLockFallbackForOwnedLegDrag` 사용처 3곳(507·532·539) 전수 확인 — 숨은 독자 없음.

**스코프·문서 — 통과.** diff는 상수 1개+주석 3행(줄 수 동일, 인용 무드리프트 확인). SPEC/plan 어디에도 "기본값 false" 서술이 없다(plan.md:133·spec.md:202·plan.md:142는 대체안을 조건부로 서술 — 전환 후에도 낡지 않음).

## 검증 증거 (관찰한 것)
- 빌드: 재실행하지 않음(지시). 레인의 로그 .moai/state/verify/t51/build-ios.log를 읽어 확인 — `** BUILD SUCCEEDED **`, `warning:` 2건 모두 appintentsmetadataprocessor 공지(540·897행), Swift 소스 경고 0.
- 코드: diff 전문, ContentView.swift 410-539·993-1284, 활성 드래그 수명 주기(activeDrag 설정 479·해제 495 단일 쌍), SPEC-UIKIT-012 spec.md:202·plan.md:133/142/232·progress.md 관련 행, 시뮬레이터 관측 기록 .moai/reports/t43/sim-result-20261008.md.

## 검사하지 않은 것 (미검증 = 미검증)
- **런타임 동작 전반** — 시뮬레이터·실기기를 돌리지 않았다. 스위치의 실제 효과(팬 끄기가 프로그램 오프셋을 살리는지, 드래그 감각·튀어 오름)는 운영자 재확인 S-6·S-16·S-17이 판정한다. 코드 읽기로는 "막힌 팬과 setContentOffset의 상호작용"조차 여전히 문서 부재 영역이다 — 이 검토는 경로 완결성만 담보한다.
- **GuardDriver 단언** — D-11(plan.md 참조)대로 이 영역을 커버하지 못한다. 확인 안 함.
- **macOS 빌드** — 2026-09-30 iOS 전용 정책으로 검증 중단. 돌리지 않았다.
- **proxy·Store·공유 확장** — 이 diff가 안 건드린 영역. 읽지 않았다.
