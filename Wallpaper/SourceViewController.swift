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
    @IBOutlet weak var wheel: NSImageView!
    
    @IBAction func press(_ sender: Any) {
        guard let url = NSOpenPanel().selectUrl else { return }
        guard let image = NSImage(contentsOf: url) else { return }
        wheel.image = image
    }
    
    @IBAction func pressRun(_ sender: Any) {
        guard let splitView = parent as? NSSplitViewController else {return}
        guard let detail = splitView.childViewControllers[1] as? DetailViewController else { return }
        guard let grp = group.titleOfSelectedItem else {return}
        if let img = wheel.image {
            detail.makeWallpaper(img, stringToRecipeFn(grp))
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}
