# SPEC-UIKIT-009 — spec-compact.md

> run이 읽는 압축본이다. 요구사항 · 수락 기준 · 바꿀 파일 · 범위 밖만 담는다. 근거·설계·결정 기록은 `spec.md`·`design.md`·`plan.md` §2에 있다.
> 기준 트리 `b2c3987`(브랜치 `WT-edit-card-unify`). 카드 t17(C8 U-1). Tier L. 요구사항 23 · 수락 기준 24. 상태 draft, 버전 0.1.4. 결정 D-1~D-14 해소(2026-09-30, 칸반 리드 경유) — 권장과 다른 것은 D-8 (b), 새로 더한 결정은 D-14 (b)(REQ-023, 권장안이 없던 새 결정 기록). 0.1.2는 D-14를 이동시간 미계산의 모든 모양에 적용했다(새 결정 아님). 0.1.3은 운영자 방침 P-1(2026-09-30 iOS 전용 개발·검증 — 결정 게이트 아님, `plan.md` §2)을 반영했다: 게이트·기준선·시뮬레이터 스크립트는 iOS만, 새 맥 전용 코드 없음, 기존 맥 코드는 지우지 않음. 0.1.4는 plan-audit 3회차의 blocking 결함 D20~D24만 고쳤다(결정 게이트·방침 변화 없음, 요구사항·수락 기준·드라이버 하한 그대로): 카드 범위의 경로 집합(D20) · 도달 기록은 `addEvent`로 새로 만든 구간만, 반복 뒤 회차는 갭(D21) · AC-015 "세 구간"(D22) · 달력 점도 공유 함수의 나열 구간을 읽음(D23) · 지시문 밖 맥 전용 탭 셋(D24).

## 요구사항 (GEARS)

### A 결합 — 편집이 활동을 안다

- **REQ-001 (Event-driven)**: When the user chooses 편집 on the detail screen of a travel leg whose `linkedActivityId` resolves to an existing activity, the app shall open that activity's edit card with the leg's rows shown, and shall not open the stand-alone travel edit form for that leg.
- **REQ-002 (Ubiquitous · Unwanted)**: The activity edit card shall derive each linked leg's time from the activity — the outbound leg arrives at the activity's start and the return leg departs at the activity's end — and shall contain no row that changes a leg's time basis, its link, or its activity-side endpoint.
- **REQ-003 (Event-driven)**: When the user saves an activity through the activity edit card, each explicitly linked leg shall follow the saved activity: its time by the derivation rule of REQ-002, its activity-side endpoint (the outbound leg's destination, the return leg's origin) from the saved place with the travel time re-estimated, and its title from the saved title.
- **REQ-004 (Event-driven)**: When the user saves an activity whose place was cleared with the "장소 없음" chip, the activity's linked legs shall be removed with the place, and the card shall already have shown the leg rows gone before the save.
- **REQ-005 (Event-driven · Unwanted)**: When an activity is saved with its place cleared, the activity's place shall become empty; and when an end time that is not later than the start is supplied, the activity shall reject it and its linked legs shall not be re-aligned to that end time.
- **REQ-006 (State-driven · Unwanted)**: While a travel leg's `linkedActivityId` does not resolve to an existing activity, the app shall treat that leg as stand-alone — its edit shall open the stand-alone travel form and its title shall be drawn on the timetable.

### B 오는 편·가는 편 나중 추가와 제거

- **REQ-007 (Ubiquitous)**: The leg rows — the two leg toggles, the outbound origin, mode, and arrival buffer, the return destination and mode, and the notification toggle and lead — shall be built and shown-or-removed by one shared, SwiftUI-free row grammar with the same labels, options, order, and membership rules as the creation card, and both the creation card and the activity edit card shall use it; the creation card shall keep no private copy, and the row keys shall live in one table so that another card's vocabulary can map to it without a second builder.
- **REQ-008 (Event-driven)**: When the user turns a leg toggle on and saves, exactly one leg of that role shall be created, linked to the activity, with its time derived; when the user turns a leg toggle off and saves, only that leg shall be deleted; when the saved card differs from its seed in no leg row, no leg record shall change and no calendar upload or removal shall be triggered; and where calendar sync is enabled for the activity, a created leg shall be queued for upload and a deleted leg's calendar item shall be removed.
- **REQ-009 (Unwanted · Event-driven)**: The app shall never create a second leg of a role the activity already has, never create a leg for an activity without a place, and never leave a leg linked to an activity that was deleted while the leg was being created; when a requested leg operation is refused for one of these reasons, the card's result shall say which.
- **REQ-010 (Event-driven)**: When a leg operation of the activity edit card fails, or finishes with the leg's travel time not computed, the card's result shall report that, and the app shall not count that leg as made.
- **REQ-011 (State-driven)**: While the activity being edited has no explicitly linked legs and belongs to a recurrence, the activity edit card shall show no leg rows and shall keep its notice that the edit applies to this occurrence only.

### C 삭제 연계

- **REQ-012 (Event-driven)**: When an activity is deleted — one at a time or as a batch — every leg explicitly linked to it shall be deleted with it, with its notification cancelled and its calendar item removed, and no leg linked to another activity and no unlinked event shall be deleted.
- **REQ-013 (Event-driven · Unwanted)**: When the user deletes a leg linked to an activity from its detail screen, only that leg shall be deleted, and the same-title delete choice shall not include any leg linked to an activity.
- **REQ-014 (Event-driven)**: When the user opens the delete confirmation of an activity that has N ≥ 1 explicitly linked legs, the confirmation text shall state N; when N is 0 the text shall be unchanged.

### D 겹침 크기 연동

- **REQ-015 (State-driven)**: While any block of an activity group overlaps another block on the displayed day, the timetable shall draw every member of the group inside the same lane, so that the group narrows and widens together; an activity group is an activity together with the legs explicitly linked to it, or, for an activity of a recurrence that has no explicitly linked leg, the legs that the existing recurrence inference (same recurrence, same day, same place name) attributes to it; the lane is the group's outer column range, and members may subdivide it per REQ-017.
- **REQ-016 (Ubiquitous)**: The group packing shall be one pure function in a source file the guard driver compiles, taking the spans that `span(for:on:)` already computed and returning each block's lane and lane count; the timetable view shall contain no second implementation of the packing or of the lane arithmetic; and the drawn frame and the hit test shall take their horizontal ranges from the same function.
- **REQ-017 (Ubiquitous · Unwanted)**: Members of one group that overlap each other on the displayed day — an activity inflated to its minimum height, a leg with no travel time drawn as a warning block, a leg the user dragged into its own activity — shall be drawn side by side inside the group's lane and shall never be drawn on top of one another; a gap between members is a legal state and the group is formed by the link or by the inference of REQ-015, not by adjacency; and for a day without any group the result shall equal the current algorithm's result.
- **REQ-018 (Ubiquitous · Unwanted)**: The change shall not alter the drag semantics — dragging an activity moves its legs, dragging a linked return leg shifts the whole leg, dragging a linked outbound leg adjusts its buffer with its arrival fixed — nor the tap result of any block of a day without a group, and `span(for:on:)` shall remain the single source of block geometry.

### E 기록·검증

- **REQ-019 (Ubiquitous · Unwanted)**: The change shall use only Theme tokens for colors and keep dark mode following the device; shall keep `EditCard.swift` free of SwiftUI; shall not add an AI class, a tool declaration, a parameter key, or change the Gemini wire format, and shall not touch secrets; shall keep `Store` the single hub with no new persistence layer or event bus; shall add no stored field except an Optional one and no case to `ScheduleAnchor`; shall add a source file only if decision D-2 (b) is adopted; shall give any new icon-only or spinner-collapsing control an explicit accessibility label; and, because development and verification are iOS-only, shall add no macOS-only code and shall not delete the existing macOS code or any `#if os` branch, while no gate of the change shall build or verify the macOS app.
- **REQ-020 (Ubiquitous)**: Every behavior of modules A through D and F that a command can observe shall be covered by a guard-driver assertion; each defect the change repairs — a cleared place that stays, an invalid end that re-aligns the legs, a bulk delete that does not cascade, and a leg linked to a missing activity — shall first be shown by an assertion run on the unmodified code, its observed ✓/✗ line recorded in `progress.md` §E.2, before the code is changed; the record shapes that a failed travel estimate leaves on a leg shall be shown as follows, because the gate run of the driver assumes online estimation (its premise assertions S and J): the shape a failed re-estimate leaves shall be shown on the unmodified code through the no-origin exit of the same estimate function, which reaches the same record state without the network; the shapes a failed estimate leaves on a leg newly created through `addEvent` (shapes (가)·(나)) shall be recorded as a reach record — the observed line together with the premise it needs, taken from a separately named offline run — and shall not be required of the gate run; and the predicate and the layout that repair these shapes shall be shown on records constructed in memory, deterministic in any environment; and the current packing result shall be recorded by assertions on the behavior-preserving extraction commit (C1) before the packing is changed.
- **REQ-021 (Event-driven)**: When a delivery card moves lines of `Shared/` or `Tools/` that `CHECKLIST.md` or root `plan.md` cite, that card's sync shall re-map every such citation by atomic token replacement with a ledger and a positive control, and shall update the CHECKLIST rows for the day timetable (K5·K8·K9), edit (D) and delete (E) flows and the root `plan.md` card table to what the change made true.
- **REQ-022 (Unwanted)**: The change shall be delivered as delivery cards each of which creates or heavily changes at most four files and touches no path outside the declared set of its card, both measured against that card's own base commit, and shall leave `Shared/AIAssistant.swift`, `Shared/GoogleCalendarService.swift`, and `proxy/` unchanged unless `plan.md` §2 records a decision gate as flipped.

### F 이동시간을 계산하지 못한 구간의 표시

- **REQ-023 (State-driven)**: While a travel leg's travel time has not been computed — for an arrival-anchored or a departure-anchored leg, whether the estimate failed when the leg was created or edited or when the upcoming leg was re-estimated — the timetable shall draw that leg as exactly one failed-estimate warning block, placed at the leg's failed-block anchor instant (for a departure-anchored leg its stored departure, or its arrival when no departure is stored; for any other leg its arrival) and listed only on the day that contains that instant; the day listing of the timetable, the calendar dots, the choice of block, and the block's geometry, and therefore its hit-test range, shall read one shared function on the leg record; a leg whose travel time has been computed shall be listed and drawn as before; and the stored meaning of `departureDate` and `arrivalDate` shall not change.

## 수락 기준 (Given / When / Then 압축)

카드 열은 `acceptance.md` AC 매트릭스(단일 출처)의 것이다. 하한은 드라이버 ✓ 줄 수만 센다.

| AC | 카드 | 관측자 | 요지 |
|---|---|---|---|
| AC-001 | MA (1) · MB (2)–(4) | 기계+사람 | Given 연결된 구간·매달린 링크·연결 없음 / When 구간→활동 조회와 편집 진입 / Then 연결됨만 활동이 나오고 편집은 활동 카드를 연다(`ActivityDetailView(activityId` grep 1, 라우팅이 조회를 부른다) (드라이버 3) |
| AC-002 | MA | 기계 | Given 활동 14:00–15:00과 힌트 30분 구간 둘 / When 수단·여유 수정·활동 이동·종료 늘림·자정 넘는 오는 편 / Then 가는 편 도착 = 활동 시작, 오는 편 출발 = 활동 끝, 링크 유지, 오는 편 버퍼 0 (드라이버 7) |
| AC-003 | MA | 기계 | Given 장소 A 활동과 구간 둘 / When 장소 B·새 제목으로 저장 / Then 안쪽 끝점 B, 바깥 끝점 그대로, 제목 따라옴, 바뀐 것 없으면 바이트 동일, 이동시간 재계산 또는 nil = 결과 플래그 (드라이버 5, 기준 트리에서 돌리지 않음) |
| AC-004 | MA | 기계 | Given 장소·구간 있는 활동 / When "장소 없음"·끝 ≤ 시작 저장 / Then 장소 지워지고 구간 0건, 잘못된 끝은 구간을 건드리지 않음, 기존 호출 모양은 장소 유지 (드라이버 6, 재현 먼저) |
| AC-005 | MA (1)(2) · MC (3) | 기계+갭 | Given 일괄 삭제 뒤 남은 구간 / When 조회 / Then 재현 후 수리, 매달린 링크는 없음, 제목 표시가 조회를 거침(grep) (드라이버 2) |
| AC-006 | MB | 기계 | Given 최종 트리 / When grep·드라이버 / Then 줄 빌더 5개 0, 줄 문구가 저장소에 한 번씩·EditCard.swift, SwiftUI import 0, 멤버십 전이·기억값·키 표·시간 줄 없음 (드라이버 6 · grep 4) |
| AC-007 | MA | 기계 | Given 가는 편만 있는 활동 / When 오는 편 나중 추가 / Then 정확히 하나·`.departure`·출발 = 활동 끝·버퍼 0, 생성과 같은 경로, 과거 출발은 무오류 (드라이버 8) |
| AC-008 | MA | 기계+갭 | Given 구간 둘 / When 가는 편 끄기·무변경 저장·수단만 수정 / Then 그 구간만, 나머지 바이트 동일; 캘린더 절은 갭 (드라이버 5) |
| AC-009 | MA | 기계 | Given 오는 편 있는 활동·장소 없는 활동·붙이는 도중 지워지는 활동 / When 재추가·추가·삭제 끼어듦 / Then 거절과 이유 값, 매달린 구간 0, 옛 중복은 첫째 규칙 (드라이버 5) |
| AC-010 | MA (1)–(4)·(10) · MB 13a · MC (5)–(9)·(11)–(13)·20·20b | 기계+사람 | Given 힌트 유무 호출, 메모리에서 만든 미계산 네 모양(도착 기준 · 출발 기준 새로 만듦 · 재추정 실패(옛 도착, 자정 판 포함) · 반복 뒤 회차), 출발지 nil 재현 레코드 / When 결과·판정·앵커·나열·점 / Then 플래그 = 레코드, 거절은 만든 것으로 세지 않음, `addEvent`로 새로 만든 구간의 실패((가)·(나))는 도달 기록(게이트 실행은 "아니오") · 반복 뒤 회차는 메모리 구성으로만(갭), 재추정 실패 모양은 출발지 nil로 결정적 재현, 판정이 네 모양에서 참·계산된 구간에서 거짓·옛 조건 포함, 앵커 = 출발 기준은 출발(없으면 도착)·그 밖은 도착, 자정 재추정 실패는 출발일에만 나열, 점 = 나열(점도 공유 함수의 나열 구간을 `dayKeys`에 넘김), 뷰에 `departureDate != nil` 0 · `ContentView`·`Store`에 `e.arrivalDate > dep` 0; 스크립트 13a(MB 뒤)·20·20b(MC 뒤에만 참) (드라이버 12) |
| AC-011 | MB | 기계+갭 | Given 반복 회차·연결 구간 둘 활동 / When 시드 / Then 반복은 구간 줄 없음(추정 구간이 있어도), 연결은 값 시드, 알림 다르면 무변경 저장 불변, 안내 문구 grep (드라이버 3) |
| AC-012 | MA | 기계+갭 | Given A1·A2·E·A3 / When 낱개·일괄 삭제 / Then 연결 구간 함께, 일괄은 재현 뒤 수리, 무관 이벤트 유지; 알림·캘린더 호출은 갭 (드라이버 5) |
| AC-013 | MA (1)–(3) · MB (4)·스크립트 | 기계+사람 | Given 같은 제목 구간·이동 / When 같은 제목 집합·구간 삭제 / Then 연결된 구간 제외, 그것만 삭제, (4) 뷰에 필터 리터럴 0 (드라이버 3 · grep 1) |
| AC-014 | MA (1) · MB (2)(3) | 기계+사람 | Given 구간 둘·없음·반복 / When 개수 조회 / Then 2·0·0, 확인 문구에 딸린 이동 수 (드라이버 3) |
| AC-015 | MA (9)–(12) · MC (1)–(8)·(13) | 기계 | Given 실례 E1·E2·E6, 반복 회차 R(내일)·늦은 회차 L(모레) / When 배치 묶음 조회·묶음 배치 / Then 묶음이 함께 [0,.5], U [.5,1], 옛 결과는 기록한 값, 묶음 키는 주입, 조회 반환이 정확히 {R 가는 편→R, R 오는 편→R}(사전 순서 무관), 다음 날 도착하는 L의 오는 편은 빠짐(약점 고정), 추정이 `moveActivity`와 같은 코드 (드라이버 12 · grep 1) |
| AC-016 | MC | 기계 | Given 최종 트리 / When grep·드라이버 / Then 뷰에 열 산술·`columnEnds` 0, 칸 함수 하나를 렌더·히트가 씀, 칸이 겹치지 않음 (드라이버 2 · grep 3) |
| AC-017 | MC | 기계 | Given E3·E3b·E4·E8·E7·E9(자정 재추정 실패)·묶음 없는 6+ / When 배치 / Then 묶음 안 나란히, 틈은 묶음, 경고 블록은 앵커에 서서 활동과 한 칸, 묶음 없는 날은 옛 출력과 같음, 동률 안정 (드라이버 9) |
| AC-018 | MA (1)–(3) · MC (4)(5) | 기계+사람 | Given 활동과 두 구간(둘 다 힌트 30분, `addEvent` 직접) / When 활동 이동·오는 편 15분·가는 편 15분 끌기 / Then 함께 이동·통째 이동·여유 5분(기준 트리에서도 결정적), 탭 회귀 (드라이버 3+2) |
| AC-019 | MA (2) · 카드마다 | 기계+갭 | Given 최종 트리와 `b2c3987` / When 명령 / Then 금지 파일 무변경, 구 JSON 디코딩(비-Optional 필드의 판정), 색 직접 사용 0, `ScheduleAnchor` 케이스 불변, (6) 플랫폼 지시문 목록에서 사라진 줄 0·새 맥 지시문 0(양성 대조 포함); 접근성 대응과 분기 안 맥 코드 · 지시문 밖에서 주석이 맥 전용으로 밝힌 코드(`ContentView.swift`의 `.onTapGesture` 셋)의 변경은 갭 (드라이버 2 · 명령 4) |
| AC-020 | 카드마다 | 기계 | Given 카드 마지막 트리 / When 게이트 / Then 드라이버(온라인) 357 − 뺀 수 + 더한 수(누적 바닥 423·432·460), iOS 빌드 무경고(맥 빌드는 게이트에 없음), 컴파일 경고 집합 동일, 재현 기록(REQ-020 결함 넷 + 재추정 실패의 결정적 재현 + `addEvent`로 새로 만든 구간의 도달 기록(게이트 아님) · 반복 뒤 회차는 갭 + C1) |
| AC-021 | 카드마다 | 기계 | Given sync / When 인용 재사상 / Then 원장 + 양성 대조, 행 갱신 |
| AC-022 | 카드마다 | 기계 | Given 카드 커밋과 **그 카드의 기준 커밋**(§E.2) / When git diff / Then SPEC·보고서 경로를 뺀 변경이 선언 목록(소스 + sync 문서) 안, `Shared`·`Tools`에서 크게 고침 ≤ 4, 새 파일 0 |
| AC-023 | MB | 사람 | 시뮬레이터 스크립트 1~13(13a 포함) — 결합·추가·제거·삭제 |
| AC-024 | MC | 사람 | iPhone 시뮬레이터 스크립트 14~22(20a·20b 포함, 11단계) — 겹침·경계·오는 편 실패 표시(새로 만듦·재추정 실패). REQ-001·002·008·010·015·017·018·023 |

통과 수: T = 357 − 뺀 수 + 더한 수. 더한 단언의 드라이버 하한 합 103(AF 66 · AG 9 · AH 28), 뺀 수 기대 0 → T ≥ 460(누적: MA 뒤 423 · MB 뒤 432 · MC 뒤 460).

## 바꿀 파일 (배달 카드별, 크기는 예측)

| 카드 | 크게 고침 | 작게 고침 · 문서 |
|---|---|---|
| **t17-a** 연계 Store + 드라이버 | `Shared/Store.swift` · `Tools/GuardDriver.swift` | sync: `CHECKLIST.md` · 루트 `plan.md` |
| **t17-b** 편집 카드 통일 UI (a 뒤) | `Shared/EditCard.swift` · `Shared/AddActivityView.swift` · `Shared/ActivityDetailView.swift` · `Tools/GuardDriver.swift` | `Shared/EventDetailView.swift` · sync 문서 |
| **t17-c** 겹침 크기 연동 + 실패 표시 (a 뒤 — `Store`의 조회를 부른다) | `Shared/Models.swift`(배치 순수 함수 · 미계산·앵커 함수) · `Shared/ContentView.swift` · `Tools/GuardDriver.swift` | `Shared/Store.swift`(달력 점 몇 줄) · sync 문서 |

바꾸지 않는다: `Shared/AIAssistant.swift` · `Shared/GoogleCalendarService.swift` · `proxy/` · `project.yml`. 카드 범위는 그 카드의 기준 커밋과 잰다(AC-022). t17-a의 `Store.swift`에는 배치 묶음 조회(D-8 (b))가 함께 든다.

## 범위 밖 (Exclusions)

### Out of Scope — AI 경로의 구간 결합

- AI `update_schedule`의 `anchor` 뒤집기·다중 매치 거절·제목 대조 삭제·`AIAssistant.swift:2038` 추정은 t30·t18·t20 몫이다. 운영자의 "분리" 증상은 UI 경로에서만 닫힌다.
- AI 목록의 실패 표지(`AIAssistant.swift:2644`)는 실패한 오는 편을 계속 놓친다 — REQ-023은 시간표만 고친다.

### Out of Scope — 구글 캘린더 왕복과 재업로드 공백

- 구글 왕복이 링크·기준을 싣지 않는 것, `moveActivity`·`shiftEvent`·`adjustBuffer`가 캘린더를 다시 올리지 않는 기존 공백(결정 D-10 (a)). 새 구간의 추가·수정·삭제는 기존 경로로 캘린더가 갱신된다.

### Out of Scope — 반복이 만든 구간(명시적 연결 없음)

- 기존 추정으로 **배치 묶음에만** 넣는다(결정 D-8 (b), REQ-015). 구간 줄·삭제 연쇄의 대상은 아니다 — 반복 회차 활동 카드에는 구간 줄이 없다. 삭제 연쇄로 넓히는 것은 별도 결정이다.
- 추정의 약점(도착이 다음 날인 오는 편 누락 `Store.swift:1128`, 같은 이름 장소 `:1129-1130`)은 고치지 않는다 — 그 구간은 낱개 배치로 돌아간다.

### Out of Scope — 충돌 검사의 짝 제외

- `Store.conflicts`에 짝 제외 입력을 더하지 않는다(결정 D-9 (b)) — 호출자가 없는 입력은 죽은 API다.

### Out of Scope — AI 카드 문법 통일(t30)과 동일 계산의 다른 복제

- AI 채팅 카드를 공유 줄 문법으로 옮기는 일, 같은 장소 50 m 가드의 폼 공유, 세 편집 화면의 복사된 장소 검색 도우미 통합.

### Out of Scope — 맥 앱의 빌드와 검증 (iOS 전용 방침, 2026-09-30)

- 맥 앱은 빌드·실행·검증하지 않는다. 새 맥 전용 코드는 만들지 않고 기존 맥 코드와 `#if os` 분기는 지우지 않는다(REQ-019) — 지우지 않을 뿐 동작 보장은 아니다.
- 받아들인 갭: 맥 타깃도 `Shared/`를 컴파일하므로(`project.yml:89`·`:93`) 이 카드의 `Shared/` 변경이 맥 타깃을 깨도 드러나지 않는다. 운영자가 받아들였고 이 카드는 메우지 않는다(`plan.md` §2 P-1).

### Out of Scope — 저장 경로의 기존 결함

- `updateEvent`의 스냅샷 되쓰기·저장 안 된 gid 비움, 새 진입점이 막는 몫 밖의 다중 `await` 고아, `updateActivity`의 바깥 호출 0(지우기 전 확인 필요).
- 재추정에 실패한 출발 기준 구간의 옛 도착은 레코드에 남고 이동 상세·충돌 검사·AI 목록·구글 업로드가 계속 읽는다(REQ-023은 시간표의 나열·점·블록만). 도착 기준 실패 구간과 반복 뒤 회차는 `refreshUpcomingEstimates`의 대상(`Store.swift:1252`)에서 빠진다 — 기존 동작.

🗿 MoAI
