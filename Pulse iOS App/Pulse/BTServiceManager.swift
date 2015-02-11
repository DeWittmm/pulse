//
//  BTServiceManager.swift
//  Originally adapted from: http://www.raywenderlich.com/85900/arduino-tutorial-integrating-bluetooth-le-ios-swift
//  Copyright: http://www.raywenderlich.com/faq
//

//  Modified by: Michael DeWitt 1/19/2015

import Foundation
import CoreBluetooth

protocol BLEServiceDelegate {
    func characteristicDidCollectBin(bin: [UInt8])
    func peripheralDidUpdateRSSI(newRSSI: Int)
}
let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"

// MARK: Services & Characteristics UUIDs for: BLUETOOTH LOW ENERGY TINYSHIELD - REV 2
//let BLEServiceUUID = CBUUID(string: "195ae58a-437a-489b-b0cd-b7c9c394bae4")
//let BLEChar1UUID = CBUUID(string: "5fc569a0-74a9-4fa4-b8b7-8354c86e45a4")
//let BLEChar2UUID = CBUUID(string: "21819ab0-c937-4188-b0db-b9621e1696cd")

//REDBEAR LAB
let BLEServiceUUID = CBUUID(string: "713D0000-503E-4C75-BA94-3148F18D941E")
let BLEChar1UUID = CBUUID(string:  "713D0002-503E-4C75-BA94-3148F18D941E") //RBL_CHAR_TX_UUID
let BLEChar2UUID = CBUUID(string: "713D0003-503E-4C75-BA94-3148F18D941E") //RBL_CHAR_RX_UUID


class BTServiceManager: NSObject, CBPeripheralDelegate {
    
    //MARK: Properties
    
    var delegate: BLEServiceDelegate?
    
    let binCapacity = 250
    var dataBin = [UInt8]()
    
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
        for service in peripheral.services as! [CBService] {
            //FIXME: REDBEARLAB
            peripheral.discoverCharacteristics(nil, forService: service)

//            if service.UUID == BLEServiceUUID { //Redundant check
//                peripheral.discoverCharacteristics(uuidsForBTService, forService: service as! CBService)
//            }
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
        for characteristic in service.characteristics as! [CBCharacteristic] {
            
            //TODO: Identify HR vs. BloodO2 characteristic
            if characteristic.UUID == BLEChar1UUID {
                println("--- BLEChar1")
                heartRateCharacteristic = characteristic
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                
                // Send notification that Bluetooth is connected and all required characteristics are discovered
                sendBTServiceNotification(isBluetoothConnected: true)
            }
            else if characteristic.UUID == BLEChar2UUID {
                println("--- BLEChar2")
                pulseOxCharacteristic = characteristic
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                
                // Send notification that Bluetooth is connected and all required characteristics are discovered
                sendBTServiceNotification(isBluetoothConnected: true)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {}
    
    //Mark: Update Delegate
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if let error = error {
            println("ERROR (value from Char): \(error.localizedDescription)")
        }
        
        if let data = characteristic.value {
//            var values = [Int8](count: data.length, repeatedValue: 0)
//            data.getBytes(&values)
            
            var bytes = UnsafePointer<UInt8>(data.bytes)
            var arr = [UInt8]()
            for var i = 0; i < data.length; i++ {
                let elem = bytes[i]
                arr.append(elem)
            }
            dataBin += arr
            
            if (dataBin.count > binCapacity) {
            
                let bin = dataBin
                dataBin.removeAll(keepCapacity: true)
                dispatch_async(dispatch_get_main_queue()) {
                    self.delegate?.characteristicDidCollectBin(bin)
                    return
                }
            }
            println("Building Bin: \(dataBin.count)")
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
        postNotification(Notification<Bool>(name: BLEServiceChangedStatusNotification), isBluetoothConnected)
    }
    
}