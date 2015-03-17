//
//  BTServiceManager.swift
//  Originally adapted from: http://www.raywenderlich.com/85900/arduino-tutorial-integrating-bluetooth-le-ios-swift
//  Copyright: http://www.raywenderlich.com/faq
//

//  Modified by: Michael DeWitt 1/19/2015

import CoreBluetooth

let BLEServiceChangedStatusNotification = "kBLEServiceChangedStatusNotification"

protocol PeripheralUpdateDelegate {
    func peripheral(peripheral: CBPeripheral, DidUpdateRSSI newRSSI: Int)
}

class BTServiceManager: NSObject, CBPeripheralDelegate {
    
    //MARK: Properties
    var updateDelegate: PeripheralUpdateDelegate?
    
    var peripheral: CBPeripheral
    var readCharacteristics = [CBCharacteristic?]()
    var writeCharacteristics = [CBCharacteristic?]()

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
        for service in peripheral.services as [CBService] {
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
        for characteristic in service.characteristics as [CBCharacteristic] {
            
            if find(characteristicUUIDS, characteristic.UUID) != nil {
                println("--- \(characteristic.UUID.description)")
                
                if characteristic.properties == CBCharacteristicProperties.Read {
                    readCharacteristics.append(characteristic)
                }
                else if characteristic.properties == CBCharacteristicProperties.Write {
                    writeCharacteristics.append(characteristic)
                }
                
                peripheral.setNotifyValue(true, forCharacteristic: characteristic)
                
                // Send notification that Bluetooth is connected and all required characteristics are discovered
                sendBTServiceNotification(isBluetoothConnected: true)
            }
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didReadRSSI RSSI: NSNumber!, error: NSError!) {
        dispatch_async(dispatch_get_main_queue()) {
            self.updateDelegate?.peripheral(peripheral, DidUpdateRSSI: RSSI.integerValue)
            return
        }
    }
    
    func peripheral(peripheral: CBPeripheral!, didUpdateNotificationStateForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {}
    
    // Mark: Private
    
    func sendBTServiceNotification(# isBluetoothConnected: Bool) {
        postNotification(Notification<Bool>(name: BLEServiceChangedStatusNotification), isBluetoothConnected)
    }
    
}