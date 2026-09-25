# t15 — C6 문구·주석 묶음 진행 기록 (WT-copy-wording)

카드: "C6 문구·주석 묶음 — 후속 18·19③·B5(이동 수단/이동수단 표기)·B7(계산 후 불가 수단 침묵)·
D-3 고지 문구(과거 일정 알림 안 걸림 화면 고지). 근거: day-close-20260924.md §7·이월 목록."
부류: Class B(SPEC 없음, plan 건너뜀). 베이스: origin/master `32df406`(t14 병합판).
원형 정의의 출처: t2 run 증거(13da206 — B5·B7·D-3(i) 이월 표)·t6 sync F4·F5(a32ad08 — 후속 18
①②)·t7 sync O3(83bf259 — 후속 19③)·day-close §6 #18·#25·#26 / §7 C6(841cf9a).

## §1 무엇을 고쳤나

| 항목 | 원형 근거 | 수리 | 좌표 |
|---|---|---|---|
| 후속 18① | t6 sync F4 — "유일한 보임새 변화" 주석이 채팅 요약 말풍선 표면을 빠뜨림 | 칩·확인 요약 말풍선 두 표면을 이름 붙이는 문장으로 교체(resolvePendingAsk의 chosenLabel 경로 명시) | AIAssistant.swift:759-761 |
| 후속 18② | t6 sync F5 — 사전 증가 차원이 "이름 수"→"지점 수"로 바뀐 데 천장 미기재 | "천장 = 이 대화에서 확정한 서로 다른 지점 수" 문단 추가 | AIAssistant.swift:772-773 |
| 후속 19③ | t7 sync O3 — nil 읽기 자리 나열("넷")이 전칭으로 읽히고 이미 낡음(현 5곳) | 자리 수 의존 제거, "신호로 읽는 곳은 prefillOrigin의 가드 하나뿐"으로 한정 | AddEventView.swift:660-664 |
| B5 | t2 ui-design 노트 — 표면 간 띄어쓰기 불일치 | "이동수단" 붙여쓰기 4곳 통일 | AddEventView.swift:245·EventDetailView.swift:340·Models.swift:4·:162 |
| B7 | t2 — 계산 후 불가 수단의 침묵(detail 접기의 승인 범위) | 모드 줄 노트가 "선택한 이동수단은 소요시간을 계산하지 못했어요. 저장할 때 다시 계산해요."를 말함. estimates가 빈 창(계산 전)에는 침묵 유지 — 계산 전과 계산 후 불가를 구분 | AddEventView.swift:573-580 |
| D-3 | t2 후속 표 — "과거 일정에는 알림이 안 걸린다"는 사실을 화면이 말하게 하기 | ① 폼 시각 줄 노트: 계산된 출발−리드 ≤ 지금이고 알림이 켜져 있으면 "알림 시각이 이미 지나 출발 알림이 예약되지 않아요."(리드 산식은 save()와 동일 우선순위) ② 상세 화면 캡션이 알림 상태를 사실대로: 꺼짐 / 예약됨 / 과거 거부 / 64건 창 밖 대기 | AddEventView.swift:600-619·EventDetailView.swift:230-233·:392-401 |

code-safety 발견 1 수기(FAIL→수리): 첫 판 삼항식이 `notificationId == nil`을 "알림 시각이 지나"로만
단정했으나, 64건 리스케줄러(`rescheduleNearestNotifications`, Store.swift:1216-1242 — 전체
notificationId nil화 후 가까운 60건만 리필해 디스크에 저장)가 만드는 창 밖 nil에서 거짓이 된다
(3주 뒤 일정에 "3주 남음 · 알림 시각이 지나"라는 자기모순). `alarmStatus` 헬퍼가 알림 시각
(출발−리드 ≤ 지금)으로 원인을 갈라 창 밖에는 "가까워지면 알림 예약돼요"를 내보내게 수정했다.
같은 판의 대입 전용 if/else는 ViewBuilder에서 해석되지 않아 빌드가 깨졌었음(삼항→헬퍼로 해소).

하네스: ui-design(뷰 3파일 편집) + code-safety(렌즈 7종 심사) + 레인 직접(AIAssistant 주석 2건,
code-safety 수리 적용, 게이트 4종).

## §2 증거 — 돌린 명령과 관측 (발견 1 수리 뒤 최종 트리 전수 재실측)

| 게이트 | 명령 | 관측 |
|---|---|---|
| iOS | `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build > build-ios.log 2>&1` | exit 0·`** BUILD SUCCEEDED **` 1회·Swift 경고 0(`grep "warning:" build-ios.log | grep -v appintentsmetadataprocessor | sort -u` 출력 0행) |
| macOS | `xcodebuild -scheme besir-macOS -derivedDataPath build build > build-mac.log 2>&1` | exit 0·`** BUILD SUCCEEDED **` 1회·같은 필터로 경고 0 |
| 프록시 | `cd proxy && npm test` | `7/7 통과`·exit 0 |
| 가드 드라이버 | `cat Shared/AIAssistant.swift Tools/GuardDriver.swift > /tmp/gd15.swift && swiftc -o /tmp/gd15 /tmp/gd15.swift Shared/EditCard.swift Shared/Store.swift Shared/Models.swift Shared/Config.swift Shared/PlaceSearch.swift Shared/DirectionsService.swift Shared/LocationManager.swift Shared/NotificationManager.swift Shared/GoogleCalendarService.swift Shared/SharedInbox.swift -parse-as-library && /tmp/gd15` | `217/217 통과`·exit 0·`[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다` |
| B5 잔여 | `grep -rn "이동 수단" Shared/ ShareExtension/` | 0건(exit 1) |
| code-safety 심사 | 미커밋 diff 전수(`git diff`) 렌즈 7종 | 발견 1(중간) — §1 수기로 수리. H1·H3·H5·간결성 0건, H2 판정 2건(D-3 침묵=보수적 설계·B7 "저장할 때 재계산" 전 경로 사실 — addEvent Store.swift:600-601·updateEvent :975-976 대조), H4 수용(아래 §5) |

빌드 로그 원본: 워크트리 루트 `build-ios.log`·`build-mac.log`(미커밋 — 각 끝 줄 `** BUILD SUCCEEDED **`).

## §3 귀속

- 베이스 origin/master `32df406`. 워크트리 `.claude/worktrees/t15`, 브랜치 `WT-copy-wording`.
- 수리 전 iOS 1회 실패(exit 65 — EventDetailView.swift:215 ViewBuilder 제네릭 추론 오류)는
  alarmStatus 헬퍼 도입으로 해소됐고, §2의 네 게이트는 그 뒤 최종 트리에서 전부 재실측한 값이다.
- 드라이버 217/217 = t23이 세운 기준선과 동일(t10~t15 간 가드 단언 무변경).
- **CLAUDE.md 레시피 정정(sync 판정 D6)**: 위 회차의 "드라이버 레시피에 EditCard.swift가 빠져
  링크가 실패한다"는 이 브랜치에서 거짓이었다 — base `32df406`·본체 `876fc34`의 CLAUDE.md:59 둘 다
  이미 `cat Shared/EditCard.swift Shared/AIAssistant.swift …`로 포함한다(card t1 `f9cd9bb`).
  빠져 있던 것은 주 체크아웃 master(`291db49`, 102커밋 낡음)의 판이고 이 카드 트리가 아니다.
  리드에게 넘겼던 후속은 취소한다.

## §4 갭 — 검증하지 않은 것 (증거 없음 ≠ 통과)

- 런타임 화면: B7 노트가 큰 글씨에서 출처 캡션과 함께 최대 2문장으로 늘어나는 보임새, D-3 두
  문안의 체감, VoiceOver 낭독 — 시뮬레이터·실기기 눈확인 필요(ux-check 확인 목록 항목).
- code-safety 재심사: 발견 1 수리(alarmStatus)는 레인이 적용하고 네 게이트를 다시 돌렸다 —
  **sync 수리 시점(2026-09-25)에 심사 완료**: 본체 diff는 sync 판정이 읽기 전용 렌즈로 통과시켰고
  수리 diff 3헝크는 별도 심사 PASS(§6).
- CHECKLIST.md:520 항목 6(이 묶음)의 "처리됨" 갱신은 sync 몫이었다 — 2026-09-25 수리 문서
  커밋에서 판정문 §3-a 문안으로 기재(§6 D7).

## §5 잔여 위험

- D-3 폼 노트는 syncFieldExtras 호출 시점의 `Date()`로 판단한다 — 폼을 띄운 채 자정을 넘기면
  노트가 다음 카드 변경·재계산까지 갱신되지 않는다. 문장이 "지나야" 말하는 방향이라 과잉 낙관은
  없고 놓칠 수만 있다.
- 출발 역산 산식(`parsed.date.addingTimeInterval(-secs - buffer)`)이 AddEventView 안의 **별개
  군집** 세 곳(예상 출발 노트 :597·D-3 depGuess :612·currentConflicts :687 — 수리 트리 기준)이다.
  Store.swift:1008-1011의 @MX:DEBT는 "이 파일 세 곳"으로 **Store에 스코프**돼 있고 Store는 여전히
  3곳(:1012·:1161·:1191)이라 합침 트리거에 도달한 것이 아니다(sync 판정 D5 정정 — 당초 기록이
  귀속을 오독했다). 네 번째 표시 자리가 생기면 depGuess를 한 번 올려 공유할 것.
- 알림 시각(출발−리드) 산식이 base 2곳(Store.swift:1050 실제 예약·:1225 64건 창 필터)에서
  4곳이 됐다 — 이 카드가 상세 캡션 판정과 폼 판정을 더했다. 지금은 넷이 일치하지만 한 곳에서
  경계 부등호나 리드 의미가 갈리면 캡션이 조용히 거짓이 된다(sync 판정 권고 A3 —
  `ScheduledEvent`에 `alarmDate`를 두는 단일 출처가 후속 카드 후보).
- "가까워지면 알림 예약돼요"는 앱이 다시 foreground될 때 리필된다는 앱 모델 전제(Store.swift:1210-1213
  주석) 위의 문장이다 — 앱을 다시 켜지 않으면 예약은 일어나지 않는다.
- EventDetailView 정보 행이 알림이 꺼져 있어도 "출발 N분 전"을 그리던 기존 결함(당초 :349로
  적었으나 실제 행은 :342였다 — sync 판정 D5)은 **sync 수리에서 권고 A2로 닫았다**(`aea15d4` —
  wantsNotification 조건부 "받지 않음", 현 좌표 :344). 캡션이 아예 안 뜨는 경로 셋(isPast·
  departureDate == nil·travelSeconds == nil)에서도 이 행은 이제 사실을 말한다.

## §6 sync 수리(2026-09-25 — 판정 FAIL D1·D2·D3~D6 → 처방 이행)

판정문: 이 디렉터리 `sync-verdict.md`(주 체크아웃 판정문을 그대로 반입해 함께 커밋 — t14 전례).
처방은 판정문 §3·§7. 디스패치(리드)는 A2를 이 카드에 넣는다는 결정을 포함했다.

| 항목 | 수리 | 좌표(수리 트리 실측) |
|---|---|---|
| D1 | `notify_enabled` 토글이 시각 줄 노트를 다시 조립 — `card = c` 뒤 `syncFieldExtras()` 한 줄(호출처 8→9곳, 재귀·루프 없음) | AddEventView.swift:317 |
| D2 | 폼 문안 "출발 시각이" → "알림 시각이"(판정식·상세 alarmStatus 어휘와 일치) | AddEventView.swift:617 |
| A2(리드 수용) | 상세 정보 행이 wantsNotification 조건부로 "받지 않음" — 캡션과의 자기모순 폐쇄 | EventDetailView.swift:342-344 |
| D3 | 살아있는 인용 18좌표(AIAssistant +4) 치환 + 귀속 밖 맨몸 2좌표(A2 행 — 출발 기준 분기 :1311-1313·buffer 강제 :1320, 내용 실측 후 수리) | CHECKLIST A1·A2·G14·G16·N2·P1 행 + 후속 7 O-1 + plan.md 후속 17 꼬리 |
| D4 | plan.md 카드 표 t15 행(t14 행 다음) + 후속 18 닫힘(`876fc34`) + 후속 19 ③ 잔여 닫힘 | plan.md 카드 표·후속 목록 |
| D5 | §1 표 좌표 6건 실측 교정 + §5 @MX:DEBT 귀속 정정(별개 군집) + 알림 시각 산식을 권고 A3 항목으로 분리 | 이 파일 |
| D6 | §3 CLAUDE.md 레시피 문단 정정 — 브랜치 트리는 t1(`f9cd9bb`)부터 정확, 낡은 건 주 체크아웃 master 판. 리드 이관 취소 | 이 파일 |
| D7 | CHECKLIST 항목 6 "처리됨"을 판정문 §3-a 문안으로 기재(A2·커밋 SHA 반영) | CHECKLIST 항목 6 |

코드 커밋 `aea15d4`(D1·D2·A2) → 재게이트 → 문서 커밋(이 파일·판정문·CHECKLIST·plan.md).

### 재게이트(수리 트리 `aea15d4`, 레인 재실측)

| 게이트 | 관측 |
|---|---|
| iOS | exit 0·`** BUILD SUCCEEDED **`·경고 필터(appintentsmetadataprocessor 제외) 0행, 바뀐 2파일 재컴파일 확인 |
| macOS | exit 0·같은 필터 0행 |
| 가드 드라이버 | `217/217 통과`·exit 0·`[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다`(CLAUDE.md:59 레시피 그대로) |
| 프록시 | `7/7 통과`·exit 0 |

code-safety 심사(수리 diff 3헝크, 읽기 전용): **PASS — 차단 0**. D1 양방향(켜기·끄기) 전 경로
추적, `syncFieldExtras` 멱등·재귀 부재, 폼 판정식과 `NotificationManager.swift:34` `guard date >
Date()`의 경계 여집합 대조, D2 잔여 문구 전수 grep 0건, A2 옛 데이터(nil→켜짐) 무회귀.
비차단 관찰 3건은 판정문 권고와 같은 선(계약 5 잔여 A3·문서 커밋 때 AddEventView 인용 재사상
— 위에서 이행·런온 A9②).

### 잔여(기록)

- **맨몸 인용의 한계**: 판정의 cite_check는 줄 안에 앞선 `.swift` 파일명이 없는 좌표를 검사하지
  못한다. A2 행의 2건은 내용 실측으로 함께 고쳤지만, 같은 한계로 검사 밖에 남는 맨몸 인용이
  살아있는 행에 더 있을 수 있다 — 다음 sync의 cite_check 개선 또는 ux-check 전수의 몫.
- 기기 확인은 판정문 §5(8항목 — D1·D2 재현, 111자 노트 감김, VoiceOver, 알림 권한 거부 A1
  실측 포함)이 운영자 몫으로 그대로 열려 있다.

### §6.1 D3 2차 — 재심사 R3 맨몸 87좌표(2026-09-25, 문서 전용 — 게이트 불요·판정 §R6)

처방: 리드 디스패치(사상표 `.moai/state/verify/t15-sync2/bare-coord-remap.tsv` — 판정자가
base[옛]==head[새]까지 검증한 값) 그대로 치환 → 잔여 0 확인(양성 대조) → 782 이하 후보 행별 판정.

**이행 중 사고와 복구(기록 — 조용히 묻힌 실패의 현장 사례).** 첫 적용 스크립트가 범위 인용의
뒤끝을 `":끝"` 패턴으로 찾았는데 본문은 하이픈(`-끝`)이라 46건가 말없이 안 맞았고, 시작점의 새
값이 우연히 뒤끝 옛 값과 같던 P5 한 건은 시작점이 이중으로 밀려 `:834-830` 역전 오염이 됐다.
두 감사 스크립트 모두 "0건"을 보고했다 — 밀린 좌표는 "이미 재사상된 다른 좌표"와 바이트가
같아 보이기 때문(0건 관측은 양성 대조부터 — 이 프로젝트가 몸으로 배운 규칙의 재발현).
육안 대조로 발견해 문서 둘을 `f377d8c`로 복구한 뒤 **토큰 전체(":시작-끝" 묶음)를 한 번에
교체하는 원자적 치환**으로 재적용했다. 부분 치환 가능성 자체를 없애는 형태로만 안전하다.

| 항목 | 내용 | 근거 |
|---|---|---|
| tsv 87행 | 단일 40건 + 범위 47건(뒤끝은 tsv에 없는 분 — base[끝]==cur[끝+4] 재검증 후 포함) 원자적 치환 | 원장 검증 87/87 |
| 782 이하 56건 판정 | **7건 드리프트 수리**: F5 `currentConflicts` :646→:677·선언 :719→:750(AEV +31)·P2 `choose(field:place:)` :761-765→**:762-766(이 구간은 +4가 아닌 +1)**·P3 `confirmedPlaceKey` :778→:782·plan t14 행 CB 3건 :732·:735·:740→:763·:766·:771(+31). **49건 무드리프트 확정**(행 소재 파일이 t15 무변경 — AIAssistant 하위 구간·AddActivityView·GuardDriver·CLAUDE.md·Store·EditCardView 등, base==cur 바이트 확인) | 내용 지문 탐색(주변 5줄 대조, 유일 hit) |
| 잔여 0 확인 | ① tsv 원장 **문자열 대조**(f377d8c 원본에서 기대 토큰 복원→현재 문장에 있는지) 87/87 ② **양성 대조 2종** — 뒤끝 되돌림·시작 되돌림 사본에서 각 1건 검출(exit 1)으로 검증기 민감도 증명 ③ 맨몸 감사(표 행 256줄, >782 잔여 0) — 이 감사의 0은 열거 완비 확인용이고 폐쇄 근거는 ①이다(바이트 우연 일치에 면역이어야 함) | 위 경위 |
| 구간 부등 이동 | AIAssistant의 t15 이동은 균일 +4가 아니다 — `choose` 주변(:761)은 **+1**. tsv 87좌표가 전부 :841 이상이라 이 구간은 1차·2차 어느 쪽에도 안 잡혔다. 내용 지문 탐색이 아니면 +4로 오식할 뻔 | 지문 탐색 hit :762(유일) |

판정 7건 좌표는 전부 수리 트리(aea15d4 + 문서 커밋) 기준 실측이다.
