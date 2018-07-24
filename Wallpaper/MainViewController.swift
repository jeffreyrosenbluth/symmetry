//
//  MainViewController.swift
//  Wallpaper
//
//  Created by Jeffrey Rosenbluth on 5/25/18.
//  Copyright © 2018 Applause Code. All rights reserved.
//

import Cocoa

class MainViewController: NSViewController, NSTextFieldDelegate {
    
    var document: Document {
        let wpDocument = view.window?.windowController?.document as? Document
        assert(wpDocument != nil, "Unable to find the document for this view controller.")
        return wpDocument!
    }
    
    var wp = WallpaperModel()
    var originalImage: Image = Image(pixels: [], width: 0, height: 0)
    let savePanel: NSSavePanel = NSSavePanel()
    var exportWidth: Int?
    var exportHeight: Int?
    
    
        
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
    @IBOutlet weak var imageTypePopup: NSPopUpButton!
    @IBOutlet weak var widthField: NSTextField!
    @IBOutlet weak var heightField: NSTextField!
    @IBOutlet weak var exportProgress: NSProgressIndicator!
    @IBOutlet weak var exportLabel: NSTextField!
    
    func updateUI() {
        group.selectItem(withTitle: document.wallpaperModel.group)
        param1Field.doubleValue = document.wallpaperModel.param1
        param2Field.doubleValue = document.wallpaperModel.param2
        repeatLengthField.intValue = Int32(document.wallpaperModel.options.repLength)
        scaleField.doubleValue = document.wallpaperModel.options.scale
        rotationField.doubleValue = document.wallpaperModel.options.rotation
        preprocessMenu.selectItem(withTitle: document.wallpaperModel.preprocess)
        handleNumOfTerms(document.wallpaperModel.numOfTerms)
        numberOfTerms.selectItem(at: document.wallpaperModel.numOfTerms - 1)
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        let tf = obj.object as! NSTextField
        let i = Int(term.intValue - 1)
        let x = Double(tf.doubleValue)
        let v = Int(x)
        switch tf.tag {
        case 8:
            wp.param1 = x
            document.wallpaperModel.param1 = x
        case 9:
            wp.param2 = x
            document.wallpaperModel.param2 = x
        case 10:
            wp.options.repLength = v
            document.wallpaperModel.options.repLength = v
        case 11:
            wp.options.scale = x
            document.wallpaperModel.options.scale = x
        case 12:
            wp.options.rotation = x
            document.wallpaperModel.options.rotation = x
        case 13:
            wp.terms[i].mCoord = v
            document.wallpaperModel.terms[i].mCoord = v
        case 14:
            wp.terms[i].nCoord = v
            document.wallpaperModel.terms[i].nCoord = v
        case 15:
            let a = wp.terms[i].anm.theta
            wp.terms[i].anm = Complex(r: x, theta: a)
            document.wallpaperModel.terms[i].anm = wp.terms[i].anm
        case 16:
            let r = wp.terms[i].anm.magnitude
            wp.terms[i].anm = Complex(r: r, degrees: x)
            document.wallpaperModel.terms[i].anm = wp.terms[i].anm
        default: break
        }
    }
    
    @IBAction func incrementTerm(_ sender: NSStepper) {
        self.view.window?.makeFirstResponder(self.view.window?.contentView)
        term.intValue = sender.intValue
        showCoef(Int(sender.intValue))
    }
    
    @IBAction func termsChanged(_ sender: NSPopUpButton) {
        let n = Int(numberOfTerms.titleOfSelectedItem!)
        handleNumOfTerms(n!)
    }
    
    func handleNumOfTerms(_ n: Int) {
        wp.numOfTerms = n
        document.wallpaperModel.numOfTerms = n
        termStepper.maxValue = Double(n)
        if term.intValue > n {
            term.intValue = Int32(n)
            showCoef(n)
        }
    }
    
    func showCoef(_ i: Int) {
        n.intValue = Int32(wp.terms[i-1].nCoord)
        m.intValue = Int32(wp.terms[i-1].mCoord)
        magnitude.doubleValue = wp.terms[i-1].anm.magnitude
        direction.doubleValue = wp.terms[i-1].anm.direction
    }
    
    @IBAction func preprocessChanged(_ sender: NSPopUpButton) {
        document.wallpaperModel.preprocess = sender.titleOfSelectedItem!
        preProcessImage()
    }
    
    @IBAction func changeGroup(_ sender: NSPopUpButton) {
        document.wallpaperModel.group = sender.titleOfSelectedItem!
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
        let image = imageToBitmap(nsImage)
        let data: [UInt8] = Array(UnsafeBufferPointer(start: image.bitmapData!, count: image.pixelsWide * image.pixelsHigh * 4))
        originalImage = Image(pixels: data, width: image.pixelsWide, height: image.pixelsHigh)
        preProcessImage()
    }
    
    @IBAction func pressRun(_ sender: Any) {
        self.view.window?.makeFirstResponder(self.view.window?.contentView)
        guard let grp = group.titleOfSelectedItem else {return}
        guard let img = wheel.image else {return}
        let a1 = wp.param1 > 0 ? wp.param1 : 1
        let a2 = wp.param2 > 0 ? wp.param2 : 1
        let rl = wp.options.repLength > 0 ? wp.options.repLength : 100
        let s = wp.options.scale != 0 ? wp.options.scale : 0.5
        var result: NSBitmapImageRep?
        // End editing session by making window the first responder.
        DispatchQueue.global(qos: .userInteractive).async {
            result = self.makeWallpaper(image: img, recipeFn: stringToRecipeFn(grp, a1, a2), width: 600, height: 480, repLength: Int(rl), scale: s, rotation: self.wp.options.rotation)
            DispatchQueue.main.async {
                self.wallpaperImage.image = bitmapToImage(result!)
            }
        }
    }
        
    @IBAction func changeFiletype(_ sender: NSPopUpButton) {
        switch sender.titleOfSelectedItem {
        case "PNG":
            savePanel.allowedFileTypes = ["png"]
        case "JPEG": savePanel.allowedFileTypes = ["jpg"]
        case "TIFF": savePanel.allowedFileTypes = ["tiff"]
        default: savePanel.allowedFileTypes = ["png"]
        }
    }
    
    @IBAction func pressExport(_ sender: Any) {
        self.view.window?.makeFirstResponder(self.view.window?.contentView)
        var topLevelObjects : NSArray?
        guard let grp = group.titleOfSelectedItem else {return}
        guard let img = wheel.image else {return}
        let a1 = wp.param1 > 0 ? wp.param1 : 1
        let a2 = wp.param2 > 0 ? wp.param2 : 1
        let rl = wp.options.repLength > 0 ? wp.options.repLength : 100
        let s = wp.options.scale != 0 ? wp.options.scale : 0.5
        savePanel.title = "Save As:"
        savePanel.prompt = "Save"
        savePanel.allowedFileTypes = ["png"]
        Bundle.main.loadNibNamed(NSNib.Name(rawValue: "ExportAccessory"), owner: self, topLevelObjects: &topLevelObjects)
        savePanel.accessoryView = topLevelObjects!.first(where: { $0 is NSView }) as? NSView
        if savePanel.runModal() == NSApplication.ModalResponse.OK {
            exportProgress.isHidden = false
            exportProgress.startAnimation(self)
            exportLabel.isHidden = false
            exportLabel.stringValue = "exporting \(savePanel.nameFieldStringValue)"
            var result: NSBitmapImageRep?
            exportWidth = widthField.intValue == 0 ? 600 : Int(widthField.intValue)
            exportHeight = heightField.intValue == 0 ? 480 : Int(heightField.intValue)
            let filetype = imageTypePopup.titleOfSelectedItem
            DispatchQueue.global(qos: .background).async {
                result = self.makeWallpaper(image: img, recipeFn: stringToRecipeFn(grp, a1, a2), width: self.exportWidth!, height: self.exportHeight!, repLength: Int(rl), scale: s, rotation: self.wp.options.rotation)
                switch filetype {
                case "PNG": result?.writeImageRep(toURL: self.savePanel.url!, filetype: .png)
                case "JPEG": result?.writeImageRep(toURL: self.savePanel.url!, filetype: .jpeg)
                case "TIFF": result?.writeImageRep(toURL: self.savePanel.url!, filetype: .tiff)
                default: result?.writeImageRep(toURL: self.savePanel.url!, filetype: .png)
                }
                DispatchQueue.main.async {
                    self.exportProgress.stopAnimation(self)
                    self.exportProgress.isHidden = true
                    self.exportLabel.isHidden = true
                }
            }
        }
    }
    
    func makeWallpaper(image: NSImage, recipeFn: ([Coef]) -> Recipe, width: Int, height: Int, repLength: Int, scale: Double, rotation: Double) -> NSBitmapImageRep {
        let opts = Options(width: width, height: height, repLength: repLength, scale: scale, rotation: Double.pi * rotation / 180)
        return wallpaper(options: opts, recipeFn: recipeFn, coefs: Array(wp.terms[0..<wp.numOfTerms]), nsImage: image)
    }
    
    func preProcessImage() {
        guard let pString = preprocessMenu.titleOfSelectedItem else {return}
        let preprocess = stringToPreprocess(pString)
        wheel.image = bitmapToImage(toNSBitmapImageRep(preprocess(originalImage)))
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
        showCoef(1)
    }
    
    override func viewWillAppear() {
        wp = document.wallpaperModel
        updateUI()
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


