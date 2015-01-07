//
//  BLEDelgate.swift
//  Pulse
//
//  Created by Michael DeWitt on 11/13/14.
//  Copyright (c) 2014 Biomedical Engineering Design. All rights reserved.
//

import Foundation

class BLEManager: NSObject, BLEDelegate {
    
    var isConnected: Bool {
        return false
    }
    
    private let ble: BLE
    
    // MARK: Initilizers
    
    override init() {
        ble = BLE()
        ble.controlSetup()
        
        super.init()
        
        ble.delegate = self
    }
    
    //MARK: BLE Delegate
    
    func bleDidConnect() {
        
        //Part of BLE protocol
        let buf: [UInt8] = [0x04, 0x00, 0x00]
        let data = NSData(bytes: buf, length: 3)
        ble.write(data)
    }
    
    func bleDidDisconnect() {
        
    }
    
    func bleDidUpdateRSSI(rssi: NSNumber!) {
        
    }
    
    func bleDidReceiveData(data: UnsafeMutablePointer<UInt8>, length: Int32) {
        
    }
}