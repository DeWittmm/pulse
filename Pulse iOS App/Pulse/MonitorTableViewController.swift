//
//  MonitorTableViewController.swift
//  Pulse
//
//  Created by Michael DeWitt on 1/20/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import UIKit

let HeartRateCellIdentifier = "HeartRateCell"
let BloodOxygenCellIdentifier = "BloodOxygenCell"
let DeviceInfoCellIdentifier = "DeviceInfoCell"
let RSSICellIdentifier = "RSSICell"

class MonitorTableViewController: UITableViewController {
    
    let btDiscovery = btDiscoverySharedInstance
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        btDiscovery.startScanning()
        
        // Watch Bluetooth connection
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("connectionChanged:"), name: BLEServiceChangedStatusNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: BLEServiceChangedStatusNotification, object: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: TableViewDelegate
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if btDiscovery.bleService != nil {
            return 4
        }
        
        createEmptyTableView()
        return 0
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        var identifier = ""
        
        switch indexPath.row {
        case 0:
            identifier = HeartRateCellIdentifier
        case 1:
            identifier = BloodOxygenCellIdentifier
        case 2:
            identifier = DeviceInfoCellIdentifier
        case 3:
            identifier = RSSICellIdentifier
        default:
            break
        }
        
        return tableView.dequeueReusableCellWithIdentifier(identifier) as UITableViewCell
    }
    
    override func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        switch indexPath.row {
        case 0:
            return 200
        case 1:
            return 200
        default:
            return 44
        }
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
    
    //MARK: BLE Connection
    
    func bleConnectionChanged(notification: NSNotification) {
        // Connection status changed. Indicate on GUI.
        let userInfo = notification.userInfo as [String: Bool]
        
        dispatch_async(dispatch_get_main_queue(), {
            // Set image based on connection status
            if let isConnected: Bool = userInfo["isConnected"] {
                if isConnected {
                    self.tableView.reloadData()
                } else {
                    println("Disconnected")
                }
            }
        });
    }

}
