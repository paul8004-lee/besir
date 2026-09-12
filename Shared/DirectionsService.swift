import Foundation
import MapKit

/// 출발지→목적지 이동시간을 수단별로 계산한다.
/// - 자동차: 카카오모빌리티(키 있을 때) → MapKit 폴백
/// - 대중교통: ODsay(키 있을 때) → MapKit 폴백
/// - 도보: MapKit (키 불필요)
struct DirectionsService {
    let config: AppConfig

    func estimateAll(from origin: CLLocationCoordinate2D,
                     to dest: CLLocationCoordinate2D) async -> [TransportMode: TravelEstimate] {
        async let car = estimate(.car, from: origin, to: dest)
        async let transit = estimate(.transit, from: origin, to: dest)
        async let walk = estimate(.walk, from: origin, to: dest)
        let results = await [car, transit, walk]
        var map: [TransportMode: TravelEstimate] = [:]
        for r in results { map[r.mode] = r }
        return map
    }

    func estimate(_ mode: TransportMode,
                  from origin: CLLocationCoordinate2D,
                  to dest: CLLocationCoordinate2D) async -> TravelEstimate {
        switch mode {
        case .car:
            if config.hasProxy, let e = try? await kakaoCar(origin, dest) { return e }
            return await mapKitETA(.automobile, mode: .car, origin, dest)
        case .transit:
            if config.hasProxy, let e = try? await odsayTransit(origin, dest) { return e }
            return await mapKitETA(.transit, mode: .transit, origin, dest)
        case .walk:
            return await mapKitETA(.walking, mode: .walk, origin, dest)
        }
    }

    // MARK: - 카카오모빌리티 자동차 길찾기(프록시 경유)

    private func kakaoCar(_ origin: CLLocationCoordinate2D,
                          _ dest: CLLocationCoordinate2D) async throws -> TravelEstimate {
        guard let req = config.proxyRequest("/kakao/directions", query: [
            URLQueryItem(name: "origin", value: "\(origin.longitude),\(origin.latitude)"),
            URLQueryItem(name: "destination", value: "\(dest.longitude),\(dest.latitude)"),
            URLQueryItem(name: "priority", value: "RECOMMEND")
        ]) else { throw URLError(.badURL) }

        let (data, _) = try await URLSession.shared.data(for: req)
        struct Resp: Decodable {
            struct Route: Decodable {
                struct Summary: Decodable { let duration: Int; let distance: Int }
                let result_code: Int?
                let summary: Summary?
            }
            let routes: [Route]
        }
        let resp = try JSONDecoder().decode(Resp.self, from: data)
        guard let summary = resp.routes.first?.summary else {
            throw URLError(.cannotParseResponse)
        }
        return TravelEstimate(mode: .car,
                              duration: TimeInterval(summary.duration),
                              distance: Double(summary.distance),
                              source: "카카오")
    }

    // MARK: - ODsay 대중교통

    private func odsayTransit(_ origin: CLLocationCoordinate2D,
                              _ dest: CLLocationCoordinate2D) async throws -> TravelEstimate {
        guard let req = config.proxyRequest("/odsay/searchPubTransPathT", query: [
            URLQueryItem(name: "SX", value: "\(origin.longitude)"),
            URLQueryItem(name: "SY", value: "\(origin.latitude)"),
            URLQueryItem(name: "EX", value: "\(dest.longitude)"),
            URLQueryItem(name: "EY", value: "\(dest.latitude)")
        ]) else { throw URLError(.badURL) }
        let (data, _) = try await URLSession.shared.data(for: req)
        struct Resp: Decodable {
            struct Result: Decodable {
                struct Path: Decodable {
                    struct Info: Decodable { let totalTime: Int; let totalDistance: Int? }
                    let info: Info
                }
                let path: [Path]?
            }
            let result: Result?
        }
        let resp = try JSONDecoder().decode(Resp.self, from: data)
        guard let info = resp.result?.path?.first?.info else {
            throw URLError(.cannotParseResponse)
        }
        return TravelEstimate(mode: .transit,
                              duration: TimeInterval(info.totalTime * 60),
                              distance: info.totalDistance.map(Double.init),
                              source: "ODsay")
    }

    /// 대중교통 경로 결과: 지도에 그릴 좌표 구간 + 사람이 읽는 환승 안내 단계.
    struct TransitPlan {
        var segments: [RouteSegment] = []
        var steps: [TransitStep] = []
    }

    /// ODsay 대중교통 경로를 지도용 구간과 환승 안내 단계로 함께 반환한다.
    /// 경로 검색은 한 번만 호출하고 그 응답을 양쪽에 재사용한다.
    /// 키가 없거나 실패하면 빈 결과(호출 측에서 마커만 표시).
    func transitPlan(from origin: CLLocationCoordinate2D,
                     to dest: CLLocationCoordinate2D) async -> TransitPlan {
        guard config.hasProxy else { return TransitPlan() }

        // 1) 경로 검색 → subPath(구간 목록) + mapObj(좌표 조회용 키)
        guard let req = config.proxyRequest("/odsay/searchPubTransPathT", query: [
            URLQueryItem(name: "SX", value: "\(origin.longitude)"),
            URLQueryItem(name: "SY", value: "\(origin.latitude)"),
            URLQueryItem(name: "EX", value: "\(dest.longitude)"),
            URLQueryItem(name: "EY", value: "\(dest.latitude)")
        ]) else { return TransitPlan() }
        guard let (data, _) = try? await URLSession.shared.data(for: req),
              let path = (try? JSONDecoder().decode(PathResp.self, from: data))?.result?.path?.first
        else { return TransitPlan() }

        // 2) 안내 단계는 좌표 없이도 만들 수 있으므로 먼저 채운다.
        var plan = TransitPlan()
        plan.steps = Self.steps(from: path.subPath)

        // 3) loadLane → 대중교통 구간별 실제 좌표열(순서대로)
        guard let mapObj = path.info.mapObj else { return plan }
        let laneCoords = await loadLane(mapObj: mapObj)
        guard !laneCoords.isEmpty else { return plan }   // 좌표 없으면 직선만 남으니 생략
        plan.segments = Self.segments(subPath: path.subPath,
                                      laneCoords: laneCoords,
                                      origin: origin,
                                      dest: dest)
        return plan
    }

    /// subPath 순서대로 도보 연결선 + 대중교통 실제 경로를 구성한다.
    private static func segments(subPath: [PathResp.Result.Path.SubPath],
                                 laneCoords: [[CLLocationCoordinate2D]],
                                 origin: CLLocationCoordinate2D,
                                 dest: CLLocationCoordinate2D) -> [RouteSegment] {
        var segments: [RouteSegment] = []
        var laneIdx = 0
        var cursor = origin
        for sp in subPath {
            if sp.trafficType == 3 { continue }   // 도보는 좌표가 없어 연결선으로 처리
            guard laneIdx < laneCoords.count else { continue }
            let coords = laneCoords[laneIdx]
            laneIdx += 1
            guard let first = coords.first, let last = coords.last else { continue }
            // 직전 위치 → 이 대중교통 시작점: 도보 연결선
            segments.append(RouteSegment(mode: .walk, color: walkColor, coords: [cursor, first]))
            if sp.trafficType == 1 {
                segments.append(RouteSegment(mode: .subway,
                                             color: subwayColor(sp.lane?.first?.subwayCode),
                                             coords: coords))
            } else {
                segments.append(RouteSegment(mode: .bus,
                                             color: busColor(sp.lane?.first?.type),
                                             coords: coords))
            }
            cursor = last
        }
        // 마지막 대중교통 → 목적지: 도보 연결선
        segments.append(RouteSegment(mode: .walk, color: walkColor, coords: [cursor, dest]))
        return segments
    }

    /// subPath를 "도보로 ㅁㅁ역까지 → 1호선 탑승 → …" 형태의 안내 단계로 변환한다.
    private static func steps(from subPaths: [PathResp.Result.Path.SubPath]) -> [TransitStep] {
        var steps: [TransitStep] = []
        var lastEnd = "출발지"
        for (i, sp) in subPaths.enumerated() {
            let minutes = sp.sectionTime ?? 0
            switch sp.trafficType {
            case 3:
                // 도보 구간엔 이름이 없으므로, 다음 대중교통 구간의 승차지를 목적지로 쓴다.
                if minutes <= 0 { continue }   // 0분짜리 연결 도보는 안내에서 생략
                let next = subPaths[(i + 1)...].first { $0.trafficType != 3 }
                var to = "목적지"
                if let next, let name = next.startName {
                    to = stopName(trafficType: next.trafficType, name)
                }
                steps.append(TransitStep(kind: .walk, line: "", from: lastEnd, to: to,
                                         minutes: minutes, stationCount: nil, color: walkColor))
            case 1, 2:
                let isSubway = sp.trafficType == 1
                let lane = sp.lane?.first
                let from = sp.startName.map { stopName(trafficType: sp.trafficType, $0) } ?? lastEnd
                let to = sp.endName.map { stopName(trafficType: sp.trafficType, $0) } ?? "하차"
                let line = isSubway
                    ? (lane?.name.map(shortLineName) ?? "지하철")
                    : (lane?.busNo.map { "\($0)번" } ?? "버스")
                steps.append(TransitStep(kind: isSubway ? .subway : .bus,
                                         line: line, from: from, to: to,
                                         minutes: minutes, stationCount: sp.stationCount,
                                         color: isSubway ? subwayColor(lane?.subwayCode)
                                                         : busColor(lane?.type)))
                lastEnd = to
            default:
                continue
            }
        }
        return steps
    }

    /// 지하철 역 이름엔 "역"을 붙인다(ODsay는 "시청"처럼 내려줌). 버스 정류장은 그대로.
    private static func stopName(trafficType: Int, _ raw: String) -> String {
        guard trafficType == 1 else { return raw }
        return raw.hasSuffix("역") ? raw : raw + "역"
    }

    /// "수도권 1호선" → "1호선" 처럼 지역 접두어를 뗀다.
    private static func shortLineName(_ raw: String) -> String {
        for prefix in ["수도권 ", "부산 ", "대구 ", "광주 ", "대전 "] where raw.hasPrefix(prefix) {
            return String(raw.dropFirst(prefix.count))
        }
        return raw
    }

    // MARK: - 도보 경로선 (MapKit)

    static let walkLineColor = "#9aa0a6"

    /// 도보 경로를 MapKit 보행 경로 좌표로 반환. 실패하면 빈 배열(마커만 표시).
    /// (카카오 공개 API에는 도보 길찾기가 없어 MapKit을 사용)
    func walkRouteSegments(from origin: CLLocationCoordinate2D,
                           to dest: CLLocationCoordinate2D) async -> [RouteSegment] {
        if let coords = await mapKitRoute(.walking, origin, dest), !coords.isEmpty {
            return [RouteSegment(mode: .walk, color: Self.walkLineColor, coords: coords)]
        }
        return []
    }

    // MARK: - 자동차 경로선

    static let carColor = "#2b7fff"

    /// 자동차 경로를 도로 좌표열로 반환. 카카오모빌리티(키 있을 때) → MapKit 폴백.
    /// 실패하면 빈 배열(호출 측에서 직선 폴백).
    func carRouteSegments(from origin: CLLocationCoordinate2D,
                          to dest: CLLocationCoordinate2D) async -> [RouteSegment] {
        if config.hasProxy, let coords = try? await kakaoCarRoute(origin, dest), !coords.isEmpty {
            return [RouteSegment(mode: .car, color: Self.carColor, coords: coords)]
        }
        if let coords = await mapKitRoute(.automobile, origin, dest), !coords.isEmpty {
            return [RouteSegment(mode: .car, color: Self.carColor, coords: coords)]
        }
        return []
    }

    /// 카카오모빌리티 길찾기 응답의 도로 좌표(vertexes: [x,y,x,y...] = [lng,lat...]) 파싱.
    private func kakaoCarRoute(_ origin: CLLocationCoordinate2D,
                               _ dest: CLLocationCoordinate2D) async throws -> [CLLocationCoordinate2D] {
        guard let req = config.proxyRequest("/kakao/directions", query: [
            URLQueryItem(name: "origin", value: "\(origin.longitude),\(origin.latitude)"),
            URLQueryItem(name: "destination", value: "\(dest.longitude),\(dest.latitude)"),
            URLQueryItem(name: "priority", value: "RECOMMEND")
        ]) else { throw URLError(.badURL) }

        let (data, _) = try await URLSession.shared.data(for: req)
        struct Resp: Decodable {
            struct Route: Decodable {
                struct Section: Decodable {
                    struct Road: Decodable { let vertexes: [Double] }
                    let roads: [Road]?
                }
                let sections: [Section]?
            }
            let routes: [Route]
        }
        let resp = try JSONDecoder().decode(Resp.self, from: data)
        guard let sections = resp.routes.first?.sections else { return [] }
        var coords: [CLLocationCoordinate2D] = []
        for section in sections {
            for road in section.roads ?? [] {
                let v = road.vertexes
                var i = 0
                while i + 1 < v.count {
                    coords.append(CLLocationCoordinate2D(latitude: v[i + 1], longitude: v[i]))
                    i += 2
                }
            }
        }
        return coords
    }

    /// MapKit 경로 폴리라인 좌표(자동차/도보 폴백용).
    private func mapKitRoute(_ transport: MKDirectionsTransportType,
                             _ origin: CLLocationCoordinate2D,
                             _ dest: CLLocationCoordinate2D) async -> [CLLocationCoordinate2D]? {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: dest))
        request.transportType = transport
        guard let route = try? await MKDirections(request: request).calculate().routes.first else {
            return nil
        }
        let poly = route.polyline
        var coords = [CLLocationCoordinate2D](repeating: .init(), count: poly.pointCount)
        poly.getCoordinates(&coords, range: NSRange(location: 0, length: poly.pointCount))
        return coords
    }

    private func loadLane(mapObj: String) async -> [[CLLocationCoordinate2D]] {
        guard let req = config.proxyRequest("/odsay/loadLane", query: [
            URLQueryItem(name: "mapObject", value: "0:0@\(mapObj)")
        ]),
              let (data, _) = try? await URLSession.shared.data(for: req),
              let lanes = (try? JSONDecoder().decode(LaneResp.self, from: data))?.result?.lane else {
            return []
        }
        return lanes.map { lane in
            (lane.section ?? []).flatMap { $0.graphPos }.map {
                CLLocationCoordinate2D(latitude: $0.y, longitude: $0.x)
            }
        }
    }

    // MARK: - ODsay 디코딩 모델

    private struct PathResp: Decodable {
        struct Result: Decodable {
            struct Path: Decodable {
                struct Info: Decodable { let mapObj: String? }
                struct SubPath: Decodable {
                    struct Lane: Decodable {
                        let name: String?       // 지하철 노선명 "수도권 1호선"
                        let busNo: String?      // 버스 번호 "101"
                        let subwayCode: Int?
                        let type: Int?          // 버스 종류(간선/광역 등)
                    }
                    let trafficType: Int        // 1=지하철, 2=버스, 3=도보
                    let sectionTime: Int?       // 이 구간 소요시간(분)
                    let stationCount: Int?      // 지나는 역·정류장 수
                    let startName: String?      // 승차 역·정류장
                    let endName: String?        // 하차 역·정류장
                    let lane: [Lane]?
                }
                let info: Info
                let subPath: [SubPath]
            }
            let path: [Path]?
        }
        let result: Result?
    }

    private struct LaneResp: Decodable {
        struct Result: Decodable {
            struct Lane: Decodable {
                struct Section: Decodable {
                    struct Pos: Decodable { let x: Double; let y: Double }
                    let graphPos: [Pos]
                }
                let section: [Section]?
            }
            let lane: [Lane]?
        }
        let result: Result?
    }

    // MARK: - 색상

    static let walkColor = "#9aa0a6"

    static func subwayColor(_ code: Int?) -> String {
        switch code {
        case 1: return "#0052A4"; case 2: return "#00A84D"; case 3: return "#EF7C1C"
        case 4: return "#00A5DE"; case 5: return "#996CAC"; case 6: return "#CD7C2F"
        case 7: return "#747F00"; case 8: return "#E6186C"; case 9: return "#BDB092"
        default: return "#3d5bf0"
        }
    }

    static func busColor(_ type: Int?) -> String {
        switch type {
        case 1, 11: return "#3D5BAB"        // 간선(파랑)
        case 14, 15, 16: return "#E60012"   // 광역·급행(빨강)
        default: return "#33A23D"           // 지선·마을 등(초록)
        }
    }

    // MARK: - MapKit ETA 폴백

    private func mapKitETA(_ transport: MKDirectionsTransportType,
                           mode: TransportMode,
                           _ origin: CLLocationCoordinate2D,
                           _ dest: CLLocationCoordinate2D) async -> TravelEstimate {
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: MKPlacemark(coordinate: origin))
        request.destination = MKMapItem(placemark: MKPlacemark(coordinate: dest))
        request.transportType = transport
        let directions = MKDirections(request: request)
        do {
            let eta = try await directions.calculateETA()
            return TravelEstimate(mode: mode,
                                  duration: eta.expectedTravelTime,
                                  distance: eta.distance,
                                  source: "Apple 지도")
        } catch {
            // 대중교통은 지역에 따라 MapKit이 지원하지 않을 수 있다.
            return TravelEstimate(mode: mode, duration: nil, distance: nil, source: "Apple 지도")
        }
    }
}
