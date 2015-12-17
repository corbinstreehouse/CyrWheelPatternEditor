//
//  CDWheelConnection.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 11/22/15 .
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa
import CoreBluetooth

protocol CDWheelConnectionDelegate {
    // complete reload or new values
    func wheelConnection(wheelConnection: CDWheelConnection, didChangeSequenceFilenames filenmames: [String])
    func wheelConnection(wheelConnection: CDWheelConnection, didChangeState: CDWheelState)
    // adding values
//    func wheelConnection(wheelConnection: CDWheelConnection, didAddFilenames filenmames: String, atIndexes indexesAdded: NSIndexSet);
    // removing values
//    func wheelConnection(wheelConnection: CDWheelConnection, didRemoveFilenamesAtIndexes indexesRemoved: NSIndexSet);
}

// TODO: Default implementation is to do nothing
//extension CDWheelConnectionDelegate {
//    func numericValueForObject(object: DelegatingObject) -> Int {
//        return 0
//    }
//    func objectShouldDoMoreWork(object: DelegatingObject) -> Bool {
//        return false
//    }	
//}

let gPatternEditorErrorDomain: String = "PatternEditorErrorDomain"
let gPatternFilenameExtension: String = "pat"

class CDWheelConnection: NSObject, CBPeripheralDelegate {
    internal var peripheral: CBPeripheral
    
    private var _cyrWheelService: CBService?
    private var _stateCharacteristic: CBCharacteristic?
    private var _commandCharacteristic: CBCharacteristic?
    private var _getSequencesCharacteristic: CBCharacteristic?
    private var _deleteSequenceCharacteristic: CBCharacteristic?
    private var _brightnessCharacteristic: CBCharacteristic?
    private var _uploadCharacteristic: CBCharacteristic?

    internal var delegate: CDWheelConnectionDelegate?

    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral;
        super.init()
        peripheral.delegate = self;
        
        let services = [CBUUID(string: kLEDWheelServiceUUID)]
        peripheral.discoverServices(services)
        
        if let name = peripheral.name {
            wheelTitle = name
        }
    }
    
    // Internal API

    internal var sequenceFilenames: [String] = []
    
    var wheelState: CDWheelState = CDWheelStatePaused {
        didSet {
            if let d = delegate {
                d.wheelConnection(self, didChangeState: wheelState);
            }
        }
    }
    
    internal var commandEnabled: Bool = false;
    internal func sendCommand(command: CDWheelCommand) {
        if let char = _commandCharacteristic {
            _writeInt16Value(Int16(command.rawValue), forCharacteristic: char);
        }
    }
    
    internal func _makeFilenameFromURL(url: NSURL) -> String {
        // TODO: rework this to have long filenames
        
        let possibleBaseFilename = url.URLByDeletingPathExtension?.lastPathComponent
        var baseFilename: String = possibleBaseFilename != nil ? possibleBaseFilename! : "Untitled"

        // We are limited to 8.3 filenames.. I should make the names prettier...
        if baseFilename.characters.count > 8 {
            // Take the first 8 characters
            let range: Range<String.Index> = Range<String.Index>(start: baseFilename.startIndex.advancedBy(8), end: baseFilename.endIndex)
            baseFilename.removeRange(range)
//            baseFilename = baseFilename!.substringToIndex(baseFilename!.startIndex.advancedBy(8))
        }
        
        
        // Make sure the name is 8.3 syntax and unique
        let possiblePathExtension = url.pathExtension;
        var pathExtension: String = possiblePathExtension != nil ? possiblePathExtension! : gPatternFilenameExtension
        // Just kill long extensions. wrong extensions won't work either..but oh well
        if pathExtension.characters.count > 3 {
            pathExtension = gPatternFilenameExtension
        }
        
        var fullFilename: String = baseFilename + pathExtension
        fullFilename = fullFilename.uppercaseString // ugly, but the filenames on disk are all uppercase
        return fullFilename
    }
    
    
    private var _writeProgressHandler: ((progress: Float, error: NSError?) -> Void)? = nil
    internal func uploadPatternItemWithURL(url: NSURL, progressHandler: ((progress: Float, error: NSError?) -> Void)) {
        let filename: String = _makeFilenameFromURL(url)
        
        if sequenceFilenames.contains(filename) {
            let error = NSError(domain: gPatternEditorErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "A file with the name '\(filename)' already exists. Please choose another file."])
            progressHandler(progress: 1.0, error: error)
            return;
        }
        
        guard let fileData: NSData = NSData(contentsOfURL: url) else {
            let error = NSError(domain: gPatternEditorErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to open the file '\(url)'"])
            progressHandler(progress: 1.0, error: error)
            return
        }
        
        let dataToUpload: NSMutableData = NSMutableData()
        
        // Format of the data: 
        // filename<null terminator>
        // 32-bit size of the data following
        // the file data
        // TODO: CRC???
        var filenameUTF8 = filename.nulTerminatedUTF8
        dataToUpload.appendBytes(&filenameUTF8, length: filenameUTF8.count + 1) // plus one for the null terminator
        
        var sizeValue: UInt32 = UInt32(fileData.length)
        dataToUpload.appendBytes(&sizeValue, length: sizeofValue(sizeValue))
        dataToUpload.appendData(fileData)

        _writeProgressHandler = progressHandler
        // start writing values to it... todo: chunk it up into bits???
        peripheral.writeValue(dataToUpload, forCharacteristic: _uploadCharacteristic!, type: .WithResponse)
    }
    
    
    private var _internalUpdate: Bool = false;
    
    // 0 to 255..ugly..
    // NOTE: this would be perfect as an optional value, and return NIL when it isn't available yet...but I want it to be bindable, so I use -1 for a value of not set
    internal dynamic var brightness: UInt8 = 178 {
        willSet(newBrightness) {
            assert(newBrightness >= 0 && newBrightness <= 255, "Brightness can be from 0 to 255")
        }
        didSet {
            _updateWheelBrightnessIfNeeded()
        }
    }
    
    internal dynamic var brightnessEnabled = false;
    
    dynamic var wheelTitle: String = "Unknown Cyr Wheel" {
        didSet(value) {
            // TODO: update the name on the device..
        }
    }

    
    private func _updateWheelBrightnessIfNeeded() {
        if !_internalUpdate && _brightnessCharacteristic != nil {
            _writeInt8Value(brightness, forCharacteristic: _brightnessCharacteristic!)
        }
    }
    
    private func _getInt16FromData(value: NSData) -> Int16 {
        var resultLittleE = Int16(littleEndian: 0) // Bytes are little Endian
        value.getBytes(&resultLittleE, length: sizeofValue(resultLittleE))
        return resultLittleE.bigEndian // We deal w/big..
    }
    
    private func _updateBrightnessFromData(value: NSData) {
        self.brightnessEnabled = true;
        _internalUpdate = true;
        
        var byteValue: UInt8 = 0; // 8 bit value in a 16 bits..
        value.getBytes(&byteValue, length: sizeofValue(byteValue))
        // convert that to a percentage
//        self.brightness = Float(byteValue) / Float(sizeofValue(byteValue));
        self.brightness = byteValue;
        _internalUpdate = false;
    }

    
    // Private API, delegate implementations, etc.
    
    private func _writeInt8Value(value: UInt8, forCharacteristic characteristic: CBCharacteristic) {
        var val: UInt8 = value
        let data: NSData = NSData(bytes: &val, length: sizeofValue(val))
        peripheral.writeValue(data, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithoutResponse)
    }

    private func _writeInt16Value(value: Int16, forCharacteristic characteristic: CBCharacteristic) {
        var val: Int16 = value.littleEndian
        let data: NSData = NSData(bytes: &val, length: sizeofValue(val))
       // NSLog("writing: %@", data.debugDescription)
        // with our without response works
        peripheral.writeValue(data, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithResponse)
    }
    
// MARK: ---------------------------
// MARK: Peripheral delegate methods
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if peripheral.services == nil {
//            debugPrint("no services found")
            return;
        }
        
        for service: CBService in peripheral.services! {
            debugPrint("found service: ", service.UUID);
            if (service.UUID.isEqual(CBUUID(string: kLEDWheelServiceUUID))) {
                debugPrint("found cyr wheel service!!!!!!!: ");
                _cyrWheelService = service;
                // Request the characteristics right away so we can get values and represent our current state
                peripheral.discoverCharacteristics(nil, forService: service);
            }
        }
    }
    
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        debugPrint("characteristics found for service", service)
        if service.characteristics == nil {
            return;
        }
        for characteristic: CBCharacteristic in service.characteristics! {
            debugPrint("charactaristic", characteristic)
            
            func watchChar() {
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                peripheral.readValueForCharacteristic(characteristic)
            }
            
            let uuid = characteristic.UUID;
            if uuid.isEqual(CBUUID(string: kLEDWheelCharSendCommandUUID)) {
                _commandCharacteristic = characteristic
                commandEnabled = true;
            } else if uuid.isEqual(CBUUID(string: kLEDWheelCharGetSequencesUUID)) {
                _getSequencesCharacteristic = characteristic
                // Request the sequences right when we find the characteristic
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
            } else if (uuid.isEqual(CBUUID(string: kLEDWheelDeleteCharacteristicUUID))) {
                _deleteSequenceCharacteristic = characteristic
            } else if (uuid.isEqual(CBUUID(string: kLEDWheelBrightnessCharacteristicUUID))) {
                _brightnessCharacteristic = characteristic;
                if let data = characteristic.value {
                    _updateBrightnessFromData(data);
                }
                watchChar();
            }  else if (uuid.isEqual(CBUUID(string: kLEDWheelCharGetWheelStateUUID))) {
                _stateCharacteristic = characteristic;
                if let data = characteristic.value {
                    self.wheelState = CDWheelState(_getInt16FromData(data));
                }
                watchChar();
            }
        }
    }
    
    func peripheralDidUpdateName(peripheral: CBPeripheral) {
        if let name = peripheral.name {
            wheelTitle = name
        } else {
            wheelTitle = "Untitled Cyr Wheel"
        }
    }

    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        debugPrint("didWriteValueForCharacteristic", characteristic, error)
        if characteristic == _uploadCharacteristic {
            if let handler = _writeProgressHandler {
                handler(progress: 1.0, error: error)
                _writeProgressHandler = nil
            }
        }
    }

    
    // MARK: ---------------------------

    
    
    
    
    
    private var _sequenceListData: NSMutableData? // Valid when we are loading the data
    private func _addDataToSequenceList(data: NSData?) {
        // Consdier done when we get nil data (or some other marker..)
        let isDone = data == nil
        if !isDone {
            if _sequenceListData == nil {
                _sequenceListData = NSMutableData()
            }
            _sequenceListData!.appendData(data!)
        }
        
        if (isDone) {
            peripheral.setNotifyValue(false, forCharacteristic: _getSequencesCharacteristic!)
            _parseSequenceListData();
        }
        
    }
    
//    public func enumerateObjectsUsingBlock(block: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Void)
    internal func deleteFilenamesAtIndexes(indexes: NSIndexSet, didCompleteHandler: (succeeded: Bool) -> Void) {
        // TODO: what is the limit of the bytes I can send at one time?
        let data: NSMutableData = NSMutableData()
        
        for var index = indexes.firstIndex; index != NSNotFound; index = indexes.indexGreaterThanIndex(index) {
            // Send 16-bit indexes
            var indexAs16Bit: Int16 = Int16(index).littleEndian;
            data.appendBytes(&indexAs16Bit, length: sizeof(Int16))
        }
            
        peripheral.writeValue(data, forCharacteristic: _deleteSequenceCharacteristic!, type: CBCharacteristicWriteType.WithResponse)
    
    }
    
    private func _addSequenceFilename(filename: String) {
        sequenceFilenames.append(filename)
    }
    
    private func _parseSequenceListData() {
        let data = _sequenceListData!
        if let dataAsString = String(data: data, encoding: NSUTF8StringEncoding) {
            var done = false
            repeat {
                if let range = dataAsString.rangeOfCharacterFromSet(NSCharacterSet.newlineCharacterSet()) {
                    let filename = dataAsString.substringToIndex(range.startIndex)
                    _addSequenceFilename(filename)
                } else {
                    done = true
                }
            } while !done;
        }
        
        delegate?.wheelConnection(self, didChangeSequenceFilenames: sequenceFilenames)
        _sequenceListData = nil // done with it
    }
    
    // Sequences loading
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        debugPrint("didUpdateNotify for characteristic: \(stringFromUUID(characteristic.UUID))")
        if (characteristic == _getSequencesCharacteristic) {
            if (characteristic.isNotifying) {
                debugPrint("sequence data read start")
            } else {
                debugPrint("sequence data read end")
            }
        }
    }
    
    func stringFromUUID(uuid: CBUUID) -> String {
        if uuid.isEqual(CBUUID(string: kLEDWheelCharSendCommandUUID)) {
            return "Wheel CommandCharacteristic"
        } else if uuid.isEqual(CBUUID(string: kLEDWheelCharGetSequencesUUID)) {
            return "Get SequencesCharacteristic"
        } else if (uuid.isEqual(CBUUID(string: kLEDWheelDeleteCharacteristicUUID))) {
            return "Delete Characteristic"
        } else if (uuid.isEqual(CBUUID(string: kLEDWheelBrightnessCharacteristicUUID))) {
            return "Brightness Characteristic"
        }  else if (uuid.isEqual(CBUUID(string: kLEDWheelCharGetWheelStateUUID))) {
            return "Get State Characteristic"
        } else {
            return uuid.description
        }
    }

    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if error != nil {
            // TODO: present the error...make sure they aren't piling up
            debugPrint("didUpdateValueForCharacteristic error:\(error)!")
            return;
        }
        
        if characteristic.value != nil {
            let charValueAsString = String(data: characteristic.value!, encoding: NSUTF8StringEncoding)
            debugPrint("didUpdateValueforChar:\(stringFromUUID(characteristic.UUID)) value:\(characteristic.value) charValueAsString: '\(charValueAsString)'")
        }
        
        
        if characteristic == _getSequencesCharacteristic {
            _addDataToSequenceList(characteristic.value)
        } else if (characteristic == _brightnessCharacteristic) {
            if let data = characteristic.value {
                _updateBrightnessFromData(data)
            }
        } else if (characteristic == _stateCharacteristic) {
            if let data = characteristic.value {
                self.wheelState = CDWheelState(_getInt16FromData(data));
            }
        }
    }
    
    
    
    

}
