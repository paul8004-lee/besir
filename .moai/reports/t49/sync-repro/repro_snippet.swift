        // [SYNC-REPRO] t49 sync 추가 질의 — moveActivity wholeSeries 교차 루프 이중 이동 가설.
        //        카드 파일이 아니라 드라이버 *복사본*에만 끼운 재현이다(수리 없음, 결과만 기록).
        //        매 케이스는 새 rid·새 활동 3개(하루 간격)와 구간 3개. 구간 변위를 분 단위로 찍는다.
        func syncRepro(_ label: String, linkedExplicit: Bool, shiftMinutes: Int, kind: String) {
            let rid = UUID()
            let base = af18d0.addingTimeInterval(8 * 3600)
            var acts: [ActivityBlock] = [], legs: [ScheduledEvent] = []
            for d in 0..<3 {
                let s = base.addingTimeInterval(Double(d) * 86400)
                let a = af18Act("SYNC \(label) \(d)", s, s.addingTimeInterval(3600), rid)
                acts.append(a)
                if kind == "return" {
                    legs.append(af18LegRet(linkedExplicit ? a.id : nil, a.endDate, a.endDate.addingTimeInterval(1200), rid))
                } else {
                    legs.append(af18LegOut(linkedExplicit ? a.id : nil, s.addingTimeInterval(-1200), s, rid))
                }
            }
            store.activities.append(contentsOf: acts); store.events.append(contentsOf: legs)
            store.moveActivity(acts[0], byMinutes: shiftMinutes, wholeSeries: true)
            var line = "[SYNC-REPRO] \(label) (\(kind), 명시연결=\(linkedExplicit), 이동 \(shiftMinutes)분):"
            var allOK = true
            for (i, l) in legs.enumerated() {
                let after = store.events.first { $0.id == l.id }!
                let d = after.arrivalDate.timeIntervalSince(l.arrivalDate) / 60
                if Int(d) != shiftMinutes { allOK = false }
                line += " leg\(i)=\(Int(d))"
            }
            let actD = acts.indices.map { i in
                Int(store.activities.first { $0.id == acts[i].id }!.startDate.timeIntervalSince(acts[i].startDate) / 60)
            }
            line += " | 활동 변위=\(actD) | 구간 전부 기대값=\(allOK ? "예" : "아니오 ← 이중 이동/누락")"
            print(line)
        }
        syncRepro("A 추정 +1440", linkedExplicit: false, shiftMinutes: 1440, kind: "return")
        syncRepro("B 추정 +1440", linkedExplicit: false, shiftMinutes: 1440, kind: "arrival")
        syncRepro("C 추정 +60(대조군)", linkedExplicit: false, shiftMinutes: 60, kind: "return")
        syncRepro("D 명시 +1440(대조군)", linkedExplicit: true, shiftMinutes: 1440, kind: "return")
        syncRepro("E 추정 -1440", linkedExplicit: false, shiftMinutes: -1440, kind: "return")
