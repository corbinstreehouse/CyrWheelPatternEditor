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
        _spinnerView.layerContentsRedrawPolicy = NSViewLayerContentsRedrawPolicy.never
        _spinnerView.layerContentsPlacement = NSViewLayerContentsPlacement.scaleProportionallyToFit
        
        // All this to get a spinning layer!
        let parentLayer = _spinnerView.layer!
        let spinnerLayer = CALayer()
        
        spinnerLayer.position = CGPoint(x: 0.5, y: 0.5)
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
            image.draw(in: frame)
            return true
        })
        
        let animation = CABasicAnimation(keyPath: "transform.rotation")
        animation.duration = 2.0
        animation.fromValue = NSNumber(value: 0.0 as Double)
        animation.toValue = NSNumber(value: -1*2.0*M_PI as Double)
        animation.isCumulative = true
        animation.repeatCount = Float.infinity
        spinnerLayer.add(animation, forKey: "rotationAnimation")
        
        parentLayer.addSublayer(spinnerLayer)
        
    }
    
    func _setupScanningTextFieldFadeAnimation() {
        
        let animation = CABasicAnimation(keyPath: "opacity")
        animation.duration = 1.0
        animation.fromValue = NSNumber(value: 0.0 as Double)
        animation.toValue = NSNumber(value: 1.0 as Double)
        animation.autoreverses = true
        animation.repeatCount = Float.infinity
        
        _scanningTextField.layer!.add(animation, forKey: "fadeAnimation")
    }
    
    override func viewDidAppear() {
        if wheelSelectTableView.numberOfRows > 0 &&  wheelSelectTableView.selectedRow == -1 {
            wheelSelectTableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
        }
        _scanningTextField.isHidden = discoveredPeripherals.count > 0
        _setupScanningTextFieldFadeAnimation()
    }
    
    @IBOutlet weak var wheelSelectTableView: NSTableView!
    @IBOutlet weak var _spinnerView: NSView!
    @IBOutlet weak var _scanningTextField: NSTextField!
    
    //MARK: Bindings
    dynamic var validSelection: Bool = false
    internal dynamic var scanning: Bool = false;
    
    //MARK: Target/actions
    @IBAction func btnConnectClicked(_ sender: AnyObject) {
        closeWithOK();
    }
    
    @IBAction func wheelSelectTableDoubleClicked(_ sender: NSTableView) {
        if selectedPeripheral != nil {
            closeWithOK();
        }
    }
    
    func cancel(_ sender: AnyObject?) {
        let sheet = self.view.window!
        sheet.sheetParent?.endSheet(sheet, returnCode: NSModalResponseCancel)
    }
    
    func closeWithOK() {
        let sheet = self.view.window!
        sheet.sheetParent?.endSheet(sheet, returnCode: NSModalResponseOK)
    }
    
    internal var discoveredPeripherals: [CBPeripheral] = []
//        {
//        didSet {
//            wheelSelectTableView?.reloadData()
//        }
//    }
    
    internal func addPeripheral(_ peripheral: CBPeripheral) {
        if !discoveredPeripherals.contains(peripheral) {
            discoveredPeripherals.append(peripheral)
            wheelSelectTableView.insertRows(at: IndexSet(integer: discoveredPeripherals.count - 1), withAnimation: [NSTableViewAnimationOptions.effectFade])
            // select the first row if nothing is selected
            if wheelSelectTableView.selectedRow == -1 {
                wheelSelectTableView.selectRowIndexes(IndexSet(integer: 0), byExtendingSelection: false)
            }
            _scanningTextField.isHidden = discoveredPeripherals.count > 0
        }
    }
    
    internal func removePeripheral(_ peripheral: CBPeripheral) {
        if let index = discoveredPeripherals.index(of: peripheral) {
            discoveredPeripherals.remove(at: index)
            wheelSelectTableView.removeRows(at: IndexSet(integer: index), withAnimation: [NSTableViewAnimationOptions.effectFade])
            _scanningTextField.isHidden = discoveredPeripherals.count > 0
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
    func numberOfRows(in tableView: NSTableView) -> Int {
        return discoveredPeripherals.count
    }
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let result: NSTableCellView = tableView.make(withIdentifier: tableColumn!.identifier, owner: nil) as! NSTableCellView
        let name = discoveredPeripherals[row].name;
        result.textField?.stringValue = name != nil ? name! : "Unknown"
        return result;
    }

    func tableViewSelectionDidChange(_ notification: Notification) {
        validSelection = wheelSelectTableView.selectedRow != -1
    }

    
}
