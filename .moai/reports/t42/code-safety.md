# besir 카드 t42 — 반대측(code-safety) 판정

- 일시: 2026-10-05 · 판정 레인: code-safety (읽기 전용 — 고치지 않음)
- 대상: worktree `WT-origin-candidate` 미커밋 diff (`git diff` — Shared/AIAssistant.swift +108/−27, Tools/GuardDriver.swift +129/−0)
- 방법: diff 헝크 전수 → 의심 지점마다 현재 트리에서 주변 함수 통독(`adoptPlace` :3078-3107, `normalizedPlaceWord` :3114, `searchTopClearlyMatches` :3133, `suffixStrippedRetryQuery` :3145, `placeAdoptionDecision` :3169-3186, `mergedPlaceResults` :3192, `resolveDestination` :3203, `resolveOriginAdoption` :2959-2969, `locallyResolvedPlace` :1357, `parkForUnclearPlaces` :918-972, `executeCreateSchedule` :1765-1788, `executeCreateActivity` :1928-1959, `executeCreateRecurringSchedule` :2171-2178, `PlaceSearch.search` :9-19). 접미·정규화 규칙의 이중 출처 여부는 grep 전수(`hasSuffix("점")|hasSuffix("역")`). 게이트는 로그 판독으로 대체(재실행 안 함).

## 판정

**PASS — 차단 0건.** 기록 5건(R-1~R-5, 전부 낮음·기록만). 커밋을 막을 결함은 없다.

## 렌즈별 판정

### 1. await 전후 인덱스 불변 (H1) — 0건, 통과

`adoptPlace`에 await가 1회(재시도 검색) 늘었다. 두 await 사이에 잡아 둔 인덱스·식별자가 없다 — `firstResults`/`retryResults`는 지역 값이고, `firstResults[0]`(:3097) 접근은 `firstResults.isEmpty ||`의 단락 평가 뒤라 빈 배열 폭발 경로가 없다. `locallyResolvedPlace`(즐겨찾기·확정 사전 읽기)는 첫 await 앞에서 한 번만 읽히고 await 뒤에 다시 읽는 곳이 없어 무효화 창이 없다. 호출부(executeCreateSchedule :1765, executeCreateActivity :1928·1949, executeCreateRecurringSchedule :2171)는 unclear 배열에 append만 하고, `parkForUnclearPlaces`의 `fields.firstIndex`(:942)는 동기 구간 안이다.

### 2. 조용히 묻히는 실패 (H2) — 0건, 통과

`PlaceSearch.search`(:9-19)는 카카오 실패 시 `try?`로 삼키고 MapKit 폴백, 최종 실패는 빈 배열로 표현된다 — 이 변경이 그 의미를 바꾸지 않았다. 재시도 검색이 실패해 빈 배열이면 `mergedPlaceResults(retry: [], original: firstResults)`는 원본 그대로(빈 원본이면 빈 배열 → notFound). 즉 재시도 실패는 옛 동작(재시도 없던 판정)으로 정확히 되돌아가고, 새로운 실패 경로가 열리지 않는다. fire-and-forget `Task { try?` 도 diff에 없다.

### 3. 외부 한도 (H3) — 0건, 통과

카카오 호출 증가는 **질의당 최대 1회 추가**이고, (a) 첫 결과가 비었거나 낱말 불만족이고 (b) 마지막 낱말에 뗄 '점'·'역'이 있을 때만 켜진다(:3096-3098). 연쇄 재시도 없음(`suffixStrippedRetryQuery`는 한 번만 벗긴다 — 주석에도 명시). 결과 목록은 카카오 size=10 고정, 후보는 `maxPlaceSuggestions`(5) 상한 그대로. 알림 64건·반복 26주·AI 토큰 경로에 이 변경이 닿는 곳 없음(툴 선언 무변경 확인).

### 4. 복제된 계산·단일 출처 (H4) — 0건, 통과 (1건 인접 주의)

- 접미 규칙은 `normalizedPlaceWord` 한 곳에서 나와 `searchTopClearlyMatches`·`placeAdoptionDecision`·`suffixStrippedRetryQuery`가 전부 이 함수만 부른다(grep 전수: AIAssistant.swift 외 `hasSuffix("점"|"역")` 일치 0건).
- `DirectionsService.swift:209`의 `hasSuffix("역")`은 **다른 목적**(대중교통 길찾이용 역 이름 조립)이라 이번 단일 출처 위반이 아니다 — 다만 두 곳이 서로를 모른다는 점은 기록해 둔다.
- 삼태 판정도 `placeAdoptionDecision` 한 곳에 모였다. `firstResults[0]` 만족 검사가 `adoptPlace`(:3097)에 한 번 더 나오지만 이는 재시도 여부를 정하는 물음이지 채택 판정이 아니고, 술어는 같은 `searchTopClearlyMatches`를 부른다.

### 5. 잠재 결함 각성 — 기록 5건 (차단 0건)

**R-1 (낮음, 기록) — 주차 안내 문구가 새 unclear 사유를 설명 못 한다.**
`AIAssistant.swift:968`: "검색 첫 결과가 사용자가 말한 지점과 확실히 맞지 않아요(이름이 다른 곳으로 보여요)". t42 ① 사례(스타벅스 강남점 → 강남 지점 셋)는 이름 낱말이 다 맞는데 **지점이 갈려서** 물어보는 경우다 — "이름이 다른 곳"은 거짓 설명이 된다. 모델이 이 문구를 사용자에게 그대로 옮기면 오판 안내가 간다. 권고: 문구를 "확실히 하나로 좁혀지지 않아요"류로 넓힌다.

**R-2 (낮음, 의심 — 실관측 필요) — 후보 중복 제거 기준이 정규화 이름이라 서로 다른 지점이 겹쳐질 수 있다.**
`AIAssistant.swift:3184`: `seen.insert(normalizedPlaceWord($0.name))` — 'OO홍대점'과 'OO홍대역'은 정규화 뒤 둘 다 'OO홍대'가 돼 한쪽이 후보에서 사라질 수 있다(같은 이름 다른 좌표는 살아남지만, 접미어만 다른 다른 좌표는 숨는다). 병합(mergedPlaceResults)은 이름+위도+경도 3종이라 정확한데 후보 dedup만 이름 기준인 게 어긋난다. 재현: 두 결과가 정규화 뒤 같고 좌표가 다른 목록. 권고: 후보 dedup도 좌표를 포함하거나, 실관측에서 겹침이 관측되면 그때 고친다.

**R-3 (낮음, 기록) — adoptPlace의 재시도 결합 배선이 드라이버 단언 밖에 있다.**
드라이버 t42절(AI-1~13)은 순수 함수(판정·재시도 쿼리·병합)만 주입 검증한다. "첫 결과 불만족 × 접미 존재 → 재시도 1회 → 병합 → 판정"의 **결합 자체**(:3094-3106)를 결정적으로 검증하는 단언이 없다 — adoptPlace가 네트워크를 품고 있어 주입 지점이 없는 구조적 한계. 파일 머리말에 "실기기 몫"이라 적혀 있으나, search 클로저 주입이 없는 이상 이 배선의 회귀는 드라이버가 못 잡는다는 사실 자체를 기록으로 남긴다.

**R-4 (낮음, 기록) — 조회 경로(check_travel_time·recommend_meal·update_*)의 unclear 평탄화 값이 바뀌었다.**
`resolveDestination`(:3203-3210)은 unclear → `candidates.first`인데, 후보 순서가 '만족 결과 우선'으로 바뀌어 첫 결과가 낱말 불만족이던 조회에서 **이전엔 raw 첫 결과, 이후엔 만족하는 첫 결과**가 쓰인다. 방향은 개선(빗나간 첫 결과 대신 낱말이 맞는 결과)이지만 행동 변화이므로 기록. unclear 빈도 증가(다지점 갈림이 새로 unclear에 합류)는 등록 경로에서만 카드로 가고, 조회 경로는 위 평탄화로 흡수된다 — 되묻기 폭주 경로 없음.

**R-5 (낮음, 간결성 니트) — GuardDriver AI-2·AI-4·AI-8이 drvAdoption을 두 번씩 부른다.**
단언식과 근거 문자열에 같은 호출을 반복(`Tools/GuardDriver.swift` t42절). 순수 함수라 무해하고 파일 관례(근거 출력)상 감수 가능하지만, `let` 하나로 줄일 수 있었다. AI-13의 카드·문구 단언과 절 경계 `drvAssertGlobalInvariants`는 충실하다.

단언 허점 점검(지시 5-(d)): 삼태 세 갈래(resolved AI-2·AI-4·AI-5 / unclear AI-1·AI-3·AI-6·AI-8 / notFound AI-7)가 전부 양성 대조로 담기고, AI-9~12는 재시도 쿼리 조립의 부정 케이스(벗길 접미 없음 → nil)까지 잡는다. 항상 참인 단언은 발견하지 못했다. 유일한 구멍은 R-3의 배선.

### 6. 간결성 — 0건 (R-5 외)

- 죽은 코드 없음 — 새 함수 4종 전부 adoptPlace·드라이버가 부른다.
- `satisfying` 한 번 filter 후 `rest`를 `!satisfying.contains($0)`로 한 번 더 순회(:3183) — O(n·m)이지만 n≤15(카카오 10+병합)라 무해. `Place`의 Equatable 비용 감안해도 측정 가치 없음. 세 비슷한 줄 > 조급한 추상화 원칙에 따라 그대로 둔다.
- 루프 안 반복 저장/네트워크 없음(검색 2회는 조건부 재시도이지 루프 아님).

### 게이트 로그 대조 (재실행 대신 판독)

- 드라이버: gate-driver.log 말줄 `492/492 통과` · `[실제 데이터] 대조 통과` — 판정문 전제와 일치.
- iOS 빌드: gate-ios-build.log `BUILD SUCCEEDED` 1회 · `warning:` 0건(appintents마저 없음) — 무경고 게이트 통과.
- 강제 언래핑·캐스트: diff 전수 — 신규 없음(`firstResults[0]`는 단락 평가로 보호됨).

### 계약 6종

툴 선언·프록시 무변경(1·2 유지), Store 무변경(3·5-Swift측 유지), 새 AI 클래스 없음(4 유지), UI/색 무변경(6 유지). 접미 정규화가 계약 5의 요지에 맞게 한 곳에 모였다.

## 확인했고 결함 없는 것 / 확인하지 않은 것

- 결함 없이 확인: adoptPlace·판정 4함수·병합·재시도 쿼리, resolveDestination/resolveOriginAdoption 래퍼, parkForUnclearPlaces·choose(field:place:) 연결(값 전달이라 후보 순서 변경에 인덱스 결합 없음), PlaceSearch.search 폴백, executeCreateSchedule/Activity/Recurring의 unclear 수집, 접미 규칙 전수 grep.
- 확인하지 않음(이유): **맥 빌드** — 2026-09-30 iOS 전용 결정으로 맥 빌드/검증 중단. 다만 AIAssistant.swift는 공유 컴파일 대상이므로 맥 재개 시 무경고 재확인이 필요하다. **proxy npm test** — proxy/ 무변경이라 미실행. **카카오·MapKit 실목록 모양** — 판정은 주입 목록 기반(드라이버 머리말이 실기기 몫으로 지정). **EditCard/AddEventView 등 카드 후보 표시의 런타임 외형** — 순수 논리만 판정 대상. **실기기 알림·캘린더** — 이 diff가 닿지 않는 경로.
