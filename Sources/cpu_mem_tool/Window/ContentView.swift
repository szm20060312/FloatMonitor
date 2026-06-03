import SwiftUI

/// 桌面窗口主视图
/// 复用 MenuBarView 的子组件，提供更宽松的布局
struct ContentView: View {
    @EnvironmentObject var monitorService: SystemMonitorService

    enum Tab: String, CaseIterable {
        case overview = "概览"
        case cpu = "CPU"
        case memory = "内存"
        case network = "网络"

        var icon: String {
            switch self {
            case .overview: return "square.grid.2x2"
            case .cpu: return "cpu"
            case .memory: return "memorychip"
            case .network: return "network"
            }
        }
    }

    @State private var selectedTab: Tab = .overview

    var body: some View {
        VStack(spacing: 0) {
            // Tab 栏
            tabBar

            Divider()

            // 内容区
            TabContentView(tab: selectedTab)
                .environmentObject(monitorService)
                .padding(20)
        }
        .frame(minWidth: 400, minHeight: 400)
        .background(.regularMaterial)
    }

    private var tabBar: some View {
        HStack(spacing: 0) {
            ForEach(Tab.allCases, id: \.self) { tab in
                Button {
                    selectedTab = tab
                } label: {
                    Label(tab.rawValue, systemImage: tab.icon)
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                }
                .buttonStyle(.plain)
                .foregroundStyle(selectedTab == tab ? .primary : .secondary)
                .background(
                    selectedTab == tab
                        ? AnyShapeStyle(.bar)
                        : AnyShapeStyle(.clear)
                )
            }
            Spacer()
        }
        .padding(.horizontal, 8)
        .padding(.top, 8)
    }
}

/// Tab 内容视图
struct TabContentView: View {
    let tab: ContentView.Tab
    @EnvironmentObject var monitorService: SystemMonitorService

    var body: some View {
        switch tab {
        case .overview:
            overviewContent
        case .cpu:
            cpuContent
        case .memory:
            memoryContent
        case .network:
            networkContent
        }
    }

    // MARK: - 概览

    private var overviewContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("系统概览")
                    .font(.title)
                    .fontWeight(.semibold)
                Text("详细实现将在后续步骤中添加")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        }
    }

    // MARK: - CPU

    private var cpuContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("CPU 详情")
                    .font(.title)
                    .fontWeight(.semibold)
                Text("每核心使用率图表将在第 4 步实现")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        }
    }

    // MARK: - 内存

    private var memoryContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("内存详情")
                    .font(.title)
                    .fontWeight(.semibold)
                Text("内存详细信息和图表将在第 4 步实现")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        }
    }

    // MARK: - 网络

    private var networkContent: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("网络详情")
                    .font(.title)
                    .fontWeight(.semibold)
                Text("网络详细信息和图表将在第 4 步实现")
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 60)
        }
    }
}
