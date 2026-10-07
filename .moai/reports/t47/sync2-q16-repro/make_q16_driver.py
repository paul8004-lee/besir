#!/usr/bin/env python3
# 저장소 드라이버 사본의 AI절 끝(전역 불변식 단언 바로 앞)에 Q16 재현 블록을 끼운다. 저장소 파일은 건드리지 않는다.
ROOT = "/Users/iseongmin/Projects/besir/.claude/worktrees/t47/"
src = open(ROOT + "Tools/GuardDriver.swift", encoding="utf-8").read().split("\n")
block = open(ROOT + ".moai/state/verify/t47-sync2/q16_block.swift", encoding="utf-8").read().split("\n")
marker = 'drvAssertGlobalInvariants(aiCard, "AI절")'
hits = [i for i, l in enumerate(src) if marker in l]
if len(hits) != 1:
    raise SystemExit(f"중단: 표지 일치 {len(hits)}건")
ext = '''

// 스크래치 전용 — 한 턴에 호출 여럿이 함께 오는 모양의 실행 전 카드(drvAskTwo와 같은 경로, 도구 이름만 다르다)
extension AIAssistant {
    func q16Mixed(_ names: [String]) -> PendingAsk? {
        let parts: [[String: Any]] = names.map { n in
            let args: [String: Any] = n == "create_schedule"
                ? ["title": "혼합", "destination_query": "회사", "origin_query": "집"]
                : ["destination_query": "강남역"]
            return ["functionCall": ["name": n, "args": args]]
        }
        return pendingAsk(for: fillStated(sanitizeModelArgs(parts)))
    }
}
'''.split("\\n")
out = src[:hits[0]] + block + src[hits[0]:] + ext
open(ROOT + ".moai/state/verify/t47-sync2/GuardDriverQ16.swift", "w", encoding="utf-8").write("\n".join(out))
print("OK 삽입 위치 줄", hits[0] + 1, "블록", len(block), "줄")
