//
//  BTServiceManager.swift
//  Originally adapted from: http://www.raywenderlich.com/85900/arduino-tutorial-integrating-bluetooth-le-ios-swift
//  Copyright: http://www.raywenderlich.com/faq
//

//  Modified by: Michael DeWitt 1/19/2015

import Foundation
import CoreBluetooth

protocol BLEServiceDelegate {
    func characteristic(characteristic: CBCharacteristic, didCollectDataBin bin: [UInt8])
    func peripheral(peripheral: CBPeripheral, DidUpdateRSSI newRSSI: Int)
    
    func characteristic(characteristic: CBCharacteristic, hasCollectedPercentageOfBin percentage: Double)
}
let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"


class BTServiceManager: NSObject, CBPeripheralDelegate {
    
    //MARK: Properties
    
    var delegate: BLEServiceDelegate?
    
    let binCapacity = 500
    var dataBin = [UInt8]()
    
    var peripheral: CBPeripheral
    var readCharacteristic: CBCharacteristic?
    var writeCharacteristic: CBCharacteristic?

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
//                peripheral.discoverCharacteristics(characteristicUUIDS, forService: service as! CBService)
//            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didDiscoverCharacteristicsForService service: CBService!, error: NSError!) {
        
        // Wrong Peripheral
        if (peripheral != self.peripheral) {
            println("Error DiscoveredCharacterisitics for unknown peripheral:  \(error?.localizedDescription)")
            return
        }
        
        println("Found \(service.characteristics.count) characteristics")
        for characteristic in service.characteristics as! [CBCharacteristic] {
            
            if find(characteristicUUIDS, characteristic.UUID) != nil {
                println("--- \(characteristic.UUID.description)")
                readCharacteristic = characteristic
                
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
                    self.delegate?.characteristic(characteristic, didCollectDataBin: bin)
                    return
                }
            }
            self.delegate?.characteristic(characteristic, hasCollectedPercentageOfBin: Double(dataBin.count)/Double(binCapacity))
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didReadRSSI RSSI: NSNumber!, error: NSError!) {
        dispatch_async(dispatch_get_main_queue()) {
            self.delegate?.peripheral(peripheral, DidUpdateRSSI: RSSI.integerValue)
            return
        }
    }
    
    func readFromConnectedCharacteristics() {
        peripheral.readRSSI()
        
        if let charcteristic = readCharacteristic {
            peripheral.readValueForCharacteristic(readCharacteristic)
        }
    }
    
    // Mark: Private
    
    func sendBTServiceNotification(# isBluetoothConnected: Bool) {
        postNotification(Notification<Bool>(name: BLEServiceChangedStatusNotification), isBluetoothConnected)
    }
    
}