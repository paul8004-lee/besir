import sys

# gd-repro2: 1차 재현 조각 + 2차 조각을 드라이버 사본에 끼운다 — 카드 파일은 읽기만 한다.
d = ".moai/state/verify/t49-sync/"
src = open("Tools/GuardDriver.swift", encoding="utf-8").read()
s1 = open(d + "repro_snippet.swift", encoding="utf-8").read()
s2 = open(d + "repro_snippet2.swift", encoding="utf-8").read()
anchor = src.index("T49-6 시작+끝을 함께 고치면")
tail = src.index("        store.events = []\n        store.activities = []", anchor)
out = src[:tail] + s1 + "\n" + s2 + "\n" + src[tail:]
open(d + "GuardDriver-repro2.swift", "w", encoding="utf-8").write(out)
print("spliced at", tail)
sys.exit(0)
