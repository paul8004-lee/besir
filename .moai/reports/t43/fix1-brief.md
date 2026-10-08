# 카드 t43 — sync 지적 수리 지시서 (run 레인, fix1)

작성: 칸반 리드, 2026-10-08. 근거: sync 증거 `.moai/reports/t43/sync-verdict.md`(커밋 183e07f)를 리드가 직접 읽고 코드를 대조한 뒤의 결정이다. 이 파일은 주 체크아웃 `.moai/reports/t43/`(미추적) — 절대 경로로 읽는다.
워크트리 `/Users/iseongmin/Projects/besir/.claude/worktrees/t43`, 브랜치 `WT-leg-drag-resize`, 시작 커밋 `183e07f`(c50754a + sync의 문서·주석 수리). 새 카드가 아니라 **같은 카드 t43의 수리 라운드**다.

## 1. 리드의 결정 (운영자에게는 결과로 알린다)

| sync 결정 요청 | 리드 결정 | 근거 |
|---|---|---|
| ① §3.1 차단 | **이 카드에서 수리**(별도 카드 아님) | 리드가 코드 확인: `ContentView.swift:1218`의 `gr.location(in: scroll).y`는 스크롤 뷰 bounds 좌표계(원점 = contentOffset)라 콘텐츠 좌표이고, 속도 식(`:1222-1225`)에 상한이 없다. S-16 첫 관측에서 터진다 |
| ② §3.2 | **수리** — 출발 기준 구간의 대조 시각을 `departureDate ?? arrivalDate`로(앱의 `failedBlockAnchor` 규칙과 같은 앵커 규칙) | 기준 트리 `b59fcaa`에서는 짝지어지던 것이 회귀다. 운영자의 "연결 유지" 의도와 무회귀 원칙. plan 레인이 N4~N5에서 정한 "출발 없는 구간은 동률 불성립"(REQ-004·AF-018-21b)이 이 경우를 놓쳤다 |
| ③ K13 | **⚠️**로 둔다 | 화면 미관측·차단 수리 전 — 이 파일 관례(Q7·Q9)와 맞춤. ✅는 운영자 S-16 통과 뒤 |

## 2. 할 일 (이 순서, 이 범위만)

1. **[차단] 자동 스크롤 좌표·상한** (`Shared/ContentView.swift` `autoScrollTick`, 지금 `:1216-1225`):
   - 띠 판정 좌표를 **보이는 창 기준**으로: `gr.location(in: scroll).y - scroll.contentOffset.y`. 그 위 주석(`location(in: scroll)이 곧 보이는 창 안 위치다`)은 틀렸으니 이유와 함께 고친다(한국어, "왜").
   - 속도에 상한: 손가락이 스크롤 영역 밖이어도 `autoScrollMaxSpeed`를 넘지 않게(`min`/`clamp`, 위쪽 띠도 대칭). SPEC plan D-11의 "깊이 ≥ 띠 높이면 최대 속도"와 일치시킨다.
   - 권장(한 줄): `AutoScrollProxy.tick`에서 target이 nil이면 `link.invalidate()`(sync [정보]).
   - 증거: sync가 만든 UIKit 좌표 변환 하네스(`scrollcoord.swift`, 위치는 `sync-verdict.md` §3.1·`.moai/state/verify/t43/sync/`)에 **고친 식**을 넣어 offset 0·448 두 조건 × 위/가운데/아래 손가락 위치를 다시 돌린 원문 출력(가운데 손가락 속도 0, 아래 가장자리 ≤ 600, 위쪽 띠 작동). 옛 식 출력과 나란히 둔다(양성 대조).
2. **[회귀] 출발 없는 복귀 구간의 짝** (`Shared/Store.swift` `estimatedLegs`):
   - 출발 기준 구간의 활동 끝 대조를 `(leg.departureDate ?? leg.arrivalDate) == activity.endDate` 꼴(새 계산식을 흩뿌리지 말고 한 곳 — 이미 있는 앵커 규칙을 재사용할 수 있으면 재사용)로. 도착 기준 갈래는 그대로.
   - SPEC: REQ-004의 "출발이 없는 오는 편은 동률이 성립하지 않는다"와 AF-018-21b, plan D-10 표, research §10 표의 해당 행을 고치고 이유("첫 회차 이동시간 추정이 실패하면 2회차부터 `departureDate`가 nil로 남는 모양 — `addRecurringEvents` `.departure` 갈래")를 적는다. 버전 0.7.3, HISTORY 행("미감사").
   - 드라이버: AF-018-21b를 새 의미로 고쳐 쓰고, **이 모양의 양성 대조**(출발 nil 복귀 구간이 소유·묶음에 들고 활동 +30 이동에서 함께 +30 — sync의 `F3` 기대와 같은 값)를 단언으로 넣는다. 단언 수가 변하면 T를 SPEC 전체(spec §0·REQ-013·plan §5·AC-011·progress)에서 같은 값으로 맞추고 이유를 적는다(번호 하나 = 단언 하나 규칙 유지).
   - 이동 계산(`shiftEvent`)이 `departureDate`가 nil인 구간에서도 도착 시각을 같은 양 옮기는지 코드로 확인해 적는다.
3. **[주의] 초가 0이 아닌 활동의 반폭 분할** (`ContentView.swift` 활동 `span`, 지금 `:651-652`): 기준 `b59fcaa`는 `minutesSinceMidnight`(초 버림)였고 구간 `span`은 지금도 그렇다. 활동 `span`만 초를 쓰면서 10:00:30 활동 + 11:00:30 출발 구간이 새로 반폭으로 갈린다(sync §4.1). **초가 0인 데이터의 배치·미리보기 값이 바뀌지 않음을 증명할 수 있는 최소 수정**으로 분 단위 기준과 맞춘다. 미리보기 정밀도 때문에 초가 꼭 필요하다는 근거가 나오면 고치지 말고 근거와 함께 "수용 위험 + S-6 확인"으로 보고한다.
4. **[문서]** `CHECKLIST.md` K13을 ✅ → **⚠️**로, 근거 문구에 "화면 미관측 + sync 차단 수리 뒤 S-16 확인 필요"를 적고 `:313` 요약의 K13 줄도 맞춘다. 줄 번호 인용이 또 밀렸으면 sync가 쓴 인용 대조 도구(`.moai/state/verify/t43/sync/check.py` — `sync-verdict.md` §5.1)로 다시 대조한다.

## 3. 하지 않는 것

- sync가 [정보]·〔가설〕로 둔 항목(`다음 날 00` 눈금 폭 §4.2, VoiceOver·큰 글자 §4.3, 초 0쪽 절단 30초 초과 §3.3, 두 `span` 갈래의 16분 규칙)은 **고치지 않는다** — 운영자 S-6·S-18 관측 몫이거나 설계 결정이다.
- `moveActivity`·`realignReturnLeg`는 무변경 유지(해시 `ab65d72c…`·`a6ca6f17…`). 소스는 `Shared/Store.swift`·`Shared/ContentView.swift`·`Tools/GuardDriver.swift` 세 파일만. 새 `Shared/` 파일·`xcodegen` 금지. 병합·push·PR 금지. `AskUserQuestion` 금지.
- 독립 감사는 하지 않는다(소진). sync의 좁은 재검증은 리드가 따로 요청한다.

## 4. 실행 규칙·증거

run-brief(`.moai/reports/t43/run-brief.md`) §5 그대로(에이전트 동시 수 2 이하, 쓰기 에이전트 한 번에 하나, `git -C`, 커밋 메시지에 `(card t43)`, 경로 지정 `git add`). 워크트리는 **sync 레인이 나온 뒤**에 들어간다(리드가 확인하고 디스패치한다).
수리 결과를 `.moai/reports/t43/run-progress.md`에 "§5 수리 라운드(fix1)" 절로 덧붙이고 다음을 **명령과 원문 출력**으로: 드라이버(최종 T와 종료 코드·`✗` 0·샌드박스 잔재 0 — 네트워크 의존 `S 전제` 실패가 나오면 즉시 재실행하고 두 결과 모두 기록), iOS 무경고 빌드, `moveActivity`·`realignReturnLeg` 해시, `git diff --name-only 183e07f` 가 소스 3파일 + 문서뿐임, 위 1의 좌표 하네스 출력, 위 2의 단언 양성 대조, 못 한 것. code-safety 판정은 이 수리 diff에 한정해 다시 받는다(자기 출력을 자기가 판정하지 않는다).
