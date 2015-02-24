//
//  BLEDataProcessingTests.swift
//  BLEDataProcessingTests
//
//  Created by Michael DeWitt on 2/23/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import UIKit
import XCTest

class BLEDataProcessingTests: XCTestCase {
    
    let dataCruncher = DataCruncher()
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    //MARK: Helpers
    func readCSV(fileName:String = "BLEData", delimiter: String = ",") ->[Double]? {
        
        let bundle = NSBundle(forClass: self.classForCoder)
        let path = bundle.pathForResource(fileName, ofType: ".csv") ?? ""
        
        if let csvFileContents = String(contentsOfFile:path, encoding: NSUTF8StringEncoding) {
        
            let strValues = csvFileContents.componentsSeparatedByString(delimiter)
            return strValues.map { NSString(string: $0).doubleValue }
        }
        
        return nil
    }
    
    func parseDataIntoPackets(values: [Double]) -> [DataPacket] {
        
        var data = [UInt8]()
        var allDataPackets = [DataPacket]()
        var count = BLE_PACKET_SIZE - 1
        for num in values {
            data.append(UInt8(num))
            
            if count-- <= 0 {
                if let packet = DataPacket(rawData: data) {
                    allDataPackets.append(packet)
                    data.removeAll(keepCapacity: true)
                }
                count = BLE_PACKET_SIZE - 1
            }
        }
        
        return allDataPackets
    }
    
    
    //MARK: Tests
    func testPeakDetectionFromFile() {
        let values = readCSV()
        XCTAssert(values != nil, "Failed to Read file")

        let packets = parseDataIntoPackets(values!)
        
        let info = dataCruncher.processBin(packets)
        XCTAssert(info != nil, "Failed to process data")

        if let info = info {
            
            let peaks = dataCruncher.findPeaks(info.0)
            XCTAssert(peaks.count == 10, "Found incorrect number of peaks")

            let bpm = dataCruncher.calculateHeartRate(info.0, avgTimeBtwPackets: info.2, avgTimePerPoint: info.1)
            XCTAssert(bpm > 60.0, "Unreasonable HR")
        }
    }
    
    func testRandomPeakDetection() {
        var packets = [DataPacket]()
        
        for i: UInt8 in 1...100 {
            let packet = [0, UInt8(random() % 255), UInt8(random() % 255), UInt8(random() % 255), UInt8(random() % 255), UInt8(random() % 255), UInt8(random() % 255), UInt8(random() % 255), UInt8(random() % 255), UInt8(random() % 255), UInt8(random() % 255), UInt8(random() % 255), UInt8(random() % 255), UInt8(random() % 255), UInt8(random() % 255), UInt8(random() % 255), UInt8(random() % 255), UInt8(random() % 255), UInt8(random() % 255), UInt8(random() % 255)]
            packets += [DataPacket(rawData: packet)!]
        }
        println(packets.first!)
        
        let info = dataCruncher.processBin(packets)
        XCTAssert(info != nil, "Failed to process data")
        
        if let info = info {
            
            let peaks = dataCruncher.findPeaks(info.0)
            XCTAssert(peaks.count == 0, "Found incorrect number of peaks")
            
            let bpm = dataCruncher.calculateHeartRate(info.0, avgTimeBtwPackets: info.2, avgTimePerPoint: info.1)
            XCTAssert(bpm.isNaN, "Unreasonable Data should not produce heartBeat: \(bpm)")
        }
    }
    
}
