//
//  BTDiscovery.swift
//  Originally adapted from: http://www.raywenderlich.com/85900/arduino-tutorial-integrating-bluetooth-le-ios-swift
//  Copyright: http://www.raywenderlich.com/faq
//

//  Modified by: Michael DeWitt 1/19/2015
//  Notes: In many cases I have removed optional values and if-let statements
//  in favor of more explicint representations of the properties.
//  Also removed a ton of unecessary self. & ; 😔

/* This class is designed as a wrapper to manage 
 the discovery and connetion to all BLE Peripheral devices.
*/


import Foundation
import CoreBluetooth

let btDiscoverySharedInstance = BTDiscovery();

class BTDiscovery: NSObject, CBCentralManagerDelegate {
    
    private var centralManager: CBCentralManager! //Would be much better as let
    private var peripheralBLE: CBPeripheral?
    
    var bleService: BTServiceManager? {
        didSet {
            bleService?.startDiscoveringServices()
        }
    }
    
    override init() {
        
        super.init()
        
        let centralQueue = dispatch_queue_create("com.centralBLEManagerQueue", DISPATCH_QUEUE_SERIAL)
        centralManager = CBCentralManager(delegate:self, queue: centralQueue)
    }
    
    func startScanning() {
        //Although "Not recommended" passing nil for the BLEServiceUUID's will search for all devices
        centralManager.scanForPeripheralsWithServices([BLEServiceUUID], options: nil)
    }
    
    // MARK: CBCentralManagerDelegate
    
    func centralManager(central: CBCentralManager!, didDiscoverPeripheral peripheral: CBPeripheral!, advertisementData: [NSObject : AnyObject]!, RSSI: NSNumber!) {
        // Be sure to retain the peripheral or it will fail during connection.
        
        // Validate peripheral information
        if (peripheral == nil || peripheral.name == nil || peripheral.name.isEmpty) {
            return
        }
        
        // If not already connected to a peripheral, then connect to this one
        if ((peripheralBLE == nil) || (peripheralBLE?.state == CBPeripheralState.Disconnected)) {
            peripheralBLE = peripheral
            
            // Reset service
            bleService = nil
            
            // Connect to peripheral
            central.connectPeripheral(peripheral, options: nil)
        }
    }
    
    func centralManager(central: CBCentralManager!, didConnectPeripheral peripheral: CBPeripheral!) {
        
        if (peripheral == nil) {
            return
        }
        
        // Create new service class
        if (peripheral == peripheralBLE) {
            bleService = BTServiceManager(initWithPeripheral: peripheral)
        }
        
        // Stop scanning for new devices
        central.stopScan()
        println("Connected to peripheral \(peripheral)")
    }
    
    func centralManager(central: CBCentralManager!, didDisconnectPeripheral peripheral: CBPeripheral!, error: NSError!) {
        
        if (peripheral == nil) {
            return
        }
        
        // See if it was our peripheral that disconnected
        if (peripheral == peripheralBLE) {
            clearDevices()
        }
        
        // Start scanning for new devices
        startScanning()
    }
    
    // MARK: Private
    
    func clearDevices() {
        bleService = nil
        peripheralBLE = nil
    }
    
    func centralManagerDidUpdateState(central: CBCentralManager!) {
        switch (central.state) {
        case CBCentralManagerState.PoweredOff:
            clearDevices()
            
        case CBCentralManagerState.Unauthorized:
            // Indicate to user that the iOS device does not support BLE.
            break
            
        case CBCentralManagerState.Unknown:
            // Wait for another event
            break
            
        case CBCentralManagerState.PoweredOn:
            startScanning()
            
        case CBCentralManagerState.Resetting:
            clearDevices()
            
        case CBCentralManagerState.Unsupported:
            break
            
        default:
            break
        }
    }
    
}
