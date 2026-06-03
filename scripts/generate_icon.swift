#!/usr/bin/env swift
import AppKit
import CoreGraphics

// 生成 FloatMonitor 应用图标
// 输出: 1024x1024 + 各尺寸 PNG 到 Resources/AppIcon.iconset/

let outDir = URL(fileURLWithPath: "Resources/AppIcon.iconset", isDirectory: true)
try? FileManager.default.createDirectory(at: outDir, withIntermediateDirectories: true)

func generateIcon(size: CGFloat, name: String) {
    let rect = CGRect(x: 0, y: 0, width: size, height: size)
    let rep = NSBitmapImageRep(
        bitmapDataPlanes: nil,
        pixelsWide: Int(size), pixelsHigh: Int(size),
        bitsPerSample: 8, samplesPerPixel: 4,
        hasAlpha: true, isPlanar: false,
        colorSpaceName: .deviceRGB,
        bytesPerRow: 0, bitsPerPixel: 0
    )!
    NSGraphicsContext.saveGraphicsState()
    NSGraphicsContext.current = NSGraphicsContext(bitmapImageRep: rep)

    let ctx = NSGraphicsContext.current!.cgContext

    // 1) 圆角矩形背景
    let cornerRadius = size * 0.22
    let bgPath = CGPath(roundedRect: rect.insetBy(dx: size*0.02, dy: size*0.02),
                         cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
    ctx.addPath(bgPath)
    ctx.clip()

    // 2) 渐变背景 (蓝 → 紫)
    let colors = [
        CGColor(red: 0.18, green: 0.45, blue: 0.96, alpha: 1.0),  // 蓝
        CGColor(red: 0.40, green: 0.25, blue: 0.90, alpha: 1.0),  // 紫
    ]
    let gradient = CGGradient(colorsSpace: CGColorSpace(name: CGColorSpace.sRGB), colors: colors as CFArray, locations: [0, 1])!
    ctx.drawLinearGradient(gradient, start: CGPoint(x: 0, y: size),
                           end: CGPoint(x: size, y: 0), options: [])

    // 3) 中央: 简化 CPU 芯片图标 (白)
    ctx.setFillColor(CGColor.white)
    let chipW = size * 0.42
    let chipH = size * 0.46
    let chipX = (size - chipW) / 2
    let chipY = (size - chipH) / 2 + size * 0.03

    // 芯片主体
    let chip = CGRect(x: chipX, y: chipY, width: chipW, height: chipH)
    let chipPath = CGPath(roundedRect: chip, cornerWidth: size*0.06, cornerHeight: size*0.06, transform: nil)
    ctx.addPath(chipPath)
    ctx.setFillColor(CGColor.white)
    ctx.fillPath()

    // 内芯 (半透明)
    let innerInset = size * 0.04
    let inner = chip.insetBy(dx: innerInset, dy: innerInset)
    let innerPath = CGPath(roundedRect: inner, cornerWidth: size*0.03, cornerHeight: size*0.03, transform: nil)
    ctx.addPath(innerPath)
    ctx.setFillColor(CGColor(gray: 0.96, alpha: 0.25))
    ctx.fillPath()

    // 4) 双条形图: CPU / MEM (芯片内)
    let barArea = inner.insetBy(dx: size*0.02, dy: size*0.04)
    let barW = barArea.width * 0.28
    let barH = barArea.height * 0.55
    let barY = barArea.midY - barH / 2
    let colorsBars: [CGColor] = [
        CGColor(red: 0.18, green: 0.45, blue: 0.96, alpha: 0.9),  // 蓝
        CGColor(red: 0.15, green: 0.78, blue: 0.42, alpha: 0.9),  // 绿
    ]
    let barVals: [CGFloat] = [0.72, 0.55]  // 模拟 72% CPU, 55% MEM

    for i in 0..<2 {
        let barX = barArea.minX + CGFloat(i) * (barW + size*0.06) + size*0.02
        // 背景条
        let bgBar = CGRect(x: barX, y: barY, width: barW, height: barH)
        let bgP = CGPath(roundedRect: bgBar, cornerWidth: size*0.015, cornerHeight: size*0.015, transform: nil)
        ctx.addPath(bgP)
        ctx.setFillColor(CGColor(gray: 0.0, alpha: 0.15))
        ctx.fillPath()

        // 前景条
        let fgH = barH * barVals[i]
        let fgY = barY + barH - fgH
        let fgBar = CGRect(x: barX, y: fgY, width: barW, height: fgH)
        let fgP = CGPath(roundedRect: fgBar, cornerWidth: size*0.015, cornerHeight: size*0.015, transform: nil)
        ctx.addPath(fgP)
        ctx.setFillColor(colorsBars[i])
        ctx.fillPath()
    }

    NSGraphicsContext.restoreGraphicsState()

    // 写入 PNG
    let data = rep.representation(using: .png, properties: [:])!
    try! data.write(to: outDir.appendingPathComponent(name))
    print("  ✓ \(name)")
}

// 生成各尺寸
let sizes: [(CGFloat, String)] = [
    (16, "icon_16x16.png"),
    (32, "icon_16x16@2x.png"),
    (32, "icon_32x32.png"),
    (64, "icon_32x32@2x.png"),
    (128, "icon_128x128.png"),
    (256, "icon_128x128@2x.png"),
    (256, "icon_256x256.png"),
    (512, "icon_256x256@2x.png"),
    (512, "icon_512x512.png"),
    (1024, "icon_512x512@2x.png"),
]

print("生成 FloatMonitor 图标…")
for (size, name) in sizes { generateIcon(size: size, name: name) }
print("完成！运行: iconutil -c icns Resources/AppIcon.iconset -o Resources/AppIcon.icns")
