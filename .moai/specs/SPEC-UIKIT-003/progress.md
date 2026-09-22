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

### M3 — AddActivityView 전환 (REQ-010~014)

⬜ 대기 (M2 완료 후 — REQ-014는 REQ-003을 요구)

### M4 — ActivityDetailView 전환 (REQ-020~021)

⬜ 대기

### M5 — 보존 대조·접근성·게이트 (REQ-030~031, 040~042)

⬜ 대기

## §E.3 Run-phase Audit-Ready Signal

(모든 마일스톤·게이트가 끝난 뒤 채운다.)
