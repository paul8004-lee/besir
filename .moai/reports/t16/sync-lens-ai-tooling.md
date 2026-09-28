# t16 sync 독립 렌즈 — ai-tooling(선언·인자 계약) (원문 보관)

- 대상: 브랜치 `WT-place-resolution` HEAD `5fb6634`, base `aa7b792`
- 수행: 2026-09-28, sync 레인이 띄운 읽기 전용 렌즈(`hns-besir-app-ai-tooling-specialist`). run 레인과 다른 손이다.
- 제약: 파일 수정·빌드·드라이버·npm·라이브 모델 요청 금지. 판정은 코드와 산출물 읽기에 근거한다.
- 이 파일은 렌즈 반환문을 고치지 않고 옮긴 것이다. A-2(= code-safety S-3)의 **실행 재현**은 sync 레인이 따로 했고 결과는 `sync-verdict.md` §2에 있다.

---

# t16 sync — ai-tooling 렌즈(선언·인자 계약) 판정

**판정: FAIL.** 차단 1건(A-2), 선택 2건(A-1, A-3), 관찰 5건입니다.

- 선언 계약(REQ-013), 프록시 무변경, 방어 함수 본문, D-5 히스토리 모양, 토큰 측정법은 모두 통과했습니다.
- 차단 사유는 A-2입니다. REQ-010과 `plan.md`:87에는 "사용자가 목적지·활동 장소와 50 m 안의 곳을 고르면 활동만 만든다"는 절이 있습니다. 이 절이 사용자가 고른 값이 장소 이름과 글자까지 같은 경우에만 동작합니다.

모든 줄 번호는 5fb6634 트리에서 `sed -n`/Read로 직접 출력해 확인했습니다. 실행 제약상 드라이버, 빌드, npm, 라이브 요청은 돌리지 않았고, 모든 판정은 코드와 산출물을 읽은 근거입니다.

## 항목별 판정

**1. 선언 계약(REQ-013) — 통과**
- 비교 범위는 `toolsJSON()` 전체입니다. base aa7b792 `:1084-1247`과 head `:1364-1527`을 비교했고, 두 쪽 모두 164줄입니다.
- 다른 줄은 58번째 한 줄뿐입니다. head `:1421`, `create_recurring_schedule`의 `origin_query` description입니다.
- 이 줄은 후보 e1a40a6에서 들어왔습니다. e1a40a6과 head의 toolsJSON 영역은 동일합니다(`diff` → IDENTICAL).
- 함수 선언, 매개변수 키, required 목록, enum, 타입 변화는 0건입니다(범위: toolsJSON 영역 전체).
- head 영역의 소문자 타입도 0건입니다. 타입 분포는 `ARRAY 1 · BOOLEAN 8 · INTEGER 6 · OBJECT 9 · STRING 44`입니다.
- 측정 산출물의 도구 JSON도 base와 final을 구조적으로 비교했고, 차이는 `VAL [2]/parameters/properties/origin_query/description` 1건뿐입니다.
- 시스템 프롬프트에는 `:1341` 한 줄이 추가됐습니다. 선언은 아니지만 토큰 비용에는 들어갑니다.
- 새 class/struct/actor/protocol은 0건입니다(범위: `Shared/`·`Tools/` diff의 `+` 줄).

**2. 내부 토큰 추적 — `noTravelToken`("__no_travel__", 칩 이름 "이동 없음")**
- 쓰는 곳은 칩 값 하나뿐입니다(`:815`). `choose` → `resolvePendingAsk`(`:1195`/`:1199`)를 거쳐 args에 주입됩니다.
- 주입된 args는 `:1222`에서 **model 턴으로 히스토리에 그대로 들어갑니다.**
- 읽는 곳:
  - `:542`·`:589` — 줄을 다시 띄우지 않음
  - `:794`·`:806` — 머무는 요청 신호
  - `:879` — 맥락 줄에서 숨김
  - `:1801`·`:1834` — 활동 쪽 해석 제외
  - `:1995`/`:2002`/`:2028` — 머무는 반복 실행
- Store에는 토큰이 들어가지 않습니다(`makeStayingRecurrence`는 목적지 Place와 제목만 씀).
- 모델로 되돌아오는 경로(F-4)는 열려 있습니다. 판정은 **선택(A-1)**입니다. 아래에 적습니다.

**3. 방어 가드 — 약화 없음, 단 새 50 m 사용처가 거의 죽어 있음(A-2)**
- base와 head의 함수 본문 md5가 같은 것: `isSamePlace`, `sanitizeModelArgs`, `modelSuppliableKeys`, `missingAskedArguments`, `executeListSchedules`(총 건수 반환 포함), `repairDanglingToolTurn`, `trimHistory`, `unresolvedGenericPlace`, `stripInlineDataFromHistory`, `cancelPendingAsk`, `runToolCalls`(11개 모두 SAME).
- `resolveOrigin`:
  - 기본값만 없어졌습니다(base `:2350` `(_ query: String? = nil, orDefault: Bool = false)` → head `:2796` `(_ query: String?, orDefault: Bool)`).
  - 남은 호출처는 `:2605`(`orDefault: true`) 하나입니다.
  - `orDefault:true` 사다리(집 즐겨찾기 → 현재 위치)는 `:2817-2821`에 보존돼 있습니다.
  - 즐겨찾기 → 확정 장소 → 일반명사 가드 순서는 `adoptPlace`(`:806-829`)로 옮겨졌을 뿐 같습니다.
- `resolvedMode`는 base에도 없습니다(주석 1건). 이번 diff와 무관합니다.
- `isSamePlace` 사용처는 3곳에서 5곳으로 늘었습니다(`:1825`, `:2039` 추가). 강화이지 약화가 아닙니다. 다만 `:1825`는 A-2 참조.

**4. 도구 루프와 히스토리 모양 — 통과**
- `git diff aa7b792 5fb6634 -- proxy/ project.yml`는 0줄입니다.
- 턴 종료 가드는 두 곳에 있습니다. `:446`(runToolCalls 뒤)과 확인 경로 미러 `:1150`입니다.
- 히스토리 추가 지점 6곳(`:205`·`:305`·`:419`·`:438`·`:468`·`:1222`)을 모두 읽었습니다.
  - 함수 호출이 든 model 턴(`:438`, `:1222`)은 같은 await 흐름 안에서 바로 `runToolCalls`가 function 턴을 붙입니다(`:468`, 호출 수 = 응답 수).
  - 그래서 "functionCall 뒤 응답 없음"과 "functionCall 바로 뒤 user 턴"은 0건입니다(범위: 위 6곳).
- 턴이 끝난 뒤 이어지는 모양은 두 가지입니다.
  - 새 발화: `:297` repair가 `[function → model("네, 확인했어요.") → user]`를 만듭니다.
  - 카드 확인: `[function → model(앱이 쓴 fc) → function]`이 됩니다.
- `toResponsesRequest`(`proxy/src/index.js:167-221`)는 순서를 그대로 옮기고, call_id는 FIFO로 대응시킵니다. 이 두 모양을 모두 문제없이 변환합니다.
- 연속 model 턴은 카드가 재시작 뒤까지 살아남아야 생기는데, 카드는 저장되지 않으므로(`:139-141`) 도달하지 않습니다.
- `trimHistory`는 user 턴에서만 자르므로 호출·응답 쌍이 쪼개지지 않습니다.
- D-5 전제(progress §E.2 M2 (a))를 독립적으로 다시 확인했습니다. 라이브 요청으로 관측하지는 않았습니다(갭).

**5. 모델에게 가는 결과 문구 — 대체로 사실, 선택 1건(A-3)과 관찰 2건**
- `stayingEndAsk`(`:1921`)는 "끝나는 시각을 **사용자에게 물어** 받은 뒤"라고 씁니다. 모델에게 값을 지어 채우라고 하지 않으므로 REQ-010의 해당 절을 충족합니다.
- `makeStayingRecurrence` 요약(`:1947`·`:1950`, 점심 인자 버림 고지 포함)과 H-8 문구(`:2273`)는 사실과 맞습니다.
- 허위 "자동 진행" 문구는 D-4로 고쳐졌습니다. 다만 카드를 버렸을 때 히스토리에 남는 약속이 문제입니다(A-3).

**6. 토큰 측정법 — `plan.md` 방법과 일치, 증분 +122 유효**
- `tokmain.swift`가 하는 일:
  - GuardDriver와 같은 격리를 씁니다(임시 홈 `CFFIXED_USER_HOME`, 프록시·앱 토큰 비움).
  - `systemPrompt()` 원문과 `toolsJSON()`을 `JSONSerialization(.sortedKeys)`(공백 없음)로 출력합니다.
- `tokcount.py`는 두 덩어리를 o200k_base로 따로 세어 합산합니다. `plan.md`:230-233에 적힌 방법 그대로입니다.
- 교차 확인한 것:
  - `/tmp/tok-base-src/Shared/AIAssistant.swift` md5가 aa7b792 원본과 일치합니다(`055d67dd…`).
  - 두 원본 파일의 시각 줄이 같습니다(둘 다 "오후 2시 12분").
  - 시스템 프롬프트 영역에 즐겨찾기 목록이 없습니다(중립 설정). `즐겨찾기` 검색 결과 각 1건은 도구 JSON 줄(46행)에 있는 것입니다.
  - 시스템 프롬프트 차이는 `:1341` 한 줄, 도구 차이는 VAL 1건입니다.
- 한계: 앱 쪽 Gemini 모양 JSON을 잽니다. 프록시가 바꾼 Responses 모양(`type:"function"` 추가, 타입 소문자화)이나 OpenAI 내부 렌더링 기준의 **실제 과금 토큰은 아닙니다**. `plan.md`도 그렇게 주장하지 않으므로, 같은 방법으로 잰 쌍의 증분으로서 유효합니다.

## 발견 표

| id | 심각도 | 위치(5fb6634, 출력 확인함) | 무엇이 깨지나 | 재현 경로 | 수정 방향(적용 안 함) |
|---|---|---|---|---|---|
| A-2 | **차단** | `:1821-1827`(50 m 분기), `:801-807`(`stayingOneShotActivity`), `:1198-1199`(주입 뒤 재계산), `:1780`·`:1972`(`missingAskedArguments` 관문) | REQ-010 "사용자가 고른 값이 활동 장소·목적지와 50 m 안이면 활동만 만든다"(`plan.md`:87 같은 문장, spec §3 D1 "확인 때 '이동 없음'으로 바꿔 싣고")가 **고른 값이 장소 이름과 글자까지 같을 때만** 동작합니다. 분기 조건이 주입 **뒤** 인자로 계산되기 때문입니다. `from`이 nil이 아니면서 `stayingOneShotActivity`가 참이 되려면 `travel_from == place`(대소문자 무시)여야 하므로(`:805-806`), 50 m 판정은 사실상 글자 비교입니다. "현재 위치"나 좌표만 같은 다른 이름을 고르면 머무는 신호가 사라지고, 수단·여유·알림 줄이 새로 계산돼 확인이 막힙니다. | 드라이버식 절차: `drvAsk("create_activity", {place_query:"집", start_iso, end_iso})`로 출발지 줄이 뜬 카드를 만들고 → 그 줄에서 좌표가 집과 같은 다른 이름의 즐겨찾기(또는 집 안에서 `현재 위치`)를 고른 뒤 → `drvResolvePendingAsk`. 코드상 결과는 "아직 만들지 않았어요 — 이동수단, 도착 여유, 알림…이(가) 비어 있어요"와 레코드 0건입니다. 모델이 셋을 받아 다시 호출하면 **거의 0분짜리 가는 이동 1건**이 생깁니다(활동 경로에는 `isSamePlace` 거절이 없음, `:568-569`). 반복(`:2039`)은 결국 활동 블록만 만들지만, 그 전에 한 바퀴 더 돌며 필요 없는 세 값을 묻습니다. 드라이버에는 좌표가 같은 두 번째 즐겨찾기 픽스처도, 이 경우를 보는 단언도 없습니다(`grep -c '우리집' Tools/GuardDriver.swift` → 0). | 카드 맥락이 살아 있는 `resolvePendingAsk`에서, **주입 전** 인자가 머무는 요청(`stayingOneShotActivity`/`stayingRecurrenceSignal`)이었고 고른 값이 장소·목적지와 50 m 안으로 풀리면 `noTravelToken`으로 바꿔 싣습니다. 모델이 직접 보낸 이름 다른 편도(AC-008 (5) 양성 대조)는 그대로 가는 이동을 만들어야 합니다. `:1821-1823` 주석을 고치고, 양쪽 단언을 드라이버에 추가합니다(그 전에 좌표가 같은 두 번째 즐겨찾기 픽스처부터 필요). |
| A-1 | 선택 | `:1222`(토큰이 든 model 턴 적재), `proxy/src/index.js:188`(args를 그대로 `arguments` JSON으로), `:957`(정화는 키만 거름), `:2830-2832`(주석 "모델은 보낼 수 없고") | F-4를 확인했습니다. 토큰은 선언된 STRING 키(`origin_query`/`travel_from_query`)의 **값**이라 `sanitizeModelArgs`를 통과합니다. 이후 가드는 전부 토큰을 "이미 받은 답"으로 믿습니다. 반대로 카드 전용 **키**(반복 호출의 mode/buffer/notify/weeks)는 다시 호출될 때 정화에서 지워지므로, 값 쪽만 뚫린 비대칭입니다. 주석의 전제는 공용 메모리 "선언에서 뺀다고 모델이 못 보내는 게 아니다"가 이미 반박한 전제입니다. | (a) 같은 도구를 다른 요청에서 다시 호출: `create_recurring_schedule(origin_query:"__no_travel__", destination:다른 곳, return_time)` → 출발지 줄 없음(`:542`), 맥락 줄에서도 숨김(`:879`) → 카드에는 기간 줄만 → `:2028` 머무는 반복으로 등록. 이번 요청에서 출발지를 한 번도 묻지 않았으므로 REQ-010 "origin = destination은 사용자 선택 없이 확정하지 않는다" 위반입니다. (b) `create_activity(travel_from:"__no_travel__", return_to:"집")` → 왕복 분기(`:605-612`)가 토큰을 모름 → 캡션 "'__no_travel__'에서 출발하는지 한 번 더 골라 주세요…"(`:828`)로 사용자에게 토큰이 노출됩니다. (c) 다른 도구의 origin에 에코되면 → 문자 그대로 검색되어 → `:2783` "'__no_travel__' 위치를 찾지 못했어요". 에코가 관측된 적은 없어 선택으로 둡니다. | 입구(`sanitizeModelArgs` 또는 그 직후)에서 **모델이 보낸** 내부 토큰 값을 일반 인자의 뜻으로 되돌립니다. `origin_query`의 토큰은 `destination_query` 값으로 바꿉니다(같은 값 신호 → 출발지 줄이 선택 없이 다시 뜸). `travel_from_query`의 토큰은 `""`로 바꿉니다. 카드가 넣는 값은 정화 뒤에 얹히므로 한 요청 안의 흐름은 유지됩니다. `:2830-2832` 주석을 고치고, 모델이 보낸 토큰을 넣는 드라이버 단언을 추가합니다. |
| A-3 | 선택 | `:938`(파크 결과 문구), `:1228-1233`(취소는 말풍선만 바꿈), `:139-141`·`:169`(카드는 저장 안 함 + repair) | 후보 카드 경로는 모델 호출과 "사용자가 고르면 그 값으로 자동 진행돼요 … 기다려"를 **턴이 끝나기 전에 히스토리에 적습니다**. 사용자가 다른 말로 넘어가거나 앱이 재시작되면, 이 약속이 모델 쪽 히스토리에 그대로 남고 진행되지 않았다는 사실은 어디에도 없습니다. 실행 전 카드(pendingAsk) 경로는 호출을 히스토리에 넣지 않았으므로 새로 생긴 모양입니다. F-3(`:909` "같은 질문의 카드" — 다른 질의에도 같은 문구)도 확인했습니다. | 모호한 장소로 후보 카드가 열림 → 사용자가 "됐고 내일 일정 보여줘" 입력 → 이후 "아까 그거 됐어?"에 모델이 히스토리의 "자동 진행"을 근거로 답할 수 있습니다. | 문구를 조건부 사실로 씁니다: "사용자가 카드에서 고르고 확인하면 앱이 그 값으로 등록해요. 다른 말로 넘어가면 등록되지 않아요." `:909`는 "이미 다른 등록 확인 카드가 열려 있어요"로 고칩니다. |
| A-4 | 관찰 | `:1921`, `:1341`, `:1421` | `stayingEndAsk`, 프롬프트, 선언 설명이 "이동 구간 없이 활동 블록만 생긴다"고 결과를 미리 단정합니다. 실제로는 뒤이은 출발지 카드에서 다른 곳을 고르면 이동이 생깁니다(REQ-010). 모델이 사용자에게 "이동 없이 만들게요"라고 말한 뒤 카드가 출발지를 묻는 앞뒤 불일치가 생길 수 있습니다. 해는 작습니다. | 끝 시각 없는 "집에서 점심식사" → 모델이 "이동 없이 만들게요, 끝 시각은?" → 카드가 출발지를 물음. | "출발지는 앱이 사용자에게 확인해요" 정도로, 정해지지 않은 결과를 단정하지 않게 씁니다. |
| A-5 | 관찰 | `:2273` | H-8 문구의 끝 "…'반복 일정 전체 삭제' 뒤 다시 등록해."가 모델에게 하는 반말 명령입니다. 다른 문구의 "~라고 안내해" 관례와 달라서, 모델이 삭제와 재등록을 직접 하라는 지시로 읽을 수 있습니다(삭제 확인 규칙이 한 번 더 막기는 함). | 머무는 반복에 "자동차로 바꿔줘" → 이 문구. | "…다시 등록하라고 사용자에게 안내해"로 고칩니다. |
| A-6 | 관찰 | `:1150` | F-2가 확인 경로에도 이어집니다. 실행 전 카드가 호출 여러 개를 쥐고 있을 때 하나가 후보 카드로 멈추면, 먼저 등록된 호출의 요약(`resolvePendingAsk` 반환값)이 말풍선 없이 버려집니다. | 이미지 공유로 호출 3건, 그중 1건만 모호한 경우. | F-2 기록(t30)에 합칩니다. |
| A-7 | 관찰 | `:442` | 코드 주석의 인용 "(:428-431)"은 실제 `:433-436`입니다. `AIAssistant.swift`는 REQ-013의 sync 수정 허용 범위에 없어 sync에서는 고칠 수 없습니다. | — | 다음 run 카드에서 줄 번호 대신 함수 이름으로 인용합니다. |
| A-8 | 관찰 | `Tools/GuardDriver.swift` | AC-008 (5)의 양성 대조("모델이 보낸 `우리집` 편도 → 가는 이동 1건")에 해당하는 단언이 없습니다(`grep -c '우리집'` → 0, 소스 grep 기준, 드라이버는 실행 안 함). A-2를 고칠 때 이 대조와 함께 세워야 합니다. | — | 좌표가 같은 두 번째 즐겨찾기 픽스처와 단언 2개를 추가합니다. |

**0건 판정과 그 표집 범위**
- 선언 변화 0 — toolsJSON 영역 164줄 전체와 측정 JSON 전체 구조 비교
- 소문자 타입 0 — head toolsJSON 영역
- 가드 본문 변화 0 — 위 11개 함수
- 응답 없는 functionCall 0 — 히스토리 추가 지점 6곳
- `proxy/`·`project.yml` 변화 0 — 경로 diff
- 새 타입 0 — `Shared/`·`Tools/` diff의 `+` 줄

## 실행한 명령과 핵심 출력(발췌)

```
git -C <tree> diff aa7b792 5fb6634 -- proxy/ | wc -l                → 0
diff tools-base(1084-1247) tools-head(1364-1527)                     → 58c58 (origin_query description 1줄), exit=1
diff <e1a40a6 toolsJSON> tools-head                                  → IDENTICAL
grep -oE '"type": *"[A-Za-z]+"' tools-head | sort | uniq -c          → 1 ARRAY · 8 BOOLEAN · 6 INTEGER · 9 OBJECT · 44 STRING (소문자 0)
python 구조 비교(token-base.raw vs token-final.raw 도구 JSON)            → VAL [2]/parameters/properties/origin_query/description
md5 비교 11개 함수(base vs head)                                        → 전부 SAME
md5 /tmp/tok-base-src/Shared/AIAssistant.swift vs aa7b792             → 055d67dd… = 055d67dd…
cat token-pair.json                                                  → base 1704+2120=3824 · final 1771+2175=3946 · increment 122
grep -n '지금:' token-*.raw                                          → 두 파일 모두 "오후 2시 12분"
grep -c '우리집' Tools/GuardDriver.swift                              → 0
sed -n '805,806p' → guard let from = …; return from == Self.noTravelToken || from.caseInsensitiveCompare(place) == .orderedSame
sed -n '957p'     → call["args"] = args.filter { allowed.contains($0.key) }
sed -n '1150p'    → if bubbles.contains(where: { $0.ask != nil }) { return }
```

## 미검증(갭)과 남는 위험

- **갭**
  - 드라이버, iOS·macOS 빌드, `npm test`, 토큰 해니스를 이번 렌즈에서 다시 돌리지 않았습니다(임무 제약). A-2의 재현 결과는 코드를 읽어 추론한 것이고, 드라이버 관측은 아닙니다.
  - D-5 히스토리 모양을 라이브 요청으로 보내 보지 않았습니다.
  - 모델이 실제로 토큰을 되울려 보내는지(A-1)도 관측하지 않았습니다.
- **남는 위험**
  - 측정한 토큰 수는 과금 토큰이 아니라 같은 방법으로 잰 쌍의 상대값입니다.
  - A-2를 고칠 때 `resolvePendingAsk`에서 장소를 해석하면 검색이 두 번 일어날 수 있습니다(즐겨찾기·확정 장소·현재 위치로 범위를 좁히는 설계가 필요합니다).
  - A-1의 정화를 도입하면, 끝 시각을 다시 받는 호출(시각 문자열이 해석 불가였던 드문 경우)에서 사용자가 "이동 없음"을 한 번 더 골라야 합니다.
