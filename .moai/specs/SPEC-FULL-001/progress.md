# SPEC-FULL-001 — progress.md

## §E.1 Plan-phase Audit-Ready Signal

```yaml
plan_status: audit-ready
plan_complete_at: "2026-09-12"
```

plan-auditor 3회 반복 이력(Retry Loop Contract 최대 3회 한도 소진):

| Iteration | Verdict | Overall Score | 리포트 |
|---|---|---|---|
| 1/3 | FAIL | 0.62 | `.moai/reports/plan-audit/SPEC-FULL-001-review-1.md` |
| 2/3 | FAIL | 0.75 | `.moai/reports/plan-audit/SPEC-FULL-001-review-2.md` |
| 3/3 (FINAL) | **PASS** | **0.875** | `.moai/reports/plan-audit/SPEC-FULL-001-review-3.md` |

Tier L PASS 임계값(0.85)을 iteration 3에서 충족(Traceability 0.50→1.0 개선이 결정적 — REQ-003/009/011/018의 미커버 AC 공백을 AC-113~116 신규 추가로 해소). 7개 must-pass 기준(MP-1~7)은 iteration 2에서 이미 전부 PASS였고, iteration 3의 FAIL→PASS 전환은 순수하게 집계 점수(카테고리 평균)가 임계값을 넘은 것이지 must-pass 기준 변화가 아니다. 사용자가 Implementation Kickoff Approval을 승인함(이 세션에서 확인됨).

## §E.2 Run-phase Evidence

**Baseline attribution**: 이 커밋을 기준으로 관측(HEAD `c6f851e`, branch `master` 대응 — 단 이 진행 기록 자체는 격리된 worktree 세션(`worktree-agent-a0fc384c4bb43e8e5`, 동일 HEAD `c6f851e`에서 분기)에서 작성됨. 아래 §Run-phase 실행 환경 제약 참고).

### M1 (Day 8, 배달/요리 카테고리 조사) — 이미 해소됨

**Status**: ✅ 완료(plan-phase 이전에 이미 결론 남).

plan.md M1 + research.md에 조사 결론이 기록돼 있다: 배달의민족·요기요 둘 다 개인 개발자 대상 공식 오픈 API를 확인하지 못했고, URL scheme 딥링크도 경로·파라미터 규격을 공식 문서로 확인할 수 없었다. 결정: `MealCategory.delivery`/`.cooking`은 열거형 케이스로만 남기고(의도적으로 보류된 예약 케이스, 죽은 코드 아님), 생성 UI·AI 경로는 추가하지 않는다(REQ-017/018).

### M2 (Day 6, 데이터 모델) / M3 (Day 7, 목적지 주변 검색) / M4a (Day 9, recommend_meal 툴) / M4b (Day 10, 전용 화면+활동 등록) — 모두 as-built, 이 SPEC 이전에 이미 구현·커밋 완료

**Status**: ✅ 완료(코드는 커밋 `d3c9327`·`c6f851e`에 이미 반영돼 있음 — 이 SPEC은 사후(as-built) 기준선 문서이며, 이번 run-phase 킥오프에서 신규 코드를 작성하지 않았다).

### M5 (Day 11, 코드 검사) — 완료. 이번 세션에서 독립 재확인한 빌드·기기 검증 증거

**Claim**: iOS 시뮬레이터·macOS 양쪽 빌드가 경고 없이 성공하고, 실기기(연결된 iPhone)에 설치·실행됨을 확인했다.

**Evidence (verbatim command + observed output)**:

```
$ xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17' -derivedDataPath build build
→ BUILD SUCCEEDED (Swift 컴파일러 경고 0건)

$ xcodebuild -scheme besir-macOS -derivedDataPath build build
→ BUILD SUCCEEDED (Swift 컴파일러 경고 0건; "WARNING: Using the first of multiple
   matching destinations"는 xcodebuild 툴 자체의 대상-선택 안내 메시지이며 코드 경고
   아님)

$ xcodebuild -allowProvisioningUpdates ... (실기기 UDID 8D9B807B-F874-5AD8-A62C-BC1731A31A1F)
→ BUILD SUCCEEDED
$ xcrun devicectl device install app ...
→ 설치 성공
$ xcrun devicectl device process launch ...
→ 실행 성공 (앱이 사용자 iPhone에서 현재 구동 중)
```

**관측된 out-of-scope 경고 1건**: 실기기 빌드에서만 "All interface orientations must be
supported unless the app requires full screen" 메시지가 나타났다 — 이는 Info.plist의
화면 방향(orientation) 설정 문제이며 be full sir(식사 추천) 스코프와 무관하다. 이 SPEC
범위에서 수정하지 않는다(기록만 남김).

**Baseline-attribution**: 이번 run(worktree HEAD `c6f851e`, 동일 커밋을 primary checkout master도
가리킴)에서 관측. 커맨드는 이 세션 안에서 실제로 실행됐다(빌드 로그를 직접 확인).

acceptance.md의 Day 11(코드 검사) AC 매트릭스는 이미 16/17건 PASS + 1건(AC-105) 측정
불가 상태로 기록돼 있다 — 이번 세션에서 AC-100/101/104/106 4건을 코드와 직접 대조해
재확인(스팟체크)했고, 전부 acceptance.md의 기존 서술과 일치했다:

| AC | 재확인 결과 |
|---|---|
| AC-100 | `Store.swift`의 `loadMeals`가 `loadActivities`/`loadEvents`/`loadFavorites`와 동일한 "배열 전체 디코드-또는-포기" 패턴임을 코드로 재확인. spec.md REQ-002 서술과 일치. |
| AC-101 | `PlaceSearch.nearbyPlaces`가 `search()`와 동일한 `config.proxyRequest("/kakao/local/keyword", ...)` 관례를 따름을 재확인. |
| AC-104 | `FullSirView.swift`의 `save()`가 `addActivityWithTravel`의 반환값(`activityId`)을 직접 저장함을 재확인 — 재조회 방식이 아님(커밋 `c6f851e`). |
| AC-106 | `MealCategory.delivery`/`.cooking` 생성 경로가 UI·AI 어디에도 없음을 재확인. |

acceptance.md 전체 17개 Day-11 AC(AC-100~116) 자체의 상태는 acceptance.md가 SSOT이며
(16 PASS + AC-105 측정불가), 이 progress.md는 그중 4건만 이번 세션에서 직접 재검증한
결과를 기록한다 — 나머지 13건은 acceptance.md에 이미 기록된 코드 대조 결과를 그대로
신뢰한다(중복 재검증 생략).

### M6 (Day 12, 실기기 테스트) — 미실행, 사용자 액션 필요

**Status**: ⬜ 미실행. acceptance.md AC-201~207 전부 미실행.

이 마일스톤은 에이전트가 완료할 수 없다 — 실제 알림 수신 확인, 제스처 느낌, 위치 권한
거부 시 UI 등은 실기기에서 사용자가 직접 조작해야 관측 가능하다. 앱은 이미 실기기에
설치·실행돼 있으므로(위 §M5 증거 참고), 사용자가 이어서 AC-201~207을 직접 확인하면 된다.

### M7 (Day 13, 안정화) — 미실행, M6 결과에 의존

**Status**: ⬜ 미실행. M6에서 발견되는 문제를 수정하거나 "알려진 이슈"로 명시하는 마일스톤이라
M6 완료 전에는 시작할 수 없다.

## §E.3 Run-phase Audit-Ready Signal

```yaml
run_status: not-ready-to-close
```

M6(Day 12 실기기 테스트)·M7(Day 13 안정화)이 미실행 상태이므로 이 SPEC의 run-phase는
**아직 완료되지 않았다** — sync-phase(§E.4, manager-docs 소관)로 넘어갈 준비가 안 됐음을
명시적으로 기록한다. 이번 커밋은 M1(run-phase 첫 커밋, `draft → in-progress` 상태 전환)만
수행한다.

- `ac_pass_count`: 16 (Day 11, acceptance.md AC-100~116 중 AC-105 제외)
- `ac_fail_count`: 0
- `ac_pending_count`: 8 (AC-105 측정불가 1건 + Day 12 AC-201~207 7건 미실행)
- 다음 세션 필요 액션: 사용자가 실기기(이미 앱 설치·실행됨)에서 plan.md M6/M7 절차를 진행.

## §F Phase 4 Mode Selection

**입력 파라미터**: Tier L, scope 7개 파일(이미 구현 완료, 이번 세션은 신규 코드 작성 없음),
domain count 1(SPEC 문서화 + 빌드 검증), coding-heavy 아님(빌드/기기 검증 + 문서화 작업).

**모드 평가**:

| Mode | 선택 여부 | 근거 |
|---|---|---|
| `direct` | 미선택 | 단일 라인 수정이 아니라 SPEC 문서 두 개(frontmatter 전환 + progress.md 신규 작성)를 다루는 작업 |
| `serial` | **선택** | 이 킥오프 기록 작업은 문서화 + 검증-결과-기록의 단일 순차 태스크이며, 병렬 처리로 얻을 이득이 없다 |
| `fanout` | 미선택 | 다중 도메인 리서치가 아님 — 이미 오케스트레이터가 빌드/기기 검증을 완료한 상태를 문서화만 하면 됨 |
| `sweep` | 미선택 | 기계적 대량 변환이 아님(파일 2개) |

**Decision: serial** (오케스트레이터 직접 실행 + 단일 문서화 위임 — Agent() 재분기 없이 이 세션 자체가 M1 킥오프 기록을 완료)

**근거**: 이 작업은 신규 기능 구현이 아니라 이미 완료된 빌드/기기 검증 결과를 SPEC 아티팩트에
반영하는 순수 문서화 작업이다. Anthropic의 coding-task parallelism caveat과 무관하게, 병렬화로
얻을 이득이 없는 단일 순차 작업이므로 `serial`(이 경우 오케스트레이터가 직접 처리하는 단일
위임)이 명백히 적절하다.

## §Run-phase 실행 환경 제약 (기록용)

manager-develop 위임이 격리된 worktree(`worktree-agent-a0fc384c4bb43e8e5`)에서 실행돼 최초
커밋(`a2a42ac`)이 `master`가 아닌 그 worktree 브랜치에 생겼다 — 하네스가 격리된 에이전트의
git 명령을 primary checkout 대상으로 차단하기 때문. 오케스트레이터가 두 파일(`spec.md`,
`progress.md`)의 내용을 primary checkout으로 옮겨 `master`에 직접 커밋해 반영했다(아래 M1
커밋 SHA 참고).
