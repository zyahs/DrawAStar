#!/usr/bin/env swift

import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

struct RGB {
    let red: Double
    let green: Double
    let blue: Double
}

struct HSV {
    let hue: Double
    let saturation: Double
    let value: Double
}

struct IconVariant {
    let assetName: String
    let palette: [RGB]?
}

func rgb(_ hex: Int) -> RGB {
    RGB(red: Double((hex >> 16) & 0xff) / 255.0,
        green: Double((hex >> 8) & 0xff) / 255.0,
        blue: Double(hex & 0xff) / 255.0)
}

func rgbToHSV(_ color: RGB) -> HSV {
    let maximum = max(color.red, color.green, color.blue)
    let minimum = min(color.red, color.green, color.blue)
    let delta = maximum - minimum
    var hue = 0.0

    if delta > 0.0001 {
        if maximum == color.red {
            hue = (color.green - color.blue) / delta
        } else if maximum == color.green {
            hue = 2.0 + (color.blue - color.red) / delta
        } else {
            hue = 4.0 + (color.red - color.green) / delta
        }
        hue /= 6.0
        if hue < 0 { hue += 1.0 }
    }

    return HSV(hue: hue,
               saturation: maximum == 0 ? 0 : delta / maximum,
               value: maximum)
}

func hsvToRGB(_ color: HSV) -> RGB {
    let hue = (color.hue - floor(color.hue)) * 6.0
    let sector = Int(floor(hue)) % 6
    let fraction = hue - floor(hue)
    let p = color.value * (1.0 - color.saturation)
    let q = color.value * (1.0 - fraction * color.saturation)
    let t = color.value * (1.0 - (1.0 - fraction) * color.saturation)

    switch sector {
    case 0: return RGB(red: color.value, green: t, blue: p)
    case 1: return RGB(red: q, green: color.value, blue: p)
    case 2: return RGB(red: p, green: color.value, blue: t)
    case 3: return RGB(red: p, green: q, blue: color.value)
    case 4: return RGB(red: t, green: p, blue: color.value)
    default: return RGB(red: color.value, green: p, blue: q)
    }
}

func hueDistance(_ lhs: Double, _ rhs: Double) -> Double {
    let distance = abs(lhs - rhs)
    return min(distance, 1.0 - distance)
}

func loadImage(at url: URL) throws -> CGImage {
    guard let source = CGImageSourceCreateWithURL(url as CFURL, nil),
          let image = CGImageSourceCreateImageAtIndex(source, 0, nil) else {
        throw NSError(domain: "AppIconGenerator", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "Cannot read \(url.path)"])
    }
    return image
}

func writePNG(_ image: CGImage, to url: URL) throws {
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL,
                                                             UTType.png.identifier as CFString,
                                                             1,
                                                             nil) else {
        throw NSError(domain: "AppIconGenerator", code: 2,
                      userInfo: [NSLocalizedDescriptionKey: "Cannot create \(url.path)"])
    }
    CGImageDestinationAddImage(destination, image, nil)
    guard CGImageDestinationFinalize(destination) else {
        throw NSError(domain: "AppIconGenerator", code: 3,
                      userInfo: [NSLocalizedDescriptionKey: "Cannot write \(url.path)"])
    }
}

func bitmapImage(width: Int, height: Int, drawing: (CGContext) -> Void) throws -> CGImage {
    guard let context = CGContext(data: nil,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: 8,
                                  bytesPerRow: 0,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
        throw NSError(domain: "AppIconGenerator", code: 4,
                      userInfo: [NSLocalizedDescriptionKey: "Cannot create bitmap context"])
    }
    context.interpolationQuality = .high
    drawing(context)
    guard let image = context.makeImage() else {
        throw NSError(domain: "AppIconGenerator", code: 5,
                      userInfo: [NSLocalizedDescriptionKey: "Cannot render bitmap"])
    }
    return image
}

func resized(_ image: CGImage, size: Int) throws -> CGImage {
    try bitmapImage(width: size, height: size) { context in
        context.draw(image, in: CGRect(x: 0, y: 0, width: size, height: size))
    }
}

func insetImage(_ image: CGImage, size: Int, scale: CGFloat, background: RGB) throws -> CGImage {
    try bitmapImage(width: size, height: size) { context in
        context.setFillColor(CGColor(red: background.red, green: background.green, blue: background.blue, alpha: 1))
        context.fill(CGRect(x: 0, y: 0, width: size, height: size))
        let side = CGFloat(size) * scale
        let origin = (CGFloat(size) - side) / 2.0
        context.draw(image, in: CGRect(x: origin, y: origin, width: side, height: side))
    }
}

func recolored(_ image: CGImage, palette: [RGB]) throws -> CGImage {
    let width = image.width
    let height = image.height
    let bytesPerRow = width * 4
    var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)

    guard let context = CGContext(data: &pixels,
                                  width: width,
                                  height: height,
                                  bitsPerComponent: 8,
                                  bytesPerRow: bytesPerRow,
                                  space: CGColorSpaceCreateDeviceRGB(),
                                  bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue) else {
        throw NSError(domain: "AppIconGenerator", code: 6,
                      userInfo: [NSLocalizedDescriptionKey: "Cannot read image pixels"])
    }
    context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

    let sourceHues = [0.0, 0.52, 0.45, 0.12]
    let targetHSV = palette.map(rgbToHSV)

    for index in stride(from: 0, to: pixels.count, by: 4) {
        let alpha = Double(pixels[index + 3]) / 255.0
        if alpha < 0.01 { continue }

        let source = RGB(red: Double(pixels[index]) / 255.0,
                         green: Double(pixels[index + 1]) / 255.0,
                         blue: Double(pixels[index + 2]) / 255.0)
        let hsv = rgbToHSV(source)
        if hsv.value < 0.10 || hsv.saturation < 0.16 { continue }

        var paletteIndex = 0
        var nearest = Double.greatestFiniteMagnitude
        for candidate in sourceHues.indices {
            let distance = hueDistance(hsv.hue, sourceHues[candidate])
            if distance < nearest {
                nearest = distance
                paletteIndex = candidate
            }
        }

        let target = targetHSV[paletteIndex]
        let highlight = max(0.0, min(1.0, (hsv.value - 0.78) / 0.22))
        let saturation = max(0.0, min(1.0, target.saturation * (0.82 + hsv.saturation * 0.18) * (1.0 - highlight * 0.30)))
        let value = max(0.0, min(1.0, hsv.value * (0.92 + target.value * 0.12)))
        var output = hsvToRGB(HSV(hue: target.hue, saturation: saturation, value: value))

        if highlight > 0 {
            let whiteMix = highlight * 0.18
            output = RGB(red: output.red * (1.0 - whiteMix) + whiteMix,
                         green: output.green * (1.0 - whiteMix) + whiteMix,
                         blue: output.blue * (1.0 - whiteMix) + whiteMix)
        }

        pixels[index] = UInt8(max(0, min(255, Int(output.red * 255.0))))
        pixels[index + 1] = UInt8(max(0, min(255, Int(output.green * 255.0))))
        pixels[index + 2] = UInt8(max(0, min(255, Int(output.blue * 255.0))))
    }

    let data = Data(pixels) as CFData
    guard let provider = CGDataProvider(data: data),
          let output = CGImage(width: width,
                               height: height,
                               bitsPerComponent: 8,
                               bitsPerPixel: 32,
                               bytesPerRow: bytesPerRow,
                               space: CGColorSpaceCreateDeviceRGB(),
                               bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                               provider: provider,
                               decode: nil,
                               shouldInterpolate: true,
                               intent: .defaultIntent) else {
        throw NSError(domain: "AppIconGenerator", code: 7,
                      userInfo: [NSLocalizedDescriptionKey: "Cannot create recolored image"])
    }
    return output
}

let variants = [
    IconVariant(assetName: "AppIcon", palette: nil),
    IconVariant(assetName: "AppIconAdventure", palette: [rgb(0x36C96B), rgb(0x4EA2FF), rgb(0xA5E34A), rgb(0xFFD338)]),
    IconVariant(assetName: "AppIconCandy", palette: [rgb(0xFF6F9F), rgb(0x8ADCF7), rgb(0xFFC0DC), rgb(0xFFF0A6)]),
    IconVariant(assetName: "AppIconSunset", palette: [rgb(0xFF625C), rgb(0xFF4AA2), rgb(0xFF9B3D), rgb(0xFFD24A)]),
    IconVariant(assetName: "AppIconOcean", palette: [rgb(0x4A7DFF), rgb(0x35D6F2), rgb(0x3BE1B5), rgb(0xB7F5FF)]),
    IconVariant(assetName: "AppIconForest", palette: [rgb(0x3ECF74), rgb(0x5DA9E9), rgb(0x8DDB55), rgb(0xFFD65A)]),
    IconVariant(assetName: "AppIconSakura", palette: [rgb(0xFF83B6), rgb(0xBDA0FF), rgb(0xFFB5D1), rgb(0xFFF0F6)]),
    IconVariant(assetName: "AppIconCyber", palette: [rgb(0xFF2B9A), rgb(0x00E5FF), rgb(0x8B5CF6), rgb(0xD7FF38)]),
    IconVariant(assetName: "AppIconRoyal", palette: [rgb(0xE83F4E), rgb(0x4169E1), rgb(0xF5E7C4), rgb(0xFFD35A)]),
    IconVariant(assetName: "AppIconPorcelain", palette: [rgb(0xD43B38), rgb(0x1E67C6), rgb(0x78B8EF), rgb(0xF4EBD0)]),
    IconVariant(assetName: "AppIconCelestial", palette: [rgb(0x7A5CFF), rgb(0x2EA8FF), rgb(0x39D2C0), rgb(0xF4C65D)]),
    IconVariant(assetName: "AppIconNoir", palette: [rgb(0x8F183D), rgb(0xB9C2D0), rgb(0x363B46), rgb(0xD98CA3)]),
    IconVariant(assetName: "AppIconPrism", palette: [rgb(0xFF3E88), rgb(0x20D8F0), rgb(0x8B5CF6), rgb(0xFFE34D)]),
    IconVariant(assetName: "AppIconAtelier", palette: [rgb(0xDB6D57), rgb(0x5C9FB8), rgb(0x7FA083), rgb(0xE7D8BD)]),
]

func androidResourceName(for assetName: String) -> String {
    switch assetName {
    case "AppIconAdventure": return "ic_launcher_adventure"
    case "AppIconCandy": return "ic_launcher_candy"
    case "AppIconSunset": return "ic_launcher_sunset"
    case "AppIconOcean": return "ic_launcher_ocean"
    case "AppIconForest": return "ic_launcher_forest"
    case "AppIconSakura": return "ic_launcher_sakura"
    case "AppIconCyber": return "ic_launcher_cyber"
    case "AppIconRoyal": return "ic_launcher_royal"
    case "AppIconPorcelain": return "ic_launcher_porcelain"
    case "AppIconCelestial": return "ic_launcher_celestial"
    case "AppIconNoir": return "ic_launcher_noir"
    case "AppIconPrism": return "ic_launcher_prism"
    case "AppIconAtelier": return "ic_launcher_atelier"
    default: return "ic_launcher"
    }
}

let outputSpecifications: [(String, Int)] = [
    ("icon-20@2x.png", 40), ("icon-20@3x.png", 60),
    ("icon-29@2x.png", 58), ("icon-29@3x.png", 87),
    ("icon-38@2x.png", 76), ("icon-38@3x.png", 114),
    ("icon-40@2x.png", 80), ("icon-40@3x.png", 120),
    ("icon-60@2x.png", 120), ("icon-60@3x.png", 180),
    ("icon-64@2x.png", 128), ("icon-64@3x.png", 192),
    ("icon-68@2x.png", 136), ("icon-76@2x.png", 152),
    ("icon-83.5@2x.png", 167), ("icon-1024.png", 1024),
]

let contentsImages: [[String: String]] = [
    ["size": "20x20", "idiom": "universal", "filename": "icon-20@2x.png", "scale": "2x", "platform": "ios"],
    ["size": "20x20", "idiom": "universal", "filename": "icon-20@3x.png", "scale": "3x", "platform": "ios"],
    ["size": "29x29", "idiom": "universal", "filename": "icon-29@2x.png", "scale": "2x", "platform": "ios"],
    ["size": "29x29", "idiom": "universal", "filename": "icon-29@3x.png", "scale": "3x", "platform": "ios"],
    ["size": "38x38", "idiom": "universal", "filename": "icon-38@2x.png", "scale": "2x", "platform": "ios"],
    ["size": "38x38", "idiom": "universal", "filename": "icon-38@3x.png", "scale": "3x", "platform": "ios"],
    ["size": "40x40", "idiom": "universal", "filename": "icon-40@2x.png", "scale": "2x", "platform": "ios"],
    ["size": "40x40", "idiom": "universal", "filename": "icon-40@3x.png", "scale": "3x", "platform": "ios"],
    ["size": "60x60", "idiom": "universal", "filename": "icon-60@2x.png", "scale": "2x", "platform": "ios"],
    ["size": "60x60", "idiom": "universal", "filename": "icon-60@3x.png", "scale": "3x", "platform": "ios"],
    ["size": "64x64", "idiom": "universal", "filename": "icon-64@2x.png", "scale": "2x", "platform": "ios"],
    ["size": "64x64", "idiom": "universal", "filename": "icon-64@3x.png", "scale": "3x", "platform": "ios"],
    ["size": "68x68", "idiom": "universal", "filename": "icon-68@2x.png", "scale": "2x", "platform": "ios"],
    ["size": "76x76", "idiom": "universal", "filename": "icon-76@2x.png", "scale": "2x", "platform": "ios"],
    ["size": "83.5x83.5", "idiom": "universal", "filename": "icon-83.5@2x.png", "scale": "2x", "platform": "ios"],
    ["size": "1024x1024", "idiom": "universal", "filename": "icon-1024.png", "scale": "1x", "platform": "ios"],
]

guard CommandLine.arguments.count >= 3 else {
    fputs("Usage: generate-app-icons.swift <master.png> <Assets.xcassets> [android-res]\n", stderr)
    exit(64)
}

let fileManager = FileManager.default
let masterURL = URL(fileURLWithPath: CommandLine.arguments[1])
let assetsURL = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
let master = try loadImage(at: masterURL)

for variant in variants {
    let image = try variant.palette.map { try recolored(master, palette: $0) } ?? master
    let setURL = assetsURL.appendingPathComponent("\(variant.assetName).appiconset", isDirectory: true)
    try fileManager.createDirectory(at: setURL, withIntermediateDirectories: true)

    for (filename, size) in outputSpecifications {
        try writePNG(try resized(image, size: size), to: setURL.appendingPathComponent(filename))
    }

    let contents: [String: Any] = [
        "images": contentsImages,
        "info": ["author": "一桌好戏", "version": 1],
    ]
    let contentsData = try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys])
    try contentsData.write(to: setURL.appendingPathComponent("Contents.json"), options: .atomic)
}

if CommandLine.arguments.count >= 4 {
    let androidURL = URL(fileURLWithPath: CommandLine.arguments[3], isDirectory: true)
    let androidSizes = [("mdpi", 48), ("hdpi", 72), ("xhdpi", 96), ("xxhdpi", 144), ("xxxhdpi", 192)]
    let foregroundDirectory = androidURL.appendingPathComponent("drawable-nodpi", isDirectory: true)
    try fileManager.createDirectory(at: foregroundDirectory, withIntermediateDirectories: true)
    let adaptiveDirectory = androidURL.appendingPathComponent("mipmap-anydpi-v26", isDirectory: true)
    try fileManager.createDirectory(at: adaptiveDirectory, withIntermediateDirectories: true)

    for variant in variants {
        let image = try variant.palette.map { try recolored(master, palette: $0) } ?? master
        let resourceName = androidResourceName(for: variant.assetName)

        for (density, size) in androidSizes {
            let directory = androidURL.appendingPathComponent("mipmap-\(density)", isDirectory: true)
            try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            let icon = try resized(image, size: size)
            try writePNG(icon, to: directory.appendingPathComponent("\(resourceName).png"))
            try writePNG(icon, to: directory.appendingPathComponent("\(resourceName)_round.png"))
        }

        let foregroundName = "\(resourceName)_foreground"
        let foreground = try insetImage(image, size: 432, scale: 0.72, background: rgb(0x07090C))
        try writePNG(foreground, to: foregroundDirectory.appendingPathComponent("\(foregroundName).png"))

        let adaptiveXML = """
        <?xml version="1.0" encoding="utf-8"?>
        <adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
            <background android:drawable="@color/launcher_icon_background" />
            <foreground android:drawable="@drawable/\(foregroundName)" />
        </adaptive-icon>
        """
        try adaptiveXML.data(using: .utf8)!.write(
            to: adaptiveDirectory.appendingPathComponent("\(resourceName).xml"),
            options: .atomic
        )
        try adaptiveXML.data(using: .utf8)!.write(
            to: adaptiveDirectory.appendingPathComponent("\(resourceName)_round.xml"),
            options: .atomic
        )
    }
}

print("Generated \(variants.count) iOS icon sets and Android launcher variants from \(masterURL.lastPathComponent)")
