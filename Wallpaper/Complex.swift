//
//  Complex.swift
//  The bare minimum set of functions needed by the wallpaper application
//  to handle complex numbers and operations.
//  Wallpaper
//
//  Created by Jeffrey Rosenbluth on 6/17/18.
//  Copyright © 2018 Applause Code. All rights reserved.
//

import Foundation

struct Complex: Hashable, Codable {
    let re: Double
    let im: Double
    
    init(_ a: Double, _ b: Double) {
        re = a
        im = b
    }
    
    init(r: Double, theta: Double) {
        re = r * cos(theta)
        im = r * sin(theta)
    }
    
    init(r: Double, degrees: Double) {
        re = r * cos(Double.pi * degrees / 180)
        im = r * sin(Double.pi * degrees / 180)
    }
    
    func scale(_ k: Double) -> Complex {
        return Complex(k * re, k * im)
    }
    
    func rotate(_ theta: Double) -> Complex {
        return self * Complex(r: 1, theta: theta)
    }
    
    var magnitude: Double {
        return sqrt(re * re + im * im)
    }
    
    var theta: Double {
        return atan2(im, re)
    }
    
    var direction: Double {
        return 180 * atan2(im, re) / Double.pi
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


