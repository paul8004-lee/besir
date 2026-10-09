# t58 진행 기록 — 연결 없는 반복 회차 편집 저장의 장소 유실(clearPlace)

카드 t58(B급 — run→sync, SPEC 없음, 재현 먼저). 워크트리 `.claude/worktrees/t58`,
브랜치 `WT-recur-edit-place`, 베이스 master `a5b8de6`(t49 병합 d53d980 포함).
운영자 승인 2026-10-09("t58로 올리고 바로 착수"). 디스패치: 리드(lead).

## 1. 원인(가설 → 재현으로 확정)

운영자 관측(sim-result-20261008.md §6 원문): "수정 뒤 오는 이동이 변하지 않음(18:00) 그대로".
리드 데이터 조사: 편집된 화요일 회차만 `location`이 비어 있고(나머지 19개는 있음) 이동 40개
모두 `linkedActivityId` 없음(추정 구간).

- `Shared/EditCard.swift` `LegCardForm.seeded`의 guard(수리 전 :587-590)가 "연결 없는
  반복 회차"에서 `recurrenceEpisodeWithoutLegs` 깃발만 심고 **일찍 돌아간다.** 장소 확정
  `f.choose(field: locationRow.id, value:place:)`(그 뒤 :592)가 실행되지 않아
  `confirmedPlaces`가 비어 있다.
- `Shared/ActivityDetailView.swift:316`의 저장 판정 `newPlace = confirmedPlace("location_query")`
  는 `confirmedPlaces[줄id]`를 읽어 nil이 되고, 저장이 `clearPlace: newPlace == nil`(= true)로
  `modifyActivity`를 부른다 → **무변경 저장(제목·시간만 바꾼 저장 포함)도 장소가 지워진다.**
- t49의 추정 복귀 연계는 `clearPlace`면 짝을 잡지 않는다(REQ-004 — 장소 없는 활동의 구간은
  존재할 수 없음, t49 sync-verdict §4 G행). t49는 설계대로 동작했고 막은 것은 이 선행 결함.
- 이 코드는 t49·t51에서 안 바뀌었다(`git diff afd36c3 a5b8de6 -- Shared/EditCard.swift
  Shared/ActivityDetailView.swift` 관련 줄 무변경)이며 `recurrenceEpisodeWithoutLegs`의
  드라이버 단언은 0건이었다(AG-011-01/04는 구간 줄 0개만 고정).

## 2. 재현(수리 전 ✗ — 결함의 기록)

드라이버에 T58절 단언 5개를 **수리 전에 바라는 동작**으로 먼저 썼다(t49절 규칙 — 이 절의
✗는 실패가 아니라 결함의 기록). 저장 판정식(chosen==nil → nil, 아니면 `confirmedPlaces[줄id]`)
은 뷰 save가 내리는 것과 같은 식을 드라이버에 인라인으로 뒀다 — ActivityDetailView는 컴파일
대상이 아니라 드라이버가 그 판정을 재현하는 유일한 길이다.

명령(CLAUDE.md 레시피, 산출물은 카드 검증 폴더):

```bash
cat Shared/EditCard.swift Shared/AIAssistant.swift Tools/GuardDriver.swift > .moai/state/verify/t58/gd-pre.swift \
  && swiftc -o .moai/state/verify/t58/gd-pre .moai/state/verify/t58/gd-pre.swift Shared/Store.swift Shared/Models.swift \
       Shared/Config.swift Shared/PlaceSearch.swift Shared/DirectionsService.swift Shared/LocationManager.swift \
       Shared/NotificationManager.swift Shared/GoogleCalendarService.swift Shared/SharedInbox.swift -parse-as-library \
  && .moai/state/verify/t58/gd-pre > .moai/state/verify/t58/gd-pre-run.log 2>&1
```

관측(로그 `.moai/state/verify/t58/gd-pre-run.log`, 종료 코드 1 — 단언 실패):

```
  ✗ T58-1 연결 없는 반복 회차 시드가 location 좌표를 confirmedPlaces에 보존한다
  ✗ T58-2 무변경 폼의 저장 판정(뷰 save의 clearPlace 식)이 장소 유지(newPlace non-nil)
  ✗ T58-3 시드가 낸 판정 그대로 저장한 끝 +30분 편집에 추정 복귀 구간이 따라온다(출발 = 새 끝)
  ✓ T58-4 "장소 없음" 칩을 고른 폼은 판정 nil(clearPlace=true) && 그 저장에서 추정 구간은 움직이지 않는다(REQ-004)
  ✓ T58-5 단발 활동·명시 연결 회차 시드의 location 좌표는 그대로 보존된다
531/534 통과
```

T58-3이 운영자 관측("오는 이동이 변하지 않음")의 결정적 재현이다. 단언 구성:

- T58-1·2 — 폼만: `agSeedActivity(recurrence)` + `seeded(outbound: nil, returnLeg: nil)`.
- T58-3 — 저장 경로: `af18Act`(rid) + `af18LegRet(nil, …, rid)`(추정 복귀 구간) 픽스처에
  시트 저장 순서(design §3)의 ① `modifyActivity(newEnd: +30분, newPlace: 시드가 낸 판정값,
  clearPlace: 판정==nil)`를 그 인자 그대로 부른다.
- T58-4 — REQ-004 보존 회귀선: 폼에서 "장소 없음" 칩(choose place nil)을 고른 뒤 판정 nil &&
  그 저장에서 추정 구간이 짝을 못 잡고 그대로 남는 것까지 고정(이 동작의 실행 고정은
  이번이 처음 — t49 sync-verdict §4 G행의 코드 읽기 판정을 드라이버가 대신 함).
- T58-5 — 기존 경로 회귀선: 단발 활동·명시 연결 회차(`af18LegOut(act.id, …, rid)`) 시드.

## 3. 수리

**파일: `Shared/EditCard.swift` 한 곳, +7줄**(swift-impl 하네스가 적용, 아래는 그대로).
guard else 블록에서 깃발을 심은 **뒤** 장소 확정을 수행한다:

```swift
guard activity.recurrenceId == nil || outbound != nil || returnLeg != nil else {
    f.recurrenceEpisodeWithoutLegs = true
    // 깃발을 먼저 심은 뒤에 장소를 고른다 — 순서가 바뀌면 choose의 전이가 구간 토글 줄을
    // end_iso 뒤에 세운다(깃발이 참이어야 :345의 삽입 건너뛰기가 돈다, AG-011-04). 옛
    // 가드는 일찍 돌아가며 장소 확정까지 건너뛰어 confirmedPlaces가 비고, 저장 판정이
    // clearPlace=true로 굳어져 편집만 열어 닫아도 장소가 지워졌다(t58). location이 nil인
    // 활동은 choose(place: nil)로 좌표가 지워질 뿐이라 "장소 없음" 저장(REQ-004)은 그대로다.
    f.choose(field: locationRow.id, value: activity.location?.name ?? noPlaceValue,
             place: activity.location)
    return f
}
```

- 순서가 핵심: 깃발이 참이어야 `choose`의 `location_query` 전이가 구간 토글 줄 삽입을
  건너뛴다(`!recurrenceEpisodeWithoutLegs`, 전이 안). AG-011-04 단언이 "반복 회차 폼에서
  장소를 골라도 구간 줄 0개"를 이미 고정하고 있어 이 순서의 안전성은 실행으로 뒷받침된다.
- location이 nil인 활동은 `choose(place: nil)`로 좌표만 지워질 뿐 → "장소 없음" 저장
  (REQ-004)은 그대로다(T58-4가 고정).
- 사용자가 제목·시작만 바꾼 저장도 같은 폼의 같은 판정을 지난다 — location 줄 상태가
  무변경 폼과 같으므로 이 수리로 함께 안전해진다(focus ④. 제목 변경 케이스를 별도
  단언으로 세우지 않은 이유: 판정이 폼의 location 줄 상태만 보기 때문).

**`ActivityDetailView.swift`는 무변경으로 뒀다** — 디스패치의 조건("판정 로직이 뷰(private)에
있어 드라이버가 못 보면 EditCard.swift로 옮겨야")은 드라이버가 판정식을 인라인으로 직접
재현하게 되어 풀렸다. 뷰 private 헬퍼를 옮기면 드라이버 인라인식·EditCard 헬퍼·뷰 호출
셋이 같은 계산 셋이 되어 오히려 계약 5를 흐린다. 최소 변경.

## 4. 검증(수리 후, 이 트리에서 직접 실행)

드라이버(레인 독립 재실행 — swift-impl 보고와 별개 경로, 로그 `gd-post-run.log`,
종료 코드 0):

```
  ✓ T58-1 … ✓ T58-2 … ✓ T58-3 … ✓ T58-4 … ✓ T58-5
534/534 통과
[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다
```

- 하한 **529 → 534**(T58 5개 추가). `Tools/GuardDriver.swift` 머리말 갱신 완료.
- AG-011-01(연결 없는 반복 회차 시드 구간 줄 0개)·AG-011-04(장소 골라도 구간 줄 0개)·
  AG-006-06·AG-011-02·03·T49-1~6 전부 ✓ 유지 — 수리가 기존 문법·연계를 안 바꿨다.
- 컴파일 경고는 macOS SDK 폐지 예고(CLGeocoder 등)뿐, EditCard.swift 구간 0건(로그
  `gd-post-compile.log`).

iOS 빌드(**빈 캐시**로 처음부터, 로그 `ios-build-clean.log`):

```bash
xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath .moai/state/verify/t58/dd build
```

관측: `exit=0`, `** BUILD SUCCEEDED **`, SwiftCompile 42단계(실제 컴파일),
소스 경고 **0건**(appintentsmetadataprocessor 툴체인 공지 제외). 새 소스 파일 없음 →
xcodegen 불필요(서명 리셋 없음).

## 5. 문서 인용 영향(+7줄, :591 이후)

- **CHECKLIST.md:253(P4)** — `EditCard.swift:741`·`:764`가 +7 밀림 → **이 카드에서
  재사상 완료**(`:748`·`:771`, 본문 대조로 실제 위치 확인 뒤 수정).
- `.moai/reports/t17/sync-verdict.md:400`의 `EditCard.swift:590-606` — 닫힌 판정 문서의
  시점 기록이라 재사상 대상 아님(관행: 과거 판정서는 그 시점의 좌표를 보존).
- 그 밖의 `EditCard.swift:NNN`(NNN ≥ 591) 인용: CHECKLIST·루트 plan.md·SPEC 전수
  grep에서 0건. GuardDriver.swift 인용은 문서에 없음.
- 루트 plan.md 후속 목록에 t58 추가 여부: run 단계에서는 안 함 — sync 단계에서 리드·
  sync 레인이 정리(t49 관행).

## 6. code-safety 검토

**차단 0건 · 주의 0건 · 메모 4건** (hns-besir-app-code-safety-specialist, 읽기 전용 —
실행은 레인 몫이라 디스크 로그 판독으로 대체, 2026-10-09).

- 위험 부류 4종(H1 await 인덱스·H2 조용한 실패·H3 외부 한도·H4 복제/죽은 코드) 전부
  0건 — diff는 동기 코드(seeded·choose)만, 새 Task 없음, 줄 추가 없음.
- **깨어난 잠재 결함 3경로 추적, 전부 무해 확인**: ① confirmedPlaces가 찬 채
  LegSavePlanner.ops 진입 — ops는 토글 줄 존재부터 검사해 연결 없는 회차 폼(구간 줄 0개)에선
  빈 목록, 좌표도 origin/return 줄만 읽음. ② 무변경 저장이 처음으로 realign 경로 진입 —
  realignLegs는 명시 연결만 보고 이 회차엔 해당 구간이 없어 무연산, modifyActivity의
  changed도 false(쓰기 없음, REQ-008 바이트 동일). ③ 이 폼에서 장소를 다른 곳으로 바꾸는
  choose — 좌표만 확정되고 깃발이 토글 삽입을 계속 막음(저장은 newPlace 명시 변경),
  장소 변경 후 추정 짝이 옛 이름 기준으로 남는 것은 이 diff 이전에도 도달 가능하던 경로
  (t50의 정확 대조 영역, 새로 깨어난 것 아님).
- 경계 조건 확인: location nil 회차의 무변경 저장은 choose(place: nil)로 좌표만 비는데
  이미 nil이라 쓰기 없음(changed=false). 시드 내부의 choose는 favoritePlaces가 빈 상태에서
  돌아(bootstrap이 seeded 반환 뒤 채움) 즐겨찾기 라벨 충돌도 불가.
- 주석 정확성: 깃발 선언(:315-318)·전이 삽입 건너뛰기(:341-344)·새 주석(:589-595) 모두
  코드와 대조 확인(독립 판정 — swift-impl의 자기 판정과 별개).

메모(이 카드 밖, 후속 후보):
- **메모 1(짝 엮기)** — 드라이버 T58-2·4의 인라인 판정식은 뷰 save의 판정
  (ActivityDetailView.swift:316·300-302)과 같은 식의 정당한 복제. **뷰 판정을 고치는
  카드에서 T58-2·4도 같이 갱신**해야 드라이버가 초록인 채 드리프트하지 않는다.
- **메모 2** — T58절 안에 같은 판정식이 세 번(T58-2·4 인라인, T58-5은 t58LocPlace 헬퍼).
  헬퍼를 절 머리로 올리면 줄어든다 — 다음에 이 절을 건드릴 때 합칠 자리(세 비슷한 줄
  규칙이 오기 전까지 굳이 고치지 않음).
- **메모 3** — 새 주석의 `:345` 줄번호 참조는 코드 이동에서 늙는다(t44 사례). 현재는
  정확하고 심볼(`choose`의 삽입 건너뛰기)로도 뜻이 살아 있어 그대로 둠.
- **메모 4** — T58-4가 choose 이전 사본의 t58Loc.chosen을 읽지만 id·nil 여부만 쓰고
  둘 다 불변이라 결과 동치(결함 아님).

## 7. 시뮬레이터·실기기 확인(운영자 몫 — 빌드로 증명 불가)

- 연결 없는 반복 회차 편집 카드를 열어 **아무것도 안 고르고 저장** → 회차 장소가 남아
  있는지(기존엔 지워졌음).
- 같은 회차의 **끝 시각만** 바꿔 저장 → 오는 이동이 새 끝에 맞춰 따라오는지(운영자가 본
  18:00 그대로 증상의 반대).
- "장소 없음" 칩을 직접 골라 저장 → 장소가 지워지고 이동이 안 따라오는지(REQ-004 유지).
- 실기기 데이터의 같은 피해(이미 지워진 회차 장소)는 이 카드가 되돌리지 못한다 — 복구는
  사용자의 재저장. 시뮬레이터 앱 데이터의 화요일 회차도 마찬가지.

## 8. 커밋·완료 신호

- 커밋: 본 파일·diff와 함께 `(card t58)` 표기. 병합·push·시뮬레이터 설치는 **안 함**
  (디스패치 지시).
- 완료 기준(디스패치 signal): 브랜치 `WT-recur-edit-place` + card t58 + evidence
  `.moai/reports/t58/progress.md`.
- 드라이버 잔여(청소): 정상 종료라 `besir-gd-*` 잔여 없음(실행 exit 0·1 모두 자기
  샌드박스 정리 경유 — 필요 시 `ls -d $TMPDIR/besir-gd-*`로 확인).
