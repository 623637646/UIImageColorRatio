//
//  ImageAnalyzer.swift
//  ImageAnalyzer
//
//  Created by Yanni Wang on 4/5/21.
//

import UIKit

public struct Color: Hashable {
    public let r: UInt8
    public let g: UInt8
    public let b: UInt8
}

extension UIImage {
    
    // compression: The degree of compression. More compression means less kind of colors.
    // Refer to: https://stackoverflow.com/a/40237504/9315497
    public func analyze(compression: UInt8 = 1) -> [(color: Color, rate: Float)] {
        
        // TODO: test the releasing.
        guard let pixelData = self.cgImage?.dataProvider?.data,
              let data = CFDataGetBytePtr(pixelData) else {
            return []
        }
        let length: Int = CFDataGetLength(pixelData)
        var dic = [Color: UInt64]()
        var totalCount = 0
        for index in 0 ... (length / 4 - 1) {
            let r = data[index * 4] / compression * compression
            let g = data[index * 4 + 1] / compression * compression
            let b = data[index * 4 + 2] / compression * compression
            let color = Color.init(r: r, g: g, b: b)
            dic[color] = (dic[color] ?? 0) + 1
            totalCount += 1
        }
        let result = dic.map { (color: $0, rate: Float($1) / Float(totalCount)) }.sorted { $0.rate > $1.rate }
        return result
    }
    
    // compression: The degree of compression. More compression means less kind of colors.
    public func image(compression: UInt8 = 1) -> UIImage? {
        guard let cgImage = self.cgImage,
              let colorSpace = cgImage.colorSpace,
              let pixelData = cgImage.dataProvider?.data else {
            return nil
        }
        let length = CFDataGetLength(pixelData)
        guard let newPixelData = CFDataCreateMutableCopy(kCFAllocatorDefault, length, pixelData),
              let data = CFDataGetMutableBytePtr(newPixelData) else {
            return nil
        }
        for index in 0 ... (length / 4 - 1) {
            data[index * 4] = data[index * 4] / compression * compression
            data[index * 4 + 1] = data[index * 4 + 1] / compression * compression
            data[index * 4 + 2] = data[index * 4 + 2] / compression * compression
        }
        
        guard let dataProvider = CGDataProvider.init(data: newPixelData) else {
            return nil
        }
        guard let newCGImage = CGImage.init(width: cgImage.width, height: cgImage.height, bitsPerComponent: cgImage.bitsPerComponent, bitsPerPixel: cgImage.bitsPerPixel, bytesPerRow: cgImage.bytesPerRow, space: colorSpace, bitmapInfo: cgImage.bitmapInfo, provider: dataProvider, decode: cgImage.decode, shouldInterpolate: cgImage.shouldInterpolate, intent: cgImage.renderingIntent) else {
            return nil
        }
        return UIImage.init(cgImage: newCGImage)
    }
    
}
