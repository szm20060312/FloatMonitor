# FloatMonitor — Claude 工作指引

## 项目概述
Mac 菜单栏系统监控应用，实时显示 CPU/内存占用，点击弹出详细面板（温度、网络、GPU），同时提供桌面窗口版完整功能。UI 符合 macOS 26 "液态玻璃"设计风格。

## 技术栈
- **语言**: Swift 5.10+
- **UI**: SwiftUI（macOS 26 原生）
- **系统监控**: IOKit + Host.framework + sysctl
- **最低系统**: macOS 26 (Tahoe)
- **IDE**: Xcode 26.5
- **分发**: DMG 自由分发（不上架 App Store）

## 标准文件路径

| 文件 | 路径 | 说明 |
|------|------|------|
| 开发需求 | [docs/requirements.md](docs/requirements.md) | 功能需求、用户故事 |
| 技术规范 | [docs/tech-spec.md](docs/tech-spec.md) | 架构设计、API 选型、数据模型 |
| 设计规范 | [docs/design-spec.md](docs/design-spec.md) | UI/UX 标准、液态玻璃指南 |
| 实施步骤 | [docs/implementation-steps.md](docs/implementation-steps.md) | 分步执行计划 |
| 开发日志 | [dev_logs/](dev_logs/) | 每日开发记录 |

## 工作原则

### 1. 逐步推进
- 严格按照 `docs/implementation-steps.md` 中的步骤顺序执行
- 每一步完成后**停下来**，与用户确认后再继续
- 不要一次性写大量代码，优先保持项目可编译、可运行

### 2. 每次编码前
- 阅读当前步骤对应的标准文件
- 确认理解需求后再动手
- 优先复用已有代码，避免重复造轮子

### 3. 每次编码后
- 确保 Xcode 项目可编译通过
- 运行验证功能是否符合预期
- 更新 `dev_logs/YYYY-MM-DD.md`，记录完成事项和待办事项

### 4. 开发日志规范
- 每天在 `dev_logs/` 下创建 `YYYY-MM-DD.md` 文件
- 包含：完成事项、待办事项、遇到的问题、下一步计划
- 每次代码变更后更新当天的日志

### 5. 遇到不确定的问题
- 优先向用户提问，不做无根据的假设
- 涉及技术选型或 UI 交互的决策需用户确认

## 构建与运行

⚠️ **关键**：`NSStatusBar` 菜单栏图标必须通过 `.app` 包运行，直接执行 SPM 裸二进制不会显示菜单栏。

```bash
# 一键构建 + 启动
bash scripts/build_app.sh --run

# 停止
killall FloatMonitor
```

## 项目结构
```
FloatMonitor/
├── CLAUDE.md                          # 本文件
├── Package.swift                      # SPM 包定义
├── docs/                              # 标准文档
│   ├── requirements.md                # 开发需求
│   ├── tech-spec.md                   # 技术规范
│   ├── design-spec.md                 # 设计规范
│   └── implementation-steps.md        # 实施步骤
├── dev_logs/                          # 开发日志
│   └── YYYY-MM-DD.md
├── Resources/                         # App 资源
│   └── Info.plist                     # 含 LSUIElement=true（隐藏 Dock）
├── scripts/                           # 构建脚本
│   └── build_app.sh                   # 编译 + 打包为 .app
├── Sources/FloatMonitor/              # Swift 源码
│   ├── App/
│   │   ├── FloatMonitorApp.swift      # @main 入口
│   │   └── AppDelegate.swift          # NSStatusBar + NSPopover
│   ├── MenuBar/
│   │   └── MenuBarView.swift          # 弹出面板视图
│   ├── Window/
│   │   └── ContentView.swift          # 桌面窗口视图
│   ├── Services/
│   │   ├── SystemMonitorService.swift # 系统监控服务
│   │   ├── SMCMonitor.swift           # SMC 温度读取
│   │   └── GPUMonitor.swift           # GPU 使用率
│   ├── Models/
│   │   └── SystemStats.swift          # 数据模型
│   └── Utils/
└── .build/                            # 构建产物
    └── FloatMonitor.app               # 可运行的 .app 包
```
