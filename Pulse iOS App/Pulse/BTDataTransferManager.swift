//
//  BTDataTransferManager.swift
//  Pulse
//
//  Created by Michael DeWitt on 2/13/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import CoreBluetooth

protocol BLEDataTransferDelegate {
    func characteristic(characteristic: CBCharacteristic, didCollectDataBin bin: [UInt8])
    func peripheral(peripheral: CBPeripheral, DidUpdateRSSI newRSSI: Int)
    
    func characteristic(characteristic: CBCharacteristic, hasCollectedPercentageOfBin percentage: Double)
}

let binCapacity = 500

class BTDataTransferManager: BTServiceManager {
    
    var dataBin = [UInt8]()
    
    var delegate: BLEDataTransferDelegate?
    
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