//
//  DomainColoring.swift
//  Wallpaper
//
//  Created by Jeffrey Rosenbluth on 6/17/18.
//  Copyright © 2018 Applause Code. All rights reserved.
//

import Foundation
import Cocoa

typealias  Recipe = (Complex) -> Complex

struct Coef: Hashable {
    var nCoord: Int
    var mCoord: Int
    var anm: Complex
    
    init(nCoord: Int, mCoord: Int, anm: Complex) {
        self.nCoord = nCoord
        self.mCoord = mCoord
        self.anm = anm
    }
    
    init() {
        nCoord = 0
        mCoord = 0
        anm = Complex(0, 0)
    }
}

extension Coef {
    func negateBoth() -> Coef {
        return Coef(nCoord: -nCoord, mCoord: -mCoord, anm: anm)
    }
    
    func negateFst() -> Coef {
        return Coef(nCoord: -nCoord, mCoord: mCoord, anm: anm)
    }
    
    func negateSnd() -> Coef {
        return Coef(nCoord: nCoord, mCoord: -mCoord, anm: anm)
    }
    
    func reverse() -> Coef {
        return Coef(nCoord: mCoord, mCoord: nCoord, anm: anm)
    }
    
    func alternate(_ alt: (Int, Int) -> Double) -> Coef {
        return Coef(nCoord: nCoord, mCoord: mCoord, anm: anm.scale(alt(nCoord, mCoord)))
    }
}

struct Options {
    let width: Int
    let height: Int
    let repLength: Int
    let scale: Double
    let rotation: Double
}

func enm(n: Int, m: Int, x: Double, y: Double) -> Complex {
    let k = 2 * Double.pi * (Double(n) * x + Double(m) * y)
    return exp(Complex(0, 1).scale(k))
}

func tnm(n: Int, m: Int, x: Double, y: Double) -> Complex {
    let z = (enm(n: n, m: m, x: x, y: y) + enm(n: -n, m: -m, x: x, y: y))
    return z.scale(0.5)
}

func wnm(n: Int, m: Int, x: Double, y: Double) -> Complex {
    let z = (enm(n: n, m: m, x: x, y: y) +
             enm(n: m, m: (-n - m), x: x, y: y) +
             enm(n: (-n - m), m: n, x: x, y: y)
            )
    return z.scale(1/3)
}

func makeRecipe(recipeFunc: @escaping (Int, Int) -> Recipe, coeffs: [Coef]) -> Recipe {
    return {z in coeffs.reduce(Complex(0, 0), {(r, c) in
        r + recipeFunc(c.nCoord, c.mCoord)(z) * c.anm
    })}
}

func focus(w: Int, h: Int, l: Int, recipe: @escaping Recipe) -> Recipe {
    return {(z) in
        let repLength = Double(l)
        return recipe(Complex((z.re - Double(w) / 2) / repLength, (Double(h) / 2 - z.im) / repLength))
    }
}

func color(options: Options, recipe: @escaping Recipe, image: Image, i: Int, j: Int) -> Pixel {
    let w1 = image.width
    let h1 = image.height
    let f = focus(w: options.width, h: options.height, l: options.repLength, recipe: recipe)
    let z = f(Complex(Double(i), Double(j)))
           .scale(options.scale * Double(min(w1, h1)))
           .rotate(options.rotation)
    func clamp(_ m: Int, _ n: Int) -> Pixel {
        if (m < 0) || (n < 0) || m >= w1 || n >= h1 {
            return blackPixel
        } else {
            return getPixel(image: image, x: m, y: n)
        }
    }
    return clamp(Int(round(z.re)) + w1 / 2, Int(round(z.im)) + h1 / 2)
}

func domainColoring(_ options: Options, _ recipe: @escaping Recipe, _ wheel: Image) -> Image {
    func clr(_ i: Int, _ j: Int) -> Pixel {
        return color(options: options, recipe: recipe, image: wheel, i: i, j: j)
    }
    return generateImage(options.width, options.height, pixelFn: clr)
}

func blend(_ options: Options, _ recipe1: @escaping Recipe, _ recipe2: @escaping Recipe,_ wheel: Image) -> Image {
    func rcp(_ z: Complex) -> Complex {
        let m = max(1, Double(options.width) / Double(options.height))
        let a = (z.re + m) / (2 * m)
        return recipe2(z).scale(a) + recipe1(z).scale(1 - a)
    }
    
    return domainColoring(options, rcp, wheel)
}

func morph(_ options: Options, _ recipe: @escaping Recipe, _ cut: Double, _ wheel: Image) -> Image {
    func phi(_ c: Double, _ u: Double) -> Double {
        if u < cut {
            return 1
        } else if u > 1 - cut {
            return -1
        } else {
            return (2 / (2 * cut - 1)) * (u - 0.5)
        }
    }
    
    func rcp(_ z: Complex) -> Complex {
        let t = Double(options.width / options.repLength)
        return Complex(0,1).scale(exp(Double.pi * phi(cut, ((z.re + t / 2) / t)))) * recipe(z)
    }
    
    return domainColoring(options, rcp, wheel)
}

func wallpaper(options: Options, recipeFn: (([Coef]) -> Recipe), coefs: [Coef], nsImage: NSImage) -> NSBitmapImageRep {
    let image = imageToBitmap(nsImage)
    let data: [UInt8] = Array(UnsafeBufferPointer(start: image.bitmapData!, count: image.pixelsWide * image.pixelsHigh * 4))
    let pixels = Image(pixels: data, width: image.pixelsWide, height: image.pixelsHigh)
    let outImage = domainColoring(options, recipeFn(coefs), pixels)
    return toNSBitmapImageRep(outImage)
}

// -------------------------------------------------------------------------------------------------

func nub<T: Hashable>(_ a: Array<T>) -> Array<T> {
    return Array(Set<T>(a))
}

func alt(_ n: Int) -> Double {
    if n % 2 == 0 {
        return 1
    } else {
        return -1
    }
}

// Generic Lattice. --------------------------------------------------------------------------------

func genericLattice(_ xi: Double, _ eta: Double) -> (Int, Int) -> Recipe {
    return {(m, n) in
        return {(z) in
            let x = z.re - xi * z.im / eta
            let y = z.im / eta
            return enm(n: n, m: m, x: x, y: y)}
    }
}

func p1(_ xi: Double, _ eta: Double) -> ([Coef]) -> Recipe {
    return {(c) in makeRecipe(recipeFunc: (genericLattice(xi, eta)), coeffs: c)}
}

func p2(_ xi: Double, _ eta: Double) -> ([Coef]) -> Recipe {
    return {(c) in
        let c1 = c.map{$0.negateBoth()}
        return makeRecipe(recipeFunc: (genericLattice(xi, eta)), coeffs: nub(c + c1))}
}
// Rhombic Lattice. --------------------------------------------------------------------------------

func rhombicLattice(_ b: Double) -> (Int, Int) -> Recipe {
    return {(m, n) in
        return {(z) in
            let x = z.re + z.im / (2 * b)
            let y = z.re - z.im / (2 * b)
            return enm(n: n, m: m, x: x, y: y)}
    }
}

func cm(_ b: Double) -> ([Coef]) -> Recipe {
    return {(c) in
        let c1 = c.map{$0.reverse()}
        return makeRecipe(recipeFunc: (rhombicLattice(b)), coeffs: nub(c + c1))}
}

func cmm(_ b: Double) -> ([Coef]) -> Recipe {
    return {(c) in
        let c1 = c.map{$0.negateBoth()}
        let c2 = c.map{$0.reverse()}
        let c3 = c.map{$0.negateBoth().reverse()}
        return makeRecipe(recipeFunc: (rhombicLattice(b)), coeffs: nub(c + c1 + c2 + c3))}
}

// Rectangular Lattice. ----------------------------------------------------------------------------

func rectangularLattice(_ l: Double) -> (Int, Int) -> Recipe {
    return {(m, n) in {(z) in enm(n: n, m: m, x: z.re, y: (z.im / l))}
    }
}

func rectangularLattice2(_ l: Double) -> (Int, Int) -> Recipe {
    return {(m, n) in {(z) in tnm(n: n, m: m, x: z.re, y: (z.im / l))}
    }
}

func pm(_ l: Double) -> ([Coef]) -> Recipe {
    return {(c) in
        let c1 = c.map{$0.negateSnd()}
        return makeRecipe(recipeFunc: (rectangularLattice(l)), coeffs: nub(c + c1))}
}

func pg(_ l: Double) -> ([Coef]) -> Recipe {
    return {(c) in
    let c1 = c.map{$0.alternate{(n, m) in alt(n)}.negateSnd()}
        return makeRecipe(recipeFunc: (rectangularLattice(l)), coeffs: nub(c + c1))}
}

func pmm(_ l: Double) -> ([Coef]) -> Recipe {
    return {(c) in
        let c1 = c.map{$0.negateSnd()}
        return makeRecipe(recipeFunc: (rectangularLattice2(l)), coeffs: nub(c + c1))}
}

func pmg(_ l: Double) -> ([Coef]) -> Recipe {
    return {(c) in
        let c1 = c.map{$0.alternate{(n, m) in alt(n)}.negateSnd()}
        return makeRecipe(recipeFunc: (rectangularLattice2(l)), coeffs: nub(c + c1))}
}

func pgg(_ l: Double) -> ([Coef]) -> Recipe {
    return {(c) in
        let c1 = c.map{$0.alternate{(n, m) in alt(n + m)}.negateSnd()}
        return makeRecipe(recipeFunc: (rectangularLattice2(l)), coeffs: nub(c + c1))}
}

// Square Lattice: for 4-fold symmetry groups. -----------------------------------------------------

func squareLattice(_ n: Int, _ m: Int) -> Recipe {
    return {(z) in
        (tnm(n: n, m: m, x: z.re, y: z.im ) + tnm(n: -n, m: m, x: z.re, y: z.im)).scale(0.5)
    }
}

func p4(_ c: [Coef]) -> Recipe {
    return makeRecipe(recipeFunc: squareLattice, coeffs: c)
}

func p4m(_ c: [Coef]) -> Recipe {
    return makeRecipe(recipeFunc: squareLattice, coeffs: nub(c + c.map{$0.reverse()}))
}

func p4g(_ c: [Coef]) -> Recipe {
    return makeRecipe(recipeFunc: squareLattice, coeffs: nub(c + c.map{$0.alternate{(n, m)
        in alt(n + m)}.reverse()}))
}

// Hexagonal Lattice. ------------------------------------------------------------------------------

func hexagonalLattice(_ n: Int, _ m: Int) -> Recipe {
    return {(z) in
        let x = z.re + z.im / sqrt(3)
        let y = 2 * z.im / sqrt(3)
        return (enm(n: n, m: m, x: x, y: y ) +
                enm(n: m, m: -n - m, x: x, y: y) +
                enm(n: -n - m, m: n, x: x, y: y))
               .scale(1/3)
    }
}

func p3(_ c: [Coef]) -> Recipe {
    return makeRecipe(recipeFunc: hexagonalLattice(_:_:), coeffs: c)
}

func p31m(_ c: [Coef]) -> Recipe {
    return makeRecipe(recipeFunc: hexagonalLattice(_:_:), coeffs: nub(c + c.map{$0.reverse()}))
}

func p3m1(_ c: [Coef]) -> Recipe {
    return makeRecipe(recipeFunc: hexagonalLattice(_:_:), coeffs: nub(c + c.map{$0.reverse().negateBoth()}))
}

func p6(_ c: [Coef]) -> Recipe {
    return makeRecipe(recipeFunc: hexagonalLattice(_:_:), coeffs: nub(c + c.map{$0.negateBoth()}))
}

func p6m(_ c: [Coef]) -> Recipe {
    let c1 = c.map{$0.negateBoth()}
    let c2 = c.map{$0.reverse()}
    let c3 = c2.map{$0.negateBoth()}
    return makeRecipe(recipeFunc: hexagonalLattice(_:_:), coeffs: nub(c + c1 + c2 + c3))
}

// -------------------------------------------------------------------------------------------------


