//
//  Utilities.swift
//  Wallpaper
//
//  Created by Jeffrey Rosenbluth on 6/6/18.
//  Copyright © 2018 Applause Code. All rights reserved.
//

import Foundation
import Cocoa

extension NSOpenPanel {
    var selectUrl: URL? {
        title = "Select Image"
        allowsMultipleSelection = false
        canChooseDirectories = false
        canChooseFiles = true
        canCreateDirectories = false
        allowedFileTypes = ["jpg","png","pdf","pct", "bmp", "tiff"]
        return runModal() == .OK ? urls.first : nil
    }
    var selectUrls: [URL]? {
        title = "Select Images"
        allowsMultipleSelection = true
        canChooseDirectories = false
        canChooseFiles = true
        canCreateDirectories = false
        allowedFileTypes = ["jpg","png","pdf","pct", "bmp", "tiff"]  
        return runModal() == .OK ? urls : nil
    }
}
