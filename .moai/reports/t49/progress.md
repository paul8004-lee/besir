# t49 진행 기록 — 편집 끝 시각 변경의 추정 복귀 구간 연계

카드 t49(B급 — run→sync, plan 생략, SPEC 없음). 리드 디스패치 2026-10-08.
본문: 활동 편집에서 끝 시각을 바꿀 때 반복 회차의 **추정** 복귀 구간이 따라오지 않는 기존 갭.
근거: SPEC-UIKIT-012 (바)항이 t43 카드 밖으로 미둔 편집 쪽 조각, 운영자 3차 답변("이 카드 밖,
별도 카드로")·원문 "이동과 편집이 연계되던 연결성 유지"의 편집 잔여분. 선행 t43 병합(afd36c3) 충족.

## 1. 원인

`modifyActivity`(Store.swift:311)가 끝 시각 변경 뒤 부르던 `realignReturnLeg`(수리 전 :352)은
`linkedActivityId` **명시 연결** 구간만 조회했다. 반복 회차의 구간은 명시 연결이 없어
`estimatedLegs`(recurrenceId + 장소 이름 + **정확한 앵커 시각** 대조, REQ-016 `anchorComparisonTime`)로
짝을 짓는데 — 편집이 일어난 시점엔 이미 `activities`에 **새** 끝이 저장돼 있어 "구간 출발 == 활동 끝"
대조가 옛 시각의 구간과 성립할 방법 자체가 없었다. 결과: 추정 복귀 구간은 제자리에 남고
짝(소유·배치 묶음)까지 깨져 단독 구간이 됐다. 자정과 무관하게 항상 그랬다(t43 이전부터).

## 2. 재현(수리 전 ✗ — 결함의 기록)

드라이버 t49절 T49-1~6을 **수리 전에** 먼저 쓰고 고치기 전 트리에서 실행(디스패치 ① 순서 준수).

명령(CLAUDE.md 레시피 그대로, 워크트리 루트에서):

```bash
cat Shared/EditCard.swift Shared/AIAssistant.swift Tools/GuardDriver.swift > /tmp/gd.swift \
  && swiftc -o /tmp/gd /tmp/gd.swift Shared/Store.swift Shared/Models.swift \
       Shared/Config.swift Shared/PlaceSearch.swift Shared/DirectionsService.swift \
       Shared/LocationManager.swift Shared/NotificationManager.swift \
       Shared/GoogleCalendarService.swift Shared/SharedInbox.swift -parse-as-library \
  && /tmp/gd
```

수리 전 출력(t49절 발췌 — 픽스처: rid 공유·명시 연결 없음·구간 출발 = 활동 끝):

```
  ✓ T49-1 편집 전 추정 복귀 구간(출발 = 활동 끝)은 짝이 성립한다
  ✗ T49-2 활동 끝 +30분 편집에 추정 복귀 구간이 통째로 따라온다(출발 = 새 끝)
  ✗ T49-3 편집 뒤에도 추정 짝·배치 묶음이 유지된다(대조 시각 = 새 끝)
  ✗ T49-4 출발 nil 추정 복귀 구간도 끝 편집을 따라온다(arrival = 새 끝, departure nil 유지) && 짝 유지
  ✓ T49-5 어긋난 추정 복귀 구간(출발 ≠ 활동 끝)은 끝 편집에 움직이지 않는다(바이트 동일)
525/528 통과
```

T49-1(양성 대조)·T49-5(회귀선)은 통과, 결함 3건(T49-2·3·4)이 ✗로 관측됐다.

## 3. 수리

파일 2개(디스패치 상한 준수) — `Shared/Store.swift`·`Tools/GuardDriver.swift`.

- **Store.swift `modifyActivity`**(:335 근처): 끝 시각을 쓰기 **전에** 복귀 구간 짝을 잡는다 —
  `let returnLegBefore = clearPlace ? nil : linkedLegs(for: updated).departure`.
  `linkedLegs`가 명시 우선·없으면 추정의 단일 출처(계약 5 — 짝 판정을 여기서 다시 쓰지 않는다).
  `clearPlace`면 잡지 않는다: 장소를 지운 활동의 구간은 존재할 수 없어 명시 짝이 지워지는데(REQ-004)
  추정 짝만 끝을 따라 옮기면 그 규칙과 어긋난다 → 장소 지우기 경로는 바이트 무변경.
- **Store.swift `realignReturnLeg`**(신규 :360): 캡처한 짝을 받아 변위를
  `anchorComparisonTime`(= departureDate ?? arrivalDate) 기준으로 잰다 — 출발 nil 회차(첫 추정
  실패 형태, t43 fix1-②와 같은 규칙)도 따라와 짝이 유지된다. 구현의 `departureDate` 직독은 삭제.
- **GuardDriver.swift**: t49절 T49-1~6 추가 6, 머리말 하한 523 → **529**(523 + 6).

`moveActivity` 무변경(카드 상한) — `git diff`로 확인: Store.swift 변경은 위 두 훅뿐.

## 4. 검증(수리 후, 이 트리에서 직접 실행)

- **드라이버(최종)**: 위와 같은 명령 → **`529/529 통과`**, exit 0, `[실제 데이터] 대조 통과`.
  T49 전부 ✓:

```
  ✓ T49-1 편집 전 추정 복귀 구간(출발 = 활동 끝)은 짝이 성립한다
  ✓ T49-2 활동 끝 +30분 편집에 추정 복귀 구간이 통째로 따라온다(출발 = 새 끝)
  ✓ T49-3 편집 뒤에도 추정 짝·배치 묶음이 유지된다(대조 시각 = 새 끝)
  ✓ T49-4 출발 nil 추정 복귀 구간도 끝 편집을 따라온다(arrival = 새 끝, departure nil 유지) && 짝 유지
  ✓ T49-5 어긋난 추정 복귀 구간(출발 ≠ 활동 끝)은 끝 편집에 움직이지 않는다(바이트 동일)
  ✓ T49-6 시작+끝을 함께 고치면 추정 복귀 구간은 새 끝에 정확히 붙는다(이동+잔차 한 번, 이중 이동 없음)
529/529 통과
```

- **iOS 빌드 무경고**(레시피 hns-besir-app-verify 그대로): `xcodebuild -scheme besir-iOS
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build` →
  exit=0, `BUILD SUCCEEDED`, 소스 경고 **0건**(appintentsmetadataprocessor 공지 필터 후).
  새 소스 파일 없음 → xcodegen 돌리지 않음(서명 리셋 회피). proxy는 무관(diff 미접촉).
- **code-safety 검토**(hns-besir-app-code-safety-specialist, 읽기 전용): **PASS — 차단 0건**.
  검토자가 드라이버를 독립 재실행해 528/528(당시) 재확인. 거짓 초록 검사 통과(t49절 단언은
  Store 관측값만 본다 — private 로직 복제 없음). H1~H5 전 등급 결함 없음, 캡처가 `linkedLegs`
  단일 출처를 읽는 점을 복제 계산 방지 준수로 확인. 잔여·후속은 §6 참조.

## 5. 이 변화가 깨는 문서 인용(실측 — 후속 재사상 카드로 넘김)

Store.swift가 순수 **+7줄**(349줄 이후 균일 — 랜드마크 실측: addLeg 488→495·realignLegs
608→615·deleteActivity 704→711·moveActivity 1388→1395). `Store.swift:NNN`(N ≥ 349) 인용이 전부 밀린다:

- CHECKLIST.md **58건**·plan.md **4건**(STATUS.md 0건)
- SPEC-UIKIT-012 (바)항의 `realignReturnLeg(:352-359)` 인용(신규 위치 :360-367)·카드 t49 본문 좌표

디스패치 파일 상한(Store.swift·GuardDriver.swift만)이 우선이라 이 카드에서는 고치지 않는다
(t44이 AIAssistant 인용을 전담하는 것과 같은 길). CHECKLIST 일부 좌표는 이미 이전 카드들에서
어긋나 있었다(예: realignLegs 인용 :581 vs 수리 전 실제 :608) — 재사상 카드는 원장 대조로 잡아야 한다.

## 6. code-safety 잔여·후속 카드 후보(이 카드 밖)

1. **AIAssistant.swift:2973** — `update_schedule` 완료 문구 "묶인 이동 구간도 같이 옮겼어요"의
   조건이 명시 연결만 본다. 이제 추정 짝도 움직이지만 문구에 안 나온다(동작은 올바르고 문구만 뒤처짐).
   파일 상한(AIAssistant 금지)으로 여기서 못 고침.
2. **moveActivity wholeSeries 교차 루프**(Store.swift:1404-1408) — 회차마다 조회→이동 교차.
   N5-1/AF-018-27이 `applyLinkedLegDrag`에서 "모아서 한 번씩"으로 수리한 형태가 남아 있다.
   일일 반복을 정확히 ±1440분 옮길 때 이중 이동 가능성(**가설 — 재현 안 함**). 카드 상한이
   moveActivity 불변이므로 미손.
3. **초 단위 newEnd**(잔여 위험) — realign 변위가 분 절사되므로 끝에 초가 남으면 추정 짝은
   정확 대조에서 깨져 단독이 된다(UI 피커는 분 단위, AI parseDate 경로만 해당). 후속 관찰 후보.

## 7. 시뮬레이터·실기기 확인(운영자 몫)

드라이버는 결정적 재현일 뿐 — 화면 흐름은 사람 확인이 필요하다. 추천 시나리오:
반복 일정(활동+이동) 회차 하나를 편집해 **끝 시각만** 늘리고 — 오는 이동 블록이 새 끝에 붙어
같이 내려가는지·묶음 표시가 유지되는지. t47 시나리오(S-1~S-12)와 같은 절차로 덧붙이면 된다.

## 8. 커밋·완료 신호

- 브랜치 `WT-edit-return-leg`(워크트리 .claude/worktrees/t49) — 병합·push **금지 준수**(리드 몫).
- 완료 신호: 브랜치명 + `(card t49)` 커밋 + 본 파일 경로(.moai/reports/t49/progress.md).
