# t10 — 드라이버 위생(C1) 완료 보고 (2026-09-24)

카드 t10 · 워크트리 `.claude/worktrees/t10` · 브랜치 `WT-driver-hygiene`(미푸시) · 베이스 `296b579`(= 디스패치 시점 origin/master, 진입 직후 fetch로 확인). 작업 주체: run 레인 오케스트레이터(판정·문서·게이트·Q절 쌍 승인) + 전문가 둘(swift-impl 구현 → code-safety 대항 리뷰). 리드 디스패치의 운영자 결정 2건을 그대로 시행했다: **O-1 = 차단 코드 시행 + CLAUDE.md:58 문구 현행 유지 / 스위퍼 = 미도입, 수동 청소 절차만 문서화.**

## §1 주장 (Claim)

1. **O-1 차단 코드를 넣었다** — 드라이버 시작 블록이 `googleClientID` 비움 옆에서 `proxyBaseURL`·`appToken`도 비운다(GuardDriver.swift:318-326). 샌드박스의 `AppConfig.load()`는 내장 기본값을 주고 그 둘은 살아 있는 값이었기에, 비우면 `hasProxy`가 거짓이 되어 프록시 경유 조회(카카오 키워드·ODsay ETA·모델 `/ai/chat`)가 전부 구조적으로 막히고 조회는 로컬 MapKit 폴백으로 간다. **CLAUDE.md:58 "(API 할당량 안 씀)" 문구는 결정대로 한 글자도 바꾸지 않았다** — 차단 뒤 이 문장이 참이 된다.
2. **전역 불변식이 프록시 비어 있음을 함께 잰다** — `drvAssertNoCalendarPush`를 `drvAssertGlobalInvariants`로 개명(:338)하고 첫 drvCheck에 조건을 병합했다(호출 3자리 :360·:1492·:1755, **drvCheck 수 불변 — 기준선 212 유지의 설계적 근거**).
3. **O-2 절마다 파일 백업 9쌍을 전부 제거했다** — Q·J·Y·N·Z·P절의 파일 백업/복원 쌍과 고립 URL 선언 9개. favorites 메모리 쌍 2개(zFav/psFav — 절 격리 기능)와 `drvPersistedPayload` 내부 백업은 유지. **Q절 쌍은 구현 중 예상 밖 독자(`AIAssistant.init`의 `loadHistory`가 매 `fresh()`마다 ai_history.json을 재독쓰)가 발견돼 swift-impl이 STOP했고, 레인이 등가 판정(파일 없음 ≡ 인사말 상태 — 인사말 리터럴 :119/:223 바이트 동일, loadHistory 복호 경로 전원 no-op)을 내려 제거를 승인했으며, code-safety가 이 유도를 대항 검증해 확인했다.**
4. **재게이트를 전부 이 레인이 재실측해 통과했다** — 드라이버 212/212(기준선 무변동)·불변식 9/9·실데이터 해시 무변경·소켓 표집 0건·iOS·macOS 무경고 빌드·proxy 7/7.
5. **스위퍼는 도입하지 않고 CLAUDE.md에 수동 청소 절차를 문서화했다**(잔여 샌드박스 이름·UUID 모양 확인 후 삭제).
6. **문서를 코드에 맞췄다** — CLAUDE.md(격리 서술에 프록시 비움 반영 + 수동 청소), CHECKLIST.md(O-1 문단 차단 후 사실로 재작성·카드 후보 1번 처리됨 표기·안전장치 문단 좌표 갱신 — code-safety 결함 1건 수리·t10 기준선 행 신설), plan.md(t10 행).

## §2 증거 (Evidence) — 돌린 명령과 관측

| # | 명령 | 관측 |
|---|---|---|
| E1 | `git fetch origin` → `git rev-parse --short origin/master`; EnterWorktree(t10) → `git branch -m WT-driver-hygiene` → `git rev-parse --short HEAD` | `296b579` 양측 일치 · 브랜치명 확인 |
| E2 | swift-impl 편집(구현): Tools/GuardDriver.swift +38/−56(머리말 1-24줄 md5 대조로 무변경 확인 `9af5472a…` 양측 동일) | 컴파일 exit 0 · 경고 본 줄 12건 = t9 E2 기준선과 같은 분포(DirectionsService 8·LocationManager 3·PlaceSearch 1) |
| E3 | 레인 Q절 쌍 제거(등가 판정 뒤) 후 신선 컴파일(레시피 그대로, `/tmp/gd-t10-lane`) | exit 0 · 경고 12건(메시지별 4+4+2+1+1, 같은 분포) |
| E4 | code-safety 대항 리뷰(독립 에이전트, 읽기 전용) | **"재게이트 진행 허가"** — A(Q동치)·B(판정 중립성)·C(백업 제거 잔여 0)·D(불변식 병합 무손실)·E(해저드·간결성 신규 결함 0)·F(문서 정합) 전 항목 코드 수준 확인. 결함 1건: CHECKLIST 안전장치 문단 좌표 드리프트(t10 소행) → §1-6대로 그 자리 수리. 노트: 과거 프록시 노출은 "약 5회"보다 실제 많았음(O절 4회·V절 2회·P-6 포함) — CHECKLIST에 계상 관대였음을 명시 반영 |
| E5 | 게이트 ① 드라이버: `cat … > /tmp/gd-t10-gate.swift && swiftc … && /tmp/gd-t10-gate > log`(CLAUDE.md 레시피 그대로) | **gate-exit=0** · `212/212 통과` · `✓ 212 · ✗ 0` · `[실제 데이터] 대조 통과 — 시작 3개, 끝 3개의 이름·바이트가 같다` · 불변식 줄 9/9 ✓ — 첫 검사 라벨 "캘린더 푸시는 꺼져 있고 **프록시 설정은 비어 있다**" · P-4 라벨 〔MapKit 단독〕 |
| E6 | 실제 지원 디렉터리 해시(실행 전·후): `shasum -a 256` 3파일 + `ls` 스냅샷 | 전후 동일(diff 0) — events·activities `4f53cda18c2b…`·config `e2698db89…`(t9 E6 값과 같음) |
| E7 | 잔여 검사: `ls -d $TMPDIR/besir-gd-*`(전·후) | 전 0 · 후 0 — 이번 실행분 자가 삭제 확인(로그 `[샌드박스] 이번 실행의 홈: …BD483923…`) |
| E8 | 네트워크 표집: 실행 내내 `lsof -nP -i | grep gd-t10-gate` 초당 1회 | **0건** — 구조적 차단(E5의 코드 경로)과 관측이 함께 닫힘 |
| E9 | 게이트 ② iOS: `xcodebuild -scheme besir-iOS -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -derivedDataPath build build` | ios-exit=0 · BUILD SUCCEEDED · swift 경고 **0**(appintentsmetadataprocessor 제외 필터) |
| E10 | 게이트 ③ macOS: 같은 형식 `-scheme besir-macOS` | mac-exit=0 · BUILD SUCCEEDED · swift 경고 **0** |
| E11 | 게이트 ④ proxy: `npm --prefix proxy test` | **7/7 통과** |

## §3 귀속 (Baseline-attribution)

- 게이트 4종(E5·E9·E10·E11)은 **이 레인이 2026-09-24에 워크트리 t10(296b579 + t10 diff)에서 직접 실행**한 값이다 — t8/t9 측정의 인용이 아니다. 드라이버 컴파일 집합 12파일 중 t10이 바꾼 것은 Tools/GuardDriver.swift뿐(Shared/·proxy/ 무변경 — `git status`로 확인)이므로 E9-E11은 t9 값의 재발견이 아니라 같은 입력에 대한 이 트리의 재측정이다.
- 212 기준선은 t8이 세우고(205+7) t9이 재확인한 값 — t10의 "기준선 변동 검증" 결과는 **변동 없음**(설계 의도대로 drvCheck 병합으로 수를 보존, E5로 관측).
- Q절 쌍 제거의 근거(등가 판정)는 이 레인이 AIAssistant.swift 소스로 직접 유도하고 code-safety가 독립 재유도한 이중 확인이다(§1-3).

## §4 갭 (Gaps) — 검증하지 않은 것 (증거 없음 ≠ 통과)

- **exit 2(재지정 거부)·exit 3(실데이터 변화)·exit 124(시한) 가지는 만들 방법이 없어 관측하지 않았다**(t8·t9와 같은 한계).
- P-4 질의의 **온라인 MapKit 실동작**(어지러운 질의가 온라인에서 정말 0건인지)은 네트워크 실험 없이 코드 경로+사례로 판정했다(오프라인 .empty는 결정적).
- 드라이버 실행은 **1회**(t9는 2회) — code-safety 전수 리뷰가 선행됐고 E6-E8의 외부 관측이 1회 실행 전후를 폐쇄하므로 1회로 충분하다고 판단했다. 2회째 재현은 리드가 요구하면 즉시 돌릴 수 있다.
- 시뮬레이터·실기기 운영자 확인은 이 카드 범위 밖(드라이버·문서만 바꿨고 앱 동작 변화가 없다 — Shared/ 무변경).

## §5 잔여 위험 (Residual-risk)

- **ipwho.is 직접 폴백**(`fresh()` → `useCurrentLocation` → 3초 무측위 시 `LocationManager.swift:82-108`)은 프록시를 안 타는 직접 HTTP라 **이 차단의 밖**이다. 이번 실행 표집 0건(E8)이나 이론상 가능 — 무키·무과금·1회성 조회라 위험은 낮고, 막으려면 LocationManager 변경(별도 카드)이 필요하다.
- **인사말 리터럴 이중화 결합**: Q절 무백업의 근거가 AIAssistant :119/:223 인사말이 바이트 동일하다는 사실 위에 있다. 한쪽만 고치면 동치가 조용히 깨지는데 어떤 단언도 버블 텍스트를 안 잰다 — Q절 주석(:803-805)이 결합을 문서화했다. 리터럴을 건드리는 카드가 이 결합을 함께 봐야 한다.
- **동치의 전제**: 드라이버가 `submit`(:302)/`confirmAsk`(:881) 경로에 닿지 않는 현 설계. 추후 절이 이 경로를 직접 태우면 ai_history.json이 풍부해지고 유도를 다시 해야 한다.
- **Z절 선재 낡은 주석**(GuardDriver :1499 — "N절이 AppConfig.load()로 되돌리는데"는 옛 모양 서술, t10 이전부터 부정확): 카드 밖이라 그대로 두고 여기에 기록한다. 문구 카드(C6 부류)에서 정리 권고.
- CLAUDE.md:58 문구는 "API 할당량 안 씀"이며 ipwho.is는 할당량 개념이 아니라 문구와 충돌하지 않는다(운영자 결정 "현행 유지"는 이 해석 위에서 성립).

## §9 리드에게 넘기는 것

1. **병합·done**: 브랜치 `WT-driver-hygiene`(미푸시 — 기존 레인 패턴). 커밋 2개: `fix(guard)`(Tools/GuardDriver.swift) + `docs`(CLAUDE.md·CHECKLIST.md·plan.md·본 progress.md) — SHA는 커밋 후 보고.
2. **CHECKLIST 전방 참조 해소 확인**: :494 "t10 행 참조"가 가리키던 기준선 행이 착지했다(§2 E5-E11).
3. **노트 7 이행**: plan.md t10 행 추가 완료(t5·t6이 빠뜨렸던 루트 plan 후속 목록 누락과 같은 실수 없음).
4. 잔여 위험 §5 중 ipwho.is·인사말 결합은 후속 카드 후보로 남긴다 — 등록은 리드 소관.
