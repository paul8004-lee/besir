# t36 — 토큰 표시 위생 묶음 (C26)

t16 sync 5차 판정문 §R5.6의 N4·N5·N6. 워크트리 `.claude/worktrees/t36`, branch
`WT-token-display`, base `f90a1f0`(= origin/master). 구현은 ai-tooling 전문가,
판정은 code-safety 전문가, 게이트·인용 수리는 판정 레인(리드 세션) 직접.

## 델타 (2 파일, +28/−6)

- **N4** `searchBoundPlace`(AIAssistant.swift) 첫 조항 `!isInternalPlaceToken(q)` —
  토큰이 두 장소 줄에 공존할 때 `sameNamePlaceNote`가 raw 삽입하던 잠복 경로 폐쇄.
- **N5** `tokenChip(_:)` 신설(displayText 단일 출처), 하드코딩 칩 라벨 5곳 교체.
  칩 문구는 바이트 동일 — 문구 변경이 아닌 단일화.
- **N6** GuardDriver AE-C-1 블록에 `drvLastCallArgs` 기반 아웃바운드 히스토리 에코
  감시 단언 1건 — 최종 확인 시 고른 토큰이 모델 턴 인자에 실리는 설계 속성 감시.

## 게이트 (전부 판정 레인 직접 실행, 로그 `.moai/state/verify/t36-r1/`)

| 게이트 | 관측 |
|---|---|
| 가드 드라이버 | COMPILE=0 · RUN=0 · **357/357 통과**(356→357, N6 단언 +1) · 실제 데이터 대조 통과 · 샌드박스 잔여 0 |
| iOS (iPhone 17 Pro, 신선 dd) | EXIT=0 · BUILD SUCCEEDED · **.swift 경고 0** |
| macOS (신선 dd) | EXIT=0 · BUILD SUCCEEDED · **.swift 경고 0** |
| 프록시 npm test | EXIT=0 · **7/7 통과** |

code-safety 판정: **PASS — 차단 0·비차단 0.** N4 도달 가능 동작 변화 없음을
전수 추적으로 확인(토큰을 담을 수 있는 키는 origin/travel_from뿐, peer 비교는
같은 호출 안 — 두 줄 공존 불가). N5 바이트 동일. N6 공허 통과 불가([:] → 거짓).

## 인용 재맞춤 (CHECKLIST.md 11행, plan.md 변경 없음)

삽입이 두 곳(searchBoundPlace +4, tokenChip +6)이라 **이동량이 구간별로 다르다**:
base 760~3004 좌표는 +4, base ~3005부터는 +10. 지문 대조로 라이브 좌표만 이동:

- +4: 1722-1730·1775-1777·1726-1728·1735·1014-1031·1697·2454·1167·1244-1246·
  3030의 동료들(1761·1924·1945·2167·2243·2758·2696·2806·2805·2924-2934)·
  1861-1865·1850·2052-2054·2283-2285·1090·1147-1150·1056-1060·1076·1097-1118
- +10: 3030→3040(genericPlaceWords)·3078→3088(creation 게이트)·
  3028-3029→3038-3039(스냅숏 한계 주석)·3067→3077(adoptPlace)

양성 대조 16/16 — 새 좌표의 본문이 기존 좌표 본문과 일치(sed 직접 덤프).
**낡은 좌표(베이스에서 이미 어긋남)는 손대지 않았다**: t9 감사 서술 블록
(135·141·146-148 — 프롬프트 블록 실제로는 choose 함수), 283 notify_enabled,
653 블록(searchPlaces :799-820, 실제 :1097), 658 reminders 주석(소실),
plan.md 565·566(create_schedule 전용 주석 소실·resolvePendingAsk 실제 :1200).
이들은 t36 이전 드리프트로 t29(C20 cite_check 개선) 영역이다.

## 갭 · 잔여 위험

- 모델 실동작 e2e·실기기 관찰은 범위 밖(드라이버 단언이 설계 속성 감시 목적).
- 시뮬레이터 AC-014·015는 여전히 운영자 몫(UI통일 Day 닫기 이월).
