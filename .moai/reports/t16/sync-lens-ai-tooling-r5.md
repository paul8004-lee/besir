# t16 sync 재심사 렌즈 — ai-tooling 5회차 (원문 보관)

- 대상: 브랜치 `WT-place-resolution` HEAD `daa77c1`(코드 = `daa77c1`, SPEC 0.1.9), 4차 판정 `a99f881`
- 수행: 2026-09-29, sync 5차 판정 레인(칸반 리드·GLM)이 띄운 읽기 전용 렌즈(`hns-besir-app-ai-tooling-specialist`). run 레인과 다른 손이다.
- 아래 원문은 렌즈 반환문을 그대로 옮긴 것이다(틀 들여쓰기만 벗겼다).

---

# t16 sync 5차 — ai-tooling 렌즈(선언·인자 계약) 재심사 보고서

**판정: FIX-FIRST** — 코드 계약(REQ-013·REQ-014·토큰 봉쇄·문자열 정화)은 전부 통과. 차단은 증거층 한 곳: `AE-C-1` 두 번째 단언이 라벨에서 주장하는 "가는 이동 1"을 조건이 검사하지 않는다(4차 판정문 R4.5의 J-1 단언 처방과 SPEC (10) 특성화가 명시적으로 요구하는 값이다). 더불어 acceptance.md AC-008 (10)(13) 산문이 J-1 수리 뒤 동작과 아직 모순된 채 남아 있다.

측정 기준: worktree `/Users/iseongmin/Projects/besir/.claude/worktrees/t16`, HEAD `daa77c1`(WT-place-resolution). 델타 `fa75e6e..daa77c1 -- Shared Tools`는 `Shared/AIAssistant.swift`(+65/-8)·`Tools/GuardDriver.swift`(+433/-71) 두 파일뿐(코드 변경 = daa77c1 단일 커밋; f441f8f·a99f881은 문서). 읽기 전용 — 드라이버·빌드는 돌리지 않았다(판정 레인이 재현). 모든 줄번호는 현행 트리 기준.

## Q1. 선언 불변(REQ-013 / AC-011 (4)) — PASS

실행한 검사 세 가지:
1. `git diff fa75e6e..daa77c1 -- Shared Tools | grep -E '"type"\s*:\s*"[a-z]|functionDeclarations|"STRING"|…'` → **일치 0건**. 델타는 toolsJSON·선언 어디에도 손대지 않았다(hunk 위치: 825-840 캡션 2, 1257-1310 J-1 갈래, 1639-1680 주석, 1937-1982 실패 문구, 2988-3001 displayText).
2. 두 리비전에서 `private func toolsJSON` 본문을 awk(중괄호 깊이)로 추출해 `cmp` → **바이트 동일**(164줄·13,475 bytes). systemPrompt(64줄·8,660 bytes)·callAI(32줄·1,484 bytes)도 동일(→ Q2).
3. 현행 toolsJSON 본문 타입 전수: `"type": "STRING"` 44 · `"OBJECT"` 9 · `"INTEGER"` 6 · `"BOOLEAN"` 8 · `"ARRAY"` 1 — 전부 대문자, 소문자 패턴 `grep -cE '"type"\s*:\s*"[a-z]'` = **0**(더 넓은 1,669줄 구간에서도 0). 도구 9개(`create_schedule`…`check_travel_time`) 이름·개수 불변.

## Q2. 토큰쌍 귀속(REQ-014) — PASS

`toolsJSON`·`systemPrompt`·`callAI` 세 본문을 fa75e6e와 daa77c1에서 같은 awk 추출로 뽑아 `cmp` — **셋 다 바이트 동일**(증거: `/tmp/t16_{fn}_{rev}.txt`, cmp exit 0; 줄·바이트 수 위 기재). 요청을 형성하는 세 표면이 최종 수리(daa77c1)에서 한 바이트도 움직이지 않았으므로, 이전에 잰 토큰쌍(3,824 → 3,946, +122)은 daa77c1에 그대로 귀속된다. 단, 나는 토크나이저를 재지 않았다 — 귀속 근거는 본문 항등이지 재측정이 아님(Gaps 참조).

## Q3. J-1 두 번째 카드의 파트 소비자 추적 — 설계 의도 확인(관찰 1건)

두 번째 카드 생성(`Shared/AIAssistant.swift:1302-1306`, `PendingAsk(parts: parts, …)` — parts는 주입 뒤 인자로 `__current_location__` 등을 실은 채) 이후의 소비자를 전수 추적:

- **카드가 열려 있는 동안**: `resolvePendingAsk`가 `return nil`(:1306) → `confirmAsk`가 `guard let summary … else { return }`(:1180)에서 즉시 복귀 — callAI도, runToolCalls도, 툴 결과 문자열도 없다. `saveHistory`(:140-145)는 `ask != nil` 말풍선을 제외하므로 parts는 디스크에 남지 않는다. bubbles의 텍스트는 `""`(:1303) — 사용자 노출 문자열 없음.
- **두 번째 확인 시**: 주입 루프(:1242-1276) 뒤 J-1 재검사(:1291-1301)에서 새 줄이 없으면 **기존 경로 그대로** `contents.append(["role":"model","parts":parts])`(:1309) → `runToolCalls(parts)`(:1310) → `confirmAsk`의 `runLoop`(:1186) → `callAI`가 `contents`를 통째로 실어 보낸다(:1371). 즉 토큰(및 카드 전용 키)은 **아웃바운드 히스토리 에코로 모델 요청에 실린다**. 이것은 첫 카드 경로가 옛날부터 하던 동일한 성질이며(라인 1309는 델타에서 불변), R1 주석(:960-963)이 "모델 턴에 오는 토큰은 전부 히스토리 에코다"라고 스스로 규정한, 인바운드 정화로 방어되는 설계 속성이다. **J-1이 새로 만든 노출면은 없다.**
- **sanitizeModelArgs 경유 여부**: 정화는 인바운드 단일 지점(runLoop :434)만 지나며, 앱이 쥔 PendingAsk parts는 어떤 경로에서도 정화를 다시 통과하지 않는다. R1/E1은 모델이 나중에 이 턴을 되울릴 때만 작동 — E1(create_recurring origin 토큰→목적지)은 되울림 복원이지 J-1 파트 왜곡이 아니다. 2차 카드 시나리오에서 반복의 origin에 `__no_travel__`이 실리면 staying 신호(:799-802)가 mode/buffer/notify 줄을 안 세우므로 2차 카드 자체가 안 열린다(:544-558).
- 관찰(주석 정밀도, NON-BLOCKING): J-1 주석 "주입 뒤 인자를 앱이 그대로 쥐므로 내부 토큰이 모델을 거치지 않는다"(:1286-1287)은 **카드 열림 주기에만** 참이다. 최종 확인 순간에는 :1309→:1371로 토큰이 히스토리에 실려 나간다(사전 설계·방어됨). 4차 판정문 R4.5도 같은 좁은 서술을 썼으니 위반은 아니나, 후속 독자가 "토큰은 절대 요청에 안 실린다"로 오독할 여지가 있다.

## Q4. 모델·사용자 노출 문자열 감사 — 다섯 번째 누수 후보 없음

델타가 건드렸거나 인자 값을 렌더하는 자리 전수(13곳):

| 자리 | file:line | 판정 |
|---|---|---|
| `stayingOriginNote` | AIAssistant.swift:828-830 | `displayText` 통과 — 토큰 세이프 |
| `roundTripOriginNote`(J-3) | :833-837 | `displayText` 통과 — **수리 확인**(AE-R3-d가 단언) |
| `unresolvedQueryText`(E6/F3) | :1976-1982 | currentLocationToken→displayText, 나머지 토큰 `isInternalPlaceToken`→nil |
| J-1 `followUpStated` | :1300 ← `filledValueLabels` :889-893 | `isInternalPlaceToken` 필터(D1) — 세이프 |
| 확인 요약 `chosenLine` | :1207 ← EditCard.swift:172-175 | 옵션 value→label 사전 매핑 — 토큰은 항상 칩 옵션 값이라 라벨로 바뀐다 |
| `statedLabels` | :371-379 | mode/buffer/notify만 — 장소값 없음 |
| `unknownPlaceNote` | :3046-3048 | `genericPlaceWords`(집·회사·학교·사무실·우리집, :3028)만 통과 — 토큰 불가 |
| `unclearPlaceNote`·park 반환문 | :848, :949-950 | unclear query는 검색 경유값 — 토큰은 실행부가 검색 앞에서 전부 차단(schedule :1753, activity :1931/1934/1939, recurring :2149) |
| `placeNotFound` | :2922-2930 | 도달 query는 비토큰뿐(위 차단) |
| 실행부 요약문 | :1838, :2014-2028, :2094 | 해석된 `Place.name`·제목·수단만 — 토큰 없음 |
| `missingAskedArguments` | :1684-1685 | 줄 라벨만 — 값 없음 |
| `recurringArgumentIssue` | :2345-2361 | `nth`(Int)만 — 값 없음 |
| `conflictPrompt`·겹침 경고 | :1873-1882, :2038 | 기존 일정 제목·시각만 |

남은 노출 두 곳(모두 기존·델타 무관): (a) 아웃바운드 히스토리 에코(Q3 — 설계가 인정하고 R1/E1로 방어), (b) `transcriptForDebugging`(:246-259 — 출시 전 제거 예정 테스트 코드). 다섯 번째 사이트는 발견하지 못했다.

## Q5. AE 단언 품질(AC-008 (10)(13), J-2) — 실물 단언 맞으나 한 건 라벨 과잉

`Tools/GuardDriver.swift:3062-3453` AE 단원 전수 열독. 정적 drvCheck 39줄 = 본단언 24줄 + 폴백 15줄; 헬퍼·루프 전개 시 본단언 **30개**(질문의 "30 AE lines"와 일치). 헬퍼는 전부 실제 앱 경로(`drvAsk`→`pendingAsk(fillStated(sanitizeModelArgs(…)))` :88-92, `drvResolvePendingAsk`→실제 `resolvePendingAsk` :153, `drvPickLabel`→실제 `choose` :160-165). 폴백(`else { drvCheck(…, false, "ask=nil") }`)은 카드가 안 서면 **실패**로 찍히는 정직한 경로다. true-by-construction 공허 단언은 없다(S-1a/1b의 `?? true == false` 방향도 ask==nil이면 실패로 떨어진다).

질문의 기대 모양("첫 단계 세 낱말 거절 → 특성화")에 대한 답 — AE-C-1/AE-C-1r은 **그 문구를 단언하지 않는다**:
- **앞 단계**: `AE-C-1`(1/2)·`AE-C-1r`(1/2)은 `first == nil && followUp != nil && Set(keys) == {mode_this_time, buffer_minutes, notify_lead_minutes}`(:3310-3313, :3338-3341) — 세 낱말 거절이 아니라 그것을 대체한 J-1의 두 번째 카드를 단언한다. 이는 4차 판정문 R4.5의 처방("두 번째 카드 키 = [수단, 여유, 알림] · 보류 travel_from = 현재 위치 토큰 · 확인 → 활동 1·이동 1")과 AE 배너의 "J-1 수리 뒤 모양"·"리드 결정 J-2"(:3062-3067)를 따른 것이다. 세 낱말 거절 자체는 J-1 뒤에도 도달 가능한 유일 경로(카드 없는 직접 호출)에서 `AE-R3-b` ×2(:3414-3428)가 단언한다 — 다만 (13) R3-b 기대의 "세 날말" 중 **이동수단 한 낱말만** 검사한다.
- **특성화(차단)**: `AE-C-1`(2/2)의 라벨은 "활동 1·가는 이동 1로 완주한다"(:3318)이지만 조건은 `store.activities…count == 1`뿐(:3319) — **가는 이동 1을 검사하지 않는다**. R4.5 처방과 SPEC (10)(acceptance.md:188 "활동 1건과 가는 이동 1건이 생기고")이 요구하는 값이다. 다리 수 검사는 `AE-S-3a/S-3c` 헬퍼(:3139-3142, `acts==1 && legs==1`)가 앵커가 즐겨찾기('집')인 변형에서 이미 하고 있으므로 한 줄(`&& store.events.filter{…}.count == 1`)을 붙이면 된다. 현재 채로는 다리 생성이 회귀로 무너져도 이 단언은 ✓로 찍힌다 — 라벨이 검사하지 않은 것을 증명했다고 읽게 하는, CLAUDE.md "검사하지 않은 것 = 실패"의 정확한 역형이다.
- **AE-C-1r**(2/2)(:3346-3348): 통근 이동 ≥1을 단언 — SPEC (10) 반복 특성화(블록 4·이동 0·"이동 구간은 만들지 않았어요" 문구)와는 다른 형태(나)-전환이다. 그 형태는 `AE-S-3r`(:3210-3213)이 담당하나 **존재 단언에 그친다**(== 4 카운트도 문구 검사도 없음).
- **보류 토큰 단언**: 판정문이 J-1에 처방한 3요소 중 "보류 travel_from = 현재 위치 토큰"은 `AE-S-3a/3c`의 둘째 단언(:3131-3134, `drvCallArgs(followUp)["travel_from_query"] == drvCurrentLocationToken()`)에 실려 있다. AE-C-1 이름 아래에는 없다(커버리지는 존재).

**BLOCKING (2)**
1. `Tools/GuardDriver.swift:3318-3320` — AE-C-1 (2/2) 조건에 가는 이동 1건 검사 추가(AE-S-3a/3c :3139-3142와 같은 한 줄). 라벨-조건 불일치가 J-2 인증(AC-008 (10) 특성화)의 한쪽 절반을 빈 채로 둔다.
2. `.moai/specs/SPEC-UIKIT-008/acceptance.md` (10)(:183-192)·(13) 표 C-1/S-3a/S-3c 행(:222 영역, 기대 "0건, 세 날말")이 J-1 수리 뒤 동작(두 번째 카드)과 모순된 채다. 4차 판정문 R4.7이 "단언 추가 **또는** SPEC 개정 — 리드 결정"으로 열어 뒀고 리드는 단언 추가를 택했지만, 산문은 그 결정을 기록하지 않아 다음 독자·grep에게 자기모순으로 남는다. manager-spec이 (10)(13) 산문을 J-1 모양으로 고치거나 리드 결정을 그 자리에 적어야 한다.

**NON-BLOCKING (4)**
3. `AE-R3-b` ×2(:3415, :3426) — (13) R3-b 기대 "세 날말" 중 `이동수단`만 검사. 도착 여유·알림 단어 추가 권고.
4. `AE-S-3r`(:3210-3213) — 블록 == 4·"이동 구간은 만들지 않았어요" 문구 미검사(존재 단언).
5. J-1 주석(:1286-1287) "토큰이 모델을 거치지 않는다"의 적용 범위를 카드 열림 주기로 한정하는 문장 보강(Q3 관찰).
6. AE-C-1 (1/2)에 보류 토큰 검사 부재(AE-S-3a/3c가 커버; C-1 이름 아래 두면 (10) 시나리오 자체 완결).

**0-주장의 표집 범위**
- "소문자 타입 0": toolsJSON 본문 164줄 + 1,669줄 확장 구간 + 델타 diff 전체 grep.
- "선언 키 추가 0": 두 리비전 본문 cmp(바이트 항등) + diff에 functionDeclarations hunk 없음.
- "다섯 번째 누수 0": AIAssistant.swift 렌더 자리 13곳 전수 열독(위 표) + EditCard.swift chosenLabel/customLabel + 세 실행부의 토큰 차단 지점 6곳. 미감사: `proxy/src`(델타 밖 — Shared/Tools만이 범위), Store.swift 직접 렌더(요약문은 실행부 문자열로만 사용자에게 나감).
- "AE 30줄 실물": :3060-3453 전수 열독(정적 39줄 전부). 드라이버 미실행 — 355/355 주장은 판정 레인 재현에 맡긴다.

**Gaps / 잔여 위험**
- 드라이버·iOS/macOS 빌드·프록시 테스트를 이 렌즈는 돌리지 않았다(읽기 전용 지시). 355/355·무경고 빌드 주장은 무검증.
- 토큰쌍 3,824→3,946을 토크나이저로 재지 않았다 — 귀속은 본문 항등(cmp)으로만 확정.
- 아웃바운드 히스토리 에코(:1309→:1371)에 토큰·카드 전용 키가 실리는 것은 기존 설계 속성(R1/E1 인바운드 방어)이나, `drvLastCallArgs`로 이를 직접 감시하는 단언이 AE에 없다 — 다음 라운드 감시망 후보.
