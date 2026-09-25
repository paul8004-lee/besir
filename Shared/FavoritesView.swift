import SwiftUI

/// 즐겨찾기 장소(집·회사 등) 관리 화면. 추가/삭제만 지원하는 단순 목록.
struct FavoritesView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var location: LocationManager
    @Environment(\.dismiss) private var dismiss

    @State private var newLabel = ""
    @State private var query = ""
    @State private var results: [Place] = []
    @State private var searching = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("즐겨찾기 장소").font(.title2).bold()
                Spacer()
                Button("닫기") { dismiss() }
            }

            if store.favorites.isEmpty {
                Text("아직 즐겨찾기가 없습니다. 아래에서 집·회사 같은 장소를 추가해보세요.")
                    .font(.callout).foregroundStyle(Theme.muted)
            } else {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(store.favorites) { fav in
                        HStack {
                            // 시스템 노랑 대신 브라스 — 하우스 팔레트의 따뜻한 강조를 별도 가져간다.
                            Image(systemName: "star.fill").foregroundStyle(Theme.activity)
                            VStack(alignment: .leading) {
                                Text(fav.label).bold()
                                Text(fav.place.name).font(.caption).foregroundStyle(Theme.muted)
                            }
                            Spacer()
                            Button(role: .destructive) { store.deleteFavorite(fav.id) } label: {
                                Image(systemName: "trash")
                            }
                            .buttonStyle(.borderless)
                        }
                        .padding(.vertical, 6)
                        Divider()
                    }
                }
            }

            Divider()
            Text("추가하기").font(.headline)
            TextField("이름 (예: 집, 회사)", text: $newLabel)
                .textFieldStyle(.roundedBorder)
            HStack {
                TextField("장소 검색", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .onSubmit { runSearch() }
                Button { runSearch() } label: {
                    if searching { ProgressView().controlSize(.small) } else { Image(systemName: "magnifyingglass") }
                }
                // 아이콘만 있는 버튼은 VoiceOver가 읽을 문구가 없다 — 무엇을 여는지 직접 말해준다.
                .accessibilityLabel("장소 검색")
            }
            ForEach(results, id: \.name) { place in
                Button {
                    addFavorite(place)
                } label: {
                    HStack {
                        Image(systemName: "mappin.circle")
                        VStack(alignment: .leading) {
                            Text(place.name)
                            Text(place.address).font(.caption).foregroundStyle(Theme.muted)
                        }
                        Spacer()
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .disabled(newLabel.trimmingCharacters(in: .whitespaces).isEmpty)
                Divider()
            }
            Spacer()
        }
        .padding(24)
        #if os(macOS)
        .frame(width: 480, height: 560)
        #endif
    }

    private func addFavorite(_ place: Place) {
        let label = newLabel.trimmingCharacters(in: .whitespaces)
        guard !label.isEmpty else { return }
        store.addFavorite(label: label, place: place)
        newLabel = ""; query = ""; results = []
    }

    private func runSearch() {
        guard query.count >= 2 else { return }
        searching = true
        Task {
            let found = await store.placeSearch.search(query, near: location.currentLocation)
            await MainActor.run { results = found; searching = false }
        }
    }
}
