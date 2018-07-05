//
//  DetailViewController.swift
//  Wallpaper
//
//  Created by Jeffrey Rosenbluth on 5/25/18.
//  Copyright © 2018 Applause Code. All rights reserved.
//

import Cocoa

class DetailViewController: NSViewController {
    @IBOutlet var imageView: NSImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
    }
    
    func imageSelected(name: String) {
        imageView.image = NSImage(named: NSImage.Name(name))
    }

    
    
}
