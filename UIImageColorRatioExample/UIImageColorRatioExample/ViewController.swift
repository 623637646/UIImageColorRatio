//
//  ViewController.swift
//  UIImageColorRatioExample
//
//  Created by Yanni Wang on 10/5/21.
//

import UIKit
import Eureka
import ViewRow
import UIImageColorRatio
import MBProgressHUD
import ZLPhotoBrowser

let maxOffset: UInt8 = 255

class ViewController: FormViewController {
    
    var originalImage = UIImage(named: "bird")!
    
    var renderedImage: UIImage?
    
    var analysisResult: UIImage.AnalyzeResult?
    
    var durationForRenderingImage: Double = 0
        
    var offset: UInt8 = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reload()
        analyze()
    }
    
    func analyze() {
        let HUD = MBProgressHUD.showAdded(to: self.view, animated: true)
        DispatchQueue.global().async {
            self.analysisResult = self.originalImage.analyze(offset: self.offset)
            let time1 = Date()
            self.renderedImage = self.originalImage.image(analyzeResult: self.analysisResult!)
            let time2 = Date()
            self.durationForRenderingImage = time2.timeIntervalSince(time1)
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
                <<< getImageRow(image: renderedImage ?? originalImage)
                +++ Section("Analysis")
                <<< SliderRow(){ row in
                    row.title = "Set offset"
                    row.value = Float(self.offset)
                    row.steps = UInt(maxOffset)
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
                    $0.value = String(analysisResult?.colorRatio.count ?? 0)
                    $0.cellSetup { (cell, _) in
                        cell.detailTextLabel?.textColor = .red
                    }
                }
                <<< LabelRow(){
                    $0.title = "Duration for analysis"
                    $0.value = "\(Int((analysisResult?.duration ?? 0) * 1000))ms"
                    $0.cellSetup { (cell, _) in
                        cell.detailTextLabel?.textColor = .red
                    }
                }
                <<< LabelRow(){
                    $0.title = "Duration for rendering"
                    $0.value = "\(Int(durationForRenderingImage * 1000))ms"
                }
                +++ Section("Top 10 colors") {
                    guard let analysisResult = self.analysisResult,
                        analysisResult.colorRatio.count > 0 else {
                        return
                    }
                    for index in 0 ... min(10 - 1, analysisResult.colorRatio.count - 1) {
                        let colorRate = analysisResult.colorRatio[index]
                        let color = colorRate.color
                        $0 <<< LabelRow(){
                            $0.title = color.hexString
                            $0.value = String.init(format: "%0.2f%%", colorRate.rate * 100)
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
