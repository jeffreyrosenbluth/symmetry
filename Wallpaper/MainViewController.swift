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
    var originalImage: RGBAimage = RGBAimage(pixels: [], width: 0, height: 0)
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
    @IBOutlet weak var xTextField: NSTextField!
    @IBOutlet weak var yTextField: NSTextField!
    @IBOutlet var morphCheckbox: NSButton!
    
    func updateUI() {
        group.selectItem(withTitle: document.wallpaperModel.group.rawValue)
        param1Field.doubleValue = document.wallpaperModel.param1
        param2Field.doubleValue = document.wallpaperModel.param2
        repeatLengthField.intValue = Int32(document.wallpaperModel.options.repLength)
        xTextField.doubleValue = document.wallpaperModel.options.origin.re
        yTextField.doubleValue = document.wallpaperModel.options.origin.im
        scaleField.doubleValue = document.wallpaperModel.options.scale
        rotationField.doubleValue = document.wallpaperModel.options.rotation
        preprocessMenu.selectItem(withTitle: document.wallpaperModel.preprocess.rawValue)
        handleNumOfTerms(document.wallpaperModel.numOfTerms)
        numberOfTerms.selectItem(at: document.wallpaperModel.numOfTerms - 1)
        term.intValue = 1
        n.intValue = Int32(document.wallpaperModel.terms[0].nCoord)
        m.intValue = Int32(document.wallpaperModel.terms[0].mCoord)
        magnitude.doubleValue = document.wallpaperModel.terms[0].anm.magnitude
        direction.doubleValue = document.wallpaperModel.terms[0].anm.direction
        morphCheckbox.state = document.wallpaperModel.options.morphing ? .on : .off
    }
    
    @IBAction func morphed(_ sender: NSButton) {
        switch sender.state {
        case .on:
            wp.options.morphing = true
            document.wallpaperModel.options.morphing = true
        default:
            wp.options.morphing = false
            document.wallpaperModel.options.morphing = false
        }
    }
    
    override func controlTextDidEndEditing(_ obj: Notification) {
        let tf = obj.object as! NSTextField
        let i = Int(term.intValue - 1)
        let x = Double(tf.doubleValue)
        let v = Int(x)
        switch tf.tag {
        case 6:
            let y = wp.options.origin.im
            wp.options.origin = Complex(x, y)
            document.wallpaperModel.options.origin = Complex(x, y)
        case 7:
            let y = wp.options.origin.re
            wp.options.origin = Complex(y, x)
            document.wallpaperModel.options.origin = Complex(y, x)
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
        guard let process = sender.titleOfSelectedItem else {return}
        guard let pp = Preprocess(rawValue: process) else {return}
        document.wallpaperModel.preprocess = pp
        preProcessImage()
    }
    
    func handleGroupChange(_ g: Group) {
        switch g {
        case .p1, .p2:
            param1Label.stringValue = "xi"
            param2Label.stringValue = "eta"
            param1Label.isHidden = false
            param2Label.isHidden = false
            param1Field.isHidden = false
            param2Field.isHidden = false
            return
        case .cm, .cmm:
            param1Label.stringValue = "b"
            param1Label.isHidden = false
            param2Label.isHidden = true
            param1Field.isHidden = false
            param2Field.isHidden = true
            return
        case .pm, .pg, .pmm, .pmg, .pgg :
            param1Label.stringValue = "L"
            param1Label.isHidden = false
            param2Label.isHidden = true
            param1Field.isHidden = false
            param2Field.isHidden = true
            return
        case .p4, .p4m, .p4g, .p3, .p31m, .p3m1, .p6, .p6m:
            param1Label.isHidden = true
            param2Label.isHidden = true
            param1Field.isHidden = true
            param2Field.isHidden = true
            return
        }
    }
    
    @IBAction func changeGroup(_ sender: NSPopUpButton) {
        guard let grpString = sender.titleOfSelectedItem else {return}
        guard let grp = Group(rawValue: grpString) else {return}
        document.wallpaperModel.group = grp
        handleGroupChange(grp)
    }
    
    @IBAction func pressRandom(_ sender: Any) {
        var cs: [Coef] = []
        var ts: [Coef] = []
        let b = (0.25 * drand48() + 0.5).round2()
        for i in 0...9 {
            cs.append(Coef.random())
        }
        func ord(_ c1: Coef, _ c2: Coef) -> Bool {
            let a = abs(c1.mCoord) + abs(c1.nCoord)
            let b = abs(c2.mCoord) + abs(c2.nCoord)
            return (a < b)
        }
        cs.sort(by: ord)
        for i in 0...9 {
            let c = cs[i]
            ts.append(Coef(nCoord: c.nCoord, mCoord: c.mCoord, anm: Complex(r: pow(b, Double(i)), theta: c.anm.theta)))
        }
        wp.terms = ts
        document.wallpaperModel.terms = ts
        wp.numOfTerms = 1 + Int(arc4random_uniform(10))
        document.wallpaperModel.numOfTerms = wp.numOfTerms
        guard let g = Group.allCases.randomElement() else {return}
        handleGroupChange(g)
        wp.group = g
        document.wallpaperModel.group = g
        updateUI()
    }
    
    @IBAction func pressLoad(_ sender: Any) {
        guard let url = NSOpenPanel().selectUrl else { return }
        guard let nsImage = NSImage(contentsOf: url) else { return }
        let image = imageToBitmap(nsImage)
        let data: [UInt8] = Array(UnsafeBufferPointer(start: image.bitmapData!, count: image.pixelsWide * image.pixelsHigh * 4))
        originalImage = RGBAimage(pixels: data, width: image.pixelsWide, height: image.pixelsHigh)
        preProcessImage()
    }
    
    @IBAction func pressRun(_ sender: Any) {
        self.view.window?.makeFirstResponder(self.view.window?.contentView)
        guard let grpString = group.titleOfSelectedItem else {return}
        guard let grp = Group(rawValue: grpString) else {return}
        guard let img = wheel.image else {return}
        let a1 = wp.param1 > 0 ? wp.param1 : 1
        let a2 = wp.param2 > 0 ? wp.param2 : 1
        let rl = wp.options.repLength > 0 ? wp.options.repLength : 100
        let s = wp.options.scale != 0 ? wp.options.scale : 1.0
        let h = wp.options.morphing ? 240 : 480
        var result: NSBitmapImageRep?
        exportProgress.isHidden = false
        exportProgress.startAnimation(self)
        exportLabel.isHidden = false
        exportLabel.stringValue = "creating preview"
        DispatchQueue.global(qos: .userInteractive).async {
            result = self.makeWallpaper(image: img, recipeFn: groupToRecipeFn(grp, a1, a2), width: 600, height: h, repLength: Int(rl), origin: self.wp.options.origin, scale: s, rotation: self.wp.options.rotation, morphing: self.wp.options.morphing)
            DispatchQueue.main.async {
                self.wallpaperImage.image = bitmapToImage(result!)
                DispatchQueue.main.async {
                    self.exportProgress.stopAnimation(self)
                    self.exportProgress.isHidden = true
                    self.exportLabel.isHidden = true
                }
            }
        }
    }
        
    @IBAction func changeFiletype(_ sender: NSPopUpButton) {
        switch sender.titleOfSelectedItem {
        case "PNG": savePanel.allowedFileTypes = ["png"]
        case "JPEG": savePanel.allowedFileTypes = ["jpg"]
        case "TIFF": savePanel.allowedFileTypes = ["tiff"]
        default: savePanel.allowedFileTypes = ["png"]
        }
    }
    
    @IBAction func pressExport(_ sender: Any) {
        self.view.window?.makeFirstResponder(self.view.window?.contentView)
        var topLevelObjects : NSArray?
        guard let grpString = group.titleOfSelectedItem else {return}
        guard let grp = Group(rawValue: grpString) else {return}
        guard let img = wheel.image else {return}
        let a1 = wp.param1 > 0 ? wp.param1 : 1
        let a2 = wp.param2 > 0 ? wp.param2 : 1
        let rl = wp.options.repLength > 0 ? wp.options.repLength : 100
        let s = wp.options.scale != 0 ? wp.options.scale : 1.0
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
                result = self.makeWallpaper(image: img, recipeFn: groupToRecipeFn(grp, a1, a2), width: self.exportWidth!, height: self.exportHeight!, repLength: Int(rl), origin: self.wp.options.origin, scale: s, rotation: self.wp.options.rotation, morphing: self.wp.options.morphing)
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
    
    func makeWallpaper(image: NSImage, recipeFn: ([Coef]) -> Recipe, width: Int, height: Int, repLength: Int, origin: Complex, scale: Double, rotation: Double, morphing: Bool) -> NSBitmapImageRep {
        let opts = Options(width: width, height: height, repLength: repLength, origin: origin, scale: scale, rotation: Double.pi * rotation / 180, morphing: morphing)
        return wallpaper(options: opts, recipeFn: recipeFn, coefs: Array(wp.terms[0..<wp.numOfTerms]), nsImage: image)
    }
    
    func preProcessImage() {
        guard let pString = preprocessMenu.titleOfSelectedItem else {return}
        guard let process = Preprocess(rawValue: pString) else {return}
        let preprocess = preprocessToFunc(process)
        var result = NSImage()
        exportProgress.isHidden = false
        exportProgress.startAnimation(self)
        exportLabel.isHidden = false
        exportLabel.stringValue = "preprocessing color wheel"
        DispatchQueue.global(qos: .userInteractive).async {
            result = bitmapToImage(toNSBitmapImageRep(preprocess(self.originalImage)))
            DispatchQueue.main.async {
                self.wheel.image = result
                DispatchQueue.main.async {
                    self.exportProgress.stopAnimation(self)
                    self.exportProgress.isHidden = true
                    self.exportLabel.isHidden = true
                }
            }
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        showCoef(1)
        let g = Group.allCases.map {$0.rawValue}
        group.addItems(withTitles: g)
        let p = Preprocess.allCases.map {$0.rawValue}
        preprocessMenu.addItems(withTitles: p)
    }
    
    override func viewWillAppear() {
        wp = document.wallpaperModel
        updateUI()
    }
    
}

func preprocessToFunc(_ p: Preprocess) -> (RGBAimage) -> RGBAimage {
    switch p {
    case .plain: return plain
    case .flipVertical: return flipVertical
    case .flipHorizontal: return flipHorizontal
    case .flipBoth: return flipBoth
    case .invertImage: return invertImage
    case .grayscale: return grayscale
    case .antiSymmVertical: return antiSymmVertical
    case .antiSymmHorizontal: return antiSymmHorizontal
    }
}


