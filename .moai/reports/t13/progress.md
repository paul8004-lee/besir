# t13 — 수정 경로 조용한 실패(C4) 진행 보고서 (2026-09-25)

카드: `moai todo` t13 "C4 수정 경로 조용한 실패 — Store.updateActivity pending/failed 기록(I1·N2 패턴 확장)".
근거: day-close-20260924 §6 row 7 · §7. 브랜치 `WT-edit-sync-status`(워크트리 `.claude/worktrees/t13`),
base `be20466` = origin/master. 코드 커밋 **`3b42e45`**, 문서 커밋은 본 보고서 포함 아래 커밋.

## §1 주장 (Claim)

1. `Store.updateActivity`의 재등록을 인라인 `try? await gcal.createEvent`에서 **업로드 큐 경유로** 바꿨다
   (본문 :272-289, 문서 주석 :263-271). 편집 자리에서 pending/failed 신호가 남고, 성공의 gid는 큐가
   단일 출처로 채운다 — `updateEvent`·`updateRecurringSeries`와 같은 모양·같은 문턱 셋
   (`googleConnected` 게이트, gid 저장 전 소거, `autoAddToCalendar` 재등록 게이트).
2. code-safety 권고 1건을 반영했다: sync 2-5(`reconcileActivities`)가 큐보다 먼저 올려 치웠을 때
   `.pending`을 아무도 해제하지 못해 설정 화면 "올리는 중"이 영구 좌초하던 상속 결함 —
   성공의 단일 출처는 gid라는 기존 원칙(:888/:921)을 2-5 성공 줄에도 적용(:1460-1462).
3. 문서: CHECKLIST 결함 4번 "처리됨(2026-09-25, 카드 t13)" 표기, CHECKLIST·plan 인용 좌표 29건
   재사상(코드 +18/−6에 따른 +9, reconcileActivities 함수 끝점은 2-5 한 줄까지 +12),
   맨몸 좌표 1건(`googleConnected` :481→:490), plan 후속 17의 :345→:354, 같은 문서 후속 20②의
   `:941-968`은 **base에서 이미 어긋났던 사전 오인용**이라 updateEvent 현 범위 :941-988로
   수리했다(출처는 1차 sync 판정이 **t7 `83bf259`로 정정** — 그 트리에서는 옳은 좌표였다).
   본 progress.md도 커밋한다(t12 sync 1차 FAIL D4의 재발 방지). *§1·§2의 좌표는 1차 커밋
   `3b42e45` 기준 — §6 수리에서 updateActivity가 :263-293으로 바뀌었고, 문서 좌표는 `258b49b`
   기준으로 재사상됐다.*

## §2 증거 (Evidence) — 이 레인이 이 트리에서 직접 관측

전 과정 로그: `.moai/state/verify/t13/`(driver-2.log · build-ios-2.log · build-mac-2.log · proxy-2.log).
1차 실측(swift-impl, 한 줄 반영 전) 로그도 같은 폴더(driver.log · build-ios.log · build-mac.log).
아래 수치는 **한 줄 반영 뒤 최종 트리 재실측치**다(1차와 기준선 변동 없음).

| 게이트 | 명령 요지 | 관측 |
|---|---|---|
| 가드 드라이버 | 워크트리 CLAUDE.md 레시피(EditCard 포함 cat 목록), 신선 컴파일 `/tmp/gd-t13b` | `driver_exit=0` · **212/212 통과** · 불변식 줄 9(전부 ✓) · `[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다` |
| iOS 빌드 | `xcodebuild -scheme besir-iOS -destination '…iPhone 17 Pro' -derivedDataPath <신선 dd>` | `ios_exit=0` · `BUILD SUCCEEDED` · **SwiftCompile 위상 42**(훈수 빌드 아님, Store.swift 컴파일 확인) · **swift 경고 0**(appintentsmetadataprocessor 공지 제외) |
| macOS 빌드 | `-scheme besir-macOS` + 신선 dd | `mac_exit=0` · `BUILD SUCCEEDED` · **위상 38** · warning: 1건은 appintentsmetadataprocessor toolchain 공지 = **swift 경고 0** |
| 프록시 | `npm --prefix proxy test` | `proxy_exit=0` · **7/7 통과** |

- 드라이버 2회(1차·최종) 모두 exit 0 — 기준선 212(t8 이후) 무변동. 샌드박스는 googleClientID
  비움이라 `googleConnected=false`, 이 변경 경로에 닿지 않는다(변경 전에도 마찬가지).
- code-safety(대항·신선 판단): 4부류(인덱스 무효화·조용한 실패·무한 증가·복제 계약) **신규 결함 0**,
  간결성 검사 "정리할 것 없음". diff가 위험을 줄이는 방향임을 근거와 함께 확인(보고서 §1).
- DerivedData(~300MB×2)·/tmp 바이너리 삭제 완료. 좌표 재사상 스크립트
  `.moai/state/verify/t13/shift_citations.py`(줄 단위 assert — 2번의 줄 오류를 스스로 잡았다).

## §3 귀속 (Baseline-attribution)

- 트리: 워크트리 `.claude/worktrees/t13`, 브랜치 `WT-edit-sync-status`, 코드 커밋 `3b42e45`
  (base `be20466`). 게이트 최종 재실측은 한 줄 반영 후 작업 트리 = `3b42e45` 내용.
- 근거 문서: `.moai/state/verify/t12-sync/src/.moai/reports/day-close-20260924.md`(§6·§7) — 1차
  체크아웃에는 day-close 보고서가 없어 t12 sync 검증 스냅샷 판을 읽었다(내용 동일성은 리드 확인 몫).
- 게이트 명령은 워크트리 CLAUDE.md 레시피 그대로(1차 체크아웃 판이 아님 — t11 사고 재발 방지).

## §4 미검증 (Gaps)

- **재등록 분기 런타임 미실행**: 드라이버 샌드박스·빌드 어디에서도 `googleConnected=true` 경로가
  돌지 않았다(이 결함 분야에 테스트 타깃이 없다 — 빌드·드라이버가 검증 상한).
- 시뮬레이터·실기기 관측 없음. 확인 문구(운영자 몫, 시뮬레이터 스크립트 방식):
  구글 계정 연결+캘린더 동기화 중인 활동 하나를 편집해 저장 → ① 설정 화면에
  "캘린더에 올리는 중 1건"이 떴다가 사라진다 ② 캘린더 앱에서 같은 활동이 **새 시간·새 제목**으로
  한 벌만 보인다(옛것 잔존·중복 없음). 실패 경로(못 올린 항목 N건 + 다시 시도)는 연결을 끊고
  편집해야 재현된다 — 상황 만들기가 사용자 몫이라 자동화하지 않았다.
- `enqueueCalendarUpload` 큐 자체의 동작(직렬화·pending 디스크 기록)은 이전 카드들이 닫은
  영역이라 재검증하지 않았다(호점만 추가).
- AI 편집 경로(AIAssistant :2220 → modifyActivity)도 수혜지만 AI 대화로의 회귀는 돌리지 않았다
  (드라이버의 AI 가드 단언 212에 영향 없음을 관측).

## §5 잔여 위험 · 후속 카드 후보

1. **[신규(활동 경로)였다 — D2로 수리됨]** autoAdd 끄김에서 활동 편집이 캘린더 사본을 조용히
   지웠다(정책만 형제에서 가져왔고, 활동에는 수동 재추가 버튼이 없어 복구 경로가 없었다 —
   1차 sync 판정 D2). 수리(운영자 결정 a): reRegister면 autoAdd와 무관하게 enqueue. 이벤트 쪽
   updateEvent :990·updateRecurringSeries는 여전히 autoAdd 게이트(수동 버튼이 있어 덜 아프다 —
   후속 카드 후보).
2. **[상속] 업로드 진행 중(.pending) 편집하면 재등록이 일어나지 않는다**(reRegister는 gid 존재
   조건) — 옛 내용이 원격에 붙고 sync도 치유 못 함. 구 코드와 동일.
3. **[기존 경로의 확대였다 — D3으로 봉쇄됨]** gid 소거 저장↔묘비 적립 창은 "한 틱 폭"이 아니라
   "스냅샷 뒤 2-2 전에 대기가 하나라도 있는 sync 전체"였다(2-2는 fetch 직후 고정된 묘비
   스냅샷을 읽는다 — 1차 수용 근거가 틀린 전제였음을 sync 판정이 정정). 옛 코드에도 있던
   경로를 1차 커밋이 넓혔고 결과는 옛 원격 사본이 새 활동으로 되살아나는 영구 유령이었다.
   수리: 비교-후-소거 + 2-2 실시간 묘비 게이트(활동 :1433·이벤트 :1396).
4. **[상속] `updateEvent`의 gid 삭제-후-비움 창**(:987-988): 삭제 대기 중 sync 1단계가 로컬 일정을
   통째로 지울 수 있는 형제의 약점 — 이번에 고친 경로가 피해 간 모양. 후속 카드 가치 있음.
5. **[관찰] 활동 편집 자리의 신호는 설정 화면 집계뿐** — ActivityDetailView는 calendarUpload를
   표시하지 않는다(EventDetailView는 :128/:135에서 함). C4 기준(생성 경로와 같은 신호 수준)은
   충족. 상세 화면 표시 확장은 ui-design 렌즈 후보.
6. **[정보] code-safety가 지적한 sync 2-5의 `try? createEvent` 침묵 스킵**은 이번 범위 밖 —
   2-5가 올리다 실패해도 `.failed`를 남기지 않는다(상속). 후속 카드 후보.
7. **[상속·공통 갭 — 1차 판정 ① 표가 지목, 이 보고서의 누락이었음]** 로그아웃 상태에서 편집하면
   재연결 뒤에도 캘린더에 반영되지 않는다(googleConnected 게이트가 gid를 보존하는데 sync는
   내용을 밀지 않는다) — updateEvent·updateRecurringSeries와 같은 공통 갭. 옛 코드는 편집마다
   로그인 화면을 띄우며 어차피 실패했으니 지금이 개선이다(N3 "모든 쓰기 경로가 googleConnected로
   막힌다"가 이 경로에서도 참이 됐다).

## §6 1차 sync 판정 FAIL(D1·D2·D3) 수리 — 2026-09-25, 코드 `258b49b`

판정문: `.moai/reports/t13/sync-verdict.md`(1차 체크아웃 소장). 게이트 4종은 판정문이 독립
재실측으로 이미 통과시켰고, 차단 결함은 문서 D1·코드 D2·D3. 수리 반영:

- **D2(운영자 결정 a)**: updateActivity 재등록을 autoAdd와 무관하게 enqueue로(:283 게이트는
  googleConnected+옛 gid 둘뿐). 1차 구현이 형제에서 가져온 autoAdd 게이트를 활동 경로에 들인
  회귀(사본 삭제만 남고 복구 없음)를 닫는다. 실패는 `.failed`로 설정 화면에 뜬다.
- **D3**: gid 소거를 removeFromCalendar 복귀 뒤 '레코드가 아직 그 gid일 때만'으로 되돌리고
  (:286-291), sync 2-2·이벤트 가져오기 게이트가 실시간 묘비 집합까지 보게 했다(:1433·:1396).
  1차의 "한 틱 폭" 수용은 스냅샷 전제 오류였다(§5-3 정정). 문서 주석 재작성(오탈자 '남어'
  흡수 — 판정 지적).
- **D1(문서)**: CHECKLIST 맨몸 꼬리 좌표 12건(판정 §2③ 표의 대상을 최종 트리 랜드마크로) +
  1차 재사상분의 구간 시프트(+4·+6·+8, 총 36건 — `shift_citations_2.py`, 줄 단위 assert).
  후속 20② 좌표 출처 정정: t9가 아니라 t7 `83bf259`에서 온 당시 옳은 좌표(판정 확인).
- **재게이트(수리 트리, 이 레인 재실측)**: 드라이버 **212/212·exit 0·불변식 9/9·실데이터 바이트
  대조 통과** · iOS `BUILD SUCCEEDED` 42위상·swift 경고 0 · macOS 38위상·경고 0(appintents
  공지만) · proxy 7/7 — 로그 `driver-3.log`·`build-ios-3.log`·`build-mac-3.log`·`proxy-3.log`.
- **code-safety 재판정: PASS-able** — 처방 충실성 5항목 전부 확인(D2 게이트·D3 순서·게이트
  2곳·오탈자·구조적 동치), 차단 결함 없음, "추적한 모든 인터리빙에서 사전보다 나쁜 경우
  없음". 잔여 4건 비차단: ①sync 2-1 경합이 autoAdd 꺼짐에서 D2 종결상태를 조건부 재현(결정적→
  경합 조건부로 축소) ②형제 간 재등록 정책 분기(updateEvent에 비교-후-소거 이식·셋 통합 후보)
  ③Task 주석 괄호 예시 뉘앙스(다음 편집 때 보강) ④좌표 재사상(본 절에서 완료). ①②는 후속
  카드 후보 — 리드 배치 판단.
- **커밋 구분**: 코드 `258b49b`(본 문서 커밋은 별도) — 판정 §3-1대로 좌표는 `258b49b` 기준.

## 리드에게

- 병합: `WT-edit-sync-status`(origin push 완료) — ff 가능(base be20466).
- t14(C5)는 `ActivityDetailView`·`AddEventView` 등을 건드린다 — 이 카드의 +18줄이 Store.swift
  좌표를 밀었으니 CHECKLIST는 이미 재사상 완료(29건), 이후 카드는 본인 diff 기준으로 다시 재야 한다.
- §5의 1·2·4·6은 후속 카드 후보로 day-close 이월 목록 성격상 리드 배치 판단.
