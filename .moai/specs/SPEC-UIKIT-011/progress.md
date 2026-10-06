# SPEC-UIKIT-011 — progress.md

칸반 카드 **t47** · 장소 채택 항상-선택. 2026-10-06 plan 레인(`manager-spec`, 서브에이전트)이 작성했다. 워크트리 `.claude/worktrees/t47`(브랜치 `WT-always-select`), 기준 트리 `d900a78`(코드는 t42 병합 `4987e2d`와 같다).

## §E.1 Plan-phase Audit-Ready Signal

- **Phase 1(소크라테스 인터뷰): SKIP** — 명확도 8 이상. 카드 본문이 운영자 지시 원문(원칙·①~⑤·자동 유지 경계·t45 일관성·동반 부채 R-5)을 그대로 싣고 있어 무엇을 바꿀지는 이미 정해져 있다. 지시만으로 정해지지 않는 자리는 인터뷰가 아니라 결정 D-1~D-6(`plan.md` §2)으로 착수 승인 게이트에 올린다.
- **Phase 4 방식: serial** — 서브에이전트를 띄우지 않고 이 레인이 직접 읽고 썼다(오케스트레이터 지시 "Do not spawn other agents").
- **Tier: M**(`plan.md` §0 — 결정 D-6 (a)로 확정). REQ 15 · AC 13.
- **산출물**: `spec.md` · `plan.md` · `acceptance.md` · `research.md` · `progress.md`(이 파일). `research.md`는 오케스트레이터 지시로 추가했다.
- **작성 주체와 범위**: 다섯 파일 모두 이 레인이 썼다. 이 SPEC 디렉터리 밖에는 쓰지 않았고 코드·빌드·드라이버 실행·커밋을 하지 않았다.
- **SPEC 번호**: 010은 반려된 t45의 번호라 쓰지 않았다(`/Users/iseongmin/Projects/besir/.moai/reports/t45/SPEC-UIKIT-010/` 보존). 011 중복 없음(아래 표).
- **게이트 표식**: 0.1.x에서는 `plan.md` §2에만 6건(D-1~D-6)이었고 `spec.md`·`acceptance.md`에는 두지 않았다. **0.2.0에서 운영자가 6건을 모두 확정해 다섯 파일 전부 0건이다**(아래 0.2.0 절의 계수).
- **신호 줄**: 0.1.x까지는 이 레인이 적지 않았다(감사 뒤 오케스트레이터 몫). 0.2.0의 결정 반영 마무리 레인이 리드 지시로 이 절 끝에 두 줄을 적었다(맨 아래 "플랜 게이트 상태").

### 관측된 증거 — 이 레인이 직접 돌린 명령

| 명령 | 관측된 출력 | 쓰인 곳 |
|---|---|---|
| `git rev-parse --short HEAD` · `git branch --show-current` | `d900a78` · `WT-always-select` | 기준 트리 |
| `git diff --quiet 4987e2d HEAD -- Shared Tools proxy project.yml; echo $?` | `0` | 코드 = t42 병합 |
| `git diff --quiet 1375587 4987e2d -- Shared Tools; echo $?` | `0` | t42 sync 로그(1375587 트리)를 이 트리의 기준으로 읽는 근거 |
| `ID="SPEC-UIKIT-011"; [[ "$ID" =~ ^SPEC(-[A-Z][A-Z0-9]*)+-[0-9]{3}$ ]] && echo PASS \|\| echo FAIL` | `PASS` | frontmatter `id` |
| `ls .moai/specs \| grep -c SPEC-UIKIT-011`(워크트리 · 주 체크아웃) | `0` · `0` | 중복 없음 |
| `wc -l Shared/AIAssistant.swift Tools/GuardDriver.swift` | `3258` · `5068` | spec §0 |
| `grep -n 'func adoptPlace\|enum PlaceAdoption\|func placeAdoptionDecision\|…' Shared/AIAssistant.swift` | `:485` askFields · `:746` placeRow · `:852` unclearPlaceNote · `:859` pendingAsk · `:886` filledValueLabels · `:918` parkForUnclearPlaces · `:1083` confirmedPlaceKey · `:1207` resolvePendingAsk · `:1358` locallyResolvedPlace · `:1688` missingAskedArguments · `:2953` resolveOrigin · `:2964` resolveOriginAdoption · `:3070` PlaceAdoption · `:3081` adoptPlace · `:3117` normalizedPlaceWord · `:3136` searchTopClearlyMatches · `:3148` suffixStrippedRetryQuery · `:3172` placeAdoptionDecision · `:3195` mergedPlaceResults · `:3206` resolveDestination | spec §1 · research §2 |
| `grep -n 'resolveDestination(\|resolveOrigin(\|resolveOriginAdoption(\|adoptPlace(\|parkForUnclearPlaces(\|…' Shared/*.swift` | 등록 `:1749`·`:1768`·`:1931`·`:1949`·`:1952`·`:2161`·`:2174` · 보류 `:1775`·`:1962`·`:2181` · 평탄화 호출 `:2250`·`:2703`·`:2762`·`:2765`·`:2813` · 재시도 `:3101` · 병합 `:3103` | spec §1.2 · plan §2 D-1 |
| `grep -n '"new_place_query"\|"lunch_place_query"' Shared/AIAssistant.swift` | 선언 `:1567`·`:1609` · `:2104` · `:2244` · `:2812` | REQ-015(선언 키 무변경) |
| `awk` 열람 `:425-476`·`:480-1103`·`:1104-1180`·`:1180-1380`·`:1686-1785`·`:1905-1990`·`:2084-2118`·`:2120-2280`·`:2354-2384`·`:2690-2941`·`:2940-3258` | `placeRow` 기본 갈래 `:752` · 주입 `:1238` · 재계산 `:1249` · 턴 종료 `:452` · 점심 해석 `:2250` > 첫 저장 `:2202` | research §3·§4 |
| `sed -n '300,379p' Shared/EditCardView.swift` · `grep -n 'struct Place' -A6 Shared/Models.swift` | `ForEach(places, id: \.self)` `:349` · 주소 줄 `:365-367` · `Place: Codable, Equatable, Hashable` `:111` | research §3 (나) |
| `sed -n '1,30p;108,140p' Shared/PlaceSearch.swift` | 카카오 → MapKit 폴백 `:13-18` · `try?` `:14`·`:122`(0.1.1 정정 — 0.1.0은 `:121`로 적었다) | 위험 렌즈 |
| `grep -c 'drvCheck(' Tools/GuardDriver.swift` · `grep -n 'func drvCheck'` | `507` · `:34` | plan §5(하한 근거로 쓰지 않음) |
| `awk 'NR>=4947 && NR<=5058' Tools/GuardDriver.swift \| grep -c 'drvCheck('` | `18` | AI절 단언 수 |
| `grep -n 'drvTopMatches(' Tools/GuardDriver.swift \| wc -l` | `9`(정의 1 + 8) | D-5 |
| `grep -c 'drvAdoption(' Tools/GuardDriver.swift` | `13` | AC-011 3 |
| `grep -c 'searchTopClearlyMatches(' Shared/AIAssistant.swift` · `grep -c 'normalizedPlaceWord('` · `grep -c 'placeSearch.search('` | `4` · `7` · `3` | D-5 · AC-003 |
| `grep -c 'suffixStrippedRetryQuery\|mergedPlaceResults'`(AIAssistant · GuardDriver) · `grep -c 'drvRetryQuery\|drvMerged' Tools/GuardDriver.swift` | `6` · `2` · `10` | AC-003 양성 대조 |
| `grep -c 'searchTopClearlyMatches\|normalizedPlaceWord\|drvTopMatches\|drvRetryQuery\|drvMerged'`(AIAssistant · GuardDriver) | `13` · `20` | AC-011 4 양성 대조 |
| `grep -c` `확실하지 않아요` · `이름이 다른 곳이나` · `첫 결과를 그대로 쓴다` · `평탄화가 그대로다` · `유일 일치`(AIAssistant) | `1` · `1` · `1` · `1` · `1` | AC-009 양성 대조 |
| `grep -c '"type": "[a-z]' Shared/AIAssistant.swift` | `0` | AC-011 6 |
| `awk '/static func placeAdoptionDecision/{f=1} f&&/^    \/\/\//{exit} f' Shared/AIAssistant.swift \| grep -c 'isSamePlace\|\.contains('` · 같은 범위 `wc -l` | `2` · `19` | AC-002 양성 대조(명령이 판정 본문만 자른다) |
| `grep -n 'parkForUnclearPlaces(tool: "update_schedule"\|store.modifyActivity(\|store.modifyEvent('` | `:2824` · `:2842`(보류 호출 0줄) | AC-008 양성 대조 |
| `grep -n 'lunch_place_query\|makeStayingRecurrence(\|store.addRecurringEvents('` | 머무는 갈래 `:2185`·`:2196` · 첫 저장 `:2202` · 점심 해석 `:2244`(질의)·`:2250`(해석) · 점심 저장 `:2252`·`:2257` | AC-008 — 기준 트리에서 "점심 < 첫 저장" 대조가 실패한다 |
| 장소 질의 리터럴 전수: `grep -o '"\(destination_query\|origin_query\|place_query\|travel_from_query\|return_to_query\|new_place_query\|lunch_place_query\)": *"[^"]*"' Tools/GuardDriver.swift \| sort \| uniq -c` | `"origin_query":"집"` 55 · `"destination_query":"회사"` 34 · `"place_query":"집"` 26 · `"destination_query":"집"` 21 · `"place_query":"회사"` 13 · `"destination_query":"스타벅스 홍대점"` 12 · … · `new_place_query` 0 | research §5 · AC-004 |
| 비즐겨찾기 리터럴 위치 `grep -n '"스타벅스 홍대입구역점"\|"OO빌딩 로비"\|"가산 오피스"\|"J-강남역"\|…'` · `grep -n -A3 'drvExecuteTool('` 중 비즐겨찾기 | 전부 `drvPark`·`drvConfirmPlace`·그 절의 즐겨찾기 등록(`:1378`·`:1587`)·`drvAsk` 안. 실행 호출의 비즐겨찾기는 `J-강남역`(즐겨찾기)·`학교`(일반명사 가드)·`우리집`(즐겨찾기) | research §5 — 검색 결과 채택에 기대는 실행 단언 없음 |
| `sed -n '1888,1910p;2272,2290p;4935,5068p' Tools/GuardDriver.swift` · `awk 'NR==…'` 좌표 확인 | AA-1 `:1896-1907` · AB-H04 `:2281-2286` · `aiPl` `:4954` · AI-8 `:5013-5018` · 불변식 `:5055` | plan §5 |
| t42 로그 `grep -n '통과$\|대조 통과'` · `grep -n 'AI-\|AI절'` · `grep -c '✓'`·`'✗'` · `grep -c '✓ AA-1:'`·`'✓ AB-H04'`·`'✓ AI-'`·`'불변식: AI절'` on `/Users/iseongmin/Projects/besir/.moai/reports/t42/gate-sync-driver.log` | `:577 492/492 통과` · `:578 [실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다` · AI절 `:551-572` · `492` · `0` · `6` · `2` · `18` · `3` | REQ-013 기준 · plan §5 산술 |
| `moai todo \| grep 't47\|t32\|t43\|t44\|t30'` | t47 `picked`(본문 원문) · t32·t30·t35·t44 `queued` · t43 `picked` | spec §1.1·§1.4 |
| `grep -n '492' plan.md CHECKLIST.md` | 루트 `plan.md:457`(다음 카드 하한 492) · `CHECKLIST.md:22`·`:311` | REQ-013 |
| `sed -n '583,585p' plan.md`(grep으로 찾음) | 후속 31·32·33 원문 | spec §1 · plan §2 |
| `head` `/Users/iseongmin/Projects/besir/.moai/reports/t45/plan-progress.md` | 반려 결정 원문("계속 물어보게 유지" · "애초에 굳이 같은 장소로 보지 않음") | REQ-006 |
| `grep -n 'R-5' .../t42/code-safety-sync.md` | `:115` "R-5(드라이버 중복 호출) 동의" | 동반 부채 |

### 0.1.1 개정 — plan 감사 1회차 반영 (2026-10-06)

- 입력: `.moai/reports/plan-audit/SPEC-UIKIT-011-review-1.md`(FAIL 0.75 — 필수 MF-1~MF-5, 권고 A-1~A-10)와 오케스트레이터의 반영 지시. 코드는 무변경.
- **수치 전후**: REQ 15 → 15 · AC 13 → 13 · 게이트 표식(plan.md) 6 → 6(다른 네 파일 0 → 0). 결정 D-3에 안 (c)(맥락 줄 없음)를 더했고, D-5 (a)의 내용에 `creation` 매개변수와 빈 바인딩 정리를 더했다 — 표식 문장 자체는 손대지 않았다.
- **반영하지 않은 것 — 한 줄씩**:
  - MF-1(미해소 게이트 표식 6건): 오케스트레이터 지시대로 반영하지 않는다 — D-1~D-6은 운영자가 착수 승인에서 정한다. 표식과 〔제안〕 권장안은 그대로다.
  - 그 밖의 권고(A-1~A-10)는 모두 반영했다. 반영하지 않은 권고는 없다.

| 대응 | 바꾼 곳 |
|---|---|
| MF-2 줄번호 | spec §1.2·§2 A [EXISTING]·REQ-005·REQ-010, plan §7 카카오 할당량 행(`:1087`/`:1092` → `:3087`/`:3092`, `:1362`) · 추가로 찾은 어긋남: `PlaceSearch.swift:121` → `:122`(plan §7·acceptance 경계표·research §2·이 파일 §E.1 표), research §4 `:2116` → `:2115`. HISTORY 0.1.0의 "전부 명령으로 쟀다"를 사실대로 낮췄다 |
| MF-3 AC-009 | 문안 행을 고정 조각 6개의 `grep -c -F` 명령과 실측 기준값으로 바꿨다. 조각 고르는 규칙(자리표시·조립 동사를 피한 가장 긴 고정 문자열, 줄 재료는 `label: "…"` 꼴)을 적었다 |
| MF-4 스크립트 | 스크립트 머리에 파서·카드 순서 가설 문단, S-1~S-10 입력을 `지하철로 가고 여유 10분, 알림 10분 전` 꼴로, S-3 `여유 0분`·`알림 출발 시각`(파서가 못 잡는다) 교체, S-8 `4주` 삭제와 [반복 기간] 카드 단계 추가, S-7 첫 문장을 가설로 표기, S-9 둘째를 [출발지] 실행 전 카드로 |
| MF-5 변경량 | plan §3에 합 줄(삭제 약 100 · 추가 약 60 · 고쳐 쓰기 약 40, D-5 (b)면 삭제 약 70), spec §0·plan §0·plan §9 ②를 그 수치로 통일. 드라이버는 줄 수 어림을 빼고 단언 수로만 |
| A-1 | REQ-009에 맥락 줄 = 〔제안〕 출처 문장, plan D-3에 (c), AC-009·S-7에 (c) 분기 |
| A-2 | plan §7 잔여 위험·§9 머리 문단·예 5에 카드 장수(단발 두 장, 반복 + 점심 최대 세 장) |
| A-3 | AC-008을 함수 본문 자르기(`awk '/func …/,/^    }$/'`) + 해석 호출(`adoptPlace(`·`resolveDestination(`) 대조로 |
| A-4 | spec REQ-014·plan D-5 (a)·§3·§7에 `resolveDestination`의 `creation` 매개변수, AC-011 4에 계수 |
| A-5 | spec §1.3 (마)·plan §3에 주석 `:34`·`:912-917` |
| A-6 | REQ-003을 "place-search service 호출 1회"로, 카카오 → MapKit 폴백은 그대로임을 명시 |
| A-7 | plan §5·acceptance AC-006에 AI-19 픽스처의 세 값과 `drvPark` 한계 |
| A-8 | plan §10 ANCHOR를 `adoptPlace`로(직접 호출 6곳 실측), 판정 함수는 NOTE |
| A-9 | research §3 (나)의 열쇠 서술 정정 |
| A-10 | plan D-5 (a)·§7, acceptance AC-011 4에 빈 바인딩 `aaT`·`h4` 정리 |

| 0.1.1 때 이 레인이 돌린 명령 | 관측된 출력 | 쓰인 곳 |
|---|---|---|
| `grep -n ':1087\|:1092' .moai/specs/SPEC-UIKIT-011/*.md`(수정 전) | spec `:64`·`:99`·`:111`·`:128` · plan `:199` | MF-2 |
| 세 문서의 맨몸 인용 수집 `grep -o` + `sort -n -u` → 해당 줄 출력(`awk 'BEGIN{split(…)} (NR in w)'` on AIAssistant · `awk 'NR==…'` on PlaceSearch·GuardDriver) | 수정 뒤 167종(`grep -o '`:[0-9]\{2,4\}'` … `\| sort -n -u \| wc -l` — 수정 전 종수는 세지 않았다). AIAssistant 인용은 전부 주장과 맞고(`:1087`·`:1092` 제외), PlaceSearch `:121`은 `let search = MKLocalSearch(…)`이고 `try?`는 `:122` | MF-2 전수 |
| `awk 'NR==…'` research 표본(`:501`·`:535`·`:559`·`:635`·`:874`·`:1222`·`:1247`·`:1308`·`:1688`·`:2136`·`:2139`·`:2213`·`:2268`·`:2368`·`:2741`·`:2953`·`:2960`) | 전부 주장과 맞음 · `executeCreateRecurringSchedule` 선언은 `:2115` | research §4 정정 |
| `grep -c -F` `바꿀 장소` · `점심 장소` · `고칠 일정` · `고칠 일정 '` · `검색 결과예요. 맞는 곳을 고르거나` · `검색으로 찾은 장소는 사용자가 후보에서 직접 골라야 확정돼요` · `label: "바꿀 장소"` · `label: "점심 장소"` · `그 카드의 일만 진행돼요` · `고치지 않았어요` | `1` · `4` · `1` · `0` · `0` · `0` · `0` · `0` · `0` · `1`(`:2806`) | MF-3 · AC-009 |
| `grep -n '"지하철로"' Shared/AIAssistant.swift` · `awk` 범위 `statedArguments` · `minutes(in:near:)` | `:362` · `:349-355` · `:2533-2556`(N > 0만, `여유`·`알림` 근처 12자) | MF-4 |
| `awk 'NR>=1500 && NR<=1600' Shared/AIAssistant.swift \| grep -n '"name": "create\|mode_this_time\|buffer_minutes\|notify_lead_minutes\|"weeks"'` | 생성 세 도구 선언에 네 키 없음(나온 `buffer_minutes`·`notify_lead_minutes`는 `update_recurring_schedule` 선언) | MF-4 · plan §7 |
| `awk '/func executeCreateRecurringSchedule/,/^    }$/{print NR": "$0}' … \| grep 'adoptPlace(\|resolveDestination(\|store.addRecurringEvents(\|makeStayingRecurrence('` · 같은 범위 `wc -l` | `:2174` · `:2185` · `:2196` · `:2202` · `:2220` · `:2250` · `:2252` · `:2257` · 180줄(`:2115-2294`) | A-3 · AC-008 양성 대조 |
| `awk '/func executeUpdateSchedule/,/^    }$/{print NR": "$0}' … \| grep 'parkForUnclearPlaces(\|store.modifyActivity(\|store.modifyEvent('` | `:2824` · `:2842`(보류 0줄), 범위 `:2785-2861` | AC-008 |
| `grep -n 'creation: Bool' Shared/AIAssistant.swift` · `grep -c 'resolveDestination(q, creation: true)'` | `:3081`(기본값 없음) · `:3206`(`= false`) · `1` | A-4 · AC-011 4 |
| `grep -n 'adoptPlace(' Shared/AIAssistant.swift` | 호출 `:1768`·`:1931`·`:1952`·`:2174`·`:2972`·`:3207` | A-8 |
| `awk 'NR==1895\|\|NR==2280' Tools/GuardDriver.swift` · `grep -n '\baaT\.' \| wc -l` · `grep -n '\bh4\.' \| wc -l` · `grep -c 'let aaT = fresh()\|let h4 = fresh()'` | `let aaT = fresh()` · `let h4 = fresh()` · `6` · `2` · `2` | A-10 |
| `grep -c 'drvPark(' Tools/GuardDriver.swift` · `grep -n -A6 'drvPark(' … \| grep '_query"\|key:' \| grep -v '"집"\|"회사"'` | `27` · 비즐겨찾기 장소 질의는 전부 보류 키(`key:`)로 들어가 있거나 토큰이다(`AB-확정제외2` `:2313-2315`는 `drvAsk`라 실행하지 않는다) | 감사 "확인하지 않은 것" 마지막 항 보충 |
| `moai spec lint --strict .moai/specs/SPEC-UIKIT-011/spec.md`(0.1.1) | 아래 Gaps 마지막 줄 | MP-3 |

### 0.1.2 개정 — plan 감사 2회차 반영 (2026-10-06)

- 입력: `.moai/reports/plan-audit/SPEC-UIKIT-011-review-2.md`(FAIL 0.86 — 필수 N-1·N-2, 권고 B-1~B-4)와 오케스트레이터의 반영 지시. 코드는 무변경.
- **수치 전후**: REQ 15 → 15 · AC 13 → 13 · 게이트 표식(plan.md) 6 → 6(다른 네 파일 0 → 0). 표식 문장은 손대지 않았다.
- **반영하지 않은 것**: 없음(N-1·N-2·B-1~B-4 모두 반영). 게이트 표식 6건은 운영자 결정 대기라 지시대로 두었다.

| 대응 | 바꾼 곳 |
|---|---|
| N-1 제목 줄 | acceptance 스크립트 머리 문단에 제목 사유(`:1463`·`:505`·`:653-654`, `create_schedule` 선언 `"required": []`), S-1~S-10의 등록 입력 11개 전부에 `제목은 …`(S-7 첫 문장은 원래 있었다), S-7 기대 문장 · plan §7 잔여 위험의 카드 장수 줄 · plan §9 머리 문단 · "그대로인 것의 예" |
| N-2 D-3 (c) 분기 | acceptance AC-005 AI-18 (b) 행("D-3 (c)면 이 행을 지운다") · AC-011 2(487·495) · plan §5 AI-18 행·더하는 단언 줄(11 → (c)면 10)·총수 조합표 |
| B-1 | acceptance AC-011 4에 `func resolveDestination(_ query: String, creation` 계수와 함수 본문 `creation` 계수 |
| B-2 | acceptance AC-008 끝에 한계 문단 — 도우미로 감싸면 그 호출 이름을 패턴에 더하고 §E.2에 적기 · `@MX:WARN` 주석 줄 위치 대조 · S-8 |
| B-3 | plan D-6에 (a)/(b) 표 |
| B-4 | acceptance AC-006 Given · plan §5 AI-19 행의 `:553-557` → `:555-557` |

| 0.1.2 때 이 레인이 돌린 명령 | 관측된 출력 | 쓰인 곳 |
|---|---|---|
| `awk 'NR==505\|\|NR==553\|\|NR==555\|\|…\|\|NR==1463'` on `Shared/AIAssistant.swift` | `:505` `if !filled("title") { fields.append(titleField()) }` · `:553` `else if let q = unknownPlace("origin_query") …` · `:555`~`:557` 이동수단·여유·알림 줄 · `:653-654` `titleField` · `:1463` "목적지·제목도 같다: **사용자가 말한 것만 채운다** — 말하지 않았으면 비워둬라(앱이 카드로 물어본다)" | N-1 · B-4 |
| `awk 'NR>=1500 && NR<=1600' Shared/AIAssistant.swift \| grep -n '"required"'` | 34행째 `"required": []`(create_schedule) · 52행째 `["title", "start_iso", "end_iso"]`(create_activity) · 77행째 `["title", "destination_query", "weekdays", "arrival_time"]`(create_recurring_schedule) · 95행째 `[]` | N-1 머리 문단 |
| `sed -n '175p' plan.md \| grep -o '([a-d]) ' \| sort -u \| wc -l` · `grep -c '^\| AI-18 (' acceptance.md` | `4` · `4` | N-2 — AI-18 하위 단언 수를 세어 확인 |
| N-2 산술(위 계수에서) | 더하는 단언 11 → D-3 (c) 10 · 총수 492−7−8+11=488 · 492−7−8+10=487 · 492−7+11=496 · 492−7+10=495 | plan §5 조합표 · AC-011 2 |
| `grep -c 'func resolveDestination(_ query: String, creation' Shared/AIAssistant.swift` · `awk '/func resolveDestination/,/^    }$/' … \| grep -c 'creation'` · 같은 범위 첫·끝 줄 | `1` · `2` · `:3206`~`:3212` | B-1 기준값 |
| `awk 'NR>=227 && NR<=236' acceptance.md \| grep -o '`[^`]*가야 해[^`]*`\|`[^`]*스터디[^`]*`' \| grep -vc '제목은'` · 같은 추출 `wc -l` | `0` · `11`(S-8은 '가야 해'가 없어 추출 밖 — 열람으로 `제목은 S8 출근` 확인) | N-1 — 제목 빠진 입력 0 |

### 0.2.0 개정 — 운영자 결정 반영 (2026-10-06, 결정 반영 마무리 레인)

- 입력: 리드가 확정해 넘긴 운영자 결정(D-1~D-6 + "원래 질의 재언급 = 의도된 동작")과 절차 — 결정에 기대는 절만 고쳐 쓴다 → 그 차이만 대조한다 → 감사 3회차 권고 C-1·C-2 → §E.1에 audit-ready 두 줄 → SPEC 5종 커밋(card t47). **재감사 없음**(plan 감사 한도 3회 소진, 감사 3회차 조건). 코드는 무변경.
- **재개 때 상태**: 앞 레인이 토큰 한계로 멈춘 자리에 0.2.0 부분 반영의 흔적은 없었다 — 다섯 파일이 전부 0.1.2였고 게이트 표식은 plan 6건 그대로였다(`grep -c`). 그래서 결정 반영을 처음부터 했고, `decisions.md`와 대조해 바로잡을 반쯤 고쳐진 절은 없었다.
- **D-1 (b)의 파급은 "결정에 기대는 절 고쳐 쓰기" 범위 안이다 — blocker 아님.** 근거: REQ 15 · AC 13 불변, 새 파일 없음, 고친 절은 0.1.2에서 이미 "결정에 기대는 절"로 표시돼 있던 곳이다(`plan.md` 0.1.2 D-1 (b) 행이 "recommend_meal의 place_query는 새 이름의 줄이 필요"를 적었고 D-5 (a)가 "`resolveDestination` 자체의 호출처가 남는지 다시 센다"를 적었다). 다만 **범위 안이지만 리드가 알아야 할 파생 넷**이 있다 — ① `placeRow`가 키 외에 도구를 받아야 한다(식사 추천의 `place_query`가 "활동 장소" 줄로 떨어지므로) ② `resolveDestination`·`resolveOrigin`이 호출처 0으로 통째로 죽는다(D-5 (a) 확장) ③ **조회 문구 `조회하지`·`기준 장소`는 운영자가 본 D-3 원문에 없던 말**이다(원문 동사 자리·선언 설명 `:1635`를 그대로 쓴 꼴 — `plan.md` §4 끝에 파생 표시) ④ 조회 단언 AI-21·22 4건과 시뮬레이터 S-12가 늘었다.
- **수치 전후**: REQ 15 → 15 · AC 13 → 13 · 게이트 표식 6 → 0 · 더하는 단언 11 → **15**(AI-21 2 + AI-22 2) · 지우는 단언 15 · **총수 T 488(D-5 (a) 기준 0.1.2) → 492**(= 492 − 15 + 15 — 기준과 같은 수는 삭제와 추가가 상쇄한 결과일 뿐이다) · 앱 변경량 삭제 약 100 → 약 130, 추가 약 60 → 약 90, 고쳐 쓰기 약 40 → 약 30(손으로 어림 — `plan.md` §3 표의 합, 고쳐 쓰기는 ±10·±12·±4·±6 합 32 → "약 30"으로 낮췄다).
- **반영하지 않은 것**: 없음. 감사 3회차 **C-1**은 "추가 11"에 "(D-3 (c)면 10)"을 덧붙이라는 것이었으나 D-3이 (a)로 닫혀 분기 자체가 사라졌다 — 세 자리(spec §0·plan §0·§9 ②)가 확정 수치(추가 15)만 적는다. **C-2**는 `acceptance.md` AC-008 한계 문단 (2)에 존재 조건(본문 안 `@MX:WARN` 정확히 1줄, 기준 0, 그 줄 < 첫 `store.addRecurringEvents(`)으로 넣었다.

| 고쳐 쓴 절 | 무엇을 |
|---|---|
| `spec.md` | frontmatter(version 0.2.0 · title · tags) · HISTORY 0.2.0 · §0(성격·예산 표 · Tier 사유) · §1.1(조회 행 신설) · §1.2(평탄화 넷 → 호출처 다섯이 삼태로) · §1.3 (가)(조회 줄 재료)·(마)(주석 목록)·(바)(D-1이 닫음) · REQ-002(제공자 순서 확정) · REQ-009(`place_query` 식사 추천 줄·`기준 장소`·맥락 줄 확정) · REQ-011(확정 문안·조회 동사) · [DELTA] B 머리 · **[DELTA] D와 REQ-012 전면** · [DELTA] E · REQ-013(하한 산술) · **REQ-014 전면**(래퍼 둘 삭제) · REQ-015(선언 인용 추가) · §3(확정 문장·조회 이름 없는 기준) · §4(t32 조회·일반명사 가드 표기·식사 추천 폴백) · §5(확정 표) |
| `plan.md` | 머리·출처 표기(〔확정〕) · §0 표 · §1 마일스톤(M5 조회 카드, 컴파일 결합) · **§2 전면**(확정 기록 + D-1 구현 모양 표) · §3 변경 목록·합 · §4 문안(확정 + 조회 행 셋 〔파생〕) · §5(AI-21·22 신설·분기 접기·총수 산술·드라이버 한계) · §6 마지막 줄 · §7 (await·try?·할당량·같은 계산·죽은 코드 행, 잔여 위험) · §9 예 6·7과 ②④⑤ · §10 MX |
| `acceptance.md` | 서두 · 매트릭스(AC-010·013) · AC-002(AI-16) · AC-005(AI-18 (b)) · **AC-008**(D-4 (b) 삭제 + C-2) · AC-009(계수 둘 추가·확정 표기) · **AC-010 전면** · AC-011 2·4(총수·래퍼 이름 계수) · AC-013 · 스크립트 S-7·S-11 고침·S-12 신설 · 경계표 · 품질 게이트 |
| `research.md` | §1(추가 열람) · §3 (마) 신설 · §6 2·3 |

| 0.2.0 때 이 레인이 돌린 명령 | 관측된 출력 | 쓰인 곳 |
|---|---|---|
| `git rev-parse --show-toplevel` · `git log --oneline -1` · plan.md의 게이트 표식 계수(`grep -c` — 표식 문자열은 이 표가 표식으로 읽히지 않게 적지 않는다) | 워크트리 `…/worktrees/t47` · `d900a78` · `6`(재개 시) | 전제 검증 |
| `moai spec lint --strict spec.md`(0.2.0) | `✓ No findings — all SPEC documents are valid`(exit 0) | MP-3 |
| `grep -c '^- \*\*REQ-' spec.md` · `grep -c '^## AC-' acceptance.md` | `15` · `13` | 수치 전후 |
| 게이트 표식 계수(다섯 파일 각각) | spec 0 · plan 0 · acceptance 0 · research 0 · progress 0 | 표식 6 → 0 |
| 새로 인용한 줄 51개를 `awk 'NR in set'`으로 출력(`:640` `:644` `:659` `:669` `:673` `:748` `:749` `:752` `:1063` `:1193` `:1238` `:1303` `:1316` `:1319` `:1567` `:1609` `:1635` `:1646` `:1647` `:1757` `:1775` `:2301` `:2703` `:2706` `:2712` `:2719` `:2722` `:2730` `:2736` `:2741` `:2762` `:2763` `:2765` `:2766` `:2776` `:2778` `:2943` `:2952` `:2953` `:2957` `:2958` `:2962` `:2974` `:2978` `:3046` `:3087` `:3202` `:3205` `:3206` `:3210` `:3212`) | 전부 주장과 맞음(예: `:749` `case "place_query": return activityPlaceField()` · `:1635` `기준 장소 직접 지정` · `:2766` `store.travelEstimates(` · `:3210` `case .unclear … candidates.first`) | 0.2.0에서 새로 인용한 줄 |
| `grep -c 'resolveDestination\|resolveOrigin[^A]'`(AIAssistant · GuardDriver) · `grep -c 'resolveDestination(\|resolveOrigin('` · `grep -c 'func resolveDestination(\|func resolveOrigin('` | `12` · `0` · `7` · `2` — 12줄 = 호출 5(`:2250` `:2703` `:2762` `:2765` `:2813`) + 정의 2(`:2953` `:3206`) + 주석 5(`:640` `:2301` `:2957` `:2962` `:3046`) | AC-011 4 기준 · REQ-014 |
| `grep -c -F` `label: "기준 장소"` · `조회하지` · `기준 장소` · `label: "활동 장소"` | `0` · `0` · `1`(선언 `:1635`) · `1` | AC-009 · AC-010 기준 |
| `grep -c 'creation: Bool = false' Shared/AIAssistant.swift` | `1` | AC-011 4 |
| `awk '/func executeRecommendMeal/,/^    }$/{…}' … \| grep '…'`(+ 줄 수) · 같은 꼴 `executeCheckTravelTime` | 식사 추천 46줄: `:2703` `resolveDestination(` · `:2722` `nearbyPlaces(`(보류·`adoptPlace(` 0줄) · 이동시간 23줄: `:2762` `resolveOrigin(` · `:2765` `resolveDestination(` · `:2766` `travelEstimates(`(보류 0줄) | AC-010 양성 대조 |
| `awk '/func executeCreateRecurringSchedule/,/^    }$/{…}' … \| grep '@MX:WARN\|store.addRecurringEvents('` · `grep -c '@MX:WARN' Shared/AIAssistant.swift` | `:2202` `:2220` `:2252` `:2257`(`@MX:WARN` 0줄) · `0` | C-2 기준 |
| `grep -c 'check_travel_time\|recommend_meal' Tools/GuardDriver.swift` | `0` | 조회 단언은 AI-21·22가 처음 |
| `grep -n 'choose(field' Tools/GuardDriver.swift` · `grep -n 'func choose' Shared/AIAssistant.swift` | 드라이버 호출 `:182`·`:786`·`:937`·`:970`·`:1183-1185`(전부 value 꼴) · `choose(field:place:)` `:1063`은 internal | AC-010 — 후보 고르기는 직접 호출, 새 도우미 불필요 |
| `grep -n 'plan_complete_at\|plan_status' SPEC-UIKIT-008·009 progress.md` | 두 줄 모두 `- 키: 값` 목록 꼴(SPEC-UIKIT-008은 시각까지, 009는 날짜만 적었다) | 신호 줄 서식 — 이 표의 서술이 신호 줄로 읽히지 않게 값을 적지 않는다 |

### 렌즈·기록과 어긋난 자리

1. **AI-8** — 카드는 반전 대상에 넣었으나 기대가 이미 "질문"이다(`Tools/GuardDriver.swift:5013-5018`, 로그 `:562`). R-5만 한다.
2. **조회 경로** — 카드 ③은 쓰기 둘만 적었고 조회 둘(`:2703`·`:2762`·`:2765`)도 같은 평탄화를 쓴다 → D-1 — **운영자가 (b) 조회도 카드로 확정**(0.2.0).
3. **후보 순서** — 카드는 순서를 말하지 않는다. "두 함수가 죽는다"(오케스트레이터 지시)는 D-2 (a)를 전제할 때만 참이었고 **운영자가 D-2 (a)·D-5 (a)를 확정**해 성립했다(0.2.0).
4. **점심 위치** — 지금 자리에서 보류하면 확인이 통근 묶음을 이중으로 만든다 → REQ-008·D-4.
5. **수정·점심 줄 재료** — `placeRow` 기본 갈래 때문에 그대로는 서지 않는다 → REQ-009.
6. **잠재 결함 (나)** — 같은 이름 다른 좌표의 확정 열쇠 충돌을 찾았으나 `confirmedPlaceKey`가 이미 가른다 — 결함 없음, 회귀선(AI-20)만 제안.

### Gaps — plan이 돌리지 않은 것 (증거 없음 ≠ 통과)

- **드라이버 — 미실행.** 기준 492는 t42 sync 레인의 로그(`1375587` 트리, 이 트리와 같은 코드)를 읽은 값이다. 새 하한은 0.2.0 확정안 기준 492(= 492 − 15 + 15)로 산술이고(0.1.2의 488·496은 폐기), run M1의 기준 실행과 마감 실행이 확정한다.
- **iOS 빌드 — 미실행.**
- **카카오 실목록 — 미관측.** 순서·주소 모양·'스타벅스 홍대점'의 실제 결과는 운영자 관찰 한 줄뿐이다. 시뮬레이터 S-1~S-4가 첫 관측이 된다.
- **"검색 결과 채택에 기대는 실행 단언 없음"** — 리터럴 전수와 위치 열람에 근거한 코드 읽기다. 실행으로 확인하지 않았다(run 마감 실행의 ✗ 0이 확인한다).
- **AI-14·15·16·18·19·21 (a)·22 (a)의 기준 트리 ✗, AI-21 (b)·22 (b)의 기준 트리 ✓** — 코드 읽기로 낸 예측이다. run M1이 관측해 §E.2에 적는다.
- **조회 도구 실행(AI-21 (b)·22 (b)) — 드라이버가 처음 지나는 경로**(0.2.0). 경로 계산은 MapKit ETA 폴백이라 네트워크 의존이고 결과가 결정적이지 않아 결과 문구 앞머리만 단언한다 — 앞머리가 성공·실패에 상관없이 같다는 것은 코드 읽기(`:2776`·`:2778`·`:2730`·`:2736`)이고 실행 확인은 run M1이다.
- **모델 행동 — 미관측.** 새 문구 뒤 모델의 응답.
- **AI 일일 할당량 영향 — 미측정**(추론).
- **변경량 어림 — 측정 아님**(`plan.md` §3).
- **`Shared/AIAssistant.swift` 미열람 구간** — `research.md` §7.
- **린트·계수 — 0.1.1에서 다시 실행함**: 같은 다섯 명령의 출력이 아래 0.1.0 값과 같다(`✓ No findings` · `15` · `13` · 0 · 6 · 0 · 0 · 0). 남은 `:1087`·`:1092`는 spec HISTORY 두 행(정정 기록)뿐이다(`grep -n ':1087\|:1092'`). plan 감사 통과 신호 줄은 쓰지 않았다(오케스트레이터 몫).
- **린트·계수 — 0.1.0 때 실행함**: `moai spec lint --strict <이 디렉터리>/spec.md` → `✓ No findings — all SPEC documents are valid` · `grep -c '^- \*\*REQ-' spec.md` → `15` · `grep -c '^## AC-' acceptance.md` → `13` · 게이트 표식 계수(대괄호 꼴, 파일별) → spec 0 · plan 6 · acceptance 0 · research 0 · progress 0.
- **MCP `spec_audit` — 미실행.** SPEC-UIKIT-008 기록상 MCP 서버가 주 체크아웃을 읽어 워크트리 SPEC을 보지 못한다(그 SPEC `progress.md` Gaps). 린트는 워크트리 CLI로 대신했다.

### 잔여 위험

- 검색으로 푸는 장소마다 카드가 선다 — t32 증상(여러 호출 요약 소실)을 더 자주 지난다.
- 조회가 두 단계(카드 → 답)가 된다 — 운영자가 D-1 (b)로 고른 비용이다. 확인 뒤 모델이 조회 결과를 어떻게 말하는지는 미관측(S-11·S-12가 첫 관측). 조회 문구(`조회하지`·`기준 장소`)는 운영자가 본 원문 밖에서 파생됐다.
- D-4 (a)(확정)로 출발지·목적지·점심이 모두 검색 질의인 반복 요청은 카드 두 장을 차례로 지난다.
- 같은 대화에서 원래 질의를 다시 말하면 다시 묻는다(확정 열쇠 = 고른 장소 이름) — 운영자가 이를 결함으로 볼 수 있다(`plan.md` §6).

### 플랜 감사 이력 (plan 레인 오케스트레이터 기록, 2026-10-06)

| 회차 | 판정 | 점수 | 필수 수정 | 보고서 |
|---|---|---|---|---|
| 1 | FAIL | 0.75 | 5 (MF-1 결정 게이트 · MF-2 줄번호 · MF-3 AC-009 기준선 · MF-4 시뮬레이터 스크립트 · MF-5 변경량) | `.moai/reports/plan-audit/SPEC-UIKIT-011-review-1.md` |
| 2 | FAIL | 0.86 | 2 (N-1 제목 줄 · N-2 D-3 (c) 분기) | `…-review-2.md` |
| 3 | PASS (운영자 결정 6건 대기 조건부) | 0.92 | 0 | `…-review-3.md` |
| (결정 반영) | 재감사 없음 — 3회 한도 소진, 감사 3회차 조건대로 "결정에 기대는 절만 고쳐 쓰고 그 차이만 대조" | — | — | 위 "0.2.0 개정" 절의 대조 표 |

- 감사는 `plan-auditor`가 맡았고 작성자(`manager-spec`)와 다른 에이전트다. 오케스트레이터는 매 회차 수정본을 린트·REQ/AC 계수·표식 개수·`audit-ready` 부재·코드 무변경(`git diff --stat 4987e2d -- Shared Tools` 빈 출력)으로 직접 재확인했고, 감사가 짚은 사실(줄번호 `:3087`/`:3092`, 문구 기준선, `:505`·`:1463`)은 코드를 읽어 따로 확인했다.
- 3회차 권고(판정 무관 — **0.2.0에서 처리**: C-1은 D-3이 (a)로 닫혀 단서가 필요 없어졌고 C-2는 AC-008에 반영): C-1 spec §0·plan §0·§9 ②의 "드라이버 단언 추가 11"에 "(D-3 (c)면 10)" 단서 없음 · C-2 AC-008의 `@MX:WARN` 대조에 "본문 안 계수 1(기준 0)" 존재 조건 필요(기준 트리에 `@MX:` 태그가 0건이라 태그가 없으면 통과해 버림). run 착수 전 manager-spec이 반영하는 것을 권한다.
- 한도: plan 감사 반복 한도(3회)를 다 썼다. 이후 변경은 새 감사가 아니라 "결정에 기대는 REQ·AC 절만 고쳐 쓰고 그 차이만 대조"한다(감사 3회차 조건).

### 플랜 게이트 상태 (audit-ready 신호 — 0.2.0에서 기입)

- 0.1.x의 조건은 세 가지였다 — 운영자가 D-1~D-6을 정할 것 · 표식 6건이 결정 결과로 바뀔 것 · 그 차이 대조가 끝날 것. **셋 다 충족했다**: 결정은 2026-10-06 착수 승인에서 확정됐고, 표식은 다섯 파일 모두 0건이며, 고친 절의 차이 대조(린트·계수·인용 51줄 전수·기준 트리 양성 대조)는 위 "0.2.0 개정" 절에 있다.
- 재감사는 하지 않았다(3회 한도 소진, 감사 3회차 조건). 대조의 한계: 이 레인은 드라이버·iOS 빌드·시뮬레이터를 돌리지 않았고(Gaps), 신설 단언 AI-14~22의 기준 트리 ✗/✓는 코드 읽기 예측이다 — run M1이 관측한다.
- 이전 상태: `plan_status: audit-passed-pending-operator-decisions`

- plan_complete_at: 2026-10-06T20:17:16+09:00
- plan_status: audit-ready

## §E.2 Run-phase Evidence

**2026-10-06 run 레인**(직렬 — §F). 구현은 swift-impl 전문가 3회 위임(RED → GREEN → M6·M7), 게이트 실행·대조·커밋은 레인이 직접했다. 드라이버 명령은 전 단계 같은 꼴(`cat Shared/EditCard.swift Shared/AIAssistant.swift Tools/GuardDriver.swift > /tmp/gd-*.swift && swiftc … -parse-as-library && 실행`)이고 swiftc의 macOS 26 deprecation 경고는 알려진 도구 체인 잡음으로 친다(hns-besir-app-verify 필터와 같은 취급).

| 단계(커밋) | 관측된 출력(원문 줄) | exit | 로그(`.moai/reports/t47/`) | 실행 주체 |
|---|---|---|---|---|
| M1 기준(aa15bcc) | `492/492 통과` · `[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다` | 0 | `gate-m1-baseline.log` | 레인 |
| M1 RED(1fb19e3) | `494/507 통과` · ✗ 13 = AI-2·4·5(반전)·14·15·16·18(a)(b)(c)·19(a)(b)·21(a)·22(a) — plan §1 괄호 목록(11건)이 AI-15·19(b)를 빠뜨린 것이고 §E.1 Gaps 예측(13건)·plan §5 AI-15 행과 일치 | 1 | `gate-m1-red.log` | 에이전트 — 레인이 ✗ 줄 전수·`drvCheck(` 계수·diff 범위 대조 |
| GREEN M2~M5(4d48736) | `507/507 통과` · 실데이터 대조 · ✗ 0 | 0 | `gate-m2m5-green.log` | 에이전트 — 레인이 로그·변경 파일 단독·`@MX:WARN` 1줄 위치 대조 |
| M6·M7(61458e1) | `492/492 통과` · 실데이터 대조 · ✗ 0 · ✓ 492 | 0 | `gate-m6m7-final.log` | 에이전트 — 레인이 이름 소멸 grep 3종 재실행(무매치) 대조 |
| M8 마감(HEAD 61458e1) | `492/492 통과` · 실데이터 대조 | 0 | `gate-m8-final.log` | **레인 직접 재실행** |

- **iOS 무경고 빌드(M8, 레인 실행)**: `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build` → exit 0 · `BUILD SUCCEEDED` · `grep "warning:" build-ios.log \| grep -v appintentsmetadataprocessor \| sort -u` → **빈 출력**(Swift 소스 경고 0). 워크트리에 `besir.xcodeproj`가 있어 xcodegen 불필요 — 서명 팀 리셋 없음.
- **REQ-014 이름 소멸**(레인 grep 재실행, 무매치 확인): `suffixStrippedRetryQuery|mergedPlaceResults|searchTopClearlyMatches|normalizedPlaceWord|drvTopMatches|drvRetryQuery|drvMerged` · `resolveDestination` · `resolveOrigin[^A]`(`resolveOriginAdoption` 제외) — 두 파일 모두 0매치.
- **C-2(WARN 위치)**: `@MX:WARN` 파일 전체 1줄(`:2268`) < 첫 `store.addRecurringEvents(`(`:2285`) — 레인 grep으로 대조.
- **범위**: 코드 변경은 두 소스 파일뿐. `git diff --stat 4987e2d..HEAD -- proxy project.yml Shared/EditCardView.swift Shared/PlaceSearch.swift` → 빈 출력(day-close 커밋 포함 전 구간 기준). 앱 변경 실측: GREEN +196/−100 · M6·M7 −150/0(plan §3 어림 삭제 130·추가 90·고침 30과 같은 차수 — 어림이 −81(6함수 정의)을 GREEN 뒤로 미뤄 실측과 순서가 다를 뿐).
- **알려진 마이크로빚**: `placeAdoptionDecision`의 `query` 매개변수가 판정에서 쓰이지 않게 됐다 — 호출처가 값을 주므로 REQ-014(“남는 호출처가 값設定 안 하는 매개변수”) 위반은 아니고, 서명 정리는 후속 몫으로 남긴다.
- **Gaps(미검증 — 증거 없음 ≠ 통과)**: 시뮬레이터 S-1~S-12(AC-012·013 — 실제 카카오 목록·카드 화면·카드 장수·확인 뒤 모델 발화는 운영자 실행 대기) · proxy `npm test`(이 카드가 proxy를 고치지 않아 diff 무변경으로 확인 — 배포 없음) · 실기기. drvPark는 "첫 실행이 저장한 뒤 보류하면 이중 생성"을 못 잰다(plan §5 명시 한계 — 구조 대조 `:2268`<`:2285`와 시뮬레이터 S-8이 담당).
- **잔여 위험**: plan §7 목록 그대로 — 카드 장수 증가(단발 두 장·반복+점심 최대 세 장) · 조회 2단계 · t32 증상 빈도 상승 · 원래 질의 재언급 시 재질의(운영자 확정 동작) · 조회 문구(`조회하지`·`기준 장소`)는 원문 밖 파생(착수 시 고지함).

🗿 MoAI

## §E.3 Run-phase Audit-Ready Signal

_<pending run-phase>_

## §E.4 Sync-phase Audit-Ready Signal

_<pending sync-phase>_

## §F Phase 4 Mode Selection

- **입력**: Tier M · 크게 고치는 파일 2(`Shared/AIAssistant.swift`·`Tools/GuardDriver.swift`) · 도메인 1(Swift/AI 실행부) · 언어 Swift · 병행 이득 낮음(코드 작업 + 컴파일 결합 — plan §1: 드라이버는 앱 파일과 함께 컴파일되고 `resolveDestination`·`resolveOrigin` 삭제는 M4·M5 선행) · Agent Teams 요청 없음.
- **평가**: direct ✗(복잡도 상) · **serial ✅ 선택** · fanout ✗(단일 도메인, 쓰기 충돌) · sweep ✗(30파일 미만·비기계적) · agent-team ✗(요청 없음).
- **Decision: serial** — 마일스톤마다 전문가 한 명씩 순차 호출(RED 드라이버 → 앱 M2~M5 → 정리·마감 M6~M7), 쓰기 에이전트 동시 1명. 코딩 작업 병렬화 주의(Anthropic coding-task parallelism caveat)와 컴파일 결합이 근거.
- **게이트 배경**: Implementation Kickoff Approval(착수 승인)은 2026-10-06 운영자 확정으로 이미 통과(D-1~D-6, `decisions.md`). Phase 1 재감사는 돌리지 않았다 — 감사 3회 한도 소진 + 3회차 조건부 PASS(0.92)의 조건("결정에 기대는 절만 고쳐 쓰고 차이 대조")이 0.2.0에서 이행된 기록이 §E.1에 있다.
- `ac_converge` 골은 arm하지 않았다 — 운영자가 세션 앞에 있고 마일스톤마다 확인하는 흐름이라 per-turn 자율이 필요 없다.

🗿 MoAI
