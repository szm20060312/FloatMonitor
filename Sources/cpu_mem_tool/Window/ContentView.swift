import SwiftUI

// MARK: - 桌面窗口主视图

struct ContentView: View {
    @EnvironmentObject var monitorService: SystemMonitorService
    @State private var selectedTab: Tab = .overview
    @State private var floatOnTop = false

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

    var body: some View {
        VStack(spacing: 0) {
            // 顶部 Tab 栏 + 控制按钮
            headerBar

            Divider().opacity(0.3)

            // 内容区
            tabContent
        }
        .frame(minWidth: 420, idealWidth: 480, minHeight: 400, idealHeight: 520)
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(.ultraThinMaterial)
        )
        .background(
            RoundedRectangle(cornerRadius: 0)
                .fill(.white.opacity(0.03))
        )
        .onChange(of: floatOnTop) { _, newValue in
            setWindowLevel(newValue ? .floating : .normal)
        }
    }

    // MARK: - 顶部栏

    private var headerBar: some View {
        HStack(spacing: 0) {
            // Tab 按钮
            ForEach(Tab.allCases, id: \.self) { tab in
                tabButton(tab)
            }
            Spacer()

            // 窗口置顶按钮
            Button {
                floatOnTop.toggle()
            } label: {
                Image(systemName: floatOnTop ? "pin.fill" : "pin")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .foregroundStyle(floatOnTop ? .blue : .secondary)
            .help(floatOnTop ? "取消置顶" : "窗口置顶")
            .padding(.horizontal, 6)
        }
        .padding(.horizontal, 8)
    }

    private func tabButton(_ tab: Tab) -> some View {
        Button {
            selectedTab = tab
        } label: {
            Label(tab.rawValue, systemImage: tab.icon)
                .font(.subheadline.weight(selectedTab == tab ? .semibold : .regular))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .foregroundStyle(selectedTab == tab ? .primary : .secondary)
        .background(
            selectedTab == tab
                ? Capsule().fill(.white.opacity(0.1))
                : Capsule().fill(.clear)
        )
    }

    // MARK: - 内容区

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case .overview:
            OverviewTab()
        case .cpu:
            CPUTab()
        case .memory:
            MemoryTab()
        case .network:
            NetworkTab()
        }
    }

    // MARK: - 窗口层级控制

    private func setWindowLevel(_ level: NSWindow.Level) {
        guard let window = NSApp.windows.first(where: {
            $0.contentView?.subviews.contains(where: { $0 is NSHostingView<AnyView> }) == false
        }) ?? NSApp.keyWindow else { return }
        window.level = level
    }
}

// MARK: - 概览 Tab

private struct OverviewTab: View {
    @EnvironmentObject var monitorService: SystemMonitorService

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // CPU 卡片
                metricCard(
                    title: "CPU", icon: "cpu", color: .blue,
                    value: monitorService.stats.cpuUsage
                ) {
                    gaugeBar(value: monitorService.stats.cpuUsage, color: .blue)
                    if !monitorService.stats.cpuPerCore.isEmpty {
                        miniCoreBars(cores: monitorService.stats.cpuPerCore)
                    }
                }

                // 内存卡片
                let memPercent = monitorService.stats.memoryTotal > 0
                    ? Double(monitorService.stats.memoryUsed) / Double(monitorService.stats.memoryTotal) * 100 : 0
                metricCard(
                    title: "内存", icon: "memorychip", color: memColor,
                    value: memPercent
                ) {
                    gaugeBar(value: memPercent, color: memColor)
                    HStack {
                        Circle().fill(memColor).frame(width: 6, height: 6)
                        Text(monitorService.stats.memoryPressure.label)
                            .font(.caption)
                        Spacer()
                        Text(OverviewTab.formatBytes(monitorService.stats.memoryUsed))
                            .font(.caption)
                        Text(" / ").font(.caption).foregroundStyle(.tertiary)
                        Text(OverviewTab.formatBytes(monitorService.stats.memoryTotal))
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }

                // GPU 卡片
                if let gpu = monitorService.stats.gpuUsage {
                    metricCard(
                        title: "GPU", icon: "display", color: .pink,
                        value: gpu
                    ) {
                        gaugeBar(value: gpu, color: .pink)
                    }
                }

                // 网络卡片
                metricCard(
                    title: "网络", icon: "network", color: .purple,
                    value: nil
                ) {
                    HStack {
                        networkMini(label: "↓ 下载", rate: monitorService.stats.networkDownload, color: .blue)
                        Spacer()
                        networkMini(label: "↑ 上传", rate: monitorService.stats.networkUpload, color: .purple)
                    }
                }

                // 刷新间隔
                HStack {
                    Text("刷新间隔").font(.caption).foregroundStyle(.secondary)
                    Picker("", selection: $monitorService.refreshInterval) {
                        ForEach(SystemMonitorService.availableIntervals, id: \.self) { i in
                            Text(OverviewTab.formatInterval(i)).tag(i)
                        }
                    }
                    .pickerStyle(.segmented).controlSize(.small)
                    .frame(maxWidth: 200)
                    Spacer()
                }
            }
            .padding(20)
        }
    }

    private var memColor: Color {
        switch monitorService.stats.memoryPressure {
        case .normal: .green; case .warning: .orange; case .critical: .red
        }
    }

    // MARK: 卡片组件

    private func metricCard<Content: View>(
        title: String, icon: String, color: Color, value: Double?,
        @ViewBuilder detail: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                Spacer()
                if let v = value {
                    Text(String(format: "%.0f%%", v))
                        .font(.largeTitle.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(
                            v > 80 ? .red : v > 60 ? .orange : color
                        )
                }
            }
            detail()
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.04)))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.08), lineWidth: 0.5)
        )
    }

    // MARK: 子组件

    private func miniCoreBars(cores: [Double]) -> some View {
        HStack(spacing: 2) {
            ForEach(Array(cores.enumerated()), id: \.offset) { _, usage in
                RoundedRectangle(cornerRadius: 1)
                    .fill(usage > 80 ? .red : usage > 60 ? .orange : .blue)
                    .frame(height: max(2, 18 * min(usage, 100) / 100))
                    .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 20)
    }

    private func networkMini(label: String, rate: UInt64, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(Self.formatBytesPerSec(rate))
                .font(.subheadline.weight(.medium).monospaced())
                .foregroundStyle(color)
        }
    }

    static func formatInterval(_ i: TimeInterval) -> String {
        i >= 1 ? "\(Int(i))秒" : String(format: "%.1f秒", i)
    }

    static func formatBytes(_ b: UInt64) -> String {
        String(format: "%.1f GB", Double(b) / (1024*1024*1024))
    }

    static func formatBytesPerSec(_ b: UInt64) -> String {
        if b >= 1_000_000 { return String(format: "%.1f MB/s", Double(b)/1_000_000) }
        if b >= 1_000 { return String(format: "%.0f KB/s", Double(b)/1_000) }
        return "\(b) B/s"
    }
}

// MARK: - CPU 详情 Tab

private struct CPUTab: View {
    @EnvironmentObject var monitorService: SystemMonitorService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 总使用率
                VStack(spacing: 12) {
                    Text("总使用率")
                        .font(.headline)
                    Text(String(format: "%.1f%%", monitorService.stats.cpuUsage))
                        .font(.system(size: 48, weight: .thin, design: .rounded))
                    gaugeBar(value: monitorService.stats.cpuUsage, color: .blue)
                }
                .frame(maxWidth: .infinity)
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.04)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.08), lineWidth: 0.5))

                // 每核心
                VStack(alignment: .leading, spacing: 12) {
                    Text("每核心负载").font(.headline)
                    ForEach(Array(monitorService.stats.cpuPerCore.enumerated()), id: \.offset) { i, usage in
                        HStack(spacing: 10) {
                            Text("核 \(i)")
                                .font(.caption.monospaced())
                                .foregroundStyle(.secondary)
                                .frame(width: 28, alignment: .leading)
                            gaugeBar(value: usage, color: coreColor(usage))
                            Text(String(format: "%2.0f%%", usage))
                                .font(.caption.monospacedDigit())
                                .foregroundStyle(coreColor(usage))
                                .frame(width: 32, alignment: .trailing)
                        }
                    }
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.04)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.08), lineWidth: 0.5))
            }
            .padding(20)
        }
    }

    private func coreColor(_ usage: Double) -> Color {
        usage > 80 ? .red : usage > 60 ? .orange : .blue
    }
}

// MARK: - 内存详情 Tab

private struct MemoryTab: View {
    @EnvironmentObject var monitorService: SystemMonitorService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                let memPercent = monitorService.stats.memoryTotal > 0
                    ? Double(monitorService.stats.memoryUsed) / Double(monitorService.stats.memoryTotal) * 100 : 0

                // 总览
                VStack(spacing: 12) {
                    Text("内存使用")
                        .font(.headline)
                    Text(String(format: "%.1f%%", memPercent))
                        .font(.system(size: 48, weight: .thin, design: .rounded))
                    gaugeBar(value: memPercent, color: memColor)

                    HStack {
                        VStack(alignment: .leading) {
                            Text("已使用").font(.caption).foregroundStyle(.secondary)
                            Text(OverviewTab.formatBytes(monitorService.stats.memoryUsed))
                                .font(.title3.weight(.semibold))
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("总容量").font(.caption).foregroundStyle(.secondary)
                            Text(OverviewTab.formatBytes(monitorService.stats.memoryTotal))
                                .font(.title3.weight(.semibold))
                        }
                    }
                    .padding(.top, 4)
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.04)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.08), lineWidth: 0.5))

                // 内存压力
                VStack(alignment: .leading, spacing: 10) {
                    Text("内存压力").font(.headline)
                    HStack(spacing: 16) {
                        ForEach(MemoryPressure.allCases, id: \.self) { level in
                            VStack(spacing: 4) {
                                Circle()
                                    .fill(level == monitorService.stats.memoryPressure ? pressureColor(level) : .clear)
                                    .frame(width: 16, height: 16)
                                    .overlay(Circle().stroke(.white.opacity(0.2), lineWidth: 1))
                                Text(level.label)
                                    .font(.caption)
                                    .foregroundStyle(level == monitorService.stats.memoryPressure ? .primary : .secondary)
                            }
                        }
                    }
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.04)))
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.08), lineWidth: 0.5))
            }
            .padding(20)
        }
    }

    private var memColor: Color {
        switch monitorService.stats.memoryPressure {
        case .normal: .green; case .warning: .orange; case .critical: .red
        }
    }

    private func pressureColor(_ p: MemoryPressure) -> Color {
        switch p { case .normal: .green; case .warning: .orange; case .critical: .red }
    }
}

// MARK: - 网络详情 Tab

private struct NetworkTab: View {
    @EnvironmentObject var monitorService: SystemMonitorService

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // 下载
                networkDetailCard(
                    title: "下载", icon: "arrow.down.circle.fill", color: .blue,
                    rate: monitorService.stats.networkDownload
                )
                // 上传
                networkDetailCard(
                    title: "上传", icon: "arrow.up.circle.fill", color: .purple,
                    rate: monitorService.stats.networkUpload
                )
            }
            .padding(20)
        }
    }

    private func networkDetailCard(title: String, icon: String, color: Color, rate: UInt64) -> some View {
        VStack(spacing: 16) {
            HStack {
                Label(title, systemImage: icon)
                    .font(.headline)
                    .foregroundStyle(color)
                Spacer()
            }
            Text(OverviewTab.formatBytesPerSec(rate))
                .font(.system(size: 36, weight: .thin, design: .monospaced))
                .foregroundStyle(color)
        }
        .padding(20)
        .background(RoundedRectangle(cornerRadius: 12).fill(.white.opacity(0.04)))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(.white.opacity(0.08), lineWidth: 0.5))
    }
}

// MARK: - 共享组件

private func gaugeBar(value: Double, color: Color) -> some View {
    GeometryReader { g in
        ZStack(alignment: .leading) {
            Capsule().fill(.white.opacity(0.1)).frame(height: 4)
            Capsule()
                .fill(value > 80 ? .red : value > 60 ? .orange : color)
                .frame(width: max(4, g.size.width * min(value, 100) / 100), height: 4)
                .animation(.smooth, value: value)
        }
    }
    .frame(height: 4)
}
