//
//  Pixel.swift
//  Wallpaper
//
//  Created by Jeffrey Rosenbluth on 6/15/18.
//  Copyright © 2018 Applause Code. All rights reserved.
//

import Foundation
import Cocoa

struct Pixel {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8
}

let blackPixel = Pixel(red: 0, green: 0, blue: 0, alpha: 255)
let whitePixel = Pixel(red: 255, green: 255, blue: 255, alpha: 255)

typealias RGBA = [UInt8]

struct RGBAimage {
    var pixels: RGBA
    let width: Int
    let height: Int
    
    mutating func setRGBA(x: Int, y: Int, pixel: Pixel) {
        let idx = (y * width + x) * 4
        pixels[idx] = pixel.red
        pixels[idx+1] = pixel.green
        pixels[idx+2] = pixel.blue
        pixels[idx+3] = pixel.alpha
    }
}

func imageToBitmap(_ image: NSImage) -> NSBitmapImageRep {
    guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        return NSBitmapImageRep()
    }
    return NSBitmapImageRep.init(cgImage: cgImage)
}

func bitmapToImage(_ bitmap: NSBitmapImageRep) -> NSImage {
    guard let cgImage = bitmap.cgImage else {
        return NSImage.init()
    }
    return NSImage(cgImage: cgImage, size: NSZeroSize)
}

func to255(_ x: CGFloat) -> UInt8 {
    return UInt8(round(255 * x))
}

func nsColorToPixel(_ nsColor: NSColor) -> Pixel {
    let rgba = UnsafeMutablePointer<CGFloat>.allocate(capacity: 4)
    nsColor.getComponents(rgba)
    return Pixel(red: to255(rgba[0]),
                 green: to255(rgba[1]),
                 blue: to255(rgba[2]),
                 alpha: to255(rgba[3]))
}

func generateImage(_ width: Int, _ height: Int, pixelFn: (Int, Int) -> Pixel) -> RGBAimage {
    var data: [UInt8] = []
    for i in 0..<height {
        for j in 0..<width {
            let pixel = pixelFn(j, i)
            data.append(pixel.red)
            data.append(pixel.green)
            data.append(pixel.blue)
            data.append(pixel.alpha)
        }
    }
    return RGBAimage(pixels: data, width: width, height: height)
}

func invertPixel(_ color: Pixel) -> Pixel {
    let r = 255 - color.red
    let g = 255 - color.green
    let b = 255 - color.blue
    return Pixel(red: r, green: g, blue: b, alpha: color.alpha)
}

func plain(_ image: RGBAimage) -> RGBAimage {
    return image
}

func invertImage(_ image: RGBAimage) -> RGBAimage {
    return generateImage(image.width, image.height) {
        (x,y) in invertPixel(getPixel(image: image, x: x, y: y))
    }
}

func flipHorizontal(_ image: RGBAimage) -> RGBAimage {
    return generateImage(image.width, image.height) {
        (x,y) in getPixel(image: image, x: image.width - 1 - x, y: y)
    }
}

func flipVertical(_ image: RGBAimage) -> RGBAimage {
    return generateImage(image.width, image.height) {
        (x,y) in getPixel(image: image, x: x, y: image.height - 1 - y)
    }
}

func flipBoth(_ image: RGBAimage) -> RGBAimage {
    return generateImage(image.width, image.height) {
        (x,y) in getPixel(image: image, x: image.width - 1 - x, y: image.height - 1 - y)
    }
}

func beside(_ image1: RGBAimage, _ image2: RGBAimage) -> RGBAimage {
    return generateImage(image1.width + image2.width, image1.height) {x,y in
        if x < image1.width {
            return getPixel(image: image1, x: x, y: y)
        } else {
            return getPixel(image: image2, x: x - image1.width, y: y)
        }
    }
}

func below(_ image1: RGBAimage, _ image2: RGBAimage) -> RGBAimage {
    return generateImage(image1.width, image1.height + image2.height) {x,y in
        if y < image1.height {
            return getPixel(image: image1, x: x, y: y)
        } else {
            return getPixel(image: image2, x: x, y: y - image1.height)
        }
    }
}

func antiSymmHorizontal(_ image: RGBAimage) -> RGBAimage {
    return beside(image, flipBoth(invertImage(image)))
}

func antiSymmVertical(_ image: RGBAimage) -> RGBAimage {
    return below(image, flipBoth(invertImage(image)))
}

func getPixel(image: RGBAimage, x: Int, y: Int) -> Pixel {
    let idx = (x + y * image.width) * 4
    return Pixel(red: image.pixels[idx],
                 green: image.pixels[idx+1],
                 blue: image.pixels[idx+2],
                 alpha: image.pixels[idx+3])
}

func toNSBitmapImageRep(_ image: RGBAimage) -> NSBitmapImageRep {
    let size = 4 * image.width * image.height
    let data: UnsafeMutablePointer<UInt8>? = UnsafeMutablePointer<UInt8>.allocate(capacity: size)
    data?.initialize(from: image.pixels, count: size)
    let planes: UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>? =
        UnsafeMutablePointer<UnsafeMutablePointer<UInt8>?>.allocate(capacity: 1)
    planes?.initialize(from: [data], count: 1)
    return NSBitmapImageRep(bitmapDataPlanes: planes,
                            pixelsWide: image.width,
                            pixelsHigh: image.height,
                            bitsPerSample: 8,
                            samplesPerPixel: 4,
                            hasAlpha: true,
                            isPlanar: false,
                            colorSpaceName: NSColorSpaceName.deviceRGB,
                            bitmapFormat: NSBitmapImageRep.Format.alphaNonpremultiplied,
                            bytesPerRow: image.width * 4,
                            bitsPerPixel: 32)!
}
