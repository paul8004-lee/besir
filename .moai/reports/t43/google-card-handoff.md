# 카드 t48 인계 — 이동 구간 드래그의 구글 캘린더 반영(삭제 후 재생성)

작성: t43 plan 레인(`manager-spec`), 2026-10-08. 이 파일은 **t48의 SPEC이 아니다** — t48이 plan 컬럼에 오를 때 SPEC을 쓰는 사람이 읽을 재료다. 출처는 SPEC-UIKIT-012 0.5.0(커밋되지 않은 작업 트리 판, 2026-10-08)이고, 0.6.0에서 이 범위를 뺐다.

## 1. 운영자 결정 (원문)

| 질문 | 답변 원문 | 출처 |
|---|---|---|
| 구글 반영(0.4.1 게이트 D-6) | "삭제 후 재생성으로 반영" | `.moai/reports/t43/gate-answers.md` §1 〔운영자〕 |
| 카드 분할(0.5.0 Q-8) | "두 장 — 핵심 먼저, 구글은 별도 (Recommended)" | `.moai/reports/t43/split-answers.md` §1 〔운영자〕 |

반영 자체와 방식은 운영자가 정했다. 반복 "전체"에도 적용하는지는 말씀이 없다(〔가정〕 — 0.5.0은 포함으로 읽었다).

## 2. 0.5.0 초안 원문 (그대로 옮김)

### REQ-012 (0.5.0)

> **REQ-012 (Ubiquitous · Event-driven)**: The leg drop shall change the stored schedule synchronously — no `await` and no ignored `try?` in the drop — and, when the drop changed at least one activity and the Google account is connected, it shall reflect the change in Google Calendar by deleting and re-creating, for every changed activity and its dragged-side leg that already has a Google event id, that record's Google event, in exactly one `Task` per drop whose first synchronous segment reads those ids by record id from the current store, clears them on the records, and records the deletion tombstones before any remote call, then removes all of them in one batched removal and enqueues all of those records for upload in one call; no loop in the drop shall contain a network call; a remote deletion failure shall leave its tombstone for the next sync to retry, and an upload failure shall leave the record in the failed upload state shown in Settings; and when the account is not connected, the drop shall leave every Google event id and upload state unchanged. 근거: 게이트 D-6 "삭제 후 재생성으로 반영"〔운영자〕, 반복 "전체"에도 적용〔가정〕. 순서와 묶음은 `updateRecurringSeries`(`Store.swift:1073-1085` — gid 한 번에 모으기, 원격 삭제 전 로컬 gid 비우기, 삭제 한 번, 큐 한 번)와 `removeFromCalendar`(`:97-103` — 묘비 먼저)를 따른다. 묘비를 첫 동기 구간에서 남기는 이유: 로컬 gid를 비운 뒤 묘비 전에 동기화가 끼면 원격 사본을 모르는 일정으로 당겨올 수 있다(묘비 주석 `Store.swift:86-96`). 연결 확인과 재등록 대상은 `updateActivity`(`:288` — 연결됐고 gid가 있을 때만)와 같다 — gid가 없던 레코드는 새로 올리지 않는다. 화면에서 실패가 보이는 자리: 재등록 실패는 설정의 "캘린더에 못 올린 항목 N건"(`Shared/SettingsView.swift:61-64`), 원격 삭제 실패는 화면에 따로 뜨지 않고 다음 동기화가 다시 지운다 — 그 사이 구글에는 옛 길이와 새 길이 사본이 함께 보일 수 있다. 비동기 재정렬 `realignLegs(of:)`(`:581`)는 쓰지 않는다.

### AC-014 (0.5.0)

> - **D**: AF-018-28 — 미연결(드라이버)에서 gid·`calendarUpload` 불변. 기준 ✓(회귀 핀 — 지금도 구글을 건드리지 않는다). 연결 갈래는 시험 이음매가 없어 드라이버가 닿지 않는다(`googleConnected`는 계산 속성 `Shared/Store.swift:790`).
> - **G** — 드롭 경로 본문(구글 갈래 포함)을 `.moai/state/verify/t43/drop.txt`로 잘라:
>
> | 대조 | 기대 | 기준 트리 양성 대조 |
> |---|---|---|
> | `grep -c 'Task {'` | **1** | `adjustTravelLeg` 0 · `updateActivity` **1**(패턴 작동) |
> | `grep -c 'removeFromCalendar('` · `grep -c 'enqueueCalendarUpload('` | **1 · 1** | `updateRecurringSeries`에서 각 1 |
> | `grep -c 'deleteEvent\|createEvent\|try?'` | **0** | — |
> | 줄 순서: `googleConnected` < `Task {` < `googleEventId = nil` < `removeFromCalendar(` < `enqueueCalendarUpload(` | 성립 | `updateRecurringSeries` 안 상대 줄 50 · 57 · 59 · 61 |
> | 네트워크 호출이 `for` 루프 안에 없다 | 읽기 판정 + 줄번호 | — |
>
> - **S**: S-12(단건) · S-15(반복 "전체" · 오프라인 실패).

### AF-018-28 (0.5.0)

> 구글 미연결 갈래: gid가 있는 활동(`googleEventId = "AF018-g-act"`)과 명시 연결 오는 편(`"AF018-g-leg"`)을 +15 → 일정은 바뀌고 두 gid와 `calendarUpload`(nil)는 그대로. 기준 ✓ 회귀 핀(지금도 구글을 건드리지 않는다). 〔운영자 D-6〕

t48에서 쓸 때 번호는 새로 매긴다(t43의 AF-018은 0.6.0에서 27까지다).

### S-12 · S-15 (0.5.0)

> | S-12 | (구글 연결) S-1 직후 구글 캘린더에서 `회의`·복귀 이동을 연다 | 구글 `회의`가 13:00–14:30, 복귀 이동이 새 시각이다. 옛 13:00–14:00 사본은 없다(있으면 다음 동기화 뒤 다시 본다 — 사라지면 "같음") |
> | S-15 | (구글 연결) S-7 같은 2주 반복을 만들고 퇴근 이동을 30분 아래로 "전체" → 구글 확인. 이어 비행기 모드로 같은 이동을 30분 위로 "전체" → 설정 화면 → 비행기 모드 해제 → "다시 시도" | 구글의 모든 평일 체류·복귀가 새 시각. 오프라인 뒤 설정에 "캘린더에 못 올린 항목 N건"이 뜨고, 다시 시도 뒤 사라진다. 그 사이 구글에 옛 사본이 남는지 메모 |

### 0.5.0 Q-7 (열린 질문)

> 구글 — 반복 "전체"에도 삭제 후 재생성(〔가정〕)인지, 26주 평일 반복이면 최악 520회 순차 호출인데 받아들일지(구글 할당량 수치는 미확인)

## 3. 호출 수 분석

- 최악: 26주 평일 반복 "전체" = 회차 130 × (활동 1 + 끌린 쪽 구간 1) = gid 260 → **원격 삭제 260 + 생성 260 = 520회**, 전부 순차다. 삭제는 `removeFromCalendar`의 gid 루프(`Shared/Store.swift:101`), 생성은 직렬 업로드 작업(`:1141-1147` → `pushToCalendar`/`pushActivitiesToCalendar` 루프)이다.
- 선례: 반복 상한 주석 "26주 × 평일 × 4구간이면 500번 넘게 순차 호출"(`:42-43`). `updateRecurringSeries`도 같은 규모를 지우고 올린다.
- **모르는 것**: 구글 캘린더 API의 사용자당 쓰기 할당량 수치(조회하지 않았다). 429/403이 오면 지금 구조에서는 재시도가 아니라 `.failed` 기록이 된다(`enqueueCalendarUpload` 머리 주석 `:1104-1108`).

## 4. 재료 (기준 트리 `b59fcaa`에서 잰 줄)

| 재료 | 자리 | 요점 |
|---|---|---|
| 묘비 | `Store.swift:86-92`(설명) · `deletedGoogleEventIds` `:92` | 지운 원격 사본을 동기화가 되살리지 못하게 막는다 |
| `removeFromCalendar` | `:97-103` | 묘비를 먼저 합치고 저장(`:99-100`, 첫 `await` 전) → gid마다 `try? await gcal.deleteEvent`(`:101`). 실패해도 묘비가 남아 다음 동기화가 다시 지운다 |
| `updateActivity` | `:282-299` | 정렬·저장 뒤 `guard googleConnected, let gid` (`:288`) → `Task` 하나에서 지우고, id로 다시 찾고(`:293-295`), gid 비우고, 재등록 큐 |
| `updateRecurringSeries` 일괄 | `:1073-1085` | `if googleConnected`(`:1073`) → gid 한 번에 모으기(`:1078`) → **로컬 gid를 원격 삭제 전에 비운다**(`:1079-1081`; 이유 주석 `:1074-1077` — nil로 기다리는 사이 동기화가 "원격에 없는 gid"를 보고 회차를 통째로 지울 수 있고, 묘비는 되살림만 막지 이 제거는 못 막는다) → `await removeFromCalendar(gids)`(`:1082`) → autoAdd면 재등록 큐(`:1083-1084`) |
| `enqueueCalendarUpload` | `:1113-1148` | 연결 확인 → 복사본에서 `.pending` 표시 후 한 번 대입·저장 → 직렬 업로드 작업에 잇는다(`:1141-1147`) |
| 업로드 실패 | `:1196-1201`(이벤트) · `:1222-1226`(활동) | `.failed` 기록 |
| 설정 표시 | `Shared/SettingsView.swift:61-64` | "캘린더에 못 올린 항목 N건" + "다시 시도" |
| 연결 판정 | `Store.swift:790` | `var googleConnected: Bool { config.hasGoogleCalendar && gcal.isConnected }` — 계산 속성 |

## 5. 검증 한계

- 드라이버는 구글과 네트워크에서 격리돼 있고 `googleConnected == false`다(`Tools/GuardDriver.swift:1490-1497`, 클라이언트 ID를 비운다). 연결 갈래를 켤 시험 이음매가 없다.
- 그래서 드라이버는 **미연결 갈래만**(gid·업로드 상태 불변) 단언할 수 있다. 연결 갈래는 구조 대조(순서·`Task` 수·루프 안 네트워크 0)와 실제 계정 시뮬레이터 단계가 맡는다.

## 6. t43에 붙이는 방법 (t43 병합 뒤)

- t43(SPEC-UIKIT-012 0.6.0)의 드롭은 **동기**이고 구글을 부르지 않는다(REQ-012 0.6.0 — 0.4.1 형태로 되돌림, AC-010이 드롭 경로 안 `Task`·`removeFromCalendar`·`enqueueCalendarUpload`·`googleEventId` 0건을 대조). t48은 이 대조를 뒤집는다(위 AC-014 초안).
- 붙일 자리: `adjustTravelLeg`의 소유 갈래가 루프·저장·알림 재예약을 마친 뒤. 루프가 바꾼 활동 id와 끌린 쪽 구간 id를 모아 넘기는 것이 필요하다 — t43은 이 목록을 만들지 않으므로 t48이 더한다.
- 활동 블록 드래그(`moveActivity`)도 같은 갭이다 — t48 범위에 넣을지는 t48 plan의 결정이다.

## 7. 물려받은 갭 F12

- 정의: SPEC-UIKIT-009 `spec.md:90` — "구글 캘린더 왕복은 `linkedActivityId`·`anchor`를 싣지 않는다. 추가·수정·삭제는 캘린더를 갱신하지만 `moveActivity`·`shiftEvent`·`adjustBuffer`는 안 한다."
- 범위 밖 기록: SPEC-UIKIT-009 `spec.md:197`(결정 D-10 (a)), 근거 측정 `research.md:41-42`.
- t43 0.6.0 범위 밖 절: "연결된 구간 드래그가 바꾼 활동 길이는 이 카드에서 구글에 반영하지 않는다(물려받은 갭 F12, t48이 닫는다)."

## 8. 열린 질문 (t48 plan이 운영자에게)

- 반복 "전체"에도 삭제 후 재생성하는가(최악 520회 순차 호출).
- 활동 블록 드래그(`moveActivity`)도 같은 카드에서 닫는가.
- 미연결 상태에서 놓은 드래그를 나중에 연결됐을 때 다시 올리는가(지금은 안 올린다).
- 원격 삭제 실패 시 옛·새 사본이 함께 보이는 구간을 받아들이는가.

🗿 MoAI
