//
//  WallpaperModel.swift
//  Wallpaper
//
//  Created by Jeffrey Rosenbluth on 7/22/18.
//  Copyright © 2018 Applause Code. All rights reserved.
//

import Cocoa

struct WallpaperModel: Codable {
    var options = Options(width: 600, height: 480, repLength: 240, origin: Complex(0,0), scale: 1, rotation: 0, morphing: false)
    var numOfTerms = 1
    var preprocess = "none"
    var group = "p3"
    var param1 = 1.0
    var param2 = 1.0
    var terms = [Coef(nCoord: 1, mCoord: 0, anm: Complex(r: 1, degrees: 0)),
                 Coef(), Coef(), Coef(), Coef(),
                 Coef(), Coef(), Coef(), Coef(), Coef()
    ]
}

func randomGroup() -> String {
    let g = ["p1", "p2", "cm", "cmm", "pm", "pg", "pmm", "pmg", "pgg", "p4", "p4m", "p4g", "p3", "p31m", "p3m1", "p6", "p6m"]
    let n = Int(arc4random_uniform(17))
    return g[n]
}
