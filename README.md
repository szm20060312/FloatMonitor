# FloatMonitor

Mac 菜单栏系统监控工具，实时显示 CPU 与内存占用，点击弹出详细面板查看 GPU、网络等数据。
## 功能

- **菜单栏实时显示** — CPU 和内存占用双行紧凑显示，不占用菜单栏空间
- **弹出详细面板** — 点击菜单栏图标弹出 Popover，展示完整监控数据
- **桌面窗口模式** — 独立窗口，带 Tab 切换（概览 / CPU / 内存 / 网络）
- **可配置刷新间隔** — 0.5s / 1s / 2s / 5s，面板内一键切换
- **GPU 使用率** — 实时读取 Apple Silicon GPU 使用率
- **网络速率** — 下载 / 上传实时速率

## 系统要求

- macOS 26 (Tahoe) 或更高版本
- Apple Silicon / Intel Mac

## 技术栈

| 层面 | 技术 |
|------|------|
| UI | SwiftUI + AppKit (NSStatusBar / NSPopover) |
| 语言 | Swift 6 |
| CPU / 内存 | Host.framework (`host_processor_info` / `host_statistics64`) |
| 网络 | `getifaddrs` + `sysctl` |
| GPU | IOKit (`IOAccelerator`) |
| 构建 | Swift Package Manager |

## 构建与运行

```bash
# 克隆仓库
git clone https://github.com/szm20060312/FloatMonitor.git
cd FloatMonitor

# 一键构建并启动
bash scripts/build_app.sh --run

# 停止应用
killall FloatMonitor
```

或使用 Xcode：

```bash
open Package.swift   # 在 Xcode 中打开，然后 Cmd+R 运行
```

## 项目结构

```
FloatMonitor/
├── Package.swift                    # SPM 包定义
├── Sources/FloatMonitor/
│   ├── App/
│   │   ├── FloatMonitorApp.swift    # @main 入口
│   │   └── AppDelegate.swift        # NSStatusBar + NSPopover
│   ├── MenuBar/
│   │   └── MenuBarView.swift        # 弹出面板视图
│   ├── Window/
│   │   └── ContentView.swift        # 桌面窗口视图
│   ├── Services/
│   │   ├── SystemMonitorService.swift # 系统监控服务
│   │   └── GPUMonitor.swift         # GPU 使用率读取
│   └── Models/
│       └── SystemStats.swift        # 数据模型
├── Resources/
│   └── Info.plist                   # App 包配置
├── scripts/
│   └── build_app.sh                 # 构建 & .app 打包脚本
├── docs/                            # 设计文档
│   ├── requirements.md
│   ├── tech-spec.md
│   ├── design-spec.md
│   └── implementation-steps.md
└── dev_logs/                        # 开发日志
```

## 已知限制

- **温度传感器** — Apple Silicon 上标准 IOKit 路径无法获取 CPU/GPU 温度（macOS 安全限制）
- **菜单栏空间** — 菜单栏图标较多时可能被系统隐藏，可尝试关闭其他菜单栏应用

## 开发状态

项目处于早期开发阶段，按步骤推进：

- [x] 第 1 步 — 项目骨架
- [x] 第 2 步 — 系统监控数据采集
- [x] 第 3 步 — 任务栏基础显示 + 刷新间隔配置
- [x] 第 4 步 — 弹出面板完善 + 液态玻璃效果
- [x] 第 5 步 — 桌面窗口模式完善
- [x] 第 6-10 步 — UI 美化 / 图表 / 设置 / 打包

## 许可证

MIT License
