import SwiftUI

/// cpu_mem_tool — Mac 菜单栏系统监控应用
/// macOS 26 "液态玻璃"设计风格
///
/// 架构说明：
/// - SystemMonitorService.shared 提供全局单一数据源
/// - AppDelegate 管理 NSStatusBar + NSPopover（菜单栏）
/// - WindowGroup 提供桌面窗口模式
@main
struct cpu_mem_toolApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @ObservedObject private var monitorService = SystemMonitorService.shared

    var body: some Scene {
        // 桌面窗口模式
        WindowGroup {
            ContentView()
                .environmentObject(SystemMonitorService.shared)
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(.contentSize)
        .defaultSize(width: 480, height: 600)
    }
}
