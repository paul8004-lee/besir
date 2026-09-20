## Task Decomposition
SPEC: SPEC-UIKIT-004

| Task ID | Description | Requirement | Dependencies | Planned Files | Status |
|---------|-------------|-------------|--------------|---------------|--------|
| T-001 | BesirTime에 `full`·`clock` 포매터 이사(패턴 불변) + `anchor(ofPrefix:)`·`prefix(for:)` 신설(switch 몸통 — 세는 신호 보존) | REQ-001, REQ-002, REQ-003, REQ-010 | - | Shared/EditCard.swift | done |
| T-002 | N2 매핑 8곳 제자리 치환(AddEventView 5·EditCardView 1·AIAssistant 2) + 유지 2곳 무변경 확인 | REQ-011, REQ-012 | T-001 | Shared/AddEventView.swift, Shared/EditCardView.swift, Shared/AIAssistant.swift | done |
| T-003 | EventDetailView 크롬 패스 — 컨테이너 3곳(2 교체+1 신규)·색 토큰화(secondary 9·tertiary 1·quaternary 1·red/green 2)·접근성 순증·38pt @ScaledMetric | REQ-020~023 | - | Shared/EventDetailView.swift | pending |
| T-004 | 어포던스 11절 대조·범위 diff 검사·양쪽 무경고 빌드·드라이버(단언 추가 금지)·프록시·검토 2인(ui-design·code-safety) | REQ-030, REQ-031, REQ-040, REQ-041 | T-001, T-002, T-003 | (문서) .moai/specs/SPEC-UIKIT-004/* | pending |

비고: 패딩 실측(AC-002)은 T-001 직후 swift 한 줄로 측정해 progress에 명령·출력 그대로 붙인다.
신규 소스 파일 0건(REQ-040(d)) — xcodegen 불필요. 시뮬레이터 AC-009는 리드 소관(standing 정책).
