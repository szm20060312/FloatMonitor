import SwiftUI

/// 菜单栏弹出面板的内容视图
struct MenuBarView: View {
    @EnvironmentObject var monitorService: SystemMonitorService

    var body: some View {
        VStack(spacing: 0) {
            // 标题栏
            headerView
            Divider()

            // 内容区
            ScrollView {
                VStack(spacing: 16) {
                    cpuSection
                    Divider()
                    memorySection
                    Divider()
                    networkSection
                    Divider()
                    gpuSection
                }
                .padding(16)
            }

            Divider()

            // 底部控制栏：刷新间隔 + 退出
            footerView
        }
        .frame(width: 320)
    }

    // MARK: - 底部控制栏

    private var footerView: some View {
        HStack(spacing: 8) {
            // 刷新间隔选择器
            Text("刷新:")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("刷新间隔", selection: $monitorService.refreshInterval) {
                ForEach(SystemMonitorService.availableIntervals, id: \.self) { interval in
                    Text(formatInterval(interval))
                        .tag(interval)
                        .font(.caption)
                }
            }
            .pickerStyle(.segmented)
            .controlSize(.mini)

            Spacer()

            // 退出按钮
            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .help("退出 cpu_mem_tool")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - 标题栏

    private var headerView: some View {
        HStack {
            Label("cpu_mem_tool", systemImage: "cpu")
                .font(.headline)
            Spacer()
            Button {
                openMainWindow()
            } label: {
                Image(systemName: "macwindow")
                    .font(.title3)
            }
            .buttonStyle(.plain)
            .help("打开桌面窗口")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }

    // MARK: - 各模块

    private var cpuSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("CPU", systemImage: "cpu", value: monitorService.stats.cpuUsage)
            gaugeBar(value: monitorService.stats.cpuUsage, color: .blue)
        }
    }

    private var memorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            let memPercent = monitorService.stats.memoryTotal > 0
                ? Double(monitorService.stats.memoryUsed) / Double(monitorService.stats.memoryTotal) * 100
                : 0
            sectionHeader("内存", systemImage: "memorychip", value: memPercent)
            gaugeBar(value: memPercent, color: .green)
            HStack {
                Text("压力: \(monitorService.stats.memoryPressure.label)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(formatBytes(monitorService.stats.memoryUsed))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(" / ")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formatBytes(monitorService.stats.memoryTotal))
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var networkSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("网络", systemImage: "network", value: nil)
            HStack(spacing: 16) {
                networkItem(
                    label: "下载",
                    systemImage: "arrow.down",
                    bytesPerSec: monitorService.stats.networkDownload,
                    color: .blue
                )
                networkItem(
                    label: "上传",
                    systemImage: "arrow.up",
                    bytesPerSec: monitorService.stats.networkUpload,
                    color: .purple
                )
            }
        }
    }

    private var gpuSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let gpuUsage = monitorService.stats.gpuUsage {
                sectionHeader("GPU", systemImage: "display", value: gpuUsage)
                gaugeBar(value: gpuUsage, color: .pink)
            }
        }
    }

    // MARK: - 小组件

    private func sectionHeader(_ title: String, systemImage: String, value: Double?) -> some View {
        HStack {
            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if let value {
                Text(String(format: "%.0f%%", value))
                    .font(.title2)
                    .fontWeight(.bold)
                    .monospacedDigit()
            }
        }
    }

    private func gaugeBar(value: Double, color: Color) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(.quaternary)
                    .frame(height: 6)
                RoundedRectangle(cornerRadius: 3)
                    .fill(
                        value > 80 ? Color.red :
                        value > 60 ? Color.orange :
                        color
                    )
                    .frame(width: geometry.size.width * min(value, 100) / 100, height: 6)
                    .animation(.smooth, value: value)
            }
        }
        .frame(height: 6)
    }

    private func networkItem(label: String, systemImage: String, bytesPerSec: UInt64, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Label(label, systemImage: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(formatBytesPerSec(bytesPerSec))
                .font(.subheadline)
                .fontWeight(.medium)
                .monospacedDigit()
                .foregroundStyle(color)
        }
    }

    // MARK: - 格式化

    private func formatInterval(_ interval: TimeInterval) -> String {
        if interval >= 1.0 {
            return "\(Int(interval))秒"
        } else {
            return String(format: "%.1f秒", interval)
        }
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        let gb = Double(bytes) / (1024 * 1024 * 1024)
        return String(format: "%.1f GB", gb)
    }

    private func formatBytesPerSec(_ bytes: UInt64) -> String {
        if bytes >= 1_000_000 {
            return String(format: "%.1f MB/s", Double(bytes) / 1_000_000)
        } else if bytes >= 1_000 {
            return String(format: "%.0f KB/s", Double(bytes) / 1_000)
        } else {
            return "\(bytes) B/s"
        }
    }

    // MARK: - 动作

    private func openMainWindow() {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)

        // 确保有可见窗口
        if NSApp.windows.isEmpty || NSApp.windows.allSatisfy({ !$0.isVisible }) {
            // 通过 URL scheme 或通知打开窗口
            if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
}
