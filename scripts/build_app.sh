#!/bin/bash
set -e

# ======================================
#  cpu_mem_tool 打包脚本
#  将 SPM 编译产物组装为 .app 包
# ======================================

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="cpu_mem_tool"
BUILD_DIR="$PROJECT_DIR/.build"
BIN_DIR="$BUILD_DIR/debug"
APP_BUNDLE="$BUILD_DIR/$APP_NAME.app"

echo "=== 1/4 编译 ==="
cd "$PROJECT_DIR"
swift build

echo ""
echo "=== 2/4 创建 .app 包结构 ==="
rm -rf "$APP_BUNDLE"
mkdir -p "$APP_BUNDLE/Contents/MacOS"
mkdir -p "$APP_BUNDLE/Contents/Resources"

echo "=== 3/4 复制文件 ==="
cp "$BIN_DIR/$APP_NAME" "$APP_BUNDLE/Contents/MacOS/"
cp "$PROJECT_DIR/Resources/Info.plist" "$APP_BUNDLE/Contents/"

# PkgInfo (APPL????)
echo -n "APPL????" > "$APP_BUNDLE/Contents/PkgInfo"

echo "=== 4/4 完成 ==="
echo ""
echo "App 已生成: $APP_BUNDLE"
echo ""
echo "运行方式:"
echo "  open \"$APP_BUNDLE\""
echo ""
echo "停止方式:"
echo "  killall $APP_NAME"
echo ""

# 可选：直接打开
if [ "$1" = "--run" ]; then
    echo "正在启动..."
    open "$APP_BUNDLE"
fi
