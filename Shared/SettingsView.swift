import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @Environment(\.dismiss) private var dismiss

    @State private var autoAdd = true
    @State private var connected = false
    @State private var working = false

    @State private var showingWipe = false

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text("설정").font(.title2).bold()

            VStack(alignment: .leading, spacing: 6) {
                Toggle("일정 생성 시 구글 캘린더에 자동 등록", isOn: $autoAdd)
                    .disabled(!store.config.hasGoogleCalendar)
                Text(store.config.hasGoogleCalendar
                     ? "끄면 일정 상세에서 직접 추가할 수 있습니다."
                     : "구글 캘린더 연동이 설정되어 있지 않습니다.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            if store.config.hasGoogleCalendar {
                if connected {
                    HStack {
                        Label("구글 계정 연결됨", systemImage: "checkmark.circle.fill")
                            .foregroundStyle(.green).font(.callout)
                        Spacer()
                        Button("연결 끊기", role: .destructive) {
                            store.gcal.disconnect(); connected = false
                        }
                    }
                } else {
                    Button {
                        Task {
                            working = true
                            await store.connectGoogle()
                            connected = store.googleConnected
                            working = false
                        }
                    } label: {
                        Label(working ? "연결 중…" : "구글 계정 연결", systemImage: "person.crop.circle.badge.plus")
                    }
                    .disabled(working)
                }
            }

            // ⚠️ 테스트용 임시 버튼 — 출시 전에 이 블록과 Store.deleteEverythingForTesting을 같이 뺀다.
            VStack(alignment: .leading, spacing: 6) {
                Text("테스트").font(.headline)
                Button(role: .destructive) {
                    showingWipe = true
                } label: {
                    Label("일정 모두 삭제", systemImage: "trash")
                }
                Text("일정·활동·식사 기록을 전부 지웁니다. 구글 캘린더에서도 지워집니다.")
                    .font(.caption2).foregroundStyle(Theme.faint)
            }
            .confirmationDialog("등록된 일정·활동·식사 기록을 모두 지울까요?",
                                isPresented: $showingWipe, titleVisibility: .visible) {
                Button("모두 삭제", role: .destructive) { store.deleteEverythingForTesting() }
                Button("취소", role: .cancel) {}
            }

            Spacer()
            HStack {
                Spacer()
                Button("취소") { dismiss() }
                Button("저장") {
                    var c = store.config
                    c.autoAddToCalendar = autoAdd
                    store.updateConfig(c)
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(24)
        #if os(macOS)
        .frame(width: 460)
        .frame(minHeight: 260)
        #endif
        .onAppear {
            autoAdd = store.config.autoAddToCalendar
            connected = store.googleConnected
        }
    }
}
