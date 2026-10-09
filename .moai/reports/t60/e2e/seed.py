#!/usr/bin/env python3
"""t60 재현용 시드 — 앱 컨테이너의 activities.json 에 활동 블록 둘(오늘·내일 07:00–08:00)을 심는다.

드래그 재현에 네트워크·AI·즐겨찾기가 끼지 않게 활동만 심는다(소유 구간 없음 →
pan-lock fallback 경로가 아니라 scrollDisabled 경로만 탄다). 판정은 화면 스크린샷과
이 파일의 startDate/endDate 변화를 함께 본다 — 앱이 이동을 저장하면 이 파일이 바뀐다.

사용: python3 seed.py            # 오늘·내일 07:00–08:00 시드
      python3 seed.py --read     # 현재 파일 내용 출력(이동 여부 판정용)
"""
import json
import subprocess
import sys
from datetime import datetime, timedelta

# Apple Codable 기본 Date 인코딩 = 2001-01-01 기준 초
REFERENCE = 978307200.0
TITLE = "재현활동"


def container_support_dir() -> str:
    out = subprocess.check_output(
        ["xcrun", "simctl", "get_app_container", "booted", "com.iseongmin.besir", "data"],
        text=True,
    ).strip()
    return out + "/Library/Application Support/besir"


def main() -> None:
    path = container_support_dir() + "/activities.json"
    if "--read" in sys.argv:
        with open(path) as f:
            data = json.load(f)
        for a in data:
            start = datetime.fromtimestamp(a["startDate"] + REFERENCE)
            end = datetime.fromtimestamp(a["endDate"] + REFERENCE)
            print(f'{a["title"]}  {start:%m-%d %H:%M} ~ {end:%H:%M}')
        return

    base = datetime.now().replace(hour=7, minute=0, second=0, microsecond=0)
    activities = []
    for day in (0, 1):
        start = base + timedelta(days=day)
        end = start + timedelta(hours=1)
        activities.append(
            {
                "id": f"00000000-6000-4000-8000-{day:012d}",
                "title": TITLE,
                "startDate": start.timestamp() - REFERENCE,
                "endDate": end.timestamp() - REFERENCE,
            }
        )
    with open(path, "w") as f:
        json.dump(activities, f)
    for a in activities:
        start = datetime.fromtimestamp(a["startDate"] + REFERENCE)
        print(f'seeded {a["title"]} {start:%m-%d %H:%M}')
    print(path)


if __name__ == "__main__":
    main()
