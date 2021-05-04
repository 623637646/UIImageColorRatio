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
    public func analyze(compression: UInt8 = 1) -> [(color: Color, rate: Float)] {
        
        // TODO: test the releasing.
        guard let pixelData = self.cgImage?.dataProvider?.data else {
            return []
        }
        let length: Int = Int(CFDataGetLength(pixelData))
        let data: UnsafePointer<UInt8> = CFDataGetBytePtr(pixelData)
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
    
}
