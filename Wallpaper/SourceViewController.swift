//
//  SourceViewController.swift
//  Wallpaper
//
//  Created by Jeffrey Rosenbluth on 5/25/18.
//  Copyright © 2018 Applause Code. All rights reserved.
//

import Cocoa

class SourceViewController: NSViewController, NSTextFieldDelegate {
    
    var originalImage: Image = Image(pixels: [], width: 0, height: 0)
    
    @IBOutlet weak var group: NSPopUpButton!
    @IBOutlet weak var wheel: NSImageView!
    @IBOutlet weak var progress: NSProgressIndicator!
    @IBOutlet weak var param1: NSTextField!
    @IBOutlet weak var param2: NSTextField!
    @IBOutlet weak var param1Label: NSTextField!
    @IBOutlet weak var param2Label: NSTextField!
    @IBOutlet weak var repeatLength: NSTextField!
    @IBOutlet weak var scale: NSTextField!
    @IBOutlet weak var rotation: NSTextField!
    @IBOutlet weak var preprocessMenu: NSPopUpButton!
    
    @IBAction func preprocessChanged(_ sender: Any) {
        preProcessImage()
    }
    
    @IBAction func changeGroup(_ sender: NSPopUpButton) {
        switch sender.titleOfSelectedItem! {
        case "p1", "p2":
            param1Label.stringValue = "xi"
            param2Label.stringValue = "eta"
            param1Label.isHidden = false
            param2Label.isHidden = false
            param1.isHidden = false
            param2.isHidden = false
            return
        case "cm", "cmm":
            param1Label.stringValue = "b"
            param1Label.isHidden = false
            param2Label.isHidden = true
            param1.isHidden = false
            param2.isHidden = true
            return
        case "pm", "pg", "pmm", "pmg", "pgg" :
            param1Label.stringValue = "l"
            param1Label.isHidden = false
            param2Label.isHidden = true
            param1.isHidden = false
            param2.isHidden = true
            return
        case "p4", "p4m", "p4g", "p3", "p31m", "p3m1", "p6", "p6m":
            param1Label.isHidden = true
            param2Label.isHidden = true
            param1.isHidden = true
            param2.isHidden = true
            return
        default:
            return
        }
    }
    
    @IBAction func press(_ sender: Any) {
        guard let url = NSOpenPanel().selectUrl else { return }
        guard let nsImage = NSImage(contentsOf: url) else { return }
        wheel.image = nsImage
        let image = imageToBitmap(nsImage)
        let data: [UInt8] = Array(UnsafeBufferPointer(start: image.bitmapData!, count: image.pixelsWide * image.pixelsHigh * 4))
        originalImage = Image(pixels: data, width: image.pixelsWide, height: image.pixelsHigh)
        preProcessImage()
    }
    
    @IBAction func pressRun(_ sender: Any) {
        guard let splitView = parent as? NSSplitViewController else {return}
        guard let detail = splitView.childViewControllers[1] as? DetailViewController else { return }
        guard let grp = group.titleOfSelectedItem else {return}
        guard let img = wheel.image else {return}
        let a1 = param1.doubleValue > 0 ? param1.doubleValue : 1
        let a2 = param2.doubleValue > 0 ? param2.doubleValue : 1
        let rl = repeatLength.intValue > 0 ? repeatLength.intValue : 100
        let s = scale.doubleValue != 0 ? scale.doubleValue : 0.5
        let r = rotation.doubleValue

        var result: NSImage = NSImage()
        DispatchQueue.global(qos: .userInteractive).async {
            result = makeWallpaper(image: img, recipeFn: stringToRecipeFn(grp, a1, a2), repLength: Int(rl), scale: s, rotation: r)
            DispatchQueue.main.async {
                detail.imageView.image = result
            }
        }
    }
    
    func preProcessImage() {
        guard let pString = preprocessMenu.titleOfSelectedItem else {return}
        let preprocess = stringToPreprocess(pString)
        wheel.image = bitmapToImage(toNSBitmapImageRep(preprocess(originalImage)))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
}

func stringToRecipeFn(_ str: String, _ a1: Double, _ a2: Double) -> ([Coef]) -> Recipe {
    switch str {
    case "p1": return p1(a1, a2)
    case "p2": return p2(a1, a2)
    case "cm": return cm(a1)
    case "cmm": return cmm(a1)
    case "pm": return pm(a1)
    case "pg": return pg(a1)
    case "pmm": return pmm(a1)
    case "pmg": return pmg(a1)
    case "pgg": return pgg(a1)
    case "p4": return p4
    case "p4m": return p4m
    case "p4g": return p4g
    case "p3": return p3
    case "p31m": return p31m
    case "p3m1": return p3m1
    case "p6": return p6
    case "p6m": return p6m
    default:
        print("The sky is falling, popup returned an unhandled group")
        return p4
    }
}

func stringToPreprocess(_ str: String) -> (Image) -> Image {
    switch str {
    case "none": return plain
    case "flip vertical": return flipVertical
    case "flip horizontal": return flipHorizontal
    case "flip both": return flipBoth
    case "invert colors": return invertImage
    case "antisymmetric vertical": return antiSymmVertical
    case "antisymmetric horizontal": return antiSymmHorizontal
    default:
        print("The sky is falling, popup returned unhandled preprocess")
        return plain
    }
}

func makeWallpaper(image: NSImage, recipeFn: ([Coef]) -> Recipe, repLength: Int, scale: Double, rotation: Double) -> NSImage {
    let c0 = Coef(nCoord: 1, mCoord: 0, anm: Complex(0.75, 0.25))
    let c1 = Coef(nCoord: -2, mCoord: 2, anm: Complex(0.2, -0.2))
    let c2 = Coef(nCoord: 1, mCoord: -1, anm: Complex(0.6, 0.1))
    
    let opts = Options(width: 600, height: 480, repLength: repLength, scale: scale, rotation: rotation)
    
    let paper = wallpaper(options: opts, recipeFn: recipeFn, coefs: [c0, c1, c2], nsImage: image)
    return paper
}
