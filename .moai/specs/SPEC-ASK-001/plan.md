# SPEC-ASK-001 — plan.md

> 이 문서는 **구현을 앞둔 계획**이다(SPEC-ONTIME-001 plan.md와 달리 as-built 아님). 설계 원본은 루트 `plan.md` §6 Phase 1.5. 루트 `plan.md`는 사용자가 "계획이 실제와 달라지면 그 자리에서 갱신"하는 1차 참조 문서다 — 구현 중 어긋남이 생기면 그 파일과 본 문서를 함께 갱신한다.

## 0. Tier 판단

**Tier: M**

- 근거: 건드리는 파일 4개(`Shared/AIAssistant.swift`, `Shared/Config.swift`, `Shared/AIChatView.swift`, `Tools/GuardDriver.swift`) + 문서 갱신 2종(`SPEC-ONTIME-001` spec.md·acceptance.md); 예상 변경 규모는 제거가 큰 비중을 차지하는 300~1000 LOC 미만; REQ 16건·AC 8건 — REQ 수가 Tier M 상한(16)과 정확히 일치하므로, 추가 REQ가 더 필요해지면 분열 신호다.
- spec.md frontmatter에 `tier: M`으로 반영. design.md/research.md는 Tier L 전용 산출물 — 코드 확인은 spec.md 작성 시 grep 실측(2026-09-15)으로 갈음했다.

## 1. 마일스톤

의사결정 가변성 순서: 사람 검토가 집중해야 할 것(새 타입 인터페이스·UX 흐름)을 앞에 두고, 확정된 제거·기계적 문서 작업은 뒤로 미뤘다. 아래 표는 검토 우선순서이고, 실행 순서는 의존성상 M1 → M2 → M3 → M4 → M5 → M6이다. D-1은 2026-09-15에 확정됐다(선택지 C 묶음 카드 — spec.md §4) — 대기 항목 없음.

| M | REQ | AC | 요약 | 상태 |
|---|---|---|---|---|
| M2 | REQ-011~014 | AC-002, AC-003 | **묶음 카드 경로(신규 타입 인터페이스 — 검토 집중, D-1 선택지 C)** 보류 상태(인자별 선택지·재개할 호출), `Bubble` 카드 case, `AIChatView` 카드 렌더링(스크롤 오버플로 포함), 확인 시 1회 호출, 모든 행의 `[직접입력]`·`0분` 칩 | ⬜ |
| M4 | REQ-040~041 | AC-002/AC-003 파생 | 무기억 불변식 단언 — 디스크 영속 금지(REQ-040)와 요청 간 기억 금지·매번 물음(REQ-041)의 GuardDriver 회귀. 카드 자체는 M2에 구현됨(D-1 확정, 2026-09-15) | ⬜ |
| M1 | REQ-001~005, REQ-010 | AC-001, AC-005(d) | 제거 패스 — 툴 11→9, `ai_memory.json`·프롬프트 3블록·`Config` 선호 필드·저장값 폴백·`applyStatedPreferences` 제거, 생성 도구 인자 선언 축소. **갱신 도구까지 확장할지 여부를 여기서 판단**(판단 결과에 따라 REQ-030 개정 범위 변동) | ⬜ |
| M3 | REQ-015 | AC-004 | 문장 파서 재목적 — 발화 명시 값을 이번 요청의 인자로(저장 아님) | ⬜ |
| M5 | REQ-030~031 | AC-006 | `SPEC-ONTIME-001` 개정 — REQ-061·REQ-063 + acceptance.md AC-007 + plan.md M5 서술 + HISTORY bump. **본문 수정은 manager-spec 소관 — 오케스트레이터 재위임 필요** | ⬜ |
| M6 | — | AC-007 | 품질 게이트 — iOS·macOS 무경고 빌드, `cd proxy && npm test`, GuardDriver 전체 초록 | ⬜ |

**D-1 해소됨(2026-09-15, 사용자): 선택지 C — 한 장의 묶음 카드 + 확인 버튼, 확인 시 툴 1회 호출.** 근거 2건(중단 비용 1회 / 세션 메모리 기각)과 기각된 대안은 spec.md §4에 기록돼 있고, 카드·무기억 형태는 REQ-011~014·REQ-040~041로 반영됐다. 해소 대기 마커는 제거했다.

## 2. 알려진 이슈 / 리스크

- **GuardDriver의 검증 경계**: 드라이버 컴파일 대상은 `Shared/`의 로직 파일들이지 SwiftUI 뷰가 아니다 — 카드 "렌더링" 자체는 가드 밖(빌드 + 실기기 AC-008). 가드가 검증하는 것은 보류 상태의 결정적 부분(카드 요청의 인자 목록·확인 시 1회 호출·파싱 결과)이다.
- **0분 칩과 생성 경로 0 가드**: 카드의 진짜 `0분` 칩(REQ-014)은 생성 경로의 "이번 한 건짜리 0" 처리(`Shared/AIAssistant.swift:1332` 부근)와 의도가 일치하는지 M2에서 확인한다 — 발화로는 전달되지 않던 0(`:1336-1341`의 `v > 0` 필터)이 새로 도달하는 경로다.
- **동시 진행 클램프 통일과의 접점**: 음수 `buffer_minutes` 클램프가 `Store.clampBuffer`/`Store.clampNotifyLead` 뒤로 통일되는 작업이 병행 중이다 — M1(생성 도구 인자 제거)·M2(카드)와 같은 경로를 건드리므로 착수 시점 트리에서 재확인하고, 충돌이 보이면 blocker로 상신한다.
- **M1과 REQ-062의 접점**: 갱신 도구(`update_recurring_schedule`)의 0 되묻기·`confirm_zero` 흐름은 "모델이 0을 전달"을 전제로 짜여 있다. 생성 도구로 제거를 한정하면 무충돌이지만, 갱신 쪽까지 확장하면 그 흐름이 칩으로 대체되며 `SPEC-ONTIME-001` 개정 범위가 REQ-062로 넓어진다 — 자동 확장 금지, blocker로 상신해서 정한다.
- **재호출과 툴 루프 상한**: 칩 재호출은 앱이 국소적으로 수행하므로 모델 턴을 소모하지 않아야 한다(설계 의도). 구현 중 달라지면 루프 상한 소진 위험이 있으므로 즉시 plan.md와 루트 plan.md를 갱신한다.
- **하네스 배정(CLAUDE.md "작업을 시작할 때" 매번 적용)**: `AIAssistant` 툴·가드 변경 → `ai-tooling` 관점, `AIChatView` 칩 렌더링·보류 상태 UX → `ui-design` 관점, 구현 후·실기기 전 → `code-safety` + `ux-check`.
- **`xcodegen generate` 금지(조건부)**: 칩은 기존 파일 안에 구현한다(새 소스 파일·Info.plist 키 없음). `xcodegen generate`는 서명 계정을 리셋하므로 새 파일이 생기는 경우에만 돌리고, 돌렸다면 besir-iOS·besirShare 두 타깃의 Team 재선택을 사용자에게 요청한다.

## 3. 사전 확인 — 기준선 (HEAD `707b9af`에서 오케스트레이터가 관측; 본 SPEC 작성 시 재실행하지 않음)

- 게이트 이름으로 기준선을 남긴다: **GuardDriver 전체 초록**, proxy `npm test` **7/7**, iOS·macOS **BUILD SUCCEEDED, Swift 소스 경고 0건**(HEAD `707b9af` 당시 오케스트레이터 관측). **드라이버 총 단언 수는 인용하지 않는다** — 본 SPEC 작성 이후 두 생성 경로의 음수 `buffer_minutes` 미클램프가 발견돼 클램프가 `Store.clampBuffer`/`Store.clampNotifyLead`로 통일되는 중이고 드라이버 단언이 추가되고 있으므로, 총수의 SSOT는 run-phase의 실측이다.
- 실기기 빌드는 "All interface orientations must be supported" 경고가 추가로 나오나 본 SPEC과 무관한 기존 경고다.
- 구현 착수 시 이 기준선을 다시 확보한 뒤 시작하고, 이후 실패는 "신규 결함"과 "기존 기준선 회귀"를 구분해 보고한다. 작업 시작 당시 트리에는 동시 진행 작업이 있을 수 있으므로 착수 전 상태를 재확인한다.

## 4. PRESERVE 목록

- `proxy/` 전체 — 와이어 포맷·모델 상수 불변(SPEC-ONTIME-001 REQ-060; 칩은 앱 안의 변경이다).
- 갱신 경로 방어 — `zeroUpdateIssue`·`confirm_zero`·`series_number`·`on_conflict`·`confirm_many`(SPEC-ONTIME-001 REQ-062). 본 SPEC은 생성 경로만 고친다.
- `Store` 단일 허브(CLAUDE.md 계약 3 — 칩 상태도 `AIAssistant`의 대화 상태 안에 둔다), 색 토큰(계약 6 — 칩 색은 `Theme` 토큰만), `isSamePlace` 50m 가드, `list_schedules` 자기교정.
- 다른 SPEC 디렉터리(SPEC-FULL-001 등)와 각 plan-phase 산출물, `.moai/state/`·`.moai/harness/` 런타임 관리 파일.
- `Tools/MakeAppIcon.swift`·`BesirMark` 기하 상수 — 무관하며 양쪽 동시 수정 규칙도 무관.

## 5. Self-Verification (run-phase 보고 형식)

- AC 이원 PASS/FAIL 매트릭스 — 각 항목에 대응 GuardDriver 단언 라벨과 그 출력(✓/✗ 라인)을 그대로 인용.
- 빌드: iOS·macOS 무경고(툴체인 경고 필터는 `hns-besir-app-verify` 기준). `cd proxy && npm test`.
- 문서: `SPEC-ONTIME-001` 개정 diff(REQ-061·REQ-063 + AC-007 + plan.md M5 + HISTORY bump) 확인. 루트 `plan.md` § Phase 1.5 항목의 완료 표시 갱신.
- 검증은 실행 시점 트리에서 새로 관측한 값을 보고한다 — 위 §3의 수치는 기준선 인용이지 예측이 아니다.
