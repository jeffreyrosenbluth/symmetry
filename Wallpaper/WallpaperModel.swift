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
    var preprocess = Preprocess.plain
    var group = Group.p4g
    var param1 = 1.0
    var param2 = 1.0
    var terms = [Coef(nCoord: 1, mCoord: 0, anm: Complex(r: 1, degrees: 0)),
                 Coef(), Coef(), Coef(), Coef(),
                 Coef(), Coef(), Coef(), Coef(), Coef()
                ]
}

enum Group: String, Codable, CaseIterable {
    case p1
    case p2
    case cm
    case cmm
    case pm
    case pg
    case pmm
    case pmg
    case pgg
    case p4
    case p4m
    case p4g
    case p3
    case p31m
    case p3m1
    case p6
    case p6m
}

enum Preprocess: String, Codable, CaseIterable {
    case plain = "none"
    case flipVertical = "flip vertical"
    case flipHorizontal = "flip horizontal"
    case flipBoth = "flip both"
    case invertImage = "invert colors"
    case grayscale
    case antiSymmVertical = "antisymmetric vertical"
    case antiSymmHorizontal = "antisymmetric horizontal"
}
