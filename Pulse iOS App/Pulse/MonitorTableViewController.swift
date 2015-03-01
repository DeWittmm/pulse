//
//  MonitorTableViewController.swift
//  Pulse
//
//  Created by Michael DeWitt on 1/20/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import UIKit
import CoreBluetooth
import HealthKit
import BLEDataProcessing

class MonitorTableViewController: UITableViewController, DataAnalysisDelegate, HKAccessProtocol, BLEDataTransferDelegate {
    
    //MARK: Outlets
    
    @IBOutlet weak var monitorLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var progressBar: UIProgressView!
    
    @IBOutlet weak var bpmLabel: UILabel!
    @IBOutlet weak var spO2Label: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var packetSize: UILabel!
    
    @IBOutlet weak var hrGraph: BEMSimpleLineGraphView!
    @IBOutlet weak var sp02Graph: BEMSimpleLineGraphView!
    
    //MARK: Properties
    var healthStore: HKHealthStore?

    let dataCruncher = DataCruncher()
    
    var redLEDGraphDelegate = GraphDelegate()
    var irGraphDelegate: GraphDelegate = GraphDelegate()
    
    var isConnected: Bool = false {
        didSet {
            if (isConnected) {
                if let service = btDiscovery.bleService {
                    monitorLabel.text = "\(service.peripheral.name)"
                    activityIndicator.stopAnimating()
                }
            }
            else {
                monitorLabel.text = "Searching..."
                activityIndicator.startAnimating()
                println("BLE Disconnected")
            }
        }
    }
    
    let btDiscovery = btDiscoverySharedInstance
    
    //Observers
    let bleStatusNotification: Notification<Bool> = Notification(name:BLEServiceChangedStatusNotification)
    private lazy var observer: NotificationObserver = {
        NotificationObserver(notification: self.bleStatusNotification, block: self.bleConnectionChanged)
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tabBarController?.tabBar.translucent = false

        isConnected = false
        
        dataCruncher.delegate = self
        btDiscovery.startScanning()
        
        redLEDGraphDelegate.graphView = hrGraph
        redLEDGraphDelegate.data = [0.0, 0.0]
        
        irGraphDelegate.graphView = sp02Graph
        irGraphDelegate.data = [15.0, 15.0]
        
        observer.observer //simply instantiating lazy var
        
        sp02Graph.colorLine = UIColor.blueColor()
        sp02Graph.backgroundColor = UIColor.clearColor()
        
        hrGraph.colorLine = UIColor.redColor()
        hrGraph.backgroundColor = UIColor.clearColor()
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        sp02Graph.reloadGraph()
        hrGraph.reloadGraph()
        
        bleRead()
//        healthStore?.requestAccess()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: DataAnalysisDelegate
    
    func currentProgress(irDataProg: Double, ledDataProg: Double) {
        progressBar.progress = Float(ledDataProg)
        
        let ledPercentage = ledDataProg*100.0 - 1 //99% instead of 100
        let irPercentage = irDataProg*100.0 - 1
        
        packetSize.text = String(format:"LED: %2.0f%%, IR: %2.0f%%", arguments: [ledPercentage, irPercentage])
    }
    
    func analysingIRData(InfaredData: [Double]) {
        if !InfaredData.isEmpty {
            irGraphDelegate.data = InfaredData
        }
    }
    
    func analysingLEDData(redLEDData: [Double]) {
        if !redLEDData.isEmpty {
            redLEDGraphDelegate.data = redLEDData
        }
    }
    
    func analysisFoundHeartRate(hr: Double)  {
        bpmLabel.text = String(format:"%.01f BPM", arguments: [hr])
    }
    
    func analysisFoundSP02(sp02: Double) {
        spO2Label.text = String(format:"%.01f SP02", arguments: [sp02])
    }
    
    //MARK: BLE Connection
    func characteristic(characteristic: CBCharacteristic, didRecieveData data: [UInt8]) {
        dataCruncher.addDataForCrunching(data)
    }
    
    func peripheral(peripheral: CBPeripheral, DidUpdateRSSI newRSSI: Int) {
        println("RSSI: \(newRSSI)")
        rssiLabel.text = "\(newRSSI)"
    }
    
    func bleConnectionChanged(connected: Bool) {
        // Indicate Connection status changed.
        isConnected = connected;
        
        if connected {
            self.beginBLEReading()
        }
        
        self.tableView.reloadData()
    }
    
    func beginBLEReading() {
        if let service = btDiscovery.bleService {
            service.delegate = self
            service.readFromConnectedCharacteristics()
        }
    }
    
    func bleRead() {
        if let service = btDiscovery.bleService {
            service.readFromConnectedCharacteristics()
        }
    }
}
