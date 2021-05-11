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

private let maxDeviation: UInt8 = 255

class ViewController: FormViewController {
    
    var originalImage = UIImage(named: "bird")!
    
    var renderedImage: UIImage?
    
    var colorRatioResult: ColorRatioResult?
    
    var durationForRenderingImage: Double?
    
    var deviation: UInt8 = 5
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reload()
        analyze()
    }
    
    func analyze() {
        let HUD = MBProgressHUD.showAdded(to: self.view, animated: true)
        DispatchQueue.global().async {
            self.colorRatioResult = self.originalImage.calculateColorRatio(deviation: self.deviation)
            if let colorRatioResult = self.colorRatioResult {
                let time1 = Date()
                self.renderedImage = self.originalImage.effectedImage(colorRatioResult: colorRatioResult)
                let time2 = Date()
                self.durationForRenderingImage = time2.timeIntervalSince(time1)
            } else {
                self.renderedImage = nil
                self.durationForRenderingImage = 0
            }
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
            if let renderedImage = self.renderedImage {
                form +++ Section("Effected image")
                    <<< getImageRow(image: renderedImage)
            }
            
            let analysisSection = Section("Analysis")
            
            form +++ analysisSection
                <<< SliderRow(){ row in
                    row.title = "Set deviation"
                    row.value = Float(self.deviation)
                    row.steps = UInt(maxDeviation)
                    row.displayValueFor = {
                        guard let value = $0 else {
                            return ""
                        }
                        return "\(UInt(value))"
                    }
                    row.cellSetup { cell, row in
                        cell.slider.minimumValue = 0
                        cell.slider.maximumValue = Float(maxDeviation)
                        cell.slider.addTarget(self, action: #selector(self.changeDeviation(slider:)), for: [.touchUpInside, .touchUpOutside])
                    }
                }
                <<< LabelRow(){
                    $0.title = "Deviation"
                    $0.value = String(self.deviation)
                }
            
            if let colorRatioResult = self.colorRatioResult,
               let durationForRenderingImage = self.durationForRenderingImage {
                let colorCount = colorRatioResult.colorRatioArray.count
                analysisSection <<< LabelRow(){
                    $0.title = "Number of colors"
                    $0.value = String(colorCount)
                    $0.cellSetup { (cell, _) in
                        cell.detailTextLabel?.textColor = .red
                    }
                }
                <<< LabelRow(){
                    $0.title = "Duration of calculation"
                    $0.value = "\(Int((colorRatioResult.duration) * 1000))ms"
                    $0.cellSetup { (cell, _) in
                        cell.detailTextLabel?.textColor = .red
                    }
                }
                <<< LabelRow(){
                    $0.title = "Duration for effected image"
                    $0.value = "\(Int(durationForRenderingImage * 1000))ms"
                }
                form +++ Section("Top 10 colors") {
                    guard colorCount > 0 else {
                        return
                    }
                    for index in 0 ... min(10 - 1, colorCount - 1) {
                        let colorRatio = colorRatioResult.colorRatioArray[index]
                        let color = colorRatio.color
                        $0 <<< LabelRow(){
                            $0.title = color.hexString
                            $0.value = String.init(format: "%0.2f%%", colorRatio.ratio * 100)
                        }.cellUpdate({ (cell, row) in
                            cell.backgroundColor = color
                            cell.textLabel?.textColor = color.inverseColor()
                            cell.detailTextLabel?.textColor = color.inverseColor()
                        })
                    }
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
    
    @objc private func changeDeviation(slider: UISlider) {
        let value = slider.value
        self.deviation = UInt8(value)
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
