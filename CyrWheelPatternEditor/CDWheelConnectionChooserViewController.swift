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
        // Do view setup here.
    }
    
    override func viewDidAppear() {
        if wheelSelectTableView.numberOfRows > 0 &&  wheelSelectTableView.selectedRow == -1 {
            wheelSelectTableView.selectRowIndexes(NSIndexSet(index: 0), byExtendingSelection: false)
        }
    }
    
    @IBOutlet weak var wheelSelectTableView: NSTableView!
    
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
        }
    }
    
    internal func removePeripheral(peripheral: CBPeripheral) {
        if let index = discoveredPeripherals.indexOf(peripheral) {
            discoveredPeripherals.removeAtIndex(index)
            wheelSelectTableView.removeRowsAtIndexes(NSIndexSet(index: index), withAnimation: [NSTableViewAnimationOptions.EffectFade])
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
