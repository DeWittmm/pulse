//
//  MonitorTableViewController.swift
//  Pulse
//
//  Created by Michael DeWitt on 1/20/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import UIKit
import CoreBluetooth

class MonitorTableViewController: UITableViewController, BLEServiceDelegate {
    
    //MARK: Outlets
    
    @IBOutlet weak var bpmLabel: UILabel!
    @IBOutlet weak var spO2Label: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var peripheralIDLabel: UILabel!
    
    
    //MARK: Properties
    
    let btDiscovery = btDiscoverySharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btDiscovery.startScanning()
        
        // Watch Bluetooth connection
//        let bleStatusNotification: Notification<[String : Bool]> = Notification(name:BLEServiceChangedStatusNotification)        
//        NotificationObserver(notification: bleStatusNotification) { userInfo in
//            self.bleConnectionChanged(userInfo)
//        }
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("bleConnectionChanged:"), name: BLEServiceChangedStatusNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: BLEServiceChangedStatusNotification, object: nil)
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        bleRead()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: TableViewDelegate
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if btDiscovery.bleService != nil {
            return 5
        }
        
        createEmptyTableView()
        return 0
    }
        
    func createEmptyTableView() {
        let scanView = UIView(frame: CGRect(origin: CGPointZero, size: tableView.frame.size))
        scanView.backgroundColor = UIColor.whiteColor()
        
        let label = UILabel()
        
        label.center = tableView.center - CGPoint(x: 100, y: 40)
        label.text = "Scanning for BLE devices..."
        label.textAlignment = .Center
        label.sizeToFit()

        let activityIndicator = UIActivityIndicatorView()
        activityIndicator.center = scanView.center
        activityIndicator.startAnimating()
        activityIndicator.color = UIColor.blackColor()
        
        scanView.addSubview(label)
        scanView.addSubview(activityIndicator)
        scanView.autoresizingMask = .FlexibleHeight | .FlexibleWidth
        
        tableView.separatorColor = UIColor.clearColor()
        tableView.backgroundView = scanView
    }
    
    //MARK: BLE Connection (BLEServiceDelegate)
    
    func characteristicDidCollectBin(bin: [Int8]) {
        println("bin: \(bin)")

        bpmLabel.text = "\(bin)"
    }
    
    func peripheralDidUpdateRSSI(newRSSI: Int) {
        println("RSSI: \(newRSSI)")

        rssiLabel.text = "\(newRSSI)"
    }
    
//    func bleConnectionChanged(userInfo: [String: Bool]) {
    func bleConnectionChanged(notification: NSNotification) {
        // Connection status changed. Indicate on GUI.
        let userInfo = notification.userInfo as [String: Bool]
    
        dispatch_async(dispatch_get_main_queue(), {
            if let isConnected: Bool = userInfo["isConnected"] {
                if isConnected {
                    self.tableView.reloadData()
                    self.beginBLEReading()
                } else {
                    self.tableView.reloadData()
                    println("BLE Disconnected")
                }
            }
        });
    }
    
    func beginBLEReading() {
        if let service = btDiscovery.bleService {
            service.delegate = self
            service.readFromConnectedCharacteristics()
            
            peripheralIDLabel.text = "\(service.peripheral.name)"
        }
    }
    
    func bleRead() {
        if let service = btDiscovery.bleService {
            service.readFromConnectedCharacteristics()
            peripheralIDLabel.text = "\(service.peripheral.name)"
        }
    }

}
