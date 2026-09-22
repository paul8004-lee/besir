# SPEC-UIKIT-003 — progress.md

칸반 카드 t3 · UI 통일 3/3. run 레인 세션(bf9dd8df)이 2026-09-22 리드 디스패치로 개시.
워크트리 `.claude/worktrees/t3` (branch `WT-ui-unify-3`).

## §E.1 Plan-phase Audit-Ready Signal

- plan_status: audit-ready
- plan_complete_at: 2026-09-22T09:48+09:00
- plan 산출물: spec.md · plan.md · acceptance.md — 커밋 `6f1257c`(최초 작성) + `dcd0354`(D-3 해소, REQ-014 신설로 REQ 15건)
- plan 세션(pid 29072)이 저술하고 종료 시 워크트리를 반납(ExitWorktree keep). 미커밋 잔여 0건으로 인계 확인.
- 운영자 판정 이력: D-3("이동 다리의 여유도 줄로 올릴지") — 2026-09-22 "올림" 확정(리드 전달). 이 결정이 §1.4의 휴면 결함을 깨워 REQ-003이 수리로 격상됐고 REQ-014의 선행 조건이 됐다.
- **run 진입 승인의 근거**: 운영자의 카드 선택(리드의 AskUserQuestion 경유) + 리드의 run 디스패치(card t3 / cmd /moai run). 선호값은 plan 단계에서 이미 소진(D-3 질의·Tier M·순차 실행).
- **Phase 1 Plan Audit Gate**: iteration 1 **FAIL**(aggregate 0.87, 블로킹 D1~D7 — 전부 문서 수준) → manager-spec이 델타 수정(D1~D7·D9·D11; 선택 D8·D10·D12~D14는 기록된 채 남김) → iteration 2 **PASS**(aggregate ≈0.93, 9/9 해소·회귀 없음, 새 계수 명령 직접 실행 확인). 교차 모델: claude=required 통과, codex=off, glm=inconclusive(fail-open·advisory, 2회 모두). 재심사 범위는 합의된 델타 한정.

## §F Phase 4 Mode Selection

**Mode: serial (sub-agent 순차)** — 근거:

- 구현이 코딩 집약형이고 마일스톤 M2→M3→M4→M5가 같은 파일 집합(EditCard.swift → AddActivityView.swift → ActivityDetailView.swift)에 순차 의존한다. 특히 **REQ-003(M2)이 REQ-014(M3)보다 먼저 커밋되어야 한다**(plan.md §2 첫 항목 — 순서가 곧 결함 방지).
- 병렬화 이득이 없다: 네 파일 중 둘(EditCard·EditCardView)은 공유 컴포넌트라 나머지 둘의 전환이 그 위에 서고, 마일스톤별 커밋이 순서 제약의 기계적 보증이 된다.
- 구현 주체: besir 하네스 전문가(`hns-besir-app-swift-impl-specialist` 구현, `hns-besir-app-ui-design-specialist` 설계 검토, M5에 `hns-besir-app-code-safety-specialist`·`hns-besir-app-ux-check-specialist`) — plan.md §2 배정표 그대로. 스폰 결함(2026-09-20 기억)은 이 세션에서 재확인 결과 재현되지 않았다(plan-auditor 스폰 성공).

## §E.2 Run-phase Evidence

(마일스톤별로 채운다 — 커밋 SHA, 게이트 출력, 기계적 신호 실측값.)

### M2 — 컴포넌트 표면 (REQ-001~003) 🟢

구현: `hns-besir-app-swift-impl-specialist`(spawn m2-swift-impl) · 설계 검수: `hns-besir-app-ui-design-specialist`(spawn m2-ui-design, 판정 **GO** — 6렌즈 OK·수정 0건).

변경: `Shared/EditCard.swift`(+33/−7) · `Shared/EditCardView.swift`(+30/−14) 두 파일만.
- REQ-001: `parseDatetime` 접두 목록 `["arr:", "dep:", ""]`(빈 문자열 마지막) · `EditField.anchored = true` 기본값 · `customLabel` 삼항 → `anchor(ofPrefix:)` 경유 switch(nil이면 접두 없는 시각) · `EditCardActions.chooseTimePlain` 기본값 추가 · `datetimeEditor` 확인이 `field.anchored`로 분기
- REQ-002: `datetimeRow` 기준 칩 전용 ChipFlow(`[.departure, .arrival]`) + 시각 칩 전용 ChipFlow, `anchored == false`면 기준 줄 통째로 부재
- REQ-003: `departureAnchored`가 `$0.kind == .datetime && $0.anchored`만 봄 — `currentBasis`의 `?? .departure` 폴백은 바이트 무변경(AC-003 (5))

리드 재실측(관측된 출력 — 구현자 보고와 별개로 이 세션이 직접 실행):
- `grep -c '"arr:" ?' Shared/EditCard.swift` = **0** · `grep -c 'kind == .datetime })' Shared/EditCardView.swift` = **0** · `grep -c 'ScheduleAnchor.arrival, .departure'` = **0** · `.departure, .arrival` = **1** · datetimeRow 내 ChipFlow = **2** · 생성부 `kind: .datetime` AddEventView **1** + AIAssistant **1** · `anchor(ofPrefix:)` 본문 diff 무변경
- 드라이버(워크트리 CLAUDE.md 레시피): compile-exit **0**, **205/205 통과** — 단언 추가 0건(REQ-040 (a))
- iOS 빌드: exit **0**, BUILD SUCCEEDED **1**, 툴체인 경고 제외 **0건**
- macOS 빌드: exit **0**, BUILD SUCCEEDED **1**, 툴체인 경고 제외 **0건** (리드 재실측, 커밋 직전)

미검증(M5/AC-010 이월): 카드 렌더링·제스처·낭독은 가드 밖 — AC-001 (6) 시뮬레이터 확인, AC-002 (3)(4)(5), AC-003 (2)(3)의 기기 관측.
M3 인계 감시(ui-design 검수 지목, LOW): `AddActivityView`가 진짜 true를 돌려주는 `chooseTimePlain`을 넘기는지 — 깜빡하면 확인 버튼이 조용히 죽는다(REQ-001 (d)의 실패 모양).

### M3 — AddActivityView 전환 (REQ-010~014) 🟢

구현: `hns-besir-app-swift-impl-specialist`(spawn m3-swift-impl) · 설계 검수: `hns-besir-app-ui-design-specialist`(spawn m3-ui-design, 판정 **GO** — 7렌즈 통과·줄 순서 6경로 추적 무결·범위 내 수정 0건).

변경: `Shared/AddActivityView.swift` 하나(+392/−104) — 폼 @State 12개 → `card` 하나, 다리·알림·여유 줄 멤버십, 캡션 삭제, PlaceField 색 3건 수리.
- REQ-010: `canSave` 삭제·잠금 `!(card?.isReady ?? false)`, save()는 카드에서 값 읽음
- REQ-011: 다리 `.toggle` 줄(만들기/안 만들기) + 멤버십(장소가 실제 장소일 때만 다리 줄 생성, "장소 없음"·미선택 시 제거), 꺼진 동안 기억값(출발지·수단·여유·복귀·알림), 안내 문구는 장소 줄 note로
- REQ-012: 알림 리드 줄(본보기와 같은 넷 + 직접입력, seed 30), off 시 lastNotifyLead 기억
- REQ-014: **"가는 편 도착 여유"** 줄(0/10/20/30 + 직접입력, seed 10, 가는 편 on일 때만), 캡션 통째 삭제, 복귀 버퍼 0은 Store 무변경
- REQ-013: 카드 `.task` 1회 생성·고정 위치·크롬 off, header/footer/프레임 유지
- REQ-042(c): PlaceField `.secondary`→`Theme.muted` 2건·`.quaternary`→`Theme.raised` 1건

구현자의 추가 방어(리드 승인): 시작을 종료 뒤로 재확정하면 확정된 종료를 미선택으로 되돌림 — 확정 시점 거절만으로는 **반대편 줄이 나중에 바뀌는 경로**(종료 5시 확정 후 시작 6시 → 종료≤시작인 채 isReady 풀림)를 못 막으므로 옛 `endDate > startDate` 저장 잠금의 계승이다(REQ-030 어포던스 손실 0 근거).

리드 재실측(관측된 출력):
- `canSave` **0** · `defaultNotify|defaultBuffer` **0** · `.secondary|.quaternary` **0** · `onChange` **0** · `^struct PlaceField` **1** · `PlaceSearchDebouncer` **1**(카드용) · `@State` **15**(화면 12 + PlaceField 3)
- 다리 줄 코드 전부 choose()·빌더·save() 안(렌더 경로 밖 — 줄번호 전수 확인) = 멤버십 not 숨김
- 드라이버: compile-exit **0**, **205/205 통과**(단언 추가 없음)
- iOS·macOS 빌드: 양쪽 exit **0** · BUILD SUCCEEDED · 툴체인 경고 제외 **0건**
- `git diff --stat`: AddActivityView.swift 1파일

AC 정정 필요 1건(구현자 보고·리드 확인): AC-009 (7)(b)의 `grep -c "PlaceSearchDebouncer" Shared/AddActivityView.swift` = 0은 카드 검색 디바운서(본보기와 같은 화면 소유 인스턴스)와 어긋나 실측 **1** — REQ-042(b)의 의도(PlaceField 자체에 부착 금지)에 맞게 문구를 정정한다(manager-spec).

미검증(M5/AC-010 이월): 멤버십 런타임(가는 이동 켜고 끄기·되살림), 여유 줄 미흐림(AC-010 (6)), 캡션 부재(8), 저장값 반영(10).
후속(범위 밖, sync에서 루트 plan.md에): PlaceField cornerRadius 8→Theme.radius, PlaceField 돋보기 버튼 라벨 없음(:518), ConflictBanner 잔여(:601·:604·radius).

### M4 — ActivityDetailView 전환 (REQ-020~021) 🟢

구현: `hns-besir-app-swift-impl-specialist`(spawn m4-swift-impl) · 설계 검수: `hns-besir-app-ui-design-specialist`(spawn m4-ui-design, 판정 **GO** — 7렌즈 통과·차단 0·마이너 2건 연기 판정).

변경: `Shared/ActivityDetailView.swift` 하나(+226/−55).
- REQ-020: @State 5개 + load() → card 하나(.task 1회, 편집 모드 전 줄 chosen 시드), Form/Section → ScrollView+Theme.bg, 화면 소유 유지(툴바·반복 안내·주변 섹션·삭제+대화상자 2), 저장 disabled = !isReady, 시각 거절은 M3와 동일(note + 시작 재확정 무효화)
- REQ-021: newPlace = confirmedPlace("location_query")(좌표가 값과 함께), `?? 0` 구문 삭제, 장소 변경(≠재탭) 시 nearby·nearbyLoaded 비움, "장소 없음" 칩으로 장소 제거 가능(→ nil), 주변 섹션 내부 줄 바이트 불변(문서화 잔여 5건 보존)
- 판단 1건(기록): 반복 회차 안내 Text를 새 레이아웃에 맞게 다시 쓰며 `.secondary` → `Theme.muted`(계약 6 — 소유 파일에 새 위반을 만들지 않기 위해; 주변 섹션의 문서화 잔여와 대비됨)

리드 재실측(관측된 출력):
- `?? 0` **0** · `Form {` **0** · `modifyActivity` **2**(호출+주석)·직접 `store.updateActivity` 호출 **0** · `.secondary|.tertiary` **5**(전부 주변 섹션 문서화 잔여) · `@State` **9**(명단: card·confirmedPlaces·placeDebounce·showingDeleteMenu·showingDeleteConfirm·nearby·nearbyCategory·loadingNearby·nearbyLoaded) · 생성부 여전히 AddEventView **1** + AIAssistant **1**
- 드라이버: compile-exit **0**, **205/205 통과**(단언 추가 없음)
- iOS·macOS 빌드: 양쪽 exit **0** · BUILD SUCCEEDED · 툴체인 경고 제외 **0건**
- `git diff --stat`: ActivityDetailView.swift 1파일

검수 연기 판정(기록): 삭제 단추 정렬은 EventDetailView 문법과 어긋나나 AC-007 "32절 그대로" 계약을 지키기 위해 현행 유지 — sync에서 루트 plan.md 후속 항목으로. 편집 중 "장소 없음"에서 주변 섹션이 옛 저장 장소 기준으로 보이는 것은 설계된 경계(placeCoord=store 기준) — 실기기 확인 목록에.

미검증(M5/AC-010 이월): 장소 재선택 후 추천 비움(AC-006 (5)), 카드 문법으로 열리는 모습(11), 홍대 재검색(12).

### M5 — 보존 대조·접근성·게이트 (REQ-030~031, 040~042) 🟢

검사: `hns-besir-app-code-safety-specialist`(spawn m5-code-safety, **FIX-FIRST → 수정 완료**) · `hns-besir-app-ux-check-specialist`(spawn m5-ux-check, 36절 개별 대조·AC-008 인벤토리·AC-010 스크립트). 수정: `hns-besir-app-swift-impl-specialist`(spawn m5-fix).

**AC-007 (36절 개별 대조, ux-check)**: ✅ **34** · ⚠️ 2(4절·24절) · ❌ 0. 세기 명령 실측 34(+접두 2)=36. ⚠️ 둘과 5절은 **후시 선언 (e)(f)(g)**으로 acceptance에 선언 목록에 편입(문서 델타) — 계획이 빠뜨린 변경을 대조에서 덮어 숨기지 않고 적었다.

**AC-008 (접근성)**: 순증 8건(줄 그룹 낭독·3중 선택 표현·.isSelected·@ScaledMetric 칩 높이 등 — 원본 두 화면 접근성 호출 실측 0/0) · 상실 선언 3종에 후시 1종(F-3 그룹 머리글 — 줄 이름 낭독 유지로 기능 손실 없음) 추가. 미선언 상실은 F-3 하나뿐이었고 선언으로 편입.

**code-safety (4중 위험 렌즈 전 가동)**:
- **MAJOR-1 수정** — 이미 켠 "만들기" 칩 재탭이 다리 줄을 중복 삽입해 `field()` 첫 줄 읽기로 저장값이 씨앗값으로 굳는 경로. 멤버십 가드 2곳(`!contains(origin_query/return_query)`)으로 폐쇄(본보기 AddEventView:268 관용구).
- **MINOR-1 수정** — `rememberTravelValues`의 무조건 대입이 다리 끈 뒤 "장소 없음" 선택 시 기억 장소를 nil로 지우던 것. `if let` 2줄로 폐쇄.
- **MINOR-2 기록** — 같은 이름 즐겨찾기/저장 장소 좌표 경계(bootstrap이 저장 좌표로 덮음): 반대로 뒤집으면 무손상 편집이 조용히 장소를 옮기므로 현행 유지 — plan.md 후속.
- **MINOR-3 기록** — `chooseTimePlain` 시작/종료 교차검증이 두 화면에 바이트 동일 중복(본보기에 없던 새 계산 — 계약 5 노출). 5번째 파일 필요라 이 카드 밖 — plan.md 후속(D-2 A안 곁에).
- 렌즈 0건 통과 기록: H1 await 인덱스 0 · H2 조용한 실패 0(SPEC 명명 함정 — chooseTimePlain 양 화면 배선 확인) · H3 외부 한도 0(묶음·상한·순서 정상) · 강제 언래핑 0 · 카드 신원 0 · 데드 코드 0.

**게이트 (리드 재실측, 최종 트리 기준)**:
- 드라이버: compile-exit **0**, **205/205 통과**(단언 추가 없음). **비결정성 기록(잔여 위험)**: 같은 바이너리 4회에 205→203→196→(실패 상세)로 도는 것을 관측 — 전 실패가 "이 환경에서 이동시간 조회가 된다" 전제(`seconds=nil`, 살아 있는 ODay 조회)에서 파생하는 C1/C2/C3·J 시나리오. 이 카드는 드라이버 커버리지 파일(뷰 제외)을 안 건드렸으므로(REQ-041 실측) 회귀가 아니라 환경 요동이고, 205/205는 M2·M3·M4 체크포인트와 최종 트리에서 각 1회씩 관측됐다.
- iOS·macOS 빌드: 양쪽 exit **0** · BUILD SUCCEEDED · 툴체인 경고 제외 **0건**(M5 수정 후 재실측)
- 프록시: **7/7 통과**
- 범위: 추가 `Shared/*.swift` **0건**(xcodegen·Team 재선택 없음) · 변경 `.moai/` 밖 **정확히 4 파일**(REQ-041) · `AddEventView`·`AIAssistant`·`AIChatView`·`Store`·`FullSirView` 무변경

**AC-010 (대체 불가능 증거 — 운영자 실행 대기)**: 초기화(설정→"일정 모두 삭제") 후 15단계 + VoiceOver 16단계 스크립트와 실기기 전용 4건을 ux-check가 작성·전달(완료 보고서 첨부). 이 프로젝트의 검증 관례대로 입력 문구·기대 결과를 정확히 준 형태이며, UI 조작은 사용자가 시뮬레이터에서 실행한다(테스트 타깃 부재로 자동화 불가 — "정말 못 하는 것만 넘긴다" 경계).

**sync 인계 — 루트 plan.md 후속 항목 목록**(REQ-041: 전환 중 눈에 띈 개선은 plan.md에):
1. PlaceSearchDebouncer 최소 글자수 게이트(F-6(ii), 컴포넌트 — 무변경 계약의 두 화면이 함께 바뀜)
2. `chooseTimePlain` 교차검증 단일 출처화(MINOR-3, D-2 A안과 함께 검토 — 5번째 파일)
3. PlaceField cornerRadius 8→Theme.radius(:501 계열)
4. PlaceField 돋보기 버튼 접근성 라벨(:518)
5. ConflictBanner 잔여 계약 6 위반·radius(AddEventView:601·:604)
6. ActivityDetailView 삭제 단추 정렬(EventDetailView 문법과 — AC-007 "그대로" 계약 유지를 위해 이번엔 못 고침)
7. 고른 장소 주소 상시 표시 원하면(후시 선언 (g) 참조)
8. 같은 이름 즐겨찾기/저장 장소 좌표 경계(MINOR-2)
9. "주변" 섹션 헤더 .isHeader 특성(AC-008 후속 — Form 랜드마크 낭독 부분 회복)
10. 토글 문구 "맞춰 도착"과 여유 분의 긴장(문구 정리 때)
11. 루트 plan.md §Phase 1.7 t3 행 갱신: 카드 본문에 없던 차이(기준 없는 시각 줄)가 새로 판단됐음을 반영

## §E.3 Run-phase Audit-Ready Signal

- run_status: **audit-ready**
- run_complete_at: 2026-09-22T12:00+09:00 (M5 커밋 시점)
- 마일스톤 커밋: M2 `d0465e3` · M3 `e341da1` · (AC 정정 `8cbc47a`) · M4 `707b371` · M5 (이번 커밋 — 수정+문서 델타)
- 게이트 요약(전부 리드 직접 관측): 드라이버 205/205(비결정성 기록 위 참조) · iOS·macOS 무경고 · 프록시 7/7 · diff 4 파일·추가 0
- Phase 1 게이트: plan-audit iteration 1 FAIL → 델타 수정 → iteration 2 **PASS**(aggregate 약 0.93)
- 하네스 로스터 실행: swift-impl 4회(M2·M3·M4·M5-fix) · ui-design 3회(M2·M3·M4 검수 전 GO) · code-safety 1회(FIX-FIRST 1+1 → 수정·재검증) · ux-check 1회(36절 대조·AC-008·AC-010 스크립트) — plan.md §2 배정표 전부 이행
- **Gaps(명시)**: AC-010 시뮬레이터 15+1단계·실기기 4건은 운영자 실행 대기(빌드로 검증 불가). 드라이버 비결정성(환경 요동)은 AC 기록에 남은 잔여 위험.
- **Residual-risk**: 라이브 이동시간 조회 의존 드라이버 시나리오의 환경 요동 · F-1~F-6 후시 선언의 운영자 승인 여부(완료 보고서에 표시 — sync에서 재확인) · 같은 이름 장소 좌표 경계(MINOR-2, 저빈도).

## §E.3 Run-phase Audit-Ready Signal

(모든 마일스톤·게이트가 끝난 뒤 채운다.)
