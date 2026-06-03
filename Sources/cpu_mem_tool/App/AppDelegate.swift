import SwiftUI
import AppKit
import Combine

/// 管理 NSStatusBar 和 NSPopover
/// 通过 NSApplicationDelegateAdaptor 集成到 SwiftUI App 生命周期
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var popover: NSPopover!
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        // 初始隐藏 Dock 图标（纯菜单栏应用）
        NSApp.setActivationPolicy(.accessory)

        setupStatusBar()
        setupPopover()
        observeStats()
    }

    // MARK: - 状态栏

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        if let button = statusItem.button {
            button.title = "CPU --% MEM --%"
            button.font = NSFont.monospacedDigitSystemFont(
                ofSize: NSFont.smallSystemFontSize,
                weight: .medium
            )
            button.target = self
            button.action = #selector(togglePopover)
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 320, height: 460)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(
            rootView: MenuBarView()
                .environmentObject(SystemMonitorService.shared)
        )
    }

    @objc private func togglePopover() {
        guard let button = statusItem.button else { return }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(
                relativeTo: button.bounds,
                of: button,
                preferredEdge: .minY
            )
            // 确保 popover 获得焦点
            popover.contentViewController?.view.window?.makeKey()
        }
    }

    // MARK: - 监听数据更新

    private func observeStats() {
        SystemMonitorService.shared.$stats
            .receive(on: DispatchQueue.main)
            .sink { [weak self] stats in
                self?.updateStatusBar(
                    cpu: stats.cpuUsage,
                    memoryUsed: stats.memoryUsed,
                    memoryTotal: stats.memoryTotal
                )
            }
            .store(in: &cancellables)
    }

    private func updateStatusBar(cpu: Double, memoryUsed: UInt64, memoryTotal: UInt64) {
        let memPercent = memoryTotal > 0
            ? Int(Double(memoryUsed) / Double(memoryTotal) * 100)
            : 0
        statusItem.button?.title = String(
            format: "CPU %02d%% MEM %02d%%",
            Int(cpu), memPercent
        )
    }
}
