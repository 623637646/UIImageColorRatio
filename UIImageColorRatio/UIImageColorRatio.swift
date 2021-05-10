//
//  UIImageColorRatio.swift
//  UIImageColorRatio
//
//  Created by Yanni Wang on 4/5/21.
//

import UIKit

extension UIImage {
    
    public struct ColorRatioResult {
        public let colorRatioArray: [(color: UIColor, ratio: Float)]
        public let duration: TimeInterval // second
        public let deviation: UInt8
    }
    
    private struct Color: Hashable {
        let r: UInt8
        let g: UInt8
        let b: UInt8
        
        func isSimilar(another: Color, deviation: UInt8) -> Bool {
            return
                max(self.r, another.r) - min(self.r, another.r) <= deviation &&
                max(self.g, another.g) - min(self.g, another.g) <= deviation &&
                max(self.b, another.b) - min(self.b, another.b) <= deviation
        }
    }
    
    // deviation: The deviation on pixels, It's from 0 to 255. Bigger deviation means less kind of colors.
    public func calculateColorRatio(deviation: UInt8) -> ColorRatioResult? {
        let startTime = Date()
        // TODO: test the releasing.
        guard let pixelData = self.cgImage?.dataProvider?.data,
              let data = CFDataGetBytePtr(pixelData) else {
            return nil
        }
        let length: Int = CFDataGetLength(pixelData)
        var dic = [Color: UInt]()
        let totalCount = length / 4
        // Refer to: https://stackoverflow.com/a/40237504/9315497
        for index in 0 ... (totalCount - 1) {
            let r = data[index * 4]
            let g = data[index * 4 + 1]
            let b = data[index * 4 + 2]
            let color = Color.init(r: r, g: g, b: b)
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
            return (color: UIColor.init(red: CGFloat(color.r) / 255.0, green: CGFloat(color.g) / 255.0, blue: CGFloat(color.b) / 255.0, alpha: 1), ratio: Float(count) / Float(totalCount))
        }
        let endTime = Date()
        return ColorRatioResult.init(colorRatioArray: colorRatioArray, duration: endTime.timeIntervalSince(startTime), deviation: deviation)
    }
    
    public func image(colorRatioResult: ColorRatioResult) -> UIImage? {
        guard let cgImage = self.cgImage,
              let colorSpace = cgImage.colorSpace,
              let pixelData = cgImage.dataProvider?.data else {
            return nil
        }
        let length = CFDataGetLength(pixelData)
        guard let newPixelData = CFDataCreateMutableCopy(kCFAllocatorDefault, length, pixelData),
              let data = CFDataGetMutableBytePtr(newPixelData),
              let dataProvider = CGDataProvider.init(data: newPixelData) else {
            return nil
        }
        let colorRatioArray = colorRatioResult.colorRatioArray.map({ (color: UIColor, ratio: Float) -> (color: Color, ratio: Float) in
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: nil)
            let color = Color.init(r: UInt8(r * 255), g: UInt8(g * 255), b: UInt8(b * 255))
            return (color: color, ratio: ratio)
        })
        for index in 0 ... (length / 4 - 1) {
            let r = data[index * 4]
            let g = data[index * 4 + 1]
            let b = data[index * 4 + 2]
            let color = Color.init(r: r, g: g, b: b)
            for item in colorRatioArray {
                if item.color.isSimilar(another: color, deviation: colorRatioResult.deviation) {
                    data[index * 4] = item.color.r
                    data[index * 4 + 1] = item.color.g
                    data[index * 4 + 2] = item.color.b
                    break
                }
            }
        }
        guard let newCGImage = CGImage.init(width: cgImage.width, height: cgImage.height, bitsPerComponent: cgImage.bitsPerComponent, bitsPerPixel: cgImage.bitsPerPixel, bytesPerRow: cgImage.bytesPerRow, space: colorSpace, bitmapInfo: cgImage.bitmapInfo, provider: dataProvider, decode: cgImage.decode, shouldInterpolate: cgImage.shouldInterpolate, intent: cgImage.renderingIntent) else {
            return nil
        }
        return UIImage.init(cgImage: newCGImage)
    }
    
}
