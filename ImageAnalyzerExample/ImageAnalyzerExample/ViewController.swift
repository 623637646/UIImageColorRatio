//
//  ViewController.swift
//  ImageAnalyzerExample
//
//  Created by Yanni Wang on 4/5/21.
//

import UIKit
import Eureka
import ViewRow
import ImageAnalyzer
import MBProgressHUD
import ZLPhotoBrowser

let maxOffset: UInt = 50

class ViewController: FormViewController {
    
    var originalImage = UIImage(named: "bird")!
    
    lazy var renderedImage = originalImage
    
    var analysisResult = [(color: Color, rate: Float)]()
    
    var durationForRenderingImage: Double = 0
    
    var durationForAnalysis: Double = 0
    
    var offset: UInt8 = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reload()
        analyze()
    }
    
    func analyze() {
        let HUD = MBProgressHUD.showAdded(to: self.view, animated: true)
        DispatchQueue.global().async {
            let time1 = Date()
            self.analysisResult = self.originalImage.analyze(offset: self.offset)
            let time2 = Date()
            self.updateRenderedImage()
            let time3 = Date()
            self.durationForAnalysis = time2.timeIntervalSince(time1)
            self.durationForRenderingImage = time3.timeIntervalSince(time2)
            DispatchQueue.main.async {
                HUD.hide(animated: true)
                self.reload()
            }
        }
    }
    
    func reload() {
        UIView.performWithoutAnimation {
            let offset = self.tableView.contentOffset
            form.removeAll()
            form +++ Section("Original image")
                <<< getImageRow(image: originalImage).onCellSelection({ (_, _) in
                    let ps = ZLPhotoPreviewSheet()
                    ps.selectImageBlock = { [weak self] (images, assets, isOriginal) in
                        guard let self = self,
                              images.count == 1,
                              let image = images.first else {
                            return
                        }
                        DispatchQueue.main.async {
                            self.originalImage = image
                            self.reload()
                            self.analyze()
                        }
                    }
                    ps.showPhotoLibrary(sender: self)
                })
                +++ Section("Image after applying offset")
                <<< getImageRow(image: renderedImage)
                +++ Section("Analysis")
                <<< SliderRow(){ row in
                    row.title = "Set offset"
                    row.value = Float(self.offset)
                    row.steps = maxOffset
                    row.displayValueFor = {
                        guard let value = $0 else {
                            return ""
                        }
                        return "\(UInt(value))"
                    }
                    row.cellSetup { cell, row in
                        cell.slider.minimumValue = 0
                        cell.slider.maximumValue = Float(maxOffset)
                        cell.slider.addTarget(self, action: #selector(self.changeOffset(slider:)), for: [.touchUpInside, .touchUpOutside])
                    }
                }
                <<< LabelRow(){
                    $0.title = "Offset"
                    $0.value = String(self.offset)
                }
                <<< LabelRow(){
                    $0.title = "Number of colors"
                    $0.value = String(analysisResult.count)
                    $0.cellSetup { (cell, _) in
                        cell.detailTextLabel?.textColor = .red
                    }
                }
                <<< LabelRow(){
                    $0.title = "Duration for analysis"
                    $0.value = "\(Int(durationForAnalysis * 1000))ms"
                    $0.cellSetup { (cell, _) in
                        cell.detailTextLabel?.textColor = .red
                    }
                }
                <<< LabelRow(){
                    $0.title = "Duration for rendering"
                    $0.value = "\(Int(durationForRenderingImage * 1000))ms"
                }
                +++ Section("Top 10 colors") {
                    guard self.analysisResult.count > 0 else {
                        return
                    }
                    for index in 0 ... min(10 - 1, self.analysisResult.count - 1) {
                        let data = self.analysisResult[index]
                        let color = UIColor.init(red: CGFloat(data.color.r) / 255, green: CGFloat(data.color.g) / 255, blue: CGFloat(data.color.b) / 255, alpha: 1)
                        $0 <<< LabelRow(){
                            $0.title = color.hexString
                            $0.value = String.init(format: "%0.2f%%", data.rate * 100)
                        }.cellUpdate({ (cell, row) in
                            cell.backgroundColor = color
                            cell.textLabel?.textColor = color.inverseColor()
                            cell.detailTextLabel?.textColor = color.inverseColor()
                        })
                    }
                }
            self.tableView.contentOffset = offset
        }
    }
    
    func getImageRow(image: UIImage) -> ViewRow<UIImageView> {
        return ViewRow<UIImageView>()
            .cellSetup { (cell, row) in
                let imageView = UIImageView()
                imageView.contentMode = .scaleAspectFit
                imageView.image = image
                
                cell.view = imageView
                cell.contentView.addSubview(cell.view!)
                
                cell.viewRightMargin = 0.0
                cell.viewLeftMargin = 0.0
                cell.viewTopMargin = 8.0
                cell.viewBottomMargin = 8.0
                cell.height = { return CGFloat(200) }
            }
    }
    
    @objc private func changeOffset(slider: UISlider) {
        let value = slider.value
        self.offset = UInt8(value)
        self.reload()
        self.analyze()
    }
    
    func updateRenderedImage() {
        guard let cgImage = self.originalImage.cgImage,
              let colorSpace = cgImage.colorSpace,
              let pixelData = cgImage.dataProvider?.data else {
            assert(false)
            return
        }
        let length = CFDataGetLength(pixelData)
        guard let newPixelData = CFDataCreateMutableCopy(kCFAllocatorDefault, length, pixelData),
              let data = CFDataGetMutableBytePtr(newPixelData) else {
            assert(false)
            return
        }
        for index in 0 ... (length / 4 - 1) {
            let r = data[index * 4]
            let g = data[index * 4 + 1]
            let b = data[index * 4 + 2]
            let color = Color.init(r: r, g: g, b: b)
            for item in self.analysisResult {
                if item.color.isSimilar(another: color, offset: self.offset) {
                    data[index * 4] = item.color.r
                    data[index * 4 + 1] = item.color.g
                    data[index * 4 + 2] = item.color.b
                    break
                }
            }
        }
        
        guard let dataProvider = CGDataProvider.init(data: newPixelData) else {
            assert(false)
            return
        }
        guard let newCGImage = CGImage.init(width: cgImage.width, height: cgImage.height, bitsPerComponent: cgImage.bitsPerComponent, bitsPerPixel: cgImage.bitsPerPixel, bytesPerRow: cgImage.bytesPerRow, space: colorSpace, bitmapInfo: cgImage.bitmapInfo, provider: dataProvider, decode: cgImage.decode, shouldInterpolate: cgImage.shouldInterpolate, intent: cgImage.renderingIntent) else {
            assert(false)
            return
        }
        self.renderedImage = UIImage.init(cgImage: newCGImage)
    }
    
}

extension UIColor {
    
    func inverseColor() -> UIColor {
        return (self.isLight() ?? false) ? .black : .white
    }
    
    // https://stackoverflow.com/a/29044899/9315497
    func isLight(threshold: Float = 0.5) -> Bool? {
        let originalCGColor = self.cgColor
        
        // Now we need to convert it to the RGB colorspace. UIColor.white / UIColor.black are greyscale and not RGB.
        // If you don't do this then you will crash when accessing components index 2 below when evaluating greyscale colors.
        let RGBCGColor = originalCGColor.converted(to: CGColorSpaceCreateDeviceRGB(), intent: .defaultIntent, options: nil)
        guard let components = RGBCGColor?.components else {
            return nil
        }
        guard components.count >= 3 else {
            return nil
        }
        
        let brightness = Float(((components[0] * 299) + (components[1] * 587) + (components[2] * 114)) / 1000)
        return (brightness > threshold)
    }
    
    var hexString: String? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        let multiplier = CGFloat(255.999999)
        
        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }
        
        if alpha == 1.0 {
            return String(
                format: "#%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier)
            )
        }
        else {
            return String(
                format: "#%02lX%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier),
                Int(alpha * multiplier)
            )
        }
    }
}

