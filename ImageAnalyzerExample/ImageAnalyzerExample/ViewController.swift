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
import ProgressHUD

let maxCompression: UInt = 100

class ViewController: FormViewController {
    
    let originalImage = UIImage(named: "bird")!
    
    lazy var filteredImage = originalImage
    
    var analysisResult = [(color: Color, rate: Float)]()
    
    var durationForFilteringImage: Double = 0
    
    var durationForAnalysis: Double = 0
    
    var compression: UInt8 = 10
    
    override func viewDidLoad() {
        super.viewDidLoad()
        reload()
        analyze()
    }
    
    func analyze() {
        ProgressHUD.show()
        DispatchQueue.global().async {
            let time1 = Date()
            self.filteredImage = self.originalImage.image(compression: self.compression)!
            let time2 = Date()
            self.analysisResult = self.filteredImage.analyze(compression: 1)
            let time3 = Date()
            self.durationForFilteringImage = time2.timeIntervalSince(time1)
            self.durationForAnalysis = time3.timeIntervalSince(time2)
            DispatchQueue.main.async {
                ProgressHUD.dismiss()
                self.reload()
            }
        }
    }
    
    func reload() {
        UIView.performWithoutAnimation {
            form.removeAll()
            form +++ Section("Original image")
                <<< getImageRow(image: originalImage)
                +++ Section("Filtered image")
                <<< getImageRow(image: filteredImage)
                +++ Section("Analysis")
                <<< SliderRow(){ row in
                    row.title = "Compression"
                    row.value = Float(self.compression)
                    row.steps = maxCompression - 1
                    row.displayValueFor = {
                        guard let value = $0 else {
                            return ""
                        }
                        return "\(UInt(value))"
                    }
                    row.cellSetup { cell, row in
                        cell.slider.minimumValue = 1
                        cell.slider.maximumValue = 100
                        cell.slider.addTarget(self, action: #selector(self.changeCompression(slider:)), for: [.touchUpInside, .touchUpOutside])
                    }
                }
                <<< LabelRow(){
                    $0.title = "Compression"
                    $0.value = String(compression)
                }
                <<< LabelRow(){
                    $0.title = "Number of colors"
                    $0.value = String(analysisResult.count)
                }
                <<< LabelRow(){
                    $0.title = "Duration for filtering image"
                    $0.value = "\(Int(durationForFilteringImage * 1000))ms"
                }
                <<< LabelRow(){
                    $0.title = "Duration for analysis image"
                    $0.value = "\(Int(durationForAnalysis * 1000))ms"
                }
                +++ Section("Top 10 colors") {
                    guard self.analysisResult.count > 0 else {
                        return
                    }
                    for index in 0 ... min(10 - 1, self.analysisResult.count - 1) {
                        let data = self.analysisResult[index]
                        $0
                            <<< LabelRow(){
                                $0.value = String.init(format: "%0.2f%%", data.rate * 100)
                            }.cellUpdate({ (cell, row) in
                                cell.backgroundColor = UIColor.init(red: CGFloat(data.color.r) / 255, green: CGFloat(data.color.g) / 255, blue: CGFloat(data.color.b) / 255, alpha: 1)
                            })
                    }
                }
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
    
    @objc private func changeCompression(slider: UISlider) {
        let value = slider.value
        self.compression = UInt8(value)
        self.reload()
        self.analyze()
    }
    
}

