        // [SYNC-REPRO2] 독립 리뷰어(code-safety)의 읽기 가설을 실행으로 판정하는 사례들. 카드 파일 무변경.
        func syncMin(_ a: Date, _ b: Date) -> Int { Int(a.timeIntervalSince(b) / 60) }
        // F — 명시 연결(linkedActivityId) + 출발 nil 복귀 구간 + 끝 +30분. (옛 코드는 departureDate nil이면 건너뜀)
        do {
            let base = af18d0.addingTimeInterval(8 * 3600)
            let act = af18Act("SYNC F", base, base.addingTimeInterval(3600))
            let leg = afInjectedLeg(title: "SYNC F 오는편", anchor: .departure, arrival: act.endDate,
                                    departure: nil, origin: afOffice, destination: afHome,
                                    linked: act.id, recurrence: nil)
            store.activities.append(act); store.events.append(leg)
            _ = store.modifyActivity(id: act.id, newEnd: act.endDate.addingTimeInterval(1800))
            let l = store.events.first { $0.id == leg.id }!
            print("[SYNC-REPRO2] F 명시+출발nil, 끝+30: 구간 arrival 변위=\(syncMin(l.arrivalDate, leg.arrivalDate))분, departure=\(String(describing: l.departureDate))")
        }
        // G — clearPlace + newEnd, 추정 복귀 구간(반복 회차).
        do {
            let rid = UUID()
            let base = af18d0.addingTimeInterval(10 * 3600)
            let act = af18Act("SYNC G", base, base.addingTimeInterval(3600), rid)
            let leg = af18LegRet(nil, act.endDate, act.endDate.addingTimeInterval(1200), rid)
            store.activities.append(act); store.events.append(leg)
            _ = store.modifyActivity(id: act.id, newEnd: act.endDate.addingTimeInterval(1800), clearPlace: true)
            let l = store.events.first { $0.id == leg.id }
            let a = store.activities.first { $0.id == act.id }!
            print("[SYNC-REPRO2] G clearPlace+끝+30(추정 구간): 구간 존재=\(l != nil), 구간 변위=\(l.map { syncMin($0.arrivalDate, leg.arrivalDate) } ?? -999)분, 활동 장소=\(String(describing: a.location?.name)), 활동 끝 변위=\(syncMin(a.endDate, act.endDate))분")
        }
        // G2 — clearPlace + newEnd, 명시 연결 복귀 구간(REQ-004: 구간이 지워져야 한다).
        do {
            let base = af18d0.addingTimeInterval(12 * 3600)
            let act = af18Act("SYNC G2", base, base.addingTimeInterval(3600))
            let leg = af18LegRet(act.id, act.endDate, act.endDate.addingTimeInterval(1200))
            store.activities.append(act); store.events.append(leg)
            _ = store.modifyActivity(id: act.id, newEnd: act.endDate.addingTimeInterval(1800), clearPlace: true)
            print("[SYNC-REPRO2] G2 clearPlace+끝+30(명시 구간): 구간 남아있음=\(store.events.contains { $0.id == leg.id })")
        }
        // H — newPlace(다른 이름) + newEnd, 추정 복귀 구간.
        do {
            let rid = UUID()
            let base = af18d0.addingTimeInterval(14 * 3600)
            let act = af18Act("SYNC H", base, base.addingTimeInterval(3600), rid)
            let leg = af18LegRet(nil, act.endDate, act.endDate.addingTimeInterval(1200), rid)
            store.activities.append(act); store.events.append(leg)
            let cafe = Place(name: "카페", address: "서울 C", latitude: 37.52, longitude: 127.05)
            _ = store.modifyActivity(id: act.id, newEnd: act.endDate.addingTimeInterval(1800), newPlace: cafe)
            let l = store.events.first { $0.id == leg.id }!
            print("[SYNC-REPRO2] H newPlace+끝+30(추정 구간): 구간 변위=\(syncMin(l.arrivalDate, leg.arrivalDate))분, 소유 활동 있음=\(store.owningActivity(of: l) != nil)")
        }
        // I — 같은 회차·같은 장소·같은 시각 활동 2개가 구간 1개를 공유(중복 데이터), 둘째를 편집.
        do {
            let rid = UUID()
            let base = af18d0.addingTimeInterval(16 * 3600)
            let a0 = af18Act("SYNC I0", base, base.addingTimeInterval(3600), rid)
            let a1 = af18Act("SYNC I1", base, base.addingTimeInterval(3600), rid)
            let leg = af18LegRet(nil, a0.endDate, a0.endDate.addingTimeInterval(1200), rid)
            store.activities.append(contentsOf: [a0, a1]); store.events.append(leg)
            let ownerBefore = store.owningActivity(of: leg)
            _ = store.modifyActivity(id: a1.id, newEnd: a1.endDate.addingTimeInterval(1800))
            let l = store.events.first { $0.id == leg.id }!
            print("[SYNC-REPRO2] I 중복 활동 2개+구간 1개, 둘째 편집: 편집 전 소유=\(ownerBefore == nil ? "없음(동률 거절)" : "있음"), 구간 변위=\(syncMin(l.arrivalDate, leg.arrivalDate))분")
        }
