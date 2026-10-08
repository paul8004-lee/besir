# t49 sync 판정 — 편집 끝 시각 변경의 추정 복귀 구간 연계

카드 t49(B급 — run→sync, SPEC 없음). 대상: 브랜치 `WT-edit-return-leg`, 커밋 97f1662(`Shared/Store.swift`·`Tools/GuardDriver.swift`·progress.md).
판정 세션: sync 레인, 2026-10-08. 병합·push는 하지 않았고 카드 파일은 한 줄도 고치지 않았다.

## 판정: **PASS — 차단 0건** (주의 3건·메모 4건은 이 카드 밖 후속 후보)

| 관점 | 결과 | 근거 절 |
|---|---|---|
| 기능성 | PASS | §1 (드라이버 독립 재실행), §2 (master 대조로 단언이 실제로 변별함) |
| 안전성(보안) | PASS | diff가 Store·드라이버·기록 3개뿐, 네트워크·비밀값·권한 접점 0 (`git diff --stat master...HEAD`) |
| 공예(코드 품질) | PASS, 메모 1건 | §4 N-1 |
| 일관성 | PASS | 파일 상한 준수, 커밋에 `(card t49)`, `moveActivity` 무변경(§3 근거) |

## 1. 드라이버 독립 재실행 (카드 트리, HEAD 97f1662)

명령(CLAUDE.md 레시피 그대로 — 단, 산출물은 공유 `/tmp`가 아니라 검증 폴더에 둠):

```bash
cat Shared/EditCard.swift Shared/AIAssistant.swift Tools/GuardDriver.swift > .moai/state/verify/t49-sync/gd-base.swift \
  && swiftc -o .moai/state/verify/t49-sync/gd-base .moai/state/verify/t49-sync/gd-base.swift Shared/Store.swift Shared/Models.swift \
       Shared/Config.swift Shared/PlaceSearch.swift Shared/DirectionsService.swift Shared/LocationManager.swift \
       Shared/NotificationManager.swift Shared/GoogleCalendarService.swift Shared/SharedInbox.swift -parse-as-library \
  && .moai/state/verify/t49-sync/gd-base
```

관측(로그 `gd-base-run.log`, 종료 `exit=0`):

```
  ✓ T49-1 … ✓ T49-2 … ✓ T49-3 … ✓ T49-4 … ✓ T49-5 … ✓ T49-6 …
529/529 통과
[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다
```

`✗` 0건. 컴파일 경고 24건은 전부 macOS SDK 폐지 예고(`CLGeocoder`·`MKPlacemark`, LocationManager·PlaceSearch·DirectionsService)이고 이 카드가 건드린 Store.swift 구간은 0건. 하한 529 = 523 + 6 일치.

## 2. 단언이 헛통과가 아닌지 — master 대조 (양성 대조)

같은 드라이버를 **master의 Store.swift**(`git show master:Shared/Store.swift`)로 컴파일해 돌렸다(`gd-repro-master-run.log`):

```
  ✗ T49-2 … ✗ T49-3 … ✗ T49-4 … ✗ T49-6 …
525/529 통과
```

수리가 없으면 T49-2·3·4·6이 실제로 ✗가 된다 → 이 단언들은 수리 효과를 변별한다. (T49-1·5는 양성 대조·회귀선이라 양쪽 ✓가 맞다.)

## 3. 추가 질의 — `moveActivity` wholeSeries 교차 루프 이중 이동

**판정: 재현됨. 단, 카드가 만든 결함이 아니라 master에도 똑같이 있는 기존 결함이다(수리 안 함, 기록만).**

원인(코드 읽기, 재현으로 확인): `Store.swift:1404-1408`은 회차마다 `linkedLegs`로 짝을 찾은 **즉시** 구간을 옮긴다. 추정 짝은 `events.first{ 대조 시각 == 활동 끝 }`(`:1635`)인데, 1회차 구간이 +1440분 옮겨지면 그 출발이 2회차 활동 끝과 같아져 2회차 조회가 1회차 구간을 다시 집는다. 이동 전에 짝을 한꺼번에 모으지 않아서 생긴다(N5-1이 `applyLinkedLegDrag`에서 고친 형태가 여기엔 남아 있다).

재현 조각: `.moai/reports/t49/sync-repro/repro_snippet.swift`(드라이버 **사본**에만 끼움 — `splice2.py`). 활동 3개(하루 간격)·구간 3개, `moveActivity(wholeSeries: true)`:

```
[SYNC-REPRO] A 추정 +1440 (return,  명시연결=false): leg0=4320 leg1=0 leg2=0 | 활동 변위=[1440,1440,1440] | 구간 전부 기대값=아니오 ← 이중 이동/누락
[SYNC-REPRO] B 추정 +1440 (arrival, 명시연결=false): leg0=4320 leg1=0 leg2=0 | 활동 변위=[1440,1440,1440] | 구간 전부 기대값=아니오 ← 이중 이동/누락
[SYNC-REPRO] C 추정 +60  (대조군)                  : leg0=60 leg1=60 leg2=60                              | 구간 전부 기대값=예
[SYNC-REPRO] D 명시 +1440(대조군)                  : leg0=1440 leg1=1440 leg2=1440                        | 구간 전부 기대값=예
[SYNC-REPRO] E 추정 -1440                          : leg0=-1440 leg1=-1440 leg2=-1440                     | 구간 전부 기대값=예
```

- 위 출력은 카드 Store(`gd-repro-run.log`)와 master Store(`gd-repro-master-run.log`)에서 **글자 그대로 같다** → 카드 이전부터 있던 결함, 카드가 늘리지도 줄이지도 않았다.
- 조건: 추정 짝(반복 회차, 명시 연결 없음) **그리고** 이동량이 회차 간격의 양의 배수(하루 간격이면 +1440). 방향 의존: 음수(E)와 어긋난 크기(C)는 정상. 명시 연결(D)은 정상.
- 화면 도달 가능성: 호출부는 `ContentView.swift:916` 하나. 활동 끌기는 자동 스크롤·하루 연장이 소유 있는 구간 끌기에만 붙고(`:505` 주석 Q-9), `hourHeight = 56pt`(`:37`)라 1440분 = 1344pt의 손가락 이동이 필요해 아이폰 화면(≈900pt 이하)에서는 닿기 어렵다. **미확인:** iPad·외부 호출 경로는 보지 않았다.

## 4. 독립 리뷰어(code-safety, 읽기 전용) 주장의 실행 판정

리뷰어 보고의 결함 가설은 코드 읽기였으므로 같은 하네스에 케이스를 더해 카드·master 양쪽에서 실행했다(`repro_snippet2.swift`, 로그 `gd-repro2-{card,master}-run.log`; 카드 529/529, master 525/529).

| # | 주장 | 실행 결과(카드 / master) | 판정 |
|---|---|---|---|
| F | 명시 연결 + 출발 nil 복귀 구간이 이제 끝 편집을 따라온다(옛 코드는 건너뜀) | 구간 arrival 변위 **+30분 / 0분** | **재현됨 — 의도에 맞는 개선**(t43 fix1-②와 같은 규칙). 단 이 경우를 고정하는 단언이 없다 → **주의 W2** |
| G | `clearPlace`+끝 편집: 추정 구간을 안 옮김, 명시 구간은 지워짐 | 추정 변위 0분·구간 존재, 명시 구간 삭제됨 / 동일 | **카드 설명과 일치**(REQ-004 정합). 고정 단언은 없음(메모) |
| H | `newPlace`+끝 편집: 추정 구간이 옮겨지지만 이름이 달라져 짝은 풀림 | 변위 **+30분 / 0분**, 소유 활동 없음 / 소유 없음 | 재현됨 — 어느 쪽이든 구간이 고아가 되는 건 같고 위치만 새 끝에 놓인다. **메모 N-2** |
| I | 같은 회차·장소·시각 활동 2개가 구간 1개를 공유하면, `owningActivity`는 동률로 거절하는데 편집은 구간을 옮긴다 | 편집 전 소유=없음(동률 거절), 구간 변위 **+30분 / 0분** | 재현됨. 현실에선 중복 데이터(가져오기·동기화 경합)에서만 → **주의 W3** |
| — | `Store.swift:411-412`의 "편집·삭제용이라 추정을 쓰지 않는다"와 모순 | 그 주석은 `legs(of:)`(명시만 조회, `:414-415`)에 대한 것. `modifyActivity`는 `linkedLegs`를 쓰고 `moveActivity`도 이미 그랬다 | 모순 아님 — 기각 |
| — | 다른 일부(stale 캡처·await·저장 반복) | 코드 읽기 근거: `modifyActivity`에 `await` 없음, 캡처는 `moveActivity`·재읽기 뒤(`:325-339`)에서 한 번 | 가설 아님 — 내가 같은 줄을 읽어 확인 |

## 5. 결함·후속 목록

차단(block): **0건.**

주의(warn) — 모두 이 카드 밖, 후속 후보:
- **W1** `moveActivity` wholeSeries 이중 이동(§3). 수리 방향 제안(내 제안, 지시 아님): 짝을 이동 전에 한꺼번에 모은 뒤 옮기기(`applyLinkedLegDrag`의 N5-1 수리와 같은 모양).
- **W2** 명시 연결 + 출발 nil 구간의 새 동작(F)을 고정하는 단언 부재 → 드라이버 한 줄 후보(하한 529→530).
- **W3** 중복 활동 동률(I)에서 `owningActivity`는 거절하는데 편집 경로는 구간을 움직임. 제안: `realignReturnLeg` 전에 `owningActivity(of: leg)?.id == id` 확인(결정 필요 — 실사용 가능성 낮음).

메모(note):
- **N-1** 주석 오탈자 `Store.swift:358-359` "departureDate로 **잴면**" → "재면". 한 글자라 이 판정에서 고치지 않았다(검증한 HEAD를 움직이지 않으려고).
- **N-2** `newPlace`+끝 편집 시 추정 구간 위치가 새 끝으로 가지만 짝은 풀림(H) — 의도 확인용 기록.
- **N-3** 문서: progress §5의 "349줄 이후 균일 +7"은 부정확(첫 훅 +5는 335줄 근처, 둘째 +2). 단 332~348줄을 가리키는 인용은 CHECKLIST·plan·SPEC에 0건(`grep "Store.swift:3[3-4][0-9]"` 출력 없음)이라 실해 없음. 재사상 카드는 원장 대조로 잡아야 한다.
- **N-4** progress §6-1(AIAssistant 완료 문구가 추정 짝 이동을 안 알림), §6-3(초 단위 newEnd) — 카드가 이미 후속으로 적어둠. 내가 검증한 것은 아님.

## 6. iOS 빌드

명령(워크트리 루트에서, **빈 캐시 폴더**로 처음부터 — 첫 시도는 `build/`가 최신이라 컴파일 줄이 0개여서 "경고 0건"을 새 관측으로 인정하지 않고 버렸다):

```bash
xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
  -derivedDataPath .moai/state/verify/t49-sync/dd build > .moai/state/verify/t49-sync/ios-build-clean.log 2>&1
```

관측(`ios-build-clean.log`): `exit=0`, `** BUILD SUCCEEDED **`, `SwiftCompile` 42줄(`Shared/Store.swift` 2회 언급 — 실제로 컴파일됨). `warning:` 줄 2건은 둘 다 `appintentsmetadataprocessor … Metadata extraction skipped` 툴체인 공지이고(필터 대상), 그 밖의 소스 경고는 **0건**. 새 소스 파일 없음 → `xcodegen` 불필요(서명 리셋 없음).

## 7. 병합 전 리드에게 (정리 사항)

- 워크트리 루트에 **추적 안 된 `build-ios.log`**가 있고 `.gitignore`에 걸리지 않는다(`git status --short` → `?? build-ios.log`). 병합·커밋은 `git add -A` 말고 경로를 지정해서 스테이징할 것.
- 이 판정의 산출물 `.moai/state/verify/t49-sync/*`는 gitignore 대상이라 디스크에만 있다(재현 조각·판정서는 `.moai/reports/t49/`에 두었다).

## 8. 미검증(Gaps) · 잔여 위험

미관측:
- 시뮬레이터·실기기 흐름(progress §7의 운영자 시나리오). 드라이버는 결정적 재현일 뿐이다.
- 자정을 넘기는 끝 편집(T49에 케이스 없음 — 리뷰어도 못 본 항목).
- 명시 연결 바깥 편 구간만 있고 복귀는 추정인 혼합 상태(`linkedLegs`가 추정으로 안 내려감, 이전과 같음) — 앱이 이 상태를 만드는지 확인 안 함.
- 호출부 `ActivityDetailView.swift:327`·`AIAssistant.swift:2968`은 읽지 않았다.
- 변이(뮤테이션) 시험: 수리를 부분만 되돌려 각 단언이 잡는지는 안 봤다 — §2의 master 대조가 대신하는 전부다.

잔여 위험: 초 단위 `newEnd`(분 절사로 짝 풀림, progress §6-3), W1 이중 이동은 코드에 그대로 남아 있음.
