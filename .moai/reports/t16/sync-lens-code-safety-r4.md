# t16 sync 재심사 렌즈 — code-safety --deep 4회차 (원문 보관)

- 대상: 브랜치 `WT-place-resolution` HEAD `f441f8f`(코드 = `fa75e6e`, SPEC 0.1.9), 3차 판정 `0f8ca1b`
- 수행: 2026-09-29, sync 레인이 띄운 읽기 전용 렌즈(`hns-besir-app-code-safety-specialist`). run 레인과 다른 손이다.
- **첫 시도는 결과 없이 끝났다** — 사용량 한도(HTTP 429)로 도중에 종료돼 아무것도 돌려주지 않았다. 통과로 세지 않았고, 한도가 풀린 뒤 같은 지시로 다시 띄운 것이 이 반환문이다.
- 제약: 파일 수정·빌드·드라이버·npm 금지. 판정은 코드 읽기에 근거한다. J-1·J-3의 **실행 재현**은 sync 레인이 따로 했고 결과는 `sync-verdict.md` §R4에 있다.

---

# t16 sync 4차 재심사: code-safety --deep 렌즈 (대상 fa75e6e, HEAD f441f8f)

## 판정: **FIX-FIRST**

마커 제거는 끝까지 됐습니다. F2와 F3도 좁은 모양에서는 닫혔습니다. 그런데 (나)가 "안전한 쪽"으로 정한 경로가 **'현재 위치'를 고른 한 번짜리에서는 끝나지 않고 같은 카드로 되돌아옵니다**(J-1). 이 경로는 이번 수리가 만든 것이 아니고 8ad3abd부터 있었지만, 지금은 16a·AE-S3c·D-8 핵심 장면이 모두 이 경로를 탑니다. 그 밖에 AC-008 (10)(13)의 증거가 적힌 대로 서 있지 않고(J-2), F4와 같은 부류의 토큰 노출이 왕복 후보 카드에 남아 있습니다(J-3).

## 기준과 명령 (읽기 전용, 발췌)

- `git diff --quiet fa75e6e f441f8f -- Shared Tools proxy project.yml` → exit 0. `git status --short -- Shared Tools proxy project.yml` → 0줄. 따라서 아래 `file:line`은 **fa75e6e = 작업 트리** 기준입니다.
- `git diff --stat bf5fbd9 fa75e6e -- Shared/ Tools/GuardDriver.swift` → AIAssistant +?/−? 103줄, GuardDriver 129줄.
- 추가된 Shared 46줄에서 `Task {`·`try?`·`as!`·강제 언래핑을 grep하면 0건입니다. `await`은 2건인데 둘 다 기존 호출을 다시 적은 것입니다.
- `gate6-driver.log`(run 레인 로그): `330/330 통과`, `grep -c '✓ AE-'` = **5**.

## 발견

| id | 등급 | 위치 (fa75e6e) | 무엇이 깨지나 | 재현 | 수리 모양 |
|---|---|---|---|---|---|
| **J-1** | **BLOCKING** | `AIAssistant.swift:811`(출발지가 비면 머무름) · `:987`(값 정화가 토큰 제거) · `:1239`(확인 때 askFields가 머무는 줄만 봄) · `:1879-1881`(수단 부재 → 모델로 반환) · `:1017-1020`(fillStated는 카드가 묻는 줄에만 채움) · `:1497-1511`(create_activity 선언에 mode·buffer·notify 없음) | **머무는 한 번짜리에서 '현재 위치'를 고르고 50 m 판정이 안 된 경우**(앵커가 검색으로만 풀리거나, 앵커는 아는데 위치가 멀 때) 등록까지 갈 수 없습니다. 순서는 이렇습니다. ① 첫 확인은 "아직 만들지 않았어요 — 이동수단…"을 모델에 돌려줍니다. ② 수단·여유·알림은 create_activity에서 **카드 전용 키**라 모델이 실어 올 수 없습니다. ③ 모델의 재호출에 실린 `__current_location__`은 R1 정화가 버립니다. 그러면 출발지가 빈 호출, 즉 다시 머무는 요청이 되고 카드는 출발지 줄 하나만(캡션 없이) 다시 띄웁니다. ④ 사용자가 말한 수단 등(statedArgs)은 fillStated가 머무는 줄에만 채우므로 들어가지 않습니다. ⑤ 다시 '현재 위치'를 고르면 ①로 돌아갑니다. 모델이 토큰 대신 "현재 위치"라는 글자를 적으면 `adoptPlace`가 그 글자로 검색해 실패하거나 후보 카드를 엽니다. **어느 갈래에서도 실제 현재 위치에서 출발하는 이동은 만들어지지 않습니다.** 즐겨찾기·직접 입력·검색 후보는 일반 문자열이라 되울려도 살아남고, 수단 카드로 이어집니다. 반복은 토큰이 빠지면 출발지가 빈 **비머무는** 호출이 되어 출발지와 수단 줄을 함께 묻고 등록까지 갑니다. 그래서 한 번짜리만의 비대칭입니다. REQ-010(0.1.8)의 "…obtained from the user, **and shall then create** the activity together with the travel"이 이 선택에서는 닿지 않습니다. (나) 결정의 잔여 위험 문장("답을 이어 가면 … 약 0분 가는 이동")이 전제한 이어가기도 이 선택에서는 성립하지 않습니다 | (드라이버 모양) 즐겨찾기 `집`, 위치 (37.60, 127.10)을 심고 `drvAsk("create_activity",{place_query:"집",start/end})` → `travel_from_query`에서 `현재 위치` 선택 → `drvResolvePendingAsk`. 여기까지가 AE-S3c이고 "이동수단" 문구가 나옵니다. 이어서 `contents`의 마지막 model 턴 args(`travel_from_query="__current_location__"`)를 그대로 `drvAsk("create_activity", echo, stated:["mode_this_time":"subway","buffer_minutes":10,"notify_lead_minutes":10])`에 넣으면, 예측 결과는 `ask.fields.map(\.key) == ["travel_from_query"]`, `drvCallArgs(ask)["travel_from_query"] == nil`, `mode_this_time` 없음입니다. 다시 고르고 확인하면 같은 거절이 나옵니다. **코드를 읽어 확정했고, 실행은 하지 않았습니다.** 16a(스타벅스 홍대점)와 AD-E5b도 같은 경로입니다 | `resolvePendingAsk`에서 주입이 끝난 뒤 `askFields(tool:name,args:args).filter { $0.note == nil }`가 이번 카드에 없던 줄(수단·여유·알림)을 내면, 실행하지 말고 그 줄들로 **두 번째 카드**를 엽니다. 이때 parts에는 앱이 쥔 주입 뒤 인자를 넣어 토큰을 보존하고 모델을 거치지 않습니다. `parkForUnclearPlaces`와 같은 모양입니다. 단언: AE-S3c·AD-E5b 뒤에 "두 번째 카드 키 = [mode_this_time, buffer_minutes, notify_lead_minutes] · 보류 travel_from = 현재 위치 토큰 · 확인 → 활동 1·이동 1" |
| **J-2** | **BLOCKING (증거)** | `Tools/GuardDriver.swift` AE절(`:3055-3138`), `acceptance.md:184-231` | **AC-008 (10)(13)이 적힌 대로 서 있지 않습니다.** (13)은 21개 id 각각에 `AE-<id> ` 단언을 두고, 합계 `✓ AE-` ≥ **26**을 요구합니다. (10)은 `AE-C-1 ` ×2와 `AE-C-1r ` ×2를 요구합니다. 실제 단언은 5개이고 이름도 다른 모양입니다(AE-S3c·S3e·S3r·F2a·F2b). run은 §E.2 M9 (c)의 대응표로 이를 대신했는데, SPEC 개정은 없었습니다(0.1.9는 AC-011 (5)(d)만 바꿨습니다). 결과적으로 **반복의 (나) 갈래(앵커 좌표를 모름, 또는 50 m 밖에서 현재 위치를 고름)는 드라이버 단언이 0건입니다**. R3-b는 대응표에서 AE-S3c(한 번짜리, 즐겨찾기 앵커)에 붙어 있습니다. (10)의 특성화 둘째 단계도 없습니다. AE-F2a는 보류 인자만 보고, R3-a가 기대하는 카드 줄 키 `[origin_query, weeks]`는 단언하지 않습니다 | `grep -c '✓ AE-' gate6-driver.log` → 5 · `grep -c '✓ AE-S-1a '`·`'✓ AE-C-1 '`·`'✓ AE-C-1r '`·`'✓ AE-R3-b '` … → 전부 0 · `grep -n 'drvPickLabel("origin_query", "현재 위치")' GuardDriver.swift` → `:3108` 한 건(AE-S3r, 즐겨찾기 앵커) | 둘 중 하나입니다. (13)의 이름·수대로 단언을 더하되 반복 C-1r·R3-b를 포함하거나, `manager-spec`으로 (10)(13)을 대응표 방식으로 개정합니다. 어느 쪽으로 할지는 리드가 정합니다 |
| **J-3** | **BLOCKING** | `AIAssistant.swift:612-619`(왕복 가는 편 줄 캡션) ← `:924`(후보 카드가 `askFields(input)`로 줄을 만듦) | **왕복 활동의 후보 카드에 `'__current_location__'에서 출발하는지 한 번 더 골라 주세요…`가 보입니다**. F4·D1과 같은 부류이고 경로만 다릅니다. 왕복 호출에서는 가는 편 출발지 줄이 늘 다시 뜨고, 캡션이 채워진 값을 그대로 적습니다(`roundTripOriginNote(v)`). 여기에 토큰을 거르는 장치가 없습니다. 캡션은 t16에서 들어왔습니다(aa7b792에는 0건, 5fb6634부터 있음). R3-d는 오는 편이 없는 모양만 봐서 이 갈래를 놓쳤습니다 | `create_activity(place_query: 검색 1위 이름이 확실히 맞지 않는 질의, start/end, travel_from_query:"집", return_to_query:"집")` → 카드의 가는 편 출발지에서 `현재 위치` 선택(위치 있음), 수단·여유·알림 선택 → 확인 → 실행부에서 그 줄은 note가 있어 부재로 세지 않고 → 장소가 unclear → `parkForUnclearPlaces` → 캡션에 토큰이 보입니다. 다중 호출 카드에서 머무는 줄의 '이동 없음'이 옆 왕복 호출에 실리면 `'__no_travel__'` 변형도 나옵니다 | 토큰을 표시 문구로 바꾸는 매퍼 **하나**(`:1944`의 '현재 위치' 표시와 공유, 계약 5)를 캡션 두 곳과 실패 문구가 함께 씁니다. 단언은 R3-d에 오는 편을 넣은 변형으로 둡니다 |
| J-4 | OPTIONAL | `AIAssistant.swift:1926-1933`, 반복 실행부 `isSamePlace` 갈래 | F1의 **모양은 남아 있습니다**. 실행부에서 머무는 호출인데 두 장소가 풀린 뒤 50 m 밖이면, 부재를 다시 따지지 않고 `.transit`/0/0으로 이동을 만듭니다. 지금 이 갈래에 닿는 길은 같은 문자열이 서로 다른 장소로 풀리는 경우뿐입니다. 예를 들어 `confirmedPlaces`의 대소문자 구분 키와 대소문자를 가리지 않는 머무름 판정이 어긋나거나, 같은 질의 두 번의 검색 결과가 다를 때입니다 | 직접 입력한 출발지가 `place_query`와 대소문자만 다른 경우 | 두 실행부가 공유하는 헬퍼 하나로 처리합니다. 머무는 호출인데 50 m 밖이면 `missingAskedArguments` 문구를 돌려줍니다 |
| J-5 | OPTIONAL (증거) | `GuardDriver.swift:3022-3026`, `:30-32` | AD-E6은 `(실패 문구 ∨ legs≥1)`이라서 위치가 잡히면 F3 갈래를 거치지 않고도 ✓입니다. `drvCheck`는 통과할 때 detail을 찍지 않으므로, AC-008 (13)이 요구한 "어느 갈래였는지"가 로그에 남지 않습니다. gate6 로그로는 F3을 재지 않았을 수 있습니다 | `grep -A1 '✓ AD-E6' gate6-driver.log` → 갈래 정보 없음 | 통과 때도 갈래를 찍거나, 위치 없음을 강제하는 drv 훅을 둡니다 |
| J-6 | OPTIONAL (G-6 잔여) | `AIAssistant.swift:1260` | "세 대화"가 아직 남아 있습니다. progress M9 ⑦은 고쳤다고 적고 있어서 기록이 사실과 다릅니다 | `grep -c '세 대화'` → 1 | 고치고, 기록도 바로잡습니다 |
| J-7 | OPTIONAL (주석 진실성) | `AIAssistant.swift:1920-1925` | "모델이 같은 값·같은 문자열로 직접 보낸 호출이 resolve 뒤에 좌표로 판정받는 자리"라고 적혀 있지만, 앱 안에서 모델이 보낸 같은 값 호출은 늘 카드(`:593-600`)를 먼저 거칩니다. 실제로 이 갈래에 닿는 것은 **사용자가 직접 입력한 값이 `place_query`와 같은 경우**(와 드라이버 직접 호출)입니다. `stayedByDistance`는 이 경로 때문에 계속 필요합니다(거짓 "찾지 못해"를 막음) | — | 문장 수정 |
| J-8 | OPTIONAL | `AIAssistant.swift:2126` | 반복에서 현재 위치를 못 잡으면 "즐겨찾기에 장소를 추가해 주세요"라는 일반 문구가 나옵니다. 조용하지 않고 토큰도 없지만, '현재 위치'가 실패했다는 사실은 적지 않습니다(`:1719`의 create_schedule 전용 문구와 다름) | — | 전용 문구를 맞춥니다 |
| J-9 | OPTIONAL (이월) | `AIAssistant.swift:1961-1963` | F-opt1/G-5 그대로입니다. 장소 검색에 실패하면 "활동 장소가 필요해요"가 나가고 `unresolved`는 버려집니다. 수단 카드 뒤에 닿습니다 | — | 풀지 못한 이름을 적습니다 |
| J-10 | OBSERVATION | `AIAssistant.swift:972-981` | E1 교체는 무관한 통근 호출에 되울린 `__no_travel__`도 머무는 요청으로 만듭니다. 그러면 끝 시각을 먼저 묻고 출발지 줄 선택을 강제합니다. **선택 없이 확정되지는 않습니다** | — | — |

## F1–F5, G-6/G-8

| 항목 | 상태 | 확인한 변형 |
|---|---|---|
| F1 | **CLOSED**(마커 경로) | 한 번짜리·반복 × 현재 위치·즐겨찾기·직접 입력·검색 후보, 앵커를 로컬에서 못 푸는 경우 모두 실행부 부재 문구에서 멈추고 기본값으로 등록하지 않습니다(코드 읽기). 같은 모양은 J-4 경로로만 남습니다 |
| F2 | **CLOSED** | 선언 키만 실은 에코(AE-F2a, bf5fbd9에서는 실패), weeks가 섞인 에코(AE-F2b = AD-E1), 공백이 붙은 토큰(`trimmedArg`), 목적지 없음(교체 없이 토큰 제거), 다른 도구·키의 토큰(제거). 최상위 값 가운데 토큰이 원본 part로 새는 조합은 0건입니다. 중첩 값은 정화하지 않지만 장소 값이 아닙니다 |
| F3 | **CLOSED**(실행부) | create_activity 가는 편 → "'현재 위치'" 표시 문구 · create_schedule → 전용 문구(`:1719`) · 반복 → 일반 문구(J-8) · 오는 편·장소 → '현재 위치' 칩이 없어 닿지 않음 · 조회·갱신 도구 → 카드가 없어 닿지 않음. 드라이버 증거는 비결정적입니다(J-5) |
| F4 | **PARTIAL** | 마커 경로는 소멸했습니다(`stayingOriginNote`의 modelValue는 장소 문자열이거나 없음). 왕복 캡션 경로는 남아 있습니다(J-3) |
| F5 | **PARTIAL** | AD-E5 이름·주석을 교정했습니다. AD-E5b는 bf5fbd9에서 실패하므로 변별력이 있습니다(C-1 "이동까지…"에는 "이동수단"이 없음). 반복 쪽 증거는 0건입니다(J-2) |
| G-6 | **PARTIAL** | "머묿" 0건, 드라이버 "weeks 줄만" 0건, 마커 주석 삭제, 정화·헬퍼 주석은 사실과 맞음. `:1260` "세 대화"가 남았습니다(J-6) |
| G-8 | **CLOSED** | `args`는 `preInjection`에 비지 않은 값만 덮어쓰므로 폴백은 도달 불가였습니다. 제거가 맞고 주석도 사실입니다 |

**마커 제거 (심사 항목 1):** `grep -n '마커\|deferred\|needsDeferredCheck\|stayingAskMarker\|__staying_pick__'`(두 파일 전체) → `AIAssistant.swift:1253`(0.1.8 경위 주석, 사실), `:1382-1383`(insufficient_quota 마커, 무관), `GuardDriver.swift:2954`(경위 주석). 읽기·쓰기·반쯤 걷힌 갈래는 **0건**입니다.

**드라이버 단언 변경 (bf5fbd9 → fa75e6e):**
- 삭제 0건.
- 이름만 바뀐 것: AD-E1, AD-E5(술어는 그대로).
- 강화: AD-E6(기존 `!contains("__")`에 조건을 ∧로 더함. 단 J-5).
- 추가 6건: AD-E5b, AE-S3c/S3e/S3r/F2a/F2b.
- bf5fbd9에서 실패하는 것(코드 읽기): AE-F2a, AD-E5b. AD-E6은 위치 응답에 따라 갈립니다.
- 이관이라 원래 통과하는 것: AE-S3c/S3e/S3r/F2b.
- 모두 실제 확인 경로(`drvAsk` = 정화 → fillStated → pendingAsk, `drvResolvePendingAsk`)를 탑니다. AD-E6만 `drvExecuteTool`로 직접 부릅니다. 헛통과는 J-5 한 건입니다.

## 검사했고 0건인 부류 (표집 범위)

- **H1:** 추가분 전체, `resolvePendingAsk` 전체, 두 실행부. `idx`는 await 전에만 쓰이고, `args`·`parts[i]`는 지역 사본입니다. 새 인덱스 캡처는 없습니다.
- **H2:** 추가 46줄에서 `Task {`/`try?` 0건. F3 경로도 코드로 읽었습니다.
- **H3:** 새로 무한히 자라는 상태는 없습니다.
- **강제 언래핑·캐스트:** 추가분 0건.
- **계약 5:** 50 m 계산은 여전히 `isSamePlace` 하나에 있습니다. 토큰 표시 문구는 두 곳(`:1944`, `:1719`)에 있고, J-3 수리 때 하나로 모을 것을 권합니다.
- **죽은 코드:** `stayedByDistance`는 J-7 경로로 도달 가능하고, `locallyResolvedPlace`는 헬퍼와 `adoptPlace`가 씁니다. 남은 죽은 코드는 0건입니다.
- **범위:** 코드 파일 2개, plan 밖 리팩터는 없습니다.

## 검사하지 못한 것 (이유)

- **빌드·드라이버·npm·무경고 게이트:** 임무 제약입니다. gate6 로그는 run 레인 산출물이라 이 렌즈가 독립 실측한 것이 아닙니다.
- **J-1의 실행 관측:** 코드 읽기로 확정했고 실행은 하지 않았습니다. 모델이 재호출에서 토큰을 되울리는지, 빼는지, "현재 위치"라는 글자를 적는지는 관측하지 않았습니다. 어느 갈래든 결론은 같습니다.
- **J-3 발동 빈도:** MapKit 검색이 unclear로 판정하는 빈도는 모릅니다.
- **렌더링:** EditCardView가 `note`를 캡션으로 그리는지는 관례로 가정했습니다.
- **범위 밖:** proxy가 히스토리를 어떻게 렌더링하는지, 문서 인용 드리프트.
