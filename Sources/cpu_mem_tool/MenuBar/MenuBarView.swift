import SwiftUI

// MARK: - 菜单栏弹出面板

struct MenuBarView: View {
    @EnvironmentObject var monitorService: SystemMonitorService

    var body: some View {
        VStack(spacing: 0) {
            headerView
            Divider()

            ScrollView {
                VStack(spacing: 0) {
                    cpuSection
                    sectionDivider
                    memorySection
                    sectionDivider
                    networkSection
                    sectionDivider
                    gpuSection
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
            }

            Divider()
            footerView
        }
        .frame(width: 260)
        .background(
            // 第 1 层：最通透的材质（液态玻璃基底）
            RoundedRectangle(cornerRadius: 12)
                .fill(.ultraThinMaterial)
        )
        .background(
            // 第 2 层：极淡白色叠加，模拟玻璃厚度感
            RoundedRectangle(cornerRadius: 12)
                .fill(.white.opacity(0.04))
        )
        .overlay(
            // 第 3 层：极细白色边框，模拟玻璃边缘折射
            RoundedRectangle(cornerRadius: 12)
                .stroke(.white.opacity(0.12), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.08), radius: 12, y: 4)
    }

    // MARK: - 标题栏

    private var headerView: some View {
        HStack {
            Label("cpu_mem_tool", systemImage: "cpu")
                .font(.subheadline.weight(.medium))
            Spacer()
            Button {
                openMainWindow()
            } label: {
                Image(systemName: "macwindow")
                    .font(.subheadline)
            }
            .buttonStyle(.plain)
            .help("打开桌面窗口")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
    }

    // MARK: - 底部控制栏

    private var footerView: some View {
        HStack(spacing: 8) {
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

            Button {
                NSApplication.shared.terminate(nil)
            } label: {
                Image(systemName: "power")
                    .font(.caption)
            }
            .buttonStyle(.plain)
            .help("退出 cpu_mem_tool")
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
    }

    // MARK: - CPU 模块

    private var cpuSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("CPU", systemImage: "cpu", value: monitorService.stats.cpuUsage)

            // 总体进度条
            gaugeBar(value: monitorService.stats.cpuUsage, color: .blue)

            // 每核心柱状图
            if !monitorService.stats.cpuPerCore.isEmpty {
                perCoreBars(cores: monitorService.stats.cpuPerCore)
            }
        }
    }

    private func perCoreBars(cores: [Double]) -> some View {
        HStack(spacing: 2) {
            ForEach(Array(cores.enumerated()), id: \.offset) { i, usage in
                VStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(
                            usage > 80 ? Color.red :
                            usage > 60 ? Color.orange : Color.blue
                        )
                        .frame(height: max(2, 14 * min(usage, 100) / 100))
                        .animation(.smooth, value: usage)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .frame(height: 16)
    }

    // MARK: - 内存模块

    private var memorySection: some View {
        VStack(alignment: .leading, spacing: 8) {
            let memPercent = monitorService.stats.memoryTotal > 0
                ? Double(monitorService.stats.memoryUsed) / Double(monitorService.stats.memoryTotal) * 100
                : 0
            sectionHeader("内存", systemImage: "memorychip", value: memPercent)
            gaugeBar(value: memPercent, color: pressureColor)

            // 用量信息行
            HStack(spacing: 0) {
                let pressure = monitorService.stats.memoryPressure
                Circle()
                    .fill(pressureColor)
                    .frame(width: 6, height: 6)
                Text(" \(pressure.label)")
                    .font(.caption2)
                    .foregroundStyle(pressureColor)
                Spacer()
                Text(formatBytes(monitorService.stats.memoryUsed))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                Text(" / ")
                    .font(.caption2)
                    .foregroundStyle(.quaternary)
                Text(formatBytes(monitorService.stats.memoryTotal))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var pressureColor: Color {
        switch monitorService.stats.memoryPressure {
        case .normal:  return .green
        case .warning: return .orange
        case .critical: return .red
        }
    }

    // MARK: - 网络模块

    private var networkSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            sectionHeader("网络", systemImage: "network", value: nil)
            HStack(spacing: 12) {
                networkItem(label: "下载", systemImage: "arrow.down",
                            bytesPerSec: monitorService.stats.networkDownload, color: .blue)
                Divider().frame(height: 28)
                networkItem(label: "上传", systemImage: "arrow.up",
                            bytesPerSec: monitorService.stats.networkUpload, color: .purple)
            }
        }
    }

    // MARK: - GPU 模块

    private var gpuSection: some View {
        Group {
            if let gpuUsage = monitorService.stats.gpuUsage {
                VStack(alignment: .leading, spacing: 8) {
                    sectionHeader("GPU", systemImage: "display", value: gpuUsage)
                    gaugeBar(value: gpuUsage, color: .pink)
                }
            }
        }
    }

    // MARK: - 分隔线

    private var sectionDivider: some View {
        Divider()
            .opacity(0.3)
            .padding(.vertical, 8)
    }

    // MARK: - 小组件

    private func sectionHeader(_ title: String, systemImage: String, value: Double?) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 16)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
            if let value {
                Text(String(format: "%.0f%%", value))
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .monospacedDigit()
            }
        }
    }

    private func gaugeBar(value: Double, color: Color) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(.white.opacity(0.1))
                    .frame(height: 4)
                Capsule()
                    .fill(
                        value > 80 ? Color.red :
                        value > 60 ? Color.orange : color
                    )
                    .frame(width: max(4, geometry.size.width * min(value, 100) / 100), height: 4)
                    .animation(.smooth, value: value)
            }
        }
        .frame(height: 4)
    }

    private func networkItem(label: String, systemImage: String, bytesPerSec: UInt64, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.caption2)
                Text(label)
                    .font(.caption2)
            }
            .foregroundStyle(.secondary)
            Text(formatBytesPerSec(bytesPerSec))
                .font(.system(.subheadline, design: .monospaced, weight: .medium))
                .foregroundStyle(color)
        }
    }

    // MARK: - 格式化

    private func formatInterval(_ interval: TimeInterval) -> String {
        interval >= 1.0 ? "\(Int(interval))秒" : String(format: "%.1f秒", interval)
    }

    private func formatBytes(_ bytes: UInt64) -> String {
        String(format: "%.1f GB", Double(bytes) / (1024 * 1024 * 1024))
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
        if NSApp.windows.isEmpty || NSApp.windows.allSatisfy({ !$0.isVisible }) {
            if let window = NSApp.windows.first(where: { $0.canBecomeMain }) {
                window.makeKeyAndOrderFront(nil)
            }
        }
    }
}
