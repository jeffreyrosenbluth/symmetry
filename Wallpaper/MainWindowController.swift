//
//  MainWindowController.swift
//  Wallpaper
//
//  Created by Jeffrey Rosenbluth on 7/6/18.
//  Copyright © 2018 Applause Code. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController {

    override func windowDidLoad() {
        super.windowDidLoad()
        window?.appearance = NSAppearance(named: NSAppearance.Name.vibrantDark)
    }
}