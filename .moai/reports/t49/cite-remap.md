# t49 마감 라운드 — 문서 인용 재사상 증거

디스패치 2026-10-08(리드): "문서 인용 재사상만(코드 무변경) — 운영자 결정 't49 안에서 마감 수리'".
코드는 한 글자도 안 고쳤다(97f1662·5932328 유지). 로그·스크립트: `.moai/state/verify/t49-run2/`
(ledger.py·ledger-before.txt·remap.py·ledger-diff.py·docs-diff.txt·docs-diff-control.txt·check-after.txt).

## 1. 원칙 — 오프셋 일괄 가정 금지

hunk 경계를 `git diff -U0 97f1662^ 97f1662 -- Shared/Store.swift`로 직접 읽었다:

```
@@ -334,0 +335,5 @@   ← modifyActivity 안 짝 포획 5줄이 334줄 뒤에 삽입
@@ -344 +349 @@       ← realign 호출부 1:1 교체(순수 0)
@@ -351,5 +356,7 @@   ← realignReturnLeg 머리말·서명 재작성(+2)
```

지역별 오프셋: **~334 → 0** · **335~350 → +5** · **351~355 → 재작성(지문 대조 불가)** ·
**356~ → +7**. 초판 progress §5의 "349줄 이후 균일 +7"은 이 지도의 오기였다(sync N-3 지적,
§5 정정 완료). 335~350 영역을 가리키는 인용은 세 문서 전수에서 **0건**(원장 실측).

## 2. 원장(전수) — 87건

`.moai/state/verify/t49-run2/ledger-before.txt`: CHECKLIST.md 58 · plan.md 4 ·
SPEC-UIKIT-012 spec.md 25(명시 12 + 맨몸 13). CHECKLIST 2026-10-06 판은 인용이 전부
`파일.swift:줄` 명시 꼴이라 맨몸 스윕 대상이 없었고(헤머리 선언), 맨몸은 SPEC에만 있었다.
각 인용마다 옛 줄 원문(97f1662^)·새 줄 원문(현재)을 나란히 찍어 **지문 같음 84건**을 기계 확인했다.

맨몸 귀속은 창 휴리스틱만 믿지 않고 심볼로 확정했다(t16 교훈). 그 결과 3갈래:

- **재사상 84건(+7)** — 명시 73 인스턴스(고유 토큰 67개: CHECKLIST 58·plan 4·SPEC 11) +
  맨몸 8(SPEC 94행 `:1404`→`:1411`·`:1406`→`:1413`, 101행 `:1439-1447`→`:1446-1454`,
  103행 `:1427-1434`→`:1434-1441`·`:1414-1422`→`:1421-1441`, 107행 `:955`→`:962`,
  153행 `:1538`→`:1545`, 182행 `:1519-1543`→`:1526-1550` — 전부 같은 줄/같은 절의
  `Store.swift:NNN` 명시를 따르는 귀속).
- **고정 3건(afd36c3 기준)** — SPEC 111행 `realignReturnLeg`(`:352-359`·`:353`)과 224행
  `Store.swift:352-359`. 이 문장들은 t49 **이전** 동작("명시 연결만 보아")을 서술한다 —
  새 좌표(:360-367)를 주면 좌표는 맞는데 문장이 거짓이 된다. 저장소 관례(그날의 기록은
  트리 고정 — plan.md t7 항 전례)대로 `(afd36c3 `…`)` 표기로 고정했다.
  대조: `git show afd36c3:Shared/Store.swift` :352-359 = 수리 전 realignReturnLeg 전문,
  :353 = `events.first(where: linkedActivityId…)` 행 — 인용 문구와 정확히 일치.
- **제외 3건(변경 없음)** — SPEC 93행 `:494`·`:408`·`:854-863`은
  `.scrollDisabled(activeDrag…)`·`SwipePager isLocked`·`ScrollTouchFixView` 심볼 = **ContentView**
  귀속(ContentView.swift:998 실측). 97f1662는 ContentView를 건드리지 않았으므로 이동 0.

## 3. 실행 — 원자적 교체

`remap.py`: 행 단위 원자적 교체(토큰별 등장 횟수 1회 단언), 편집은 단일 패스 사상이라
옛/새 번호 충돌(예: 옛 :1607→1614와 옛 :1614→1621)이 연쇄로 꼬일 수 없다. 계획 밖 인용
발견 시 즉시 중단(안전 실패) — 발동 없음. 출력:

```
CHECKLIST 58건·plan 4건·SPEC 명시 11건 + 맨몸 8건 재사상, 고정 3건, 제외 3건 확인
```

## 4. 검증 — 세 가지 독립 대조

**① check.py(t43 sync 도구) — 새 좌표가 실제 줄을 가리키는지 원문 대조.**
`git diff -U0`의 추가 줄에서 인용 80건(중복 제거 74)을 읽어 현재 원문을 찍었다
(check-after.txt). 심볼 눈검증: `legAnchor` :385·`owningActivity` :436·`moveActivity` :1394·
`effectiveDragMinutes` :1530·`shiftEvent` :1643·`adjustBuffer` :1655 등 전부 산문 심볼과
일치. 유일한 현재-원문 불일치는 고정 3건 — 설계상(afd36c3 참조)이며 §2에서 옛 트리로 대조 완료.

**② 양성 대조 — 도구가 진짜 줄을 읽는지.** diff 입력에 가짜 좌표를 끼워 넣어 재실행:

```
!! Store.swift:99999-99999 파일 길이 2044 초과
Store.swift:1 | import Foundation
--- 양성 대조(틀린 좌표를 일부러 읽는다) ---
ContentView.swift:1 | import SwiftUI
```

**③ 원장 전·후 문자열 대조(다중집합).** `ledger-diff.py`는 재사상 전 원장에 편집과 같은
단일 패스 사상을 적용해 기대 원장을 만들고 실제와 통째로 비교한다(개별 토큰 역추적은
번호 충돌에서 오탐을 내므로 폐기 — 그 오탐판 2판은 t16 '인용 재사상은 원자적 토큰 교체로'
교훈의 재현이었다). 출력:

```
재사상 67건·고정 1건·영향권 밖 불변 13건 — 기대 원장과 실제 원장 대조
문제 0건
```

(67 고유 토큰 = 73 인스턴스의 중복 제거. 맨몸 8건은 ①의 줄 원문과 remap.py의 원자성
단언으로 별도 검증 — check.py는 파일 접두 없는 맨몸 인용을 읽지 못한다.)

## 5. 잔여 발견 — 이번 이동분이 아니라 옛 어긋남(후속 원장 카드 몫)

SPEC 설계절 맨몸 4건(`:1411`·`:1413`(94행)·`:1446-1454`(101행)·`:1434-1441`(103행))은
97f1662 **이전부터** 산문과 좌표가 어긋나 있었다 — 산문은 `shiftEvent`·`estimatedLegs`를
말하지만 afd36c3의 그 좌표는 adjustTravelLeg의 wholeSeries 필터·호출 갈래다
(`estimatedLegs` 함수는 옛 :1613 = 현 :1620에 있다). 이번 +7은 같은 대상을 충실히
보존한 것이라 새 결함이 아니며, 산문-좌표 정합은 t44 계열 전체 원장 카드가 잡는다.
CHECKLIST의 옛 어긋남(예: realignLegs :581 인용)도 같은 부류 — progress §5에 기록.

## 6. 변경 파일·커밋

- CHECKLIST.md(58)·plan.md(4)·.moai/specs/SPEC-UIKIT-012/spec.md(19 교체+3 고정 표기)
- .moai/reports/t49/progress.md §5 정정(sync N-3 반영)
- 본 파일. 코드(Shared/·Tools/)·build-ios.log(미추적) 무변경. 병합·push 없음.

완료 신호: 브랜치 `WT-edit-return-leg` · 커밋 "(card t49)" · 본 파일 경로.
