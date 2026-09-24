# t11 — C2 AddEventView 경합·할당량 묶음 (2026-09-24)

카드 t11 · 워크트리 `.claude/worktrees/t11` · 브랜치 `WT-eventview-race-quota` · 베이스 `f13ca3c`(디스패치 시점 origin/master와 일치 — 진입 직후 실측). 구현 커밋 `f0c18da`. 명세는 카드 본문 + 리드 디스패치 노트(20④ 표기 착오 정정 — 빈 이름 칩=20③ 기각 제외) + `day-close-20260924.md` §6·§7 + 같은 날 code-safety 보고서의 처방. 작업 주체: swift-impl(구현) → 레인 diff 전수 검토 → code-safety(렌즈 4종) → F1·F2·@MainActor 패치 레인 직접(사유는 §2 E7).

## §1 주장 (Claim)

1. **다섯 항목을 전부 구현했다.** 20① `recomputeEstimates` await 경합(estimateFlights 카운터 + await 뒤 신원·좌표 재확인)·20④ `gatedRows(seeding:)` 과부하로 인자 2벌 접힘·N1 `save()`→`travelSecondsHint` 양쪽 전달(+`updateEvent` 선택 인자 추가)·후속 19① `syncOriginBusy()` 단일 규칙·19② 권한 거부 출발지 안내 + prefillOrigin 조기 반환·19③ confirmedPlace 주석 좁힘. 20③ 빈 이름 칩은 구현 안 함(기각 지시).
2. **code-safety 렌즈 4종(H1~H4) 판정 전부 통과.** 발견 2건을 같은 커밋에 닫았다 — F1(재계산 왕복 창에 저장하면 옛 좌표 쌍의 estimates가 힌트로 흘러 옛 경로의 이동시간이 저장값으로 굳는 회귀 창 → `estimatesFor` 쌍 대조로 같은 쌍일 때만 힌트, 어긋나면 nil·저장 시 재조회 1회), F2(목적지 미선택 경로에서 권한 안내가 값 찬 줄에 잔존 → choose 출발지 갈래에 `syncFieldExtras()` 1줄). 처방받은 `recomputeEstimates` `@MainActor` 경화(flights 카운터 직렬화)도 포함.
3. **게이트 4종을 이 레인이 재실측해 전부 통과했다** — iOS·macOS BUILD SUCCEEDED swift 경고 0/0(최종본 각 1회)·proxy 7/7·드라이버 212/212 + 실데이터 대조 통과 + 샌드박스 잔존 0건.

## §2 증거 (Evidence) — 돌린 명령과 관측

| # | 명령 | 관측 |
|---|---|---|
| E1 | `git fetch origin` 후 `git rev-parse --short origin/master` | `f13ca3c` — 디스패치 베이스와 일치 |
| E2 | iOS 빌드(최종본): `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build` | exit=0 · `** BUILD SUCCEEDED **` · swift 경고 `grep 'warning:' \| grep -c '\.swift'` = **0** |
| E3 | macOS 빌드(최종본, 같은 형식 `-scheme besir-macOS`) | exit=0 · BUILD SUCCEEDED · swift 경고 **0** |
| E4 | 드라이버(워크트리 CLAUDE.md 레시피 — cat에 `Shared/EditCard.swift` 포함): `cat Shared/EditCard.swift Shared/AIAssistant.swift Tools/GuardDriver.swift > /tmp/gd-t11.swift && swiftc -o /tmp/gd-t11 …(CLAUDE.md 9파일) -parse-as-library && /tmp/gd-t11` | compile-exit=0 · run-exit=0 · `212/212 통과` · `[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다` · 컴파일 경고 12본(DirectionsService 8·LocationManager 3·PlaceSearch 1 — t9 기준선과 동일배분, **Store.swift 0건**) |

> **E4 문구 정정(sync 판정 N4)**: 처음 적은 "CLAUDE.md 블록은 EditCard만 빠진 옛 형태"는 사실이 아니다 — 워크트리·origin/master의 CLAUDE.md는 t1(`f9cd9bb`)부터 cat에 EditCard.swift를 포함한다. 빠진 것은 세션 컨텍스트에 자동으로 실린 **1차 체크아웃의 로컬 master**(`291db49`, origin보다 78커밋 뒤) 판뿐이고, 레인이 실제로 돌린 명령은 워크트리 레시피와 같으므로 게이트 수치는 그대로 유효하다.
| E5 | proxy: `npm --prefix proxy test` | exit=0 · `7/7 통과` |
| E6 | 드라이버 샌드박스 잔존: `ls -d $TMPDIR/besir-gd-*` | 0건 |
| E7 | 구현 경위: swift-impl 1스폰 완결(diff +78/−21, 양 빌드 무경고 관측 보고) → 레인이 diff 전수 대조(처방 일치·범위 밖 변경 0건) → code-safety 1스폰(렌즈 4종 PASS + F1·F2 확정·잔여 4건) → **F1·F2·@MainActor는 레인이 직접 패치** — code-safety가 마지막 스윕 중 429(5시간 한도, 21:15 리셋)로 종료돼 재위임이 막혔고, 패치는 그 검토자가 문서로 처방한 모양 그대로다 | 최종 `git diff --stat` = `2 files changed, 97 insertions(+), 21 deletions(-)` → 커밋 `f0c18da` |
| E8 | 드라이버 집합 무변경(F1/F2 패치 뒤): `git diff --name-only -- <드라이버 12파일>` | Store.swift(원래 N1 몫 — E4 실측 시점에 이미 포함)만. AddEventView.swift는 애초에 집합 밖 → E4의 212/212 귀속 유지(t9 E13과 같은 정당화) |

로그: `.moai/state/verify/6e87fbc3/`(ios-build-4.log · mac-build-4.log · driver-run.log · driver-compile-warnings.log · proxy-test.log). 중간 빌드 실패 2회(F1 튜플 비교 — 튜플은 Equatable 순응이 없어 옵셔널 `==` 승격 불가)는 그 자리에서 if-let 언래핑으로 수정했고 최종본이 E2·E3이다.

## §3 귀속 (Baseline-attribution)

- 게이트 4종 수치는 **이 레인이 2026-09-24에 워크트리 t11(f0c18da 최종분)에서 직접 실행**한 값이다 — t9/t10 측정의 인용이 아니다. E8로 드라이버만 입력 바이트 동일 귀속(t9 E13 관례).
- 빌드 경고 기준은 `grep 'warning:' | grep -c '\.swift'`(t3 확립 — appintentsmetadataprocessor 노이즈 제외).
- code-safety의 판정·F1·F2 좌표는 그 보고(읽기 전용, 현재 트리 본문 정독)에 귀속되고, 레인이 F1(isReady가 estimating을 안 봄·estimates는 재계산 착지시에만 갱신)·F2(ensureGatedRows·재계산 가드 둘 다 목적지 미선택으로 조기 복귀)를 코드로 재확인한 뒤 패치했다.

## §4 갭 (Gaps) — 검증하지 않은 것

- **실행 재현 없음.** 20① 경합·F1 저장 창·19① 스피너·19② 안내 문구는 전부 정적 추적으로 확정된 것이다. 시뮬레이터 스크립트(입력 문구+기대 결과+초기화 시점, `[[besir-verify-script-style]]`)는 운영자 몫 — t9 CHECKLIST 재생성판의 편집 시트 항목과 **같은 빌드**에서 볼 것(카드 지시 그대로). 제안 항목: ① 장소 바꾼 뒤 재계산 도중 모드 칩 소요시간이 옛 값을 되찾지 않는지 ② 권한 "안 함" 상태에서 새 일정 열 때 안내 문구·출발지만 고를 때 문구 해제 ③ 저장된 출발지 있는 편집 시트 냉시작 무스피너 ④(할당량) 저장 시 프록시 로그에 조회 0회.
- 실기기·VoiceOver 낭독 관측 없음(note가 줄 라벨과 결합 낭독되는지 — 렌더 경로는 EditCardView:156 패턴으로 코드 확인).
- 드라이버 exit 2/3 가지 관측 불가(t8·t9와 같은 한계). EventDetailView·AIChatView 등 카드 밖 표면은 code-safety Gaps 그대로 이월.

## §5 잔여 위험

- **notDetermined에서 시스템 프롬프트로 거부 전환**: prefill 루프가 5초를 다 쓰고 note는 다음 syncFieldExtras까지 늦게 뜬다(code-safety 잔여 2 — 자가 치유, 좁은 갭).
- **F1 수정의 남은 성질**: estimates가 현재 쌍과 일치하면 저장값은 폼 표시값과 같다 — 사용자가 옛 표시를 보고 저장하는 창은 20① 수리로 '옛 쌍'인 경우에만 닫혔고, 표시 갱신 전 수 초의 '재계산 중 표시 지연'은 존재한다(그 창의 힌트는 어긋난 쌍이므로 nil → 저장 시 재조회, 수리 전과 같은 정확성).
- 후속 20② 편집 모드 stale-gid 좁은 창은 t9 문서화 잔여 그대로(이 카드 밖, 카드 C8 계열).
- 거부 상태에서 옛 좌표 프리필 폐쇄(denied 판정이 currentLocation 확인보다 앞) — 의도적으로 읽힌 진실한 안내(code-safety 잔여 3).

## §6 리드에게 넘기는 것

1. **병합·done**: 브랜치 `WT-eventview-race-quota`(미푸시), 종결 커밋 `f0c18da`(구현) + 문서 커밋(plan.md 후속 19·20행 닫기·본 progress.md).
2. 카드 t11 완료 — §4의 시뮬레이터 4항목을 편집 시트 확인 목록에 추가할지는 ux-check/리드 판정.
3. 하네스 이력: swift-impl·code-safety 1스폰씩 정상. code-safety 종료 직전 429(21:15 리셋) — 이후 카드 스폰 시 같은 한도 주의.

## §7 sync FAIL 수리 (2026-09-24, 판정문 `sync-verdict.md` 처방)

sync 판정 **FAIL(D1·D2·D3 — 문서 인용 드리프트. 코드·게이트는 PASS)** 을 받아 판정문 처방 그대로 수리했다. 수리 커밋: 아래 백필.

- **D1** — CHECKLIST.md 표 10행의 인용 12개를 판정문 표의 새 좌표 그대로 이동(A1 :999 · F4 :1232-1258 · F5 셋(:64-65·:608·:681) · F7 :127 · H2 :1028-1038 · H3 :1204-1228 · K8 :1105-1119 · L1 :1323-1389 · L2 :1397-1453 · L3 :1436-1440). 판정문이 "옮기지 않는 것"으로 지목한 날짜 박힌 기록(L11·L467·L645·L647·L119·t2 기준선)과 AIAssistant 인용은 손대지 않았다.
- **D2** — 이월 목록 2번 "AddEventView 경합·표시 묶음"을 t10 1번과 같은 형식으로 **처리됨(2026-09-24, 카드 t11)** 표기.
- **D3** — plan.md 후속 14의 `AddEventView:276` → `:287`(본문 바이트 동일 — 판정문 대조 완료분). 같은 줄의 다른 파일 인용은 불변.
- **N1** — `@MainActor` 주석을 정정: View 순응으로 이미 주 액터(SDK View 프로토콜 선언)이고 병렬 경합 전제가 틀렸음을 적시, 속성은 문서적 명시로 유지(판정문 권고 문구).
- **N2** — buildCard의 별도 시드식을 지우고 `card = buildCard()` 직후 `syncOriginBusy()` 호출로 규칙을 실제 한 곳에 둬 "단일 규칙" 문구를 글자 그대로 참으로 만듦.
- **N4** — §2 E4의 CLAUDE.md 문구 정정(위 인용문 — 낡은 판은 1차 체크아웃 로컬 master 것).

**수리 게이트** (AddEventView가 바뀌어 재실측 — 드라이버는 컴파일 집합 불변이라 판정문 지시대로 생략):

```
iOS:  exit=0 · BUILD SUCCEEDED · swift 경고 0   (ios-build-5.log)
macOS: exit=0 · BUILD SUCCEEDED · swift 경고 0   (mac-build-5.log)
```

커밋 구성: 수리 1개(D1·D2·D3·N1·N2·N4 + 본 절) + SHA 백필 1개.
