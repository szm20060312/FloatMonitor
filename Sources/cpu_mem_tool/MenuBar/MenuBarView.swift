import SwiftUI

// MARK: - 菜单栏弹出面板

struct MenuBarView: View {
    @EnvironmentObject var monitorService: SystemMonitorService
    @Environment(\.openWindow) private var openWindow

    var body: some View {
        VStack(spacing: 0) {
            headerView
            separator

            ScrollView {
                VStack(spacing: 6) {
                    cpuSection
                    separator
                    memorySection
                    separator
                    networkSection
                    separator
                    gpuSection
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
            }

            separator
            footerView
        }
        .frame(width: 260)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(.white.opacity(0.08), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.12), radius: 16, y: 6)
    }

    // MARK: - 标题栏

    private var headerView: some View {
        HStack(spacing: 6) {
            Image(systemName: "cpu")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.blue)
            Text("cpu_mem_tool")
                .font(.caption.weight(.semibold))
            Spacer()
            Button { openMainWindow() } label: {
                Image(systemName: "macwindow").font(.caption)
            }
            .buttonStyle(.plain).foregroundStyle(.secondary).help("打开桌面窗口")
            SettingsLink {
                Image(systemName: "gearshape").font(.caption)
            }
            .buttonStyle(.plain).foregroundStyle(.secondary).help("设置")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    // MARK: - 底部控制栏

    private var footerView: some View {
        HStack(spacing: 5) {
            Picker("", selection: $monitorService.refreshInterval) {
                ForEach(SystemMonitorService.availableIntervals, id: \.self) { interval in
                    Text(formatInterval(interval)).tag(interval).font(.caption2)
                }
            }
            .pickerStyle(.segmented)
            .controlSize(.mini)
            Spacer()
            Button { NSApplication.shared.terminate(nil) } label: {
                Image(systemName: "power").font(.caption2)
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
            .help("退出")
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 7)
    }

    // MARK: - CPU

    private var cpuSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            sectionHeader("CPU", icon: "cpu", color: .blue,
                          value: monitorService.stats.cpuUsage)
            gaugeBar(value: monitorService.stats.cpuUsage, color: .blue)
            if !monitorService.stats.cpuPerCore.isEmpty {
                perCoreBars(cores: monitorService.stats.cpuPerCore)
            }
        }
    }

    private func perCoreBars(cores: [Double]) -> some View {
        HStack(spacing: 2) {
            ForEach(Array(cores.enumerated()), id: \.offset) { _, u in
                RoundedRectangle(cornerRadius: 1)
                    .fill(coreBarColor(u))
                    .frame(height: max(2, 14 * min(u, 100) / 100))
                    .frame(maxWidth: .infinity)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: u)
            }
        }
        .frame(height: 16)
    }

    // MARK: - 内存

    private var memorySection: some View {
        VStack(alignment: .leading, spacing: 5) {
            let pct = monitorService.stats.memoryTotal > 0
                ? Double(monitorService.stats.memoryUsed) / Double(monitorService.stats.memoryTotal) * 100 : 0
            sectionHeader("内存", icon: "memorychip", color: pressureColor,
                          value: pct)
            gaugeBar(value: pct, color: pressureColor)
            HStack(spacing: 0) {
                Circle().fill(pressureColor).frame(width: 6, height: 6)
                Text(" \(monitorService.stats.memoryPressure.label)")
                    .font(.caption2).foregroundStyle(pressureColor)
                Spacer()
                Text(formatBytes(monitorService.stats.memoryUsed))
                    .font(.caption2).foregroundStyle(.secondary)
                Text(" / ").font(.caption2).foregroundStyle(.quaternary)
                Text(formatBytes(monitorService.stats.memoryTotal))
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
    }

    private var pressureColor: Color {
        switch monitorService.stats.memoryPressure {
        case .normal: .green; case .warning: .orange; case .critical: .red
        }
    }

    // MARK: - 网络

    private var networkSection: some View {
        VStack(alignment: .leading, spacing: 5) {
            sectionHeader("网络", icon: "network", color: .purple, value: nil)
            HStack(spacing: 10) {
                netItem("↓ 下载", bytes: monitorService.stats.networkDownload, color: .blue)
                Rectangle().fill(.white.opacity(0.06)).frame(width: 1, height: 28)
                netItem("↑ 上传", bytes: monitorService.stats.networkUpload, color: .purple)
            }
        }
    }

    private func netItem(_ label: String, bytes: UInt64, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(formatBytesPerSec(bytes))
                .font(.caption.weight(.medium).monospaced())
                .foregroundStyle(color)
                .contentTransition(.numericText(value: Double(bytes)))
        }
    }

    // MARK: - GPU

    private var gpuSection: some View {
        Group {
            if let g = monitorService.stats.gpuUsage {
                VStack(alignment: .leading, spacing: 5) {
                    sectionHeader("GPU", icon: "display", color: .pink, value: g)
                    gaugeBar(value: g, color: .pink)
                }
            }
        }
    }

    // MARK: - 组件

    private var separator: some View {
        Rectangle()
            .fill(.white.opacity(0.06))
            .frame(height: 1)
            .padding(.horizontal, 14)
    }

    private func sectionHeader(_ title: String, icon: String, color: Color, value: Double?) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(color)
                .frame(width: 14)
            Text(title)
                .font(.caption)
                .foregroundStyle(.primary)
            Spacer()
            if let v = value {
                Text(String(format: "%.0f%%", v))
                    .font(.system(.callout, design: .rounded, weight: .bold))
                    .monospacedDigit()
                    .foregroundStyle(v > 80 ? .red : v > 60 ? .orange : .primary)
                    .contentTransition(.numericText(value: v))
            }
        }
    }

    private func gaugeBar(value: Double, color: Color) -> some View {
        GeometryReader { g in
            ZStack(alignment: .leading) {
                Capsule().fill(.quaternary).frame(height: 4)
                Capsule()
                    .fill(coreBarColor(value))
                    .frame(width: max(4, g.size.width * min(value, 100) / 100), height: 4)
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: value)
            }
        }
        .frame(height: 4)
    }

    private func coreBarColor(_ usage: Double) -> Color {
        usage > 80 ? .red : usage > 60 ? .orange : usage > 30 ? .blue : .blue.opacity(0.6)
    }

    // MARK: - 格式化

    private func formatInterval(_ interval: TimeInterval) -> String {
        interval >= 1.0 ? "\(Int(interval))秒" : String(format: "%.1f秒", interval)
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        String(format: "%.1f GB", Double(bytes) / (1024*1024*1024))
    }

    private func formatBytesPerSec(_ bytes: UInt64) -> String {
        let unit = AppSettings.shared.networkUnit
        if unit == .bitsPerSec {
            let bps = Double(bytes) * 8
            if bps >= 1_000_000_000 { return String(format: "%.1f Gbps", bps / 1_000_000_000) }
            if bps >= 1_000_000 { return String(format: "%.1f Mbps", bps / 1_000_000) }
            if bps >= 1_000 { return String(format: "%.0f Kbps", bps / 1_000) }
            return "\(Int(bps)) bps"
        }
        if bytes >= 1_000_000 { return String(format: "%.1f MB/s", Double(bytes)/1_000_000) }
        if bytes >= 1_000     { return String(format: "%.0f KB/s", Double(bytes)/1_000) }
        return "\(bytes) B/s"
    }

    // MARK: - 动作

    private func openMainWindow() {
        NSApp.setActivationPolicy(.regular)
        openWindow(id: "main")
        NSApp.activate(ignoringOtherApps: true)
    }

}
