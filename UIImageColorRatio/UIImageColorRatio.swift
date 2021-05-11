//
//  UIImageColorRatio.swift
//  UIImageColorRatio
//
//  Created by Yanni Wang on 4/5/21.
//

import UIKit

public struct ColorRatioResult {
    public let colorRatioArray: [(color: UIColor, ratio: Float)]
    public let duration: TimeInterval // second
    public let deviation: UInt8
}

struct Color: Hashable {
    let r: UInt8
    let g: UInt8
    let b: UInt8
    let a: UInt8
    
    func isSimilar(another: Color, deviation: UInt8) -> Bool {
        return
            max(self.r, another.r) - min(self.r, another.r) <= deviation &&
            max(self.g, another.g) - min(self.g, another.g) <= deviation &&
            max(self.b, another.b) - min(self.b, another.b) <= deviation &&
            max(self.a, another.a) - min(self.a, another.a) <= deviation
    }
}

extension UIImage {
    
    // deviation: The deviation on pixels, It's from 0 to 255. Bigger deviation means less kind of colors.
    public func calculateColorRatio(deviation: UInt8) -> ColorRatioResult? {
        let startTime = Date()
        guard let cgImage = self.cgImage,
              let context = cgImage.formalizedContext(),
              let ptr = context.data?.assumingMemoryBound(to: UInt8.self) else {
            return nil
        }
        var dic = [Color: UInt]()
        for index in 0 ... (cgImage.width * cgImage.height - 1) {
            let r = ptr[index * CGImage.bytesPerPixel]
            let g = ptr[index * CGImage.bytesPerPixel + 1]
            let b = ptr[index * CGImage.bytesPerPixel + 2]
            let a = ptr[index * CGImage.bytesPerPixel + 3]
            let color = Color.init(r: r, g: g, b: b, a: a)
            dic[color] = (dic[color] ?? 0) + 1
        }
        
        let array = dic.map { (color: $0, count: $1) }.sorted { $0.count > $1.count }
        var colorCountArray = [(color: Color, count: UInt)]()
        for item in array {
            var similarItemIndex: Int? = nil
            for (index, one) in colorCountArray.enumerated() {
                if one.color.isSimilar(another: item.color, deviation: deviation) {
                    similarItemIndex = index
                    break
                }
            }
            if let similarItemIndex = similarItemIndex {
                colorCountArray[similarItemIndex].count += item.count
            } else {
                colorCountArray.append(item)
            }
        }
        colorCountArray.sort(by: { $0.count > $1.count })  // need to sort again.
        let colorRatioArray = colorCountArray.map { (color: Color, count: UInt) -> (color: UIColor, ratio: Float) in
            return (color: UIColor.init(red: CGFloat(color.r) / 255.0,
                                        green: CGFloat(color.g) / 255.0,
                                        blue: CGFloat(color.b) / 255.0,
                                        alpha: CGFloat(color.a) / 255.0),
                    ratio: Float(count) / Float(cgImage.self.width * cgImage.self.height))
        }
        let endTime = Date()
        return ColorRatioResult.init(colorRatioArray: colorRatioArray, duration: endTime.timeIntervalSince(startTime), deviation: deviation)
    }
    
    // Refer to: https://stackoverflow.com/a/31661519/9315497
    public func effectedImage(colorRatioResult: ColorRatioResult) -> UIImage? {
        guard let cgImage = self.cgImage,
              let context = cgImage.formalizedContext(),
              let ptr = context.data?.assumingMemoryBound(to: UInt8.self) else {
            return nil
        }
        
        let colorRatioArray = colorRatioResult.colorRatioArray.map({ (color: UIColor, ratio: Float) -> (color: Color, ratio: Float) in
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            var a: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: &a)
            let color = Color.init(r: UInt8(r * 255), g: UInt8(g * 255), b: UInt8(b * 255), a: UInt8(a * 255))
            return (color: color, ratio: ratio)
        })
        
        for index in 0 ... (cgImage.width * cgImage.height - 1) {
            let r = ptr[index * CGImage.bytesPerPixel]
            let g = ptr[index * CGImage.bytesPerPixel + 1]
            let b = ptr[index * CGImage.bytesPerPixel + 2]
            let a = ptr[index * CGImage.bytesPerPixel + 3]
            let color = Color.init(r: r, g: g, b: b, a: a)
            for item in colorRatioArray {
                if item.color.isSimilar(another: color, deviation: colorRatioResult.deviation) {
                    ptr[index * CGImage.bytesPerPixel] = item.color.r
                    ptr[index * CGImage.bytesPerPixel + 1] = item.color.g
                    ptr[index * CGImage.bytesPerPixel + 2] = item.color.b
                    ptr[index * CGImage.bytesPerPixel + 3] = item.color.a
                    break
                }
            }
        }
        guard let outputCGImage = context.makeImage() else {
            return nil
        }
        return UIImage.init(cgImage: outputCGImage)
    }
    
}

// refer to: https://stackoverflow.com/a/48281568/9315497
extension CGImage {
    
    static let bytesPerPixel = 4
    static let bitsPerComponent = 8
    static let colorSpace = CGColorSpaceCreateDeviceRGB()
    static let bitmapInfo = CGImageAlphaInfo.premultipliedLast.rawValue | CGBitmapInfo.byteOrder32Big.rawValue
    
    func formalizedContext() -> CGContext? {
        guard let context = CGContext(data: nil, width: self.width, height: self.height, bitsPerComponent: CGImage.bitsPerComponent, bytesPerRow: CGImage.bytesPerPixel * self.width, space: CGImage.colorSpace, bitmapInfo: CGImage.bitmapInfo) else {
            return nil
        }
        context.draw(self, in: CGRect(x: 0, y: 0, width: self.width, height: self.height))
        return context
    }
    
}
