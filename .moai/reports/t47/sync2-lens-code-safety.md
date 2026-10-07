# t47 sync 2차 — code-safety 렌즈 (수리 7dbcd9d 판정)

- 대상: `git diff 83ac07f 7dbcd9d -- Shared/AIAssistant.swift Shared/AIChatView.swift` (좌표는 HEAD 7dbcd9d 기준)
- 성격: 읽기 전용이다. 지시에 따라 드라이버와 xcodebuild는 돌리지 않았다. 아래 "OBSERVED"는 이번 회차에 실행한 git·grep 출력과 HEAD 본문 정독으로 직접 확인한 사실을 뜻하며, 실행 재현은 아니다. 결함 주장은 리드가 실행으로 재현하기 전까지 모두 가설이다.
- 실행한 명령: `git diff 83ac07f 7dbcd9d -- Shared/AIAssistant.swift Shared/AIChatView.swift`, `git diff --stat 83ac07f 7dbcd9d`, `grep -n`(Shared/·Tools/GuardDriver.swift·project.yml·proxy/src/index.js). 정독 범위: AIAssistant.swift 280-668·880-1032·1213-1215·1250-1450, EditCard.swift 228-247·685-709, EditCardView.swift 1-30, GuardDriver.swift 88-207·1972-1991·2200-2239, project.yml 19-98.

## 판정 요약

BLOCKING 0건, WARN 3건, NOTE 7건이다. 운영자가 확정한 사양(Q16)의 세 동작은 단일 호출 카드에서 코드상 사양대로 구현됐다. 세 동작은 도구별 확인 버튼, 열린 카드의 도구를 따르는 버린 카드 말풍선, 같은 기준을 쓰는 열린 카드 가드이고, 후보 카드는 전부 단일 호출 카드다. 그러나 여러 호출을 담은 실행 전 카드에서는 이번 수리가 맞던 버튼을 틀리게 만들 수 있다(W-1). 또 수리한 세 동작을 단언하는 드라이버 검사가 없다(W-3).

## 발견 표

| id | 등급 | 근거 | 위치 | 결함 | 실패 시나리오 | 수리 |
|---|---|---|---|---|---|---|
| W-1 | WARN | HYPOTHESIS(정독. 실행 재현 전이며, 모델이 혼합 호출을 보내는지는 관측된 적 없음) | `Shared/AIAssistant.swift:973-975`(toolName). 소비처는 `:993`·`:1447`·`Shared/AIChatView.swift:114` | `toolName(of:)`는 카드 parts의 **첫** functionCall 이름을 쓴다. 실행 전 카드(`pendingAsk(for:)` `:892-913`)는 턴의 호출을 모두 담지만, 줄을 만드는 도구는 생성 도구 셋뿐이다(`askFields` `:502-637`, 나머지 도구는 `default: break` `:636`). 그래서 첫 호출이 조회·수정 도구이면 생성 카드인데도 버튼이 "조회하기"나 "고치기"로 나온다. | 한 턴에 `[check_travel_time{origin_query,destination_query}, create_schedule{destination_query만}]`이 오면 `askFields(check_travel_time)`는 빈 배열이고 `askFields(create_schedule)`는 줄을 여러 개 만든다. 카드는 한 장이 되고 parts 순서는 그대로 남는다. 이때 버튼은 "조회하기"가 되고, 다른 발화로 카드를 접으면 "물어본 값을 받지 못해서 조회하지 않았어요."가 남는다. 실제로 버려진 일은 등록이다. J-1 두 번째 카드(`:1385-1388`)도 같은 parts를 그대로 쓰므로 결과가 같다. 수리 전에는 이 카드에 기본값 "등록하기"가 떴으므로, **맞던 표시를 이번 수리가 틀리게 만드는 경로**다. 후보 카드(`:1021`)는 호출이 정확히 하나여서 해당하지 않는다. 프록시에는 병렬 호출을 제한하는 설정이 없다(`grep -n "parallel" proxy/src/index.js` 출력 없음). API 쪽에서 막혀 있지는 않지만, 모델이 실제로 이런 턴을 내는지는 관측된 적이 없다. | 생성 도구를 먼저 찾고, 없을 때만 첫 호출을 쓴다: `let names = card.parts.compactMap { ($0["functionCall"] as? [String: Any])?["name"] as? String }; return names.first(where: creationTools.contains) ?? names.first ?? ""`. 생성 도구 세 이름의 배열 리터럴이 이미 `:907`과 `:1382` 두 곳에 있다. `static let creationTools`로 한 곳에 모으면 세 번째 사본이 생기지 않는다(계약 5). |
| W-2 | WARN | OBSERVED(grep) | `Shared/EditCardView.swift:14-16`, `Shared/EditCard.swift:690-693`, `Shared/AIChatView.swift:113` | 머리글 리터럴 "몇 가지만 알려주세요"가 두 곳에 있고, `EditCardView`의 chrome 기본값은 이제 아무도 쓰지 않는다. 두 주석도 사실과 맞지 않게 됐다. `:14-15`는 "기본값이 있어야 유일한 기존 호출부(채팅)가 무변경으로 컴파일된다"고 하고, `EditCard.swift:692-693`은 "AI 카드의 기본 문구는 뷰 쪽 기본값에 둔다"고 한다. | `grep -rn -A2 "EditCardView(" Shared/` 결과, 호출부 넷(AddEventView:68, ActivityDetailView:68, AddActivityView:42, AIChatView:112)이 모두 chrome을 명시한다. 다음 작업자가 주석을 믿고 기본값의 머리글이나 버튼을 고쳐도 화면은 바뀌지 않는다. 운영자 결정 Q16은 이 기본값을 "수동 편집 화면 무관 유지"라는 이유로 동결했다. 하지만 수동 편집 화면 셋은 원래부터 `EditCardChrome(header: nil, confirmTitle: nil)`을 넘기므로 이 기본값을 쓰는 화면은 없다. 결정의 전제가 성립하지 않는다. | 병합을 막을 사안은 아니다. 운영자 결정이 동결한 자리이므로 리드가 운영자에게 올린다. 선택지는 둘이다. (가) 기본값을 지워 chrome을 필수 인자로 만들고 AI 문구는 AIChatView 한 곳에만 둔다. (나) 기본값은 남기되 두 주석을 사실대로 고친다. 어느 쪽이든 리터럴은 한 곳에만 둔다. |
| W-3 | WARN | OBSERVED(grep) | `Tools/GuardDriver.swift`(7dbcd9d에서 바뀌지 않음. `git diff --stat`에 Tools/가 없다) | 이번 수리의 세 동작을 단언하는 드라이버 검사가 없다. 1차 W-1의 수리안에도 "문구 단언을 드라이버에 하나 더한다"가 들어 있었다. | `grep -n "drvCancelPendingAsk\|pendingConfirmTitle\|toolName(of\|진행하지\|그 카드의 일만\|물어본 값을 받지 못해서\|조회하기\|고치기"` 결과는 이렇다. `drvCancelPendingAsk`는 정의(:121)와 정리용 호출 11곳(:846~:2979)뿐이고, 호출 뒤 말풍선 문구를 보는 단언은 없다. `pendingConfirmTitle`, `toolName(of`, `그 카드의 일만`, `물어본 값을 받지 못해서`는 하나도 나오지 않는다. 가드 문구를 단언하는 검사는 AB-H02(:2217-2220)와 AA-6(:1987-1988) 두 개인데, 둘 다 등록 카드가 열린 상태에서 등록 호출이 들어오는 경우라 수리 전후 출력이 같다. 따라서 드라이버가 초록이어도 Q16 수리가 동작한다는 증거가 되지 않는다. | 결정적인 단언 세 개를 더한다. 아래 재현 레시피 R-2, R-3, R-4가 그대로 단언이 된다. |
| N-1 | NOTE | OBSERVED(정독) | `Shared/AIAssistant.swift:974`·`:957` | `toolName`이 ""를 돌려주면 `default` 갈래로 가서 "등록하기"/"등록하지"가 된다. | AI 카드에서 ""가 나오려면 첫 functionCall에 문자열 name이 없어야 한다. `sanitizeModelArgs`(`:1051-1052`)는 그런 part를 손대지 않고 통과시킨다. 이 호출은 `askFields(tool: "")`가 줄을 만들지 않으므로, 카드가 섰다면 같은 턴에 다른 생성 호출이 있다는 뜻이다. 그래서 결과 문구가 우연히 맞는다. 수동 편집 카드는 parts가 비어 있지만 toolName을 거치는 경로가 없다. 세 화면 모두 chrome에 nil을 넘기고, cancelPendingAsk는 bubbles만 본다. | 따로 할 일은 없다. W-1을 수리할 때 같은 함수 안에서 함께 닫힌다. |
| N-2 | NOTE | OBSERVED(정독) | `Shared/AIAssistant.swift:992-998` | 가드 문구의 첫 마디는 이제 **열린 카드**의 동사다. 그런데 이 문자열은 **들어온 호출**의 도구 결과로 모델에게 전달된다. | 등록 카드가 열린 상태에서 같은 턴의 `check_travel_time`이 보류되면, 그 조회 호출의 결과로 "등록하지 않았어요 — 이미 같은 질문의 카드가 열려 있어요… 그 등록만 진행돼요. 이 호출은 카드가 끝난 뒤에… 다시 호출해."가 나간다. 운영자 사양("같은 기준(열린 카드의 도구)")을 그대로 따른 결과다. 도구가 다를 때 "같은 질문"이 틀린 말이 되는 문제는 1차 N-3에서 넘어온 것이다. 모델만 읽는 문구여서 사용자에게는 보이지 않는다. | 사양대로이므로 고치지 않고 기록만 남긴다. |
| N-3 | NOTE | OBSERVED(정독) | `Shared/AIAssistant.swift:994` vs `:957` | `verb == "등록하지"` 비교가 스위치가 돌려주는 리터럴에 묶여 있다. 이 비교는 수리 전부터 있었다(diff에 문맥 줄로 나온다). | 동사 낱말을 바꾸면 비교가 조용히 거짓이 되고 일반 문장 "…그 카드의 일만"으로 떨어진다. AB-H02는 `contains("등록하지 않았")`만 보므로 이 변화를 잡지 못한다. | 문자열이 아니라 도구 분류로 가른다. 예를 들어 `pendingActionWords`가 `isRegistration` 같은 판별값도 함께 돌려주게 한다. 이번 수리가 만든 문제가 아니므로 후속 작업으로 넘긴다. |
| N-4 | NOTE | OBSERVED(grep) | `Shared/AIAssistant.swift:962-969` | `pendingActionVerb`는 이제 `pendingActionWords(for:).verb`를 그대로 넘겨주기만 한다. | 호출부가 셋(`:993`·`:1030`·`:1447`)이라 죽은 함수는 아니다. `pendingConfirmTitle`의 호출부는 AIChatView:114 하나다. 옛 리터럴 "그 등록은 진행하지 않았어요"는 Shared/와 Tools/에서 한 건도 나오지 않는다. 낱말의 원천이 스위치 하나(`:953-958`)여서 계약 5를 지킨다. | 없음. |
| N-5 | NOTE | OBSERVED(정독) | `Shared/AIChatView.swift:112-114` | 본문을 평가할 때마다 카드 말풍선 하나당 `toolName`과 `pendingConfirmTitle`이 한 번씩 호출된다. | 비용은 parts 몇 개를 도는 compactMap과 스위치 하나여서 무시해도 된다. `static`을 내부 공개로 넓힌 것도 상태 없는 순수 함수 둘이라, 바뀔 수 있는 상태가 새로 드러나지 않는다. 다만 뷰가 AI 내부 어휘인 도구 이름에 기대게 된다. 이 결합을 줄이려면 버튼 문구를 카드 쪽에서 구해 넘기면 되지만, 지금 고칠 일은 아니다. | 없음. |
| N-6 | NOTE | OBSERVED(project.yml) | `project.yml:89-94` | besir-macOS 타깃의 sources에 Shared가 들어 있어, AIChatView 변경도 맥 타깃에서 함께 컴파일된다. | 새 코드는 플랫폼 전용 API를 쓰지 않는다. 다만 2026-09-30 iOS 전용 지침에 따라 맥 빌드를 돌리지 않았으므로, 맥에서 컴파일된다는 확인은 없다. | 없음(기록만 남김). |
| N-7 | NOTE | OBSERVED(diff) | diff 전체 | 사양 밖 변경은 없다. | 코드 변경은 Q16의 세 동작과 `toolName`·`pendingActionWords`·`pendingConfirmTitle` 신설이 전부다. 주석은 이력 주석 두 곳(`:882-884`·`:1027-1029`)이 바뀌었고, 같은 취지로 `cancelPendingAsk` 문서 주석의 낱말 하나가 "등록되지"에서 "진행되지"로 바뀌었다(`:1440`). `git diff --stat` 기준으로 Shared/ 변경은 AIAssistant.swift 57줄, AIChatView.swift 6줄이고 나머지는 문서와 로그다. 문서 쪽은 이 렌즈의 범위 밖이다. | 없음. |

## 일곱 질문에 대한 답

1. **toolName이 첫 호출을 쓰는 문제**: CODE-READ HYPOTHESIS(W-1). 후보 카드는 호출이 하나뿐이라 안전하다(`:1021`). 실행 전 카드와 J-1 카드는 호출을 여러 개 담을 수 있고, 줄을 만드는 도구는 생성 도구뿐이다. 그래서 조회·수정 호출이 앞에 오면 버튼, 말풍선, 가드 동사가 모두 사실과 달라진다. ""는 첫 호출에 이름이 없을 때만 나오고, 그때 문구는 "등록하기"다(N-1).
2. **가드의 `first(where:)`**: OBSERVED(정독). `if let openCard` 블록 안의 두 갈래는 각각 `:995`와 `:997`에서 return한다. 열린 카드가 없으면 `first(where:)`가 nil이 되어 `:999`로 넘어간다. `:999-1031`은 diff에서 주석(`:1027-1029`)만 바뀌었으므로 동작은 수리 전과 바이트 단위로 같다. 열린 카드가 여러 장이면 가장 오래된 카드가 기준이 된다. 하지만 두 장이 동시에 열리는 경로는 정독한 범위에서 찾지 못했다. submit이 먼저 열린 카드를 모두 접고(`:297`), 확인 경로는 카드를 요약으로 바꾼 뒤에 실행하며(`:1290`), 가드가 둘째 카드를 막는다(`:992`).
3. **cancelPendingAsk 루프**: OBSERVED(정독). `:1441-1449`에는 await가 없다. `bubbles.indices`는 루프가 시작될 때 정해지고, 본문은 같은 자리의 값만 바꿔 써서 배열 길이가 변하지 않는다. 그래서 인덱스가 어긋나지 않는다. `cancelPlaceSearches`(`:1213-1215`)는 `placeDebounce.cancelAll()`만 부르고 bubbles는 건드리지 않는다. 카드가 여러 장이면 카드마다 자기 도구의 동사를 쓴다. 완성되는 문장 "물어본 값을 받지 못해서 등록하지/고치지/조회하지 않았어요."는 셋 다 문법상 맞다.
4. **호출부와 죽은 감싸개**: OBSERVED(grep). N-4와 N-3을 보라. `pendingActionVerb`는 호출부가 셋이라 살아 있다. 옛 리터럴은 한 건도 남지 않았다. `verb == "등록하지"`는 수리 전부터 있던 문자열 결합이다.
5. **머리글 중복과 비용**: OBSERVED(grep). W-2(쓰이지 않는 기본값, 리터럴 두 벌, 사실과 다른 주석 둘)와 N-5(비용은 무시할 만하고 노출 범위도 문제없음)를 보라. `EditCardChrome`에는 AI 문구를 둘 단일 출처가 없다. 타입 주석이 그 자리를 일부러 비워 두었기 때문이다(`EditCard.swift:690-693`).
6. **macOS**: 기록만 남긴다(N-6).
7. **목적 밖 변경**: 없다(N-7).

## 수리를 검증하는 테스트

7dbcd9d에서 `Tools/GuardDriver.swift`는 바뀌지 않았다. 버튼 문구, 버린 카드 말풍선, 도구가 다른 경우의 가드 동사를 단언하는 검사는 하나도 없다(W-3의 grep 결과). 가드의 등록 갈래는 AB-H02와 AA-6이 검사하지만, 이 갈래의 출력은 수리 전과 같다.

## 재현 레시피 (리드 실행용, private 멤버에 접근할 수 있는 드라이버 extension 안에서)

- **R-1 (W-1, 실제 카드 생성 경로)**: 먼저 임시 도우미 `func drvAskParts(_ parts: [[String: Any]]) -> PendingAsk? { pendingAsk(for: fillStated(sanitizeModelArgs(parts))) }`를 추가한다. 그다음 아래를 실행한다.
  `let c = mx.drvAskParts([["functionCall": ["name": "check_travel_time", "args": ["origin_query": "집", "destination_query": "회사"]]], ["functionCall": ["name": "create_schedule", "args": ["destination_query": "회사"]]]])`
  결함이 있다면 `c != nil`, `AIAssistant.toolName(of: c!) == "check_travel_time"`, `AIAssistant.pendingConfirmTitle(for: AIAssistant.toolName(of: c!)) == "조회하기"`가 모두 참이다. 이어서 `mx.drvOpen(c!); mx.drvCancelPendingAsk()`를 실행하면 `mx.bubbles.last?.text == "물어본 값을 받지 못해서 조회하지 않았어요."`가 된다. 수리한 뒤에는 "등록하기"와 "등록하지"가 나와야 한다.
- **R-2 (W-3, 버린 조회 카드의 말풍선)**: `_ = q.drvPark("check_travel_time", ["origin_query": "스타벅스 강남점", "destination_query": "홍대입구역"], [(key: "origin_query", query: "스타벅스 강남점", candidates: abGangnam)]); q.drvCancelPendingAsk()`를 실행하면 `q.bubbles.last?.text == "물어본 값을 받지 못해서 조회하지 않았어요."`여야 한다. 수정 카드는 `drvPark("update_schedule", …)`로 같은 순서를 밟고 "고치지 않았어요."를 기대한다.
- **R-3 (W-3, 열린 카드 기준 가드)**: `_ = g.drvPark("update_schedule", <AI-18 입력>, <후보>)` 다음에 `let r = g.drvPark("create_schedule", <AB-H02 입력>, <후보>)`를 실행하면 `r.hasPrefix("고치지 않았어요 — ")`와 `r.contains("그 카드의 일만")`가 참이고 카드는 1장이어야 한다.
- **R-4 (W-3, 버튼 문구)**: R-2에서 열린 카드에 대해 `AIAssistant.pendingConfirmTitle(for: AIAssistant.toolName(of: q.drvLiveAsk()!)) == "조회하기"`여야 한다. 같은 방식으로 update 카드는 "고치기", create 카드는 "등록하기"를 확인한다.

## 검사했고 발견이 없던 부류

- H1(await 전후 인덱스 무효화): 바뀐 코드(`:992-998`, `:1441-1449`, AIChatView:112-114)에는 await가 없다. `cancelPendingAsk`의 인덱스는 하나의 동기 구간 안에서만 쓰인다.
- H2(조용히 삼켜진 실패): 새로 생긴 `Task {}`나 `try?`가 없다.
- H3(외부 한도): 새로 쌓이는 상태가 없다.
- 강제 언래핑·강제 캐스트: 새로 생긴 것이 없다. `toolName`은 `as?`와 `?? ""`만 쓴다.
- 경계 조건: parts가 빈 카드나 이름 없는 호출은 ""가 되어 기본 갈래로 간다(N-1). 열린 카드가 0장일 때 가드는 수리 전과 같다(질문 2).
- 루프 안에서 반복되는 저장·네트워크 호출: 없다.
- 범위: 사양 밖 변경이 없다(N-7).

## 검사했고 발견이 있던 부류

- H4·계약 5(같은 계산을 두 곳에 두지 않기): 낱말의 원천은 스위치 하나로 모였으므로 이 부분은 통과다. 다만 머리글 리터럴이 두 벌이고 쓰이지 않는 기본값이 남았다(W-2). W-1을 수리할 때는 생성 도구 리터럴의 세 번째 사본이 생기지 않도록 주의해야 한다.

## 검사하지 않은 것

- iOS 빌드와 무경고 게이트: 지시에 따라 xcodebuild를 돌리지 않았다. AIChatView가 컴파일된다고도 주장하지 않는다.
- 가드 드라이버 실행: 지시에 따라 돌리지 않았다. R-1~R-4는 레시피일 뿐 실행 결과가 없다.
- 모델이 실제로 조회·수정 호출과 생성 호출을 한 턴에 섞어 보내는지: 관측 자료가 없어 W-1의 도달 가능성은 확정되지 않았다.
- 시뮬레이터·실기기에서 버튼이 실제로 어떻게 보이는지(줄바꿈, 폭): 확인하지 않았다.
- macOS 빌드: 2026-09-30 지침에 따라 하지 않았다.
- diff에 들어 있는 문서 파일(CHECKLIST.md, plan.md, progress.md, spec.md, 각종 보고서): 이 렌즈의 범위 밖이다.

## 잔여 위험

- W-1은 정독으로 세운 가설이다. R-1이 결함을 재현하더라도, 운영자가 실제로 이 상황을 마주칠지는 모델이 병렬 호출을 얼마나 내는지에 달려 있다.
- W-3이 그대로 남으면, 이후 누가 `pendingActionWords`나 `toolName`을 바꿔도 드라이버가 잡아내지 못한다.
