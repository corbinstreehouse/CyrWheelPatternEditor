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
        self.init(Int16(rawValue))
    }
}


protocol CDWheelConnectionPresenter {
    var connectedWheel: CDWheelConnection? { get set }
}

protocol CDWheelConnectionSequencesPresenter {
    var customSequences: [String] { get set }
}

class CDWheelConnectionViewController: NSViewController, CBCentralManagerDelegate, CDWheelConnectionPresenter, CDPatternItemHeaderWrapperChanged {

    lazy var centralManager: CBCentralManager = CBCentralManager(delegate: self, queue: nil)
    
    dynamic var connectedWheel: CDWheelConnection? = nil {
        didSet {
            _updatePlayButton()
            _pushConnectedWheelToChildren()
            _updateCurrentPatternItem()
            _pushSequencesToChildren()
        }
    }
    lazy var _discoveredPeripherals: [CBPeripheral] = []
    dynamic var lastConnectedWheelUUID: UUID? = nil {
        didSet {
//            self.invalidateRestorableState()
        }
    }

    // outlets
    @IBOutlet weak var _titleTextField: NSTextField!
    @IBOutlet weak var _brightnessContainerView: NSView!
    @IBOutlet weak var _brightnessMenuItem: NSMenuItem!
    @IBOutlet weak var _playButton: CDRolloverButton!

    @IBOutlet weak var _middleBox: NSBox!
    
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
        _brightnessMenuItem.view = _brightnessContainerView
        // The title color for the placeholder is terrible with bindings... control it
        let placeHolderAttributes =  [NSForegroundColorAttributeName : _titleTextField.textColor!]
        _titleTextField.placeholderAttributedString = NSAttributedString(string: "Connecting...", attributes: placeHolderAttributes)
        _middleBox.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
        _updatePlayButton()
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        checkBluetoothState()
    }
    
    override func viewWillDisappear() {
        super.viewWillDisappear()
        centralManager.delegate = nil // drop our ref to us so we don't do anything...
        _disconnectFromWheel();
    }
    
    dynamic var isConnectingToWheel: Bool {
        get {
            if connectedWheel != nil {
                return connectedWheel!.peripheral.state == .connecting
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
    dynamic var scanButtonEnabled: Bool
    {
        get {
            if centralManager.state == .poweredOn {
                if connectedWheel != nil {
                    return connectedWheel!.peripheral.state != .connecting
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
    
    override class func keyPathsForValuesAffectingValue(forKey key: String) -> Set<String> {
        if key == "isConnectingToWheel" {
            return ["connectedWheel", "connectedWheel.peripheral.state"]
        } else if key == "scanButtonEnabled" {
            return ["centralManager.state", "isConnectingToWheel"]
        } else {
            return super.keyPathsForValuesAffectingValue(forKey: key)
        }
    }
    
    var _wheelChooserViewController: CDWheelConnectionChooserViewController?
    
    func startScanning() {
        let services = [CBUUID(string: kLEDWheelServiceUUID)]
        centralManager.scanForPeripherals(withServices: services, options: [CBCentralManagerScanOptionAllowDuplicatesKey: false])
    }
    
    func startConnectionToPeripheral(_ peripheral: CBPeripheral) {
        self.centralManager.connect(peripheral, options: nil)
    }
    
    func showConnectionChooser() {
        // Start the sheet to choose a periperal..ideally the code to bind things together shouldn't be here, but it is hard to seperate the delegate for the manager to provide just the items
        let localWheelChooserViewController: CDWheelConnectionChooserViewController = self.storyboard!.instantiateController(withIdentifier: "CDWheelConnectionChooserViewController") as! CDWheelConnectionChooserViewController
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
    
    
    @IBOutlet weak var _mnuItemConnect: NSMenuItem!
    @IBOutlet weak var _menuItemDisconnect: NSMenuItem!
    
    @IBAction func _mnuConnectClicked(_ sender: AnyObject) {
        startScanning()
        showConnectionChooser()
    }
    
    func _disconnectFromWheel() {
        if let peripheral: CBPeripheral = connectedWheel?.peripheral {
            centralManager.cancelPeripheralConnection(peripheral)
            connectedWheel = nil
        }
    }
    
    @IBAction func _mnuDisconnectClicked(_ sender: AnyObject) {
        _disconnectFromWheel();
    }
    
    override func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        if menuItem == _mnuItemConnect {
            return true; // maybe limit...
        } else if menuItem == _menuItemDisconnect {
            if let peripheral: CBPeripheral = connectedWheel?.peripheral {
                if peripheral.state != .disconnected {
                    return true
                }
            }
            return false;
        }
        // super doesn't implement this..
        return true;
    }

    @IBAction func bntStartConnectionClicked(_ sender: AnyObject) {
        if let peripheral: CBPeripheral = connectedWheel?.peripheral {
            switch (peripheral.state) {
            case .connecting:
                centralManager.cancelPeripheralConnection(peripheral)
            case .connected:
                centralManager.cancelPeripheralConnection(peripheral)
            case .disconnected:
                startConnectionToPeripheral(peripheral)
            case .disconnecting:
                print("disconnecting")
                 // corbin?
            }
        } else {
            startScanning()
            showConnectionChooser()
        }
    }
    
    @IBAction func btnPlayClicked(_ sender: AnyObject) {
        if let connectedWheel = connectedWheel {
            // Is it playing? then pause
            var wheelState: CDWheelState = connectedWheel.wheelState
            if (wheelState & CDWheelStatePlaying) == CDWheelStatePlaying {
                connectedWheel.sendCommand(CDWheelCommandPause);
                wheelState = wheelState & ~CDWheelStatePlaying
            } else {
                connectedWheel.sendCommand(CDWheelCommandPlay);
                wheelState = wheelState | CDWheelStatePlaying
            }
            // Assume it worked so we update the UI right away
            _updatePlayButtonWithState(wheelState)
        }
    }
    
    @IBAction func btnCommandClicked(_ sender: NSButton) {
        connectedWheel?.sendCommand(CDWheelCommand(sender.tag));
    }
    
    @IBAction func menuOrentationStreamingClicked(_ sender: AnyObject!) {
        if let wheel = connectedWheel {
            if wheel.isStreamingOrentationData {
                wheel.endOrientationStreaming()
            } else {
                let url = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
                let dataURL = url.appendingPathComponent("OrientationData.csv", isDirectory: false)
                // Create the file empty if it doesn't exist
                let fileManager = FileManager.default
                if !fileManager.fileExists(atPath: dataURL.path) {
                    fileManager.createFile(atPath: dataURL.path, contents: nil, attributes: [:])
                }

                wheel.startOrientationStreamingToURL(dataURL)
                NSWorkspace.shared().selectFile(dataURL.path, inFileViewerRootedAtPath: "")
            }
        }
    }
    
    @IBAction func menuCommandClicked(_ sender: NSMenuItem) {
        connectedWheel?.sendCommand(CDWheelCommand(sender.tag));
    }
    
    func checkBluetoothState() {
        let state = centralManager.state;
        
        switch (state) {
        case .unsupported:
            managerStateDescription = "Bluetooth LE is not supported by this machine"
        case .poweredOff:
            managerStateDescription = "Bluetooth LE is not powered on"
        case .resetting:
            managerStateDescription = "Bluetooth LE is resetting"
        case .unauthorized:
            managerStateDescription = "This application is not authorized to use Bluetooth LE"
        case .unknown:
            managerStateDescription = "Bluetooth LE in an unknown state"
        case .poweredOn:
            managerStateDescription = ""
        }
        let poweredOn = state == .poweredOn
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
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        checkBluetoothState()
    }
    
    func centralManager(_ central: CBCentralManager, didRetrievePeripherals peripherals: [CBPeripheral]) {
        print("didRetrieve peripherals: %@", peripherals)
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
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
    
    override func addChildViewController(_ childViewController: NSViewController) {
        super.addChildViewController(childViewController)
        _pushConnectedWheelToChildren()
    }

    fileprivate func _pushConnectedWheelToChildrenFromViewController(_ viewController: NSViewController) {
        if var presenter = viewController as? CDWheelConnectionPresenter {
            presenter.connectedWheel = connectedWheel
        }
        for child in viewController.childViewControllers {
            _pushConnectedWheelToChildrenFromViewController(child)
        }
    }
    
    fileprivate func _pushConnectedWheelToChildren() {
        for child in self.childViewControllers {
            _pushConnectedWheelToChildrenFromViewController(child)
        }
    }
    
    fileprivate func _pushSequencesChangeFromViewController(_ viewController: NSViewController, customSequences: [String]) {
        if var presenter = viewController as? CDWheelConnectionSequencesPresenter {
            presenter.customSequences = customSequences
        }
        for child in viewController.childViewControllers {
            _pushSequencesChangeFromViewController(child, customSequences: customSequences)
        }
    }
    
    fileprivate func _pushSequencesToChildren() {
        let sequences = (connectedWheel != nil) ? connectedWheel!.customSequences : []
        for child in self.childViewControllers {
            _pushSequencesChangeFromViewController(child, customSequences: sequences)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        if connectedWheel == nil {
            connectedWheel = CDWheelConnection(peripheral: peripheral);
            connectedWheel!.delegate = self;
            lastConnectedWheelUUID = peripheral.identifier
        } else if connectedWheel?.peripheral == peripheral {
            _updateIsConnectingToWheel();
            _updatePlayButton() // Refresh that state too
        }
        
        // Stop scanning once we are connected to something
        centralManager.stopScan()
        _discoveredPeripherals = []; // drop whatever we found
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        let alert = NSAlert()
        if let actualError: NSError = error as NSError? {
            alert.messageText = actualError.localizedDescription
            if actualError.localizedFailureReason != nil {
                alert.informativeText = actualError.localizedFailureReason!
            }
        } else {
            alert.messageText = "Failed to connect to wheel"
        }
        alert.addButton(withTitle: "OK")
        alert.beginSheetModal(for: self.view.window!, completionHandler: nil)
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("did disconnect ", peripheral)
        startScanning()
        // Don't drop the connectedWheel so we can reconnect easily, but update our state
        if peripheral == connectedWheel?.peripheral {
            connectedWheel = nil
        }
    }
    
    
    // For bindings
    dynamic var currentPatternItem: CDPatternItemHeaderWrapper?
    fileprivate func _updateCurrentPatternItem() {
        if let patternItem = connectedWheel?.currentPatternItem {
            self.currentPatternItem = CDPatternItemHeaderWrapper(patternItemHeader: patternItem, patternItemFilename: connectedWheel?.currentPatternItemFilename, patternSequenceFilename: connectedWheel?.currentPatternSequenceFilename, delegate: self)
        } else {
            self.currentPatternItem = nil
        }
    }
    
    func patternItemSpeedChanged(_ item: CDPatternItemHeaderWrapper) {
        connectedWheel?.setCurrentPatternDuration(CDPatternDurationForPatternSpeed(item.speed, item.patternType))
    }
    
    func patternItemColorChanged(_ item: CDPatternItemHeaderWrapper) {
        let encodedColor = CDEncodedColorTransformer.int(from: item.color)
        connectedWheel?.setCurrentPatternColor(UInt32(encodedColor))
    }
    
    func patternItemVelocityBasedBrightnessChanged(_ item: CDPatternItemHeaderWrapper) {
        connectedWheel?.setCurrentPatternBrightnessByRotationalVelocity(item.velocityBasedBrightness)
    }
    
    func patternItemBitmapOptionsChanged(_ item: CDPatternItemHeaderWrapper) {
        connectedWheel?.setCurrentBitmapPatternOptions(item.bitmapPatternOptions)
    }
    
    fileprivate dynamic var _playButtonEnabled = false;
    fileprivate dynamic var _nextPatternEnabled = false;
    fileprivate dynamic var _priorPatternEnabled = false;
    fileprivate dynamic var _nextSequenceEnabled = false;
    fileprivate dynamic var _priorSequenceEnabled = false;
    
    func _updatePlayButtonWithState(_ wheelState: CDWheelState) {
        // When paused, show Play, and when playing show Paused
        if (wheelState & CDWheelStatePlaying) == CDWheelStatePlaying {
            _playButton.image = NSImage(named: "pause")
        } else {
            _playButton.image = NSImage(named: "play")
        }
        
        // Update the enabled state of the other buttons
        if connectedWheel != nil  {
            _playButtonEnabled = true
            _nextPatternEnabled = (wheelState & CDWheelStateNextPatternAvailable) != 0
            _priorPatternEnabled = (wheelState & CDWheelStatePriorPatternAvailable) != 0
            _nextSequenceEnabled = (wheelState & CDWheelStateNextSequenceAvailable) != 0
            _priorSequenceEnabled = (wheelState & CDWheelStatePriorSequenceAvailable) != 0
        } else {
            _playButtonEnabled = false
            _nextPatternEnabled = false
            _priorPatternEnabled = false
            _nextSequenceEnabled = false
            _priorSequenceEnabled = false
        }

    }
    
    func _updatePlayButton() {
        if let connectedWheel = connectedWheel {
            _updatePlayButtonWithState(connectedWheel.wheelState)
        } else {
            _updatePlayButtonWithState(0)
        }
    }
    
    
    func _updateUploadProgressAmount(_ uploadProgressAmount: Float, finished: Bool, error: NSError?) {
        print("\(uploadProgressAmount) - \(finished)");
    }

}

extension CDWheelConnectionViewController: CDWheelConnectionDelegate {
    func wheelConnection(_ wheelConnection: CDWheelConnection, didChangeState wheelState: CDWheelState) {
        _updatePlayButton();
    }
    
    func wheelConnection(_ wheelConnection: CDWheelConnection, didChangePatternItem patternItem: CDPatternItemHeader?, patternItemFilename: String?) {
        _updateCurrentPatternItem()
    }
    
    func wheelConnection(_ wheelConnection: CDWheelConnection, didChangeSequences customSequences: [String]) {
        _pushSequencesToChildren()
    }
    
    func wheelConnection(_ wheelConnection: CDWheelConnection, uploadProgressAmount: Float, finished: Bool, error: NSError?) {
        _updateUploadProgressAmount(uploadProgressAmount, finished: finished, error: error)
    }
    
    
}
