//
//  SourceViewController.swift
//  Wallpaper
//
//  Created by Jeffrey Rosenbluth on 5/25/18.
//  Copyright © 2018 Applause Code. All rights reserved.
//

import Cocoa

class SourceViewController: NSViewController {
    @IBOutlet weak var group: NSPopUpButton!
    
    @IBAction func press(_ sender: Any) {
        print(group.titleOfSelectedItem!)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}
