//
//  DataCruncher.swift
//  Pulse
//
//  Created by Michael DeWitt on 2/9/15.
//  Copyright (c) 2015 Biomedical Engineering Design. All rights reserved.
//

import CoreBluetooth

// Convert the analog reading (which goes from 0 - 1023) to a voltage (0 - 5V)
let ArudinoVoltageConversionFactor = 1.0 //4.0 / 1023.0
let binCapacity = 800
let MAX_TIME = 65535

protocol DataAnalysisDelegate: class {
    func analysisingData(InfaredData: [Double], RedLEDData: [Double])
    func analysisFoundHeartRate(hr: Double)
}

class DataCruncher {
    
    //MARK: Private Properties
    private var currentPacket = DataPacket()

    //MARK: Properties
    var IRDataBin = [Double]()
    var LEDDataBin = [Double]()
    
    var timeBetweenPackets = [Int]()
    var timeInPackets = [Double]()
    
    weak var delegate: DataAnalysisDelegate?
    
    var binPercentage: Double {
        return Double(self.IRDataBin.count)/Double(binCapacity)
    }
    
    //MARK: Build filteredDataBin
    
    func addDataPacket(packet: DataPacket) {
        
        var startTime = packet.startTime
        if currentPacket.endTime > startTime {
             startTime += MAX_TIME
        }
        
        timeInPackets += [packet.timePerPoint * Double(packet.dataPoints.count)]
        timeBetweenPackets += [Int(startTime - currentPacket.endTime)]
        currentPacket = packet
        
        let voltageValues = packet.dataPoints.map { $0.value * ArudinoVoltageConversionFactor }
        
        //Filtering
        if var lowPass =  FIRFilter(inputData: voltageValues) {
            let filteredValues = lowPass.filter()
            
            switch packet.lightSource {
            case .IR:
                IRDataBin += filteredValues
            case .RedLED:
                LEDDataBin += filteredValues
            }
            
            if LEDDataBin.count > binCapacity {
                let hr = calculateHeartRate(LEDDataBin)
                
                let ledData = LEDDataBin
                dispatch_async(dispatch_get_main_queue()) {
                    self.delegate?.analysisingData([], RedLEDData: ledData)
                    self.delegate?.analysisFoundHeartRate(hr)
                }
                
                totalTime()
                LEDDataBin.removeAll(keepCapacity: true)
                clear()
            }
            
            if IRDataBin.count > binCapacity {
                let hr = calculateHeartRate(IRDataBin)
                
                let irData = IRDataBin
                dispatch_async(dispatch_get_main_queue()) {
                    self.delegate?.analysisingData(irData, RedLEDData:[])
                    self.delegate?.analysisFoundHeartRate(hr)
                }
                
                IRDataBin.removeAll(keepCapacity: true)
                clear()
            }
        }
    }
    
    func clear() {
        timeBetweenPackets.removeAll(keepCapacity: true)
        timeInPackets.removeAll(keepCapacity: true)
    }
    
    func totalTime() {
        let totalTimeBtw = timeBetweenPackets.reduce(0){ $0 + $1 }
        let totalTimeIn = timeInPackets.reduce(0.0){ $0 + $1 }
        let total = Double(totalTimeBtw) + totalTimeIn
        println("TimeBtw: \(totalTimeBtw) TimeIn: \(totalTimeIn)")
        println("Total TimeGraphs: \(total)")
    }
    
    //MARK: Calculations
    
    let MIN_TIME_SPAN = 100.0
    let MILLS_PER_MIN = 60000.0
    func calculateHeartRate(data: [Double]) -> Double {
        
        let peaks = findPeaks(data)
        
        var timeSpans = [Double]()
        for var i=0; i < peaks.count - 1; i++ {
            let p1 = peaks[i].point
            let p2 = peaks[i+1].point
            
            let time = millsBetweenPoints(Double(p1), p2: Double(p2))
            timeSpans.append(time)
        }
        
        timeSpans = timeSpans.filter { $0 > self.MIN_TIME_SPAN }
        timeSpans = timeSpans.map { self.MILLS_PER_MIN/$0 }
        
        var avgMap = [Double]()
        for var i=0; i < timeSpans.count - 1; i++ {
            let t1 = timeSpans[i].0
            let t2 = timeSpans[i+1].0
            let avg = (t1 + t2) / 2
            avgMap.append(avg)
        }
        
        var sum = timeSpans.reduce(0.0) { $0 + $1 }
        let avgBPM = sum/Double(timeSpans.count)
        
        return avgBPM
    }
    
    let BIN_PRINT_TIME  = 727.0
    let TIME_PER_POINT = 0.17
    
    private func millsBetweenPoints(p1: Double, p2: Double) -> Double {
        let timePts = (p2 - p1) * TIME_PER_POINT
        let numPrintBins = floor((p2 - p1) / 100)
        let spanWithPrint = BIN_PRINT_TIME * numPrintBins
        let milis = (timePts + spanWithPrint)
        
        return milis
    }
    
    private func findPeaks(data: [Double]) -> [DataPoint] {
        let maxValue = data.reduce(0.0) { max($0, $1) }
        maxValue
        
        let maxValueTolerance = 0.75
        var indicies = [DataPoint]()
        for (index, value) in enumerate(data) {
            if value >= maxValue * maxValueTolerance {
                indicies.append(DataPoint(point: index, value: value))
            }
        }
        
        //MARK: Clustering
        let HR_WIDTH = 100
        var peaks = [DataPoint]()
        func average(group: [DataPoint]) -> DataPoint {
            let count = group.count
            let total = group.reduce(DataPoint.Zero()){ $0 + $1 }
            
            return DataPoint(point: total.point / count, value: total.value / Double(count))
        }
        
        var cluster = [indicies.first!]
        for dataPoint in indicies {
            let width = cluster.first!.point + HR_WIDTH

            if  width > dataPoint.point {
                cluster.append(dataPoint)
            }
            else {
                let avg = average(cluster)
                peaks.append(avg)
                
                cluster.removeAll(keepCapacity: true)
                cluster.append(dataPoint)
            }
        }
        peaks.append(average(cluster))
        
        return peaks
    }
}

//Finite Impulse Response (FIR) filter
// http://www.arc.id.au/FilterDesign.html
struct FIRFilter {
    //    static let FIR_coeff = [0.1, 0.2, 1, 0.2, 0.1]
    static let FIR_coeff = [0.4, 0.8, 1, 0.8, 0.4]
    
    var queue = [Double]()
    var data: [Double]
    
    init?(inputData: [Double]) {
        let count = FIRFilter.FIR_coeff.count
        if count > inputData.count {
            return nil
        }
        
        data = Array(inputData[count..<inputData.count])
        queue += inputData[0..<count]
    }
    
    mutating func filter() -> [Double] {
        return data.map { value in
            self.queue.insert(value, atIndex: 0)
            self.queue.removeLast()
            
            var output = 0.0
            for (index,value) in enumerate(self.queue) {
                output += value * FIRFilter.FIR_coeff[index]
            }
            return output
        }
    }
}
