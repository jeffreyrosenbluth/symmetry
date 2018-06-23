//
//  Complex.swift
//  Wallpaper
//
//  Created by Jeffrey Rosenbluth on 6/17/18.
//  Copyright © 2018 Applause Code. All rights reserved.
//

import Foundation

struct Complex: Hashable {
    let re: Double
    let im: Double
    
    init(_ a: Double, _ b: Double) {
        re = a
        im = b
    }
    
    func scale(_ k: Double) -> Complex {
        return Complex(k * re, k * im)
    }
}

func +(_ a: Complex, _ b: Complex) -> Complex {
    return Complex(a.re + b.re, a.im + b.im)
}

func *(_ a: Complex, _ b: Complex) -> Complex {
    return Complex(a.re * b.re - a.im * b.im, a.re * b.im + a.im * b.re)
}

func exp(_ z: Complex) -> Complex {
    let expx = exp(z.re)
    return Complex(expx * cos(z.im), expx * sin(z.im))
}


