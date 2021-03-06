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

class MonitorTableViewController: UITableViewController, UIAlertViewDelegate, DataAnalysisDelegate, HKAccessProtocol, BLEDataTransferDelegate {
    
    //MARK: Outlets
    
    @IBOutlet weak var monitorLabel: UILabel!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var progressBar: UIProgressView!
    
    @IBOutlet weak var bpmLabel: UILabel!
    @IBOutlet weak var spO2Label: UILabel!
    @IBOutlet weak var rssiLabel: UILabel!
    @IBOutlet weak var packetSize: UILabel!
    @IBOutlet weak var peaksLabel: UILabel!
    
    @IBOutlet weak var hrGraph: BEMSimpleLineGraphView!
    @IBOutlet weak var sp02Graph: BEMSimpleLineGraphView!
    
    var typeAlert: UIAlertView?
    var activityType = ""
    var uploadData: Bool = false
    
    //MARK: Private Properties
    private let client = HeartfulAPIClient()
    
    //MARK: Properties
    var healthStore: HKHealthStore?
    
    var previousHRs = [Double]()

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
        irGraphDelegate.data = [0.0, 0.0]
        
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
    
    @IBAction func addActivity(sender: UIButton) {
        
        typeAlert = UIAlertView(title: "New Heartful DataSet", message: "Please enter your activity type", delegate: self, cancelButtonTitle: "Cancel", otherButtonTitles: "Start")
        
        typeAlert?.alertViewStyle = UIAlertViewStyle.PlainTextInput
        typeAlert?.textFieldAtIndex(0)?.placeholder = "Presenting"
        
        typeAlert?.show()
    }
    
    func alertView(alertView: UIAlertView, didDismissWithButtonIndex buttonIndex: Int) {
        if buttonIndex != alertView.cancelButtonIndex {
            let text = alertView.textFieldAtIndex(0)?.text
            println(alertView.textFieldAtIndex(0)?.text)
            activityType = text ?? "default"
            uploadData = true
        }
        else {
            uploadData = false
        }
    }
    
    func uploadActivity(data: [Double]) {
        let predicate = todayPredicate
        let gId = NSUserDefaults.standardUserDefaults().objectForKey("googleid") as? String
        
        if let gId = gId {
            client.postUserReading(gId, type: activityType, heartRates: data, forDate: NSDate()) { (error) -> Void in
                
                if error == nil {
                    self.packetSize.text = "Uploaded!"
                }
            }
        }
    }
    
    //MARK: DataAnalysisDelegate
    func currentProgress(irDataProg: Double, ledDataProg: Double) {
        progressBar.progress = Float(ledDataProg)
        
        let ledPercentage = abs(ledDataProg*100.0 - 1.0) //99.9% instead of 100
        let irPercentage = abs(irDataProg*100.0 - 1.0)
        
        packetSize.text = String(format:"LED: %2.0f%%, IR: %2.0f%%", arguments: [ledPercentage, irPercentage])
    }
    
    func analysingIRData(InfaredData: [Double], foundPeaks: Int) {
        if !InfaredData.isEmpty {
            irGraphDelegate.data = InfaredData
        }
        peaksLabel.text = "\(foundPeaks) IR"
    }
    
    func analysingLEDData(redLEDData: [Double], foundPeaks: Int) {
        if !redLEDData.isEmpty {
            redLEDGraphDelegate.data = redLEDData
        }
        peaksLabel.text = "\(foundPeaks) LED"
    }
    
    func analysisFoundHeartRate(hr: Double)  {
        println(String(format:"%.01f BPM", arguments: [hr]))
        
        if hr < MAX_HR && hr > MIN_HR {
            
            previousHRs.append(hr)
            let average = avg(previousHRs)
            let smoothHR = average * 0.75 + hr * 0.25
            healthStore?.saveHeartRate(smoothHR)

            if previousHRs.count >= SMOOTHING_BIN_SIZE {
                previousHRs.removeLast()
            }
            
            bpmLabel.text = String(format:"%.01f BPM", arguments: [smoothHR])
            
            if uploadData {
                uploadActivity([smoothHR])
            }
        }
        else {
            spO2Label.text = "---"
            bpmLabel.text = "💔"
        }
    }
    
    func analysisFoundSP02(sp02: Double) {
//        let percentage = abs(sp02*100.0 - 0.9) //99.9% instead of 100
        if sp02 > 0 {
            spO2Label.text = String(format:"%2.2f SP02", arguments: [sp02])
        }
        else {
            spO2Label.text = "---"
        }
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
