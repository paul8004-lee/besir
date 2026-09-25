# t14 — Theme·계약 6 정리(C5) 진행 보고서 (2026-09-25)

카드: `moai todo` t14 "C5 Theme·계약 6 정리(ui-design 렌즈) — CB 3건 + 같은 부류 7건 + 후속 16 두 건 +
후속 3·4(PlaceField radius·돋보기 접근성 라벨) + 신규: 카드의 장소 검색·날짜 시각 고르기 버튼
점선→실선". 근거: day-close-20260924 §6 rows 12·17·§7 + 운영자 실기기 확인 세션(2026-09-24).
브랜치 `WT-theme-token-cleanup`(워크트리 `.claude/worktrees/t14`), base `45c26eb` = origin/master.
코드 커밋 **`96529a4`**, 문서 커밋은 본 보고서 포함 아래. sync 수리(§7): 코드 **`df827b7`** + 수리 문서 **`1eceb43`**.

## §1 주장 (Claim)

1. **계약 6 위반 정리(11파일 +41/−35)** — 디스패치 노트대로 day-close 좌표를 현재 트리에서
   재실측해 확정했다(CB 3건은 `AddEventView :732·:735·:740` — t13 수리에서 CHECKLIST에 재사상된
   좌표와 일치). 매핑(치환 계수는 sync 판정 D3 정정값): `.secondary`→`Theme.muted` **16곳**,
   `.tertiary`→`Theme.faint` **2곳**, 직접 색 **4건**(`.white`·`.primary`·`.yellow`·`.green`) —
   AIChatView 말풍선 `.white`/`.primary`→`Theme.bg`/`Theme.ink`(다크 대비 2.51→7.26:1, sync 판정
   contrast.py 실측 — 최초 보고의 ≈2.5→≈7.3은 손계산 근사), FavoritesView 별
   `.yellow`→`Theme.activity`(브라스), SettingsView 연결됨 `.green`→`Theme.travel`. 카드 좌표 밖
   같은 부류 **13곳**(FavoritesView 4·FullSirView 6·SettingsView 2·AIChatView:85)도 디스패치 계약
   문구 "색은 전부 Theme 토큰 경유"에 따라 함께 정리했다. **커밋 `96529a4` 메시지의 17·3·5는
   오기다(실측 16·2·4).** "전수 정리"였던 최초 주장은 스윕이 `.tint(`를 못 본 탓에 성립하지
   않았다 — §7 D4 참조.
2. **literal 반경 3건 → `Theme.radius`**: `AddEventView:740`(ConflictBanner)·`AddActivityView:574`
   (PlaceField 선택 박스 = 후속 3)·`AIChatView:115`(말풍선 — 판단 항목으로 통일. 말풍선도 면이며
   둥근 문법은 칩 Capsule에만 남긴다는 why-주석 신설).
3. **후속 4**: 돋보기(장소 검색) 버튼에 `.accessibilityLabel("장소 검색")` 부착
   (`AddActivityView:596`, Button 자체에, why-주석 동반 — 아이콘 전용 버튼은 VoiceOver가 읽을
   문구가 없었다).
4. **신규(점선→실선)**: `chip()`의 `dashed` 파라미터 제거(호출 6건 전수 확인 — 2건 갱신·4건
   기본값), `StrokeStyle(dash:)` 형태 축소, 점선 서술 주석 4건 갱신(EditCardView:182·:262-264·
   EditCard:161·AIAssistant:589 — 스윕으로 발견한 스스로 낡은 문서). `startsOpen` 깃발 논리 무변경.
5. **문서화 예외 2건 유지**: `EventDetailView:61`(지도 클립 12 — D-4 2번 유지 판정, 기존 주석)·
   `EventDetailView:286`(`.white` — API 제공 노선색 뱃지 위 글자. 적응형 토큰을 못 쓰는 이유를
   why-주석으로 신설).
6. **문서**: CHECKLIST 결함 5번 "처리됨(2026-09-25, 카드 t14)" 표기 + 이 카드 줄 밀림에 따른 인용
   재사상 5건(§아래), CLAUDE.md 출시 전 제거 목록의 SettingsView #L71→#L72, plan 카드 표 t14 행
   신설, 본 progress.md 커밋.

## §2 증거 (Evidence) — 이 레인이 이 트리에서 직접 관측

전 과정 로그: `.moai/state/verify/t14/`(proxy.log·driver.log·build-ios.log·build-mac.log).

| 게이트 | 명령 | 종료 | 관측 |
|---|---|---|---|
| proxy | `cd proxy && npm test` | 0 | "7/7 통과" |
| 드라이버 | CLAUDE.md 레시피(EditCard.swift 포함 판) | 0 | "217/217 통과" + "[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다" |
| iOS 빌드 | `xcodebuild -scheme besir-iOS …iPhone 17 Pro` | 0 | BUILD SUCCEEDED, 경고 필터(appintentsmetadataprocessor 제외) **0건** |
| macOS 빌드 | `xcodebuild -scheme besir-macOS` | 0 | BUILD SUCCEEDED, 같은 필터 **0건** |

- 드라이버 컴파일 경고는 `LocationManager`·`DirectionsService`의 macOS 26 SDK 지정 폐기 안내 —
  t14가 건드리지 않은 파일의 기존 것.
- 스윕(레인 재실행): `grep "foregroundStyle(\.\|foregroundColor(\." | grep -v Theme.` → 잔여 1건
  (`EventDetailView:286` 문서화 예외); `grep "cornerRadius: [0-9]" | grep -v Theme.radius` → 잔여
  1건(`EventDetailView:61` 문서화 예외); `grep "dashed\|점선" Shared/` → **0건**; colorLiteral·
  legacy `foregroundColor` 비-Theme → 0건.
- 구현(ui-design) 보고의 diff 통계·좌표는 레인이 재관측해 일치 확인(`git diff --stat` 11파일
  +41/−35 동일).
- code-safety 독립 검토: **PASS** — 7렌즈 전부 구동(await 불신 0·조용한 실패 0·외부 한도 0·
  단일 출처 0·간결성 0·빌드 밖 의미론 0·크로스 플랫폼 0), FIX-NOW 0·권고 3(§5).

## §3 귀속 (Baseline-attribution)

- 트리: 워크트리 `.claude/worktrees/t14`(base `45c26eb` = origin/master)에서 전 과정 실측.
  게이트는 코드 커밋 `96529a4`와 같은 작업 트리(커밋 전후 내용 동일 — 스테이지만 된 상태).
- 기준선: 드라이버 **217/217**(t23 판정 기준선과 동일 — 이 카드는 모델측 무변경이라 단언 수
  불변), proxy **7/7**(verify 스킬 재측정 기준선), 빌드 **무경고**(경고 필터는 스킬 재료 그대로).
- ui-design 구현은 하네스 전문가(hns-besir-app-ui-design-specialist), code-safety 검토도 하네스
  전문가(hns-besir-app-code-safety-specialist) — 레인은 명단표(CLAUDE.md)에 따라 배정·재관측.

## §4 갭 (Gaps) — 검증하지 않은 것 (증거 없음 ≠ 통과)

- **화면 렌더링 실측 없음** — 말풍선 곡률 14→3의 보임새, 세이지 "연결됨" 행, 실선 칩의 탭 가능성
  인지, 다크 모드 대비(손계산 근사)는 시뮬레이터·실기기 몫(§5 목록). 빌드는 컴파일만 증명한다.
- code-safety의 대비비는 손계산 근사였다 — sync 판정이 contrast.py(WCAG 2.x 상대휘도)로
  실측해 7.26:1로 닫았다(§1.1·§7 정정 반영).
- `ShareExtension/ShareViewController.swift` — `:13` `.label`·`:18` `.secondarySystemBackground`
  미문서화 시스템 색 + `:19` cornerRadius 14(UIKit layer). 기존·카드 범위 밖이고 구조적 이유가
  있다(확장 타깃에 Theme.swift가 없어 고치려면 xcodegen이 필요 — sync 판정 §2 ②). "각진 면"
  전체 적용 시 후보.
- 아이콘 전용 버튼 무라벨 부류 — 이 카드가 지목받은 1건(AddActivityView:596)과 sync 수리에서
  쌍둥이까지(FavoritesView:55 → 라벨 `:58-59`) 닫아 **head 기준 15건 중 14건이 남는다**(sync 판정
  §2 ④ 열거, 좌표 정정 반영): FavoritesView:36 trash·FullSirView:144 돋보기·FullSirView:291
  trash·FullSirView:60·AIChatView:64 `.help`만(iOS VoiceOver 불능)·AIChatView:58(테스트용)·
  AIChatView:143 전송·ContentView:197 sync(macOS)·ContentView:209·:213·:217·:222·:227(Menu)·
  :242 메인 툴바(`.help`만). **별도 a11y 스윕 카드 후보**(등록은 리드 소관).
- t9 회차 관찰 기록(CHECKLIST :648-)의 옛 좌표들(AddEventView:119·:549·:614 계열)은 그 문서
  자체 정책("그날 좌표 기록으로 둔다")에 따라 역사 기록으로 미수리 — 살아있는 행(F5 :244)은
  현행 좌표로 무변확인.

## §5 잔여 위험 (Residual-risk)

- 점선으로만 구별되던 직접입력/고르기 칩이 실선이 되어 값 칩과 테두리가 같아졌다 — 구별은
  글자가 담당하나 "탭할 수 있는 게 하나 더"로 읽히는지 기기 확인 필요(아래 ②).
- 권고 3건(code-safety, 비차단): ① 반경 3건은 시각 변화가 있는 크롬 변경(로직 무변화 한정
  "무변화") ② a11y 아이콘 부류 별도 카드 ③ ShareExtension literal 반경 — 전부 §4·여기에 기록.
- 확인 목록(운영자 — 시뮬레이터/실기기):
  1. AI 채팅 내 말풍선 글자가 **다크 모드에서도** 읽히는지(옅은 세이지 바탕 + 어두운 글자로 바뀜).
  2. 카드의 "장소 검색"·"날짜·시각 고르기" 칩이 다른 칩과 같은 실선 — 점선이 사라진 뒤에도
     "이걸 눌러 직접 고른다"로 인지되는지.
  3. 설정 "구글 계정 연결됨" 행이 세이지로 여전히 **성공 상태**로 읽히는지(이동 의미로 오독 안 되는지).
  4. 즐겨찾기 별이 브라스(옐로 아님) — 채움 상태 구분.
  5. 일정 만들기 겹침 배너(ConflictBanner) 모서리·보조 글자색.
  6. VoiceOver로 장소 검색 돋보기 버튼이 "장소 검색, 버튼"으로 낭독되는지.
  7. iOS "최근 먹은 것" 행의 휴지통 아이콘(FullSirView.swift:294): 옛 틴트색에서 회색으로
     바뀌었는지, 그것이 의도에 맞는지(sync 판정 §5 ⑦).
  8. 즐겨찾기 추가에서 이름 칸을 비운 채 검색 결과 행(FavoritesView — sync 판정 기준 :66-67,
     A1 수리 뒤 현 좌표 :68-69): 비활성일 때 주소 줄도 이름과 함께 흐려지는지(iOS·macOS).
  9. 겹침 배너를 **라이트 모드**로 — 겹치는 일정 이름(muted 2.84:1)과 안내문(1.70:1)이
     읽히는지(sync 판정 §5 ⑨ — 전부터 이 대비였고 회귀 아님).
  10. 일정 상세 지도의 출발 마커가 세이지로 보이는지(D4-a 수리 — sync 판정 §5 ⑩).

## §6 문서 인용 재사상 목록 (이 카드 줄 밀림 분)

| 문서:행 | 옛 인용 | 새 인용 | 사유 |
|---|---|---|---|
| CHECKLIST:270 (G11) | EditCardView:482-530 | :480-528 | chip() −2 |
| CHECKLIST:368 (N2) | SettingsView:51-69 | :52-70 | :30 why-주석 +1 |
| CHECKLIST:397 (P1) | EditCardView:318-346·:349-370 | :316-344·:347-368 | chip() −2 |
| CHECKLIST:401 (P5) | EditCardView:334-339 | :332-337 | chip() −2 |
| CLAUDE.md:139 | SettingsView#L71 | #L72 | 같은 +1 |

안정 확인(재실측 일치): AddEventView :71-72·:138·:646·:719, AddActivityView:509, EditCard.swift
:161·:240·:294·:317, EditCardView:31-35·:50-54·:125-128·:145-152·:175-180, AIAssistant
:589 외 무변경(문서 주석 1줄 치환), EventDetailView:108-144·:121-157·:159-164(변경 :284+가 뒤라
무영향). **정정(sync D6)**: 최초 판이 "일치"로 적은 `EditCardView:186-263`(CHECKLIST G16 인용)은
base부터 끝점 오기였다 — `datetimeRow`는 `:186-254`이고 `:263`은 chip() 문서 주석 줄이다.
CHECKLIST:275 G16을 `:186-254`로 고쳤다.

## §7 sync 판정(D1~D6) 수리 (2026-09-25)

판정: `.moai/reports/t14/sync-verdict.md`(1차 체크아웃 소장) — **FAIL(문서·완결성 주장)·코드
PASS**. 처방(판정 §3)과 리드 결정(D4=a·A1 포함)을 그대로 수행했다.

- **D1** plan 후속 14의 EditCardView 좌표 6개 + 본문 grep 출력 4수를 옮겼다(`:310`→`:308`·
  `:383`/`:384`→`:381`/`:382`·`:318-346`→`:316-344`·`:313-316`→`:311-314`, grep
  `383·384·435·436`→`381·382·433·434`). 수리 코드는 EditCardView를 건드리지 않아 판정의
  `35b24e2` 기준 좌표가 그대로 유효하다.
- **D2** plan 후속 3·4·5·16에 "**닫혔다 — t14(`96529a4`, 2026-09-25)**" 표기. 후속 16의
  `AddActivityView:575`는 base부터 한 줄 어긋난 좌표였음(반경 줄은 base `:574`)도 적었다.
- **D3** 치환 계수를 실측 16·2·4·스윕 13으로 정정(progress §1.1·CHECKLIST 블록 5·plan t14 행).
  커밋 `96529a4` 메시지의 17·3·5는 고칠 수 없어 §1.1에 오기로 기록. CHECKLIST가 말풍선
  bg/ink(카드 내 후속 16)을 스윕에 넣던 plan 행과의 모순도 풀었다.
- **D4(리드 결정 a)** `RouteMapView.swift:28` `.tint(.blue)`→`.tint(Theme.travel)` + why-주석.
  최초 스윕 명령에 `.tint(`가 없어 놓친 것이다.
- **A1** `FavoritesView.swift` 돋보기 버튼에 같은 접근성 라벨(`:58-59`) — AddActivityView:596의
  쌍둥이(리드가 이 카드에 포함시켰다).
- **D5** SPEC-UIKIT-001 spec.md REQ-021(h)·SPEC-UIKIT-003 plan.md 반증 신호 줄에 t14 대체 표기
  (본문 보존, 주석만).
- **D6** §4 좌표 정정(FullSirView:293→:291·AIChatView:63→:64)·a11y 잔여 14건 등재·§5 ⑦~⑩
  추가·§6 안정 목록 정정·CHECKLIST G16 `:186-254`.

**수리 게이트(코드 `df827b7` 트리, 이 레인 재실측)**: 신선 DerivedData 전체 빌드 — iOS exit 0 ·
BUILD SUCCEEDED · `^SwiftCompile` **42** · RouteMapView·FavoritesView 컴파일 줄 확인 · Swift 경고
0; macOS exit 0 · **38** 위상 · 같은 확인 · 경고 0(로그 `build-ios-2.log`·`build-mac-2.log`,
dd 약 306MB는 센 뒤 삭제 — t5 sync 재측정 규율). 드라이버·proxy는 재실측 생략 — RouteMapView·
FavoritesView가 드라이버 컴파일 집합 밖이고 proxy는 무변경(판정 §1이 같은 근거로 독립 재실측
완료).

**수리 후 좌표 재사상**: A1의 +2줄로 FavoritesView 인용이 밀렸다 — 주소 줄 `:67`→`:69`(§5 ⑧에
병기). RouteMapView·EditCardView는 이 판 문서 인용 0건·불변(grep 확인).

권고 A2~A10은 판정문 기록만 남긴다(카드 배치는 리드 소관 — A2 겹침 배너 안내문 muted 이동·
A5 고대비·A6 토큰 의미 불일치·A8 중복 쌍둥이 등이 후보).
