//
//  BTServiceManager.swift
//  Originally adapted from: http://www.raywenderlich.com/85900/arduino-tutorial-integrating-bluetooth-le-ios-swift
//  Copyright: http://www.raywenderlich.com/faq
//

//  Modified by: Michael DeWitt 1/19/2015

import Foundation
import CoreBluetooth

// MARK: Services & Characteristics UUIDs for BLUETOOTH LOW ENERGY TINYSHIELD - REV 2
let BLEServiceUUID = CBUUID(string: "195ae58a-437a-489b-b0cd-b7c9c394bae4")
let BLEChar1UUID = CBUUID(string: "5fc569a0-74a9-4fa4-b8b7-8354c86e45a4")
let BLEChar2UUID = CBUUID(string: "21819ab0-c937-4188-b0db-b9621e1696cd")

let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"

class BTServiceManager: NSObject, CBPeripheralDelegate {
    var peripheral: CBPeripheral
    var positionCharacteristic: CBCharacteristic?
    
    init(initWithPeripheral peripheral: CBPeripheral) {
        self.peripheral = peripheral

        super.init()
        self.peripheral.delegate = self
    }
    
    deinit {
        self.reset()
    }
    
    func startDiscoveringServices() {
        self.peripheral.discoverServices([BLEServiceUUID])
    }
    
    func reset() {
        //TODO: Is this a better approach than an optional peripheral"?"
        // Resetting to general CBPeripheral
        peripheral = CBPeripheral()
        
        // Deallocating therefore send notification
        self.sendBTServiceNotificationWithIsBluetoothConnected(false)
    }
    
    // Mark: CBPeripheralDelegate
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
        let uuidsForBTService: [CBUUID] = [BLEChar1UUID]
        
        // Wrong Peripheral
        if (peripheral != self.peripheral) {
            return
        }
        
        if (error != nil) {
            return
        }
        
        // No Services
        if ((peripheral.services == nil) || (peripheral.services.count == 0)) {
            return
        }
        
        for service in peripheral.services {
            if service.UUID == BLEServiceUUID {
                peripheral.discoverCharacteristics(uuidsForBTService, forService: service as CBService)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        if (peripheral != self.peripheral) {
            // Wrong Peripheral
            return
        }
        
        if (error != nil) {
            return
        }
        
        for characteristic in service.characteristics {
            if characteristic.UUID == BLEChar1UUID {
                self.positionCharacteristic = (characteristic as CBCharacteristic)
                peripheral.setNotifyValue(true, forCharacteristic: characteristic as CBCharacteristic)
                
                // Send notification that Bluetooth is connected and all required characteristics are discovered
                self.sendBTServiceNotificationWithIsBluetoothConnected(true)
            }
        }
    }
    
    // Mark: - Private
    
    func writePosition(position: UInt8) {
        // See if characteristic has been discovered before writing to it
        if positionCharacteristic == nil {
            return
        }
        
        // Need a mutable var to pass to writeValue function
        var positionValue = position
        let data = NSData(bytes: &positionValue, length: sizeof(UInt8))
        peripheral.writeValue(data, forCharacteristic: positionCharacteristic, type: CBCharacteristicWriteType.WithResponse)
    }
    
    func sendBTServiceNotificationWithIsBluetoothConnected(isBluetoothConnected: Bool) {
        let connectionDetails = ["isConnected": isBluetoothConnected]
        NSNotificationCenter.defaultCenter().postNotificationName(BLEServiceChangedStatusNotification, object: self, userInfo: connectionDetails)
    }
    
}