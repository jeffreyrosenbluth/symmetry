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

extension NSBitmapImageRep {
    func writeImageRep(toURL url: URL, filetype: FileType) {
        let imgData = self.representation(using: filetype, properties: [.compressionFactor : NSNumber(floatLiteral: 1.0)])
        do {
            try imgData?.write(to: url)
        } catch let error {
            print("\(self.self) Error Function '\(#function)' Line: \(#line) \(error.localizedDescription)")
        }
    }
}
