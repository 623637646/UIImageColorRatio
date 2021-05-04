//
//  ViewController.swift
//  ImageAnalyzerExample
//
//  Created by Yanni Wang on 4/5/21.
//

import UIKit
import Eureka
import ViewRow

class ViewController: FormViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        form +++ Section("Original image")
            <<< getImageRow(image: UIImage(named: "bird")!)
            +++ Section("Analyzed image")
            <<< getImageRow(image: UIImage(named: "bird")!)
            +++ Section("Config")
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

