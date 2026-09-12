import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var store: Store
    @EnvironmentObject var assistant: AIAssistant
    @Environment(\.dismiss) private var dismiss

    @State private var autoAdd = true
    @State private var connected = false
    @State private var working = false

    /// 기본값을 5분 단위로 올리고 내린다(정해두지 않은 상태에서 올리면 5분부터 시작).
    private func bump(_ key: WritableKeyPath<AppConfig, Int?>, by delta: Int) {
        var c = store.config
        let next = (c[keyPath: key] ?? 0) + delta
        c[keyPath: key] = next <= 0 ? nil : min(next, 120)
        store.updateConfig(c)
    }

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

            // AI가 값으로 저장한 기본값. 모델이 말로 옮기면서 틀릴 수 있어(실제로 "여유 10분,
            // 알림 30분"을 "둘 다 10분"으로 답한 적이 있다) 여기서 직접 보고 고칠 수 있게 둔다.
            VStack(alignment: .leading, spacing: 8) {
                Text("기본값").font(.headline)
                Picker("이동 수단", selection: Binding(
                    get: { store.config.preferredMode ?? "" },
                    set: { v in var c = store.config; c.preferredMode = v.isEmpty ? nil : v; store.updateConfig(c) }
                )) {
                    Text("정해두지 않음").tag("")
                    ForEach(TransportMode.allCases) { m in Text(m.title).tag(m.rawValue) }
                }
                Stepper("도착 여유: \(store.config.preferredBuffer.map { "\($0)분" } ?? "정해두지 않음")",
                        onIncrement: { bump(\.preferredBuffer, by: 5) },
                        onDecrement: { bump(\.preferredBuffer, by: -5) })
                Stepper("알림: 출발 \(store.config.preferredNotify.map { "\($0)분" } ?? "—") 전",
                        onIncrement: { bump(\.preferredNotify, by: 5) },
                        onDecrement: { bump(\.preferredNotify, by: -5) })
                Text("AI가 새 일정을 만들 때 이 값을 씁니다.")
                    .font(.caption2).foregroundStyle(Theme.faint)
            }

            if !assistant.rememberedFacts.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("AI가 기억하는 정보").font(.headline)
                        Spacer()
                        Button("모두 지우기", role: .destructive) { assistant.forgetAllFacts() }
                            .buttonStyle(.borderless).font(.caption)
                    }
                    ForEach(assistant.rememberedFacts, id: \.self) { fact in
                        HStack {
                            Text(fact).font(.callout)
                            Spacer()
                            Button {
                                assistant.forgetFact(fact)
                            } label: { Image(systemName: "xmark.circle.fill") }
                                .buttonStyle(.borderless)
                                .foregroundStyle(.secondary)
                        }
                    }
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
