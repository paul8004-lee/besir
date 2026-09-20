# SPEC-UIKIT-004 — spec-compact.md

run 단계가 싣는 요약 판(전문은 spec.md·plan.md·acceptance.md). 기술 식별자·코드·파일 경로는
그대로, 서술만 줄였다.

## 요구사항 (14건 — `grep -c '^- \*\*REQ-' spec.md` = 14)

**§2.1 시각 포매터 단일화**
- **REQ-001**: `fullFmt`·`timeFmt`를 `BesirTime`의 `static let` 멤버 `full`·`clock`로 이사, 패턴
  불변. 신호: `grep -c "DateFormatter()" Shared/EventDetailView.swift` = 1, `…EditCard.swift` = 5.
- **REQ-002**: `shortTimeFmt`("a h:mm")는 **흡수 금지** — EventDetailView 로컬 유지.
- **REQ-003**: 분 0패딩 현행 유지 — full/compact/clock=mm, when=m, shortTimeFmt=mm. 상호 흡수 금지.

**§2.2 기준 매핑 단일화 (N2)**
- **REQ-010**: `BesirTime.anchor(ofPrefix:) -> ScheduleAnchor?` + `prefix(for:) -> String` 신설
  (`ScheduleAnchor` = `Models.swift:204`, 드라이버 집합 안).
- **REQ-011**: 순수 매핑 8곳 제자리 치환 — `AddEventView:325·335·476·531·554`,
  `EditCardView:168`, `AIAssistant:826·885`. 유지 2곳: `EditCard:139`(라벨), `AIAssistant:893`(인자 키).
  신호: `grep -rn 'prefix == "arr:"\|prefix == "dep:"\|hasPrefix("arr:")' Shared/*.swift` = 2,
  `grep -rn '? "arr:" : "dep:"' Shared/*.swift` = 0.
- **REQ-012**: 폼·AI 카드 관측 동작 무변경 — 드라이버 단언 추가 없음, 기존 P 계열 초록.

**§2.3 크롬 통일**
- **REQ-020**: 카드 컨테이너 3곳(출발 `:213-214`·여정 `:249-250` 교체, 상세행 `:302-348` 신규
  감싸기) → `Theme.raised` + `Theme.radius` + `Theme.line` 스트로크. 신호: `grep -c 'thinMaterial'` = 0.
- **REQ-021**: `.secondary` 9→`Theme.muted`, `.tertiary` 1→`Theme.faint`, `.quaternary` 1→
  `Theme.line`, `:203` `isPast ? Theme.nowLine : Theme.travel`, `:116` `.green`→`Theme.travel`.
  예외: `.white` 글리프·`Color(hex:)` 노선색·`Theme.bg`. 신호: `grep -c '\.secondary\|\.tertiary\|\.quaternary\|\.red\|\.green'` = 0.
- **REQ-022**: 캘린더 네 갈래(`:115-144`) 분기·문구·재시도 무변경 — 크롬만.
- **REQ-023**: 접근성 순증(현재 0건) — 출발 카드 결합 낭독·stepRow 결합 낭독·지도 라벨·
  38pt `@ScaledMetric` 상대화.

**§2.4 보존**
- **REQ-030**: 어포던스 절별 대조(AC-006 11절 표, 일괄 통과 금지).
- **REQ-031**: 편집 표면 0개 유지 — 시트 위임 그대로, 읽기 전용 렌더 모드 금지(D-1 승계).

**§2.5 검증·범위**
- **REQ-040**: 게이트 4종 — 드라이버(단언 추가 없음)·iOS/macOS 무경고·프록시·새 소스 파일 0
  (xcodegen·Team 재선택 없음).
- **REQ-041**: 소스는 본체 2(`EventDetailView`·`EditCard`) + 치환 3(`AddEventView` 5줄·
  `EditCardView` 1줄·`AIAssistant` 2줄)만. 문서 예외: 루트 `plan.md`·본 SPEC 4종·`progress.md`·
  `CHECKLIST.md`(sync).

## 인수 기준 (9건 — `grep -c '^## AC-' acceptance.md` = 9)

- **AC-001** 포매터 소유권 — grep 3종(화면 1·BesirTime 5·패턴 대조)
- **AC-002** 패딩 실측 — swift로 5종 찍어 표와 대조(05분/5분/3:05) — **t2a AC-009 S8 승계 종결**
- **AC-003** 매핑 단일화 — grep 신호 2건+0건, diff 7줄 한정
- **AC-004** 관측 무변경 — 드라이버 초록·단언 추가 0
- **AC-005** 크롬 — grep 0건 3종·컨테이너 3곳·클립 12 유지·@ScaledMetric
- **AC-006** 어포던스 **11절 개별 대조**(일괄 통과 금지)
- **AC-007** 편집 표면 0 — 입력 컨트롤 0건·readOnly 0건·시트 그대로
- **AC-008** 범위·게이트 — 새 파일 0·소스 5종·무경고 빌드·프록시
- **AC-009** 시뮬레이터 10항목(스크립트 방식) + 실기기 목록(Day 닫기 이월)

## 파일

- `Shared/EventDetailView.swift` — 본체(크롬·포매터 호출부·접근성)
- `Shared/EditCard.swift` — 본체(BesirTime 멤버 2·접근자 2)
- `Shared/AddEventView.swift` — 치환 5줄(N2)
- `Shared/EditCardView.swift` — 치환 1줄(N2)
- `Shared/AIAssistant.swift` — 치환 2줄(N2)

## 제외 (What NOT to Build)

- `shortTimeFmt`의 BesirTime 흡수 — 금지(REQ-002)
- `EditCardView` 읽기 전용 렌더 모드 — 금지(D-1)
- CB(ConflictBanner 계약 6 우회 3건)·B7·S-lens4 — 본 카드 밖
- 활동 화면 둘 — 카드 t3(`SPEC-UIKIT-003`)
- 지도 클립 반경 토큰화 — 유지 판정(D-4)

🗿 MoAI
