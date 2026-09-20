# SPEC-UIKIT-004 — plan-audit review-1

**⚠️ SELF-AUDIT(대체) — 독립 plan-auditor 판정이 아니다.** 본 plan 세션에서 독립 감사
채널 3종(서브에이전트·codex·GLM)이 전부 불능이었다(progress.md §F.1 감사 표). 아래는 작성자
본인의 기계적 검증 기록이며, `/moai run` Phase 1의 Plan Audit Gate가 이 자리에서 독립 감사를
다시 해야 한다.

- 대상: `.moai/specs/SPEC-UIKIT-004/`(spec.md 0.1.0 · plan.md · acceptance.md · spec-compact.md)
- 검증일: 2026-09-20, base `9e4a374`
- verdict: PASS(자체 기계 검증 한정 — 독립성 없음)
- score: 산출 불가(독립 채널 부재 — Tier M 0.80 판정은 run Phase 1로 이월)

## 검증한 것 (전부 명령으로 재현 가능)

| 검증 | 명령/방법 | 결과 |
|---|---|---|
| frontmatter 12 필드 | `sed -n '1,20p' spec.md \| grep -c '^id:\|…'` | **12/12** |
| 거부 별칭 | `grep -c 'created_at\|updated_at\|labels:\|spec_id:'` | **0** |
| REQ 수 = GEARS 라벨 수 | `grep -c '^- \*\*REQ-'` vs 라벨 grep 합 | **14 = 14**(Ubiquitous 10·Unwanted 4) |
| AC 수 | `grep -c '^## AC-' acceptance.md` | **9** |
| REQ↔AC 커버 | 매트릭스 표 대조 | 14 REQ 전부 ≥1 AC에 매핑 |
| 매핑 실측 일관성 | `grep -rn 'prefix == …'` 7건 + 삼항 3건 | §1.3의 10곳(전환 8·유지 2)과 정합, 사후 신호 2+0 산술 성립 |
| 포매터 실측 일관성 | `grep -c "DateFormatter()"` 화면 3·EditCard 3 | §1.2의 5종+iso와 정합, 이사 뒤 1+5 산술 성립 |
| 색 신호 실측 | `.secondary\|.tertiary` 10건, `.red\|.green` 실사용 2건(:116·:203) | §1.1·REQ-021 열거와 정합(참고: `.reduce`가 `\.red`에 오탐 — 신호 grep은 REQ-021의 패턴을 그대로 씀) |
| 인용 스팟체크 | `EditCardView:63-64`·`ContentView:449`·`Theme.swift:55`·`EventDetailView:203`·`AddEventView:325-335` | 5/5 일치 |
| 제외 절 ≥1 | spec.md §3 | 5건 |
| 파일 목록 정합 | spec §2.5 · compact Files · plan §0 · AC-008 | 소스 5종(본체 2+치환 3)로 통일 |

## 독립 감사가 다봐야 할 것 (run Phase 1 넘김)

- D-4 크롬 매핑의 디자인 판단(표 9줄) — 협의 채널 부재로 본 세션 실측 근거만으로 확정됨.
  run M3의 `ui-design` 협의가 승인 절차를 이어받는다.
- "4벌" 해석(when·compact·fullFmt·timeFmt = 흡수 금지 shortTimeFmt 제외 4종)이 리드
  디스패치의 의도와 일치하는지 — 본 세션의 문서화된 해석(spec.md §1.2·D-2)에 대한 리드 확인.
- 매핑 "5곳"(t2a §E.3)→"10곳"(현 트리 전수) 확장이 디스패치 범위 내인지 — HISTORY 0.1.0에
  차이를 명시해 뒀다.

🗿 MoAI
