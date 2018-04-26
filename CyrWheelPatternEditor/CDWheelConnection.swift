//
//  CDWheelConnection.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 11/22/15 .
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol CDWheelConnectionDelegate {
    func wheelConnection(_ wheelConnection: CDWheelConnection, didChangeState: CDWheelState)
    func wheelConnection(_ wheelConnection: CDWheelConnection, didChangePatternItem patternItem: CDPatternItemHeader?, patternItemFilename: String?)
    func wheelConnection(_ wheelConnection: CDWheelConnection, didChangeSequences: [String])
}

typealias CDWheelConnectionUploadHandler = (_ uploadProgressAmount: Float, _ finished: Bool, _ error: NSError?)-> Void

let BT_DEBUG = 0
func DLog(_ format: String, _ args: CVarArg...) {
    #if BT_DEBUG
    NSLog(format, __VA_ARGS__)
    #endif
}


extension Data {
    
    // I had this backwards... the ARM chip is dealing with big, but we are 386, which is little. But going big -> little doesn't work for some reason...the initializer for Int16 doesn't keep that state
    func readLittleEndianFromBigEndianInt16() -> Int16 {
        var result: Int16 = 0
        (self as NSData).getBytes(&result, length: MemoryLayout.size(ofValue: result)) // this read always seems to make the bytes littleEndian, because that is our architecture. So...we want to flip it
        return result.byteSwapped // We deal w/little endian.
    }

    func readLittleEndianFromBigEndianUInt16() -> UInt16 {
        return UInt16(readLittleEndianFromBigEndianInt16());
    }
    
    // assumes same architecture...why does this work? I'm confused...
    func readUInt32AtOffset(_ offset: Int) -> UInt32 {
        var result: UInt32 = 0
        (self as NSData).getBytes(&result, range: NSRange(location: offset, length: MemoryLayout.size(ofValue: result)))
        return result
    }
    
    // filenameLength should NOT include the NULL terminator, but we do read the NULL terminator
    func readStringOfLength(_ filenameLength: Int, offset: Int = 0) -> String? {
        if filenameLength > 0 {
            let stringData = self.subdata(in: offset..<(offset + filenameLength)) // Swift 3
            //            let stringData = self.subdata(in: offset..<filenameLength) // Swift 1
            let tmpStr = String(data: stringData, encoding: String.Encoding.utf8) as String!
            return tmpStr
        } else {
            return nil
        }
    }
    
    func attemptToReadStringAtOffset(_ offset: inout Int, string: inout String?) -> Bool {
        var dataAvailable = self.count - offset
        if dataAvailable >= MemoryLayout<UInt32>.size {
            // we can read the size, so read it
            let stringLength = Int(readUInt32AtOffset(offset))
            dataAvailable -= MemoryLayout<UInt32>.size
            if stringLength == 0 {
                offset += MemoryLayout<UInt32>.size
                string = nil
                return true;
            } else if stringLength > 1024 { // harcoded max length, ugly!
                NSLog("ERROR reading string (bad length: %d", stringLength)
                // Error condition.... how to represent this??
                offset += MemoryLayout<UInt32>.size
                string = nil
                return true
            } else if dataAvailable >= stringLength {
                // We can read the string (might be 0)
                offset += MemoryLayout<UInt32>.size
                string = readStringOfLength(stringLength, offset: offset)
                offset += stringLength
                return true;
            }
        }
        return false;
    }
    
}

extension NSMutableData {
    
    func writeUInt32(_ i: UInt32) {
        var rawValue: UInt32 = i;
        self.append(&rawValue, length: MemoryLayout.size(ofValue: rawValue))
    }
    
    func writeString(_ string: String) {
        // Includes NULL term in size (for better or worse)
        let filenameUTF8 = string.utf8CString
        var sizeValue: UInt32 = UInt32(filenameUTF8.count)
        self.append(&sizeValue, length: MemoryLayout.size(ofValue: sizeValue))
        
        let filenameLength = filenameUTF8.count; // null terminator
        string.withCString { (p: UnsafePointer<Int8>) in
            // filename, including null terminator
            self.append(p, length: filenameLength)
        }
    }
}

// State machine to parse the data, with a timeout.
class CDDataReader {
    fileprivate var _data: NSMutableData!
    fileprivate var _offset: Int = 0;
    fileprivate var _completionHandler: (_ dataReader: CDDataReader, _ unusedData: Data?)-> Void
    fileprivate var _timeoutHandler: (_ dataReader: CDDataReader)->Void
    fileprivate var _timeoutTimerMaker = 0
    internal var _completed = false
    
    init(completionHandler: @escaping (_ dataReader: CDDataReader, _ unusedData: Data?)-> Void, timeoutHandler: @escaping (_ dataReader: CDDataReader)->Void) {
        _completionHandler = completionHandler
        _timeoutHandler = timeoutHandler
    }
    
    internal func addData(_ data: Data) {
        _timeoutTimerMaker += 1
        if (_data == nil) {
            _data = NSData(data: data) as Data as Data as! NSMutableData
        } else {
            _data.append(data)
        }
        _parseData()
    }
    
    fileprivate func _startProcessDataResetTimer() {
        _timeoutTimerMaker += 1
        let localTimer = _timeoutTimerMaker;
        let delay: Int64 = Int64(NSEC_PER_SEC)*1 // 1 seconds
        DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(delay) / Double(NSEC_PER_SEC), execute: { () -> Void in
            if localTimer == self._timeoutTimerMaker {
                if !self._completed {
                    DLog("Timeout for UART data recieve: %@", self._data)
                    self._timeoutHandler(self);
                }
            } else {
                // Ignore; we got more data
            }
        })
    }
 
    fileprivate func _parseData() {
        parseData(_data as Data)
        if (!_completed) {
            _startProcessDataResetTimer()
        }
    }
    
    internal func completedParsingDataAtOffset(_ offset: Int) {
        _completed = true
        if _data.length > offset {
            // we have more UART data to process; trim down and process
            let subData = _data.subdata(with: NSRange(location: offset, length: _data.length-offset))
            DLog(" -- more data: %@", subData as CVarArg)
            _completionHandler(self, subData)
        } else {
            // Done!
            _completionHandler(self, nil)
        }
    }
    
    // Override point
    func parseData(_ data: Data) {
        
    }
}

class CDGetCurrentPatternInfoDataReader: CDDataReader {
    
    var currentPatternItemFilename: String? = nil
    var currentPatternSequenceFilename: String? = nil
    var currentPatternItem: CDPatternItemHeader? = nil
    
    override func parseData(_ data: Data) {
        // If it is invalid...we don't process it (I was getting a bad packet from something..)
//        DLog("_processPatternInfoData (data.length: %d): %@, subData:%@", data.count, data as CVarArg, data.subdata(in: NSRange(location: 1, length: data.count-1)))
        var dataOffset = MemoryLayout<CDWheelUARTRecieveCommand>.size // start past the command
        var dataAvailable = data.count - dataOffset
        // Keep repeating our reads until we have enough data to do all the work..
        let expectedSize = MemoryLayout<CDPatternItemHeader>.size
        if (dataAvailable >= expectedSize) {
            // Read in the header
            var patternItemHeader = CDPatternItemHeader()
            (data as NSData).getBytes(&patternItemHeader, range: NSRange(location: dataOffset, length: MemoryLayout.size(ofValue: patternItemHeader)))
            dataOffset += MemoryLayout.size(ofValue: patternItemHeader)
            dataAvailable -= MemoryLayout.size(ofValue: patternItemHeader)
            
            // Validate our header...if we are invalid, we stop right away
            if patternItemHeader.patternType.rawValue > LEDPatternTypeCount.rawValue || patternItemHeader.patternType.rawValue < 0 {
                completedParsingDataAtOffset(data.count)
//                NSLog("BAD PATTERN: %d, subData: %@", patternItemHeader.patternType.rawValue, data.subdata(in: NSRange(location:sizeof(CDWheelUARTRecieveCommand), length:data.count-1)))
                return; // ugly,.
            }

            // Translate an invalidate item to NULL
            if patternItemHeader.patternType != LEDPatternTypeCount {
                self.currentPatternItem = patternItemHeader
            } else {
                self.currentPatternItem = nil;
            }
            
            // Read the filename following the header
            if data.attemptToReadStringAtOffset(&dataOffset, string: &self.currentPatternItemFilename) {
                // Then read the sequence name following that name
                if data.attemptToReadStringAtOffset(&dataOffset, string: &self.currentPatternSequenceFilename) {
                    // And we are done!
                    completedParsingDataAtOffset(dataOffset)
                } else {
                    DLog("......currentPatternSequenceFilename waiting, dataAvailable: %d", dataAvailable);
                }
            } else {
                DLog("......currentPatternItemFilename waiting, dataAvailable: %d", dataAvailable);
            }
        } else {
            DLog("......waiting for header, dataAvailable: %d, expectedSize: %d", dataAvailable, expectedSize);
        }
    }
}



class CDGetFilenamesDataReader: CDDataReader {
    
    var filenames: [String] = []
    var scannerOffset: Int = 1 // go past the first byte in the data indicating what we are doing
    
    override func parseData(_ data: Data) {
        let dataLength = data.count
        // We have to have at least 2 bytes to read (the CRLF)
        let dataLeft = dataLength - scannerOffset
        if dataLeft >= 2 {
            data.withUnsafeBytes { (chars: UnsafePointer<UInt8>) in
                // We stop before the LF so we can read the next char (dataLength - 1)
                for i in scannerOffset ..< (dataLength - 1) {
                    if chars[i] == 13 && chars[i+1] == 10 {
                        // Found a filename!
                        let filenameLength = i - scannerOffset
                        if filenameLength > 0 {
//                            let stringRange = NSRange(location: scannerOffset, length: filenameLength) // Swift 1
                            let stringData = data.subdata(in: scannerOffset..<(scannerOffset + filenameLength)) // Swift 3
                            let tmpStr = String(data: stringData, encoding: String.Encoding.utf8)!
                            filenames.append(tmpStr)
                            scannerOffset += filenameLength + 2 // Go past the CR LF
                        } else {
                            // We are done! we just read a CRLF and nothing more.
                            scannerOffset += filenameLength + 2 // Go past the CR LF
                            completedParsingDataAtOffset(scannerOffset)
                            break;
                        }
                    }
                }
            }
            
        }
    }
}

class CDOrientationDataReader: CDDataReader {
    
    var result: Data!
    
    override func parseData(_ data: Data) {
        let dataLength = data.count
        if (dataLength >= MemoryLayout<CDWheelUARTRecieveCommand>.size) {
            let startOffset = MemoryLayout<CDWheelUARTRecieveCommand>.size;
            var endOffset = startOffset;
            // Read until a CRLF
            // NOTE: if I make CDWheelUARTRecieveCommand larger than 1 byte, this will fail (or if it has the value \r)
            var foundCR = false;
            
            // Swift 3.0
            // TODO: corbin, check the conversion using withUnsafeBytes!
            data.withUnsafeBytes { (body: UnsafePointer<UInt8>) in
                for i in 0..<dataLength {
                    if foundCR && body[i] == 10 {
                        endOffset = i
                        break
                    } else if body[i] == 13 {
                        foundCR = true
                    } else {
                        foundCR = false;
                    }
                }
            }

            if endOffset > startOffset {
                result = data.subdata(in: startOffset ..< endOffset + 1)
                completedParsingDataAtOffset(endOffset)
            } else {
                // waiting..for the newline
            }

            // Swift 1.0
            /*
            var foundCR = false;
            data.enumerateByteRangesUsingBlock({ (bytes: UnsafePointer<Void>, range: NSRange, stop: UnsafeMutablePointer<ObjCBool>) -> Void in
                // CDGetFilenamesDataReader does this better
                let chars = UnsafePointer<UInt8>(bytes)
                for var i = 0; i < range.length; i++ {
                    //ugh...\r\n?
                    if foundCR && chars[i] == 10 {
//                        Done!
                        endOffset = range.location + i + 1; // past us
                        stop.memory = true
                    } else if chars[i] == 13 {
                        foundCR = true
                    } else {
                        foundCR = false;
                    }
                }
            })
 
            if endOffset > startOffset {
                result = data.subdata(in: NSRange(location: startOffset, length: endOffset-startOffset))
                completedParsingDataAtOffset(endOffset)
            } else {
                // waiting..for the newline
            }
             */
        }
    }
    
}

let gPatternEditorErrorDomain: String = "PatternEditorErrorDomain"
let gPatternFilenameExtension: String = "pat"
let gSequenceEditorExtension: String = "cyrwheel"

// Simple organization..children not used yet..
// It is an NSObject so we can feed it to NSOutlineView items
class CDWheelFileObject: NSObject {
    var filename: NSString
    var label: String
    weak var parent: CDWheelFileObject?
    var children: [CDWheelFileObject] = []
    
    init(filename: String, parent: CDWheelFileObject?) {
        self.filename = filename as NSString
        self.parent = parent;
        let s = filename as NSString
        self.label = s.lastPathComponent
    }
}


class CDWheelConnection: NSObject, CBPeripheralDelegate {
    fileprivate let uartServiceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E") // From AdaFruit's docs
    fileprivate let wheelServiceUUID = CBUUID(string: kLEDWheelServiceUUID)
    fileprivate let uartTransmitCharacteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E") // Write/transmit characteristic UUID
    fileprivate let uartReceiveCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E") // Read/receive (via notify) characteristic UUID

    fileprivate let fpsCharUUID = CBUUID(string: kLEDWheelFPSCharacteristicUUID) // Read / notify
    
    internal var peripheral: CBPeripheral
    
    fileprivate var _cyrWheelService: CBService? // do i need to hold onto this??
    fileprivate var _stateCharacteristic: CBCharacteristic?

    fileprivate var _brightnessReadCharacteristic: CBCharacteristic?
    
    // uart stuff
    fileprivate var _uartTransmitCharacteristic: CBCharacteristic?
    fileprivate var _uartRecieveCharacteristic: CBCharacteristic?
    fileprivate var _fpsChar: CBCharacteristic?

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
    var currentPatternSequenceFilename: String?
    
    var wheelState: CDWheelState = CDWheelStateNone {
        didSet {
            delegate?.wheelConnection(self, didChangeState: wheelState);
        }
    }
    
    var customSequences: [String] = [] {
        didSet {
            delegate?.wheelConnection(self, didChangeSequences: customSequences)
        }
    }
    
    // For all files, I used CDWheelFileObject representation. I could move customSequences to this..
    fileprivate var _rootFileObject: CDWheelFileObject? = nil
    var rootFileObject: CDWheelFileObject? {
        get {
            if _rootFileObject == nil {
                _rootFileObject = CDWheelFileObject(filename: "/", parent: nil)
                // request here..
            }
            return _rootFileObject
        }
    }
    
    
    // Data sending
    let _dataChunkSize = 20 // I think this is a limit of the peripheral
    fileprivate var _dataToSend: Data? = nil;
    fileprivate var _dataOffset: Int = 0;
    fileprivate var _nextDataToSend: NSMutableData?
    fileprivate var _writeCounter = 0; // for debugging mainly

    // Send the UART data, chunking as necessary, and requesting a response after the last chunk is sent... (maybe?)
    fileprivate func _startSendingUARTData(_ data: Data) {
        if let transmitChar = _uartTransmitCharacteristic {
            if _dataToSend == nil {
                if data.count <= _dataChunkSize {
                    // All of it goes in one chunk
                    peripheral.writeValue(data, for: transmitChar, type: CBCharacteristicWriteType.withResponse)
                    _didSendUARTDataWithLength(data.count)
                } else {
                    // Chunk it
                    _dataOffset = 0
                    _writeCounter = 0;
                    _dataToSend = data
                    _sendUARTDataChunk()
                }
            } else {
                // queue the data up...or we drop it?
                // I could just append into _dataToSend; that should work..
                if _nextDataToSend == nil {
                    _nextDataToSend = NSMutableData()
                }
                _nextDataToSend!.append(data)
            }
        } else {
            // Not yet connected...
        }
    }
    
    fileprivate func _doneSendingData() {
        _dataToSend = nil // done
        // If we have more queued data, start it
        if let nextData = _nextDataToSend {
            _nextDataToSend = nil // drop it
            _startSendingUARTData(nextData as Data)
        }
    }
    
    fileprivate func _sendMoreUARTDataIfNeededAfterDelay() {
        guard let data = _dataToSend else { return }
        let nowDataLeft = data.count - _dataOffset;
        if (nowDataLeft > 0) {
            let delay: Int64 = Int64(NSEC_PER_MSEC)*2 // At about 4ns, it starts to get slower on the recieving end.
            DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + Double(delay) / Double(NSEC_PER_SEC), execute: { () -> Void in
                self._sendUARTDataChunk();
            })
        } else {
            _doneSendingData()
        }
    }
    
    fileprivate func _sendUARTDataChunk() {
        guard let data = _dataToSend else { return }
        if let transmitChar = _uartTransmitCharacteristic {
            let dataLeft = data.count - _dataOffset;
            if dataLeft > 0 {
                let amountToSend = min(dataLeft, _dataChunkSize)
//                let subData: Data = data.subdata(in: NSMakeRange(_dataOffset, amountToSend)) // Swift 1
                let subData: Data = data.subdata(in: _dataOffset ..< _dataOffset + amountToSend) // Swift 3
                _dataOffset += subData.count
                // CBCharacteristicWriteType.WithResponse vs without
                peripheral.writeValue(subData, for: transmitChar, type: CBCharacteristicWriteType.withoutResponse)
    //            DLog("write: %d, %d, _dataOffset %d, total: %d", _writeCounter++, amountToSend, _dataOffset, data.length);
                _sendMoreUARTDataIfNeededAfterDelay();
                _didSendUARTDataWithLength(amountToSend)
            } else {
                _doneSendingData()
            }
        } else {
            // connection dropped while sending data..
            _nextDataToSend = nil // drop the queued data too
            _doneSendingData()
            _markUploadSucceeded(false)
        }
    }

    fileprivate func _writeWheelUARTCommand(_ uartCommand: CDWheelUARTCommand, with16BitValue rawValueC: Int16? = nil) {
        DLog("_writeWheelUARTCommand")
        // Write the command as an 8-bit value..
        var uartCommand: Int8 = uartCommand.rawValue
        // the uartCommand, followed by the value..
        let data: NSMutableData = NSMutableData(bytes: &uartCommand, length: MemoryLayout.size(ofValue: uartCommand))
        
        if var rawValue: Int16 = rawValueC {
            data.append(&rawValue, length: MemoryLayout.size(ofValue: rawValue))
        }
        
        // No response might be faster...but we could ignore *MORE* writes until we get a response to avoid flooding it
        _startSendingUARTData(data as Data)
    }

    fileprivate func _writeWheelUARTCommand(_ uartCommand: CDWheelUARTCommand, with32BitValue rawValueC: UInt32) {
        DLog("_writeWheelUARTCommand32")
        // Write the command as an 8-bit value..
        var uartCommand: Int8 = uartCommand.rawValue
        // the uartCommand, followed by the value..
        let data: NSMutableData = NSMutableData(bytes: &uartCommand, length: MemoryLayout.size(ofValue: uartCommand))
        
        if var rawValue: UInt32 = rawValueC {
            data.append(&rawValue, length: MemoryLayout.size(ofValue: rawValue))
        }
        
        // No response might be faster...but we could ignore *MORE* writes until we get a response to avoid flooding it
        _startSendingUARTData(data as Data)
    }
    
    internal func setDynamicPatternType(_ patternType: LEDPatternType, color: CRGB, duration: UInt32) {
        // Write the command as an 8-bit value..
        var uartCommand: Int8 = CDWheelUARTCommandPlayProgrammedPattern.rawValue
        // the uartCommand, followed by the value..
        let data: NSMutableData = NSMutableData(bytes: &uartCommand, length: MemoryLayout.size(ofValue: uartCommand))

        // pattern type
        var rawPatternValue: Int32 = patternType.rawValue
        data.append(&rawPatternValue, length: MemoryLayout.size(ofValue: rawPatternValue))

        // duration
        var rawDuration: UInt32 = duration;
        data.append(&rawDuration, length: MemoryLayout.size(ofValue: rawDuration))
        
        // color
        var rawColor: CRGB = color
        data.append(&rawColor, length: MemoryLayout.size(ofValue: rawColor))
        
        // No response might be faster...but we could ignore *MORE* writes until we get a response to avoid flooding it
        _startSendingUARTData(data as Data)
    }
    
    internal func setDynamicImagePattern(_ filename: String, duration: UInt32, bitmapOptions: LEDBitmapPatternOptions) {
        // Write the command as an 8-bit value..
        var uartCommand: Int8 = CDWheelUARTCommandPlayImagePattern.rawValue
        // the uartCommand, followed by the value..
        let data: NSMutableData = NSMutableData(bytes: &uartCommand, length: MemoryLayout.size(ofValue: uartCommand))
        
        // duration
        data.writeUInt32(duration)
        
        // LEDBitmapPatternOptions
        var rawOptions: LEDBitmapPatternOptions = bitmapOptions
        assert(MemoryLayout.size(ofValue: rawOptions) == 4)
        data.append(&rawOptions, length: MemoryLayout.size(ofValue: rawOptions))

        data.writeString(filename)
        
        // No response might be faster...but we could ignore *MORE* writes until we get a response to avoid flooding it
        _startSendingUARTData(data as Data)
    }
    
    internal func playPatternSequence(_ filename: String) {
        // Write the command as an 8-bit value..
        var uartCommand: Int8 = CDWheelUARTCommandPlaySequence.rawValue
        // the uartCommand, followed by the value..
        let data: NSMutableData = NSMutableData(bytes: &uartCommand, length: MemoryLayout.size(ofValue: uartCommand))
        
        // Includes NULL term in size (for better or worse)
        let filenameUTF8 = filename.utf8CString
        var sizeValue: UInt32 = UInt32(filenameUTF8.count)
        data.append(&sizeValue, length: MemoryLayout.size(ofValue: sizeValue))
        
        let filenameLength = filenameUTF8.count; // null terminator
        filename.withCString { (p: UnsafePointer<Int8>) in
            // filename, including null terminator
            data.append(p, length: filenameLength)
        }
        
        // No response might be faster...but we could ignore *MORE* writes until we get a response to avoid flooding it
        _startSendingUARTData(data as Data)
    }
    
    internal var commandEnabled: Bool = false;
    internal func sendCommand(_ command: CDWheelCommand) {
        // Stupid Adafruit BLE is slow for command reads, so I don't do this...
//        if let char = _commandCharacteristic {
//            _writeInt16Value(Int16(command.rawValue), forCharacteristic: char);
//        }
        
        // Use the UART characteristic to write the value..
        _writeWheelUARTCommand(CDWheelUARTCommandWheelCommand, with16BitValue: command.rawValue);
    }
    
    internal func _makeFilenameFromURL(_ url: URL) -> String {
        // TODO: rework this to have long filenames
        
        let possibleBaseFilename = url.deletingPathExtension().lastPathComponent
        var baseFilename: String = possibleBaseFilename != nil ? possibleBaseFilename : "Untitled"

        // We are limited to 8.3 filenames.. I should make the names prettier...
        if baseFilename.characters.count > 8 {
            // Take the first 8 characters
            let range: Range<String.Index> = (baseFilename.characters.index(baseFilename.startIndex, offsetBy: 8) ..< baseFilename.endIndex)
            baseFilename.removeSubrange(range)
//            baseFilename = baseFilename!.substringToIndex(baseFilename!.startIndex.advancedBy(8))
        }
        
        
        // Make sure the name is 8.3 syntax and unique
        let possiblePathExtension = url.pathExtension;
        var pathExtension: String = possiblePathExtension != nil ? possiblePathExtension : gPatternFilenameExtension
        // Just kill long extensions. wrong extensions won't work either..but oh well
        if pathExtension.characters.count > 3 {
            pathExtension = gPatternFilenameExtension
        }
        
        var fullFilename: String = baseFilename + pathExtension
        fullFilename = fullFilename.uppercased() // ugly, but the filenames on disk are all uppercase
        return fullFilename
    }
    
    
    // TODO: junk.... need to re-write
    fileprivate var _writeProgressHandler: ((_ progress: Float, _ error: NSError?) -> Void)? = nil
//    internal func uploadPatternItemWithURL(url: NSURL, progressHandler: ((progress: Float, error: NSError?) -> Void)) {
//        let filename: String = _makeFilenameFromURL(url)
//        
//        if sequenceFilenames.contains(filename) {
//            let error = NSError(domain: gPatternEditorErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "A file with the name '\(filename)' already exists. Please choose another file."])
//            progressHandler(progress: 1.0, error: error)
//            return;
//        }
//        
//        guard let fileData: NSData = NSData(contentsOfURL: url) else {
//            let error = NSError(domain: gPatternEditorErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to open the file '\(url)'"])
//            progressHandler(progress: 1.0, error: error)
//            return
//        }
//        
//        let dataToUpload: NSMutableData = NSMutableData()
//        
//        // Format of the data: 
//        // filename<null terminator>
//        // 32-bit size of the data following
//        // the file data
//        // TODO: CRC???
//        var filenameUTF8 = filename.utf8CString
//        dataToUpload.appendBytes(&filenameUTF8, length: filenameUTF8.count + 1) // plus one for the null terminator
//        
//        var sizeValue: UInt32 = UInt32(fileData.length)
//        dataToUpload.appendBytes(&sizeValue, length: sizeofValue(sizeValue))
//        dataToUpload.appendData(fileData)
//
//        _writeProgressHandler = progressHandler
//    }
    
    
    fileprivate var _internalUpdate: Bool = false;
    
    
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

    fileprivate func _updateWheelBrightnessIfNeeded() {
        if !_internalUpdate {
            _writeWheelUARTCommand(CDWheelUARTCommandSetBrightness, with16BitValue: Int16(_brightness));
        }
        // better way, when we can write chars
//        if !_internalUpdate && _brightnessWriteCharacteristic != nil {
//            _writeInt16Value(Int16(brightness), forCharacteristic: _brightnessWriteCharacteristic!)
//        }
    }
    
    func setCurrentPatternDuration(_ duration: UInt32) {
        _writeWheelUARTCommand(CDWheelUARTCommandSetCurrentPatternSpeed, with32BitValue: duration);
    }

    // encoded color
    func setCurrentPatternColor(_ color: UInt32) {
        _writeWheelUARTCommand(CDWheelUARTCommandSetCurrentPatternColor, with32BitValue: color);
    }
   
    func setCurrentPatternBrightnessByRotationalVelocity(_ value: Bool) {
        _writeWheelUARTCommand(CDWheelUARTCommandSetCurrentPatternBrightnessByRotationalVelocity, with32BitValue: value ? 1 : 0);
    }
    
    func setCurrentBitmapPatternOptions(_ valueX: LEDBitmapPatternOptions) {
        // convert the raw data...
        // Swift 1.0
        /*
         var value: LEDBitmapPatternOptions = valueX
        withUnsafePointer(&value) { (arg: UnsafePointer<LEDBitmapPatternOptions>) in
            let p: UnsafePointer<UInt32> = UnsafePointer<UInt32>(arg)
            _writeWheelUARTCommand(CDWheelUARTCommandSetCurrentPatternOptions, with32BitValue: p.memory);
        }
         */
        // Swift 3.0?
        var value: LEDBitmapPatternOptions = valueX
        withUnsafePointer(to: &value) { (arg: UnsafePointer<LEDBitmapPatternOptions>) in
            arg.withMemoryRebound(to: UInt32.self, capacity: 1, { p in
                let value: UInt32 = p.pointee
                _writeWheelUARTCommand(CDWheelUARTCommandSetCurrentPatternOptions, with32BitValue: value);
            })
        }
    }
    
    fileprivate func _updateBrightnessFromData(_ value: Data) {
        self.brightnessEnabled = true;
        _internalUpdate = true;
        // Wait..this has to be wrong..we are little, ARM is big
        self.brightness = value.readLittleEndianFromBigEndianUInt16()
        _internalUpdate = false;
    }

    
    // Private API, delegate implementations, etc.
    
//    private func _writeInt8Value(value: UInt8, forCharacteristic characteristic: CBCharacteristic) {
//        var val: UInt8 = value
//        let data: NSData = NSData(bytes: &val, length: sizeofValue(val))
//        peripheral.writeValue(data, forCharacteristic: characteristic, type: CBCharacteristicWriteType.WithoutResponse)
//    }

    fileprivate func _writeInt16Value(_ value: Int16, forCharacteristic characteristic: CBCharacteristic) {
        var val: Int16 = value.bigEndian
        // Swift 1:
//         let data: NSData = NSData(bytes: &val, length: sizeofValue(val))
        // Swift 3:
        let data = withUnsafePointer(to: &val) {
            Data(bytes: $0, count: MemoryLayout.size(ofValue: val))
        }
        
//        NSLog("writing: %@", data.debugDescription)
        // with our without response works
        peripheral.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
    
    fileprivate func _writeInt32Value(_ value: Int32, forCharacteristic characteristic: CBCharacteristic) {
        var val: Int32 = value;
        let data = withUnsafePointer(to: &val) { (ptr: UnsafePointer<Int32>) -> Data in
            return Data(bytes: ptr, count: MemoryLayout.size(ofValue: val))
        }
//        let data: Data = Data(bytes: UnsafePointer<UInt8>(&val), count: sizeofValue(val))
        peripheral.writeValue(data, for: characteristic, type: CBCharacteristicWriteType.withResponse)
    }
    
    
// MARK: ---------------------------
// MARK: Peripheral delegate methods
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        for service: CBService in peripheral.services! {
            DLog("found service: %@, service.UUID")
            if (service.uuid.isEqual(wheelServiceUUID)) {
                _cyrWheelService = service;
                // Request the characteristics right away so we can get values and represent our current state
                peripheral.discoverCharacteristics(nil, for: service);
            } else if (service.uuid.isEqual(uartServiceUUID)) {
                peripheral.discoverCharacteristics(nil, for: service);
            }
        }
        if _cyrWheelService == nil {
            DLog("FAILED to find cyr wheel service")
        }
    }
    
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        DLog("characteristics found for service", service)
        if service.characteristics == nil {
            return;
        }
        for characteristic: CBCharacteristic in service.characteristics! {
            DLog("charactaristic",  stringFromUUID(characteristic.uuid))
            
            func watchChar() {
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
            }
            
            let uuid = characteristic.uuid;
            
            if (uuid.isEqual(CBUUID(string: kLEDWheelBrightnessCharacteristicReadUUID))) {
                _brightnessReadCharacteristic = characteristic;
                if let data = characteristic.value {
                    _updateBrightnessFromData(data);
                }
                watchChar();
            }  else if (uuid.isEqual(CBUUID(string: kLEDWheelCharGetWheelStateUUID))) {
                _stateCharacteristic = characteristic;
                if let data = characteristic.value {
                    self.wheelState = CDWheelState(data.readLittleEndianFromBigEndianInt16());
                }
                watchChar();
            } else if (uuid.isEqual(uartTransmitCharacteristicUUID)) {
                _uartTransmitCharacteristic = characteristic;
                commandEnabled = true;
            } else if (uuid.isEqual(uartReceiveCharacteristicUUID)) {
                _uartRecieveCharacteristic = characteristic; // TODO: only notify?? no read of the value
                watchChar();
            } else if (uuid.isEqual(fpsCharUUID)) {
                _fpsChar = characteristic;
                watchChar();
                _updateFPS();
            }
        }
    }
    
    dynamic var wheelFPS: Int = 0
    
    fileprivate func _updateFPS() {
        if let char = _fpsChar {
            if let data =  char.value {
                wheelFPS = Int(data.readLittleEndianFromBigEndianInt16())
            }
        }
    }
    
    fileprivate func _updateCurrentPatternItem() {
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
    
    func peripheralDidUpdateName(_ peripheral: CBPeripheral) {
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

    
    dynamic fileprivate(set) var uploading: Bool = false;
    
    /*
    
    uint32_t filenameSize - including NULL
    char * filename, including NULL
    uint32_t file size
    data
    */

    
    fileprivate class UploadData {
        var filename: String
        var dataLength: Int
        var amountUploaded: Int = 0
        var uploadHandler: CDWheelConnectionUploadHandler
        
        init(filename: String, dataLength: Int, uploadHandler: @escaping CDWheelConnectionUploadHandler) {
            self.filename = filename
            self.dataLength = dataLength
            self.uploadHandler = uploadHandler
        }
        
    }
    
    fileprivate var _uploadData: UploadData? = nil
    
    fileprivate func _didSendUARTDataWithLength(_ length: Int) {
        if let uploadData = _uploadData {
            // we might start sending more data..so ignore more than 100%
            if (uploadData.amountUploaded < uploadData.dataLength) {
                uploadData.amountUploaded += length;
                if (uploadData.amountUploaded > uploadData.dataLength) {
                    // not sure about this.. just theory
                    uploadData.amountUploaded = uploadData.dataLength
                }
                let progress = Float(uploadData.amountUploaded) / Float(uploadData.dataLength)
                uploadData.uploadHandler(progress, false, nil)
            }
        }
    }
    
    fileprivate func _markUploadSucceeded(_ succeeded: Bool) {
        uploading = false
        if let uploadData = _uploadData {
            let error: NSError? = succeeded ? nil : NSError(domain: gPatternEditorErrorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Failed to upload the file '\(uploadData.filename)'"])
            uploadData.uploadHandler(Float(uploadData.amountUploaded) / Float(uploadData.dataLength), true, error)
            _uploadData = nil
        }
    }
    
    func uploadFileWithData(_ dataToWrite: Data, filename: String, uploadHandler: @escaping CDWheelConnectionUploadHandler) {
        assert(!uploading)
        
        var totalDataLengthToWrite: Int = dataToWrite.count
        let dataLength: UInt32 = UInt32(totalDataLengthToWrite)
        
        // keep track of how much data is in the queue before us; we have to send it too before our file is uploaded
        if let data = _dataToSend {
            totalDataLengthToWrite = data.count - _dataOffset;
        }
        
        if let data = _nextDataToSend {
            // none of _nextDataToSend will be sent yet..
            totalDataLengthToWrite += data.length
        }

        _uploadData = UploadData(filename: filename, dataLength: totalDataLengthToWrite, uploadHandler: uploadHandler)
        uploading = true;

        DLog("uploading file...")
        // Write the command as an 8-bit value..
        var uartCommand: Int8 = CDWheelUARTCommandUploadFile.rawValue
        // the uartCommand, followed by the value..
        let dataToSend: NSMutableData = NSMutableData(bytes: &uartCommand, length: MemoryLayout.size(ofValue: uartCommand))
        
        dataToSend.writeString(filename)
        
        dataToSend.writeUInt32(dataLength)
        
        dataToSend.append(dataToWrite);
        
        // No response might be faster...but we could ignore *MORE* writes until we get a response to avoid flooding it
        _startSendingUARTData(dataToSend as Data)
    }

//    internal func writeNewSequenceFileWithData(dataToWrite: NSData, filename: String, uploadHandler: CDWheelConnectionUploadHandler) {
//        uploadFileWithData(dataToWrite, filename: filename, uploadHandler: uploadHandler);
//    }
    
    fileprivate var m_orientationStreamingURL: URL?
    dynamic var isStreamingOrentationData: Bool = false
    func startOrientationStreamingToURL(_ url: URL) {
        m_orientationStreamingURL = url
        isStreamingOrentationData = true;
        _writeWheelUARTCommand(CDWheelUARTCommandOrientationStartStreaming)
    }
    func endOrientationStreaming() {
//        m_orientationStreamingURL = nil
        isStreamingOrentationData = false
        _writeWheelUARTCommand(CDWheelUARTCommandOrientationEndStreaming)
    }
    
    fileprivate func _writeOrientationData(_ data: Data, toURL fileURL: URL) {
        do {
            let fileHandle = try FileHandle(forWritingTo: fileURL)
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
            fileHandle.closeFile()
            
        } catch let error as NSError {
//            NSApp.presentError(error)
            NSLog("Can't write to log file: %@", error)
        }
    }
    
    
    func removeFile(_ filename: String) {
        var uartCommand: Int8 = CDWheelUARTCommandDeletePatternSequence.rawValue
        let dataToSend: NSMutableData = NSMutableData(bytes: &uartCommand, length: MemoryLayout.size(ofValue: uartCommand))
        dataToSend.writeString(filename);
        _startSendingUARTData(dataToSend as Data)
        // Remove it..
        if let index = self.customSequences.index(of: filename) {
            self.customSequences.remove(at: index)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic == _uartTransmitCharacteristic {
            // After initial response, start sending the file.....if we  need toooo
//            sendMoreData();
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        DLog("didUpdateNotify for characteristic: %@", stringFromUUID(characteristic.uuid))
        // We have to wait until we did update the notification state before we can request status...otherwise we loose "packets"
        if characteristic == _uartRecieveCharacteristic {
            _updateCurrentPatternItem()
        }
    }
    
    func stringFromUUID(_ uuid: CBUUID) -> String {
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
//    private var _dataToReceive: NSMutableData? = nil;
//    private var _dataRecieveCommand: CDWheelUARTRecieveCommand = CDWheelUARTRecieveCommandInvalid

    fileprivate var _dataReader: CDDataReader?
    fileprivate func _commonDataReaderDoneWithUnusedData(_ unusedData: Data?) {
        _dataReader = nil;
        // Start reading more, if necessary
        if let unusedData = unusedData {
            _recieveIncomingUARTData(unusedData)
        }
    }
    
    fileprivate func _didCompleteReadOfPatternInfo(_ dataReader: CDDataReader, unusedData: Data?) {
        let dataReader = dataReader as! CDGetCurrentPatternInfoDataReader
        self.currentPatternItemFilename = dataReader.currentPatternItemFilename
        self.currentPatternSequenceFilename = dataReader.currentPatternSequenceFilename
        self.currentPatternItem = dataReader.currentPatternItem
        _commonDataReaderDoneWithUnusedData(unusedData)
        _requestCustomSequencesIfNeeded()
    }
    
    fileprivate func _didCompleteReadOfCustomSequences(_ dataReader: CDDataReader, unusedData: Data?) {
        let dataReader = dataReader as! CDGetFilenamesDataReader
        self.customSequences = dataReader.filenames
        
        _commonDataReaderDoneWithUnusedData(unusedData)
    }
        
    fileprivate func _didCompleteOrientationRead(_ dataReader: CDDataReader, unusedData: Data?) {
        let dataReader = dataReader as! CDOrientationDataReader
        // m_orientationStreamingURL might be reset
        if let url = m_orientationStreamingURL {
            _writeOrientationData(dataReader.result, toURL: url)
        }
        
        _commonDataReaderDoneWithUnusedData(unusedData)
    }

    
    fileprivate func _didFailDataReader(_ dataReadre: CDDataReader) {
        _dataReader = nil;
    }
    
    fileprivate func _startNewDataReaderWithData(_ data: Data) {
        // Read the first byte to see what to create
        var dataRecieveCommand: CDWheelUARTRecieveCommand = CDWheelUARTRecieveCommandInvalid
        (data as NSData).getBytes(&dataRecieveCommand, length: MemoryLayout.size(ofValue: dataRecieveCommand))
        
        switch (dataRecieveCommand) {
        case CDWheelUARTRecieveCommandInvalid:
            // Done.. error state... droppingt the data..
            print("Invalid command, data: %@", data);
        case CDWheelUARTRecieveCommandCurrentPatternInfo:
            _dataReader = CDGetCurrentPatternInfoDataReader(completionHandler: _didCompleteReadOfPatternInfo, timeoutHandler: _didFailDataReader);
            _dataReader!.addData(data)
        case CDWheelUARTRecieveCommandCustomSequences:
            _dataReader = CDGetFilenamesDataReader(completionHandler: _didCompleteReadOfCustomSequences, timeoutHandler: _didFailDataReader);
            _dataReader!.addData(data)
        case CDWheelUARTRecieveCommandUploadFinished:
            _markUploadSucceeded(true)
            break;
        case CDWheelUARTRecieveCommandOrientationData:
            _dataReader = CDOrientationDataReader(completionHandler: _didCompleteOrientationRead, timeoutHandler: _didFailDataReader);
            _dataReader!.addData(data)
            break;
        default:
            // An invalid value; we drop the data
            print("Invalid UART data: %@", data);
            break
        }
    }
    
    func requestCustomSequences() {
        _requestedCustomSequences = false;
        _requestCustomSequencesIfNeeded()
    }
    
    fileprivate func _recieveIncomingUARTData(_ data: Data) {
        DLog("_recieveIncomingUARTData: %@", data as CVarArg)
        // Feed the existing, or create a new one!
        if let dataReader = _dataReader {
            dataReader.addData(data)
        } else {
            _startNewDataReaderWithData(data)
        }
    }
    
    fileprivate var _requestedCustomSequences = false
    
    fileprivate func _requestCustomSequencesIfNeeded() {
        if (!_requestedCustomSequences) {
            _requestedCustomSequences = true;
            _writeWheelUARTCommand(CDWheelUARTCommandRequestCustomSequences)
        }
    }
    
//    var customSequenceFilenames: [String] = []
//    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if error != nil {
            // TODO: present the error...make sure they aren't piling up
            // not sure why _uartRecieveCharacteristic kicks this off
            if characteristic != _uartRecieveCharacteristic {
                debugPrint("didUpdateValueForCharacteristic error:\(error)!")
            }
            return;
        }
        
        if (characteristic == _brightnessReadCharacteristic) {
            if let data = characteristic.value {
                _updateBrightnessFromData(data)
            }
        } else if (characteristic == _stateCharacteristic) {
            if let data = characteristic.value {
                self.wheelState = CDWheelState(data.readLittleEndianFromBigEndianInt16());
            }
        } else if characteristic == _uartRecieveCharacteristic {
            if let data = characteristic.value {
                _recieveIncomingUARTData(data)
            } else {
                DLog("NO _uartRecieveCharacteristic data??");
            }
        } else if (characteristic == _fpsChar) {
            _updateFPS()
        }
    }
    
    

}
