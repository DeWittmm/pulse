//
//  BTServiceManager.swift
//  Originally adapted from: http://www.raywenderlich.com/85900/arduino-tutorial-integrating-bluetooth-le-ios-swift
//  Copyright: http://www.raywenderlich.com/faq
//

//  Modified by: Michael DeWitt 1/19/2015

import Foundation
import CoreBluetooth

protocol BLEServiceDelegate {
    func characteristicDidCollectBin(bin: [Int8])
    func peripheralDidUpdateRSSI(newRSSI: Int)
}

// MARK: Services & Characteristics UUIDs for BLUETOOTH LOW ENERGY TINYSHIELD - REV 2
let BLEServiceUUID = CBUUID(string: "195ae58a-437a-489b-b0cd-b7c9c394bae4")
let BLEChar1UUID = CBUUID(string: "5fc569a0-74a9-4fa4-b8b7-8354c86e45a4")
let BLEChar2UUID = CBUUID(string: "21819ab0-c937-4188-b0db-b9621e1696cd")

let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"

class BTServiceManager: NSObject, CBPeripheralDelegate {
    
    //MARK: Properties
    
    var delegate: BLEServiceDelegate?
    
    var peripheral: CBPeripheral
    var heartRateCharacteristic: CBCharacteristic?
    var pulseOxCharacteristic: CBCharacteristic?

    init(initWithPeripheral peripheral: CBPeripheral) {
        self.peripheral = peripheral

        super.init()
        self.peripheral.delegate = self
    }
    
    deinit {
        self.reset()
    }
    
    func startDiscoveringServices() {
        //FIXME
//        self.peripheral.discoverServices([BLEServiceUUID])
        self.peripheral.discoverServices(nil)
    }
    
    func reset() {
        //TODO: Is this a better approach than an optional peripheral"?"
        // Resetting to general CBPeripheral
        
        //FIXME: Causes Crash
//        peripheral = CBPeripheral()
        
        // Deallocating therefore send notification
        sendBTServiceNotification(isBluetoothConnected: false)
    }
    
    // Mark: CBPeripheralDelegate
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverServices error: NSError!) {
//        let uuidsForBTService: [CBUUID] = [BLEChar1UUID, BLEChar2UUID]
        let uuidsForBTService: [CBUUID] = [BLEChar2UUID]
        
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
        
        println("Found \(peripheral.services.count) services")
        for service in peripheral.services {
            if service.UUID == BLEServiceUUID {
                peripheral.discoverCharacteristics(uuidsForBTService, forService: service as CBService)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        // Wrong Peripheral
        if (peripheral != self.peripheral) {
            return
        }
        
        if (error != nil) {
            println("Error DiscoveringCharacteristicsForService: \(error.localizedDescription)")
            return
        }
        
        println("Found \(service.characteristics.count) characteristics")
        for characteristic in service.characteristics {
            
            //TODO: Identify HR vs. BloodO2 characteristic
            if characteristic.UUID == BLEChar1UUID {
                println("--- BLEChar1")
                heartRateCharacteristic = (characteristic as CBCharacteristic)
                peripheral.setNotifyValue(true, forCharacteristic: characteristic as CBCharacteristic)
                
                // Send notification that Bluetooth is connected and all required characteristics are discovered
                sendBTServiceNotification(isBluetoothConnected: true)
            }
            else if characteristic.UUID == BLEChar2UUID {
                println("--- BLEChar2")
                pulseOxCharacteristic = (characteristic as CBCharacteristic)
                peripheral.setNotifyValue(true, forCharacteristic: characteristic as CBCharacteristic)
                
                // Send notification that Bluetooth is connected and all required characteristics are discovered
                sendBTServiceNotification(isBluetoothConnected: true)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        
    }
    
    //Mark: Update Delegate
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if let error = error {
            println(error.localizedDescription)
        }
        
        if let data = characteristic.value {
//            var values = [Int8](count: data.length, repeatedValue: 0)
//            data.getBytes(&values)
            
            var bytes = UnsafePointer<Int8>(data.bytes)
            var arr = [Int8]()
            for var i = 0; i < data.length; i++ {
                let elem = bytes[i]
                arr.append(elem)
            }
            dispatch_async(dispatch_get_main_queue()) {
                self.delegate?.characteristicDidCollectBin(arr)
                return
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didReadRSSI RSSI: NSNumber!, error: NSError!) {
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate?.peripheralDidUpdateRSSI(RSSI.integerValue)
            return
        }
    }
    
    func readFromConnectedCharacteristics() {
        peripheral.readRSSI()
        
        if let hrCharacteristic = heartRateCharacteristic {
            peripheral.readValueForCharacteristic(heartRateCharacteristic)
        }
        
        if let IRCharacteristic = pulseOxCharacteristic {
            peripheral.readValueForCharacteristic(pulseOxCharacteristic)
        }
    }
    
    // Mark: Private
    
    func sendBTServiceNotification(# isBluetoothConnected: Bool) {
//        let connectionDetails = ["isConnected": isBluetoothConnected]
        postNotification(Notification<Bool>(name: BLEServiceChangedStatusNotification), isBluetoothConnected)
    }
    
}