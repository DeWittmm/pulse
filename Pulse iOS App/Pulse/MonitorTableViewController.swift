//
//  MonitorTableViewController.swift
//  Pulse
//
//  Created by Michael DeWitt on 1/20/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import UIKit
import CoreBluetooth
import BLEDataProcessing

class MonitorTableViewController: UITableViewController, BLEDataTransferDelegate, PeripheralUpdateDelegate, DataAnalysisDelegate {
    
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
    
    let dataCruncher = DataCruncher()
    var rawDataBin = [UInt8]()
    
    lazy var hrGraphDelegate: GraphDelegate = {
        GraphDelegate(graph: self.hrGraph)
    }()
    
    lazy var sp02GraphDelegate: GraphDelegate = {
        GraphDelegate(graph: self.sp02Graph)
    }()
    
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
        isConnected = false
        
        super.viewDidLoad()
        
        dataCruncher.delegate = self
        btDiscovery.startScanning()
        
        hrGraphDelegate.data = [0.0, 0.0]
        sp02GraphDelegate.data = [0.0, 0.0]
        observer.observer //simply instantiating lazy var
        
        sp02Graph.colorLine = UIColor.blueColor()
        hrGraph.colorLine = UIColor.redColor()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        sp02Graph.reloadGraph()
        hrGraph.reloadGraph()
        
        bleRead()
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    //MARK: DataAnalysisDelegate
    
    func analysingData(InfaredData: [Double], RedLEDData: [Double]) {
        
        println(rawDataBin)
        rawDataBin.removeAll(keepCapacity: true)

        if !InfaredData.isEmpty {
//            sp02GraphDelegate.data = InfaredData
        }
        
        if !RedLEDData.isEmpty {
            hrGraphDelegate.data = RedLEDData
        }
        
        self.progressBar.progress = 0.0
    }
    
    func analysisFoundHeartRate(hr: Double)  {
        bpmLabel.text = String(format:"%.01f BPM", arguments: [hr])
    }
    
    //MARK: BLE Connection (BLEServiceDelegate)
    
    func characteristic(characteristic: CBCharacteristic, didRecieveData data: [UInt8]) {
        packetSize.text = "\(data.count)"

        rawDataBin += data

        if let data = DataPacket(rawData: data) {
            dataCruncher.addDataPacket(data)
            
            //FIXME: Might have a threading issue here
            dispatch_async(dispatch_get_main_queue()) {
//                println("Collected \(self.dataCruncher.binPercentage)%")
                
                self.progressBar.progress = Float(self.dataCruncher.binPercentage)
            }
        }

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
            service.updateDelegate = self
            service.readFromConnectedCharacteristics()
        }
    }
    
    func bleRead() {
        if let service = btDiscovery.bleService {
            service.readFromConnectedCharacteristics()
        }
    }

}
