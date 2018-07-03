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

    func makeWallpaper(_ image: NSImage, _ recipeFn: ([Coef]) -> Recipe) -> NSImage {
        let c0 = Coef(nCoord: 1, mCoord: 0, anm: Complex(0.75, 0.25))
        let c1 = Coef(nCoord: -2, mCoord: 2, anm: Complex(0.2, -0.2))
        let c2 = Coef(nCoord: 1, mCoord: -1, anm: Complex(0.6, 0.1))
        let opts = Options(width: 600, height: 480, repLength: 100, scale: 0.5, rotation: Double.pi/6)
        
        let paper = wallpaper(options: opts, recipeFn: recipeFn, coefs: [c0, c1, c2], preProcess: antiSymmVertical, nsImage: image)
        return paper
    }
    
}
