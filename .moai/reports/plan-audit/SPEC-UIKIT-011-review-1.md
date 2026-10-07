# SPEC Review Report: SPEC-UIKIT-011
Iteration: 1/3
Verdict: FAIL
Overall Score: 0.75 (Tier M 통과 기준 0.80 미달)
필수 수정 5건(MF-1~MF-5: 명확화 게이트 1 + 문서 결함 4) · 권고 10건(A-1~A-10)

감사 기준 트리: `d900a78`(브랜치 `WT-always-select`). 직접 확인한 결과 `git diff --quiet 4987e2d HEAD -- Shared Tools proxy project.yml` → exit 0이고, `git diff --quiet 1375587 4987e2d -- Shared Tools` → exit 0이다. `wc -l`은 3258 · 5068이다. 작성자의 추론 맥락은 전달되지 않았다. 호출자가 준 운영자 지시문은 `moai todo`의 t47 행 원문과 대조한 뒤 지시 출처로 썼다(M1 맥락 격리).

---

## 필수 통과 항목 결과

- **[PASS] MP-1 REQ 번호 일관성**: `grep -c '^- \*\*REQ-' spec.md` → 15. REQ-001~015가 spec.md:L103·105·107·109·111·113·122·124·126·128·134·140·148·150·154에 빠짐없이, 중복 없이 이어진다.
- **[PASS] MP-2 GEARS 형식(요구사항 층에서 판정)**: 15건 모두 패턴 라벨과 `shall` / `shall not` 문형을 갖췄다. REQ-012(L140)와 REQ-014(L150)는 `Where decision D-n (a) is adopted`처럼 미해소 결정을 Where 게이트로 썼다. 정적 설정 게이트로 볼 수 있어 통과로 판정한다. 인수 기준(AC)의 Given-When-Then은 이 항목의 판정 대상이 아니다.
- **[PASS] MP-3 YAML 머리말**: spec.md:L1-17에 12개 필드가 모두 있다(`version: "0.1.0"`는 따옴표 문자열, `priority: P1`, `lifecycle: spec-anchored`, `tags`는 쉼표 문자열). `moai spec lint --strict .moai/specs/SPEC-UIKIT-011/spec.md` → `✓ No findings — all SPEC documents are valid`.
- **[N/A] MP-4 언어 중립성**: Swift 단일 언어 앱이라 해당 없다.
- **[PASS] MP-5 D7 SPEC 간 정합**: 참조 SPEC은 005·008·009·010·011이다. 005·008·009는 `status: completed`다. 010은 `.moai/specs/`에 없어 SHOULD 등급이지만, HISTORY(L25)가 "반려된 t45(SPEC-UIKIT-010, `status: rejected`)"로 명시해 정합을 맞췄다. 보존 사본 `/Users/iseongmin/Projects/besir/.moai/reports/t45/SPEC-UIKIT-010/spec.md`도 `status: rejected`다. BLOCKING 없음.
- **[PASS] MP-6 D8 플랫폼 규율**: SPEC 파일 다섯 개 모두에 `syscall`이 0건이다.
- **[FAIL] MP-7 명확화 게이트**: `grep -c '\[NEEDS CLARIFICATION'` 결과 spec 0 · **plan 6** · acceptance 0 · research 0 · progress 0이다. 표식은 plan.md:L46(D-1)·L58(D-2)·L69(D-3)·L80(D-4)·L91(D-5)·L102(D-6)에 있다. 표식 위치는 관례에 맞다(spec·acceptance 0). 하지만 미해소 표식은 계약상 필수 통과 실패다. 해소 주체는 manager-spec이 아니라 오케스트레이터이며, 착수 승인 전에 운영자에게 묻는다 → MF-1.

## 영역별 점수(루브릭 고정)

| 영역 | 점수 | 구간 | 근거 |
|---|---|---|---|
| 명확성 | 0.75 | 0.75 | 요구사항은 대체로 한 가지로 읽힌다. 다만 REQ-003(L107)의 "at most one provider search"는 `PlaceSearch.search`의 카카오 → MapKit 폴백(`Shared/PlaceSearch.swift:13-18`)과 겹쳐 두 가지로 읽힌다(A-6). REQ-009(L126)의 맥락 줄은 출처가 흐리다(A-1) |
| 완결성 | 1.0 | 1.0 | HISTORY(L21)·배경(L44)·요구사항(L95)·바뀌지 않는 것(L156)·범위 밖 H3 다섯 개(L173·177·181·187·191, 각각 `-` 항목 있음)·결정(L195)이 있고 머리말도 완전하다 |
| 시험 가능성 | 0.50 | 0.50 | AC-009 둘째 행은 기준선 주장이 거짓이고 명령이 없다(MF-3). AC-012·013 스크립트는 기대 화면이 코드와 어긋난다(MF-4). AC-008 점심 대조는 판단이 필요하다(A-3) |
| 추적성 | 1.0 | 1.0 | REQ 15건이 모두 AC를 하나 이상 갖고, AC 13건이 모두 실재하는 REQ를 가리킨다(아래 행렬) |

종합 0.75(조화평균). Tier M 기준 0.80(`.claude/rules/moai/workflow/spec-workflow.md:141`)에 미달한다.

---

## 영역 1 — 인용 사실의 정확성 (직접 대조 25건)

| # | 문서 주장 | 대조 방법 | 결과 |
|---|---|---|---|
| 1 | `placeRow` 기본 갈래가 `destinationField()`(`:752`) | `Shared/AIAssistant.swift:746-754` 열람 | ✓ 모르는 키는 `destination_query` 줄로 떨어진다 |
| 2 | 보류는 `item.key`로 줄을 바꾸거나 덧붙이고(`:942-943`) `clearedKeys`를 남긴다(`:950`) | `:918-958` 열람 | ✓ |
| 3 | 확인 주입은 `kind == .place`이면서 `clearedKeys`에 든 줄만 본다(`:1238`), 도구 이름은 보지 않는다 | `:1222-1247` 열람 | ✓ → REQ-009의 줄 재료 필요성이 성립한다(가) |
| 4 | `filledValueLabels`에 수정 도구 갈래가 없다 | `:899-908`(`default: break`) | ✓ |
| 5 | `askFields`에 `update_schedule` 갈래가 없다 | `:635 default: break`, `case "update_schedule"`는 `:1713` 디스패치에만 있다 | ✓ |
| 6 | 반복 점심 해석(`:2250`)이 통근(`:2202`)·복귀(`:2220`)·체류(`:2228`) 저장 뒤에 있다 | `:2201-2268` 열람 | ✓ 해석 조건 `:2242-2243`, 머무는 갈래 `:2184-2199`, 점심 미적용 안내 `:2104-2106`도 확인 → (나) 성립 |
| 7 | 확인은 도구 전체를 다시 실행한다(`:1318-1319`) | 열람 | ✓ |
| 8 | `confirmedPlaceKey`(`:1083-1092`) 사다리가 같은 이름 다른 좌표를 가른다 | 열람 | ✓(다) 성립. research §3(나)의 "주소가 같으면 이름 · 좌표"는 작은 부정확이다(A-9) |
| 9 | 칩 `ForEach(places, id: \.self)` · 주소 줄 · 자유 텍스트 확정 버튼 없음 | `Shared/EditCardView.swift:349`·`:365`·`:315`, `Shared/Models.swift:111-116` | ✓ |
| 10 | 사라지는 `.resolved` 갈래에 기대는 다른 소비처가 없다 | `grep -rl 'adoptPlace\|placeAdoptionDecision\|resolveDestination\|resolveOrigin\|parkForUnclearPlaces' --include='*.swift' Shared Tools ShareExtension` → AIAssistant·EditCard·GuardDriver. EditCard.swift:240은 주석뿐이다. AIAssistant 안 호출처는 `:1749·1768·1931·1949·1952·2161·2174·2250·2703·2762·2765·2813`이다. `:1949`는 현재 위치 토큰 전용(`:1948`)이다. Store.swift에는 0건이다 | ✓(라) 성립. `stayingTokenForColocatedPick`은 `locallyResolvedPlace`만 본다(`:1347`·`:1350`) |
| 11 | 반복 확인 상태는 보류 → 재실행에서도 유효하다 | `:2354-2383`, 소거는 생성 뒤 `:2213` | ✓ |
| 12 | 수정 경로는 대상 찾기와 여러 건 가드가 검색 앞에 있고, 저장은 뒤에 있다 | `:2792-2809`, 가드 `:2802`, 해석 `:2811-2815`, 저장 `:2824`·`:2842` | ✓ 카드 앞의 부분 쓰기 없음. "여러 건" 가드가 보류보다 먼저 돈다 |
| 13 | 재시도 블록 `:3094-3104`, 검색 `:3093`·`:3102` | 열람 | ✓ `grep -c 'placeSearch.search('` → 3 |
| 14 | 계수 `searchTopClearlyMatches(` 4 · `normalizedPlaceWord(` 7 · 재시도·병합 6·2 · 드라이버 도우미 10 · 합집합 13·20 · `drvAdoption(` 13 · `drvCheck(` 507 | 같은 `grep -c` 재실행 | ✓ 전부 일치 |
| 15 | 지울 단언 수: AI-6 3, AI-9~12 4, AA-1 6, AB-H04 2. AI-8은 이미 "질문" | `Tools/GuardDriver.swift:5004·5005·5007`, `:5020·5023·5026·5028`, `:1896-1907`, `:2281-2286`, `:5013-5018` | ✓ 반복·조건 밖이라 각 1회 실행 |
| 16 | 기준 492 | `/Users/iseongmin/Projects/besir/.moai/reports/t42/gate-sync-driver.log:551-579` | ✓ AI절 18줄 + 불변식 3 + 전체 불변식 3, `492/492 통과`, `[실제 데이터] 대조 통과`, `EXIT=0` |
| 17 | 새 총수 488 / 496, 마감 `drvAdoption(` 12 | 직접 계산 | ✓ 492−7−8+11=488, 492−7+11=496. 13 −1(AI-6) −4(R-5) +4(AI-14~17)=12 |
| 18 | AI-14·15·16이 기준 트리에서 ✗ | `placeAdoptionDecision` `:3172-3189`를 손으로 따라감 | ✓ AI-14 → 정확 일치 `resolved`. AI-15 → 정규화 이름 키가 둘째 홍대입구역점을 지워 후보 2. AI-16 → 만족 결과 우선 재정렬로 홍대입구역점이 앞 |
| 19 | AC-002 awk 범위의 기준 계수 2 | `:3172-3190`, `.contains(`는 `:3182`·`:3186` | ✓ |
| 20 | 기준 트리 = t42 병합 | 위 `git diff --quiet` 두 건 | ✓ |
| 21 | 루트 `plan.md:583-585` = 후속 31·32·33, `:457` = t42 행 | `sed -n` | ✓ |
| 22 | t45 반려 원문, R-5 정의 | `.moai/reports/t45/plan-progress.md:63·65`, `.moai/reports/t42/code-safety-sync.md:115` | ✓ |
| 23 | 시스템 프롬프트에 채택 방식에 기대는 문구가 없다(research §7 미열람 구간) | `awk 'NR>=1380 && NR<=1560'`에서 `카드\|등록하지 않\|고르`, 전역에서 `후보\|모호\|애매` | ✓ 결과(`:1452`·`:1462-1472`)는 채택과 무관 |
| 24 | adoptPlace 사다리의 줄번호 `:1087` · `:1092` | 열람 | **✗ 실제는 `:3087`·`:3092`.** `:1087`은 `confirmedPlaceKey` 안의 `for` 줄이다 → MF-2 |
| 25 | "앱 −90 / +110 = plan §3 목록의 합" | plan.md §3 표를 합산 | **✗ 삭제 100 · 추가 60, ± 항목 30이 별도**다 → MF-5 |

## 영역 2 — 지시 충실도와 출처 표기

- 카드 원문(`moai todo` 25행)과 대조했다. 원칙·①~⑤·자동 유지 경계·환승역 일관성·R-5·AI-3 정리는 spec.md §1.1(L50-60)과 plan.md §5 머리에 빠짐없이 옮겨졌다. 〔운영자〕로 표기된 방향은 모두 카드 원문에서 찾을 수 있다. REQ-003의 취지 인용(L107)도 원문과 글자 단위로 같다.
- 카드와 코드가 어긋난 곳(AI-8은 이미 "질문"이다, 조회 경로 평탄화, 순서 미지정, 점심 위치, 줄 재료)은 〔조사〕로 정직하게 드러냈다. 운영자 지시를 넘는 범위인 D-1(조회 경로)·D-2(순서)·D-5(죽은 코드)는 〔제안〕과 결정 게이트로 분리했다. REQ-014(L150)는 "계획자의 제안이며 운영자 지시가 아니다"라고 명시했다. 제안을 지시로 둔갑시킨 곳은 찾지 못했다.
- 예외: REQ-009(L126)의 "수정 카드에 고칠 일정을 적는 맥락 줄"은 운영자 지시에 없는 UX 추가다. 문안은 D-3에 올라 있지만, 맥락 줄을 둘지 말지는 결정으로 올라 있지 않고 요구사항 본문에 출처 표기가 없다 → A-1.
- `CLAUDE.md` "카드 착수 전 설명" 네 항목은 plan.md §9가 형식을 모두 갖췄다(①~⑤). ① 전후 동작은 예 다섯과 미리보기로, ② 파일·규모, ③ 그대로 두는 것, ④ 운영자 스크립트가 있다. 다만 ①의 예와 ④의 스크립트는 실행 전 카드(이동수단·기간 줄)가 후보 카드 앞에 뜨는 경우를 빠뜨렸다 → MF-4.

## 영역 3 — 완결성과 안전

- **plan §7 위험 렌즈의 "검사함" 판정**: 대부분 코드 읽기이고, 이번 대조에서 재현했다(인덱스 재사용 없음 `:918-958`·`:2792-2842` / 검색 `try?` `PlaceSearch.swift:14`·`:121` / 강제 언래핑 `:2794`·`:2798`). "AI 일일 할당량"은 추론이라고 스스로 밝혔다. 판정은 실제로 얻은 증거와 맞는다.
- **이중 카드 위험**: `parkForUnclearPlaces`의 가드(`:923`)는 확인 경로에서 원래 카드 말풍선이 먼저 사용자 말풍선으로 바뀌므로(`:1216`) 막히지 않는다. 확인 안의 재보류는 `confirmAsk`의 가드(`:1191`)가 받는다. 기존 AC-003 10번과 같은 모양이라 새 위험은 없다. D-4 (a)의 연쇄 카드도 같은 길을 탄다.
- **놓친 것**:
  - 실행 전 카드 + 후보 카드의 누적 장수(A-2·MF-4). 생성 도구는 `mode_this_time`·`weeks`를 선언하지 않는다(`:1515-1578`의 선언 키 목록에 없다). 발화 파서도 `지하철로` / `지하철 타` 같은 꼴만 잡는다(`:361-366`). 따라서 검색으로 푸는 장소가 있는 등록은 대개 카드 두 장, 반복 + 점심은 최대 세 장이 된다. plan §7 잔여 위험은 "두 장"으로 적었다.
  - REQ-008 뒤 `resolveDestination`의 `creation:` 인자는 `true`로 부르는 곳이 사라진다(현재 유일한 호출 `:2250`). 죽은 매개변수인데 D-5와 죽은 코드 렌즈에 없다(A-4).
  - 주석 목록 누락: `:34`("실행부 셋"), `:912-917`(보류 카드 설명 "검색 첫 결과가 이름과 맞지 않아")이 plan §3과 AC-009 grep 밖에 있다(A-5).
- **확인한 무위험 항목**: 수정 경로의 여러 건 가드가 보류보다 먼저 돌고, 부분 쓰기는 없다(#12). 재시도 삭제는 카카오 호출을 질의당 최대 2회에서 1회로 줄인다(`:3093`·`:3102`). 모델에게 가는 문구는 `:924`·`:957`과 캡션 `:853`이 거짓이 되는데 REQ-011이 덮는다. 프롬프트에는 해당 문구가 없다(#23). iOS 전용 방침은 REQ-015(L154)와 §4(L191-193)에 있다.

## 영역 4 — 시험 가능성과 추적성

### REQ ↔ AC 추적 행렬 (직접 작성)

| REQ | AC (D·G) | AC (S) |
|---|---|---|
| 001 | AC-001 | AC-012 |
| 002 | AC-002 | AC-012 |
| 003 | AC-003 | AC-012 |
| 004 | AC-004 | AC-012 · AC-013(S-10) |
| 005 | AC-004 | AC-012(S-6) · AC-013(S-9) |
| 006 | AC-002 | AC-012(S-3) |
| 007 | AC-005 · AC-008 | AC-013(S-7) |
| 008 | AC-006 · AC-008 | AC-013(S-8) |
| 009 | AC-005 · AC-006 | — |
| 010 | AC-007 | AC-012(S-6) |
| 011 | AC-009 | — |
| 012 | AC-010 | AC-013(S-11) |
| 013 | AC-011 | — |
| 014 | AC-011 | — |
| 015 | AC-011 | — |

역방향도 모두 성립한다. AC-001~013은 각각 위 표의 REQ만 가리키고, 고아 AC는 없다.

- "0건" 주장의 양성 대조(AC-002·003·009 첫 행·011-4)는 기준 트리 수치를 내가 다시 재서 모두 맞았다(#14·#19). AC-011-6 `'"type": "[a-z]'`는 기준도 0이라 양성 대조가 없다. 이 점은 문서가 스스로 밝혔다("드라이버 (e)절이 맡는다").
- 결함: MF-3(AC-009 둘째 행), MF-4(S 스크립트), A-3(AC-008 점심 대조), A-7(AI-19 픽스처).

## 영역 5 — 형식과 파일 간 모순

- 게이트 표식은 plan.md에만 있다(MP-7 근거). 머리말·GEARS는 위와 같다. 시간 추정은 정규식 검사에서 0건이고, plan.md:L25가 추정하지 않는다고 명시했다.
- REQ 15 · AC 13 · 결정 D-1~D-6 · Tier M은 다섯 파일이 서로 맞는다(spec L38, plan L17·§2, progress L9).
- 모순 두 건: 줄번호(MF-2 — spec과 plan은 `:1087`/`:1092`, research §2와 progress 표는 `:3087`/`:3092`), 변경량 합(MF-5).

---

## 발견한 결함 (구조화 목록)

D1. MF-1 — plan.md:L46·58·69·80·91·102 — 미해소 `[NEEDS CLARIFICATION]` 6건(D-1~D-6), 명확화 게이트 — Severity: critical — Class: blocking — Required fix: **오케스트레이터가** 착수 승인 전에 `AskUserQuestion`으로 운영자에게 여섯 결정을 받고, plan.md §2의 표식을 결정 결과로 바꾼다. 결정이 권장안과 다르면 REQ-002·012·014와 AC-002·009·010·011의 "(b)면" 갈래를 그 안으로 다시 쓴다. manager-spec 단독 수정 대상이 아니다.

D2. MF-2 — spec.md:L64·L99·L111·L128, plan.md:L199 — `adoptPlace`의 로컬 두 단·일반명사 가드를 `:1087`·`:1092`로 인용했다. 실제는 `Shared/AIAssistant.swift:3087`(`if let local = locallyResolvedPlace(query)`)·`:3092`(`if creation, unresolvedGenericPlace(query)`)이다. `:1087`은 `confirmedPlaceKey`의 `for key in candidates` 줄이다. HISTORY(L25)의 "줄번호는 전부 이 트리에서 명령으로 쟀다"와 모순되고, research §2(`:3087`·`:3092`)와도 어긋난다 — Severity: minor — Class: blocking(내부 일관성·명시 기준) — Required fix: 다섯 자리의 `:1087`을 `:3087`로, `:1092`를 `:3092`로 고친다. L128의 `(:1063-1092 · :1087)`은 "확정 사전 조회 `:3087`/`:1362`"로 바로잡는다. 고친 뒤 `grep -n ':1087\|:1092' spec.md plan.md`로 남은 곳이 없는지 확인한다.

D3. MF-3 — acceptance.md:L151 (AC-009 둘째 행) — "채택 원문 각각이 `Shared/AIAssistant.swift`에 정확히 1회, 기준 트리 0"은 실측하지 않은 주장이고 거짓이다. 기준 트리에서 `grep -c '바꿀 장소'` → 1(`:1609` 선언 설명), `grep -c '점심 장소'` → 4(`:1567`·`:2114`·`:2247`·`:2265`), `grep -c '고칠 일정'` → 1이다. 제안 원문에는 자리표시(`{q}`·`{names}`·`{title_query}`)가 있고, 동사는 "한 도우미에서" 조립하므로(plan §3 L119) 원문 전체가 소스에 글자 그대로 나타날 수 없다. 명령도 없다 — Severity: major — Class: blocking — Required fix: 행을 고정 부분 문자열의 명령 목록으로 바꾸고 기준값을 실측해 적는다. 예: `grep -c '검색 결과예요\. 맞는 곳을 고르거나'`(기준 0 → 1), `grep -c 'label: "바꿀 장소"'` 또는 줄 공장 정의를 가리키는 꼴(기준 0 → 1, 선언 설명 `:1609`과 구분되게), `grep -c '"점심 장소"'`의 기준 실측값, `grep -c "고칠 일정 '"`(기준 실측). 모델 문구는 동사를 뺀 고정 조각(`'검색으로 찾은 장소는 사용자가 후보에서 직접 골라야 확정돼요'`)으로 센다.

D4. MF-4 — acceptance.md:L189-203 (AC-012·013 스크립트 S-1~S-11), plan.md:L235-287(§9 예) — 입력문의 `지하철,`은 발화 파서의 이동수단 목록(`Shared/AIAssistant.swift:362` — `"지하철로"`, `"지하철 타"` …)에 걸리지 않는다. 생성 도구는 `mode_this_time`·`weeks`를 선언하지 않으므로(`:1515-1578` 선언 키 목록에 없음) 이 값은 카드로만 채워진다. 그래서 S-1·2·3·4·6·7(첫 문장 "카드 없이 등록")·9·10에는 후보 카드 앞에 [이동수단] 실행 전 카드가 뜨고, S-8에는 [이동수단]·[기간] 카드가 [점심 장소] 카드보다 먼저 뜰 것으로 보인다. 운영자 스크립트의 기대 결과가 첫 화면부터 어긋난다(`CLAUDE.md` 공용 메모리 "입력 문구 + 기대 결과를 정확히"). 코드 읽기에서 나온 가설이며 시뮬레이터에서 실행하지 않았다 — Severity: major — Class: blocking — Required fix: 입력문을 `지하철로` 꼴로 바꾸거나(예: "…집에서 출발할게. 지하철로 가고 여유 10분, 알림 10분 전"), 각 S의 기대 열에 실행 전 카드 단계를 적는다. S-8은 `weeks`를 발화로 줄 수 없으므로 "[기간] 줄이 있는 실행 전 카드 → 확인 → [점심 장소] 카드" 순서로 기대를 고친다. plan §9의 예와 §7 잔여 위험도 카드 장수에 맞게 고친다(A-2).

D5. MF-5 — spec.md:L36, plan.md:L14·L291 — "앱 삭제 약 90줄 · 추가·수정 약 110줄(plan.md §3 목록의 합)"이라 적었다. 그러나 §3 표(L112-123)를 더하면 삭제 100(−15 −23 −25 −29 −8), 추가 60(+10 +15 +5 +10 +20), ± 항목 30(±10 ±12 ±4 ±4)이다. 밝힌 산식이 밝힌 수를 내지 않는다(귀속되지 않은 수치) — Severity: minor — Class: blocking(파일 간 수치 모순) — Required fix: 세 자리를 §3 합(예: "삭제 약 100 · 추가 약 60 · 수정 약 30줄, 어림")으로 고치거나, "§3 목록의 합"이라는 출처 표기를 지운다.

D6. A-1 — spec.md:L126 (REQ-009) — 수정 카드의 맥락 줄을 둘지는 운영자 지시 밖의 UX 추가인데, 요구사항에는 출처 표기가 없다(D-3은 문안만 묻는다) — Severity: minor — Class: optional — Required fix: REQ-009 근거에 "맥락 줄의 존재는 〔제안〕"을 적거나, D-3에 "(c) 맥락 줄 없음" 안을 더한다.

D7. A-2 — plan.md:L214, L235-287 — 잔여 위험의 "카드 두 장"은 실행 전 카드를 세지 않았다. 검색 장소가 있는 반복 + 점심은 최대 세 장이고, 이동수단을 말하지 않은 단발 등록도 이 SPEC 뒤로는 늘 두 장이다(이전에는 정확·유일 일치면 한 장) — Severity: minor — Class: optional — Required fix: §7·§9 ①에 장수 변화를 적는다.

D8. A-3 — acceptance.md:L124-136 (AC-008 점심) — `grep -n 'lunch_place_query\|makeStayingRecurrence(\|…'`가 잡는 것은 인자를 **읽는** 줄(`:2244`)과 정의(`:2084`·`:2104`·`:1567`)다. 해석(검색) 호출 줄을 잡지 못해, 읽기만 위로 올리고 해석은 저장 뒤에 남겨도 대조가 통과할 수 있다 — Severity: minor — Class: optional — Required fix: 대조 대상을 "점심 질의로 부르는 `adoptPlace(` 줄"로 못 박고, 범위를 `awk '/func executeCreateRecurringSchedule/,/^    }$/'`로 자른 뒤 `grep -n 'adoptPlace(\|store.addRecurringEvents(\|makeStayingRecurrence('`을 돌린다.

D9. A-4 — plan.md:L121-122, §7 "죽은 코드" 행 — REQ-008 뒤 `resolveDestination(_:creation:)`의 `creation`을 `true`로 부르는 곳이 없어진다(현재 유일 `:2250`). 죽은 매개변수가 남는다 — Severity: minor — Class: optional — Required fix: D-5 또는 plan §3에 "creation 인자 제거 또는 유지"를 한 줄 넣는다.

D10. A-5 — plan.md:L116-123 — 거짓이 되는 주석 목록에 `Shared/AIAssistant.swift:34`("실행부 셋")와 `:912-917`(보류 카드 설명 "검색 첫 결과가 이름과 맞지 않아 등록을 멈추고")이 빠졌다 — Severity: minor — Class: optional — Required fix: §3 표에 더한다.

D11. A-6 — spec.md:L107 (REQ-003) — "at most one provider search per query"는 `placeSearch.search` 안의 카카오 → MapKit 폴백(`PlaceSearch.swift:13-18`, 카카오가 비거나 실패하면 두 번째 제공자 호출)과 충돌하는 것처럼 읽힌다. 운영자의 "빈 결과는 현행 notFound 그대로"는 그 폴백을 포함한 현행이다 — Severity: minor — Class: optional — Required fix: "one call to the place-search service per query"로 바꾸고 폴백은 §4 범위 밖임을 이어 적는다.

D12. A-7 — plan.md:L171, acceptance.md:L104 (AI-19) — 인자 모양으로 쓴다고 한 AB-H10(`Tools/GuardDriver.swift:2470-2473`)에는 `mode_this_time`·`buffer_minutes`·`notify_lead_minutes`가 없다. 목적지를 '회사'로 바꿔 머무르지 않는 반복이 되면 보류 카드에 이동수단·여유·알림 줄이 함께 뜬다(`askFields` `:553-557`). 그러면 (a)의 줄 검사와 (b)의 확인(`isReady`)이 달라진다. 또 `drvPark`는 첫 실행을 건너뛰므로 (b)의 "한 번 만든 수"는 이중 생성을 관측할 수 없다(AC-008·S-8이 맡는다는 점을 적어야 한다) — Severity: minor — Class: optional — Required fix: 픽스처에 세 값을 넣는다고 명시하고, (b)의 한계를 적는다.

D13. A-8 — plan.md:L307 — `@MX:ANCHOR`를 `placeAdoptionDecision`에 두기로 했지만, 이 함수의 앱 호출처는 `adoptPlace` 하나다. 호출이 많은 쪽(3개 이상)은 `adoptPlace`다(호출처 7곳 이상) — Severity: minor — Class: optional — Required fix: ANCHOR를 `adoptPlace`로 옮기거나 둘 다에 둔다.

D14. A-9 — research.md:L45 — "주소가 같거나 비면 `이름 · 좌표`"는 부정확하다. 첫 선택이 `이름` 열쇠를 차지하면, 같은 주소의 둘째 선택도 `이름 · 주소` 열쇠는 비어 있으므로 그 열쇠를 쓴다(`:1084-1089`). 결론(서로 덮지 않음)은 같다 — Severity: minor — Class: optional — Required fix: "주소가 비면 `이름 · 좌표`"로 고친다.

D15. A-10 — plan.md:L164-165 (D-5 (a)의 AA-1·AB-H04 삭제) — 단언을 지우면 `let aaT = fresh()`(`Tools/GuardDriver.swift:1895`)·`let h4 = fresh()`(`:2280`)가 쓰이지 않는 바인딩으로 남을 수 있다. 드라이버 컴파일 경고라 게이트 대상은 아니다 — Severity: minor — Class: optional — Required fix: run 지시에 바인딩도 함께 지운다고 적는다.

## 회귀 확인

1회차라 해당 없다.

## 권고 (manager-spec · 오케스트레이터)

1. **오케스트레이터(MF-1)**: D-1~D-6을 착수 승인 전에 운영자에게 묻는다. 권장안과 다른 답이 나오면 manager-spec이 의존 REQ·AC를 다시 쓴다.
2. **manager-spec(MF-2)**: spec.md L64·L99·L111·L128과 plan.md L199의 `:1087`/`:1092`를 `:3087`/`:3092`로 고친다.
3. **manager-spec(MF-3)**: AC-009 둘째 행을 고정 부분 문자열 grep 목록으로 바꾸고, 기준 트리 값을 실측해 적는다(`바꿀 장소` 1 · `점심 장소` 4 · `고칠 일정` 1이 이미 있다).
4. **manager-spec(MF-4)**: S-1~S-11 입력문을 `지하철로` 꼴로 바꾸거나 실행 전 카드 단계를 기대에 넣는다. S-8에는 [기간] 줄 카드를 넣고, plan §9 예·§7 잔여 위험을 함께 고친다. run 레인이 시뮬레이터 첫 단계에서 이 가설을 확인하게 한다.
5. **manager-spec(MF-5)**: 변경량 어림을 §3 합과 맞추거나 출처 표기를 지운다.
6. 권고 A-1~A-10은 오케스트레이터 재량이다. A-2·A-3·A-7은 MF-4·AC 정밀도와 붙어 있어 같은 수정에 묶는 편이 싸다.

재감사(2회차)는 위 D1~D5의 해소 여부만 대조하면 된다.

---

## 확인하지 않은 것 (증거 없음 ≠ 통과)

- **드라이버·iOS 빌드·시뮬레이터 — 실행하지 않았다.** AI-14~16의 기준 트리 ✗와 MF-4는 코드를 손으로 따라간 예측이다.
- **교차 모델 감사(`audit_multi`, 설정 `audit: model: multi`, codex off · glm advisory) — 호출하지 않았다.** MCP 서버는 주 체크아웃을 읽고, 이 SPEC은 워크트리에만 있다(호출자가 `spec_audit`를 금지한 것과 같은 이유). GLM은 advisory 게이트라 결과에 영향이 없다.
- **카카오 실목록, 모델의 실제 응답** — 볼 수단이 없다.
- `Shared/AIAssistant.swift`의 `:1-340`·`:1560-1686`·`:1785-1905`·`:2280-2340`·`:2384-2690`은 grep으로만 훑었다(채택 호출처가 없다는 것만 확인).
- AC-004가 이름을 든 P-3(`Tools/GuardDriver.swift:1771`)·AD-E5(`:2997`)·O-단발(`:667`)은 존재만 확인했고, 결과는 t42 로그의 ✓를 믿었다.
- 드라이버 확인 재실행 경로에서 보류 인자 가운데 비우지 않은 비즐겨찾기 장소가 검색으로 흘러가는 단언이 없다는 주장은 `drvExecuteTool`·`drvCreate`·`drvCreateRecurring` 인자 전수(즐겨찾기·일반명사·토큰만)로 확인했다. `drvPark(` 27줄(`grep -c`)의 입력 전수는 하지 않았다.

## 잔여 위험

- D-1 (a)와 D-2 (a)를 함께 고르면 조회 답의 장소가 제공자 첫 결과로 돌아간다(문서가 스스로 적었다).
- 검색 장소마다 카드가 서므로 t32(한 턴 여러 호출의 요약 소실)를 지나는 빈도가 오른다(문서가 스스로 적었다).
- 같은 이름 칩이 늘면 주소가 빈 MapKit 폴백 결과는 화면에서 구별되지 않을 수 있다(research §3(나)가 언급했다).

🗿 MoAI
