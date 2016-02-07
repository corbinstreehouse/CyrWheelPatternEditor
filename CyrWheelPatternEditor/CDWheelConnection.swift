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
//    func wheelConnection(wheelConnection: CDWheelConnection, didChangeSequenceFilenames filenmames: [String])
    func wheelConnection(wheelConnection: CDWheelConnection, didChangeState: CDWheelState)
    func wheelConnection(wheelConnection: CDWheelConnection, didChangePatternItem patternItem: CDPatternItemHeader?, patternItemFilename: String?)
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
    private let uartServiceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E") // From AdaFruit's docs
    private let wheelServiceUUID = CBUUID(string: kLEDWheelServiceUUID)
    private let uartTransmitCharacteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E") // Write/transmit characteristic UUID
    private let uartReceiveCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E") // Read/receive (via notify) characteristic UUID
    
    internal var peripheral: CBPeripheral
    
    private var _cyrWheelService: CBService? // do i need to hold onto this??
    private var _stateCharacteristic: CBCharacteristic?
//    private var _commandCharacteristic: CBCharacteristic?
//    private var _getSequencesCharacteristic: CBCharacteristic?
    
//    private var _deleteSequenceCharacteristic: CBCharacteristic?
    private var _brightnessReadCharacteristic: CBCharacteristic?
    
    // uart stuff
    private var _uartTransmitCharacteristic: CBCharacteristic?
    private var _uartRecieveCharacteristic: CBCharacteristic?
    

    internal var delegate: CDWheelConnectionDelegate?

    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral;
        super.init()
        peripheral.delegate = self;
        
        // corbin - scanning for everything with nil
        // We use the wheel service and uart service
        let services = [wheelServiceUUID, uartServiceUUID]
        peripheral.discoverServices(services)
        
        if let name = peripheral.name {
            wheelTitle = name
        }
    }
    
    
    // NULL if not loaded, not set, or not available
    var currentPatternItem: CDPatternItemHeader? {
        didSet {
            delegate?.wheelConnection(self, didChangePatternItem: currentPatternItem, patternItemFilename: currentPatternItemFilename)
        }
    }
    // set before the item..
    var currentPatternItemFilename: String?
    
    // Internal API
    internal var sequenceFilenames: [String] = [] // TODO: remove this..not used anymore..
    
    var wheelState: CDWheelState = CDWheelStatePaused {
        didSet {
            delegate?.wheelConnection(self, didChangeState: wheelState);
        }
    }
    
    // Data sending
    let _dataChunkSize = 20 // I think this is a limit of the peripheral
    private var _dataToSend: NSData? = nil;
    private var _dataOffset: Int = 0;
    private var _nextDataToSend: NSMutableData?
    private var _writeCounter = 0; // for debugging mainly

    // Send the UART data, chunking as necessary, and requesting a response after the last chunk is sent... (maybe?)
    private func _startSendingUARTData(data: NSData) {
        if let transmitChar = _uartTransmitCharacteristic {
            if _dataToSend == nil {
                if data.length <= _dataChunkSize {
                    // All of it goes in one chunk
                    peripheral.writeValue(data, forCharacteristic: transmitChar, type: CBCharacteristicWriteType.WithResponse)
                } else {
                    // Chunk it
                    _dataOffset = 0
                    _writeCounter = 0;
                    _dataToSend = data
                    _sendUARTDataChunk()
                }
            } else {
                // queue the data up...or we drop it?
                if _nextDataToSend == nil {
                    _nextDataToSend = NSMutableData()
                }
                if let nextData = _nextDataToSend {
                    nextData.appendData(data)
                }
            }
        } else {
            // Not yet connected...
        }
    }
    
    private func _doneSendingData() {
        _dataToSend = nil // done
        // If we have more queued data, start it
        if let nextData = _nextDataToSend {
            _startSendingUARTData(nextData)
        }
    }
    
    private func _sendMoreUARTDataIfNeededAfterDelay() {
        guard let data = _dataToSend else { return }
        let nowDataLeft = data.length - _dataOffset;
        if (nowDataLeft > 0) {
            let delay: Int64 = Int64(NSEC_PER_MSEC)*2 // At about 4ns, it starts to get slower on the recieving end.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay), dispatch_get_main_queue(), { () -> Void in
                self._sendUARTDataChunk();
            })
        } else {
            _doneSendingData()
        }
    }
    
    private func _sendUARTDataChunk() {
        guard let data = _dataToSend else { return }
        if let transmitChar = _uartTransmitCharacteristic {
            let dataLeft = data.length - _dataOffset;
            if dataLeft > 0 {
                let amountToSend = min(dataLeft, _dataChunkSize)
                let subData: NSData = data.subdataWithRange(NSMakeRange(_dataOffset, amountToSend))
                _dataOffset += subData.length
                // CBCharacteristicWriteType.WithResponse vs without
                peripheral.writeValue(subData, forCharacteristic: transmitChar, type: CBCharacteristicWriteType.WithoutResponse)
    //            NSLog("write: %d, %d, _dataOffset %d, total: %d", _writeCounter++, amountToSend, _dataOffset, data.length);
                _sendMoreUARTDataIfNeededAfterDelay();
            } else {
                _doneSendingData()
            }
        } else {
            // conneciton dropped while sending data..
            _nextDataToSend = nil // drop the queued datta too
            _doneSendingData()
        }
    }

    private func _writeWheelUARTCommand(uartCommand: CDWheelUARTCommand, with16BitValue rawValueC: Int16? = nil) {
        // Write the command as an 8-bit value..
        var uartCommand: Int8 = uartCommand.rawValue
        // the uartCommand, followed by the value..
        let data: NSMutableData = NSMutableData(bytes: &uartCommand, length: sizeofValue(uartCommand))
        
        if var rawValue: Int16 = rawValueC {
            data.appendBytes(&rawValue, length: sizeofValue(rawValue))
        }
        
        // No response might be faster...but we could ignore *MORE* writes until we get a response to avoid flooding it
        _startSendingUARTData(data)
    }
    
    internal func setDynamicPatternType(patternType: LEDPatternType, color: CRGB, duration: UInt32) {
        // Write the command as an 8-bit value..
        var uartCommand: Int8 = CDWheelUARTCommandPlayProgrammedPattern.rawValue
        // the uartCommand, followed by the value..
        let data: NSMutableData = NSMutableData(bytes: &uartCommand, length: sizeofValue(uartCommand))

        // pattern type
        var rawPatternValue: Int32 = patternType.rawValue
        data.appendBytes(&rawPatternValue, length: sizeofValue(rawPatternValue))

        // duration
        var rawDuration: UInt32 = duration;
        data.appendBytes(&rawDuration, length: sizeofValue(rawDuration))
        
        // color
        var rawColor: CRGB = color
        data.appendBytes(&rawColor, length: sizeofValue(rawColor))
        
        // No response might be faster...but we could ignore *MORE* writes until we get a response to avoid flooding it
        _startSendingUARTData(data)
    }
    
    
    internal func setDynamicImagePattern(filename: String, duration: UInt32) {
        // Write the command as an 8-bit value..
        var uartCommand: Int8 = CDWheelUARTCommandPlayImagePattern.rawValue
        // the uartCommand, followed by the value..
        let data: NSMutableData = NSMutableData(bytes: &uartCommand, length: sizeofValue(uartCommand))
        
        // duration
        var rawDuration: UInt32 = duration;
        data.appendBytes(&rawDuration, length: sizeofValue(rawDuration))
        
        // LEDBitmapPatternOptions
        var rawOptions: LEDBitmapPatternOptions = LEDBitmapPatternOptions()
        assert(sizeofValue(rawOptions) == 4)
        data.appendBytes(&rawOptions, length: sizeofValue(rawOptions))
        
        // Includes NULL term in size (for better or worse)
        let filenameUTF8 = filename.nulTerminatedUTF8
        var sizeValue: UInt32 = UInt32(filenameUTF8.count)
        data.appendBytes(&sizeValue, length: sizeofValue(sizeValue))

        let filenameLength = filenameUTF8.count; // null terminator
        filename.withCString { (p: UnsafePointer<Int8>) in
            // filename, including null terminator
            data.appendBytes(p, length: filenameLength)
        }
        
        // No response might be faster...but we could ignore *MORE* writes until we get a response to avoid flooding it
        _startSendingUARTData(data)
    }
    
    internal var commandEnabled: Bool = false;
    internal func sendCommand(command: CDWheelCommand) {
        // Stupid Adafruit BLE is slow for command reads, so I don't do this...
//        if let char = _commandCharacteristic {
//            _writeInt16Value(Int16(command.rawValue), forCharacteristic: char);
//        }
        
        // Use the UART characteristic to write the value..
        _writeWheelUARTCommand(CDWheelUARTCommandWheelCommand, with16BitValue: command.rawValue);
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
    }
    
    
    private var _internalUpdate: Bool = false;
    
    
    var _brightness: UInt16 = 178;
    // 0 to 255..ugly..
    // NOTE: this would be perfect as an optional value, and return NIL when it isn't available yet...but I want it to be bindable, so I use -1 for a value of not set
    internal dynamic var brightness: UInt16 { // = 178
        get {
            return _brightness;
        }
        set(newBrightness) {
            assert(newBrightness >= 0 && newBrightness <= 255, "Brightness can be from 0 to 255")
            _brightness = newBrightness;
            _updateWheelBrightnessIfNeeded()
        }
        // I don't know why these didn't work w/bindings...but oh well..
//        willSet(newBrightness) {
//            assert(newBrightness >= 0 && newBrightness <= 255, "Brightness can be from 0 to 255")
//        }
//        didSet {
//            _updateWheelBrightnessIfNeeded()
//        }
    }
    
    internal dynamic var brightnessEnabled = false;
    
    dynamic var wheelTitle: String = "Unknown Cyr Wheel" {
        didSet(value) {
            // TODO: update the name on the device..
        }
    }

    private func _updateWheelBrightnessIfNeeded() {
        if !_internalUpdate {
            _writeWheelUARTCommand(CDWheelUARTCommandSetBrightness, with16BitValue: Int16(_brightness));
        }
        // better way, when we can write chars
//        if !_internalUpdate && _brightnessWriteCharacteristic != nil {
//            _writeInt16Value(Int16(brightness), forCharacteristic: _brightnessWriteCharacteristic!)
//        }
    }
    
    private func _getInt16FromData(value: NSData) -> Int16 {
        var resultLittleE = Int16(littleEndian: 0) // Bytes are little Endian
        value.getBytes(&resultLittleE, length: sizeofValue(resultLittleE))
        return resultLittleE.bigEndian // We deal w/big..
    }
    
    private func _updateBrightnessFromData(value: NSData) {
        self.brightnessEnabled = true;
        _internalUpdate = true;
        
        var byteValue: UInt16 = UInt16(littleEndian: 0);
        value.getBytes(&byteValue, length: sizeofValue(byteValue))
        self.brightness = byteValue.bigEndian;
        _internalUpdate = false;
    }

    
    // Private API, delegate implementations, etc.
    
//    private func _writeInt8Value(value: UInt8, forCharacteristic characteristic: CBCharacteristic) {
//        var val: UInt8 = value
//        let data: NSData = NSData(bytes: &val, length: sizeofValue(val))
//        peripheral.writeValue(data, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithoutResponse)
//    }

    private func _writeInt16Value(value: Int16, forCharacteristic characteristic: CBCharacteristic) {
        var val: Int16 = value.bigEndian
        let data: NSData = NSData(bytes: &val, length: sizeofValue(val))
//        NSLog("writing: %@", data.debugDescription)
        // with our without response works
        peripheral.writeValue(data, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithResponse)
    }
    
    
    private func _writeInt32Value(value: Int32, forCharacteristic characteristic: CBCharacteristic) {
        var val: Int32 = value;
        let data: NSData = NSData(bytes: &val, length: sizeofValue(val))
        peripheral.writeValue(data, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithResponse)
    }
    
    
// MARK: ---------------------------
// MARK: Peripheral delegate methods
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        for service: CBService in peripheral.services! {
            debugPrint("found service: \(service.UUID)")
            if (service.UUID.isEqual(wheelServiceUUID)) {
                _cyrWheelService = service;
                debugPrint("found CYR wheel service: \(service.UUID)")
                // Request the characteristics right away so we can get values and represent our current state
                peripheral.discoverCharacteristics(nil, forService: service);
            } else if (service.UUID.isEqual(uartServiceUUID)) {
                peripheral.discoverCharacteristics(nil, forService: service);
            }
        }
        if _cyrWheelService == nil {
            debugPrint("FAILED to find cyr wheel service")
        }
    }
    
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        debugPrint("characteristics found for service", service)
        if service.characteristics == nil {
            return;
        }
        for characteristic: CBCharacteristic in service.characteristics! {
            debugPrint("charactaristic",  stringFromUUID(characteristic.UUID))
            
            func watchChar() {
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                peripheral.readValueForCharacteristic(characteristic)
            }
            
            let uuid = characteristic.UUID;
            
            if (uuid.isEqual(CBUUID(string: kLEDWheelBrightnessCharacteristicReadUUID))) {
                _brightnessReadCharacteristic = characteristic;
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
            } else if (uuid.isEqual(uartTransmitCharacteristicUUID)) {
                _uartTransmitCharacteristic = characteristic;
                commandEnabled = true;
            } else if (uuid.isEqual(uartReceiveCharacteristicUUID)) {
                _uartRecieveCharacteristic = characteristic;
                watchChar();
            }
        }
    }
    
    private func _updateCurrentPatternItem() {
        // Only can do this if the chars are valid
        if _uartTransmitCharacteristic != nil && _uartRecieveCharacteristic != nil {
            _writeWheelUARTCommand(CDWheelUARTCommandRequestPatternInfo)
        }
    }
    
//    var _i = 0;
//    
//    // speed test
//    func doTest() {
//        if (_sendingData) {
//            NSLog("sending data already")
//            return;
//        }
//        if (_uartTransmitCharacteristic == nil) {
//            NSLog("NO _uartTransmitCharacteristic!!");
//            return
//        }
//        // send 20 bytes at a time..ugh!
//        _dataToSend = NSData(contentsOfFile: "/corbin/Desktop/testing.txt")
//
//        // 20 bytes max..ugh...
//        // send the size..then the next packets follow
//        _writeInt32Value(Int32(_dataToSend!.length).littleEndian, forCharacteristic: _uartTransmitCharacteristic!)
//        
//        _dataOffset = 0;
//        _i=0;
////        let subData: NSData = _dataToSend!.subdataWithRange(NSMakeRange(_dataOffset, _dataChunkSize))
////        NSLog("sending %@, length: %d", _dataToSend!, subData.length);
////        _dataOffset += subData.length
////        peripheral.writeValue(subData, forCharacteristic: _uartTransmitCharacteristic!, type: CBCharacteristicWriteType.WithResponse)
//    }
    
    func peripheralDidUpdateName(peripheral: CBPeripheral) {
        if let name = peripheral.name {
            wheelTitle = name
        } else {
            wheelTitle = "Untitled Cyr Wheel"
        }
    }
    
//    func sendMoreDataIfNeededAfterDelay() {
//        let nowDataLeft = _dataToSend!.length - _dataOffset;
//        if (nowDataLeft > 0) {
//            let delay: Int64 = Int64(NSEC_PER_MSEC)*2 // At about 4ns, it starts to get slower on the recieving end.
//            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delay), dispatch_get_main_queue(), { () -> Void in
//                self.sendMoreData();
//            })
//        }
//    }
//    
//    func sendMoreData() {
//        let dataLeft = _dataToSend!.length - _dataOffset;
//        if dataLeft > 0 {
//            let amountToSend = min(dataLeft, _dataChunkSize)
//            let subData: NSData = _dataToSend!.subdataWithRange(NSMakeRange(_dataOffset, amountToSend))
//            _dataOffset += subData.length
//            // CBCharacteristicWriteType.WithResponse vs without
//            peripheral.writeValue(subData, forCharacteristic: _uartTransmitCharacteristic!, type: CBCharacteristicWriteType.WithoutResponse)
//            NSLog("write: %d, %d, left %d", _i++, amountToSend, _dataOffset);
//            sendMoreDataIfNeededAfterDelay();
//        }
//    }

    func peripheral(peripheral: CBPeripheral, didWriteValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if characteristic == _uartTransmitCharacteristic {
            // After initial response, start sending the file.....if we  need toooo
//            sendMoreData();
        }
    }

    // MARK: ---------------------------

//    private var _sequenceListData: NSMutableData? // Valid when we are loading the data
//    private func _addDataToSequenceList(data: NSData?) {
//        // Consdier done when we get nil data (or some other marker..)
//        let isDone = data == nil
//        if !isDone {
//            if _sequenceListData == nil {
//                _sequenceListData = NSMutableData()
//            }
//            _sequenceListData!.appendData(data!)
//        }
//        
//        if (isDone) {
//            peripheral.setNotifyValue(false, forCharacteristic: _getSequencesCharacteristic!)
//            _parseSequenceListData();
//        }
//        
//    }
    
//    public func enumerateObjectsUsingBlock(block: (AnyObject, Int, UnsafeMutablePointer<ObjCBool>) -> Void)
//    internal func deleteFilenamesAtIndexes(indexes: NSIndexSet, didCompleteHandler: (succeeded: Bool) -> Void) {
//        // TODO: what is the limit of the bytes I can send at one time?
//        let data: NSMutableData = NSMutableData()
//        
//        for var index = indexes.firstIndex; index != NSNotFound; index = indexes.indexGreaterThanIndex(index) {
//            // Send 16-bit indexes
//            var indexAs16Bit: Int16 = Int16(index).littleEndian;
//            data.appendBytes(&indexAs16Bit, length: sizeof(Int16))
//        }
//            
//        peripheral.writeValue(data, forCharacteristic: _deleteSequenceCharacteristic!, type: CBCharacteristicWriteType.WithResponse)
//    
//    }
    
//    // not used..
//    private func _addSequenceFilename(filename: String) {
//        sequenceFilenames.append(filename)
//    }
//    
//    // not used..
//    private func _parseSequenceListData() {
//        let data = _sequenceListData!
//        if let dataAsString = String(data: data, encoding: NSUTF8StringEncoding) {
//            var done = false
//            repeat {
//                if let range = dataAsString.rangeOfCharacterFromSet(NSCharacterSet.newlineCharacterSet()) {
//                    let filename = dataAsString.substringToIndex(range.startIndex)
//                    _addSequenceFilename(filename)
//                } else {
//                    done = true
//                }
//            } while !done;
//        }
//        
//        delegate?.wheelConnection(self, didChangeSequenceFilenames: sequenceFilenames)
//        _sequenceListData = nil // done with it
//    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        debugPrint("didUpdateNotify for characteristic: \(stringFromUUID(characteristic.UUID))")
        // We have to wait until we did update the notification state before we can request status...otherwise we loose "packets"
        if characteristic == _uartRecieveCharacteristic {
            _updateCurrentPatternItem()
        }
    }
    
    func stringFromUUID(uuid: CBUUID) -> String {
/*        if uuid.isEqual(CBUUID(string: kLEDWheelCharSendCommandUUID)) {
            return "Wheel CommandCharacteristic"
        } else */
        if (uuid.isEqual(CBUUID(string: kLEDWheelBrightnessCharacteristicReadUUID))) {
            return "Brightness READ Characteristic"
        }  else if (uuid.isEqual(CBUUID(string: kLEDWheelCharGetWheelStateUUID))) {
            return "Get State Characteristic"
        } else if (uuid.isEqual(uartTransmitCharacteristicUUID)) {
            return "UART Transmit characteristic"
        } else {
            return uuid.description
        }
    }
    
    // Data receiving
    private var _dataToReceive: NSMutableData? = nil;
    private var _dataRecieveCommand: CDWheelUARTRecieveCommand = CDWheelUARTRecieveCommandInvalid

    private func _recieveUARTData(data: NSData) {
        // Append to _dataToReceive and attempt to process
        if _dataToReceive == nil {
            // First time
            _dataToReceive = NSMutableData()
            _dataToReceive!.appendData(data)
            // First time in, we have to see what we are going to process to know when we are done...
            _dataRecieveCommand = CDWheelUARTRecieveCommandInvalid
            _dataToReceive!.getBytes(&_dataRecieveCommand, length: sizeofValue(_dataRecieveCommand))
            // If it is invalid...we don't process it (I was getting a bad packet from something..)
            
            
            NSLog("value got: %d", _dataRecieveCommand.rawValue)
        } else {
            _dataToReceive!.appendData(data)
        }
        
        _processUARTRecieveData(_dataToReceive!)
    }
    
    private func _processUARTRecieveData(data: NSData) {
        switch (_dataRecieveCommand) {
        case CDWheelUARTRecieveCommandInvalid:
            // Done.. error state...
            _dataToReceive = nil;
        case CDWheelUARTRecieveCommandCurrentPatternInfo:
            _processPatternInfoData(data)
            break
        default:
            // An invalid value...
            NSLog("Invalid UART data: %@", data);
            _dataToReceive = nil;
            break
        }
    }
    
    private func _processPatternInfoData(data: NSData) {
        NSLog("_processPatternInfoData")
        var dataOffset = sizeof(CDWheelUARTRecieveCommand) // start past the command
        var dataAvailable = data.length - dataOffset
        // Keep repeating our reads until we have enough data to do all the work..
        let expectedSize = sizeof(CDPatternItemHeader)
        if (dataAvailable >= expectedSize) {
            // Read in the header
            var patternItemHeader = CDPatternItemHeader()
            data.getBytes(&patternItemHeader, range: NSRange(location: dataOffset, length: sizeofValue(patternItemHeader)))
            dataOffset += sizeofValue(patternItemHeader)
            dataAvailable -= sizeofValue(patternItemHeader)
            
            // Does it have a filename? if so, wait for it..
            // Stupid thunk... 
            let test = CDPatternItemHeaderGetFilenameLength(patternItemHeader)

            
            print(test)
            let filenameLength = Int(CDPatternItemHeaderGetFilenameLength(patternItemHeader))
            if filenameLength > 0 {
                if dataAvailable >= (filenameLength + 1) {
                    // read in the filename and we are done!
                    let stringData = data.subdataWithRange(NSRange(location: dataOffset, length: filenameLength))
                    let s = NSString(data: stringData, encoding: NSUTF8StringEncoding)
                    self.currentPatternItemFilename = String(s)
                    _dataToReceive = nil;
                    NSLog("got filename: %@", self.currentPatternItemFilename!)
                    self.currentPatternItem = patternItemHeader
                } else {
                    // not done..
                    NSLog("...waiting..");
                }
            } else {
                // done!
                self.currentPatternItemFilename = nil
                // Translate an invalidate item to NULL
                if patternItemHeader.patternType != LEDPatternTypeCount {
                    self.currentPatternItem = patternItemHeader
                } else {
                    self.currentPatternItem = nil;
                }
                _dataToReceive = nil; // marker that we are done
            }
        } else {
            NSLog("......waiting..");

        }
    }
    
    func peripheral(peripheral: CBPeripheral, didUpdateValueForCharacteristic characteristic: CBCharacteristic, error: NSError?) {
        if error != nil {
            // TODO: present the error...make sure they aren't piling up
            debugPrint("didUpdateValueForCharacteristic error:\(error)!")
            return;
        }
        
        if (characteristic == _brightnessReadCharacteristic) {
            if let data = characteristic.value {
                _updateBrightnessFromData(data)
            }
        } else if (characteristic == _stateCharacteristic) {
            if let data = characteristic.value {
                self.wheelState = CDWheelState(_getInt16FromData(data));
            }
        } else if characteristic == _uartRecieveCharacteristic {
            if let data = characteristic.value {
                _recieveUARTData(data)
            }
        }
    }
    

}
