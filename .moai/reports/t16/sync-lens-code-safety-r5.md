# t16 sync 재심사 렌즈 — code-safety 5회차 (원문 보관)

- 대상: 브랜치 `WT-place-resolution` HEAD `daa77c1`(코드 = `daa77c1`, SPEC 0.1.9), 4차 판정 `a99f881`
- 수행: 2026-09-29, sync 5차 판정 레인(칸반 리드·GLM)이 띄운 읽기 전용 렌즈(`hns-besir-app-code-safety-specialist`). run 레인과 다른 손이다.
- 아래 원문은 렌즈 반환문을 그대로 옮긴 것이다(틀 들여쓰기만 벗겼다).

---

판정: **PASS-obs** (차단 결함 0건 · 비차단 6건). 측정 트리 daa77c1 (f441f8f·a99f881 문서전용 확인, `git show --stat`). 검토 범위: `git diff fa75e6e..daa77c1 -- Shared Tools` 전체(Shared/AIAssistant.swift +65, Tools/GuardDriver.swift +433)와 그것이 닿는 주변 함수 원문 전체(resolvePendingAsk 1200-1311, askFields 485-638, stayingTokenForColocatedPick 1313-1344, filledValueLabels 882-906, pendingAsk 855-876, 실행부 1710-2290, 토큰 정의부 2973-3009, EditCard.swift 145-247, GuardDriver AE 절 3058-3440, 드라이버 헬퍼 30-200, AIChatView 107-110, saveHistory 140-147). 모든 줄번호는 현 트리 sed -n 실측.

## 1. J-1 갈래 도달성·새 위험 (질문 1)

**도달 경로 전수 열거.** fresh(1289-1301)가 비어 있으려면 "카드가 세워질 때 억제됐는데 주입 뒤 필요해진 줄"이어야 한다. askFields에서 억제는 staying 갈래 둘뿐이다:

- **create_activity 한 번짜리 머무름** (`Shared/AIAssistant.swift:590-601` break — 수단·여유·알림 억제, I-1): 출발지 줄(travel_from_query)에서 (i) 실제 장소 픽(좌표 몰라도 — `stayingTokenForColocatedPick` 1339-1341이 좌표 아는 픽만 토큰화), (ii) '현재 위치' 픽인데 측위가 50 m 밖(가드 1342 탈락 → 토큰 그대로 적재 1266). 그러면 stayingOneShotActivity(808-813)가 거짓이 되어 626-634의 mode_this_time·buffer_minutes·notify_lead_minutes 줄이 fresh → 두 번째 카드. '이동 없음'/동조 픽은 staying 유지(812)라 카드2 없음.
- **create_recurring_schedule 머무름** (`Shared/AIAssistant.swift:544-558` 억제): origin_query 줄에서 같은 두 종류 픽 → 555-557 줄 fresh. weeks는 559가 무조건이라 늘 1번 카드에 있어 fresh 불가.
- **create_schedule은 카드2에 도달 불가**(정합 확인): mode(528)·notify(534)는 비면 무조건 1번 카드에 오르고, buffer(531-533)는 "시각 줄이 떠 있는" 모양에서 이미 카드에 있다가 dep: 픽이 들어오면 531 조건 자체가 소멸한다. datetime 주입(1268-1274)이 새 줄을 만드는 방향으로는 작동하지 않는다. 또한 buffer 의도적 미주입(1247-1249 스킵) 뒤에도 askFields가 buffer를 돌려주지 않아(531: arrival 무·departure 유) fresh 재발이 없다.
- 후보 카드(parkForUnclearPlaces) 경유의 staying 반복(origin이 unclear로 비웠다가 픽)도 927이 비우기 전 인자로 줄을 만들므로 같은 의미론으로 card2에 도달 — 정상 확장.

**(a) 정상 경로 손실·이중 질문 — 없음.** 1번 카드 줄은 키로 배제(1295)되어 재질문 없음. 주입값은 parts(1277-1278)에 실린 채 card2로 이동(1304). card2의 stated가 filledValueLabels(1300)로 활동 장소 등 맥락을 유지한다. 측위·모델 턴 사이에 끼는 것 없음 — card2는 앱이 args를 그대로 쥐며(1302-1306), confirmAsk의 카드 뒤 가드(1184)가 모델 재호출을 끊는다(주석 1287 그대로).

**(b) 다중 호출 오염 — 없음.** fresh는 키 단위 dedup(1296)로 pendingAsk(860)와 같은 "한 장 카드·같은 답 전부 적용" 의미론. 주입은 그 호출의 askFields가 줄을 돌려줄 때(=그 호출에서 비어 있을 때만, 1242-1243) 실리므로, 값이 찬 호출은 건드리지 않는다. 한 호출의 fresh가 다른 호출의 카드를 오염시키는 방향은 열거 전수에서 발견되지 않았다.

**(c) 세 번째 카드 — 불가(유한).** card2 필드는 mode/buffer/notify/weeks로 한정됨을 열거로 확인했다: fresh에 장소·시각 줄이 오려면 주입이 장소 값을 비우거나 시각을 지워야 하는데 주입은 채우기만 한다. card2 확인 주입이 staying 판정(장소 값만 봄, 799-813)을 바꿀 방법이 없으므로 fresh 재발이 없다. 실행부 후보 카드(parkForUnclearPlaces)는 다른 메커니즘(기존)이며 followUp-of-followUp이 아니다.

**(d) 순서 위험 — 없음.** J-1 블록은 await 없음(완전 동기). 함수의 유일한 await(측위 1257) 직후 세대 가드(1265)가 불일치 시 nil 복귀 → 카드2 미생성(버린 대화에 카드 안 달림). card2에 .place 필드가 없어 clearedKeys(1231)·측위·confirmedPlaces 경로는 전부 죽은 상태로 안전하다. stayingEndAsk(B-3)는 end_iso/return_time이 카드보다 먼저 확보되는 구조(563/540)라 card2와 무관. AE-C-2(3350-3360)가 이 세대 경계를 실측위 대기 중 실제 재설정으로 단언한다.

**(e) stated 토큰 유입 — 불가.** filledValueLabels의 add(889-893)가 `!isInternalPlaceToken(v)`로 세 토큰을 거른다(D1). AE-S-1a/1b(3083/3093)가 이를 stated 문자열에 "__" 없음으로 단언한다.

**새로 관찰된 경합(비차단 4번).** 1번 카드 확인 시점 측위(>50 m → 토큰화 안 됨)와 card2 확인 뒤 실행 시점 재측위(`resolveOriginAdoption` 2957-2958) 사이에 사용자가 이동하면 50 m 이내가 되어도, 실행부의 stayedByDistance 절(1961)은 stayingOneShotActivity(input) — 토큰값을 place 문자열과 비교 — 이 거짓이라 못 잡고 초근접 이동 구간이 생길 수 있다. 사전에도 있던 측위-시간 경합이 J-1로 새로 도달 가능해진 경로. 실질 피해는 수십 미터짜리 구간 생성(경미).

## 2. J-3 매퍼 완전성 (질문 2)

사용자에게 렌더되는 토큰 가능 값의 **전 사이트 열거**:

| 사이트 | 처치 | 판정 |
|---|---|---|
| stayingOriginNote 830, roundTripOriginNote 837 | displayText | ✓ (본 델타) |
| unresolvedQueryText 1979-1980 | currentLocation→displayText, 나머지 토큰 isInternalPlaceToken 차단 | ✓ |
| filledValueLabels 890 | isInternalPlaceToken 필터 | ✓ |
| chosenLine→chosenLabel (EditCard.swift:172-175) | 옵션 value→label 사전 경유 — 세 토큰 칩에 모두 라벨 있음(646/700/703/820-821) | ✓ |
| unknownPlaceNote 3047 | unresolvedGenericPlace(3034)가 토큰을 일반명사로 안 봄 → 도달 불가 | ✓ |
| unclearPlaceNote 849, park names 949 | 토큰은 검색에 진입 불가(1931/1934/1939, 2142, 2957, 1753 차단) | ✓ |
| 실행부 isSamePlace/요약문(1774, 1838, 2015, 2094, 2284) | 해석된 Place.name만 — 토큰 아님 | ✓ |
| 정화 에코 드롭 987-990 | 모델 턴 유입 차단 | ✓ |
| **sameNamePlaceNote 844** | **raw 삽입, searchBoundPlace(759-763)가 토큰을 못 걸러냄** | **잠복(비차단 2번)** |

sameNamePlaceNote가 터지려면 같은 토큰이 두 줄에 공존해야 하는데 destination/place/return_to 줄은 칩이 없고 모델 에코는 정화가 버려 사실상 도달 불가다. 그러나 네 라운드의 누출 이력("자리마다 따로 나왔다")이 보여주듯 도달 불가는 영구적이지 않다 — `repeatedSearchQuery`/`searchBoundPlace`에 `isInternalPlaceToken` 한 줄이면 닫힌다.

## 3. 4대 위험군 + 단순성 (질문 3) — 전항 "0건"의 표집 범위 명시

표집 범위: **델타 전체 + resolvePendingAsk·askFields·두 staying 판정·실행부 create 셋·카드 뷰·saveHistory**. (이 외 파일의 기존 위험은 이 카드 범위 밖.)

- **H1(await 후 인덱스)**: 델타가 await를 추가하지 않음. bubbles[idx] 교체(1209)는 await 전, card2 append는 동기, 1265 가드가 await 창을 커버. AE-C-2가 단언. **0건.**
- **H2(조용한 실패)**: card2 경로의 `return nil`은 카드 자체가 가시 산출물(948 parkForUnclearPlaces와 같은 모양). 빈 텍스트 말풍선은 렌더 문제 없음(AIChatView.swift:107-110 — ask 있으면 EditCardView만 그림). saveHistory(140-147)가 ask 말풍선을 제외해 보류 인자의 토큰이 디스크에 안 남는다. **0건.**
- **H3(무한 증가/외부 한도)**: 요청당 카드 ≤ 2 + 후보 카드(기존), bubbles·contents 유한, 알림 경로 무변경. **0건.**
- **H4(중복 계산)**: askFields가 확인당 호출당 2회(1242 주입용 + 1294 J-1용) — 주입 **뒤** 상태를 봐야 하므로 2회는 본질적으로 필요하고, 함수는 동기·메모리·저렴(즐겨찾기 스캔). token→표시문구가 두 벌(칩 옵션 라벨 646/700/703/820-821 vs displayText 2994-3000)인 것이 계약 5 관점의 경미한 중복(비차단 3번) — 칩 문구를 고치면 chosenLine과 캡션이 어긋날 수 있다.
- **단순성**: followUpFields가 최소 형태다 — 대안은 거절문 모델 반환(교착의 원본)이거나 선제 수단 질문(I-1·AC-008 (5) 위반). J-1 블록이 pendingAsk(855-876)와 18줄 평행 구조이나, 배제집합(ask.fields) 매개변수 때문에 헬퍼화는 조기 추상화다. 통과.

## 4. J-2 단언 품질 (질문 4)

헬퍼가 진짜 경로를 탄다: drvAsk → 정화→fillStated→pendingAsk 실물(88-92), drvResolvePendingAsk → 실제 resolvePendingAsk(153), drvLiveAsk → live bubbles(102), drvSeedCurrentLocation → 실제 LocationManager(168), 최종 단언은 store.activities/store.events 직독. 모형 아님.

- **AE-S-3a/3c (3132-3146)**: 3단 모두 end-to-end — (1) `first == nil && followUp != nil` + 키 집합이 정확히 {mode_this_time, buffer_minutes, notify_lead_minutes}(집합 동등 — 공헨 불가), (2) drvCallArgs로 보류 parts의 travel_from_query가 currentLocationToken 그대로임을 관찰(토큰 보관 단언), (3) 최종 activities==1 && events==1. mode가 주입 안 되면 missingAskedArguments(1913)가 거절해 count 0이 되므로 (3)은 공허 통과가 불가능하다.
- **AE-C-1 (3310-3321)**: (1/2)는 같은 강도. **(2/2)는 라벨-술어 불일치** — "가는 이동 1로 완주한다"고 쓰였으나 술어는 `activities == 1`만(3319)으로 events 수를 검증하지 않는다(S-3a·C-1r보다 약). 가는 구간이 사라지는 회귀는 activities만으로도 잡히지 않는다(비차단 1번).
- **AE-C-1r (3338-3348)**: (1) 키 집합, (2) `events 비어있지 않음` — 통근 구간 실생성 검증. 실질적.
- **'30 ✓ AE-' 주장 — 정적 세기 일치(행복 경로)**: 정적 18(S-1a·S-1b·S-2·S-3a+·S-3b·S-3e·S-3r·S-4·S-4v·B-1·C-1×2·C-1r×2·C-2·R3-b×2·R3-d) + 동적 12(aeStayingCurrentLocation 2호출×3단언, aeAnchorFromPick 2×1, AE-C-3/R3-c 루프 2, AE-R3-a 루프 2) = **30**.
- AE-R3-d(3430-3445)가 J-3 수정 지점(왕복 후보 카드 캡션)을 정확히 검증 — note에 "__" 없음 + "현재 위치" 포함.

## 비차단 목록 (merge 후 처리 가능)

1. `Tools/GuardDriver.swift:3318-3320` — AE-C-1 (2/2) 술어가 라벨 대비 불완전(events 수 미검증).
2. `Shared/AIAssistant.swift:844` + 759-763 — sameNamePlaceNote raw 삽입, searchBoundPlace의 토큰 무방비(현시점 도달 불가, 잠복). isInternalPlaceToken 한 줄로 폐쇄 가능.
3. `Shared/AIAssistant.swift:2994-3000` vs 646/700/703/820-821 — 토큰 표시문구 두 벌(계약 5 경미).
4. `Shared/AIAssistant.swift:1339-1341` / `1961-1966` — 카드 확인-실행 사이 측위 이동 시 초근접 구간 생성 가능(stayedByDistance가 토큰값 비교로 못 잡음). 경미.
5. `Shared/AIAssistant.swift:1300` — card2 stated가 statedLabels()를 안 얹는다(pendingAsk 865 대비). 말한 수단이 statedArgs에 있으면 card2 줄이 줄고(작동 정상) 그 값이 card2에 재표시되지 않으나 1번 카드가 이미 보였다. 화용적.
6. `Shared/AIAssistant.swift:2161` — 반복의 현재 위치 실패 문구가 선택을 언급 안 함(create_schedule 1753-1754·활동 1979과 불일치). 등록이 막히므로 조용한 등록은 아니다. 화용적.

## Gaps (명시적 미검증)

- **드라이버 실행 결과(355/355·exit 0)와 iOS·macOS 무경고 빌드** — 지시에 따라 내가 돌리지 않았다. 판정 레인이 게이트로 재현해야 한다. 내 AE 단언 30건은 정적 세기다.
- Swift 컴파일·타입 검증 없음(읽기 전용 정적 검토).
- 실기기 UX(카드2의 칩 선택감, 실측위 타이밍) — 시뮬레이터 절차·실기기 확인 대상.

## 잔여 위험

fresh 도달 경로의 "불가" 결론은 askFields 전 갈래의 열거 추론에 기반하며, 드라이버 30단언은 대표 경로를 덮지만 왕복+같은이름+unknown 조합의 전수 조합 실행은 아니다. 측위 시차(비차단 4번)는 재현이 시드 타이밍에 좌우된다.
