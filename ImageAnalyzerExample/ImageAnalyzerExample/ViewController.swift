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

class ViewController: FormViewController {
    
    let originalImage = UIImage(named: "bird")!
    
    var filteredImage = UIImage(named: "bird")!
    
    var analysisResult = [(color: Color, rate: Float)]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        form +++ Section("Original image")
            <<< getImageRow(image: originalImage)
            +++ Section("Filtered image")
            <<< getImageRow(image: filteredImage)
            +++ Section("Analysis")
            <<< LabelRow(){
                $0.title = "Number of colors"
                $0.value = String(analysisResult.count)
                $0.tag = "numberOfColors"
            }
            +++ Section("Top 10 colors") {
                $0.tag = "top10Colors"
            }
        
        analyze()
    }
    
    func analyze() {
        analysisResult = originalImage.analyze()
        reload()
    }
    
    func reload() {
        if let row = self.form.rowBy(tag: "numberOfColors") as? LabelRow {
            row.value = String(analysisResult.count)
        }
        if let top10ColorsSection = self.form.sectionBy(tag: "top10Colors") {
            top10ColorsSection.removeAll()
            for index in 0 ... min(10 - 1, analysisResult.count - 1) {
                let data = analysisResult[index]
                top10ColorsSection
                    <<< LabelRow(){
                        $0.value = String.init(format: "%0.2f%%", data.rate * 100)
                    }.cellUpdate({ (cell, row) in
                        cell.backgroundColor = UIColor.init(red: CGFloat(data.color.r) / 255, green: CGFloat(data.color.g) / 255, blue: CGFloat(data.color.b) / 255, alpha: 1)
                    })
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
    
}

