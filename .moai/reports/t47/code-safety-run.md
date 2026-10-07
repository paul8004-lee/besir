# t47 run 단계 code-safety 심사 기록 (2026-10-06)

심사 주체: hns-besir-app-code-safety-specialist(읽기 전용 임무). 대상: `git diff 4987e2d..HEAD`
HEAD `61458e1` — 커밋 1fb19e3(RED)·4d48736(GREEN M2~M5)·61458e1(M6·M7). 아래는 심사 보고의 요지이고
원문은 run 레인 대화 기록에 있다.

## 판정 — 결함 0건

- H1 await 전후 인덱스/상태 무효화: 이상 없음 — 점심 해석(:2270~2282)이 첫 `store.addRecurringEvents(`(:2285) 앞,
  unclear면 저장 없이 return(:2279). 출발지·목적지 unclear 갈래(:2218~2238)도 저장 전. 확인 재실행은
  `resolvePendingAsk`가 `runToolCalls`로 정확 1회(:1376) + `confirmAsk` 카드-뒤 가드(:1248)가 중첩 카드를 끊는다 —
  이중 생성 경로 없음.
- H2 조용히 묻히는 실패: 이상 없음 — diff에 새 `try?`/`Task {}` 0건, notFound 문구 보존.
- H3 외부 한도: 이상 없음 — `adoptPlace` 검색 단 1회(재시도·병합 삭제 확인). 확인 재실행은 확정 사전
  (`locallyResolvedPlace` :1415 — 즐겨찾기→사전)으로 풀려 재검색 없음.
- H4 복제 계산·죽은 코드·강제 언래핑·루프 내 저장: 이상 없음 — `pendingActionVerb`·`placeRow(key:tool:)` 단일 출처,
  삭제 심벌 grep 0건, 호출처(:517·:578)도 tool 인자 전달로 정합.
- SPEC 불변식: 카드 1장 원칙·세대 가드·`@MX:WARN` 1줄(:2268 < :2285)·REQ-008 점심 자리 — 이상 없음.

## Gaps(심사가 못 잰 것)

드라이버 실행·iOS 빌드(오케스트레이터 몫 — §E.2에 관측 기록) · EditCard.swift UI(diff 밖) · H8 형태 실측.

## 잔여 위험

직접입력 새 질의 → 확인 재실행 검색 1회 → 다시 unclear → 두 번째 카드(설계상 정상) · 카카오 0건과 오프라인
구분 불가(기존 제약) · 확인 뒤 모델 발화는 시뮬레이터 S-11·S-12가 첫 관측.

## 사소 관찰(결함 아님)

`resolveOriginAdoption`의 `orDefault` 기본값 false 잔여 — true 호출처는 check_travel_time(:2855) 하나로 주석이
설명하는 방어적 잔여.

🗿 MoAI
