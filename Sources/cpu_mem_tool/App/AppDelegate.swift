import SwiftUI
import AppKit
import Combine

// MARK: - 双行菜单栏文本视图

/// 自定义 NSView，在菜单栏中以双行紧凑布局显示 CPU/内存数据
/// 宽度仅 ~36pt，避免因文字过长被系统隐藏
final class StatusBarTextView: NSView {
    var cpuText: String = "--" {
        didSet { needsDisplay = true }
    }
    var memText: String = "--" {
        didSet { needsDisplay = true }
    }

    override var intrinsicContentSize: NSSize {
        NSSize(width: 37, height: 22)
    }

    override func draw(_ dirtyRect: NSRect) {
        // 根据深色/浅色模式自适应文字颜色
        let isDark = effectiveAppearance.name == .darkAqua
            || effectiveAppearance.name == .vibrantDark
        let textColor: NSColor = isDark ? .white : .black

        let lineAttrs: [NSAttributedString.Key: Any] = [
            .font: NSFont.monospacedDigitSystemFont(ofSize: 7.5, weight: .medium),
            .foregroundColor: textColor,
            .kern: -0.2 as NSNumber,
        ]

        let cpuLine = "C \(cpuText)" as NSString
        let memLine = "M \(memText)" as NSString

        cpuLine.draw(at: NSPoint(x: 1, y: bounds.height - 9.5), withAttributes: lineAttrs)
        memLine.draw(at: NSPoint(x: 1, y: 1.5), withAttributes: lineAttrs)
    }
}

// MARK: - AppDelegate

/// 管理 NSStatusBar 和 NSPopover
/// 通过 NSApplicationDelegateAdaptor 集成到 SwiftUI App 生命周期
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem!
    private var statusView: StatusBarTextView!
    private var popover: NSPopover!
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        setupStatusBar()
        setupPopover()
        observeStats()
    }

    // MARK: - 状态栏（双行紧凑视图）

    private func setupStatusBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: 37)

        if let button = statusItem.button {
            // 隐藏默认 title，使用自定义双行 view
            button.title = ""
            button.target = self
            button.action = #selector(togglePopover)

            statusView = StatusBarTextView(frame: button.bounds)
            statusView.autoresizingMask = [.width, .height]
            button.addSubview(statusView)
        }
    }

    // MARK: - Popover

    private func setupPopover() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 260, height: 380)
        popover.behavior = .transient

        // 用 NSVisualEffectView 作为底层承载，实现 Liquid Glass 效果
        let visualEffectView = NSVisualEffectView(frame: NSRect(x: 0, y: 0, width: 260, height: 380))
        visualEffectView.wantsLayer = true
        visualEffectView.material = .fullScreenUI       // 液态玻璃材质
        visualEffectView.blendingMode = .behindWindow   // 透出背后内容（无模糊）
        visualEffectView.state = .active
        visualEffectView.isEmphasized = false
        visualEffectView.layer?.cornerRadius = 12
        visualEffectView.layer?.masksToBounds = true

        // SwiftUI 视图（应用 .glassEffect(.clear)）
        let hostingView = NSHostingView(
            rootView: MenuBarView()
                .environmentObject(SystemMonitorService.shared)
                .glassEffect(.clear)
        )
        hostingView.translatesAutoresizingMaskIntoConstraints = false

        visualEffectView.addSubview(hostingView)
        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: visualEffectView.leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: visualEffectView.trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: visualEffectView.topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: visualEffectView.bottomAnchor),
        ])

        let vc = NSViewController()
        vc.view = visualEffectView
        popover.contentViewController = vc
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
        statusView.cpuText = String(format: "%02d%%", Int(cpu))
        statusView.memText = String(format: "%02d%%", memPercent)
    }
}
