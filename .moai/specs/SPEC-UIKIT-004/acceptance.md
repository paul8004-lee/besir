# SPEC-UIKIT-004 — acceptance.md

계획 SPEC이므로 전 AC를 ⬜(미확인)로 시작한다.

본 SPEC은 **크롬 패스 + 중립 타입 확장**이다 — t2a가 "의도하지 않은 것은 안 바뀜"을 어포던스
대조로 보였다면, 이쪽은 그 규율에 더해 **시각 표기·기준 매핑이라는 두 계산의 소유권 이동**을
기계 신호(grep·swift 실측·드라이버)로 보인다. 뷰 렌더링은 가드 밖이므로 AC-009(시뮬레이터)가
대체 불가능한 증거다 — 드라이버 초록으로 갈음하지 않는다.

## AC 매트릭스

| AC | 대응 REQ | 검증 수단 | 상태 |
|---|---|---|---|
| AC-001 | REQ-001 | grep + 컴파일 | ⬜ |
| AC-002 | REQ-002~003 | swift 실측 | ⬜ |
| AC-003 | REQ-010~011 | grep | ⬜ |
| AC-004 | REQ-012 | 드라이버 | ⬜ |
| AC-005 | REQ-020~021·023 (REQ-022의 절 대조는 AC-006 7행·AC-009 5항) | grep + 시뮬레이터 | ⬜ |
| AC-006 | REQ-030 | **절별 대조** | ⬜ |
| AC-007 | REQ-031 | diff + 원본 대조 | ⬜ |
| AC-008 | REQ-040~041 | diff + 빌드·프록시 | ⬜ |
| AC-009 (시뮬레이터·실기기) | REQ-040·REQ-023 — 포괄 화면 증거 채널(REQ-001·002·020~022·030·031의 화면 판정 포함) | 기기 조작 | ⬜ |

세는 명령: `grep -c '^## AC-' acceptance.md` = **9**(Tier M 상한 16 아래).

---

## AC-001 — 포매터 소유권이 BesirTime 하나로 모인다 ⬜

- **Given** 사람이 읽는 시각 표기가 두 파일에 다섯 종이고(spec.md §1.2), 그중 `fullFmt`·`timeFmt`가
  `EventDetailView.swift:17-24`에 살며
- **When** 이사가 끝나면
- **Then**
  1. `grep -c "DateFormatter()" Shared/EventDetailView.swift` = **1** — 남은 하나는
     `shortTimeFmt`(`:26-29`)뿐이고 그 주석("경로 안내 단계 옆에 붙는 짧은 시각")이 그대로다.
  2. `grep -c "DateFormatter()" Shared/EditCard.swift` = **5** — `whenFormatter`·`compact`·
     `isoFormatter` + 신규 `full`·`clock`. 다섯의 패턴 문자열이 §1.2 표와 **한 글자도 다르지
     않다**(이사이지 재작성이 아니다).
  3. 호출부 `:179`·`:201`(줄번호는 이사 뒤 재실측)가 `BesirTime.full`·`BesirTime.clock`을
     가리킨다 — 화면이 포매터를 소유하지 않는다.

## AC-002 — 분의 0패딩이 포매터별로 정확히 산다 (t2a AC-009 S8 승계) ⬜

- **Given** `fullFmt`가 `when`과 패딩만 다른 쌍둥이고(mm vs m), "오후 3:5" 회귀가 이 카드의
  상시 함정이며
- **When** swift 실측 한 줄이 다섯 포매터로 `2026-09-17T15:05:00`(목요일)을 찍으면
- **Then** 결과가 이 표와 전부 일치한다(ko_KR):

| 포매터 | 기대 문자열 |
|---|---|
| `BesirTime.full` | `9월 17일 (목) 오후 3시 05분` |
| `BesirTime.clock` | `오후 3시 05분` |
| `BesirTime.when` | `9월 17일 (목) 오후 3시 5분` (비패딩 — 여기만) |
| `BesirTime.compact` | `9/17 (목) 오후 3시 05분` |
| `shortTimeFmt`(로컬) | `오후 3:05` |

실측은 `swift -e`(또는 /tmp 임시 스크립트)로 하고 **명령과 출력을 그대로 progress.md에
붙인다** — 패딩은 눈으로 봐야 하는 성질이 아니다. `shortTimeFmt`가 BesirTime 멤버로
존재하지 않는 것도 같이 확인한다(REQ-002 — `grep -c 'stepTime\|shortTime' Shared/EditCard.swift` = 0).

## AC-003 — 접두↔기준 매핑이 BesirTime 홀로 산다 ⬜

- **Given** 매핑이 10곳에 흩어져 있고(spec.md §1.3 표) 그중 8곳이 순수 매핑이며
- **When** 전환이 끝나면
  1. `grep -rn 'prefix == "arr:"\|prefix == "dep:"\|hasPrefix("arr:")' Shared/*.swift` = **2** —
     `EditCard.swift:139`(라벨 조립)와 `AIAssistant.swift:893`(인자 키)뿐, 둘 다 §1.3의
     열거된 유지다. 그 외 잔여는 미전환(REQ-011 위반).
  2. `grep -rn '? "arr:" : "dep:"' Shared/*.swift` = **0** — 기준→접두 삼항이 전부
     `BesirTime.prefix(for:)`로 갔다.
  3. `BesirTime.anchor(ofPrefix:)`·`prefix(for:)`가 `EditCard.swift`에 정확히 한 벌씩 있고
     `ScheduleAnchor`를 주고받는다 — `grep -c 'func anchor(ofPrefix:' Shared/EditCard.swift` = 1,
     `grep -c 'func prefix(for' Shared/EditCard.swift` = 1. (0.1.1 정정: `for`는 키워드라
     `func prefix(for:` 꼴은 관용 서명 `prefix(for anchor:)`과 공존할 수 없다 — 접두 일치로 잰다.)
  4. 치환 3개 파일(`AddEventView`·`EditCardView`·`AIAssistant`)의 diff가 **열거된 8줄만**
     담는다 — 줄 추가·삭제로 인접 인용이 밀리지 않았다(AC-008 2과 연결).

## AC-004 — 폼과 AI 카드의 관측 동작이 무변경이다 ⬜

- **Given** 드라이버가 시각 줄 왕복(`parseDatetime` 경로)과 장소 검색을 P 계열로 단언하고 있고
- **When** 매핑 전환과 포매터 이사가 끝나면
- **Then** 드라이버를 돌려 **기존 단언 전부가 여전히 초록이고 단언이 하나도 추가되지 않았다** —
  새 단언이 필요해졌다면 동작이 바뀐 신호다(REQ-012). 직렬화("arr:"+ISO)·칩 라벨("도착 "/"출발 ")·
  저장 anchor·툴 인자 키는 각각 `AC-003`의 grep 결과와 함께 원본 값 대조로 확인한다.

## AC-005 — 크롬이 전부 토큰을 지나고 컨테이너가 한 문법이다 ⬜

- **Given** 카드 2곳이 `.thinMaterial`/14, 시스템 보조색 11건, 원색 2건이고(§1.1)
- **When** 크롬 패스가 끝나면
  1. `grep -c 'thinMaterial' Shared/EventDetailView.swift` = **0**; 컨테이너 3곳(출발 카드·
     여정·상세행 신규)이 `Theme.raised` + `Theme.radius` + `Theme.line` 스트로크 문법이다.
  2. `grep -cE '\.secondary|\.tertiary|\.quaternary|\.red[^u]|\.green' Shared/EventDetailView.swift`
     = **0** — 예외는 D-4 변경 금지 목록뿐(`.white` 글리프·`Color(hex:)` 노선색·`Theme.bg`).
     (0.1.2 정정: `\.red`는 원본의 `.reduce(0)`에 오탐한다 — `[^u]`로 제외.)
  3. 지도 클립(`:59` 근방)은 `cornerRadius: 12` 유지 + 유지 사유 주석(D-4 표 2번).
  4. 출발 숫자가 `@ScaledMetric` 상대 크기(D-4 표 9번) — 큰 글씨에서 38pt 고정이 아니라
     함께 자란다(AC-009 시뮬레이터 10번).

## AC-006 — 어포던스가 절별로 대조된다 (일괄 통과 금지) ⬜

REQ-030의 대조 단위. 한 절 = 사용자가 지각하는 상호작용/정보 하나. **표의 행 수 자체가
실측이다** — 줄을 고치면 다시 세고 이 표를 맞춘다. 형태가 바뀌는 것은 "크롬" 칸에 적힌
것뿐이다:

| # | 절 (원본 근거 `9e4a374`) | 크롬 패스 뒤 | 판정 |
|---|---|---|---|
| 1 | 내비게이션 제목 = 일정 제목(`:72`) | 그대로 | ⬜ |
| 2 | 헤더 — 목적지명+`flag.fill`·주소·"도착 …"(`:172-182`) | 보조색 muted, 시각은 `BesirTime.full`(05분 유지) | ⬜ |
| 3 | 지도 280pt, 카카오/기본 전환(`:57-59`·`:92-106`) | 클립 12 유지(D-4) | ⬜ |
| 4 | 출발 카드 — 수단 아이콘+"약 N분"·출발 시각 큰 숫자·isPast 경고·남음+알림 문구(`:184-221`) | 컨테이너 교체, 색 nowLine/travel, `@ScaledMetric`, 결합 낭독 | ⬜ |
| 5 | "이동시간을 계산하지 못했습니다" 폴백(`:215-220`) | 그대로(이미 `Theme.activity`) | ⬜ |
| 6 | 대중교통 여정 — 헤더·"예상 시각"·단계행(글리프·헤드라인·디테일·시각)·ODsay 주의문(`:223-252`) | 컨테이너 교체, 주의문 faint, 단계 시각 "오후 3:05" 무변경 | ⬜ |
| 7 | 캘린더 — 등록됨/pending/실패+재시도/미연결 네 갈래(`:110-146`) | 분기·문구 그대로, 색만 토큰(REQ-022) | ⬜ |
| 8 | 상세행 — 이동 수단·버퍼·알림(+반복 배지)(`:302-310`) | 같은 카드 컨테이너로 감쌈(내용 무변경) | ⬜ |
| 9 | 삭제 — 단일 확인 / 반복·같은 제목 메뉴 2종(`:311-347`) | 그대로 | ⬜ |
| 10 | 편집 툴바 → 시트 `AddEventView(editing:)`(`:76-82`) | 그대로 — 편집 필드 0개(REQ-031) | ⬜ |
| 11 | 상대시각 문구 "X시간 Y분"(`:359-364`) | 그대로 | ⬜ |

## AC-007 — 편집 표면이 늘지 않는다 ⬜

- **Given** 이 화면의 편집이 전부 시트 위임이고(D-1 승계)
- **When** 구현이 끝나면
  1. `EventDetailView.swift`에 `TextField`·`Stepper`·`Toggle`·`Picker`(값 입력용)가 **0건**이다.
  2. `EditCardView`에 읽기 전용(`readOnly`·render mode) 분기가 **0건** 추가됐다 —
     `grep -c 'readOnly\|renderMode' Shared/EditCardView.swift` = 0.
  3. `.sheet` 제시(`:80-82` 계열)가 `AddEventView(editing: event)` 그대로다.

## AC-008 — 범위 경계와 품질 게이트 ⬜

- **Given** 본 SPEC의 소스 변경이 본체 2파일 + 열거된 8줄이라고 못박았고
- **When** 구현이 끝나면
  1. `git diff --name-only --diff-filter=A origin/master...HEAD -- 'Shared/*.swift'`가 **0건** —
     `xcodegen generate`를 돌리지 않는다(**서명 리셋·Team 재선택 요청이 없는 것이 통과 조건**,
     REQ-040 (d)).
  2. 바뀐 소스 파일은 `EventDetailView.swift`·`EditCard.swift`·`AddEventView.swift`·
     `EditCardView.swift`·`AIAssistant.swift` 5개뿐이고, 뒤의 셋은 REQ-011이 열거한 줄만 담는다.
     `Tools/GuardDriver.swift`도 예외가 아니다(AC-004 — 단언 추가 없음). 문서 예외는 루트
     `plan.md`·본 SPEC 4종·`progress.md`·`CHECKLIST.md`(sync)뿐이다.
  3. iOS·macOS 양쪽 **무경고** 빌드(툴체인 경고 제외), `cd proxy && npm test` 전체 통과.

## AC-009 — 시뮬레이터·실기기에서 화면이 온전하다 ⬜

드라이버가 못 보는 것의 목록. **시뮬레이터는 입력 문구 + 기대 결과를 정확히 준 스크립트
방식**(초기화 시점 포함)으로 돌리고, 실기기는 사용자가 직접 확인한다. 사용자에게 넘기는 것은
**내가 검증할 수 없는 것만**이다.

시뮬레이터(스크립트로 확인):
1. 일정 상세 열기 → 헤더 도착 시각이 `9월 17일 (목) 오후 3시 05분` — **05의 0 유지**(AC-002의
   화면 증거, t2a AC-009 S8 이월의 종결).
2. 출발 카드 큰 숫자가 `오후 3시 05분` — 미래 일정은 `Theme.travel` 녹색, 지난 일정은
   `Theme.nowLine` 적색(기준 시각을 바꿔 양쪽 다).
3. 카드 3곳(출발·여정·상세행)이 `Theme.raised` 배경 + 얇은 스트로크 — material blur가
   사라졌고 다크 모드에서도 대비가 산다.
4. 대중교통 일정 단계 옆 표기가 `오후 3:05` 그대로(shortTimeFmt 무변경).
5. 캘린더 네 갈래 — 등록됨(체크+녹색 토큰)/pending/실패+재시도/미연결 문구가 분기 그대로.
6. 상세행 블록이 카드로 감싸져 있고 수단·버퍼·알림 값이 그대로 읽힌다.
7. 편집 버튼 → t2a 카드 폼 시트가 뜨고, 저장하면 상세에 즉시 반영된다(기존 `event` 재읽기 경로).
8. 삭제 — 단일일 때 확인 한 번, 반복/같은 제목일 때 메뉴 분기가 그대로.
9. 지도 클립 반경이 기존 모양(12) 그대로 — D-4 유지 판정의 화면 확인.
10. 큰 글씨 최대 → 출발 시각 숫자가 함께 커지고 잘리지 않는다(`@ScaledMetric`). 다크 모드 →
    기기 설정을 따른다.

실기기(사용자 확인 목록 — 빌드로 검증 불가):
- VoiceOver: 출발 카드가 시각+상태 캡션을 한 덩어리로 낭독하는지, 단계행이 헤드라인+예상 시각을
  함께 읽는지, 지도의 이름.
- 카드 크롬의 실제 질감(raised+스트로크가 material 대비 어떻게 느껴지는지).
- 실제 푸시 알림 수신은 본 카드 무관(로직 무변경) — Day 닫기 목록에서 제외해도 됨을 확인.

실기기 전용 항목은 운영자 standing 정책(2026-09-18 — 검증은 시뮬레이터 스크립트 방식)에
따라 **Day 닫기 이월 목록**으로 리드가 넘긴다(t2a AC-009 판정 기록과 같은 형태로 처리한다).

🗿 MoAI
