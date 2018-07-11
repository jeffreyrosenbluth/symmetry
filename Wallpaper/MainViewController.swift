//
//  MainViewController.swift
//  Wallpaper
//
//  Created by Jeffrey Rosenbluth on 5/25/18.
//  Copyright © 2018 Applause Code. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController, NSTextFieldDelegate {
    
    var originalImage: Image = Image(pixels: [], width: 0, height: 0)
    var formula: [Coef] = [Coef(nCoord: 1, mCoord: 0, anm: Complex(0.75, 0.25)),
                           Coef(nCoord: -2, mCoord: 2, anm: Complex(0.2, -0.2)),
                           Coef(nCoord: 1, mCoord: -1, anm: Complex(0.6, 0.1)),
                           Coef(), Coef(),
                           Coef(), Coef(), Coef(), Coef(), Coef()
                           ]
    var terms: Int = 3
    var rotation: Double = 0
    var scale: Double = 0.5
    var repeatLength: Double = 100
    var param1: Double = 1
    var param2: Double = 1
    
    @IBOutlet weak var group: NSPopUpButton!
    @IBOutlet weak var wheel: NSImageView!
    @IBOutlet weak var param1Field: NSTextField!
    @IBOutlet weak var param2Field: NSTextField!
    @IBOutlet weak var param1Label: NSTextField!
    @IBOutlet weak var param2Label: NSTextField!
    @IBOutlet weak var repeatLengthField: NSTextField!
    @IBOutlet weak var scaleField: NSTextField!
    @IBOutlet weak var rotationField: NSTextField!
    @IBOutlet weak var preprocessMenu: NSPopUpButton!
    @IBOutlet weak var term: NSTextField!
    @IBOutlet weak var n: NSTextField!
    @IBOutlet weak var m: NSTextField!
    @IBOutlet weak var magnitude: NSTextField!
    @IBOutlet weak var direction: NSTextField!
    @IBOutlet weak var termStepper: NSStepper!
    @IBOutlet weak var numberOfTerms: NSPopUpButton!
    @IBOutlet weak var wallpaperImage: NSImageView!
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        let tf = obj.object as! NSTextField
        let i = Int(term.intValue - 1)
        let x = Double(tf.doubleValue)
        let v = Int(x)
        switch tf.tag {
        case 8: param1 = x
        case 9: param2 = x
        case 10: repeatLength = x
        case 11: scale = x
        case 12: rotation = x
        case 13: formula[i].mCoord = v
        case 14: formula[i].nCoord = v
        case 15:
            let a = formula[i].anm.theta
            formula[i].anm = Complex(r: x, theta: a)
        case 16:
            let r = formula[i].anm.magnitude
            formula[i].anm = Complex(r: r, degrees: x)
        default: break
        }
    }
    
    @IBAction func incrementTerm(_ sender: NSStepper) {
        self.view.window?.makeFirstResponder(self.view.window?.contentView)
        term.intValue = sender.intValue
        showCoef(Int(sender.intValue))
    }
    
    @IBAction func termsChanged(_ sender: NSPopUpButton) {
        let n = numberOfTerms.titleOfSelectedItem!
        terms = Int(n)!
        termStepper.maxValue = Double(n)!
    }
    
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
            param1Field.isHidden = false
            param2Field.isHidden = false
            return
        case "cm", "cmm":
            param1Label.stringValue = "b"
            param1Label.isHidden = false
            param2Label.isHidden = true
            param1Field.isHidden = false
            param2Field.isHidden = true
            return
        case "pm", "pg", "pmm", "pmg", "pgg" :
            param1Label.stringValue = "l"
            param1Label.isHidden = false
            param2Label.isHidden = true
            param1Field.isHidden = false
            param2Field.isHidden = true
            return
        case "p4", "p4m", "p4g", "p3", "p31m", "p3m1", "p6", "p6m":
            param1Label.isHidden = true
            param2Label.isHidden = true
            param1Field.isHidden = true
            param2Field.isHidden = true
            return
        default:
            return
        }
    }
    
    @IBAction func pressLoad(_ sender: Any) {
        guard let url = NSOpenPanel().selectUrl else { return }
        guard let nsImage = NSImage(contentsOf: url) else { return }
        wheel.image = nsImage
        let image = imageToBitmap(nsImage)
        let data: [UInt8] = Array(UnsafeBufferPointer(start: image.bitmapData!, count: image.pixelsWide * image.pixelsHigh * 4))
        originalImage = Image(pixels: data, width: image.pixelsWide, height: image.pixelsHigh)
        preProcessImage()
    }
    
    @IBAction func pressRun(_ sender: Any) {
        self.view.window?.makeFirstResponder(self.view.window?.contentView)
        guard let grp = group.titleOfSelectedItem else {return}
        guard let img = wheel.image else {return}
        let a1 = param1 > 0 ? param1 : 1
        let a2 = param2 > 0 ? param2 : 1
        let rl = repeatLength > 0 ? repeatLength : 100
        let s = scale != 0 ? scale : 0.5
        var result: NSImage = NSImage()
        // End editing session by making window the first responder.
        DispatchQueue.global(qos: .userInteractive).async {
            result = self.makeWallpaper(image: img, recipeFn: stringToRecipeFn(grp, a1, a2), repLength: Int(rl), scale: s, rotation: self.rotation)
            DispatchQueue.main.async {
                self.wallpaperImage.image = result
            }
        }
    }
    
    func makeWallpaper(image: NSImage, recipeFn: ([Coef]) -> Recipe, repLength: Int, scale: Double, rotation: Double) -> NSImage {
        let opts = Options(width: 600, height: 480, repLength: repLength, scale: scale, rotation: Double.pi * rotation / 180)
        let paper = wallpaper(options: opts, recipeFn: recipeFn, coefs: Array(formula[0..<terms]), nsImage: image)
        return bitmapToImage(paper)
    }
    
    func preProcessImage() {
        guard let pString = preprocessMenu.titleOfSelectedItem else {return}
        let preprocess = stringToPreprocess(pString)
        wheel.image = bitmapToImage(toNSBitmapImageRep(preprocess(originalImage)))
    }

    func showCoef(_ i: Int) {
        n.intValue = Int32(formula[i-1].nCoord)
        m.intValue = Int32(formula[i-1].mCoord)
        magnitude.doubleValue = formula[i-1].anm.magnitude
        direction.doubleValue = formula[i-1].anm.direction
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showCoef(1)
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


