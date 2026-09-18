import SwiftUI
#if os(iOS)
import UIKit
#else
import AppKit
#endif

/// LLM 대화로 일정을 등록하는 채팅 화면.
struct AIChatView: View {
    // 이 assistant는 App 레벨에서 생성돼 공유되는 기존 객체다(공유 확장이 백그라운드에서 채워도
    // 같은 인스턴스를 봐야 함). @StateObject로 감싸면 "이 뷰가 새로 소유·생성한 객체"로 취급돼
    // 화면이 열려 있는 동안 온 변경이 제때 반영되지 않는 문제가 있었다(닫았다 열어야 보임) — 이미
    // 존재하는 객체를 그대로 관찰만 하는 @ObservedObject가 맞다.
    @ObservedObject var assistant: AIAssistant
    @Environment(\.dismiss) private var dismiss
    @FocusState private var inputFocused: Bool
    @State private var copied = false

    /// 대화 전체를 클립보드로. 복사됐다는 표시를 잠깐 보여준다.
    private func copyTranscript() {
        let text = assistant.transcriptForDebugging()
        #if os(iOS)
        UIPasteboard.general.string = text
        #else
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        #endif
        copied = true
        Task {
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            copied = false
        }
    }

    var body: some View {
        NavigationStack {
            Group {
                if assistant.canUse {
                    chat
                } else {
                    ContentUnavailableView("대화형 등록을 사용할 수 없어요",
                                           systemImage: "sparkles",
                                           description: Text("설정에서 서버(프록시) 연결을 확인해 주세요."))
                }
            }
            .background(Theme.bg)
            .navigationTitle("AI로 일정 추가")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("닫기") { dismiss() }
                }
                if assistant.canUse {
                    // ⚠️ 테스트용 임시 버튼 — 출시 전에 AIAssistant.transcriptForDebugging과 같이 뺀다.
                    ToolbarItem(placement: .primaryAction) {
                        Button { copyTranscript() } label: {
                            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                        }
                        .help("대화 전체 복사(도구 호출·결과 포함)")
                    }
                    ToolbarItem(placement: .primaryAction) {
                        Button { assistant.resetConversation() } label: {
                            Image(systemName: "arrow.counterclockwise")
                        }
                        .help("새 대화 시작(이전 대화 기록 지우기)")
                    }
                }
            }
        }
    }

    private var chat: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(assistant.bubbles) { bubble in
                            bubbleView(bubble).id(bubble.id)
                        }
                        if assistant.isThinking {
                            HStack {
                                ProgressView().controlSize(.small)
                                Text("생각 중…").foregroundStyle(.secondary).font(.callout)
                                Spacer()
                            }
                            .id("thinking")
                        }
                    }
                    .padding()
                }
                .onChange(of: assistant.bubbles.count) { _, _ in scrollToEnd(proxy) }
                .onChange(of: assistant.isThinking) { _, _ in scrollToEnd(proxy) }
            }

            Divider()
            inputBar
        }
    }

    @ViewBuilder
    private func bubbleView(_ bubble: AIAssistant.Bubble) -> some View {
        if let ask = bubble.ask {
            // 카드는 말풍선이 아니라 한 장짜리 폼이다 — 줄이 다섯을 넘길 수 있어서 폭을 다 쓴다.
            EditCardView(card: ask, busy: assistant.isThinking, actions: editCardActions)
        } else {
            HStack {
                if bubble.role == .user { Spacer(minLength: 40) }
                Text(bubble.text)
                    .padding(.horizontal, 12).padding(.vertical, 8)
                    .background(bubble.role == .user ? Theme.travel : Theme.raised,
                                in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(bubble.role == .user ? .white : .primary)
                    .textSelection(.enabled)
                if bubble.role == .assistant { Spacer(minLength: 40) }
            }
        }
    }

    /// 추출된 카드 컴포넌트와 AIAssistant를 잇는 어댑터 — 컴포넌트는 이 묶음 너머를 모른다.
    private var editCardActions: EditCardActions {
        EditCardActions(
            chooseValue: { assistant.choose(field: $0, value: $1) },
            rechooseTimeBasis: { _ = assistant.rechooseTimeBasis(field: $0, basis: $1) },
            chooseTime: { assistant.chooseTime(field: $0, basis: $1, date: $2) },
            choosePlace: { assistant.choose(field: $0, place: $1) },
            searchPlaces: { assistant.searchPlaces(field: $0, text: $1) },
            submitCustom: { assistant.submitCustom(field: $0, text: $1) },
            confirm: { await assistant.confirmAsk() }
        )
    }

    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("일정을 말로 입력하세요", text: $assistant.input, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...4)
                .focused($inputFocused)
                .onSubmit(sendTapped)
            Button(action: sendTapped) {
                Image(systemName: "arrow.up.circle.fill").font(.title2)
            }
            .buttonStyle(.plain)
            .disabled(assistant.isThinking ||
                      assistant.input.trimmingCharacters(in: .whitespaces).isEmpty)
        }
        .padding(.horizontal, 12).padding(.vertical, 8)
    }

    private func sendTapped() {
        Task { await assistant.send() }
    }

    private func scrollToEnd(_ proxy: ScrollViewProxy) {
        withAnimation {
            if assistant.isThinking {
                proxy.scrollTo("thinking", anchor: .bottom)
            } else if let last = assistant.bubbles.last {
                proxy.scrollTo(last.id, anchor: .bottom)
            }
        }
    }
}
