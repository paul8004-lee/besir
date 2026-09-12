import SwiftUI

/// 앱의 최상위 화면. 서비스(be on-time sir / be full sir)를 고르는 홈을 두고,
/// 고른 서비스의 화면을 전체로 띄운다.
///
/// 서비스별로 화면을 나눈 이유: 일정·이동(be on-time sir)과 식사(be full sir)는 쓰는 맥락이
/// 다른데 한 화면에 섞으면 둘 다 복잡해진다. 대신 **데이터는 같은 Store를 공유**하므로,
/// 식사에서 고른 식당을 바로 일정으로 만들거나(`FullSirView`) 일정 상세에서 주변 맛집을
/// 보는(`EventDetailView`) 식의 연계는 그대로 된다.
struct RootView: View {
    enum Service: String, Identifiable, CaseIterable {
        case onTime, full
        var id: String { rawValue }

        var title: String {
            switch self {
            case .onTime: return "be on-time sir"
            case .full: return "be full sir"
            }
        }
        var systemImage: String {
            switch self {
            case .onTime: return "clock.badge.checkmark"
            case .full: return "fork.knife"
            }
        }
        /// 색은 서비스 구분에만 쓴다 — 이동=세이지, 식사=브라스.
        var tint: Color {
            switch self {
            case .onTime: return Theme.travel
            case .full: return Theme.activity
            }
        }
    }

    @EnvironmentObject var store: Store
    @EnvironmentObject var assistant: AIAssistant
    @State private var service: Service?

    var body: some View {
        Group {
            switch service {
            case .none:
                home
            case .onTime:
                ContentView(onBack: { service = nil })
            case .full:
                FullSirView(onBack: { service = nil })
            }
        }
        // 어느 화면에 있든 같은 시트를 쓴다(홈·be on-time sir·be full sir 모두 AI 버튼이 있다).
        .sheet(isPresented: $assistant.isPresented) {
            AIChatView(assistant: assistant)
        }
    }

    /// 고를 것 두 개와 AI 버튼뿐. 설명 문구는 두지 않는다 — 이름만으로 충분하고,
    /// 매일 여는 첫 화면에 읽을 거리가 있으면 그게 그대로 피로가 된다.
    private var home: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                BesirMark(size: 40)
                Text("besir")
                    .font(.system(size: 32, weight: .regular))
                    .foregroundStyle(Theme.ink)
            }
            .padding(.top, 52)
            .padding(.bottom, 34)

            VStack(spacing: 0) {
                Divider().overlay(Theme.line)
                ForEach(Service.allCases) { s in
                    serviceCard(s)
                    Divider().overlay(Theme.line)
                }
            }

            Spacer()

            if store.config.hasAI {
                Button {
                    assistant.isPresented = true
                } label: {
                    Label("AI에게 물어보기", systemImage: "sparkles")
                        .font(.callout)
                        .foregroundStyle(Theme.travel)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 13)
                        .overlay(RoundedRectangle(cornerRadius: Theme.radius).stroke(Theme.line))
                }
                .buttonStyle(.plain)
                .padding(.bottom, 28)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Theme.bg)
        #if os(macOS)
        .frame(minWidth: 520, minHeight: 560)
        #endif
    }

    private func serviceCard(_ s: Service) -> some View {
        Button {
            service = s
        } label: {
            HStack(spacing: 14) {
                Image(systemName: s.systemImage)
                    .font(.system(size: 17))
                    .foregroundStyle(s.tint)
                    .frame(width: 24)
                Text(s.title)
                    .font(.title3)
                    .foregroundStyle(Theme.ink)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundStyle(Theme.faint)
            }
            .padding(.vertical, 18)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}
