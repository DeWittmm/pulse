//
//  FirstViewController.swift
//  Pulse
//
//  Created by Michael DeWitt on 10/26/14.
//  Copyright (c) 2014 Biomedical Engineering Design. All rights reserved.
//

import UIKit

class MonitorViewController: UIViewController {
    
    let btDiscovery = BTDiscovery()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        btDiscovery.startScanning()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
}

