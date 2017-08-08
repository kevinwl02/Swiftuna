//
//  TableViewController.swift
//  SwiftunaExample
//
//  Created by Kevin on 03/12/14.
//  Copyright (c) 2014 Kevin Wong. All rights reserved.
//

import UIKit
import Swiftuna

private let kExampleCellIdentifier = "ExampleCell"

class TableViewController: UITableViewController {

    //MARK: UITableViewDelegate
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return 5
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        
        return 1
    }
    
    //MARK: UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: kExampleCellIdentifier) as! ExampleCell
        
        cell.exampleTitleLabel.text = String(format: "Title for item number %d", indexPath.row)
        cell.exampleDescriptionLabel.text = String(format: "Description for item number %d", indexPath.row)
        decorateCell(cell)
        
        return cell
    }
    
    //MARK: Private methods
    
    fileprivate func decorateCell(_ cell : UITableViewCell) {
        
        let options = [
            SwiftunaOption(image: UIImage(named: "Search")!),
            SwiftunaOption(image: UIImage(named: "Up")!),
            SwiftunaOption(image: UIImage(named: "Down")!)
        ]
        Swiftuna(targetView: cell, options: options).attach()
    }
}
