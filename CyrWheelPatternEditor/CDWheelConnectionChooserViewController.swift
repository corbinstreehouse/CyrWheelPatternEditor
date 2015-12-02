//
//  CDWheelConnectionChooserViewController.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 11/21/15 .
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa
import CoreBluetooth

class CDWheelConnectionChooserViewController: NSViewController, NSTableViewDelegate, NSTableViewDataSource {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.wantsLayer = true
        _spinnerView.layerContentsRedrawPolicy = NSViewLayerContentsRedrawPolicy.Never
        _spinnerView.layerContentsPlacement = NSViewLayerContentsPlacement.ScaleProportionallyToFit
        
        // All this to get a spinning layer!
        let parentLayer = _spinnerView.layer!
        let spinnerLayer = CALayer()
        
        spinnerLayer.position = CGPointMake(0.5, 0.5)
        spinnerLayer.contentsScale = parentLayer.contentsScale
        spinnerLayer.frame = parentLayer.bounds
        spinnerLayer.contentsGravity = kCAGravityResizeAspect
//        spinnerLayer.backgroundColor = NSColor.redColor().CGColor
        
        // http://uxrepo.com/icon/spinner5-by-icomoon#

        // Maintain the same aspect ratio
        var imageSize = _spinnerView.bounds.size
        
        imageSize.width = min(imageSize.width, imageSize.height)
        imageSize.height = imageSize.width;
        spinnerLayer.contents = NSImage(size: imageSize, flipped: false, drawingHandler: { (frame) -> Bool in
            let image = NSImage(named: "spinner2")!
            image.drawInRect(frame)
            return true
        })
        
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.duration = 2.0
        animation.fromValue = NSNumber(double: 0.0)
        animation.toValue = NSNumber(double: -1*2.0*M_PI)
        animation.cumulative = true
        animation.repeatCount = Float.infinity
        spinnerLayer.addAnimation(animation, forKey: "rotationAnimation")
        
        parentLayer.addSublayer(spinnerLayer)
        
    }
    
    func _setupScanningTextFieldFadeAnimation() {
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.duration = 1.0
        animation.fromValue = NSNumber(double: 0.0)
        animation.toValue = NSNumber(double: 1.0)
        animation.autoreverses = true
        animation.repeatCount = Float.infinity
        
        _scanningTextField.layer!.addAnimation(animation, forKey: "fadeAnimation")
    }
    
    override func viewDidAppear() {
        if wheelSelectTableView.numberOfRows > 0 &&  wheelSelectTableView.selectedRow == -1 {
            wheelSelectTableView.selectRowIndexes(NSIndexSet(index: 0), byExtendingSelection: false)
        }
        _scanningTextField.hidden = discoveredPeripherals.count > 0
        _setupScanningTextFieldFadeAnimation()
    }
    
    @IBOutlet weak var wheelSelectTableView: NSTableView!
    @IBOutlet weak var _spinnerView: NSView!
    @IBOutlet weak var _scanningTextField: NSTextField!
    
    // Bindings
    dynamic var validSelection: Bool = false
    internal dynamic var scanning: Bool = false;
    
    @IBAction func btnConnectClicked(sender: AnyObject) {
        let sheet = self.view.window!
        sheet.sheetParent?.endSheet(sheet, returnCode: NSModalResponseOK)
    }
    
    func cancel(sender: AnyObject?) {
        let sheet = self.view.window!
        sheet.sheetParent?.endSheet(sheet, returnCode: NSModalResponseCancel)
    }

    internal var discoveredPeripherals: [CBPeripheral] = []
//        {
//        didSet {
//            wheelSelectTableView?.reloadData()
//        }
//    }
    
    internal func addPeripheral(peripheral: CBPeripheral) {
        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)
            wheelSelectTableView.insertRowsAtIndexes(NSIndexSet(index: discoveredPeripherals.count - 1), withAnimation: [NSTableViewAnimationOptions.EffectFade])
            // select the first row if nothing is selected
            if wheelSelectTableView.selectedRow == -1 {
                wheelSelectTableView.selectRowIndexes(NSIndexSet(index: 0), byExtendingSelection: false)
            }
            _scanningTextField.hidden = discoveredPeripherals.count > 0
        }
    }
    
    internal func removePeripheral(peripheral: CBPeripheral) {
        if let index = discoveredPeripherals.indexOf(peripheral) {
            discoveredPeripherals.removeAtIndex(index)
            wheelSelectTableView.removeRowsAtIndexes(NSIndexSet(index: index), withAnimation: [NSTableViewAnimationOptions.EffectFade])
            _scanningTextField.hidden = discoveredPeripherals.count > 0
        }
        
    }

    internal var selectedPeripheral: CBPeripheral? {
        get {
            let row = wheelSelectTableView.selectedRow
            if row != -1 {
                return discoveredPeripherals[row]
            } else {
                return nil
            }
        }
    }
    
    // table view delegate/datsource
    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        return discoveredPeripherals.count
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let result: NSTableCellView = tableView.makeViewWithIdentifier(tableColumn!.identifier, owner: nil) as! NSTableCellView
        let name = discoveredPeripherals[row].name;
        result.textField?.stringValue = name != nil ? name! : "Unknown"
        return result;
    }

    func tableViewSelectionDidChange(notification: NSNotification) {
        validSelection = wheelSelectTableView.selectedRow != -1
    }

    
}
