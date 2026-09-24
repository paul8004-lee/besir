# t12 — C3 무취소 Task 부류 (+ N5 동반) 완료 보고 (2026-09-24)

card: t12 · 부류 B(원인 확정 — plan 생략) · 레인: run
branch: **WT-task-cancel-tag** (base origin/master 368b30e, push 완료)
merge 후보 SHA: **7532f10** · evidence: 이 파일

## §1 주장 (Claim)

- 카드 본문 그대로: 후속 12(ActivityDetailView nearby onChange) + 신규
  EventDetailView.loadTransitPath 무취소를 "**`.task` 취소/태깅 패턴 하나로**" 정리했다.
- 리드 지시로 N5(t11 sync 신규 발견 — 재계산 취소 없음·prefill 5초 vs 측위 8초)를 같은
  부류로 평가해 함께 태웠다. 범위 판단: 태깅 확장 + 상수 파생식이라 부풀지 않음 → 포함.
  (N5의 시한 불일치 반쪽도 같이 닫았다 — §2 prefill 파생식.)
- 구현 swift-impl / 판정 code-safety — **SHIP, 신규 결함 0건**.

## §2 증거 (Evidence)

통일 패턴: 뷰마다 `@State Task` 핸들 + 발화 지점 취소-교체
(`LocationManager.startTimeout` 선례와 판박이) + `await` 뒤 `!Task.isCancelled`
재확인 뒤에만 상태 쓰기. 카카오·ODsay 경로는 전부 `URLSession.shared.data(for:)`
async 변형이라 취소가 진행 중 요청을 **클라이언트 측에서** 끊는다(업스트림 할당량 절감은
미측정 — t12 sync D4 정정). 취소된 `estimateAll`이 꼭 빈 추정으로 돌아오는 건 아니다 — 카카오·
ODsay 갈래는 취소로 끊기지만 MapKit 폴백이 섞인 실제 값으로 돌아올 수 있고, 가드가 그 값을 버린다.

파일별 (+103/−24, 커밋 7532f10):

| 파일 | 내용 |
|---|---|
| Shared/LocationManager.swift | `locateTimeoutSeconds` 단일 출처 신설(iOS 8 / macOS 3), `startTimeout` 하드코딩 제거 — 계약 5 |
| Shared/EventDetailView.swift | `transitTask` 태깅(onChange 구조 유지·최소 diff), 세 awaited 갈래 각각 isCancelled 가드, onDisappear 취소 |
| Shared/ActivityDetailView.swift | `nearbyTask` + `startNearby()`로 버튼·onChange 두 발화 통과, 스피너 해제(`loadingNearby=false`)를 가드보다 먼저 — 취소 잔여 잠금 방지, onDisappear 취소 |
| Shared/AddEventView.swift | `estimateTask`/`prefillTask` + `restartEstimates()`(발화 4곳), 기존 신원 대조 가드에 `!Task.isCancelled` 추가(기존 방어 전부 유지), prefill 대기 `max(5, locateTimeoutSeconds + 1)` 파생(iOS 9초·macOS 5초 바이트 동일), 루프 취소 break, onDisappear 확장 |

게이트 4종 — **이 레인이 이 트리에서 재실측**:

| 게이트 | 명령 | 관측 |
|---|---|---|
| iOS 빌드 | `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build` (> /tmp/t12-ios.log) | `** BUILD SUCCEEDED **` · swift 경고 0 (raw 2건 = appintentsmetadataprocessor 잡음) |
| macOS 빌드 | `xcodebuild -scheme besir-macOS -derivedDataPath build build` (> /tmp/t12-mac.log) | `** BUILD SUCCEEDED **` · 잡음 1건뿐 |
| 가드 드라이버 | CLAUDE.md 레시피(EditCard.swift 포함판) — **레인 직접 실행** | `212/212 통과` · `[실제 데이터] 대조 통과` · exit 0 |
| proxy | `cd proxy && npm test` — **레인 직접 실행** | `7/7 통과` · exit 0 |

code-safety 판정(렌즈 4종 전부 가동 — "검사하지 않은 것 = 실패" 기준 준수):

- H1 await 전후 상태 재사용 **0건** — estimateFlights 증감 균형(감산이 모든 경로에서 실행),
  loadNearby 스피너 해제 순서, loadTransitPath 상단 clear의 순서 문제는 도달 불가로 확인
- H2 조용히 묻히는 실패 **0건** — 가드가 삼키는 건 취소된 조회의 빈 결과뿐
- H3 무한 증가·외부 한도 **0건** — 핸들 뷰당 1개, 취소가 진행 중 요청 중단
- H4 복제 계산·간결성 신규 결함 **0건** — 제2 패턴 변형 없음(다발 화점 헬퍼·단발 인라인 정책)
- 처방 밖이었던 onDisappear 취소 3곳: **KEEP** 확정 — 세 뷰 전부 시트로 호스팅, 푸시 경로
  없음(시트·다이얼로그는 presenter의 onDisappear를 유발하지 않음) — ContentView:127-155 대조
- 부동소수점 실측: `9.0/0.2 == 45.0` · `5.0/0.2 == 25.0` · `8.0*1e9` 정확 → 절단 없음

## §3 귀속 (Baseline-attribution)

- 게이트 관측은 전부 이 워크트리(`.claude/worktrees/t12`, 커밋 시점 HEAD 7532f10)에서
  이번 실행으로 측정했다.
- 가드 드라이버·proxy는 레인이 직접 재실행해 관측; 빌드 두 건은 swift-impl 실행 로그
  (/tmp/t12-ios.log·/tmp/t12-mac.log)를 레인이 직독(SUCCEEDED 마커·경고 수 grep)했다.
- code-safety는 게이트를 재실행하지 않고 레인 관측을 인용(지시에 따름 — §4 참조).
- 빌드 두 건은 sync 판정(C1)이 `git archive` 격리 사본·새 DerivedData로 독립 재현해 같은 결론을
  얻었다(iOS·macOS `BUILD SUCCEEDED`·swift 경고 0/0 — 증거 `.moai/state/verify/t12-sync/`).
  레인의 빌드 관측 갭을 그 측정이 닫는다(2026-09-25 보강).

## §4 갱 (미검증)

- iOS onChange 클로저 형태의 런타임 동작 — 빌드가 담보, 형태는 diff 이전과 동일.
- MapKit 비동기(MKDirections.calculateETA 등)의 취소 전파는 문서화되지 않음 — 최악의
  경우 Apple 쪽 요청이 끝까지 돌고 결과만 버려진다(카카오·ODsay 할당량과 무관).
- 시뮬레이터·실기기 관측 없음(§5 실기기 몫).
- code-safety의 게이트 재실행 없음 — 레인 이중 관측(직접 실행 2 + 로그 직독 2) + sync 격리
  재현(t12 sync C1)으로 보강.

## §5 잔여 위험 · 후속

후속 카드 후보(이 카드 범위 밖 — 리드 판단 대상):

1. **LocationManager.startTimeout 취소 미확인(사전 존재 결함 — 기전 정정 뒤 수리로 닫힘)** —
   이중 호출 경로("현재 위치" 칩 AddEventView:446→:463 · 앱 시작 AIAssistant:122→App:90)에서
   두 번째 startTimeout이 첫 태스크를 cancel하면 sleep이 즉시 깨는데, **실제 증상은 처음
   적은 것과 반대다**(t12 sync D4 실험 정정): 취소된 URLSession 요청은 서버에 닿기 전 -999로
   끝나 폴백이 조용히 실패하고 `isLocating=false`·실패 `lastError`가 ~0.05초에 쓰인다 — IP
   폴백이 죽고 출발지 스피너가 일찍 꺼진다. **대략 위치가 확정되는 일은 없다.** 수리: 수리
   커밋 `01bb149`(N1)가 가드에 `!Task.isCancelled`를 더해 이 경로를 닫았다. 첫 실행에서 권한
   대화 상자를 노릴 때의 효과는 실기기 확인 몫(sync Gaps).
2. **0.2초 틱 쌍 이중화** — AddEventView 제수 `0.2` vs `200_000_000`ns. 사전 존재 암묵 쌍인데
   이번에 카운트 파생이 이 값을 의존하게 됨(load-bearing). 계약 5 후보. (t12 sync N6 확장:
   `AIAssistant:2382`의 `0..<15`(3초 대기)도 같은 측위 시한 불일치인데 파생되지 않았다 —
   AI 경로의 N5는 여전히 열려 있다. 기록만.)
3. **FullSirView:158·:181 무취소 runSearch** — 퀵픽·정렬 변경마다 카카오 재조회. 같은 부류,
   이 카드 근거 밖. (또한 AddEventView:129 save·EventDetailView addToGoogleCalendar의
   1회성 Task는 busy-플래그 잠김으로 보호돼 이 부류가 아님 — code-safety 확인.)
4. **bootstrap 구조적 `.task` 안 직접 await 두 곳**(t12 sync N5 — 기록만) — 편집 모드 bootstrap
   재계산은 `restartEstimates`가 취소하지 못하지만 신원 가드·카운터로 결과는 옳다(조회 한 벌
   낭비). bootstrap 프리필과 칩 프리필이 함께 기다리면 둘 다 확정하나 멱등이다. 태깅하려면
   화면 생명주기 소유권 재설계가 필요해 이 카드 범위로 보지 않았다.

실기기 확인 목록(빌드로 증명 불가 — 운영자 몫):

- 재계산 버튼 두 연타·출발지/목적지 연달아 변경 시 모드 칩 소요시간이 **마지막 선택
  기준으로만** 갱신되는지, 스피너가 남지 않는지.
- 실내 GPS 등 측위 5~8초 지연 환경에서 빈 출발지 줄이 이제 채워지는지(9초 창).
- 일정 상세에서 수단을 바꿀 때 옛 경로가 덮지 않는지, 상세 닫기 직후 이상 유무.

## §6 sync FAIL 수리 (2026-09-25)

- 판정: `.moai/reports/t12/sync-verdict.md` — 코드 `7532f10` **PASS**(독립 렌즈 DEFECT 0건)·
  게이트 **PASS**(sync 격리 사본 독립 재현)·문서 **FAIL**(D1~D4). 병합 조건은 D1~D4 문서 커밋.
- **코드 수리 커밋 `01bb149`**(리드 판정으로 권고 5건 포함): N1 `startTimeout` 가드에
  `!Task.isCancelled`(기전은 §5-1 정정판)·N2 주변 스피너 순서(취소 가드를 스피너 해제보다
  앞으로 + placeCoord nil 조기 반환에서 플래그 내림 + 낡은 "영영 풀리지 않는다" 주석 전제
  재작성)·N3 `choose()` 장소 변경 시 `nearbyTask` 취소(N2 적용 뒤 — 거짓 "찾지 못함" 없음)·
  N4 estimateAll 주석 정정(MapKit 폴백 혼입 가능)·N7 오타. **처방 밖 변경 0건** — swift-impl
  재기동(직전 구현자)이 적용, 레인이 diff를 처방과 대조해 확인.
- 게이트 재실측(수리 트리): 드라이버 **212/212 통과**·실데이터 대조 통과·exit 0(레인 직접) ·
  proxy **7/7**·exit 0(레인 직접) · iOS·macOS `** BUILD SUCCEEDED **`·swift 경고 0(raw 잡음
  1/1 — /tmp/t12r-ios.log·/tmp/t12r-mac.log 직독).
- 문서 수리: CHECKLIST D1 좌표 9건 + D2 이월 3번 "처리됨(2026-09-25, 카드 t12)" 표기 ·
  plan D3(후속 12 닫힘 문단·후속 11·14 좌표 재사상) + N8 카드 표 t11·t12 행 · 이 progress
  D4(§2·§5-1 기전 2건 정정, §3 sync C1 인용 보강, §5-2 N6 확장, §5-4 N5 기록).
- **좌표 재사상**(판정문 '이 세션 자신의 빈틈' 경고 이행 — 수리 코드로 밀린 5건만 이동,
  나머지 6건은 판정문 표 값 그대로 grep -nF 재확인): `currentConflicts` :644→**:646**,
  `ConflictBanner` 선언 :717→**:719**, 이월5 AddEventView :730·:733·:738→**:732·:735·:740**,
  이월5 ActivityDetailView :372·:380·:394·:397·:401→**:376·:384·:398·:401·:405**,
  O-1 :90-117→**:95-123**. (EventDetailView는 수리가 안 건드려 :121-157·:159-164 그대로.)
- 문서 커밋 SHA: 아래 백필.
