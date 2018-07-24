//
//  WallpaperModel.swift
//  Wallpaper
//
//  Created by Jeffrey Rosenbluth on 7/22/18.
//  Copyright © 2018 Applause Code. All rights reserved.
//

import Cocoa

struct WallpaperModel: Codable {
    var options = Options(width: 600, height: 480, repLength: 100, scale: 0.25, rotation: 0)
    var numOfTerms = 1
    var preprocess = "none"
    var group = "p4m"
    var param1 = 1.0
    var param2 = 1.0
    var terms = [Coef(nCoord: 1, mCoord: 0, anm: Complex(r: 0.8, degrees: 20)),
                 Coef(), Coef(), Coef(), Coef(),
                 Coef(), Coef(), Coef(), Coef(), Coef()
    ]
}

//                 Coef(nCoord: -2, mCoord: 2, anm: Complex(r: 0.3, degrees: 315)),
//                 Coef(nCoord: 1, mCoord: -1, anm: Complex(r: 0.6, degrees: 90)),
