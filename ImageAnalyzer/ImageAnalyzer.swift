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
    
    public init(r: UInt8, g: UInt8, b: UInt8) {
        self.r = r
        self.g = g
        self.b = b
    }
    
    public func isSimilar(another: Color, offset: UInt8) -> Bool {
        return
            max(self.r, another.r) - min(self.r, another.r) <= offset &&
            max(self.g, another.g) - min(self.g, another.g) <= offset &&
            max(self.b, another.b) - min(self.b, another.b) <= offset
    }
}

extension UIImage {
    
    // offset: The degree of compression. More offset means less kind of colors.
    // Refer to: https://stackoverflow.com/a/40237504/9315497
    public func analyze(offset: UInt8 = 0) -> [(color: Color, rate: Float)] {
        
        // TODO: test the releasing.
        guard let pixelData = self.cgImage?.dataProvider?.data,
              let data = CFDataGetBytePtr(pixelData) else {
            return []
        }
        let length: Int = CFDataGetLength(pixelData)
        var dic = [Color: UInt64]()
        var totalCount = 0
        for index in 0 ... (length / 4 - 1) {
            let r = data[index * 4]
            let g = data[index * 4 + 1]
            let b = data[index * 4 + 2]
            let color = Color.init(r: r, g: g, b: b)
            dic[color] = (dic[color] ?? 0) + 1
            totalCount += 1
        }
        let array = dic.map { (color: $0, rate: Float($1) / Float(totalCount)) }.sorted { $0.rate > $1.rate }
        var result = [(color: Color, rate: Float)]()
        for item in array {
            var similarItemIndex: Int? = nil
            for (index, one) in result.enumerated() {
                if one.color.isSimilar(another: item.color, offset: offset) {
                    similarItemIndex = index
                    break
                }
            }
            if let similarItemIndex = similarItemIndex {
                result[similarItemIndex].rate += item.rate
            } else {
                result.append(item)
            }
        }
        result.sort(by: { $0.rate > $1.rate })
        return result
    }
    
}
