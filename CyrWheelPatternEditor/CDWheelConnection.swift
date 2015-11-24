//
//  CDWheelConnection.swift
//  CyrWheelPatternEditor
//
//  Created by Corbin Dunn on 11/22/15 .
//  Copyright © 2015 Corbin Dunn. All rights reserved.
//

import Cocoa
import CoreBluetooth

class CDWheelConnection: NSObject, CBPeripheralDelegate {
    internal var peripheral: CBPeripheral
    private var cyrWheelService: CBService?
    private var commandCharacteristic: CBCharacteristic?
    private var getSequencesCharacteristic: CBCharacteristic?
    
    
    init(peripheral: CBPeripheral) {
        self.peripheral = peripheral;
        super.init()
        peripheral.delegate = self;
        peripheral.discoverServices(nil); // TODO: limit services!
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverServices error: NSError?) {
        if peripheral.services == nil {
            print("no services found"); // corbin testing
            return;
        }
        
        for service: CBService in peripheral.services! {
            print("found service: ", service.UUID);
            if (service.UUID.isEqual(CBUUID(string: kLEDWheelServiceUUID))) {
                cyrWheelService = service;
                peripheral.discoverCharacteristics(nil, forService: service);
            }

        }
    }
    
    func peripheral(peripheral: CBPeripheral, didDiscoverCharacteristicsForService service: CBService, error: NSError?) {
        print("characteristics found for service", service)
        if service.characteristics == nil {
            return;
        }
        for characteristic: CBCharacteristic in service.characteristics! {
            print("\tcharactaristic", characteristic)
            let uuid = characteristic.UUID;
            if uuid.isEqual(CBUUID(string: kLEDWheelCharSendCommandUUID)) {
                commandCharacteristic = characteristic
//                currentPeripheral.setNotifyValue(true, forCharacteristic: rxCharacteristic!)
            } else if uuid.isEqual(CBUUID(string: kLEDWheelCharRecieveSequencesUUID)) {
                getSequencesCharacteristic = characteristic
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
            }
        }
    }
    
    internal func sendCommand(command: CDWheelCommand) {
        if commandCharacteristic == nil {
            return;
        }
        var val = command.rawValue.bigEndian
        let data: NSData = NSData(bytes: &val, length: sizeofValue(val))
        peripheral.writeValue(data, forCharacteristic: commandCharacteristic!, type: CBCharacteristicWriteType.WithoutResponse)
    }
    
    
    
    
    

}
