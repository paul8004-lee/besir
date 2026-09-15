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
            AskCardView(assistant: assistant, ask: ask)
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

// MARK: - 되묻기 카드

/// 빠진 인자를 **한 장에 모아** 묻는 카드. 호출마다 끼어들지 않는 이유는 AIAssistant 쪽에 적혀
/// 있고, 여기서 지키는 건 그 반대편이다: 물어본 값도 묻지 않고 정해진 값도 **전부 화면에 보인다**.
/// 화면에서 빠진 값은 사용자가 고칠 수 없는 값이고, 그게 b303f41(여유 0분 35건)의 모양이었다.
private struct AskCardView: View {
    @ObservedObject var assistant: AIAssistant
    let ask: AIAssistant.PendingAsk

    // 직접입력 상태는 카드와 수명을 같이 한다. 채팅 뷰에 두면 카드가 요약으로 바뀐 뒤에도
    // 열린 입력창과 거절 표시가 남아 다음 카드로 흘러간다.
    @State private var customOpen: Set<UUID> = []
    @State private var draft: [UUID: String] = [:]
    @State private var rejected: Set<UUID> = []

    // 칩 높이는 글자 크기를 따라 커진다 — 고정하면 큰 글씨 설정에서 칩이 잘린다.
    // iOS는 손가락이라 44pt가 최소고, macOS는 포인터라 그만큼 키우면 카드만 길어진다.
    #if os(iOS)
    @ScaledMetric(relativeTo: .callout) private var chipHeight: CGFloat = 44
    #else
    @ScaledMetric(relativeTo: .callout) private var chipHeight: CGFloat = 28
    #endif

    private var canConfirm: Bool { ask.isReady && !assistant.isThinking }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("몇 가지만 알려주세요")
                .font(.callout.weight(.semibold))
                .foregroundStyle(Theme.ink)

            // 줄이 안 생긴 값 = 묻지 않고 정해진 값. 적어두지 않으면 그게 곧 조용한 기본값이다.
            if !ask.stated.isEmpty {
                Text("말씀하신 대로: " + ask.stated.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(Theme.muted)
            }

            ForEach(ask.fields) { field in
                fieldRow(field)
            }

            confirmButton
        }
        .padding(14)
        .background(Theme.raised, in: RoundedRectangle(cornerRadius: Theme.radius))
        .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.line))
    }

    // MARK: 줄

    @ViewBuilder
    private func fieldRow(_ field: AIAssistant.AskField) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(field.label)
                .font(.caption)
                .foregroundStyle(Theme.faint)

            ChipFlow(spacing: 6, lineSpacing: 6) {
                ForEach(field.options) { option in
                    chip(option.label, selected: field.chosen == option.value) {
                        assistant.choose(field: field.id, value: option.value)
                        closeCustom(field)
                    }
                }
                // 직접 적은 값도 선택된 칩으로 남긴다 — 고른 값이 화면에 없으면 안 고른 것과 같다.
                if let typed = typedLabel(field) {
                    chip(typed, selected: true) { openCustom(field) }
                }
                if field.allowsCustom {
                    chip("직접입력", selected: false, dashed: true) { openCustom(field) }
                }
            }

            if customOpen.contains(field.id) { customEditor(field) }

            // 거절 사유에 범위를 적지 않는 이유: 상한이 Store 상수라 문구에 박으면 두 곳이 된다.
            if rejected.contains(field.id) {
                Text("그 값은 쓸 수 없어요")
                    .font(.caption)
                    .foregroundStyle(Theme.warn)
            }
        }
        // 칩만 따로 읽히면 무엇에 대한 선택인지 알 수 없다 — 줄 이름과 묶어서 읽히게 한다.
        .accessibilityElement(children: .contain)
        .accessibilityLabel(field.label)
    }

    /// 칩 목록에 없는 값이 골라져 있으면 그 표시 문구. 없으면 nil.
    private func typedLabel(_ field: AIAssistant.AskField) -> String? {
        guard let chosen = field.chosen,
              !field.options.contains(where: { $0.value == chosen }) else { return nil }
        return field.chosenLabel
    }

    /// 칩 하나. 선택 표시를 색에만 맡기지 않는다(체크 글리프 + 글자 굵기) — 색을 구분 못 하면
    /// 어느 값을 골랐는지 알 방법이 사라진다. 직접입력 칩은 점선 테두리로 성격이 다름을 보인다.
    private func chip(_ label: String, selected: Bool, dashed: Bool = false,
                      action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 4) {
                if selected {
                    Image(systemName: "checkmark").font(.caption2.weight(.bold))
                }
                Text(label).font(.callout.weight(selected ? .semibold : .regular))
            }
            .foregroundStyle(selected ? Theme.bg : Theme.ink)
            .padding(.horizontal, 12)
            .frame(minHeight: chipHeight)
            .background(selected ? Theme.travel : Theme.bg, in: Capsule())
            .overlay(
                Capsule().strokeBorder(selected ? Color.clear : Theme.line,
                                       style: StrokeStyle(lineWidth: 1, dash: dashed ? [3, 3] : []))
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isButton, .isSelected] : .isButton)
    }

    // MARK: 직접입력

    @ViewBuilder
    private func customEditor(_ field: AIAssistant.AskField) -> some View {
        HStack(spacing: 6) {
            TextField(field.kind == .place ? "장소 이름" : "숫자만", text: draftBinding(field))
                .textFieldStyle(.roundedBorder)
                #if os(iOS)
                // 숫자 줄은 숫자판이 편하지만 숫자판엔 완료 키가 없다 — 그래서 확인 버튼이 있다.
                .keyboardType(field.kind == .place ? .default : .numberPad)
                #endif
                .onSubmit { submitCustom(field) }
            Button("확인") { submitCustom(field) }
                .buttonStyle(.plain)
                .font(.callout.weight(.semibold))
                .foregroundStyle(Theme.travelInk)
                .padding(.horizontal, 10)
                .frame(minHeight: chipHeight)
                .background(Theme.travelFill, in: Capsule())
        }
    }

    private func draftBinding(_ field: AIAssistant.AskField) -> Binding<String> {
        Binding(
            get: { draft[field.id] ?? "" },
            set: { text in
                draft[field.id] = text
                // 고쳐 쓰기 시작하면 거절 표시는 지운다 — 남아 있으면 지금 값이 거절된 것처럼 보인다.
                rejected.remove(field.id)
            }
        )
    }

    private func openCustom(_ field: AIAssistant.AskField) {
        draft[field.id] = typedLabel(field) == nil ? "" : (field.chosen ?? "")
        customOpen.insert(field.id)
    }

    private func closeCustom(_ field: AIAssistant.AskField) {
        customOpen.remove(field.id)
        rejected.remove(field.id)
    }

    /// 거절되면 입력창을 열어둔 채 표시만 남긴다 — 닫아버리면 무엇이 안 받아들여졌는지 사라진다.
    private func submitCustom(_ field: AIAssistant.AskField) {
        if assistant.submitCustom(field: field.id, text: draft[field.id] ?? "") {
            draft[field.id] = ""
            closeCustom(field)
        } else {
            rejected.insert(field.id)
        }
    }

    // MARK: 확인

    private var confirmButton: some View {
        Button { Task { await assistant.confirmAsk() } } label: {
            HStack(spacing: 6) {
                Spacer(minLength: 0)
                if assistant.isThinking {
                    ProgressView().controlSize(.small)
                } else {
                    Text("등록하기").font(.callout.weight(.semibold))
                }
                Spacer(minLength: 0)
            }
            .foregroundStyle(canConfirm ? Theme.bg : Theme.muted)
            .frame(maxWidth: .infinity, minHeight: chipHeight)
            .background(canConfirm ? Theme.travel : Theme.bg,
                        in: RoundedRectangle(cornerRadius: Theme.radius))
            .overlay(
                RoundedRectangle(cornerRadius: Theme.radius)
                    .stroke(canConfirm ? Color.clear : Theme.line)
            )
        }
        .buttonStyle(.plain)
        .disabled(!canConfirm)
        .accessibilityHint(ask.isReady ? "" : "빠진 값을 모두 고르면 눌 수 있어요")
    }
}

/// 칩을 줄바꿈으로 흘려 넣는 배치.
///
/// 가로 스크롤을 쓰지 않는 이유: 화면 밖으로 밀린 칩은 **고를 수 없는 값**이고, 이 카드에서
/// 못 고른 값은 그대로 조용한 기본값이 된다. 반복 일정이면 줄이 다섯을 넘지만 카드는 길어져도
/// 되고, 스크롤은 채팅 쪽 ScrollView가 이미 맡고 있다.
private struct ChipFlow: Layout {
    var spacing: CGFloat = 6
    var lineSpacing: CGFloat = 6

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(subviews, maxWidth: proposal.width ?? .infinity)
        let height = rows.reduce(0) { $0 + $1.height } + lineSpacing * CGFloat(max(0, rows.count - 1))
        return CGSize(width: proposal.width ?? (rows.map(\.width).max() ?? 0), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize,
                       subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(subviews, maxWidth: bounds.width) {
            var x = bounds.minX
            for item in row.items {
                subviews[item.index].place(at: CGPoint(x: x, y: y), anchor: .topLeading,
                                           proposal: ProposedViewSize(item.size))
                x += item.size.width + spacing
            }
            y += row.height + lineSpacing
        }
    }

    private struct Row {
        var items: [(index: Int, size: CGSize)] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    /// 배치와 크기 계산이 같은 함수를 쓴다 — 따로 세면 높이와 실제 줄 수가 어긋난다.
    private func arrange(_ subviews: Subviews, maxWidth: CGFloat) -> [Row] {
        var rows: [Row] = []
        var row = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            // 칩 하나가 한 줄보다 넓어도 줄을 새로 열지 않는다 — 빈 줄만 생긴다.
            if !row.items.isEmpty, row.width + spacing + size.width > maxWidth {
                rows.append(row)
                row = Row()
            }
            row.width += row.items.isEmpty ? size.width : spacing + size.width
            row.height = max(row.height, size.height)
            row.items.append((index, size))
        }
        if !row.items.isEmpty { rows.append(row) }
        return rows
    }
}
