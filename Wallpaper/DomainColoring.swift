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

struct Coef: Hashable, Codable {
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

extension Coef {
    static func random() -> Coef {
        var n = Int(arc4random_uniform(7))
        n = Int(arc4random_uniform(2)) == 0 ? n : -n
        var m = Int(arc4random_uniform(7))
        m = Int(arc4random_uniform(2)) == 0 ? m : -m
        let d = (360 * drand48()).rounded()
        return Coef(nCoord: n, mCoord: m, anm: Complex(r: 1, degrees: d))

    }
}

struct Options: Codable {
    let width: Int
    let height: Int
    var repLength: Int
    var origin: Complex
    var scale: Double
    var rotation: Double
    var morphing: Bool
}

extension Options {
    static func random() -> Options {
//        let x = (2 * drand48() - 1).round2()
//        let y = (2 * drand48() - 1).round2()
//        let s = (drand48() + 0.5).round2()
        let r = (360 * drand48()).rounded()
        return Options(width: 600, height: 480, repLength: 240, origin: Complex(0, 0), scale: 1, rotation: r, morphing: false)
    }
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
    func f(_ z: Complex) -> Complex {
        return coeffs.reduce(Complex(0, 0), {(r, c) in (r + recipeFunc(c.nCoord, c.mCoord)(z) * c.anm)})
    }
    let m = (0...360).reduce(0.0, {(r, c) in
        max(r, f(Complex(r: 1, degrees: Double(c))).magnitude)
    })
    // Handle case where the max of the recipe function is 0.
    let s = m > 0 ? m : 1
    return {z in f(z).scale(1 / s)}
}

func focus(w: Int, h: Int, l: Int, recipe: @escaping Recipe) -> Recipe {
    return {(z) in
        let repLength = Double(l)
        return recipe(Complex((z.re - Double(w) / 2) / repLength, (Double(h) / 2 - z.im) / repLength))
    }
}

func color(options: Options, recipe: @escaping Recipe, image: RGBAimage, i: Int, j: Int) -> Pixel {
    let (x0, y0) = (options.origin.re, options.origin.im)
    let (w1, h1) = (image.width, image.height)
    let (w0, h0) = (Double(w1), Double(h1))
    let (x, y) = (x0 * w0 / 2, -y0 * h0 / 2)
    let r = min(w0 / 2 - abs(x), h0 / 2 - abs(y))
    let f = focus(w: options.width, h: options.height, l: options.repLength, recipe: recipe)
    let z = f(Complex(Double(i), Double(j)))
           .scale(options.scale * r)
           .rotate(options.rotation)
    func clamp(_ m: Int, _ n: Int) -> Pixel {
        var x = m
        var y = n
        if m < 0 {x = 0}
        if n < 0 {y = 0}
        if m >= w1 {x = w1 - 1}
        if n >= h1 {y = h1 - 1}
        return getPixel(image: image, x: x, y: y)
    }
    return clamp(Int(z.re) + w1 / 2 + Int(x), Int(z.im) + h1 / 2 + Int(y))
}

func domainColoring(_ options: Options, _ recipe: @escaping Recipe, _ wheel: RGBAimage) -> RGBAimage {
    func clr(_ i: Int, _ j: Int) -> Pixel {
        return color(options: options, recipe: recipe, image: wheel, i: i, j: j)
    }
    return generateImage(options.width, options.height, pixelFn: clr)
}

func blend(_ options: Options, _ recipe1: @escaping Recipe, _ recipe2: @escaping Recipe,_ wheel: RGBAimage) -> RGBAimage {
    func rcp(_ z: Complex) -> Complex {
        let m = max(1, Double(options.width) / Double(options.height))
        let a = (z.re + m) / (2 * m)
        return recipe2(z).scale(a) + recipe1(z).scale(1 - a)
    }
    return domainColoring(options, rcp, wheel)
}

func morph(_ options: Options, _ recipe: @escaping Recipe, _ cut: Double, _ wheel: RGBAimage) -> RGBAimage {
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
    let pixels = RGBAimage(pixels: data, width: image.pixelsWide, height: image.pixelsHigh)
    // We set the cutoff (i.e amount of unchanging border to 15%) somewhat arbitrarily.
    let outImage = options.morphing ? morph(options, recipeFn(coefs), 0.15, pixels) : domainColoring(options, recipeFn(coefs), pixels)
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


