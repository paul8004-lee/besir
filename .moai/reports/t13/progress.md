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
   `:941-968`은 **t9 트리 좌표로 be20466에서 이미 어긋났던 사전 오인용**이라 updateEvent 현 범위
   :941-988로 수리(t7의 "이전 오인용 수리" 선례). 본 progress.md도 커밋한다(t12 sync 1차 FAIL D4의
   재발 방지).

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

1. **[상속·정책] autoAdd 끄김 상태에서 gid 있는 활동 편집 시 원격에서만 사라진다**(재등록 안 함) —
   updateEvent :986·updateRecurringSeries :784와 동일 정책. 세 편집 경로가 같으므로 패리티는
   유지됐고, 정책 자체를 바꿀지는 별도 판단.
2. **[상속] 업로드 진행 중(.pending) 편집하면 재등록이 일어나지 않는다**(reRegister는 gid 존재
   조건) — 옛 내용이 원격에 붙고 sync도 치유 못 함. 구 코드와 동일.
3. **[신규·관찰·수용] gid 소거 저장↔묘비 적립 사이 미세 창**(메인액터 한 틱 폭): 그 창에서 죽거나
   끝난 sync가 끼면 다음 sync 2-2가 옛 원격 사본을 중복 가져올 수 있다(제목·시간이 바뀌었으면
   중복 판정이 못 막음). 형제 경로들도 각자 같은 폭의 창을 갖는다 — code-safety는 "수용 합리적"
   판정(묘비 선적립은 removeFromCalendar 첫 두 줄 복제를 치러야 한다).
4. **[상속] `updateEvent`의 gid 삭제-후-비움 창**(:982-984): 삭제 대기 중 sync 1단계가 로컬 일정을
   통째로 지울 수 있는 형제의 약점 — 이번에 고친 경로가 피해 간 모양. 후속 카드 가치 있음.
5. **[관찰] 활동 편집 자리의 신호는 설정 화면 집계뿐** — ActivityDetailView는 calendarUpload를
   표시하지 않는다(EventDetailView는 :128/:135에서 함). C4 기준(생성 경로와 같은 신호 수준)은
   충족. 상세 화면 표시 확장은 ui-design 렌즈 후보.
6. **[정보] code-safety가 지적한 sync 2-5의 `try? createEvent` 침묵 스킵**(:1456)은 이번 범위 밖 —
   2-5가 올리다 실패해도 `.failed`를 남기지 않는다(상속). 후속 카드 후보.

## 리드에게

- 병합: `WT-edit-sync-status`(origin push 완료) — ff 가능(base be20466).
- t14(C5)는 `ActivityDetailView`·`AddEventView` 등을 건드린다 — 이 카드의 +18줄이 Store.swift
  좌표를 밀었으니 CHECKLIST는 이미 재사상 완료(29건), 이후 카드는 본인 diff 기준으로 다시 재야 한다.
- §5의 1·2·4·6은 후속 카드 후보로 day-close 이월 목록 성격상 리드 배치 판단.
