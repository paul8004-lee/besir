# t16 — C7 장소 해석 UX 진행 기록 (1차·AI측, WT-place-resolution)

카드: "C7 장소 해석 UX — U-4(지점 불일치) + AC-009 7·9(되묻기/create 카드에 장소 줄 안 생김) +
U-2(장소검색 열 때 옛 선택 강조 잔여·뷰 몫) + 2026-09-24 관측(왕복 create_activity 카드의 가는 편
출발지 줄·'가는 편 없음' 칩 부재, '집에서 점심식사'→통근 76건)."
부류: Class B(SPEC 없음, plan 건너뜀). 베이스: origin/master `aa7b792`(t15 병합판). 워크트리
`.claude/worktrees/t16`, 브랜치 `WT-place-resolution`.
원형 정의의 출처: 백로그 t16 본문(2026-09-24 시뮬레이터 14항목 세션 관측 반영)·
day-close-20260924.md §6 #21·#23·#24 / §7 C7·SPEC-UIKIT-005 acceptance.md AC-009 7·9번
("되묻기 카드에 출발지 줄과 목적지 줄이 함께", "create_activity 카드에 장소 줄이 셋").

## §1 무엇을 고쳤나

| 항목 | 원형 근거 | 수리 | 좌표(이 트리 실측) |
|---|---|---|---|
| U-4 지점 불일치(최우선) | resolveOrigin/resolveDestination이 검색 `.first`를 조용히 채택 — '스타벅스 홍대점'→대학로점(2026-09-23), '강남'→서울선릉과정릉(2026-09-24, 빌드 5a357cc) | 해석 사다리를 단일 출처 `adoptPlace`(즐겨찾기→확정→일반명사 가드→검색)로 통합하고 검색 채택을 삼태(`resolved/notFound/unclear`)로. 첫 결과의 이름+주소가 질의의 구분 낱말(띄어쓰기 토큰, 끝의 점·역은 제거)을 전부 포함하지 않으면 `unclear` — 등록 실행부가 **기존 되묻기 카드**를 열어 상위 5후보를 줄에 미리 얹는다(`parkForUnclearPlaces`). 모호한 질의만 보류 인자에서 비워 확인 시 주입이 일어나게 했다. 모델이 같은 호출을 되풀이하면 카드를 두 장 열지 않는다. 조회 경로(check_travel_time·recommend_meal·수정)는 평탄화해 첫 결과를 그대로(옛 동작) | 삼태 `PlaceAdoption` :2645·`adoptPlace` :2653·토큰 판정 `searchTopClearlyMatches` :2685·래퍼 `resolveDestination` :2701·`resolveOrigin` :2568/`resolveOriginAdoption` :2579·실행부 갈래 create_schedule :1455-1487·create_activity :1628-1660·create_recurring :1783-1806·되묻기 카드 `parkForUnclearPlaces` :786-813 |
| AC-009 7번(재질문에 출발지·목적지 줄 안 뜸) | 값이 차 있으면 askFields가 장소 줄을 만들지 않아 첫 결과 채택이 두 줄을 한 지점으로 무너뜨리고 isSamePlace가 거절로 끝났다(2026-09-23 관측 FAIL) | 한 호출의 장소 줄에 **검색에 맡겨질 같은 이름**이 둘 이상 오면(즐겨찾기·확정 장소·일반명사 제외) 값이 차 있어도 두 줄을 띄우고 "왜 다시 묻는지" 캡션을 단다. 사용자가 각 줄에서 지점을 고르면 t6의 confirmedPlaces 열쇠로 각각 다른 좌표가 실린다 | create_schedule 같은이름 줄 :495-507·`repeatedSearchQuery` :708·`searchBoundPlace` :700·캡션 `sameNamePlaceNote` :729 |
| AC-009 9번(create_activity 장소 줄 셋) | 같은 무너짐이 활동 경로에도 — 이쪽은 isSamePlace 가드가 없어 0분 구간이 조용히 생긴다 | 세 장소 줄(place/travel_from/return_to)에 같은 검색 이름이 섞이면 셋 다 줄을 띄운다 | :537-548 |
| 왕복 create_activity 카드의 가는 편 출발지 줄·'가는 편 없음' 칩 부재(2026-09-24 관측, 체크리스트 (b) 8번 관측 불가의 원인) | 생산자는 **AIAssistant의 askFields·outboundOriginField**(뷰 아님) — `if back, !outbound` 조건이라 모델이 travel_from_query를 채워 보내면(이 모델의 습관, H8) 줄이 사라졌다 | 왕복 호출(return_to_query 있음)에서는 값이 차 있어도 가는 편 출발지 줄을 항상 띄운다 — 탈출 칩이 돌아오고, 차 있던 값은 캡션으로 왜 다시 묻는지를 설명한다. 출발지를 절대 추측해 넣지 않는다는 2026-09-16 결함 A의 결과와 같은 자리 | :549-564(조건 `if back, !fields.contains…`) |
| '집에서 점심식사' 반복이 통근형(회사↔집 76건)으로 | 이 도구로 "한 장소에 머무는 반복"을 표현할 와이어 형태가 없어 모델이 출발지를 지어냈다. 반복 경로엔 isSamePlace 가드도 없어 0분 통근이 그 수만큼 조용히 생길 수 있었다 | (a) 선언·프롬프트에 의미를 정의: origin_query=destination_query 같은 값 = 머무는 반복(이동 구간 없음). (b) 실행부 가드: 해석 뒤 출발지≈목적지(50m)면 통근 다리를 만들지 않고 **활동 블록만** 생성(끝 시각 return_time 필요 — 없으면 그 인자를 요구하는 재호출 안내). 카드 쪽에서는 머무는 반복이면 수단·여유·알림 줄을 묻지 않는다(쓸 구간이 없다) | 선언 :1273·프롬프트 :1193·실행부 변환 :1808-1839·카드 억제 `stayingRecurrence` :720, 적용 :520-529 |

공유 부품: 줄 공장 디스패처 `placeRow` :687(되묻기 카드가 키 하나로 재료를 얻는 단일 출처),
`filledValueLabels` :764(runLoop 카드와 실행부 카드의 "말씀하신 대로" 문장 단일 출처 — pendingAsk에서
추출), 캡션 `unclearPlaceNote` :734. 계약 5 준수: 장소 해석 사다리·줄 재료·캡션이 각각 한 곳에만 산다.

범위 밖(원상 유지·기록): U-2 강조 잔존은 뷰 몫(§6 좌표), 점심 장소(lunch_place_query)는 되묻기
카드를 열지 않는다(실패·틀린 지점이 결과 문구에 이름으로 드러나고 통근 전체를 멈춰 물을 자리가
아니다 — :1876 주석), update_schedule의 new_place_query·check_travel_time은 조회/수정 경로라
첫 결과 채택 그대로.

## §2 증거 — 돌린 명령과 관측 (최종 트리 전수 재실측)

| 게이트 | 명령 | 관측 |
|---|---|---|
| 가드 드라이버 | `cat Shared/EditCard.swift Shared/AIAssistant.swift Tools/GuardDriver.swift > /tmp/gd16.swift && swiftc -o /tmp/gd16 …(CLAUDE.md 블록 그대로) -parse-as-library && /tmp/gd16` | **exit 0 · `241/241 통과` · ✗ 0 · `[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다`**. t23 기준선 217 → +24(신설 AA절 23 + T절 D2 칩/캡션 1). AA절 전 줄 ✓(로그 `/tmp/gd16-run2.log`) |
| iOS | `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build > build-ios.log` | exit 0 · `** BUILD SUCCEEDED **` 1회 · swift 경고 **0**(`grep "warning:" build-ios.log \| grep -v appintentsmetadataprocessor` 0행) |
| macOS | 같은 형식 `-scheme besir-macOS > build-mac.log` | exit 0 · BUILD SUCCEEDED · 같은 필터 경고 **0** |
| 프록시 | `cd proxy && npm test` | `7/7 통과` · exit 0(이 카드는 프록시 무변경 — 무결 확인) |
| 고정 토큰비 | plan.md:233 측정법(systemPrompt 원문 + toolsJSON 직렬화 sortedKeys·공백 없음 → tiktoken `o200k_base`)을 **base와 head 양쪽에 동일 적용** | base `3,824`(시스템 1,704 + 툴 2,120) → head **`3,946`(1,771 + 2,175), Δ+122**(+67/+55 — 프롬프트 1줄·recurring origin_query 선언). 선언이 늘었다: t23판 4,425 기준선을 이 방법으로 이 기계에서 재현하면 base가 3,824로 나온다(직렬화·tokenizer 버전 차이로 추정) — 절대치가 아니라 **동일 방법 base 대비 +122(+3.2%)** 을 귀속 값으로 보고한다 |

빌드 로그 원본: 워크트리 루트 `build-ios.log`·`build-mac.log`(미커밋).

## §3 귀속

- 베이스 origin/master `aa7b792` + 본 카드 미커밋 diff(`Shared/AIAssistant.swift`·`Tools/GuardDriver.swift`
  2파일 — 커밋하지 않고 레인 판정에 넘긴다). 새 파일 추가 없음 → xcodegen 불요(서명 리셋 회피).
- §2의 네 게이트는 주석 순서 정리(askFields 내 같은이름 블록 이동) 뒤 최종 트리에서 전부 재실측한 값이다.
- 토큰 측정은 base(origin/master 판 두 파일)와 head를 **같은 하니스·같은 인코더**로 잰 쌍이다
  (/tmp/tok16base.out·/tmp/tok16.out). 서로 다른 측정끼리 더하거나 빼지 않는다(plan.md:234 원칙).

## §4 갭 — 검증하지 않은 것 (증거 없음 ≠ 통과)

- **실제 모델 왕복은 전부 미검증** — 드라이버는 모델 없이 돈다. 같은이름 줄이 실제 발화
  ("스타벅스 가야 해, 스타벅스에서 출발할게"·AC-009 7·9번 원문)에서 모델 인자와 함께 뜨는지,
  U-4 후보 카드가 실검색(카카오) 결과로 열리는지, '집에서 점심식사'가 모델에 의해 같은 값
  origin/destination로 오는지(프롬프트 준수)는 시뮬레이터·실기기 확인 항목이다. AC-009 7·9번의
  사람 판정은 SPEC-UIKIT-005 acceptance.md 그대로 열려 있다.
- **후보 카드의 실검색 연동 갈래** — 드라이버는 MapKit 폴백이라 검색 결과가 결정적이지 않아,
  `parkForUnclearPlaces`를 후보 주입으로 직접 열아 검증했다(AA-6·AA-7). 검색→unclear 판정→카드의
  종단 연결은 실기기에서 본다.
- 토큰 절대치(3,946)는 이 기계·이 tiktoken 버전의 값이다 — t23 기준선(4,425)과의 차이는 측정 재현
  불일치이지 이 카드의 증가분이 아니다(증가분은 +122).
- 시뮬레이터 UX(칩 감김·VoiceOver·캡션 체감)·U-2 뷰 수리는 이 카드 1차(본 기록) 밖.

## §5 잔여 위험

- **토큰 판정의 경계**: 구분 낱말이 결과 이름·주소 어디에도 없으면 되묻는다(의도됨). 다만
  주소 표기 차이('서울시' vs '서울')로 거짓 되묻기가 날 수 있다 — 후보가 줄에 있으니 한 번 더
  고르는 비용으로 닫힌다. 낱말 목록·접미어(점·역)는 정적 집합이라 완전하지 않다
  (genericPlaceWords 스냅숏 한계와 같은 성질).
- **머무는 반복의 문자열/좌표 어긋남**: 카드 억제는 문자열 같음, 실행부 변환은 해석 뒤 50m —
  '집'/'우리집'처럼 다른 이름의 같은 좌표면 카드는 수단을 묻고 실행부는 구간을 안 만든다(묻는 쪽이
  손해라 그대로 둔 선택, :722 주석). 머무는 반복에서 lunch_* 인자가 오면 조용히 버려진다(변환 요약이
  만들어진 것만 말한다).
- **후보 카드와 모델 재호출**: 실행부가 카드를 연 뒤 모델이 안내를 무시하고 같은 호출을 되풀이하면
  "이미 같은 질문" 안내로 카드를 한 장 유지한다(루프 상한 5회 안에서 끝난다). 모델이 이 안내를
  지키는지는 실기기 관찰 몫.
- **인용 드리프트(다음 sync에 반드시)**: AIAssistant.swift가 base 대비 +331줄(2753줄) —
  CHECKLIST.md·plan.md·SPEC-UIKIT-005/007 문서의 `AIAssistant.swift:숫자` 인용 중 옛 ~:490 아래는
  전부 밀렸다(예: 프롬프트 규칙 블록·maxPlaceSuggestions·isSamePlace 옛 좌표). t15 D3식 cite_check
  재사상이 필요하다 — 본 카드에서 고치지 않았다(범위 밖, 무계획 대량 편집 금지).
- GuardDriver 낡은 좌표 11 끝점(t9 §E.4.2 값)도 이 증가로 다시 밀린다 — 같은 sync에서 재사상.

## §6 다음 전문가(뷰측 2차)에게 넘기는 것

- **U-2 강조 잔존** — 생산자 좌표: 칩 강조 판정 `EditCardView.swift:116`
  (`chip(option.label, selected: field.chosen == option.value, …)`), 검색창 열림 `openCustom`
  `EditCardView.swift:416-424`(`customOpen.insert`), 장소 검색 에디터 `placeSearchEditor`
  `EditCardView.swift:316-318`. 이월 목록의 처방은 "검색 열면 강조 취소 1줄".
- 카드 문법은 본 1차에서 그대로다 — 같은이름 줄·후보 카드 모두 기존 AskField/EditCard 표면만
  쓰므로 뷰 수정 없이 렌더된다(빌드 무경고로 확인).
