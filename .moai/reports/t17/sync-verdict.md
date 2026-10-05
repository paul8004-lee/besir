# t17 sync 판정문 — SPEC-UIKIT-009 (1차 FAIL · 2차 PASS · 최종 PASS)

## 최종 판정 — 트리 `aed00ed` · 2026-10-05 · **PASS** (3-phase close 포함, 병합·push는 리드)

- 대상: 2차가 권고한 경고 F1·F2의 병합 전 수리 — 코드 `1876772`(`ActivityDetailView.swift` 하나, 29+16) · 문서 `aed00ed`. 이 레인이 2차 문서 커밋 `e9be4a2` 위에서 다시 돌렸다.
- **F1·F2는 닫혔다.** 읽기로만 판정하지 않고 실제 `LegSavePlanner`·`Store`에 뷰의 두 규칙(미계산 안내 = 연산 뒤 레코드, 안내 뒤 재시드)을 같은 모양으로 적용해 재현했다. 차단 0, 새 경고 1(W1 — 코드 주석 '다시 저장은 추정 실패의 복구 경로다'가 사실이 아니다. 이 카드가 만든 한계가 아니라 기존 한계를 드러낸 것이라 PASS는 유지하고 병합 전 주석 한 줄 정정을 권고한다. §3.1b).
- 기계 몫 AC-001~022 전부 충족, AC-023·024는 사람 전용 🟡. 문서 몫(인용 재사상 · CHECKLIST · 루트 `plan.md`)은 최종 HEAD 기준으로 다시 적용·검증했다.
- 판정은 이 파일과 증거 로그를 읽고 내려 달라 — 내 보고 메시지가 아니라.

### 3.1 증거(Evidence) — `aed00ed`에서 이 레인이 직접 돌렸다 (로그: `.moai/state/verify/t17-sync/r3-*`, `repro/r3-*`)

| 항목 | 관측 |
|---|---|
| 드라이버 | `compile_exit=0` · `run_exit=0` · 끝 줄 `471/471 통과` · `[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다` · ✓ **471** · ✗ **0** |
| 라벨 집합 | 2차 실행 대비 뺀 라벨 **0**, 더한 라벨 **0** (코드 변경이 뷰 하나라 드라이버 집합은 그대로) · AF **69** · AG **10** · AH **35** |
| 컴파일 경고 집합 | 24줄 = 기준 24줄, `diff` exit 0 |
| iOS 빌드 | 새 DerivedData `r3-ios-build.log:945 ** BUILD SUCCEEDED **` · `^SwiftCompile` **42** · 툴체인 안내를 뺀 `warning:` **0** · `ActivityDetailView.swift` 컴파일 줄 포함 (드라이버 집합에는 뷰가 없다) |
| 샌드박스 잔여 | `ls -d $TMPDIR/besir-gd-*` → no matches |
| AC-019 | (1) 무출력 · (3) 색 **0** · (5) `Image(systemName` **0** · (6) 플랫폼 지시문 집합 37줄 = 기준 37줄 diff **0** · `.onTapGesture` `:627·:650·:685` · `#if os(macOS)` `ContentView.swift:190` 유지 |
| 명령 항목 | `ActivityDetailView`를 건드렸으므로 AC-001·005·006·011·013·014·010 (9)를 전부 다시 쟀다 — 모두 기대값 (AC-006 (9) 키 리터럴 `0·0·9`, AC-011 (4) `1`, AC-014 (2) `2`, AC-010 (9) `0·0/0·무출력 exit 1·0·0·2·2·1·2`) |
| AC-022 | 이번 수리 `e9be4a2`→`1876772`: `ActivityDetailView.swift` 하나(29+16), 새 파일 0 · 카드 MD 누적 `9936bb2`→`1876772`: 소스 4파일(ADV 40+12 · EditCard 15+4 · Store 33+9 · GuardDriver 41+0), 100줄 이상 **0**, 새 소스 파일 **0** |

**F1 · F2 닫힘 재현** (`repro/repro-f12`, 실제 `EditCard.swift`의 `LegSavePlanner`와 `Store`를 컴파일해 쓴다):

```text
[F1 전] travel=nil
[F1 후] travel=Optional(13567.0)
[F1] 수리 전 규칙(OR 누적) 안내=true · 수리 후 규칙(레코드) 안내=false · 레코드 계산됨=true → 수리 후 OR과 갈라짐 = 레코드와 일치
[F1 반대 방향] 원래 nil인 구간이 그대로면 수리 후 규칙 안내=true (nil 레코드 = 안내 참)
[F2 첫 저장] ops 1건
[F2 첫 저장 결과] ["created(travelKnown: false)"]  → 미계산(레코드)=true → 안내 뜨고 시트 열린 채
[F2 수리 전 규칙 — 다시 저장] ops 1건 → ["refused(reason: …duplicateRole)"]  (거짓 거절 문구)
[F2 수리 후 규칙 — 다시 저장] ops 0건 (거짓 안내 없음)
[F2 수리 후 + 오는 편을 더 켬] ops 1건: ["add(departure)"]
[F2 거절된 추가 뒤 재시드] 다음 저장 ops 1건: ["add(arrival)"]
```

양방향을 모두 쟀다 — F1은 계산된 레코드에서 거짓 안내가 사라지는 쪽과 nil 레코드에 안내가 남는 쪽, F2는 거짓 거절이 사라지는 쪽과 사용자가 더 고친 줄은 여전히 나가는 쪽(양성 대조). 수리 전 규칙은 이 레인이 2차에서 재현한 `ActivityDetailView.swift`의 OR 누적과 낡은 `seed`를 그대로 옮긴 것이다. 거절된 추가가 재시드 뒤에도 재시도되는지도 쟀다 — 계획기가 "기존 구간 유무 × 토글"로 판정하므로 구간이 없으면 다음 저장에서 `.add`가 다시 나간다(위 마지막 줄: 거절된 추가 뒤 재시드해도 `add(arrival)`이 그대로 나간다 — 조용히 버려지지 않는다).

### 3.1b 독립 렌즈(`code-safety`, 이번 수리 diff `e9be4a2..1876772` 전용) — 차단 0 · 경고 1 · 메모 4

- **F1 닫힘 (렌즈 판독 + 이 레인 실행)**: 미계산 판정은 모든 await 뒤 레코드에서 한 번만 읽는다(`ActivityDetailView.swift:380-382`, 그 사이 await 없음). 이번 저장에서 제거한 구간은 `legs(of:)`가 `events`에서 동기로 지워진 뒤 읽으므로 셈에 들어가지 않는다. clearPlace 가지는 검사를 건너뛰는데 그 구간은 `modifyActivity`에서 이미 지워졌으므로 맞다. 거절 사유(REQ-009)와 실패 계수(REQ-010)는 그대로고, `.created/.updated`의 값은 원래 `unknownTravel`에만 쓰였으므로 무시해도 잃는 보고가 없다.
- **F2 닫힘**: 렌즈의 모형 탐침(save()의 `newPlace≠nil` 가지를 그대로 옮기고 실제 `Store`·`LegSavePlanner` 사용) — 수리 전 형태 `save2-noedit ops=1 msgs=["UNKNOWN_TRAVEL","FAILED"]`(거짓 FAILED 재현), 수리 후 `ops=0`. `self.seed = current`는 지역 `let seed`가 이름을 가리기 때문에 `self.`가 필요하고 실제 `@State`에 쓴다(`:18`·`:21` 선언, 같은 클로저의 `saving`/`saveReport` 쓰기와 같은 메커니즘). `current`는 연산을 계산한 바로 그 값이다. `saving` 종료점은 두 곳뿐이고 그 사이에 throw·이른 return이 없다.
- **경고 W1 (최종, 이 레인이 재현)**: 코드 주석 '다시 저장은 추정 실패의 복구 경로다'는 사실이 아니다. 도보 구간에 이동시간 nil을 주입한 재현(`repro/r3-w1.log`) — `[① 무편집 다시 저장] realign=updated(travelKnown: false) → travel=nil`, `[② 제목을 바꾼 저장] realign=updated(travelKnown: true) → travel=13567.0`. 끝점이 그대로이고 제목·앵커도 같으면 `realignLegs`는 '유도값이 저장값과 같다'며 구간을 건너뛰므로(`Store.swift` `leg.title == title && anchorSame && …` 가지) 재추정이 일어나지 않는다. 수리 전에는 낡은 `seed`가 update 연산을 다시 돌려 우연히 재추정했다 — F2 수리가 그 우연한 경로를 없앴다. 다만 이 한계는 이 카드가 만든 것이 아니라 SPEC-UIKIT-009 plan §6이 이미 적은 '복구되지 않는 실패 구간'이다(기존 동작). 데이터 손실은 없고 안내는 사실이며, 사용자가 시트를 빠져나가는 길은 '닫기'뿐이다. **내가 2차 문서(F2 행)와 후속 27 초안에 쓴 같은 표현도 틀렸고 이 판에서 정정했다.** 처분: 코드 주석 정정은 run 레인(한 줄, 병합 전 권고), 재시도 경로를 실제로 만드는 일은 별도 결정(루트 `plan.md` 후속 30).
- 메모: N1(`.refused(.duplicateRole)` 뒤 재시드하면 폼과 레코드가 조용히 어긋날 수 있으나 `saving` 잠금 때문에 이 화면 안에서는 사실상 도달하기 어렵다 — 가설) · N2(`LegOutcome` 값과 `realignLegs` 반환값을 앱 안에서 읽는 곳이 없어졌고 같은 사실을 Store 플래그와 뷰의 레코드 읽기가 둘 다 유도한다 — 지금은 같은 값이라 어긋나지 않는다) · N3(스와이프 닫기 미잠금 — 기존, 후속 23) · N4(`.activityMissing` 안내 뒤 '저장'이 무반응 — 기존, 후속 23 ④).
- 렌즈가 못 본 것: 모형 탐침은 뷰가 아니라 규칙을 옮긴 것이고 SwiftUI `@State`가 `Task` 안에서 실제로 써지는지는 실행으로 못 봤다(판독과 같은 파일의 기존 패턴으로 판단). 렌즈 탐침 샌드박스 하나가 남아 있어 CLAUDE.md 절차대로 이 레인이 지웠다(`besir-gd-<UUID>` 한 개, 내용은 빈 `Library`).

### 3.2 AC 전수 — 2차 표 대비 달라진 것

| AC | 최종 관측 | 판정 |
|---|---|---|
| 010 | AF-010 ✓ 6 · AH-010 ✓ 7 · (9) 명령 기대값. 뷰의 미계산 안내가 이제 레코드 하나에서 나온다 | 충족 |
| 020 | §3.1 | 충족 |
| **021** | 같은 도구를 최종 HEAD로 다시 돌렸다 — 원장 237행(처분 분포 불변), 독립 검증기 본문 대조 135건 · 변경 줄 58 · 그대로인 줄 1267 · 삽입 23줄 **실패 0**, 양성 대조 2종 검출(되돌린 토큰 1건 · 원장이 모르는 줄의 한 글자 변경 1건), 적용 직후 초안과 실제 문서 `cmp` 동일. 렌즈 W1을 반영해 후속 30을 더했고(삽입 22→23줄) 틀린 '복구 경로' 표현을 CHECKLIST D11·후속 27에서 정정했다. 달라진 것: D9 · D11 · E7의 `ActivityDetailView` 줄번호, D11 서술(레코드에서 읽고 안내 뒤 재시드), 머리말 문단('sync 최종'), 루트 `plan.md` t17 행(최종 PASS·ME 수리)과 후속 26·27 '닫혔다' | 충족 |
| 022 | §3.1 | 충족 |
| 023 · 024 | 스크립트 25단계 미실행 | 🟡 (사람 전용) |
| 그 밖 | 2차 표와 같다 | 같음 |

### 3.3 3-phase close

- `spec.md` frontmatter `status: draft → completed`, `moai spec lint --strict` → `✓ No findings — all SPEC documents are valid`. run이 `in-progress`로 올리지 않아 `draft`에서 곧장 닫았다(선례 SPEC-UIKIT-008은 `in-progress → completed`를 한 커밋으로 닫았다). `spec.md` 본문·`plan.md`·`acceptance.md`는 건드리지 않았다(`manager-spec` 소유).
- `progress.md` §E.4에 최종 종결 신호(`sync_complete_at` · `sync_status: PASS (최종 …)`)를 적었다. 이 커밋 자신의 SHA는 이 파일에 적지 않는다 — 단일 출처는 `git log`의 'sync 최종' 커밋이다.
- 닫힘은 **기계 몫의 닫힘**이다. AC-023·024가 🟡이므로 SPEC이 사람 확인까지 끝났다는 뜻이 아니다.

### 3.4 Gaps · 잔여 위험(최종)

**Gaps.**
- 시뮬레이터·실기기 동작 전부(AC-023·024 스크립트 25단계), 알림 취소·재예약의 기기 효과.
- 진짜 `ActivityDetailView.save()`는 드라이버에도 내 하네스에도 컴파일되지 않는다 — F1·F2 닫힘은 diff 읽기와 뷰의 두 규칙을 같은 모양으로 적용한 하네스로 봤다(iOS 빌드는 뷰를 컴파일해 문법 오류가 없음을 보인다). 실제 시트에서 안내가 뜨고 닫히는 모습은 보지 못했다.
- 독립 렌즈는 이번 수리에도 돌렸다(§3.1b). 렌즈가 못 본 것(실제 SwiftUI 시트 동작)은 위 첫 두 항목과 같다.
- `ui-design` 렌즈는 sync에서 끝까지 돌리지 않았다. 새 문구('반복 일정 회차에는 이동을 따로 만들 수 없어요')와 '안내 뒤 시트가 열린 채 남는' 모습은 눈으로 확인하지 못했다.
- W2(같은 구간 `updateEvent` 이중 호출 — 구글 연결 필요)는 재현하지 않았다.

**잔여 위험.**
- 안내가 레코드를 읽는 규칙이 되면서 '손대지 않은 nil 구간 때문에 제목만 바꾼 저장도 안내가 뜨고 시트가 열린다'는 동작은 의도로 남았다 — 진실을 알리는 쪽이지만 사용자가 매번 '닫기'를 눌러야 한다(제품 판단: 실기기에서 거슬리면 다음 Day).
- 저장 흐름의 순수 부분(결과 집계 · 연산 순서)이 뷰 안에 있어 같은 부류(Store 결과를 뷰가 놓치는 자리)는 앞으로도 드라이버가 못 본다 — 루트 `plan.md` 후속 28.
- 문서 좌표는 `aed00ed` 기준이다. 이후 `Shared/` 변경이 있으면 `cite/apply.py` 한 번 + `verify.py`로 다시 사상한다.

---

## 이력 (2차·1차 본문은 보존)

- 카드 t17 · SPEC-UIKIT-009 · 판정 레인: sync 세션(`--deep`) · 2026-10-05
- 판정한 트리: `38bd215`(브랜치 `WT-edit-card-unify`), 누적 기준 `b2c3987`, 카드 기준 MA `42065af` · MB `61d84b4` · MC `7980190`
- **2차 판정(트리 `951d7de`): PASS** — 아래 "2차 판정" 절. 1차 FAIL의 차단 둘은 재현 하네스로 닫힘을 확인했고 문서 몫도 끝냈다.
- **1차 판정(트리 `38bd215`): FAIL.** 차단 2건(B1 · B2), 경고 4건, 메모 7건. 기계 게이트(드라이버 · iOS 빌드 · 범위 · 계약)는 전부 통과했고, 실패의 원인은 게이트가 보지 않는 자리에서 **직접 재현한** 두 결함이다.
- (1차 당시) 문서 갱신(AC-021 인용 재사상 · CHECKLIST 행 · 루트 `plan.md`)은 하지 않았다. 수리 커밋이 `Store.swift`·`EditCard.swift`·`ActivityDetailView.swift`의 줄을 다시 움직이므로, 문서 커밋은 코드 커밋 **뒤에** 사상해야 한다(`feedback_besir_refactor_breaks_citations`, 2026-09-25 보강). 도구와 결정표는 준비·드라이런을 끝냈다(§6).

## 2차 판정 — 트리 `951d7de` · 2026-10-05 · **PASS** (경고 2건은 병합 전 작게 닫기를 권고, 차단 아님)

- 대상: 수리 커밋 `6586cf7`(코드 4파일 +111/−20) · 문서 `02b9363`·`951d7de`. 이 레인이 1차 판정 커밋 `9936bb2` 위에서 다시 돌렸다.
- **1차 차단 B1·B2는 닫혔다.** 둘 다 1차와 같은 재현 하네스를 새로 컴파일해 수리 트리에서 돌려 확인했고, W1·W3도 닫혔다. 렌즈(`code-safety`)를 수리 diff에 독립으로 다시 돌렸고 **차단 0**이다.
- 새 경고 둘(F1 · F2)은 데이터 손실도 조용한 실패도 아닌 **안내 문구가 레코드와 어긋나는** 문제다. F1은 이 레인이 재현했고 F2는 코드로 확정했다(§2.4). 막을지는 리드가 정한다 — 판정은 PASS이고 작게 닫기를 권한다.
- 1차에서 미뤘던 문서 몫(AC-021 인용 재사상 · CHECKLIST 행 · 루트 `plan.md`)을 이 판에서 끝냈다(§2.5).
- 판정은 이 파일과 증거 로그를 읽고 내려 달라 — 내 보고 메시지가 아니라.

### 2.1 주장(Claim)

| # | 주장 | 판정 |
|---|---|---|
| R1 | 수리 트리의 기계 게이트(AC-020)는 통과한다 | 참 |
| R2 | B1(REQ-011)은 폼과 Store 두 곳에서 닫혔다 | 참 — 재현 |
| R3 | B2(REQ-010)는 값 보존과 결과 집계 양쪽에서 닫혔다 | 참 — 재현. 단 집계에 F1이 새로 생겼다 |
| R4 | W1(캘린더 동의 추종) · W3(제거 → 따라오기 순서)이 닫혔다 | 참 — 렌즈 양성 대조 + 코드 |
| R5 | AC-021(인용 재사상)은 원장 문자열 대조와 양성 대조로 충족된다 | 참 — §2.5 |
| R6 | 수리가 새 차단 결함을 만들지 않았다 | 참 — 렌즈 차단 0, 경고 F1·F2 |

### 2.2 증거(Evidence) — 이 레인이 `951d7de`에서 직접 돌렸다

로그는 `.moai/state/verify/t17-sync/`(gitignored, 이 워크트리 안)의 `r2-*`와 `repro/r2-*`다.

| 항목 | 관측 |
|---|---|
| 드라이버 | 컴파일 `compile_exit=0`, 실행 `run_exit=0`, 끝 줄 `471/471 통과` · `[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다` · ✓ **471** · ✗ **0** |
| 뺀 수 · 더한 라벨 | 기준 357 로그 대비 뺀 라벨 **0**, 1차 내 실행(468) 대비 뺀 **0** · 더해진 것은 정확히 `AF-003-06` · `AF-009-06` · `AG-011-04` 셋 |
| 접두별 하한 | AF **69**(하한 66) · AG **10**(9) · AH **35**(28) — 전부 이상 |
| 컴파일 경고 집합 | 24줄 = 기준 24줄, 줄·열 제거 정렬 `diff` exit 0 |
| iOS 빌드 | 새 DerivedData `r2-ios-build.log:945 ** BUILD SUCCEEDED **` · `^SwiftCompile` **42** · 툴체인 안내를 뺀 `warning:` **0** |
| 샌드박스 잔여 | `ls -d $TMPDIR/besir-gd-*` → no matches |
| 명령 항목 | §2.2 1차 표와 같은 명령을 전부 다시 돌려 모두 기대값(AC-001 1·1·1 · AC-005 0·1 · AC-006 0·0·각 1·0/0/9 · AC-010 (9) 0·0/0·무출력 exit 1·0·0·2·2·1·2 · AC-011 1 · AC-013 0 · AC-014 2 · AC-015 (8) 0 · AC-016 0·0/8·2/1/1) |
| AC-019 | (1) 무출력 · (3) 색 0 · (4) `case arrival, departure` 불변 · (5) 추가된 `Image(systemName` 0 · (6) 플랫폼 지시문 집합 37줄 = 기준 37줄, diff **0**, 양성 대조(한 줄 지운 사본) **1** · `.onTapGesture` `:627·:650·:685` 셋과 `#if os(macOS)` `ContentView.swift:190` 유지 |
| AC-022 (수리 카드 MD) | 기준 `9936bb2`(수리가 시작한 커밋)로 잰 `--name-only` = `ActivityDetailView` · `EditCard` · `Store` · `GuardDriver` — 모두 앞 카드들의 선언 목록 안, 100줄 이상 파일 **0**(22+7 · 15+4 · 33+9 · 41+0), 새 소스 파일 **0**. **정정**: `progress.md` §E.2 MD 행의 `card_base_sha`가 수리 커밋 자신(`6586cf7`)으로 적혀 있다 — AC는 카드가 **시작할 때**의 커밋을 요구하므로 `9936bb2`가 맞다(그 칸대로 재면 `6586cf7..HEAD`가 소스 0건이라 범위를 잴 수 없다) |

**B1 — 닫힘 (재현).**

```text
$ repro-b1-r2   # 1차에서 created였던 호출
[전] 활동 1건(recurrenceId 있음=true), 구간 0건
[addLeg 결과] refused(reason: main.Store.LegRefusalReason.recurrenceEpisode)
[후] 명시적 구간 0건 — leg.recurrenceId=nil
[반복 전체 삭제 뒤] 활동 0건, 남은 구간 0건

$ probe-form-r2   # 폼 쪽 — 렌즈 탐침을 수리된 EditCard로 다시, 양성 대조 포함
[반복 회차] 깃발 recurrenceEpisodeWithoutLegs=true · 시드 구간 줄=0
[반복 회차] 장소를 고른 뒤 구간 줄=[]
[반복 회차] 저장 연산 0건: []
[단발(양성 대조)] 깃발 recurrenceEpisodeWithoutLegs=false · 시드 구간 줄=2
[단발(양성 대조)] 장소를 고른 뒤 구간 줄=["outbound_enabled", "return_enabled"]
[단발(양성 대조)] 저장 연산 1건: [… .add(role: arrival, …)]
```

(렌즈 원 탐침은 14번째 줄에서 존재하지 않게 된 `outbound_enabled`를 force-unwrap하다 죽는다 — 수리가 먹혔다는 신호이고, 위는 같은 시나리오를 죽지 않게 고쳐 다시 낸 것이다.)

**B2 — 닫힘 (재현).** `repro-b2-r2`, 수단 transit + 프록시 비움 = 추정 실패 주입, walk = 성공 대조:

```text
# 시나리오 1 — 제목만 바꾼 저장 (transit, 추정 실패 주입)
[제목만 바꾼 저장 뒤] 가는 편: title=새 제목 travel=Optional(1800.0) dep=있음 … failedBlockAnchor=nil
[제목만 바꾼 저장 뒤] 오는 편: title=새 제목 (복귀) travel=Optional(1800.0) dep=있음 … failedBlockAnchor=nil
[realignLegs 결과] 가는 편=…updated(travelKnown: true) 오는 편=…updated(travelKnown: true)
[시나리오 1 — 제목만] 뷰가 모으는 안내: (안내 없음 → dismiss)
# 시나리오 2 — 장소를 바꾼 저장 (끝점이 달라져 재추정이 맞고, 실패하면 알린다)
[장소를 바꾼 저장 뒤] 가는 편: travel=nil dep=nil … failedBlockAnchor=있음(경고 블록)
[realignLegs 결과 2] …updated(travelKnown: false) …updated(travelKnown: false)
[시나리오 2 — 장소 변경] 뷰가 모으는 안내: 이동시간을 계산하지 못했어요
# walk 대조: 시나리오 2에서 travel=5156/5071초로 새로 계산, 안내 없음
```

1차에서는 시나리오 1이 `travel=nil` + 경고 블록 + 안내 없음이었다. 하네스의 "뷰가 모으는 안내"는 수리된 `ActivityDetailView.save()`의 집계 규칙(`.updated(known:false)` → `unknownTravel`)을 같은 모양으로 적용한 것이고, 진짜 뷰 코드는 diff와 렌즈가 읽었다(뷰는 드라이버 컴파일 집합에 없다 — §2.7).

**기준 트리 재현(AC-020 (5) ⓐ).** 1차에서 `021f9fd`를 독립 재실행한 `372/377`(✗ 5건: AF-004-01·02·05, AF-012-02·05)이 §E.2 기록과 같은 라벨이다.

### 2.3 AC 전수 판정 — 1차 표 대비 달라진 것

| AC | 2차 관측 | 판정 |
|---|---|---|
| 010 | AF-010 ✓ 6 · AH-010 ✓ 7 · (9) 명령 전부 기대값. 뷰 쪽 REQ-010은 B2 수리로 집계가 생겼다(F1 경고) | 충족 |
| 011 | AG-011 ✓ **4**(하한 3) — 신규 AG-011-04가 "장소를 고른 뒤"를 본다 | 충족 — REQ-011 위반 해소 |
| 003 · 009 | AF-003 ✓ 6(AF-003-06 신규) · AF-009 ✓ 6(AF-009-06 신규) | 충족 |
| 020 | 드라이버 **471**/0 · 뺀 0 · iOS 무경고 · 경고 집합 24 · 재현 기록 | 충족 |
| **021** | §2.5 | **충족** |
| 022 | §2.2 — 카드 MD 포함 | 충족 |
| 023 · 024 | 스크립트 25단계 미실행 | 🟡 (사람 전용) |
| 그 밖 | 1차 표와 같다 | 같음 |

기계 몫 AC-001~022 **전부 충족**, AC-023·024는 사람 대기.

### 2.4 렌즈 보고와 경고

`code-safety`(독립, 수리 diff 전용) — **차단 0**, 경고 F1·F2, 이월 W2, 메모 N-T1·N-T2·N-b·N-c. 닫힘 판정은 렌즈가 `38bd215` 대비 양성 대조를 붙였다(B1 base `created` → HEAD `refused`; B2 base `travel=nil` → HEAD `1800.0`; W1 base `wantsCalendarSync=true` → HEAD `false`). 렌즈 증거: `lens-cs2/`.

| id | 분류 | 내용 | 처분 |
|---|---|---|---|
| **F1** | 경고 · **이 레인이 재현**(`repro-f1`) | `save()`가 `unknownTravel`을 따라오기 결과와 diff 연산 결과 두 출처에서 OR로만 쌓는다. 이동시간이 이미 nil이던 구간의 수단만 바꿔 저장하면 따라오기 `.updated(travelKnown: false)` → `updateLeg` `.updated(true)`인데 안내는 '이동시간을 계산하지 못했어요'를 띄우고 시트를 닫지 않는다. 출력: `[후] 가는 편 travel=Optional(13567.0)` · `[뷰 집계] unknownTravel=true` · `[최종 레코드는 계산됨=true] → 안내와 **어긋남**`. B2 수리가 만든 과잉 보고다(수리 전엔 결과를 버렸다). 손대지 않은 구간이 원래 nil이면 제목만 바꾼 저장도 매번 안내가 뜨고 시트가 열린다 | **병합 전 작게 닫기를 권고** — 수리 모양: 플래그를 저장 끝에 레코드(`store.legs(of:)`의 `travelSeconds`) 하나에서 읽는다 |
| **F2** | 경고 · 코드로 확정 | 안내가 떠서 시트가 열린 채 남은 뒤 다시 저장하면 낡은 `seed`·`seedLegs`(`bootstrap`에서 한 번만 — `ActivityDetailView.swift:152-160`)로 같은 `ops`를 다시 돌린다. 성공했던 제거는 `removeLeg`가 없는 id에 `.failed`(`Store.swift:568`)를 돌려 거짓 '저장하지 못한 이동이 있어요', 추가는 `.refused(.duplicateRole)`로 거짓 거절 문구가 된다. 다시 저장은 흔한 동작이라 눈에 띈다(중복 생성은 가드가 막는다) — [최종 정정] 이 줄은 2차에서 '다시 저장은 추정 실패의 복구 경로'라고 썼으나 틀렸다: 끝점이 그대로인 nil 구간은 다시 저장해도 재추정되지 않는다(최종 W1, 아래 3.1b) | **병합 전 작게 닫기를 권고** — 안내를 띄우고 남을 때 `seed = form; seedLegs = store.legs(of:)`로 다시 시드 |
| W2 | 이월 · 가설 | 같은 구간의 `updateEvent` 이중 호출 — 수리는 노출을 바꾸지 않았다 | 후속(루트 `plan.md` 24) |
| N-T1 | 메모 | 끝점이 바뀌면 저장값을 다시 쓰지 않는다를 고정하는 단언이 없다 | 후속(28) |
| N-T2 | 메모 | 뷰는 드라이버 컴파일 집합 밖 — B2 뷰 쪽 절반과 W3 순서는 코드 읽기로만 닫혀 있다 | 후속(28) |
| N-b · N-c | 메모 | 머리 주석의 단계 번호가 본문과 다르다 · 옛 반복 회차에서 '가는 편 끄기 + 오는 편 켜기'를 한 번에 저장하면 추가가 거절된다(REQ-011과 일관, 안내 정확) | 수용 |

F1·F2의 판정 근거: 차단으로 올리지 않은 이유는 **데이터 손실도 조용한 실패도 없다**는 것이다(F1은 안내가 틀리게 뜰 뿐 레코드는 맞고, F2는 중복 생성을 가드가 막으며 사용자가 '닫기'로 벗어난다). 다만 둘 다 이번 저장 흐름이 보고의 통로가 된 뒤에 생긴 안내 신뢰 문제라 병합 전에 닫는 편이 싸다. 리드가 막기로 하면 수리 뒤 이 레인이 `ActivityDetailView.swift` 줄 번호 인용만 같은 도구로 다시 사상한다(`apply.py` 한 번, 검증기 포함).

**후속 감 3건의 승계(디스패치 ③)**: W-b · 반복 회차 각주 문구 · `endpointsSame` 3곳은 비차단에 동의한다. SPEC-UIKIT-009 `plan.md` §6은 `manager-spec` 소유라 건드리지 않고 **루트 `plan.md` 후속 25**에 올렸다. 렌즈 보강 둘을 함께 적었다 — W-b의 구조적 원인은 `deleteRecurringSeries`가 `recurrenceId`로만 지운다는 점이라 `removeExplicitLegs(of:)` 연쇄가 둘을 함께 닫고, `endpointsSame`은 `updateLeg`의 지역 함수 `write(_ act:)` 패턴으로 이미 풀 수 있어 '합치면 인자가 늘어난다'는 `progress.md` §E.2의 전제가 틀렸다.

### 2.5 인용 재사상(AC-021)

- 도구: `.moai/state/verify/t17-sync/cite/{extract,review,review2,apply,verify,makepc,newtext}.py`(gitignored). 서술 안의 좌표는 손으로 적지 않고 심볼 패턴 조회(`ln`)·base→HEAD 사상(`mp`)으로 계산했다 — 1차 드라이런의 좌표가 수리 커밋(`Store` +24 등)으로 이미 밀려 있었다.
- 원장 `.moai/reports/t17/sync-cite-ledger.tsv`(237행): 재사상 **83** · 서술 갱신 **21** · 재측정 **2** · 이동량 0 **42** · 이력 보존 **70** · 귀속 오류 **19**. 인용 토큰 596개 추출, 미결정 0.
- **검증(독립 구현 `verify.py`)**: 재사상 토큰 135건(범위는 시작·끝 각각)의 옛(`b2c3987`)·새(`951d7de`) 줄을 `git show`로 새로 읽어 바이트 일치 · 원본을 한 줄씩 걸어 변경 줄 **58** · 그대로인 줄 **1267** · 삽입 **22줄** 전부를 원장과 대조 — 설명 못 하는 변경 **0**, 실패 **0**.
- **양성 대조**: 재사상된 토큰 하나를 옛 값으로 되돌린 사본(`CHECKLIST.md:182` `:1308`→`:1012`)은 실패 2건(같은 줄이 '기대와 다름'과 '그대로임'으로 보고), 원장이 모르는 줄을 한 글자 바꾼 사본은 '설명 못 하는 변경' 1건으로 걸렸다. 적용 직후 최종 문서와 초안이 `cmp` 동일임도 확인했다.
- **자동 귀속이 틀린 것을 문맥·본문 대조로 잡았다**: K9의 `span(for:on:) :542·557`(→ `Store`로 오귀속, 실제 `ContentView`) · `weeksField :735-741`·`:140-142`(→ `Store`로 오귀속, 실제 `AIAssistant` 심볼) · `gatedRows :179-182·:201-204`(→ 실제 `AddEventView`). 그대로 옮겼다면 맞는 인용을 틀린 값으로 덮었다.
- 본문이 사라진 좌표는 재측정: `AddActivityView :509`→`:274`, K9 `ContentView :92`→`isListed` `:88`, 후속 11·14의 `anchored: false`·쓰기 줄→`EditCard`.
- **갱신한 행**: K5 · K8 · K9 서술(판정 ✅ 불변) · 새 행 **8개**(D9~D11 · E6~E8 · K11 · K12 — ✅ 2·⚠️ 6) · 이월 8번 · 머리말 기준선 문단 · 루트 `plan.md` 카드 표 **t17 행**(t16 행 뒤) · 후속 11·14 좌표 · **새 후속 21~29**. 기존 행의 ✅/⚠️/❌는 한 칸도 바꾸지 않았다.
- **옮기지 않은 선재 드리프트(이 카드 소행 아님)**: `AddEventView.swift:119`→실제 `:138`(t11 삽입), `EditCard.swift:294`(2026-09-16 관찰 블록, base에서 이미 어긋남) — t29 영역.

### 2.6 Card Cross-Check — 새 후속 ↔ 대기열(`moai todo` 직접 확인)

| 후속(루트 plan.md) | 대기열 카드 | 비고 |
|---|---|---|
| 21 · 29 (AI 경로: 실패 표지 · 구간 계수 · 삭제 보고) | SPEC plan §6이 t30·t18·t20 몫으로 적음 | 세 카드 본문에 이 항목이 **없다** — 카드 요청 때 본문에 더해야 한다(t20은 `Store.swift:345` 출발지 폴백, t18은 대화 메모리, t30은 AI 카드 문법) |
| 22 · 23 · 24 · 25 · 28 | 없음 | 새 카드 후보 — 리드가 묶음을 정한다(23은 시트 위생, 22는 폭 하한 단일 출처) |
| 26 · 27 (F1 · F2) | 없음 | **병합 전 수리 권고** — 새 카드보다 이 카드의 작은 수리 커밋이 싸다 |

### 2.7 귀속 · Gaps · 잔여 위험(2차)

**귀속.** 2차 수치는 전부 이 레인이 `951d7de`에서 §2.2의 명령으로 직접 얻었다. 가져온 값은 기준 로그(357/0, 경고 24줄)와 카드 기준 SHA뿐이다.

**Gaps.**
- 시뮬레이터·실기기 동작 전부(AC-023·024 스크립트 25단계), 알림 취소·재예약의 기기 효과.
- 진짜 `ActivityDetailView.save()`는 드라이버에도 내 하네스에도 컴파일되지 않는다 — B2의 뷰 쪽 절반(결과 소비)과 W3(실행 순서), F1·F2의 시트 동작은 diff 읽기와 같은 집계 규칙을 재현한 하네스로만 봤다(렌즈도 같은 한계).
- `ui-design` 렌즈는 2차에도 sync에서 돌리지 않았다(수리가 뷰 문구 한 줄과 저장 순서뿐). 새 문구 '반복 일정 회차에는 이동을 따로 만들 수 없어요'(`.recurrenceEpisode`)는 눈으로 확인하지 못했다.
- W2는 구글 연결 상태가 필요해 재현하지 않았다. B2의 '출발 알림이 취소된 채 남는다'는 1차에 이어 코드 읽기다.
- 이 레인의 B2 하네스는 "오프라인"이 아니라 추정 실패 주입이다(`sandbox-exec (deny network*)`는 MapKit 시스템 데몬을 막지 못한다 — 1차에서 확인).

**잔여 위험.**
- F1·F2를 그대로 병합하면 추정 실패를 한 번 겪은 뒤의 첫 재저장에서 틀린 안내가 뜬다.
- 뷰 저장 흐름이 순수 함수로 분리돼 있지 않아 같은 부류(Store 결과를 뷰가 놓치는 자리)는 다음 변경에서도 드라이버가 못 본다 — 후속 28.
- 문서 좌표는 이 HEAD 기준이다. F1·F2 수리가 `ActivityDetailView.swift`를 움직이면 인용(D9 · D11 · E7의 줄번호)이 밀리므로 위 도구로 다시 사상한다.

---

# 1차 판정 본문 (보존 — 트리 `38bd215`)

## 1. 주장(Claim)

| # | 주장 | 판정 |
|---|---|---|
| C1 | 최종 트리의 기계 게이트(AC-020)는 통과한다 | 참 — §2.1 |
| C2 | AC 24개 가운데 기계 몫 21개(AC-001~020 · 022)는 문면대로 충족, AC-021은 미판정, AC-023·024는 사람 대기 | 참 — §3 |
| C3 | 활동 카드의 구간 줄은 반복 회차에서 REQ-011대로 나타나지 않는다 | **거짓** — B1 |
| C4 | 활동 카드 저장에서 구간의 이동시간 미계산은 사실대로 보고된다(REQ-010) | **거짓** — B2 |

C3·C4가 거짓이라 카드는 `audit-ready`가 아니다.

## 2. 증거(Evidence)

모든 명령은 이 레인이 이 트리에서 직접 돌렸다. 로그는 `.moai/state/verify/t17-sync/`(gitignored, 이 워크트리 안)에 있다.

### 2.1 게이트(AC-020)

```text
$ (CLAUDE.md 가드 컴파일 명령) → driver-compile.log        compile_exit=0
$ /…/gd-s > driver-run.log                                  run_exit=0
468/468 통과
[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다
```

| 항목 | 관측 |
|---|---|
| ✓ / ✗ | `grep -c '^  ✓ '` = **468**, `grep -c '^  ✗ '` = **0** (기준 `t17-plan/driver-run.log` 357 / 0) |
| 뺀 수 | 기준 ✓ 라벨 정렬본과 `diff … \| grep -c '^<'` = **0**, 더한 라벨 `grep -c '^>'` = **111** (= AF 67 + AG 9 + AH 35, 357 + 111 = 468) |
| 접두별 하한 | AF-001 3 · 002 7 · 003 5 · 004 6 · 005 2 · 007 8 · 008 5 · 009 5 · 010 6 · 012 5 · 013 3 · 014 3 · 015 4 · 018 3 · 019 2 → AF 67(하한 66) · AG-006 6 · AG-011 3 → 9(하한 9) · AH-009 1 · 010 7 · 015 9 · 016 2 · 017 14 · 018 2 → 35(하한 28). **모든 AC 하한 이상.** 누적 하한 460 초과 |
| 컴파일 경고 집합 | 기준 24줄 / 최종 24줄, 줄·열 제거 정렬 `diff` exit 0 |
| iOS 빌드 | `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath …/dd build` → `ios-build.log:943 ** BUILD SUCCEEDED **` · `^SwiftCompile` **42** · 툴체인 안내를 뺀 `warning:` **0** |
| 샌드박스 잔여 | `ls -d $TMPDIR/besir-gd-*` → no matches (남은 것 없음) |
| 재현 기록(AC-020 (5) ⓐ) | 기준 `021f9fd` 트리를 `git archive`로 임시 디렉터리에 풀어 **독립 재실행**: `372/377 통과`, ✗ = `AF-004-01` · `AF-004-02` · `AF-004-05` · `AF-012-02` · `AF-012-05` — run 레인 §E.2 기록과 같은 다섯 라벨 |
| 도달 기록(ⓑ) | 게이트 온라인 실행에서도 `· AF-010-04 실패 분기 도달: 예`, `· AF-009-03 경쟁 도달: 예`. AC는 AF-010-04의 온라인 기대를 "아니오"로 적었다 — **기록일 뿐 판정이 아니다**(AC-010 (4)). 원인은 이 레인이 검증하지 못했다(run 레인은 MapKit ETA 한도로 적었다) |

### 2.2 명령 항목(grep · git diff) — 기대값과 관측

| AC | 명령 | 기대 | 관측 |
|---|---|---|---|
| 001 (2)(3) | `grep -c 'ActivityDetailView(activityId'` · `'AddEventView(editing'` · `'activity(forLeg:'` (EventDetailView) | 1 · 1 · ≥1 | 1 · 1 · 1 |
| 005 (3) | ContentView `linkedActivityId == nil` · `activity(forLeg:` | 0 · ≥1 | 0 · 1 |
| 006 (1)(3) | AddActivityView 빌더 다섯 · EditCard `import SwiftUI` | 0 · 0 | 0 · 0 |
| 006 (2) | 여섯 문구 `grep -rnF … Shared` | 각 1, 모두 `EditCard.swift` | 각 1: `EditCard.swift:343·:344·:496·:490·:507·:514` |
| 006 (9) | 아홉 키 리터럴 AddActivityView · ActivityDetailView · EditCard | 0 · 0 · 표 한 자리 | 0 · 0 · 9 (키마다 1: `uniq -c` 전부 1) |
| 011 (4) | `반복 일정의 한 회차입니다` | ≥1 | 1 |
| 013 (4) | `grep -cF 'store.events.filter { $0.title == event.title }'` | 0 | 0 |
| 014 (2) | `딸린 이동` | ≥1 | 2 |
| 010 (9) | ContentView `e.departureDate != nil` · `e.arrivalDate > dep`(두 파일) · `git grep -c … Store` · `events(on:)`·`recomputeDaysWithSchedule`의 `departureDate` · `failedBlockAnchor`(ContentView/Store) · `isListed(on:` · `listedSpan` | 0 · 0/0 · 무출력 exit 1 · 0/0 · ≥2/≥1 · ≥1 · ≥1 | 0 · 0/0 · 무출력 `exit=1` · 0/0 · 2/1 · 2 · 2 |
| 015 (8) | `overlapSlots`·`overlapColumns` 선언 줄 `grep -c 'ScheduledEvent\|ActivityBlock'` | 0 | 선언 `Models.swift:340`·`:395`, 0 |
| 016 | `gap \* CGFloat\|1 / CGFloat(p.columns)` ContentView · `columnEnds` ContentView/Models · `overlapSlots` ContentView/Models · `struct SlotRange` | 0 · 0/≥1 · 2/1 · 1 | 0 · 0/8 · 2/1 · 1 |
| 019 (1) | `git diff --name-only b2c3987 HEAD -- proxy project.yml Shared/AIAssistant.swift Shared/GoogleCalendarService.swift` | 무출력 | 무출력 |
| 019 (3) | 색 직접 사용 파이프 | 0 (양성 대조 1) | **0** · 양성 대조 `+ .foregroundStyle(.gray)` → **1** |
| 019 (4) | `ScheduleAnchor` 케이스 줄 | 1 = 기준 | `case arrival, departure` 1, 기준과 같다. 보조 신호(판정 아님): 추가된 비-Optional `let` 줄은 `LayoutItem`·`LayoutSlot`·`SlotRange` 같은 **저장되지 않는 새 타입** 안의 것뿐이고, 저장 모델의 옛 JSON 디코딩은 `AF-019-01·02` ✓가 판정한다 |
| 019 (5) | 추가된 `Image(systemName` | (갭) | 0 — 새 아이콘 전용 컨트롤 없음 |
| 019 (6) | `#if os`·`#elseif os`·`canImport(AppKit)` 정렬 집합 diff | 0 | 기준 37줄 = 최종 37줄(`#if os(iOS)` 25 · `#if os(macOS)` 12), diff **0**. 양성 대조: 한 줄 지운 사본 **1** · macOS 줄 더한 사본 **1** · iOS 줄 더한 사본 **0** |
| 019 갭 ⓑ | `.onTapGesture` 코드 줄 | 셋 불변 | 기준 `:618·:641·:674` → 최종 `:627·:650·:685`, 세 줄 모두 존재, `ContentView.swift:190` `#if os(macOS)`도 존재 |

### 2.3 범위(AC-022) — 카드마다 그 카드의 기준 커밋으로

| 카드 | `--name-only`(SPEC 디렉터리·보고서 제외) | `--numstat -- Shared Tools`에서 100줄 이상 | 새 소스 파일 |
|---|---|---|---|
| MA `42065af..61d84b4` | `Shared/Store.swift` · `Tools/GuardDriver.swift` (선언과 일치) | Store 293+32 · GuardDriver 850+0 → **2** | 0 |
| MB `61d84b4..7980190` | ActivityDetailView · AddActivityView · EditCard · EventDetailView · GuardDriver (선언과 일치) | ADV 172+104 · AAV 51+286 · EditCard 430+0 · GuardDriver 203+0 → **4**(한도 4 이하) | 0 |
| MC `7980190..38bd215` | ContentView · Models · Store · GuardDriver (선언과 일치) | ContentView 64+72 · Models 194+0 · GuardDriver 371+0 → **3** (Store 63+19 = 82, 100 미만) | 0 |

## 3. AC 전수 판정(24)

"문면 충족"은 AC가 적은 항목이 전부 기대값이라는 뜻이다. B1·B2는 AC가 보지 않는 자리의 결함이다.

| AC | 관측자 | 이 레인이 직접 본 것 | 판정 |
|---|---|---|---|
| 001 | 기계+사람 | AF-001 ✓ 3/3 · §2.2 (2)(3) · (4)=스크립트 4 | 기계 충족 · 사람 대기 |
| 002 | 기계 | AF-002 ✓ 7/7 | 충족 |
| 003 | 기계 | AF-003 ✓ 5/5. **주의**: 제목만 바뀐 힌트 없는 따라오기(뷰가 실제로 부르는 모양)를 보는 단언은 없다 — B2가 그 자리다 | 문면 충족 |
| 004 | 기계 | AF-004 ✓ 6/6, 기준 트리 ✗ 3건(01·02·05) 독립 재현 | 충족 |
| 005 | 기계+갭 | AF-005 ✓ 2/2 · (3) 0/1 · (4) 갭(앱에 매달린 링크를 넣을 수단 없음) | 기계 충족 · 갭 1 |
| 006 | 기계 | AG-006 ✓ 6/6 · §2.2 (1)(2)(3)(9) | 충족 |
| 007 | 기계 | AF-007 ✓ 8/8 | 충족 |
| 008 | 기계+갭 | AF-008 ✓ 5/5 · 캘린더 갭 유지. **W1**(편집 카드의 `.add`가 활동의 캘린더 제외를 따르지 않음)은 이 AC가 못 본다 | 문면 충족 · 갭 |
| 009 | 기계 | AF-009 ✓ 5/5(경쟁 도달 예) | 충족 |
| 010 | 기계+사람 | AF-010 ✓ 6(하한 5) · AH-010 ✓ 7/7 · (9) 명령 전부 기대값 · 사람 3 대기. **B2**: REQ-010의 뷰 쪽 | 문면 충족 · **REQ-010 위반(B2)** |
| 011 | 기계+사람(갭) | AG-011 ✓ 3/3 · (4)=1. **B1**: 시드만 보고 "장소를 고른 뒤"는 안 본다 | 문면 충족 · **REQ-011 위반(B1)** |
| 012 | 기계 | AF-012 ✓ 5/5, 기준 트리 ✗ 2건(02·05) 독립 재현 | 충족 |
| 013 | 기계+사람 | AF-013 ✓ 3/3 · (4)=0 · 스크립트 8·13 | 기계 충족 · 사람 대기 |
| 014 | 기계+사람 | AF-014 ✓ 3/3 · (2)=2 · 스크립트 10·11 | 기계 충족 · 사람 대기 |
| 015 | 기계 | AF-015 ✓ 4/4 · AH-015 ✓ 9(하한 8) · (8) 0 | 충족 |
| 016 | 기계 | AH-016 ✓ 2/2 · §2.2 (1)(2)(5). 렌더=히트는 점 사각형이 코드 열람으로 성립(드라이버의 AH-018 히트는 비율 히트) → N4 | 충족 |
| 017 | 기계 | AH-017 ✓ 14(하한 9) | 충족 |
| 018 | 기계+사람 | AF-018 ✓ 3/3 · AH-018 ✓ 2/2 · 스크립트 16·19 | 기계 충족 · 사람 대기 |
| 019 | 기계 | §2.2 (1)(3)(4)(6) + AF-019-01·02 ✓. (5) 새 아이콘 전용 컨트롤 0 | 충족 |
| 020 | 기계 | §2.1 (1)~(5) | 충족 |
| 021 | 기계 | 도구·결정표·드라이런(원장 237행) 완료, **문서 미적용** | **미판정**(수리 뒤) |
| 022 | 기계 | §2.3 | 충족 |
| 023 | 사람 전용 | 스크립트 1~13a 미실행 | 🟡 |
| 024 | 사람 전용 | 스크립트 14~22·20a·20b 미실행 | 🟡 |

## 4. 차단 결함

렌즈(`code-safety`, 독립 렌즈 보고)가 코드 읽기로 올린 차단 후보 둘을 이 레인이 **실행으로 재현**했다. 읽기만으로는 가설이다(`feedback_besir_reproduce_lens_positives`).

### B1 — 반복 회차 활동 카드에 구간 줄이 생기고, 저장하면 반복 삭제 뒤 매달린 링크가 남는다 (REQ-011 위반)

원인: 시드 가드(`Shared/EditCard.swift:579` `guard activity.recurrenceId == nil || outbound != nil || returnLeg != nil else { return f }`)는 **시드 때만** 돈다. 장소를 고르면 `LegCardForm.choose`(`:321`, 토글 줄 삽입 `:332-346`)가 반복 여부를 보지 않고 토글 줄을 넣는다. 저장하면 `LegSavePlanner`가 `.add`를 내고 `Store.addLeg`(`:461-505`)에는 반복 회차 검사가 없다.

재현 1 — 폼 전이(렌즈가 만든 탐침을 이 레인이 읽고 다시 실행: `lens-cs/probe.swift`):

```text
$ lens-cs/probe
seed leg rows: 0
after place change leg rows: ["outbound_enabled", "return_enabled"]
ops: [probe.LegSaveOp.add(role: probe.ScheduleAnchor.arrival, outerPlace: probe.Place(name: "집", …), mode: probe.TransportMode.transit, bufferMinutes: 10, notifyLeadMinutes: 30, notifyEnabled: true)]
```

재현 2 — Store 연쇄(이 레인이 새로 쓴 `repro/repro-b1.swift`, 드라이버와 같은 임시 홈 샌드박스, 지원 디렉터리가 샌드박스 밖이면 시작 거부):

```text
[전] 활동 1건(recurrenceId 있음=true), 구간 0건
[addLeg 결과] created(travelKnown: true)
[후] 명시적 구간 1건 — leg.recurrenceId=nil
[반복 전체 삭제 뒤] 활동 0건, 남은 구간 1건
[반복 전체 삭제 뒤] 활동 id를 가리키는 구간 1건 — store.activity(forLeg:)=nil (nil이면 매달린 링크)
```

의미: 이 카드가 REQ-006·012로 닫았다고 주장하는 "매달린 링크"가 다른 경로(반복 회차 편집)로 다시 생긴다. `deleteRecurringSeries`(`Store.swift:975-990`)는 `recurrenceId`로만 지워서 `recurrenceId`가 없는 명시적 구간을 남긴다. 알림·캘린더 항목도 함께 남는다(코드 읽기).

도달 경로: 반복 회차 활동을 편집 → 장소 변경 → 가는/오는 이동 `만들기` → 저장. (AI의 "반복 전체 삭제"는 CHECKLIST E2.)

수리 방향(제안): ① `LegCardForm`에 "반복 회차·명시 구간 없음" 상태를 시드에서 들고, `choose`의 토글 삽입을 건너뛴다. ② `Store.addLeg`도 같은 조건이면 거절한다(방어). ③ 드라이버: `AG-011-04`(반복 회차 폼에서 장소를 고른 뒤에도 구간 줄 0개), `AF-009-06`(반복 회차 활동에 `addLeg` → 거절).

### B2 — 활동 카드 저장의 따라오기(`realignLegs`) 결과가 버려져, 추정이 실패하면 이동시간이 조용히 사라진다 (REQ-010 위반)

원인: `Shared/ActivityDetailView.swift:334` `_ = await store.realignLegs(of: a.id)` — 힌트를 안 넘기고 결과도 버린다. `Store.realignLegs`(`:587-600`)는 제목·끝점·앵커가 하나라도 다르면 `updateEvent(travelSecondsHint: nil)`을 불러 **네트워크로 다시 추정**하고(`:1247-1248`), 추정이 실패하면 `applyEstimate`가 먼저 알림을 취소하고 `travelSeconds`·`departureDate`를 비운 채 끝난다(`:1267-1273`). 뷰의 안내 `messages`(`:367-375`)는 `ops` 루프(`:339`~)의 결과로만 채워진다.

재현 — `repro/repro-b2.swift`(같은 샌드박스, 구간 둘에 이동시간 1800초 힌트를 주고 **제목만** 바꾼 뒤 뷰와 같은 순서로 `modifyActivity` → `realignLegs(힌트 없음)`):

```text
# 추정 실패 주입 — 구간 수단 transit, 프록시 비움(이 환경에서 MapKit이 transit ETA를 못 준다)
[저장 전] 가는 편: title=원래 제목 travel=Optional(1800.0) dep=있음 … failedBlockAnchor=nil
[저장 전] 오는 편: title=원래 제목 (복귀) travel=Optional(1800.0) dep=있음 … failedBlockAnchor=nil
[제목만 바꾼 저장 뒤] 가는 편: title=새 제목 travel=nil dep=nil … failedBlockAnchor=있음(경고 블록)
[제목만 바꾼 저장 뒤] 오는 편: title=새 제목 (복귀) travel=nil dep=있음 … failedBlockAnchor=있음(경고 블록)
[realignLegs 결과] 가는 편=Optional(…LegOutcome.updated(travelKnown: false)) 오는 편=Optional(…LegOutcome.updated(travelKnown: false))
[뷰가 모으는 안내] (비어 있음 → dismiss, 사용자는 아무것도 못 본다)

# 양성 대조 — 수단 walk, 추정 성공
[제목만 바꾼 저장 뒤] 가는 편: title=새 제목 travel=Optional(13567.0) dep=있음 … failedBlockAnchor=nil
[realignLegs 결과] 가는 편=Optional(…LegOutcome.updated(travelKnown: true)) 오는 편=Optional(…LegOutcome.updated(travelKnown: true))
```

정확히 말하면 "오프라인"이 아니라 **추정 실패**를 주입한 재현이다. `sandbox-exec (deny network*)`는 이 프로세스의 직접 네트워크만 막고 MapKit(시스템 데몬)은 막지 못했다 — walk의 "오프라인" 실행도 추정에 성공했다(`b2-offline-walk.log`). 그래서 제품에서 같은 일을 일으키는 조건은 추정이 실패하는 모든 경우다: 네트워크 단절, 카카오 할당량 소진, 경로 없음.

의미: 지하철에서 활동 이름만 바꿔 저장해도 두 구간이 경고 블록이 되고, 기기에서는 출발 알림이 취소된 채 되살아나지 않는다(`applyEstimate`는 취소만 하고 재예약은 추정 성공 때만). 도착 기준 실패 구간은 `refreshUpcomingEstimates` 대상에서도 빠진다(SPEC plan §6, 기존 동작). 알림 취소의 기기 효과는 비번들 실행이라 관측하지 못했다(코드 읽기).

추가로 `progress.md` §E.2 MC code-safety ④(b)의 "재쓰기는 같은 hint 재사용이라 새 네트워크 조회를 만들지 않는다"는 사실이 아니다(뷰 경로의 hint는 항상 nil, 렌즈 N5).

수리 방향(제안): ① `Store.realignLegs`: 끝점이 그대로이고 제목·앵커만 다르면 `leg.travelSeconds`를 힌트로 넘겨 추정을 건너뛴다(네트워크 없음, 값 손실 없음). ② `ActivityDetailView.save()`: `realignLegs` 결과의 `travelKnown == false`를 `unknownTravel`에 합친다. ③ 드라이버: `AF-003-06`(제목만 바꾼 힌트 없는 따라오기 뒤 `travelSeconds`가 유지된다 — 현재 HEAD에서는 온라인에서도 1800이 아니라 새 추정값으로 바뀌므로 **✗가 되는** 회귀 단언).

## 5. 경고 · 메모

| id | 분류 | 내용 | 처분 |
|---|---|---|---|
| W1 | 경고 · 코드로 확정 | 편집 카드의 `.add`가 `syncToCalendar`를 안 넘겨(`ActivityDetailView.swift:350`) 기본 `true`(`Store.swift:469`) — "캘린더 안 함" 활동에 가는 편을 붙이면 그 구간이 구글 캘린더에 오를 수 있다(REQ-008) | **B1·B2와 같은 수리 커밋에서 닫기를 권고** — `addLeg`의 기본을 `activity.wantsCalendarSync`로 |
| W2 | 경고 · 가설(재현 안 함) | 한 번의 저장에서 같은 구간에 `updateEvent`가 두 번 돈다(realign → updateLeg, 또는 `activityIfChanged` 재쓰기). 둘째의 await 전 스냅샷이 그 사이 업로드 큐가 적은 `googleEventId`를 덮어 중복 캘린더 항목이 생길 수 있다 | 후속 카드 후보. 가설이므로 FAIL 근거로 쓰지 않았다 |
| W3 | 경고 · 가설(재현 안 함) | realign이 제거 연산보다 먼저 돌아 곧 지울 구간을 다시 쓰며 업로드를 큐에 올린다 | B2 수리 때 순서(제거 → 따라오기)를 함께 바꾸는 것을 권고(비용 거의 없음) |
| W4 | 경고(낮음) · 코드로 확정 | `AIAssistant.swift:2644` 실패 표지는 `departureDate == nil`, 시간표는 `failedBlockAnchor` — 갈라짐을 만든 것은 이 카드(SPEC `spec.md:222`가 받아들인 갭) | 후속 목록(SPEC plan §6에 이미 있음) |
| N1 | 메모 | 저장 중 잠금은 "닫기" 버튼만 막는다. 시트 쓸어 내리기·삭제 버튼(`:83`)은 안 막고, 주석(`:20-25`)의 "시트가 내려가는 것을 막는다"는 사실보다 넓다 | 후속 |
| N2 | 메모 | `EditCard.swift:590-606`의 `first{…}!`가 "장소 없는 활동 + 명시 구간"에서 트랩(탐침 exit 133). 현재 생산자 없음 | 후속(옛/손상 JSON만) |
| N3 | 메모 · 가설 | `ContentView.swift:726` `Dictionary(uniqueKeysWithValues:)`는 id 중복에서 트랩 — 중복을 만드는 경로를 못 찾음 | `uniquingKeysWith:`로 바꾸면 비용 없이 막힌다(후속) |
| N4 | 메모 | 렌더 `max(f.width,1)`(`ContentView.swift:740`)와 히트 raw 폭(`:760`)이 다르다 — 폭 < 1pt, 320pt 기준 108열부터 | 후속(`SlotRange.points`로 하한을 옮기면 단일 출처 회복) |
| N5 | 메모 | `progress.md` §E.2 ④(b) 서술이 거짓(§4 B2) | run 레인이 정정 |
| N6 | 메모 | `addActivityWithTravel`이 `LegOutcome`을 버리고 `made += 1`(기존 패턴) | 후속(AI 경로) |
| N7 | 메모 | REQ-012 이후 `deleteActivities`가 연결 구간까지 지우는데 AI 결과 `totalCount`는 제목·날짜가 맞은 것만 센다(`AIAssistant.swift:2908-2911`) | 후속(AI 경로) |

간결성 제안(렌즈, 수정 안 함): `realignLegs`의 둘째 `updateEvent` 블록을 `updateLeg`처럼 지역 `write`로 합치기 · `deleteActivity`가 `deleteActivities([a])`를 부르게 하기 · `linkedLegs`의 명시 분기가 `legs(of:)`를 부르게 하기 · `removeExplicitLegs`의 `linkedActivityId!` 제거.

### Card Cross-Check (후속 ↔ 대기열 카드)

| 후속 | 대기열 카드(`moai todo`로 확인) | 비고 |
|---|---|---|
| W4 · N6 · N7 (AI 경로) | SPEC plan §6이 t30·t18·t20 몫으로 적음 | t30(AI 카드 문법 통일)·t18(대화 메모리)·t20(수정 경로 출발지 대체)에는 이 항목 본문이 **없다** — 카드 요청 때 본문에 더해야 한다 |
| N1 · N2 · N3 · N4 · W2 | 대기열에 없음 | 새 카드 후보. 리드가 묶음을 정한다 |

## 6. 인용 재사상(AC-021) — 준비 상태

- 문서에는 아직 손대지 않았다. 도구는 `.moai/state/verify/t17-sync/cite/{extract,review,review2,apply}.py`(gitignored, 이 워크트리에 남는다). 드라이런 결과: 토큰 596개 추출 → 원장 **237행**(이력 보존 70 · 재사상 83 · 이동량 0 42 · 귀속 오류 19 · 재측정 2 · 서술 갱신 21), 미결정 0.
- 이번 드라이런에서 **자동 귀속이 틀린 것**을 잡았다: K9의 `span(for:on:) :542·557`(앞의 `Store.swift:38`에 끌려 `Store`로 귀속 — 실제는 `ContentView`) 2건, `weeksField :735-741`·`:140-142` 2건(`AIAssistant` 심볼), `gatedRows :179-182·:201-204` 2건(`AddEventView`). 그대로 옮겼다면 맞는 인용을 틀린 값으로 덮었을 것이다.
- 본문이 바뀌어 사상할 수 없는 좌표(`AddActivityView :509`→`:274`, K9의 `ContentView :92`→`isListed` `:88`, 후속 11·14번의 `anchored: false`·쓰기 줄 → `EditCard.swift:573·:575·:330`)는 재측정했다.
- 정책: 머리말(<178줄) 기준선 문단과 "당시/그날 좌표" 서술, 닫힌 카드 행은 옮기지 않는다. 표 행 · "현행"이라 밝힌 방어 서술 · 열린 후속(11·14) · "현 좌표" 문장은 옮긴다.
- 선재 드리프트(이 카드 소행 아님, 옮기지 않음): `AddEventView.swift:119` → 실제 `:138`(t11 삽입), `EditCard.swift:294`(2026-09-16 관찰 블록, base에서 이미 어긋남). t29(cite_check) 영역.
- 재sync에서 할 일: 수리 커밋이 끝나면 `extract.py`·`apply.py`의 `HEAD` 상수만 바꿔 다시 돌린다. 이어서 원장 문자열 대조 · 양성 대조 · CHECKLIST 행(K5·K8·K9 서술, D9~D11 · E6~E8 · K11 · K12 새 행, 이월 8번) · 루트 `plan.md`(카드 표 t17 행 — 현재 t16 행에서 끝남, 후속 11·14 좌표, 새 후속) 갱신.

## 7. 귀속(Baseline-attribution) · 못 본 것(Gaps) · 잔여 위험(Residual-risk)

**귀속.** 위 모든 수치는 이 레인이 `38bd215` 트리에서 §2의 명령으로 직접 얻은 것이다. 이전 측정에서 가져온 값은 기준 로그(`t17-plan/driver-run.log` 357/0, 경고 24줄)와 카드 기준 커밋 SHA뿐이고, 둘 다 비교 대상으로만 썼다. 로그 위치: `.moai/state/verify/t17-sync/{driver-compile,driver-run,ios-build,base021-compile,base021-run}.log`, `repro/{b1-store,b2-online,b2-offline,b2-online-walk,b2-offline-walk}.log`, `lens-cs/`.

**Gaps (관측하지 않은 것).**
- 시뮬레이터·실기기 동작 전부(AC-023·024의 스크립트 25단계). 알림 취소·재예약의 기기 효과(비번들 실행이라 `NotificationManager.center`가 늘 nil).
- `ui-design` 렌즈는 sync에서 다시 돌리지 않았다 — run 레인 MB·MC 보고(결함 0)는 읽기만 했고 재검증하지 않았다. 새 아이콘 전용 컨트롤이 0이라는 것(`Image(systemName` 0)만 직접 쟀다.
- W2·W3은 타이밍 의존 가설이라 재현하지 않았다. B2의 "알림이 취소된다"는 코드 읽기다. B1의 "알림·캘린더 항목이 남는다"도 코드 읽기다.
- 구글 연결 상태(키체인·OAuth)는 드라이버 불변식이 막아 둔 영역이라 건드리지 않았다.
- AF-010-04가 온라인 게이트에서 "도달: 예"인 원인(run 레인 주장: MapKit ETA 한도)은 검증하지 못했다.
- `GuardDriver.swift`의 AF·AG·AH 단언 본문 전수 열람은 하지 않았다(라벨 존재·수·✓만 쟀다).

**잔여 위험.**
- 이 FAIL은 렌즈와 이 레인이 본 범위에서 나온 것이다. 수리 뒤 재sync에서 렌즈를 **수리 diff에** 다시 돌려야 한다 — 같은 부류(뷰가 Store 결과를 버리는 자리)가 `ActivityDetailView.save()` 안에 더 있는지는 다시 봐야 한다.
- B1 수리는 `choose`와 `addLeg` 두 곳을 건드린다. 둘 중 하나만 고치면 다른 한쪽 경로(AI 등)로 다시 열린다.
- 드라이버 468/468이 초록인 트리에서 이 둘이 나왔다 — 기계 초록은 완료가 아니다(2026-09-15 88/88 다음 날 결함 7건 선례).

## 8. 재sync 체크리스트

1. 수리 커밋(B1 · B2, 권고 W1·W3) 후 `git rev-parse --short HEAD`를 §E.2 카드별 칸에 MD(t17-d 등)로 적는다.
2. 게이트 재실행: 드라이버(≥ 468 + 새 단언) · 뺀 수 0 · iOS 무경고 · 경고 집합 24줄 · AC-022 범위.
3. B1·B2 재현 하네스(`repro/repro-b1`·`repro-b2`)를 다시 돌려 기대 출력 확인: B1은 `addLeg` 거절 · 구간 0건, B2는 제목만 바꾼 따라오기 뒤 `travel=Optional(1800.0)` 유지.
4. `code-safety`를 수리 diff에 다시 돌린다.
5. 원장 재생성 → 문서 적용 → 양성 대조 → 새 행 · `plan.md` t17 행 · 이월 8번 갱신 → `progress.md` §E.4 갱신 → 3-phase close.

🗿 MoAI
