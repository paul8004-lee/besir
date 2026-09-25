# t15 — C6 문구·주석 묶음 진행 기록 (WT-copy-wording)

카드: "C6 문구·주석 묶음 — 후속 18·19③·B5(이동 수단/이동수단 표기)·B7(계산 후 불가 수단 침묵)·
D-3 고지 문구(과거 일정 알림 안 걸림 화면 고지). 근거: day-close-20260924.md §7·이월 목록."
부류: Class B(SPEC 없음, plan 건너뜀). 베이스: origin/master `32df406`(t14 병합판).
원형 정의의 출처: t2 run 증거(13da206 — B5·B7·D-3(i) 이월 표)·t6 sync F4·F5(a32ad08 — 후속 18
①②)·t7 sync O3(83bf259 — 후속 19③)·day-close §6 #18·#25·#26 / §7 C6(841cf9a).

## §1 무엇을 고쳤나

| 항목 | 원형 근거 | 수리 | 좌표 |
|---|---|---|---|
| 후속 18① | t6 sync F4 — "유일한 보임새 변화" 주석이 채팅 요약 말풍선 표면을 빠뜨림 | 칩·확인 요약 말풍선 두 표면을 이름 붙이는 문장으로 교체(resolvePendingAsk의 chosenLabel 경로 명시) | AIAssistant.swift:757-760 |
| 후속 18② | t6 sync F5 — 사전 증가 차원이 "이름 수"→"지점 수"로 바뀐 데 천장 미기재 | "천장 = 이 대화에서 확정한 서로 다른 지점 수" 문단 추가 | AIAssistant.swift:772-773 |
| 후속 19③ | t7 sync O3 — nil 읽기 자리 나열("넷")이 전칭으로 읽히고 이미 낡음(현 5곳) | 자리 수 의존 제거, "신호로 읽는 곳은 prefillOrigin의 가드 하나뿐"으로 한정 | AddEventView.swift:654-662 |
| B5 | t2 ui-design 노트 — 표면 간 띄어쓰기 불일치 | "이동수단" 붙여쓰기 4곳 통일 | AddEventView.swift:245·EventDetailView.swift:340·Models.swift:4·:162 |
| B7 | t2 — 계산 후 불가 수단의 침묵(detail 접기의 승인 범위) | 모드 줄 노트가 "선택한 이동수단은 소요시간을 계산하지 못했어요. 저장할 때 다시 계산해요."를 말함. estimates가 빈 창(계산 전)에는 침묵 유지 — 계산 전과 계산 후 불가를 구분 | AddEventView.swift:569-576 |
| D-3 | t2 후속 표 — "과거 일정에는 알림이 안 걸린다"는 사실을 화면이 말하게 하기 | ① 폼 시각 줄 노트: 계산된 출발−리드 ≤ 지금이고 알림이 켜져 있으면 "출발 시각이 이미 지나 출발 알림이 예약되지 않아요."(리드 산식은 save()와 동일 우선순위) ② 상세 화면 캡션이 알림 상태를 사실대로: 꺼짐 / 예약됨 / 과거 거부 / 64건 창 밖 대기 | AddEventView.swift:597-615·EventDetailView.swift:227-233·:392-400 |

code-safety 발견 1 수기(FAIL→수리): 첫 판 삼항식이 `notificationId == nil`을 "알림 시각이 지나"로만
단정했으나, 64건 리스케줄러(`rescheduleNearestNotifications`, Store.swift:1216-1242 — 전체
notificationId nil화 후 가까운 60건만 리필해 디스크에 저장)가 만드는 창 밖 nil에서 거짓이 된다
(3주 뒤 일정에 "3주 남음 · 알림 시각이 지나"라는 자기모순). `alarmStatus` 헬퍼가 알림 시각
(출발−리드 ≤ 지금)으로 원인을 갈라 창 밖에는 "가까워지면 알림 예약돼요"를 내보내게 수정했다.
같은 판의 대입 전용 if/else는 ViewBuilder에서 해석되지 않아 빌드가 깨졌었음(삼항→헬퍼로 해소).

하네스: ui-design(뷰 3파일 편집) + code-safety(렌즈 7종 심사) + 레인 직접(AIAssistant 주석 2건,
code-safety 수리 적용, 게이트 4종).

## §2 증거 — 돌린 명령과 관측 (발견 1 수리 뒤 최종 트리 전수 재실측)

| 게이트 | 명령 | 관측 |
|---|---|---|
| iOS | `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build > build-ios.log 2>&1` | exit 0·`** BUILD SUCCEEDED **` 1회·Swift 경고 0(`grep "warning:" build-ios.log | grep -v appintentsmetadataprocessor | sort -u` 출력 0행) |
| macOS | `xcodebuild -scheme besir-macOS -derivedDataPath build build > build-mac.log 2>&1` | exit 0·`** BUILD SUCCEEDED **` 1회·같은 필터로 경고 0 |
| 프록시 | `cd proxy && npm test` | `7/7 통과`·exit 0 |
| 가드 드라이버 | `cat Shared/AIAssistant.swift Tools/GuardDriver.swift > /tmp/gd15.swift && swiftc -o /tmp/gd15 /tmp/gd15.swift Shared/EditCard.swift Shared/Store.swift Shared/Models.swift Shared/Config.swift Shared/PlaceSearch.swift Shared/DirectionsService.swift Shared/LocationManager.swift Shared/NotificationManager.swift Shared/GoogleCalendarService.swift Shared/SharedInbox.swift -parse-as-library && /tmp/gd15` | `217/217 통과`·exit 0·`[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다` |
| B5 잔여 | `grep -rn "이동 수단" Shared/ ShareExtension/` | 0건(exit 1) |
| code-safety 심사 | 미커밋 diff 전수(`git diff`) 렌즈 7종 | 발견 1(중간) — §1 수기로 수리. H1·H3·H5·간결성 0건, H2 판정 2건(D-3 침묵=보수적 설계·B7 "저장할 때 재계산" 전 경로 사실 — addEvent Store.swift:600-601·updateEvent :975-976 대조), H4 수용(아래 §5) |

빌드 로그 원본: 워크트리 루트 `build-ios.log`·`build-mac.log`(미커밋 — 각 끝 줄 `** BUILD SUCCEEDED **`).

## §3 귀속

- 베이스 origin/master `32df406`. 워크트리 `.claude/worktrees/t15`, 브랜치 `WT-copy-wording`.
- 수리 전 iOS 1회 실패(exit 65 — EventDetailView.swift:215 ViewBuilder 제네릭 추론 오류)는
  alarmStatus 헬퍼 도입으로 해소됐고, §2의 네 게이트는 그 뒤 최종 트리에서 전부 재실측한 값이다.
- 드라이버 217/217 = t23이 세운 기준선과 동일(t10~t15 간 가드 단언 무변경).
- **CLAUDE.md 드라이버 레시피 낡음 발견**: CLAUDE.md의 컴파일 파일 목록에 `Shared/EditCard.swift`
  (t2 추가)가 없어 그대로는 `cannot find type 'EditCard'`로 링크 실패한다. 이번 실행은 EditCard.swift를
  추가한 목록으로 돌렸다 — CLAUDE.md 본문 갱신은 이 카드 범위 밖으로 리드에 넘긴다.

## §4 갭 — 검증하지 않은 것 (증거 없음 ≠ 통과)

- 런타임 화면: B7 노트가 큰 글씨에서 출처 캡션과 함께 최대 2문장으로 늘어나는 보임새, D-3 두
  문안의 체감, VoiceOver 낭독 — 시뮬레이터·실기기 눈확인 필요(ux-check 확인 목록 항목).
- code-safety 재심사: 발견 1 수리(alarmStatus)는 레인이 적용하고 네 게이트를 다시 돌렸으나
  전문가 재리뷰는 아직 — sync 게이트가 알림 진실성 관점에서 확인할 것.
- CHECKLIST.md:520 항목 6(이 묶음)의 "처리됨" 갱신은 sync 몫(t13·t14 전례 — sync 판정 근거와
  함께 적는다).

## §5 잔여 위험

- D-3 폼 노트는 syncFieldExtras 호출 시점의 `Date()`로 판단한다 — 폼을 띄운 채 자정을 넘기면
  노트가 다음 카드 변경·재계산까지 갱신되지 않는다. 문장이 "지나야" 말하는 방향이라 과잉 낙관은
  없고 놓칠 수만 있다.
- 출발 역산 산식(`parsed.date.addingTimeInterval(-secs - buffer)`)이 AddEventView에 세 곳(예상
  출발 노트 :594·D-3 depGuess :609·currentConflicts :684) — Store의 @MX:DEBT 합침 트리거
  (Store.swift:1008-1011, "네 번째 호출처가 생기면 합친다") 기준에 도달. 네 번째 표시 자리가
  생기면 depGuess를 한 번 올려 공유할 것.
- "가까워지면 알림 예약돼요"는 앱이 다시 foreground될 때 리필된다는 앱 모델 전제(Store.swift:1210-1213
  주석) 위의 문장이다 — 앱을 다시 켜지 않으면 예약은 일어나지 않는다.
- EventDetailView.swift:349 정보 행이 알림이 꺼져 있어도 "알림 | 출발 N분 전"을 보이는 기존
  결함(code-safety 잔여 노트) — 카드 범위 밖, 후속 카드 후보로 기록.
