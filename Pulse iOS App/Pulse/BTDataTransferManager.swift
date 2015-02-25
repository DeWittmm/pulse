//
//  BTDataTransferManager.swift
//  Pulse
//
//  Created by Michael DeWitt on 2/13/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import CoreBluetooth

protocol BLEDataTransferDelegate: PeripheralUpdateDelegate {
    func characteristic(characteristic: CBCharacteristic, didRecieveData data: [UInt8])
}

class BTDataTransferManager: BTServiceManager {
    
    
    var delegate: BLEDataTransferDelegate?
    
    //Mark: Update Delegate
    
    func peripheral(peripheral: CBPeripheral!, didUpdateValueForCharacteristic characteristic: CBCharacteristic!, error: NSError!) {
        if let error = error {
            println("ERROR (value from Char): \(error.localizedDescription)")
        }
        
        if let data = characteristic.value {
            var values = [UInt8](count: data.length, repeatedValue: 0)
            data.getBytes(&values)
            
            self.delegate?.characteristic(characteristic, didRecieveData: values)
        }
    }
    
    //MARK: Read/ Write
    
    func readFromConnectedCharacteristics() {
        peripheral.readRSSI()
        
        for rcharacteristic in readCharacteristics {
            if let char = rcharacteristic {
                peripheral.readValueForCharacteristic(char)
            }
        }
    }
    
    func writeValueToConnectedCharacteristics(var value: Int) {
        
        let data = NSData(bytes:&value, length: sizeof(Int))
        for wcharacteristic in writeCharacteristics {
            if let char = wcharacteristic {
                peripheral.writeValue(data, forCharacteristic: char, type: CBCharacteristicWriteType.WithResponse)
            }
        }
    }
    
}