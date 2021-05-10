//
//  UIImageColorRatio.swift
//  UIImageColorRatio
//
//  Created by Yanni Wang on 4/5/21.
//

import UIKit

extension UIImage {
    
    // TODO: rename to colorRatioResult?
    public struct AnalyzeResult {
        public let colorRatio: [(color: UIColor, rate: Float)]
        public let duration: TimeInterval // second
        public let offset: UInt8
    }
    
    private struct Color: Hashable {
        let r: UInt8
        let g: UInt8
        let b: UInt8
        
        func isSimilar(another: Color, offset: UInt8) -> Bool {
            return
                max(self.r, another.r) - min(self.r, another.r) <= offset &&
                max(self.g, another.g) - min(self.g, another.g) <= offset &&
                max(self.b, another.b) - min(self.b, another.b) <= offset
        }
    }
    
    // offset: The degree of compression. More offset means less kind of colors.
    // Refer to: https://stackoverflow.com/a/40237504/9315497
    public func analyze(offset: UInt8) -> AnalyzeResult? {
        let startTime = Date()
        // TODO: test the releasing.
        guard let pixelData = self.cgImage?.dataProvider?.data,
              let data = CFDataGetBytePtr(pixelData) else {
            return nil
        }
        let length: Int = CFDataGetLength(pixelData)
        var dic = [Color: UInt]()
        let totalCount = length / 4
        for index in 0 ... (totalCount - 1) {
            let r = data[index * 4]
            let g = data[index * 4 + 1]
            let b = data[index * 4 + 2]
            let color = Color.init(r: r, g: g, b: b)
            dic[color] = (dic[color] ?? 0) + 1
        }
        let array = dic.map { (color: $0, count: $1) }.sorted { $0.count > $1.count }
        var colorRatios = [(color: Color, count: UInt)]()
        for item in array {
            var similarItemIndex: Int? = nil
            for (index, one) in colorRatios.enumerated() {
                if one.color.isSimilar(another: item.color, offset: offset) {
                    similarItemIndex = index
                    break
                }
            }
            if let similarItemIndex = similarItemIndex {
                colorRatios[similarItemIndex].count += item.count
            } else {
                colorRatios.append(item)
            }
        }
        colorRatios.sort(by: { $0.count > $1.count })
        let resultcolorRatio = colorRatios.map { (color: Color, count: UInt) -> (UIColor, Float) in
            return (UIColor.init(red: CGFloat(color.r) / 255.0, green: CGFloat(color.g) / 255.0, blue: CGFloat(color.b) / 255.0, alpha: 1), Float(count) / Float(totalCount))
        }
        let endTime = Date()
        return AnalyzeResult.init(colorRatio: resultcolorRatio, duration: endTime.timeIntervalSince(startTime), offset: offset)
    }
    
    public func image(analyzeResult: AnalyzeResult) -> UIImage? {
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
        let colorRatio = analyzeResult.colorRatio.map({ (color: UIColor, rate: Float) -> (color: Color, rate: Float) in
            var r: CGFloat = 0
            var g: CGFloat = 0
            var b: CGFloat = 0
            color.getRed(&r, green: &g, blue: &b, alpha: nil)
            let color = Color.init(r: UInt8(r * 255), g: UInt8(g * 255), b: UInt8(b * 255))
            return (color: color, rate: rate)
        })
        for index in 0 ... (length / 4 - 1) {
            let r = data[index * 4]
            let g = data[index * 4 + 1]
            let b = data[index * 4 + 2]
            let color = Color.init(r: r, g: g, b: b)
            for item in colorRatio {
                if item.color.isSimilar(another: color, offset: analyzeResult.offset) {
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
