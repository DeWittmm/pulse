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
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: TableViewDelegate
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
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

}
