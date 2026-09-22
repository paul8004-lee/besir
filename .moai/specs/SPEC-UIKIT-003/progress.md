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

**AC-010 (대체 불가능 증거 — 운영자 실행 대기)**: 아래 스크립트는 ux-check가 작성·리드가 영속화(오탈자 1건·칩 문구 실측 반영). 이 프로젝트의 검증 관례대로 입력 문구·기대 결과를 정확히 준 형태이며, UI 조작은 사용자가 시뮬레이터에서 실행한다(테스트 타깃 부재로 자동화 불가 — "정말 못 하는 것만 넘긴다" 경계).

**시뮬레이터 스크립트 (iPhone 17 Pro)** — 초기화: besir 실행 → 설정 탭 → "일정 모두 삭제" → "모두 삭제" → 시간표 복귀.

| 단계 | 입력 | 기대 결과 | 실패 시 |
|---|---|---|---|
| 1 | "+"→활동 추가, 제목칸에 `스터디 모임` → 확인 | 입력칸이 처음부터 열려 있고 제목 칩 확정(체크+굵게) | AC-004 (1) |
| 2 | "장소 검색" 칩 → `강남역` 입력 → 후보 탭 | 이름+주소 후보 → 탭 순간 확정, 글자 안 지워짐 | AC-004 (2)·AC-005 (7) |
| 3 | 시작 줄 → 내일 오후 2:00 → 확인 | 칩 확정. **기준 칩 줄이 없어야 함** | AC-001 (6)·AC-002 (3) |
| 4 | 종료 줄 → 오늘 오전 9시 → 확인 | 확정 안 됨 + note "종료는 시작보다 뒤여야 해요" + 에디터 유지 → 이어서 내일 오후 4시 확정 | REQ-030(a) |
| 5 | "가는 이동" 만들기 → 출발지 `서울역`·"대중교통" | 출발지·이동수단·"가는 편 도착 여유" 세 줄 등장 | AC-004 (3)·REQ-011 |
| 6 | 여유 줄 관찰 | **흐려지지 않고 "출발 기준이라 쓰지 않아요" 없음** → "20분" 확정 | AC-003 (3)·REQ-003 |
| 7 | 알림 "1시간 전" → 끄기 → 재켬 | 끄면 줄 소멸, 재켬 시 "1시간 전" 부활 | REQ-012·AC-005 |
| 8 | 화면 전체 | "여유 10분 · 알림 30분 전" 문구 없음 | AC-005 (3) |
| 9 | "가는 이동" 안 만들기 → 재켬 | 세 줄 소멸 → `서울역`·`대중교통`·`20분` 부활 | AC-004 (4) |
| 10 | "추가" → 이동 블록 상세 | 활동+이동 블록 표시, 도착 여유 **20분**(10분이면 REQ-014 실패) | AC-005 (6) |
| 11 | 활동 블록 탭 | 상세가 Form 아닌 카드 문법 | AC-006 (2) |
| 12 | 상세에서 장소 `홍대입구역` 재선택·저장 → 추천 보기 | 홍대 주변(강남 잔존 ❌) | AC-006 (5)·REQ-021 |
| 13 | 이동 일정 추가 폼 시각 줄 | 출발→도착 기준 한 줄 + 아래 시각 칩; 출발 기준 고르면 도착 여유 흐려짐(기존 동작) | AC-002 (3)(i)·AC-003 (2) |
| 14 | AI 채팅 `내일 3시에 강남역 가야 해` | 되묻기 카드 시각 줄 같은 배치 | AC-002 (3)(ii) |
| 15 | 설정→손쉬운 사용→텍스트 최대 → 1·3·13 재확인 | 칩 안 잘림, 시각 칩이 기준 칩 옆으로 안 올라감 | AC-002 (4) |
| 16 | VoiceOver 켜고 활동 추가 | 각 줄 "줄 이름+고른 값" 이어 읽기, 이름 없는 버튼 없음 | AC-008 (3) |

**실기기 전용** (시뮬레이터 대체 불가): ① 출발 알림 실제 수신(리드 시간이 고른 값 그대로) ② 칩 44pt·날짜 바퀴 손맛 ③ 구글 캘린더 앱에서 활동·이동 블록 묶임 ④ VoiceOver 실제 음성.

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

## §E.4 Sync-phase Audit-Ready Signal

sync_status: audit-ready — **sync 단계 종료(3-phase close, 단일 sync 커밋)**
sync_complete_at: 2026-09-22
sync_commit_sha: d5203cb

**이 sync는 문서만 만지고 끝나지 않았다.** 독립 렌즈가 확정 결함 하나를 냈고 카드가 run으로
되돌아갔다가 돌아왔다 — 경위는 아래 §독립 렌즈에 있다. 그래서 이 커밋에는 `Shared/` 두 파일의
수정이 함께 실린다.

### 게이트 — sync lane이 최종 트리에서 직접 실측

**귀속.** run이 닫힌 HEAD는 `28d097a`이고 그 뒤 소스 커밋은 없다(`git diff --name-only b83e260..HEAD`가
`.moai/specs/` 셋만 돌려준다). 이 커밋이 싣는 소스 변경은 sync에서 난 MAJOR-A·MINOR-C 수정
둘뿐이며, **아래 값은 그 수정이 들어간 작업 트리에서 잰 것이다.** 수정 이전 트리에서도 한 번 재어
동일했으나(205/205·무경고·7/7), 그 값은 이 커밋이 싣는 코드의 값이 아니므로 인용하지 않는다.

| 게이트 | 결과 | 관측 |
|---|---|---|
| 가드 드라이버 | ✅ **205/205**, compile-exit=0 · run-exit=0 | 비툴체인 경고 **0건**(전체 24건 전부 SDK `DeprecatedDeclaration`). `Tools/` diff **0줄** = 단언 추가 0건(REQ-040 (a)). 불변식 "전체 실행 뒤에도 `autoAddToCalendar`는 꺼져 있다" 통과 — 드라이버가 실제 캘린더를 건드리던 사고(`9a5b3d6`)의 재발 없음 |
| iOS 빌드 | ✅ `BUILD SUCCEEDED` **1**, exit=0 | **Swift 소스 경고 0건.** 전체 `warning:` 1건은 `appintentsmetadataprocessor`의 "No AppIntents.framework dependency found"로 어떤 `.swift`도 가리키지 않는 툴체인 경고다(게이트가 제외하는 부류). `build-ios.log` |
| macOS 빌드 | ✅ `BUILD SUCCEEDED` **1**, exit=0 | **Swift 소스 경고 0건.** 툴체인 경고 1건은 iOS와 동일 문구. `build-mac.log` |
| 프록시 npm test | ✅ **7/7**, exit=0 | 본 카드는 프록시 무변경 — 변환층이 조용히 깨지지 않았음의 확인 |
| REQ-040 (d) 신규 소스 | ✅ **0건** | `git diff --name-only --diff-filter=A 30be9ad -- 'Shared/*.swift'` → 0. xcodegen 불필요 · **두 타깃 Team 재선택 요청 없음** |
| REQ-041 파일 집합 | ✅ **정확히 넷** | `ActivityDetailView`(+249/−55) · `AddActivityView`(+464/−102) · `EditCard`(+27/−6) · `EditCardView`(+36/−15). `AddEventView`·`AIAssistant`·`AIChatView`·`Store`·`FullSirView` 전부 무변경 |
| REQ-021 기계 신호 | ✅ **0** | `grep -c "?? 0" Shared/ActivityDetailView.swift` |

**경고 표기 주의 1건.** 수정 이전 실행에서는 양쪽 `warning:` 총계가 0이었는데 최종 실행에서 1이
됐다. 증분 빌드라 `appintentsmetadataprocessor` 단계가 앞 실행에서 돌지 않았을 뿐이고, 경고 원문이
어떤 소스도 가리키지 않는다(`grep 'warning:' | grep -c '\.swift'`가 양쪽 **0**). 총계만 보고
"경고가 늘었다"로 읽으면 틀린다 — **게이트의 기준은 총계가 아니라 소스를 가리키는 경고다.**

**기준선 정정 1건.** AC-009 (5)(6)은 `origin/master...HEAD`로 재라고 적혀 있다. 로컬 `master`는
`291db49`에 멈춰 있어 그것으로 재면 t1·t2·t4 몫까지 여덟 파일이 t3에 붙는다 — 그러나
**`origin/master`는 이미 `30be9ad`**(t4까지의 병합분)이라 AC 문구 그대로가 옳다. 처음에 로컬
`master`로 재어 여덟 파일을 본 것을 원격 ref 확인으로 정정했다.

각 명령은 자기 `cd`를 스스로 들고 순차 실행했다(병렬 `cd` 오염 함정 재발 방지). 드라이버 산출물은
`/tmp/gd`가 아니라 세션 전용 스크래치패드에 뒀다 — `/tmp`는 동시에 도는 다른 세션과 겹친다.
레시피는 **워크트리의** `CLAUDE.md`를 따랐다(주 체크아웃판과 달리 `Shared/EditCard.swift`가 컴파일
집합에 들어간다 — 브랜치마다 다르므로 워크트리 것을 쓴다).

### 독립 렌즈 (code-safety, `--deep`) — **FIX-FIRST**, 카드가 run으로 되돌아갔다

스폰은 정상이었다(2026-09-20 기억의 기계 공통 결함은 이 세션에서 재현되지 않았다). 다만 렌즈가
분석을 마치고도 `SendMessage` 없이 텍스트로만 내 리드에 닿지 않았고, 리드가 `idle` 표시를 완료로
읽지 않고 직접 물어 회수했다 — **idle은 "끝났다"와 "멈췄다"와 "죽었다"를 가르지 못하므로 완료
신호가 아니다.**

**확정 결함 MAJOR-A · 이름-키 장소 사전이 한 화면의 장소 줄 셋을 공유한다.**

`AddActivityView:21`의 `confirmedPlaces: [String: Place]` 하나를 장소 줄 셋(`:123` 장소 ·
`:281` 출발지 · `:298` 도착지)이 공유한다. `choosePlace`(`:356`)가 `confirmedPlaces[place.name]`에
쓰고 `confirmedPlace(_:)`(`:428`)가 줄의 `chosen` 문자열로 되읽으므로, 같은 상호의 다른 지점을
두 줄에 고르면 나중 쓰기가 앞 좌표를 덮고 **두 줄이 같은 좌표를 되읽는다.** 결과는 둘이다 —
활동이 사용자가 고른 적 없는 좌표로 저장되고, 출발지 == 도착지가 되어 0분 이동 구간과 활동
시작 시각에 울리는 출발 알림이 생긴다. 화면에는 이름만 보여 알아챌 신호가 없다.

리드가 렌즈 판정을 그대로 받지 않고 기계적 사실 일곱을 직접 재확인했다(전부 일치):
base `30be9ad`의 독립 바인딩 셋(`locationPlace:15`·`originPlace:22`·`returnPlace:24`) ·
현재의 사전 하나와 줄 셋 · `isSamePlace`가 `AIAssistant.swift` 세 줄뿐이고 `create_schedule`
전용(`:2279` 정의 · `:1297` 호출 · `:1613` 언급) · `Store`에 출발지==도착지 판정 없음 ·
`Models.swift:108`이 "이름이 겹칠 수 있어 좌표까지 포함한 값 전체로 구분"이라 적어 둔 것 ·
`PlaceSearch.swift:126`의 MapKit 폴백 `Place(name: item.name ?? p.name ?? query, ...)`가 한 결과
목록 안에서 같은 이름을 여러 번 내는 것 · `AIAssistant.swift:2318`의 "화면에는 같은 이름이 찍혀
있어 알아챌 방법도 없다".

**범위 밖이 아니라 이 카드의 인수 기준 미충족이다.** REQ-021(`spec.md:119`)이 "Editing the place
shall carry its coordinates — 고른 장소의 좌표가 `confirmedPlaces`에서 값과 함께 온다"이고,
§1.2 결함의 본체(`spec.md:53`)가 "이름만 바꾸고 좌표는 옛 장소의 것을 그대로 쓴다"이다. 충돌은
그 실패가 형태만 바꾼 것이고, `spec.md:121`이 이미 "§1.2의 증상이 형태만 바꿔 살아남는 경로"로
경고해 둔 자리다.

**이 카드가 연 경로다.** 옛 폼은 좌표가 줄마다 붙어 있어 충돌이 구조적으로 불가능했고, 전환이
셋을 사전 하나로 합치며 열었다. 그리고 **t3만의 것이 아니다** — `AddEventView`도 통일 전
`originPlace`·`selectedPlace` 독립 둘이었다가 카드 t2에서 같은 형태가 됐다(`:17` 주석이
"`AIAssistant.confirmedPlaces`와 같은 형태"라고 적어 둔 대로 AI 카드의 모양을 따라온 것이다).
통일이 화면마다 좌표 안전성을 하나씩 버려온 **계통적 회귀**다.

**운영자 판정(2026-09-22): t3 안에서 닫는다.** 사전 키를 이름에서 줄 신원(`EditField.id`)으로
바꾼다 — REQ-041의 네 파일 경계 안이고 새 파일이 없다. 남은 둘(`AddEventView` 줄 2 ·
`AIAssistant` 줄 5)은 루트 `plan.md` 후속 8번으로, 같은 4줄 변경을 한 카드에 묶는다.

**함께 고친 것 — MINOR-C(주석이 없는 메커니즘을 가리킨다).** `AddActivityView:325` ·
`ActivityDetailView:192`의 "false를 돌려주면 카드 뷰가 거절 문법을 띄운다"가 사실이 아니다.
거절 표시는 `rejected` 집합이 그리는데 `rejected.insert`는 `EditCardView:440` 한 곳, 텍스트
에디터의 `submitCustom` 경로뿐이고, 시각 줄 확인은 에디터를 열어둘 뿐 `rejected`를 건드리지
않는다. 실제 피드백은 `chooseTimePlain`이 스스로 다는 `note`다. 동작은 맞고 주석만 틀렸으나,
이 프로젝트의 주석은 읽히는 대신 **믿기므로** 다음 사람이 `note`를 지워 그 줄의 유일한 피드백을
없앨 수 있다.

**렌즈가 돌린 0건 기록** — H1 await 인덱스 무효화 0(diff의 await 셋을 전수: `save()`는 읽기가
전부 인자식이라 중단 이전 평가, `searchPlaces` armed 클로저는 `setLookup`이 id로 재조회, 
`loadNearby`는 인덱스를 안 잡음) · H2 조용한 실패 신규 0(`try?`는 `EditCard:326`의 `Task.sleep`
하나뿐이고 diff 헝크 밖) · H3 외부 한도 0(알림 최대 2건, 디바운서가 양 화면에서 정상 소유,
`cancelAll()` 양쪽) · 강제 언래핑 0 · 경계 조건 0(자정 넘김·빈 배열·동시각 인접) · 카드 신원
혼동 0 · M5 수정 2건 재검증 **둘 다 닫힘**(다리 줄 `.insert(` 6곳 모두 앞에 멤버십 가드,
우회 경로 없음 / 기억값 7개 대입이 `:223` 하나만 직접이고 값이 칩 문자열이라 항상 유효).

**렌즈가 못 돌린 것(명시)** — iOS·macOS 빌드와 가드 드라이버(리드 지시로 제외, 위 게이트 표가
덮는다) · AC-010 시뮬레이터·실기기(여기서 실행 불가) · MAJOR-A의 런타임 재현(코드만 읽음) ·
MINOR-E의 AI 활동 생성 경로 · SPEC 문서 전수 대조 · `AIAssistant`/`AddEventView`/`Store` 전면
검토. 렌즈가 `progress.md`를 읽은 시점에 sync 레인이 그 파일을 수정 중이었다는 것도 스스로 적었다.

### 렌즈가 반증한 run 기록 2건 — 덮지 않고 정정으로 남긴다

1. **MINOR-3의 중복 규모.** `progress.md` §E.2 M5는 `chooseTimePlain` 26줄 하나를 "바이트 동일
   중복"으로 적었다. 실측은 **7블록 81줄 + `noPlaceMarker` 상수**다(`chooseTimePlain` 26 ·
   `searchPlaces` 20 · `field`/`chosenIn`/`confirmedPlace` 12 · `finishPlaceSearch` 7 ·
   `submitCustom` 7 · `setLookup` 5 · `choosePlace` 4 — 7건 모두 `diff` exit 0). run의 기록은
   **run이 관측한 것**이므로 고쳐 덮지 않고, 루트 `plan.md` 후속 2번의 범위를 넓히고 여기 적는다.
2. **파일별 증감 줄 수.** §E.2가 적은 `AddActivityView` +392/−104 · `EditCard` +33/−7 ·
   `EditCardView` +30/−14는 M5 커밋(`b83e260`) 이전 측정이다. sync가 이 값을 실측 없이 옮겨
   `CHECKLIST.md` 기준선 블록에 한 번 적었다가 렌즈의 재실측에 반증당했다 — **세거나 실측하지
   않은 수치를 옮겨 적은 것이고, 이 프로젝트가 이미 데인 자리다.** 최종 값은 아래 §최종 실측에
   있으며 `CHECKLIST.md`도 그 값으로 고쳤다.

### MAJOR-A 수정 — 무엇을 어떻게 닫았나

구현은 `hns-besir-app-swift-impl-specialist`(spawn `t3-majorA-fix`), 두 파일만 손댔다.

**열쇠를 이름에서 줄 신원으로.** `confirmedPlaces`가 `[String: Place]` → `[UUID: Place]`(`EditField.id`)가
됐다. 신원은 줄 생성 때 한 번 찍히므로 **두 줄이 겹칠 수가 없다** — 충돌을 막는 것이 아니라
구조적으로 불가능하게 만든다. 즐겨찾기 라벨은 별도 씨앗 사전 `favoritePlaces: [String: Place]`로
갈라냈다(칩 탭은 `Place` 없이 라벨만 들고 오므로 라벨→좌표 해석이 여전히 필요하다).

**쓰기 자리를 하나로.** 파일당 한 줄이다 —
`if c.fields[i].kind == .place { confirmedPlaces[field] = place ?? favoritePlaces[value] }`.
`choosePlace`는 좌표를 미리 적지 않고 `choose`에 인자로 실어 보낸다. 그래서 "검색이 즐겨찾기를
이긴다"가 **호출 순서가 아니라 구조로** 정해진다 — 리드가 지시문에서 경고한 순서 함정(먼저 쓰고
나중에 다시 푸는 형태)을 만들지 않는 방향으로 풀었다. 그 순서인 이유는 두 값의 성격이 다르기
때문이다: 검색 후보는 사용자가 지점까지 특정한 값이고, 즐겨찾기 라벨은 우연히 같을 수 있는
이름일 뿐이다. 반대로 두면 결함이 형태만 바꿔 살아남는다.

**구현자가 더 찾은 함정 1건(리드가 지시문에 넣지 못했던 것).** 다리 토글을 껐다 켜면
`outboundRows`/`returnRows`가 줄을 **새로 만들어** 신원이 바뀐다. 이름 열쇠 시절엔 이름이 그대로라
좌표가 저절로 따라왔지만, 신원 열쇠에서는 되심은 줄의 좌표가 nil이 되어 `travelFrom`이 통째로
사라진다 — **다리는 켜졌는데 출발지 없는 구간이 만들어지는 새 결함**이다. 그래서 기억값에 좌표를
함께 두고(`rememberedOutboundOriginPlace`·`rememberedReturnToPlace`) 되심을 때 `reseed`로 새 신원에
다시 건다. 줄이 빠질 때는 `forgetPlaces`로 그 줄의 좌표를 놓는다.

**`ActivityDetailView`의 작은 충돌도 함께 닫혔다.** 저장된 장소를 이름으로 걸면 같은 이름의
즐겨찾기와 서로를 덮어, 어느 좌표가 살아남는지가 씨앗 뿌린 순서로 정해졌다(run이 MINOR-2로
기록해 둔 그 경계다). 이제 장소 줄을 `locationRow`로 먼저 만들고 그 신원에 건다.

**리드가 diff를 직접 읽고 확인한 것** — 순서 두 곳이 맞다: `rememberOutboundOrigin`/
`rememberTravelValues`의 좌표 **읽기가** `forgetPlaces`의 **지우기보다 먼저**고, `reseed`의 신원
걸기가 `insert`보다 먼저다(구현자가 `insert(contentsOf:)`의 신원 보존을 별도 증명 스크립트로
실측했다). `:184`의 "진짜 장소인가" 판정은 `confirmedPlaces[field] != nil`로 뜻이 보존된다.

**리드가 찾은 의미 변화 1건(구현자 보고에 없던 것).** `confirmedPlace(_:)`가
`field(key)?.chosen.flatMap { confirmedPlaces[$0] }` → `field(key).flatMap { confirmedPlaces[$0.id] }`로
바뀌며 **`chosen != nil` 요구를 잃었다.** 좌표만 걸린 줄이 이름 없이도 좌표를 돌려주게 된다.
현재 도달 불가로 판단한 근거는 §잔여 위험 3에 적었다.

**MINOR-C(틀린 주석)도 함께 닫혔다.** 구현자가 확인 과정에서 렌즈 주장보다 **한 단계 강한 사실**을
찾았다 — 거절 표시 `Text`(`EditCardView:135`)는 `if field.kind == .datetime`(`:110`)의 **else 가지
안**에 있다. 시각 줄 id가 `rejected`에 들어가더라도 그 뷰는 트리에 존재조차 하지 않는다.
"집합에 안 넣는다"가 아니라 "넣어도 못 그린다"이며, 리드가 두 줄을 직접 읽어 확인했다.

### 렌즈 재판정 — **GO**

같은 렌즈(`t3-deep-lens`)에게 수정본을 다시 읽혔다. 판정 **GO**, 새 결함 **0건**. 리드가 물은
다섯 가지에 대한 답이다(전부 "검증"으로 표시된 것만 인용한다).

1. **즐겨찾기 칩 경로도 닫혔다.** 세 경로 전부 좌표를 쓴다 — 칩 탭은 `choose`에서
   `favoritePlaces[value]`로, 검색 후보는 실려 온 `place`로, "장소 없음"은 어느 쪽에도 없어 nil로
   옛 좌표를 지운다. **가장 하중이 큰 확인**: 렌즈가 주석을 믿지 않고 `EditCardView`를 직접 읽어
   `.place` 줄의 `chosen` 쓰기가 전부 `choose`를 지난다는 것을 세웠다(`customEditor`가
   `placeSearchEditor`/`textCustomEditor`로 갈리고 `submitCustom`은 후자 안에서만 불린다).
2. **`reseed` → `insert` 순서 안전.** `EditField.id`는 `EditCard.swift:132`의 `let id = UUID()`,
   구조체 값 복사가 신원을 넘긴다. `.place` 줄을 만드는 곳은 정확히 셋이고 뒤 둘은 reseed가
   insert와 **같은 가드 안 바로 앞줄**에 있다 — reseed 없는 재생성 경로 없음.
3. **읽기가 지우기보다 먼저** — 세 가지 가지 전부. `forgetPlaces`가 `removeAll` 뒤에 있었다면
   키를 못 찾아 조용히 no-op 하고 사전이 샜을 자리다.
4. **`confirmedPlace`의 의미 변화는 도달 불가**(리드 논증 확인). 좌표가 있는데 이름이 없는 상태를
   만드는 쓰기가 없다 — `choose:179`는 바로 앞줄이 비옵셔널 `chosen`을 적고, `reseed`의 place는
   `guard let o = f.chosen` 아래에서 이름과 함께 쓰인 값이며, `bootstrap:144`의 `chosen`도 비지
   않는다. **다만 렌즈가 한 절을 되돌리기를 권했고 리드가 받아들였다** — 아래 참조.
5. **새 결함 0건.** 좌표가 줄보다 오래 사는 경로 0(`removeAll` 5곳 전수, `.place`를 지우는 셋은
   전부 앞에 `forgetPlaces`) · 무한 증가 0(`confirmedPlaces`는 줄당 한 칸·동시 최대 3, 다리 켬/끔
   반복의 순증 0. `favoritePlaces`는 bootstrap 1회) · 조용한 실패 신규 0.

**렌즈 권고를 받아 한 절을 되돌렸다 — `confirmedPlace`의 fail-closed 복원.**

```swift
field(key).flatMap { $0.chosen == nil ? nil : confirmedPlaces[$0.id] }
```

렌즈의 논지가 옳다: 옛 가드가 막던 **살아 있는 경로는 없었지만**, 가드가 하던 일은 **실패 방향을
닫아두는 것**이었다. 열쇠가 이름이던 시절엔 이름 없는 줄이 사전을 못 찾아 저절로 nil이 나왔다.
신원 열쇠에서는 "좌표만 걸리고 이름은 없는 줄"이 생기면 그 좌표가 조용히 실려 나간다 —
잘못된 장소보다 없는 장소가 낫다. 불변식이 쓰기 세 자리의 **규율로만** 유지되므로 한 절로 갚아
둔다. 이 프로젝트의 "테스트로 불필요함을 확인하기 전까지 방어를 걷어내지 않는다"가 이 자리에도
걸린다. 렌즈는 이것을 **비차단 권고**로 냈고 차단 사유가 아니라고 명시했다.

구현자(`swift-impl`)가 세션 한도로 종료된 뒤라 리드가 직접 넣었다 — 한 절짜리 **복원**이고
렌즈가 코드까지 제시한 것이라 재설계 여지가 없었다. 소스가 바뀌었으므로 **게이트 넷을 다시
돌렸고**, 아래 §게이트 표의 값이 그 최종 실행 결과다.

**렌즈가 확인하지 않았다고 밝힌 것** — 빌드·드라이버·프록시(리드가 병렬 실행) · **컴파일 여부**
(타입은 눈으로 맞다고 봤으나 빌드로 확인하지 않음 — 리드의 게이트가 덮는다) · macOS 다중 창에서
즐겨찾기를 동시에 바꾸는 경우 · 기기 실행 · 미커밋 문서 4파일(sync 레인 소관) ·
`AddEventView`·`AIAssistant`의 이름-키 사전(설계대로 안 건드림, 카드 t6).

### 루트 문서 정합 — 이 카드가 만든 드리프트를 이 카드가 수리한다

**`CHECKLIST.md` 코드 근거 수리.** 좌표 **10종 · 자리 12곳**. 뜻밖의 결과 하나 — 이 카드가 가장 크게
갈아엎은 두 화면(`AddActivityView` +464/−102 · `ActivityDetailView` +249/−55 — sync 종결 트리 실측)은 **인용이 0건이라
드리프트를 만들지 않았다.** 활동 행(A3·A4·G9·O4 등)이 전부 `AIAssistant.swift`·`Store.swift`를 가리키고
그 둘은 diff 밖이기 때문이다. 민 것은 공유 컴포넌트 둘뿐이다.

| 파일 | 옛 인용 → 새 인용 | 밀린 폭 |
|---|---|---|
| `EditCard.swift` | `:273`→`:294`(350ms 지연 상수) · `:296`→`:317`(같은 질의 스킵) | 균일 **+21** |
| `EditCardView.swift` | `:31-35`(@ScaledMetric) · `:50-54`("말씀하신 대로") | **무변경** |
| " | `:122-125`→`:125-128`(`[장소 검색]` 칩) · `:142-149`→`:145-152`(여유 흐림 캡션) | **+3** |
| " | `:181-242`→`:186-263`(`datetimeRow`~`chip` 머리말) | 시작 +5 · 끝 +21 |
| " | `:218-224`→**`:231-245`**(확인의 basis 가드) | **길이가 바뀜** |
| " | `:297-325`→`:318-346` · `:313-318`→`:334-339` · `:328-349`→`:349-370` · `:461-509`→`:482-530` | 균일 **+21** |

**되짚기 검증이 잡은 오답 1건 (기록).** 확인 버튼의 basis 가드를 처음엔 균일 이동(+18)으로 셈해
`:236-242`로 적었다. 그 좌표는 실제로 `if field.anchored {` 한 줄을 가리킨다 — REQ-001의 `anchored`
분기가 그 클로저 안에서 8줄을 늘려 **폭이 아니라 길이가 바뀌었기** 때문이다. 새 좌표 열 곳을 전부
본문으로 되짚어 읽는 과정에서 드러났다. **산술로 민 좌표는 산술로 검증되지 않는다** — 옛 인용이
가리키던 본문을 새 좌표에서 다시 읽는 것만이 검증이다. 판정 집계는 불변(✅ 102 · ⚠️ 8 · ❌ 2 · — 1).

**루트 `plan.md`.** §Phase 1.7 분할표 t3 행 `대기`→`done`(카드 본문에 없던 차이 — 기준 없는 시각 줄 —
이 plan 단계에서 새로 판단됐음을 함께 적었다). 후속 항목 11건 편입 — REQ-041이 "전환 중 눈에 띈
개선은 코드가 아니라 루트 `plan.md`로"라고 정했기 때문이다. 11번(t3 행 갱신)은 이 sync가 처리했고
남은 열은 공유 컴포넌트 2 · `PlaceField`/`ConflictBanner` 잔여 3 · "그대로" 계약으로 보류 3 ·
접근성·문구 2로 묶어 적었다.

**`progress.md` §E.3 중복 빈 스텁 1건 제거.** 채워진 §E.3 뒤에 빈 스텁이 하나 더 남아 있었다
(163→159줄, `grep -c '^## §E.3'`가 2→**1**).

### AC 매트릭스 종결

**✅ 3 · 🟡 6 · ⬜ 1.** ✅는 AC-004(값이 카드 하나에 산다) · AC-007(36절 대조) · AC-009(게이트와 범위)
셋이고, 전부 sync lane이 명령을 직접 돌려 관측했다. 나머지 여섯(AC-001·002·003·005·006·008)은
**기계 몫은 충족했으나 시뮬레이터 관측이 조건에 들어 있어 🟡**이고, AC-010은 ⬜다.

**여기서 ✅를 달지 않은 것이 이 카드의 판단이다.** 이 프로젝트는 드라이버 88/88 초록을 근거로 Day를
닫았다가 다음 날 실기기에서 결함 일곱을 받은 적이 있다(2026-09-15). 게이트 넷이 전부 초록인 지금이
정확히 그때와 같은 상태이므로, 시뮬레이터가 조건에 든 AC는 올리지 않았다. 🟡→✅의 유일한 경로는
AC-010 실행이다.

**후시 선언 (e)(f)(g) — 2026-09-22 운영자 승인.** §E.3 Residual-risk가 "sync에서 재확인"으로 남긴
항목이다. (e) 4절 검색 버튼 소멸 · (f) 24절 장소 자유 텍스트 소멸 · (g) 5절 주소 상시 표시 소멸,
그리고 AC-008의 F-3(그룹 머리글 상실)까지 넷을 되돌리지 않고 선언으로 남기는 것으로 확정됐다.
(f)는 되돌리면 §1.2의 좌표 결함이 재발하므로 애초에 되돌릴 수 없는 자리였고, (g)는 루트 `plan.md`
후속 7번으로 올라갔다 — 되살린다면 화면이 아니라 컴포넌트에서다.

### 잔여 위험 (sync가 적는다)

1. **AC-010이 아직 안 돌았다.** 시뮬레이터 16단계와 실기기 4건은 운영자 실행 대기다. 게이트 넷이
   초록이고 드라이버가 205/205라는 것이 이 카드가 가진 증거의 천장이며, 이 프로젝트는 그 천장을
   관측으로 갈음했다가 다음 날 결함 일곱을 받은 적이 있다(2026-09-15). MAJOR-A 수정이 더한
   확인 항목 넷은 §최종 실측 아래 목록에 있다.
2. **MAJOR-A 수정은 코드로만 검증됐다.** 렌즈도 "런타임 재현은 안 했다"고 적었고, sync도
   빌드·드라이버·전제 증명까지가 천장이다. 같은 이름 두 지점을 카카오/MapKit 실응답으로 뽑아
   좌표가 실제로 갈라지는지는 기기에서만 보인다.
3. **"좌표와 이름은 늘 함께 쓰인다"는 불변식이 규율로만 유지된다.** `confirmedPlace`의
   fail-closed 절을 되돌려 **이 불변식이 깨져도 잘못된 장소가 실려 나가지는 않게** 했으나(nil이
   나온다), 불변식 자체를 강제하는 코드는 여전히 없다 — 쓰기 세 자리(`choose:179`·`reseed`·
   `ActivityDetailView.bootstrap:144`)가 지키고 있을 뿐이다. 렌즈도 같은 비대칭을 명명했다:
   기억한 이름은 있는데 `Place`가 nil이면 `reseed`가 조용히 no-op이고 줄은 좌표 없이 산다
   (현재 도달 불가). **이 사전에 네 번째 쓰기를 더하는 사람이 확인할 자리다.**
4. **드라이버 비결정성.** run이 기록한 환경 요동(같은 바이너리 4회에 205→203→196)은 살아 있는
   이동시간 조회 전제에서 파생한다. sync 재실측 2회는 모두 205/205였으나 요동 자체가 사라졌다는
   증거는 아니다.
5. **`AddEventView`·`AIAssistant`에 같은 이름-키 부류가 남아 있다.** t3가 닫은 것은 두 화면뿐이고
   앱에는 아직 결함이 산다. 카드 **t6**로 등록됐다(2026-09-22 운영자 승인, t3 병합 후·t5 앞).
6. **MINOR-E(저장 게이트 약화)의 도달 불가는 추정이다.** 렌즈가 `executeCreateActivity` 계열을
   읽지 않았다고 명시했다. 루트 `plan.md` 후속 13번에 그 불확실성째로 적었다.
