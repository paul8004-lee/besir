# t58 sync 판정 — PASS (차단 0 · 주의 1건은 이 카드에서 수리)

카드 t58(B급, SPEC 없음). 브랜치 `WT-recur-edit-place`, run 커밋 `5ce1bac`, 베이스 master `a5b8de6`.
판정일 2026-10-09, sync 레인. 병합·push는 하지 않았다(리드 몫). 로그는 전부
`.moai/state/verify/t58-sync/`에 있다.

## 1. 재현한 것 (내가 직접 돌린 명령과 출력)

| 항목 | 명령 | 관측 |
|---|---|---|
| 드라이버(레인 독립 재실행) | CLAUDE.md 레시피(cat→swiftc→실행), 산출물 `t58-sync/gd*` | `534/534 통과`, `[실제 데이터] 대조 통과 — 시작 3개, 끝 3개`, `exit=0`, 컴파일 error 0·EditCard/GuardDriver 경고 0 (`gd-compile.log`, `gd-run.log`) |
| T58-1~5 | 위 로그 536-540행 | 전부 ✓ |
| iOS 빈 캐시 빌드 | `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath .moai/state/verify/t58-sync/dd build` | `exit=0`, `BUILD SUCCEEDED` 1회, `SwiftCompile` 42단계(실제 컴파일), 소스 경고 0(appintentsmetadataprocessor 툴체인 공지 2줄만) (`ios-build-clean.log`) |
| master 병합 | `git merge-tree --write-tree master HEAD` | 충돌 없음(master == merge-base `a5b8de6`, 빨리감기 가능) |
| 수리 전 ✗ 보존 | `.moai/state/verify/t58/gd-pre-run.log` 536-543행 | T58-1·2·3 ✗, T58-4·5 ✓, `531/534` — progress.md §2와 일치(결함의 기록이 디스크에 있다) |
| 샌드박스 잔여 | `ls -d $TMPDIR/besir-gd-*` | 0건 |

## 2. 추가 점검 ①~④

**① 수리 순서(깃발 → choose) — 안전. 반대 순서가 깨지는 것을 실행으로 확인했다.**
- 코드: `Shared/EditCard.swift:341-345` — `choose`의 `location_query` 전이는
  `!recurrenceEpisodeWithoutLegs`일 때만 토글 줄을 end_iso 뒤에 삽입한다. 수리(`:588-597`)는
  깃발(`:588`)을 먼저 심고 `choose`(`:594`)를 부르므로 삽입이 건너뛰어진다.
- 변이 실험(렌즈 주장이 아니라 내가 만든 반증 시도): 수리 블록의 `choose`를 깃발 앞으로 옮긴
  복사본(`t58-sync/EditCard-swapped.swift`)으로 드라이버를 돌리면 `532/534`, **AG-011-01·
  AG-011-04가 ✗**(`gd-swapped-run.log` 532·536행, `exit=1`). 즉 순서는 우연히 맞은 게 아니라
  기존 단언이 지키고 있다.
- `choose(place: nil)`(위치 없는 회차)도 확인: `else` 가지(`:353-357`)는 `rememberTravelValues`
  → `forgetPlaces` → 구간 키 줄 제거인데, 이 폼엔 구간 줄이 없고 `chosenIn`이 전부 nil이라 아무
  것도 쓰지 않는다. `favoritePlaces`는 `bootstrap`(ActivityDetailView.swift:158)에서 seeded 반환
  **뒤**에 채워지므로 시드 안의 `place ?? favoritePlaces[value]`는 `place`만 본다(라벨 충돌 불가).

**② 다른 호출부 영향 — 없음.** `LegCardForm.seeded` 프로덕션 호출처는 전수 grep 결과
`Shared/ActivityDetailView.swift:154` 한 곳뿐이다(AI 채팅 편집 카드는 이 시드를 쓰지 않는다 —
Shared·ShareExtension·Tools에서 `seeded(` 매치는 이 줄과 드라이버 단언뿐). 깨어난 경로도 코드로
재독했다: `LegSavePlanner.ops`(`:634-`)는 토글 줄이 없으면 `continue`(`:648`, `guard let toggle`)라 구간 줄 0개인
이 폼에선 빈 목록이고, `modifyActivity`는 `newPlace != updated.location`일 때만 changed
(`Store.swift:341`)라 같은 장소 재저장은 쓰기 없음.

**③ 보존 — 확인.** "장소 없음" 칩(REQ-004)은 T58-4가 판정 nil && 그 저장에서 추정 구간 불변까지
고정(✓). 단발·명시 연결 회차는 T58-5(✓)와 수리가 건드리지 않은 본 경로(`:599-`).

**④ 드라이버 판정식 vs 뷰 — 줄 단위 같음.**
- 뷰: `ActivityDetailView.swift:300-302` `confirmedPlace(_:)` = `field(key).flatMap { $0.chosen == nil ? nil : form?.confirmedPlaces[$0.id] }`;
  `:316` `let newPlace = confirmedPlace("location_query")`; `:332` `clearPlace: newPlace == nil`.
- 드라이버: `Tools/GuardDriver.swift:5261`(T58-2)·`:5278`(T58-3)·`:5294`(T58-4)·`:5326-5329`
  (T58-5 `t58LocPlace`)가 모두 `row.chosen == nil ? nil : f.confirmedPlaces[row.id]`.
  T58-3·4의 호출 인자(`newPlace: …, clearPlace: … == nil`)도 뷰 `:331-332`와 같은 모양.
- 한계(못 본 것): 뷰는 컴파일 대상이 아니라 드라이버가 뷰를 **부르는 것이 아니라 베낀다.** 위는
  지금 시점의 줄 대조이고, 뷰가 바뀌면 드라이버는 초록인 채 어긋난다 — run 메모 1(짝 갱신)을
  그대로 유효로 둔다.

## 3. 4관점

- **기능** — PASS. 결함 경로(시드가 깃발만 심고 조기 종료 → `confirmedPlaces` 빔 → `clearPlace=true`)와
  수리가 코드로 일치하고, 수리 전 ✗ 3건 → 수리 후 ✓로 같은 단언이 뒤집혔다.
- **보안/안전** — PASS(차단 0). 새 비동기·저장 루프·외부 호출 없음(동기 7줄), 강제 언래핑 추가 0.
- **다듬기** — 정보 1: 가드 안팎에서 같은 `f.choose(field: locationRow.id, value: …, place: …)`가
  두 번 적혀 있다(`:594`, `:599`). 깃발만 `if`로 정하고 `choose`를 한 번 부르는 모양이 더 짧지만,
  현재 모양은 "깃발이 먼저"라는 불변을 주석과 함께 눈에 보이게 해 준다 — 카드 안에서 고치지
  않는다(변이 실험이 보여 주듯 순서는 단언이 지키므로 합치기는 선택).
- **일관성** — 주의 1(수리함): run의 progress §5가 "`EditCard.swift:NNN`(NNN ≥ 591) 인용 0건"이라
  했으나 **`CHECKLIST.md:94`가 `LegSavePlanner`를 `EditCard.swift:627`로 인용**하고 있었다.
  `grep -n "enum LegSavePlanner"`: 수리 전 `:627` → 수리 후 `:634`(+7). 이 카드가 만든 드리프트라
  카드 안에서 `CHECKLIST.md:94`의 `:627`→`:634` 한 토큰을 고쳤다(양성 대조: 같은 줄의
  `LegCardForm.seeded :566`·`줄 키 :255`·`:319`는 591 미만이라 무영향, `:566`은 수리 전후
  같은 줄). 전수 재확인: 루트 CHECKLIST.md·plan.md·STATUS.md·CLAUDE.md의 `EditCard.swift:N`
  8종(`94: 255·319·566·634`, `253: 748·771`, `279: 359`, plan.md `:240`)이 현재 코드와 맞고,
  `.moai/specs` 49건의 최댓값은 `:332`라 ≥591 인용이 없다(awk 임계 필터의 양성 대조로 max 출력 확인).
  닫힌 판정서(`.moai/reports/**`)의 옛 좌표는 시점 기록이라 건드리지 않는다.

## 4. 이 카드에서 고친 것

| 파일 | 변경 | 이유 |
|---|---|---|
| `CHECKLIST.md:94` | `EditCard.swift:627` → `:634` | run의 +7줄이 `LegSavePlanner` 선언을 밀었는데 §5 전수 grep이 놓쳤다 |
| `.moai/reports/t58/sync-verdict.md` | 신규 | 이 판정서 |

코드(`Shared/EditCard.swift`, `Tools/GuardDriver.swift`)는 손대지 않았다.

## 5. 못 본 것 · 운영자 몫

- 화면 동작(편집 카드를 열어 아무것도 안 고르고 저장 → 장소 유지, 끝 시각 +30분 → 오는 이동이
  따라옴, "장소 없음" 칩 → 삭제 유지)은 빌드·드라이버로 증명되지 않는다 — progress §7의 시뮬레이터
  3항목이 그대로 운영자 확인 몫. 리드가 전한 "운영자 화면 모두 정상 + 앱 데이터 대조 일치"는
  디스크에서 근거를 찾지 못해 이 판정의 근거로 쓰지 않았다(재현은 위 §1만).
- 이미 지워진 기존 회차 장소는 이 카드가 되돌리지 못한다(progress §7) — 재저장으로 복구.
- 메모 1~4(run code-safety)는 유효하며 후속 입력으로만 둔다: 특히 메모 3(주석의 `:345` 줄번호
  참조)은 이번에 내가 확인한 현재 값이 정확(`:345`가 `if !recurrenceEpisodeWithoutLegs,`)하다.

## 6. 결론

**PASS — 차단 0.** 병합 가능(빨리감기). 병합은 리드가 한다.
