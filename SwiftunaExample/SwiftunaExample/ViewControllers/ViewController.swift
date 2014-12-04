//
//  ViewController.swift
//  SwiftunaExample
//
//  Created by Kevin on 03/12/14.
//  Copyright (c) 2014 Kevin Wong. All rights reserved.
//

import UIKit
import Swiftuna

private let kShowTableSegueIdentifier = "ShowTableSegue"

class ViewController: UIViewController, SwiftunaDelegate {

    @IBOutlet weak var compoundView: UIView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var label: UILabel!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        decorateViews()
    }
    
    //MARK: Private methods
    
    private func decorateViews() {
        
        let labelOptions = [
            SwiftunaOption(image: UIImage(named: "Search")!)
        ]
        
        let likeOptions = [
            SwiftunaOption(image: UIImage(named: "Up")!),
            SwiftunaOption(image: UIImage(named: "Down")!)
        ]
        
        let labelSwiftuna = Swiftuna(targetView: label, options: labelOptions)
        labelSwiftuna.backgroundViewColor = UIColor.whiteColor()
        labelSwiftuna.delegate = self
        labelSwiftuna.attach()
        
        Swiftuna(targetView: imageView, options: likeOptions).attach()
        
        let viewSwiftuna = Swiftuna(targetView: compoundView, options: likeOptions)
        viewSwiftuna.optionsSpacing = 20
        viewSwiftuna.backgroundViewColor = UIColor.whiteColor()
        viewSwiftuna.attach()
    }
    
    //MARK: SwiftunaDelegate
    
    func swiftuna(swiftuna: Swiftuna, didSelectOption option: SwiftunaOption, index: Int) {
        
        performSegueWithIdentifier(kShowTableSegueIdentifier, sender: nil)
    }

}

