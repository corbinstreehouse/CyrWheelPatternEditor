//
//  CDWheelConnectionViewController.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 11/19/15 .
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa
import CoreBluetooth

extension CDWheelCommand {
    public init(_ rawValue: Int) {
        self.init(UInt32(rawValue))
    }
}

class CDWheelConnectionViewController: NSViewController, CBCentralManagerDelegate, CDWheelConnectionDelegate, NSTableViewDelegate, NSTableViewDataSource {

    lazy var centralManager: CBCentralManager = CBCentralManager(delegate: self, queue: nil)
    dynamic var connectedWheel: CDWheelConnection? = nil {
        didSet {
            _updateConnectButtonTitle()
        }
    }
    lazy var _discoveredPeripherals: [CBPeripheral] = []
    dynamic var lastConnectedWheelUUID: NSUUID? = nil {
        didSet {
//            self.invalidateRestorableState()
        }
    }
    
    @IBOutlet weak var _sequencesTableView: NSTableView!
    
    // state restoration
    override class func restorableStateKeyPaths() -> [String] {
        var result = super.restorableStateKeyPaths()
        result.append("lastConnectedWheelUUID")
        return result
    }
//    override func encodeRestorableStateWithCoder(coder: NSCoder) {
//        super.encodeRestorableStateWithCoder(coder);
//    }
//    
//    override func restoreStateWithCoder(coder: NSCoder) {
//        super.restoreStateWithCoder(coder)
//    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewWillAppear() {
        checkBluetoothState()
    }
    
    dynamic var isConnectingToWheel: Bool {
        get {
            if connectedWheel != nil {
                return connectedWheel!.peripheral.state == .Connecting
            } else {
                // maybe return state of the bluetooth
                return false;
            }
        }
        set {
            // dummy setter for KVO
        }
    }
    
    func _updateIsConnectingToWheel() {
        isConnectingToWheel = true; // ignored... pings KVO
    }
    
    // properties for bindings to UI
    dynamic var managerStateDescription: String = ""
    dynamic var cyrWheelName: String = "Unknown Cyr Wheel"
    dynamic var scanButtonEnabled: Bool
    {
        get {
            if centralManager.state == .PoweredOn {
                if connectedWheel != nil {
                    return connectedWheel!.peripheral.state != .Connecting
                } else {
                    return true
                }
            } else {
                return false;
            }
        }
        set {
            // does nothing, but for writing to signal it changed.
        }
    }
    
    // actually, I don't like this style...I need two buttons
    dynamic var connectButtonTitle: String {
        get {
            if connectedWheel == nil {
                return "Connect..."
            } else {
                switch (connectedWheel!.peripheral.state) {
                case .Connecting:
                    return "Disconnect" // We do the same action
                case .Connected:
                    return "Disconnect"
                case .Disconnected:
                    return "Reconnect"
                }
            }
        }
        set {
            
        }
    }
    
    func _updateConnectButtonTitle() {
        connectButtonTitle = "" // fires KVC
    }
    
    
    override class func keyPathsForValuesAffectingValueForKey(key: String) -> Set<String> {
        if key == "connectButtonTitle" || key == "isConnectingToWheel" {
            return ["connectedWheel", "connectedWheel.peripheral.state"]
        } else if key == "scanButtonEnabled" {
            return ["centralManager.state", "isConnectingToWheel"]
        } else {
            return super.keyPathsForValuesAffectingValueForKey(key)
        }
    }
    
    var _wheelChooserViewController: CDWheelConnectionChooserViewController?
    
    func startScanning() {
        // TODO: limit the peripherals when I have a UUID
        centralManager.scanForPeripheralsWithServices([], options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    func startConnectionToPeripheral(peripheral: CBPeripheral) {
        self.centralManager.connectPeripheral(peripheral, options: nil)
    }
    
    func showConnectionChooser() {
        // Start the sheet to choose a periperal..ideally the code to bind things together shouldn't be here, but it is hard to seperate the delegate for the manager to provide just the items
        let localWheelChooserViewController: CDWheelConnectionChooserViewController = self.storyboard!.instantiateControllerWithIdentifier("CDWheelConnectionChooserViewController") as! CDWheelConnectionChooserViewController
        localWheelChooserViewController.discoveredPeripherals = _discoveredPeripherals
        localWheelChooserViewController.scanning = true
        self.addChildViewController(localWheelChooserViewController)
        let sheetWindow: NSWindow = NSWindow(contentViewController: localWheelChooserViewController)
        sheetWindow.setFrameAutosaveName("ConnnectionChooserWindow")
        
        // Keep track of it so we can update it when the peripherals change
        _wheelChooserViewController = localWheelChooserViewController
        self.view.window?.beginSheet(sheetWindow, completionHandler: { (sheetResult: NSModalResponse) -> Void in
            if sheetResult == NSModalResponseOK {
                // Connect to the selected wheel
                self.connectedWheel = nil
                let peripheral = localWheelChooserViewController.selectedPeripheral!
                self.startConnectionToPeripheral(peripheral)
            }
            localWheelChooserViewController.removeFromParentViewController()
            self._wheelChooserViewController = nil
        })
    }
    
    // Target/actions...
    @IBAction func bntStartConnectionClicked(sender: AnyObject) {
        if let peripheral: CBPeripheral = connectedWheel?.peripheral {
            switch (peripheral.state) {
            case .Connecting:
                centralManager.cancelPeripheralConnection(peripheral)
            case .Connected:
                centralManager.cancelPeripheralConnection(peripheral)
            case .Disconnected:
                startConnectionToPeripheral(peripheral)
            }
        } else {
            startScanning()
            showConnectionChooser()
        }
    }
    
    @IBAction func btnCommandClicked(sender: NSButton) {
        connectedWheel?.sendCommand(CDWheelCommand(sender.tag));
    }
    
    @IBAction func menuCommandClicked(sender: NSMenuItem) {
        connectedWheel?.sendCommand(CDWheelCommand(sender.tag));
    }
    

    private func _doAddWithOpenPanel() {
        let openPanel = NSOpenPanel()
        openPanel.title = "Select a pattern sequence"
        openPanel.allowedFileTypes = [gPatternFilenameExtension]
        openPanel.allowsOtherFileTypes = false
        openPanel.beginWithCompletionHandler { (result: Int) -> Void in
            if result == NSModalResponseOK {
                openPanel.orderOut(self)
                self.connectedWheel?.uploadPatternItemWithURL(openPanel.URL!, progressHandler: { (progress, error) -> Void in
                    
                })
            }
        }
        
    }

    private func _doRemoveSelectedRows() {
        _removeSequencesAtIndexes(_sequencesTableView.selectedRowIndexes)
    }


    @IBAction func btnAddSequenceClicked(sender: NSButton) {
        _doAddWithOpenPanel()
    }
    
    
    @IBAction func btnRemoveSelectedSequencesClicked(sender: NSButton) {
        _doRemoveSelectedRows()
    }
    
    func checkBluetoothState() {
        let state: CBCentralManagerState = centralManager.state;
        
        switch (state) {
        case .Unsupported:
            managerStateDescription = "Bluetooth LE is not supported by this machine"
        case .PoweredOff:
            managerStateDescription = "Bluetooth LE is not powered on"
        case .Resetting:
            managerStateDescription = "Bluetooth LE is resetting"
        case .Unauthorized:
            managerStateDescription = "This application is not authorized to use Bluetooth LE"
        case .Unknown:
            managerStateDescription = "Bluetooth LE in an unknown state"
        case .PoweredOn:
            managerStateDescription = ""
        }
        let poweredOn = state == .PoweredOn
        _wheelChooserViewController?.scanning = poweredOn
        scanButtonEnabled = poweredOn
        
        if poweredOn {
            connectToWheelOrStartScanning()
        }

    }
    
    func connectToWheelOrStartScanning() {
        startScanning()
        // Attempt to do stuff once we are powered on..
        if connectedWheel == nil && lastConnectedWheelUUID == nil {
            showConnectionChooser()
        } else {
            // We will wait until we reconnect to this wheel...
        }
    }
    
    
    // CBCentralManagerDelegate delegate methods
    func centralManagerDidUpdateState(central: CBCentralManager) {
        checkBluetoothState()
    }
    
    func centralManager(central: CBCentralManager, didRetrievePeripherals peripherals: [CBPeripheral]) {
        print("didRetrieve peripherals: %@", peripherals)
    }

    func centralManager(central: CBCentralManager, didDiscoverPeripheral peripheral: CBPeripheral, advertisementData: [String : AnyObject], RSSI: NSNumber) {
        if !_discoveredPeripherals.contains(peripheral) {
            _discoveredPeripherals.append(peripheral)
            if _wheelChooserViewController == nil {
                if lastConnectedWheelUUID == peripheral.identifier {
                    // autoconnect to the last one..
                    self.startConnectionToPeripheral(peripheral)
                }
            } else {
                _wheelChooserViewController!.addPeripheral(peripheral)
            }
        }
    }
    
    func centralManager(central: CBCentralManager, didConnectPeripheral peripheral: CBPeripheral) {
        print("didConnect to ", peripheral)
        if connectedWheel == nil {
            connectedWheel = CDWheelConnection(peripheral: peripheral);
            connectedWheel!.delegate = self;
            lastConnectedWheelUUID = peripheral.identifier
        } else if connectedWheel?.peripheral == peripheral {
            _updateIsConnectingToWheel();
        }
        
        // Stop scanning once we are connected to something
        centralManager.stopScan()
    }
    
    func centralManager(central: CBCentralManager, didFailToConnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        let alert = NSAlert()
        if let actualError: NSError = error {
            alert.messageText = actualError.localizedDescription
            if actualError.localizedFailureReason != nil {
                alert.informativeText = actualError.localizedFailureReason!
            }
        } else {
            alert.messageText = "Failed to connect to wheel"
        }
        alert.addButtonWithTitle("OK")
        alert.beginSheetModalForWindow(self.view.window!, completionHandler: nil)
    }
    
    func centralManager(central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: NSError?) {
        print("did disconnect ", peripheral)
        // Don't drop the connectedWheel so we can reconnect easily, but update our state
        if peripheral == connectedWheel?.peripheral {
            _updateConnectButtonTitle();
        }
    }

    // complete reload or new values
    func wheelConnection(wheelConnection: CDWheelConnection, didChangeSequenceFilenames filenmames: [String]) {
        _sequencesTableView.reloadData()
    }
    
//    func wheelConnection(wheelConnection: CDWheelConnection, didAddFilenames filenmames: String, atIndexes indexesAdded: NSIndexSet) {
//        _sequencesTableView.insertRowsAtIndexes(indexesAdded, withAnimation: NSTableViewAnimationOptions.EffectFade)
//    }
//    
//    func wheelConnection(wheelConnection: CDWheelConnection, didRemoveFilenamesAtIndexes indexesRemoved: NSIndexSet) {
//        _sequencesTableView.removeRowsAtIndexes(indexesRemoved, withAnimation: NSTableViewAnimationOptions.EffectFade)
//
//    }

    func numberOfRowsInTableView(tableView: NSTableView) -> Int {
        if let wheel = connectedWheel {
            return wheel.sequenceFilenames.count
        } else {
            return 0;
        }
    }
    
    func tableView(tableView: NSTableView, viewForTableColumn tableColumn: NSTableColumn?, row: Int) -> NSView? {
        let cellView = tableView.makeViewWithIdentifier(tableColumn!.identifier, owner: nil) as! NSTableCellView
        cellView.textField!.stringValue = connectedWheel!.sequenceFilenames[row]
        return cellView
    }
    
    func _removeSequencesAtIndexes(indexes: NSIndexSet) {
        // TODO: Remove them right away from our visual representation. If we failed to really remove them, we add them back in..
        connectedWheel?.deleteFilenamesAtIndexes(indexes, didCompleteHandler: { (succeeded: Bool) -> Void in
            if (succeeded) {
                self._sequencesTableView.removeRowsAtIndexes(indexes, withAnimation: NSTableViewAnimationOptions.EffectFade)
            } else {
                // TODO: present some error..
            }
        })
    }

    // row actions from the sequences table
    @IBAction func btnStartSequenceClicked(sender: NSButton) {
        assert(false, "impl");
    }
    
    
    @IBAction func btnRemoveSequenceClicked(sender: NSButton) {
        let row = _sequencesTableView.rowForView(sender)
        if row != -1 {
            _removeSequencesAtIndexes(NSIndexSet(index: row))
        }
    }
    
}
