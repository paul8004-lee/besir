# UI통일 Day 닫기 — code-safety 전수 검사 (card t9, 2026-09-24)

대상 트리: `.claude/worktrees/t9` @ `57f874f` (= origin/master, Day 전체 병합 상태).
범위: CLAUDE.md Day 끝내기 절차 2번(코드 버그 검사)·3번(간결성 검사), 우선 표면 10개
(EditCard·EditCardView·AddEventView·EventDetailView·AddActivityView·ActivityDetailView·
AIAssistant·Store·GuardDriver·proxy/index.js). 읽기 전용 — 고친 파일 없음.

---

## ① 렌즈 4종 결과

### H1 — await 인덱스/스냅숏 무효화

**Store 본류: 0건.** 2026-09-12에 기록된 `firstIndex → await → 배열 쓰기` 4곳은 현재 트리에서
전부 await 뒤 id 재조회 패턴으로 돈다 — `updateRecurringSeries`(Store.swift:755 "await(이동시간
조회) 사이 동기화·삭제로 배열이 바뀔 수 있으니 쓸 때 id로 다시 찾는다"), `updateEvent`(:957),
`refreshUpcomingEstimates`(:1245), `pushToCalendar`(:877), `reconcileActivities`(:1440).
그렵 매치만으로 재보고하지 않았다 — 함수 본문을 전부 읽었다.

**부류 변종(값 스냅숏 경합) 2건 발견 — 둘 다 "늦게 끝난 쪽이 이긴다" 모양:**

1. **`AddEventView.recomputeEstimates` (:464-474) — 확인됨.** 좌표를 `await estimateAll` 앞에서
   잡고(:465-470) 돌아온 뒤 `estimates = all`·`estimating = false`를 무조건 쓴다(:471-472).
   계산 도중 출발지/목적지 칩을 바꾸면 두 비동기 작업이 겨쉬고, 늦게 끝난 **옛** 좌표의 값이
   모드 칩 소요시간·시각 줄 예상 문구(:478-516 syncFieldExtras)·ConflictBanner(:549-567
   currentConflicts)에 남는다. `estimating` 플래그도 먼저 끝난 쪽이 거짓으로 내려 스피너가
   일찍 사라진다. 저장 값은 Store가 다시 계산하므로 표시만 틀리다(plan.md 후속 20① 판정 그대로).
   수리 모양: await 뒤 `confirmedPlace("origin_query")`/`("destination_query")`를 다시 읽어
   시작할 때의 줄 신원·좌표와 같을 때만 쓴다(`setLookup` :401-407의 재확인과 같은 규율).
2. **`EventDetailView.loadTransitPath` (:72, :153-168) — 확인됨.**
   `.onChange(of: transitTaskKey) { Task { await loadTransitPath() } }`이 이전 Task를 끊지
   않는다. 편집으로 수단·좌표가 연달아 바뀌면 두 조회가 병행하고 늦게 도착한 옛 경로가
   `routeSegments`/`transitSteps`를 덮어 지도 폴리라인·환승 안내가 마지막 상태와 어긋난다.
   후속 12(nearby onChange)과 같은 부류.

또한 `.last {`/제목 되찾기 변종(H1 변종, 결함 J 계통)은 우선 표면에서 0건 — `addEvent`가
기록을 반환하고(:558-597) 실행부가 그것을 직접 읽는다(AIAssistant :1376-1388).

### H2 — 조용히 삼켜지는 실패

**우선 표면 6개 뷰 파일: 0건.** `Task { try? ... }` 형태 없음(뷰의 유일한 `try?`는
AddEventView:434 `Task.sleep` — 취소 삼킴이라 정상).

**Store: 알려진 5곳 + 새 1건.**
- 알려진 것(묘비로 봉쇄됨, 재확인만): `removeFromCalendar` fire-and-forget — deleteActivity
  :370, deleteRecurringSeries :706, deleteEvent :1258, deleteEvents :1276, deleteActivities
  :1289. 묘비가 되살림은 막지만 실패 자체는 여전히 안 보인다(변경 없음, 문서화된 잔여).
- **새 발견 — `Store.updateActivity` (:270-279): `try? await gcal.createEvent` 실패가
  상태 기록 없이 삼켜진다.** ActivityDetailView 저장 → modifyActivity(:310) → updateActivity
  경로로 도달한다. 구체적 흐름: 구글 캘린더에 올라간 활동(gid 있음)을 편집하면 옛 gid를
  묘비 삭제한 뒤(:272-273) 재등록을 시도하는데, `try?`로 실패하면 그 활동은 gid=nil·
  calendarUpload=nil로 남는다. enqueue 계통의 pending/failed 기록(:804-839)을 이 경로는
  쓰지 않으므로 설정 화면의 대기/실패 카운트(:843-850)에도 잡히지 않는다.
  완화 요인: 다음 동기화의 reconcileActivities 2-5(:1434-1442)가 gid=nil·wantsCalendarSync
  항목을 다시 올려 자가 치유할 수 있다 — 다만 편집한 그 자리에서는 실패가 무신호다.
  수리 모양: 이 블록도 enqueueCalendarUpload 경로로 옮긴다(updateEvent :963-968이 이미
  그 모양이다 — 옛 gid 삭제 후 enqueue). **카드 권장.**

**AIAssistant: 0건 새 발견.** 실행부 반환 문구가 실패를 말하는 구조(⚠️ 문구 등)가 살아 있고,
`callAI` 실패는 userMessage로 표면화된다(:883-890).

### H3 — 외부 한도

- **iOS 64건 알림**: `rescheduleNearestNotifications(limit: 60)`(:1195-1219) 방어 유지.
  호출처 4곳 확인 — 앱 포그라운드(App.swift:26), 백그라운드 작업(App.swift:104), 반복 생성
  뒤(Store:680), 반복 수정 뒤(Store:780). 단발 addEvent/updateEvent은 직접 호출하지 않지만
  포그라운드 재보충이 누적을 묶는다. 설계 그대로, 0건.
- **반복 26주 상한**: `maxRecurrenceWeeks`가 addRecurringEvents(:627)·addRecurringActivities
  (:244)에서 모두 묶는다. 0건.
- **AI 고정 5,804 토큰**: 이번 Day는 툴 선언을 건드리지 않았다(toolsJSON 무변경). 고정 비용
  변동 없음. 0건.
- **묘비 목록**: 원격 부재 확인 시 정리(:1355-1359) — 상한 있음. 0건.
- **무한 증가 후보 점검**: `confirmedPlaces` 사전 3곳(화면)+AIAssistant(:52) — 세션 수명,
  순회·직렬화 경로 없음(후속 18② 주석 한 줄 과제로 남음). `estimates`·`seriesNumbers`·
  히스토리(maxHistoryTurns 40, :187) 모두 상한 있음. 0건.

### H4 — 복제된 계산 (계약 5)

- **출발시각 산식 3중 복제**: `@MX:DEBT` 마커가 살아 있다(applyEstimate :986-989,
  adjustBuffer :1138, applyCachedArrivalEstimate :1168). 문서화된 알려진 부채 — 이번 판정
  대상 아님(늘지 않음 확인).
- **후속 20④ `gatedRows(…)` 인자 여섯 2벌**: AddEventView :179-182 ↔ :201-204 — 글자 그대로
  2벌. 아래 ②-1에서 판정.
- **chooseTimePlain 26줄 바이트 동일**(AddActivityView :385-410 ↔ ActivityDetailView
  :211-236, `diff`로 확인) — 이미 청구된 D-2/5번째 파일 묶음. **늘지 않음 확인.**
- **알림 옵션·여유 옵션 거울**: notifyLeadRow 6줄 바이트 동일(AddEventView :255-260 ↔
  AddActivityView :371-376), 여유 칩 0/10/20/30도 2벌(:233-234 ↔ :347-348). 양쪽 다
  "같은 넷이어야 한다"는 의도 주석이 있으나(REQ-012) BesirMark식 lockstep 경고는 없다.
  D-2 통합 때 함께 흡수할 후보 — 단독 카드 아님.
- `BesirMark`(Theme.swift)↔`Tools/MakeAppIcon.swift` — 이번 Day가 안 건드렸고 양쪽 모두
  무변경(계약 예외 그대로).

---

## ② Part B — 항목별 판정

### 1. 후속 20 (AddEventView 원래 것 넷)

**① recomputeEstimates await 경합 — 유효(렌즈 H1-1에서 서술).** 좌표 :464-470, 무조건 쓰기
:471-472. **배치: 즉시 수리 후보.** 수리는 await 뒤 줄 신원 재확인 몇 줄 — 다만 이 파일은
편집 씨앗(t7) 실기기 확인이 남은 파일이라, 그 확인과 같은 빌드에 태우는 것이 순서다.
심각도는 낮다(표시만 틀림, 저장 값은 Store가 재계산).

**② 저장 버튼이 `saving`을 보지 않는다 — 실제 구멍, 확인됨.**
- 비대칭 확인: AddEventView:119 `.disabled(!(card?.isReady ?? false))` ↔ 같은 파일 안
  EditCardView:37 `canConfirm = card.isReady && !busy`, 그리고 **AddActivityView:509는
  이미 온전하다** — `.disabled(!(card?.isReady ?? false) || saving)`. AddEventView만 빠뜨렸다.
- 호출 사슬(읽어서 추적): footer 버튼 :109-119 → `Task { await save() }` → save() :571-609는
  진입 가드가 `confirmedPlace`·`parsed`뿐, `saving` 재진입 검사 없음. `saving = true`(:593)는
  버튼 잠금에 안 걸린다. 카드 안 확인 버튼은 이 화면에서 크롬으로 꺼져 있다(:53-54
  `EditCardChrome(header: nil, confirmTitle: nil)` → EditCardView:450 confirmButton 미그림).
  즉 보호받는 제출 경로가 하나도 없다. `.keyboardShortcut(.defaultAction)`(:115)의 엔터도
  같은 경로다.
- **추가 모드**: 두 번 탭하면 `addEvent`가 **결정론적으로 2건** 실행된다(두 Task 모두 가드
  통과 — 창은 네트워크 이동시간 조회 수 초). 서로 다른 UUID로 일정 2건·알림 2건·캘린더
  업로드 2건. 중복 제거 장치가 전혀 없다.
- **편집 모드**: 두 `updateEvent`가 겨쉬지만 대부분 자가 치유된다 — enqueue의 `googleEventId
  == nil` 가드(Store:812)와 pushToCalendar의 재확인(:873 "이미 gid가 있으면 다시 올리지
  않는다")가 두 번째 등록을 흘린다. **중복 경로는 하나 남는다**: 두 번째 estimate가 첫
  사슬(estimate+원격 삭제+원격 생성) 전체보다 늦게 돌아오면, 두 번째의 await 전 사본 쓰기
  (:958)가 이미 저장된 새 gid G2를 옛 gid G1로 되돌리고(:942 사본이 G1을 물고 있다),
  이후 재등록으로 G3가 생긴다. 원격엔 G2·G3 둘, 로컬·묘비는 G3만 알며 G2의 묘비가 없으니
  다음 동기화가 G2를 "다른 기기에서 추가된 일정"으로 가져온다(syncWithGoogle 2단계
  :1367-1375). 재현된 적 없음(네트워크가 느릴수록 열리는, 좁지만 실재하는 창).
- **수리: 1줄.** AddEventView:119를
  `.disabled(!(card?.isReady ?? false) || saving)`로 — AddActivityView:509가 이미 그 모양이다.
  **배치: 즉시 수리(이번 Day 닫기 안에서).** 뷰 동작 변화는 "저장 중 잠김"뿐이고 시뮬레이터
  증거 부담이 작다.

**③ 출발지 이름 빈문자열 칩 가설 — 현재 생성 경로 전부 봉쇄됨, 가설 유지(사소).**
`currentPlaceName`은 두 생산자 다 빈 문자열을 내지 않는다(LocationManager:107
`name.isEmpty ? "현재 위치(대략)"`, :157 `parts.isEmpty ? "현재 위치"`) → AddEventView:447의
`?? "현재 위치"`로는 빈 문자열이 안 나온다. 이론적 공급처는 원격 파싱뿐 — GoogleCalendarService:183
`p["destName"] ?? "도착지"`가 nil만 막고 빈 문자열은 통과시킨다(원격에 빈 값으로 저장된 적이
있어야 한다). **배치: 기각(단독 카드 아님).** 원격 파싕 경화를 다루는 날 isEmpty 검사 한 줄로 끝낸다.

**④ gatedRows 인자 여섯 2벌 — 확인(:179-182 ↔ :201-204).** 값의 계산이 두 곳이라기보다
"편집 씨앗 변환식"이 두 곳 — 필드가 늘면 두 곳을 같이 고쳐야 한다(BesirMark 예외는 주석
경고가 있는데 이쪽은 없다). **배치: 카드.** `gatedRows(seeding: e)` 과부하 한 개로 접히지만
AddEventView를 여는 카드(①·②·후속 19 수리 후보)에 얹는 것이 파일 수를 아낀다. 단독으로
열 이유는 아니다.

### 2. 후속 19 (t7이 깨운 것 셋) — 전부 현재 좌표에서 재확인, "다음 Day 카드 묶음"에 동의

- **① 값 있는 줄의 스피너**: 구동 확인 — AddEventView:93 `.onChange(of: location.isLocating)`
  → `setBusy(key: "origin_query")`, buildCard:166이 `busy: location.isLocating`으로 시딩,
  EditCardView:91-95가 스피너를 그린다. `isLocating`은 그 줄과 무관한 측위(예: 앱 시작
  프리필)에도 켜진다. 값은 덮이지 않고 냉시작 직후에만 보인다 — 결함 아님, UX 부정확함.
- **② 권한 거부 + "현재 위치" 칩**: 경로 확인 — :276이 좌표를 지우고(hereMarker는 씨앗에
  없어 nil), :297이 chosen을 비우고, :412-419가 위치를 기다리다 빈손으로 끝난다(권한 거부 시
  LocationManager:49-52가 lastError만 남긴다). 저장된 출발지가 줄에서 사라지고 isReady가
  잠기며, 이 시트엔 안내가 없다(lastError를 읽는 곳 없음 — AddEventView에서 grep 0건).
  사용자 탭이므로 REQ-002 위반은 아니고 취소·재오픈으로 복구된다.
- **③ 주석 범위**: :536의 "출발지 줄의 nil 읽기는 … 프리필을 여는 신호다" — nil 읽기는 넷
  (:424·:465·:542·:573 — 전부 확인)이고 프리필을 여는 것은 :424 하나다.
- **배치: 다음 Day 카드 묶음(동의).** ①②는 시뮬레이터·ux-check 편집 시트 항목과 같은 빌드에서
  봐야 하고 ③은 문구 1줄이다. ①의 수리 모양(편집 씨앗이 있으면 setBusy를 걸지 않는다)과
  ③의 좁힘 문구는 plan.md에 이미 적혀 있다.

### 3. O-1 — 드라이버 네트워크 가설

**판정: "모델 API 할당량 안 씀"은 참. "네트워크를 전혀 안 탄다"는 코드상 성립하지 않는다.**
샌드박스 시드는 프록시를 끄지 않는다 — `AppConfig.load()`가 config.json 없는 샌드박스에서
`bundledDefaults`를 돌려주고(Config.swift:83-89), 그 기본값은 **살아 있는 프록시 주소와
앱 토큰**이다(Config.swift:76-81). 드라이버가 비우는 필드는 autoAddToCalendar
(GuardDriver:309)와 googleClientID(:315)뿐이다. 실행되는 절 중 프록시 도달 가능 경로:

| 절 | 호출 | 경로 |
|---|---|---|
| P-4 (:1718) | `searchPlaces("ㅁㄴㅇㄹ쀍똙")` → 350ms 뒤 `PlaceSearch.search` | hasProxy 참 → `kakaoKeyword` → `URLSession`(PlaceSearch.swift:13-29) — **카카오 키워드 1회**. 단언 자체에 〔네트워크 의존〕 표시(:1724)가 있다 |
| Y-2 (:1350) | `drvCreate(mode transit)` → `travelSeconds` → `estimate(.transit)` | `odsayTransit` 우선(DirectionsService.swift:30) — **ODsay 1회**, 실패 시 MapKit 폴백 |
| Z O-2 (:1547-1553) | 카드 확정 → `resolvePendingAsk` → 같은 estimate 경로 | **ODsay 1회** |
| P-1 (:1663-1667) | 같은 모양 | **ODsay 1회** |
| S·J | `estimate(.walk)`만 | MapKit 단독(XPC — 프로세스 소켓 없음). S절 주석(:921-925)이 이 선택을 명시한다 |
| P-6 (:1744) | searchPlaces 후 즉시 카드 취소 | 취소가 350ms 대기 중 작업을 끊어 **발화 안 됨**(arm의 `Task.isCancelled` 가드) |
| 매 `fresh()` (AIAssistant:122) | `useCurrentLocation` → 3초 무측위 시 `ipLocationFallback` | `https://ipwho.is/` HTTP(LocationManager:82-108) — CoreLocation 권한 상태에 따라 발화 |

즉 OpenAI 할당량은 구조적으로 0(callAI를 부르는 경로가 드라이버에 없다 — resolvePendingAsk는
runToolCalls까지만), 카카오·ODsay는 **회당 최대 약 5회** 프록시를 경유한다. 관측(소켓 0,
0.1초 표집 136회)과 이 추적이 양립하려면 (a) 표집이 짧은 연결을 놓쳤거나 (b) 그 환경에서
DNS가 죽어 TCP 자체가 안 열렸거나(이 경우에도 판정은 MapKit 폴백으로 같아 212/212가
나온다) 둘 중 하나다. **관측이 구조적 부재의 증거는 아니다.**

CLAUDE.md:58·GuardDriver 머리말(:26-27)의 "(API 할당량 안 씀)"은 무조건 문장으로는 과하다.
**정확한 시정 방법 두 가지(오케스트레이터 선택):**
1. **문서 한정**: 문장을 "모델 API 할당량은 안 씀(카카오·ODsay는 일부 절이 회당 몇 회
   프록시를 경유한다)"으로 좁힌다. 코드 무변경.
2. **코드로 무조건화**: GuardDriver:315 뒤에
   `store.config.proxyBaseURL = ""; store.config.appToken = ""` 추가(이유 주석 포함).
   단언 영향 정밀 추적: P-4는 mapKitSearch 폴백으로 같은 .empty 판정, Y-2·Z O-2·P-1은
   mapKitETA(.transit)로 이행(세 곳 다 transit 초록 여부에 단언이 걸려 있지 않다 — Y-2는
   "등록 완료" 접두·Z O-2는 건수·장소명·P-1은 인자·좌표), S·J는 walk이라 무관. 212개
   유지 가능성 높으나 **재실행 재게이트가 필수**다.
**배치: 카드(O-2와 한 묶음).** 둘 다 GuardDriver 시작 블록·문서를 같이 만지고 같은 재실행으로
게이트한다.

### 4. O-2 — 드라이버 백업 중복 7곳

전수 확인: 파일 백업/복원 쌍은 6개 절에 9쌍 — Q(ai_history :791/:793), J(events
:1285/:1314), Y(events+activities :1325-1326/:1394-1396), N(:1409-1410/:1496-1498),
Z(:1515-1516/:1637-1639), P(events :1649/:1768) + 메모리 favorites 2쌍(Z :1517/:1641,
P :1650/:1770). t8 이후 이 URL은 전부 **샌드박스 안**에서 풀린다(시작 검사 :267-272가
지원 디렉터리의 샌드박스 귀속을 보증) — 실제 데이터 보호는 종료 시 실측 디렉터리 바이트
대조(drvFinishOnce→drvDiffSupportDir)가 단일 장치로 맡았다. 절 중간에 파일을 다시 읽는
곳은 Q(drvPersistedPayload :809) 하나뿐이고, N-3/N-4는 파일이 아니라 메모리 JSON 왕복으로
단언한다(:1453-1463). events/activities 백업 5쌍은 샌드박스 안에서도 **독자가 없다.**

**판정: 제거 가능성은 있으나 이번엔 미룰 것(defer).** 이유: (a) 메모리 사전(favorites)·
세션 간 히스토리 누설 같은 절간 간섭을 정독만으로 전부 배제하기 어렵고 재실행 게이트가
필수인데, (b) CLAUDE.md의 드라이버 사고 절차 서술이 백업·cmp 절차와 묶여 있어(자동 메모리
`feedback_besir_driver_touches_real_data`) 문서를 같이 고쳐야 하고, (c) O-1의 시정 2안과
같은 시작 블록·같은 재실행을 공유한다. **O-1+O-2를 "드라이버 위생" 카드 한 장으로 묶어
다음 Day에 처리**를 권한다. 정확한 편집 목록(적용 시): :789-793, :1284-1285, :1313-1315,
:1323-1326, :1394-1397, :1407-1410, :1496-1499, :1513-1516, :1637-1640, :1648-1649,
:1768-1769 (백업·복원 쌍 전부; favorites 메모리 쌍은 절 격리 기능이 있어 유지).

### 5. N1 — save()가 travelSecondsHint를 안 넘긴다

**주장 유효, 현재 좌표로 확인.** AddEventView.save()의 두 호출(:595-599 updateEvent,
:601-605 addEvent) 모두 힌트를 넘기지 않는다. addEvent는 힌트 인자를 받는다(Store:567
`travelSecondsHint: TimeInterval? = nil`) — 폼은 이미 `estimates[mode].duration`을 갖고
있는데(:27 estimates, recomputeEstimates가 채움)도 조회를 다시 한다(Store:587
`case (.arrival, nil): await applyEstimate`). **updateEvent는 힌트 인자 자체가 없다**
(:930-940) — 편집 폼의 추정값이 구조적으로 못 흐른다. 비용: 저장마다 카카오/ODsay 1회
추가 + "폼이 보여준 소요시간"과 "저장된 소요시간"이 다를 수 있음(재조회 사이 교통상황 변동).
AI 경로는 이미 본보기다 — executeCreateSchedule이 `travelSecondsHint: seconds`로 넘긴다
(AIAssistant:1338-1388) + `travelSeconds` 조회 헬퍼의 주석(Store:539-540)이 정확히 이
용도를 문서화한다. **배치: 카드.** 수리는 addEvent 호출에
`travelSecondsHint: estimates[mode]?.duration` 한 줄(+updateEvent에 선택 인자 추가)이지만
후속 20②의 1줄 수리와 같은 함수 안이라 같은 빌드에 태우면 파일 수를 아낀다.

### 6. CB — ConflictBanner 계약 6 우회 3건

**현재 좌표로 3건 모두 존재 확인** — AddEventView:627 `.foregroundStyle(.secondary)`(건별
줄), :630 `.foregroundStyle(.tertiary)`(안내 줄), :635 `RoundedRectangle(cornerRadius:
8)`(배경; Theme.warn·warnFill은 토큰이라 정상). 같은 부류 추가 좌표(ui-design 묶음에
함께 기록할 것): AddActivityView(PlaceField) :574 `cornerRadius: 8`(후속 16), ActivityDetailView
주변 섹션 .secondary/.tertiary 다섯 줄(:366, :374, :388, :391, :395). **배치: 다음 Day
ui-design 카드(계획대로)** — 좌표만 확정하고 이번엔 손대지 않는다.

### 7. plan.md 후속 11/12/13/15/16/18 — 한 줄 상태

| 항목 | 현재 상태(좌표) | 배치 |
|---|---|---|
| 11 chooseTimePlain 기본값 false | 그대로. EditCard.swift:263 기본 클로저 false; `anchored: false` 생성은 4곳(AddActivityView :139·:141, ActivityDetailView :152·:154 — t3 좌표에서 미세 이동) 모두 배선됨(각 :113·:122) | D-2 묶음(다음 Day) |
| 12 nearby onChange 취소 없음 | 그대로. ActivityDetailView :362(구 :339), loadNearby :409-415(구 :386-392) 무조건 덮기 | 카드(다음 Day — 카카오 할당량·낡은 목록) |
| 13 저장 게이트 약화 | 게이트 약화는 확정(ActivityDetailView:90). **미결이었던 AI 경로를 읽었다 — executeCreateActivity :1449가 빈 제목을 거부한다.** 수동 생성(accepts 빈 거절)·AI 생성·편집(기존 제목은 세 경로 모두 비빈) 전부 막혀 도달 불가 | 노트만 닫기(plan.md에 "AI 경로 확인됨" 한 줄). 코드 불필요 |
| 15 장소 확정 칩 감김 | 그대로. EditCardView:122-124(장소 확정 칩, lineLimit 없음) ↔ :206-208(시각 칩은 있음) | 계획대로 시뮬레이터 AC-009 (14) 실측 뒤 |
| 16 Theme 위반 2자리 | 그대로. AIChatView:114 `.foregroundStyle(.white/.primary)` 확인, AddActivityView:574 `cornerRadius: 8` 확인 | CB 묶음과 같은 ui-design 카드 |
| 18 주석 과적용 2건 | 그대로. ① "유일한 보임새 변화" AIAssistant:759-760(구 :756), ② confirmedPlaces 천장 미기술 :45-52·쓰기 :762-763·resetConversation :220 | 문구 카드(후속 19③와 한묶음) |

---

## ③ 간결성 소견

- **루프 안 반복 저장/네트워크(우선 표면): 0건.** pushToCalendar(성공분 모으고 save 1회,
  Store:895), updateRecurringSeries(루프 뒤 1회 :759), addRecurringEvents(:672),
  syncWithGoogle(가져오기 루프의 estimate는 건당 필요 1회, save는 :1379 1회),
  rescheduleNearestNotifications(복사본 대입 1회 :1217-1218). H5 부류는 현재 트리에서
  정리돼 있다.
- **죽은 코드 후보(재검증)**: `KoreanHolidays.dates(year:)` 호출 0건 — 후보 유지.
  `MealLog.estimatedCost` 쓰기만 있고 읽기 0건 — 후보 유지. `RouteMode.car`는 **살아 있음**
 (DirectionsService :243·:246이 car 폴리라인을 만든다 — 삭제 금지, 2026-09-16 교훈 재확인).
  `Store.updateMeal` 호출 0건이나 SPEC-FULL-001 결정으로 유지(:408 이유 주석 확인).
  `MealCategory.delivery/.cooking` 보호 유지. **이번 패스에서 제거한 것 없음** — Day 닫기
  트리에서 죽은 코드를 끊는 것은 드라이버 재게이트를 수반하므로 O-1/O-2 카드로 넘긴다.
- **프록시 `/claude/messages` 사 경로**: 앱 쪽 호출 0건(`proxyPOSTRequest` 호출은
  `/ai/chat` 한 곳, AIAssistant:961). proxyClaude + ANTHROPIC_KEY 처리 + ANTHROPIC 시크릿이
  사용 없이 남아 있다. 제거는 npm test + 배포 + 시크릿 정리를 수반하므로 **프록시 카드로
  이월 권장**(redactSecrets 목록에서 ANTHROPIC_KEY를 당장 빼는 건 잔여 시크릿이 있으면
  누출 경로가 남으니 제거와 함께).
- **과하게 바쁜 함수**: 우선 표면에서 새로 지적할 만큼은 없다. AddEventView.choose의
  switch가 가장 길지만 분기마다 이유 주석이 붙어 있고 분해하면 좌표 쓰기가 여러 자리로
  흩어진다(의도적 단일 쓰기 자리).

---

## ④ Gaps — 검증하지 않은 것

1. **빌드·드라이버·프록시 테스트를 돌리지 않았다**(임무 제약: 읽기 전용). 무경고 빌드 게이트는
   이번 패스의 주장 아니다 — t8 sync가 이미 재실행했고, 이후 코드 변화가 없다(트리 = 57f874f).
2. **ContentView·FullSirView·AIChatView 전체·ShareExtension·SettingsView·Theme.swift·
   MakeAppIcon은 이번 패스의 읽기 대상이 아니었다**(우선 표면 밖). 특히 `ContentView.span(for:)`
   단일 출처 현행 유지 여부는 확인하지 않았다 — 이번 Day가 그 파일을 안 건드렸다는 커밋
   기록에 기댄 미검증이다.
3. **후속 20② 편집 모드 중복 경로는 정적 추적이다.** 두 updateEvent의 인터리빙을 실행으로
   재현하지 않았다(재현 안 된 것은 원래 기록과 같다). 추가 모드 2건 생성은 결정론적이라
   실행 재현 없이도 확정했다.
4. **O-1의 관측-추적 긴장을 기계적으로 해소하지 못했다.** 소켓 표집을 반복하거나 프록시
   로그를 보는 행위가 금지(쓰기·외부 접근)였다. 판정은 코드 추적에 근거하며, 관측과의
   정합 해소는 O-1/O-2 카드의 재게이트에 묶는다.
5. **GoogleCalendarService는 파싱 3곳(:174-196 부근)만 읽었다** — OAuth·토큰 캐시·fetch
   페이지 처리(maxResults 250)는 이번에 재검증하지 않았다.
6. **plan.md 후속 1-10·14(PlaceField 계열·주소 상시 표시 등)은 이번 지시 범위(11-13·15·16·
   18-20) 밖**이라 상태를 갱신하지 않았다. 14번은 plan.md가 이미 강등·이월 판정을 내린
   그대로다(장소 줄 자유 텍스트 경로 부재를 EditCardView:310과 :383-384로 이 트리에서
   재확인했다 — 판정 근거 유효).

## ⑤ 잔여 위험

- **후속 20② 추가 모드 이중 탭은 지금도 열려 있다.** 1줄 수리 전에 실기기 확인 단계가
  끝나면 사용자가 겪을 가능성이 가장 높은 결함이다(네트워크 느릴수록 창이 커진다).
- **updateActivity의 재등록 실패 무신호(H2 신규)** — 다음 동기화가 치유할 수 있으나 그때까지
  "캘린더에 안 올라갔다"는 아무 데도 안 보인다. 카드로 못 옮기면 실기기 확인 목록에
  "활동 편집 뒤 캘린더 반영" 항목을 추가할 것.
- **드라이버의 카카오·ODsay 미량 소비**는 할당량을 위태롭게 하지 않지만(회당 ~5회),
  CLAUDE.md 문장이 근거 없이 강하다. 문서 시정 전에 드라이버를 자주 돌리는 만큼 누적된다.
- 후속 12·H1-2(EventDetailView 경로 경합)는 표시 어긋남뿐이지만 "화면이 거짓말하는" 부류
  (렌더링·히트테스트 어긋남의 사촌)라 다음 수정 시점 전에 두고 볼 이유가 없다.
